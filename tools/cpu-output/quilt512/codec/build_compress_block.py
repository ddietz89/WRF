"""Reproduce the qualified one-object codec change in a new directory only."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import traceback

S = Path(__file__).resolve().parent / 'compress-block-local-carry'
Z = Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng')
G = Path('/pool/wrf-experiment/toolchains/gnu/13.3.0')
LIB = 'libz.so.1.3.1.zlib-ng'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--output-dir', type=Path, required=True)
    out = ap.parse_args().output_dir.absolute()
    assert not out.exists() and not out.is_symlink()
    assert all(not p.is_symlink() for p in out.parents)
    pins = json.loads((S / 'source-pins.json').read_text())
    assert all(sha(S / n) == h for n, h in pins.items())
    recipe = json.loads((S / 'REPRODUCTION_INPUTS.json').read_text())
    parent = Path(recipe['parent_build'])
    names = recipe['ordered_shared_link_inputs']
    objects = recipe['parent_link_input_sha256']
    assert len(names) == len(set(names)) == len(objects) == 52
    assert set(names) == set(objects)
    assert all(sha(parent / n) == objects[n] for n in names)
    assert sha(parent / LIB) == recipe['parent_library_sha256']
    assert sha(recipe['compiler_path']) == recipe['compiler_sha256']
    for name, digest in recipe['source_headers'].items():
        assert sha(Z / 'source' / name) == digest
    old = (S / 'parent_compress_block.inc').read_text()
    new = (S / 'candidate_compress_block.inc').read_text()
    source = (S / 'candidate_trees.c').read_text()
    assert source.replace(new, old, 1) == (S / 'parent_trees.c').read_text()
    assert new.count('#else\n' + old + '#endif\n') == 1
    assert sha(S / 'trees_emit.h') == recipe['unchanged_emit_header_sha256']
    out.mkdir(parents=True)
    receipt = {'status': 'FAIL', 'scope': 'Build reproduction only; no activation'}
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
        for name in names:
            target = build / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(parent / name, target)
        source_dir = out / 'source'
        source_dir.mkdir()
        for name in ['candidate_trees.c', 'trees_emit.h']:
            target = 'trees.c' if name == 'candidate_trees.c' else name
            shutil.copyfile(S / name, source_dir / target)
        cc = recipe['compiler_path']
        run([cc, *recipe['sflags'], '-DPIC', *recipe['includes'], '-c',
             source_dir / 'trees.c', '-o', build / 'trees.lo'], 'compile-trees')
        assert sha(build / 'trees.lo') == recipe['candidate_trees_object_sha256']
        changed = [n for n in names if sha(build / n) != objects[n]]
        assert changed == ['trees.lo']
        run([cc, *recipe['cflags'], '-shared', '-Wl,-soname,libz.so.1',
             '-Wl,--version-script,' + str(Z / 'build/zlib.map'),
             '-o', build / LIB, *[build / n for n in names]], 'link-codec')
        assert sha(build / LIB) == recipe['candidate_library_sha256']
        assert all(sha(parent / n) == objects[n] for n in names)
        assert sha(parent / LIB) == recipe['parent_library_sha256']
        assert all(sha(S / n) == h for n, h in pins.items())
        receipt.update(status='BUILD_PASS_EXACT_COMPRESS_BLOCK_CARRY_REPRODUCTION',
                       candidate_library_path=str(build / LIB),
                       candidate_library_sha256=sha(build / LIB),
                       changed_shared_link_inputs=changed,
                       unchanged_shared_link_inputs=51,
                       matches_qualified_library=True)
    except BaseException:
        receipt['error'] = traceback.format_exc()
        raise
    finally:
        (out / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
