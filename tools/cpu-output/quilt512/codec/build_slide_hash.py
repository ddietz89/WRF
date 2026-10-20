"""Create-only reproduction of the qualified slide-hash codec; no activation."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import traceback

S = Path(__file__).resolve().parent / 'slide-hash-unroll4'
C = Path('/pool/wrf-experiment/wrf-cpu/builds/codec-huffman-word-load-native-r1/build')
Z = Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng')
G = Path('/pool/wrf-experiment/toolchains/gnu/13.3.0')
LIB = 'libz.so.1.3.1.zlib-ng'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, required=True)
    out = parser.parse_args().output_dir.absolute()
    assert not out.exists() and not out.is_symlink()
    assert all(not p.is_symlink() for p in out.parents)
    pins = json.loads((S / 'source-pins.json').read_text())
    assert all(sha(S / n) == h for n, h in pins.items())
    meta = json.loads((S / 'original-build-metadata.json').read_text())
    arch = json.loads((S / 'arch-build-metadata.json').read_text())
    current = json.loads((S / '881-build-receipt.json').read_text())
    qualified = json.loads((S / 'CODEC_PROVIDER_RECEIPT.json').read_text())
    native = json.loads((S / 'NATIVE_RECEIPT.json').read_text())
    objects = dict(meta['pic_objects'])
    previous = json.loads((S / 'f85-build-receipt.json').read_text())
    for receipt, base in [(previous, C.parent.parent / 'codec-avx2-caller-specialization-r1/build'), (current, C)]:
        for path, digest in receipt['artifacts'].items():
            path = Path(path)
            if path.is_relative_to(base) and str(path.relative_to(base)) in objects:
                objects[str(path.relative_to(base))] = digest
    assert len(objects) == 71 and all(sha(C / n) == h for n, h in objects.items())
    assert sha(C / LIB) == qualified['parent_library_sha256']
    assert sha(meta['compiler_path']) == meta['compiler_sha256']
    for name, digest in arch['source_headers'].items():
        assert sha(Z / 'source' / name) == digest
    parent = (S / 'parent-slide_hash_avx2.c').read_text()
    candidate = (S / 'candidate-slide_hash_avx2.c').read_text()
    assert candidate.count('#pragma GCC unroll 4') == 1
    assert candidate.replace('    #pragma GCC unroll 4\n', '', 1) == parent
    names = current['ordered_shared_link_inputs']
    assert len(names) == len(set(names)) == 52
    out.mkdir(parents=True)
    receipt = {'status': 'FAIL', 'scope': 'Build reproduction only; no model activation or qualification'}
    env = os.environ.copy()
    env.pop('LD_PRELOAD', None)
    env.update(PATH=str(G / 'bin') + ':' + env.get('PATH', ''),
               LD_LIBRARY_PATH=str(G / 'lib64') + ':' + str(G / 'deps/lib'))

    def run(argv, label):
        with (out / (label + '.log')).open('w') as log:
            subprocess.run(list(map(str, argv)), env=env, stdout=log,
                           stderr=subprocess.STDOUT, check=True, timeout=60)
        receipt.setdefault('commands', []).append(list(map(str, argv)))

    try:
        build = out / 'build'
        build.mkdir()
        for name in objects:
            target = build / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(C / name, target)
        source = out / 'slide_hash_avx2.c'
        shutil.copyfile(S / 'candidate-slide_hash_avx2.c', source)
        var = lambda text, name: shlex.split(re.search(r'^' + name + r'=(.*)$', text, re.M)[1])
        isa = var(arch['arch_makefile'], 'AVX2FLAG')
        assert isa == ['-mavx2', '-mbmi2']
        obj = build / 'arch/x86/slide_hash_avx2.lo'
        flags = [*var(arch['arch_makefile'], 'SFLAGS'), *isa, '-fno-lto', '-DPIC',
                 '-I' + str(Z / 'build'), '-I' + str(Z / 'source'),
                 '-I' + str(Z / 'source/arch/x86')]
        run([meta['compiler_path'], *flags, '-c', source, '-o', obj], 'compile-slide-hash')
        assert sha(obj) == native['candidate_production_object_sha256']
        shutil.copyfile(obj, build / 'slide_hash_avx2.lo')
        changed = sorted(n for n, h in objects.items() if sha(build / n) != h)
        assert changed == ['arch/x86/slide_hash_avx2.lo', 'slide_hash_avx2.lo']
        run([meta['compiler_path'], *var(meta['makefile'], 'CFLAGS'), '-shared',
             '-Wl,-soname,libz.so.1', '-Wl,--version-script,' + str(Z / 'build/zlib.map'),
             '-o', build / LIB, *[build / n for n in names]], 'link-codec')
        assert sha(build / LIB) == qualified['candidate_library_sha256']
        assert all(sha(C / n) == h for n, h in objects.items())
        assert all(sha(S / n) == h for n, h in pins.items())
        receipt.update(status='BUILD_PASS_EXACT_SLIDE_HASH_CODEC_REPRODUCTION',
                       candidate_library_sha256=sha(build / LIB),
                       candidate_library_path=str(build / LIB),
                       changed_pic_paths=changed, unchanged_shared_link_inputs=51,
                       matches_qualified_library=True)
    except BaseException:
        receipt['error'] = traceback.format_exc()
        raise
    finally:
        (out / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
