"""Finite experimental package build. Root must activate after all model units close."""
from pathlib import Path
import hashlib,json,os,socket,subprocess,time,traceback
D=Path('/pool/wrf-experiment/wrf-cpu/source-discovery/quilt512-package-build-r1')
P=D/'cpu-output/quilt512';UNIT='wrf-cpu-quilt512-package-build-hpc02-r1'
EXPECTED='4cb1c2abc61e60be2c79fc40ab9b9fd45fb19aefb59798afd2bbdad09d20cc71'
def sha(p):
 h=hashlib.sha256()
 with Path(p).open('rb')as f:
  for b in iter(lambda:f.read(1024**2),b''):h.update(b)
 return h.hexdigest()
begin=time.monotonic();result={'status':'RUNNING','unit':UNIT,'invocation_id':os.environ['INVOCATION_ID'],'no_model_or_native_matrix':True};cg=None
try:
 assert socket.gethostname().split('.')[0]=='hpc02'and set(os.sched_getaffinity(0))=={24,25}
 cg=Path('/sys/fs/cgroup'+Path('/proc/self/cgroup').read_text().strip().split('::')[-1]);q,p=map(int,(cg/'cpu.max').read_text().split());assert q==2*p and int((cg/'memory.max').read_text())==2*1024**3 and(cg/'memory.swap.max').read_text().strip()=='0'and UNIT+'.service'in cg.parts
 pins=json.load(open(D/'stage-source-pins.json'))
 for name,h in pins.items():assert sha(D/name)==h,(name,'stage identity')
 env=os.environ.copy();env.pop('LD_PRELOAD',None)
 r=subprocess.run(['/usr/bin/python3',str(P/'build.py'),'--shared-dir',str(P.parent),'--output-dir',str(D/'artifact')],env=env,capture_output=True,text=True,timeout=250)
 result['build_driver']={'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr};assert r.returncode==0,result['build_driver']
 receipt=json.load(open(D/'artifact/build-receipt.json'));assert receipt['returncode']==0
 binary=D/'artifact/wrf_quilt_thread_shim.so';actual=sha(binary);assert actual==receipt['binary_sha256']
 result.update(status='PASS_PACKAGE_BINARY_BYTEIDENTICAL'if actual==EXPECTED else'BUILD_PASS_DIFFERENT_BINARY_PENDING_ROOT_REVIEW',binary=str(binary),binary_sha256=actual,expected_native_sha256=EXPECTED,byteidentical=actual==EXPECTED,build_receipt_sha256=sha(D/'artifact/build-receipt.json'),source_pins=pins)
except Exception as e:result.update(status='FAIL_PACKAGE_BUILD',exception=repr(e),traceback=traceback.format_exc())
result.update(wall_seconds=time.monotonic()-begin,cgroup_peak_bytes=int((cg/'memory.peak').read_text())if cg else None)
(D/'result.json').write_text(json.dumps(result,indent=2)+'\n');raise SystemExit(1 if result['status']=='FAIL_PACKAGE_BUILD'else 0)
