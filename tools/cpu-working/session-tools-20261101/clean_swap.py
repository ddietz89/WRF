"""Swap a runtime package's executable admission to a clean full-source build.
Usage: clean_swap.py <package_dir> <build_dir> <exe_sha> <archive_sha> <manifest_sha>
Writes clean_build_proof.py, points batch_release at it, updates the lease, repins."""
import sys, json, hashlib
from pathlib import Path

P, B, EXE_SHA, ARCH_SHA, MAN_SHA = Path(sys.argv[1]), sys.argv[2], *sys.argv[3:6]
(P / 'clean_build_proof.py').write_text(f'''"""Clean full-source executable admission (replaces the ordered-RK lineage proof)."""
from pathlib import Path
import json,hashlib
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
EXE='{B}/WRF/main/wrf.exe'
EXE_SHA='{EXE_SHA}'
ARCH='{B}/WRF/main/libwrflib.a'
ARCH_SHA='{ARCH_SHA}'
MANIFEST='{B}/BUILD_MANIFEST.json'
def check(S,b,l,remote=True):
 assert l['executable']==EXE and l['executable_sha256']==EXE_SHA and sha(EXE)==EXE_SHA
 assert sha(ARCH)==ARCH_SHA and l['build_receipt']==MANIFEST and sha(MANIFEST)==l['build_receipt_sha256']=='{MAN_SHA}'
 m=json.loads(Path(MANIFEST).read_text());assert m['outputs']['wrf.exe']==EXE_SHA and m['outputs']['libwrflib.a']==ARCH_SHA
 return {{'status':'PASS_CLEAN_FULL_SOURCE_PENDING_OWN_SCIENCE','executable':{{'path':EXE,'sha256':EXE_SHA}},'archive':{{'path':ARCH,'sha256':ARCH_SHA}}}}
''')
br = P / 'batch_release.py'; t = br.read_text()
if 'from clean_build_proof import check as child_build' not in t:
    old = 'from combined_child_build_proof import check as child_build\n'
    assert t.count(old) == 1; t = t.replace(old, 'from clean_build_proof import check as child_build  # clean full-source executable admission\n')
    br.write_text(t)
lp = P / 'lease-candidate-proposed.json'; l = json.loads(lp.read_text())
l.update(executable=f'{B}/WRF/main/wrf.exe', executable_sha256=EXE_SHA, build_receipt=f'{B}/BUILD_MANIFEST.json', build_receipt_sha256=MAN_SHA)
lp.write_text(json.dumps(l, indent=2))
pins = json.loads((P / 'source-pins.json').read_text()); pins['clean_build_proof.py'] = ''
for n in pins: pins[n] = hashlib.sha256((P / n).read_bytes()).hexdigest()
(P / 'source-pins.json').write_text(json.dumps(pins, indent=2) + '\n')
print('swapped', P.name)
