"""Inactive current0a551 one BIGSTEP nonfinalT overlay, canonical CPP only, no cache/timing."""
from pathlib import Path
import argparse,base64,hashlib,json,shlex,subprocess,time
P=Path(__file__).resolve().parent
S='/pool/wrf-experiment/wrf-cpu/source-discovery/current3582-calc-bc-source-reproduction-hpc02-r1'
q=json.loads((P/'REBUILD_RECIPE.json').read_text());HOST=q['host'];assert HOST in ['hpc02']
D=q['output']
UNIT='wrf-cpu-current3582-calc-bc-source-reproduction-'+HOST+'-r1.service'
ap=argparse.ArgumentParser()
ap.add_argument('--execute-after-root-release',action='store_true',required=True)
ap.add_argument('--expected-pins-sha256',required=True)
a=ap.parse_args()
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(P/'manifest.json')==a.expected_pins_sha256
assert json.loads((P/'REBUILD_RECIPE.json').read_text())['ready'] is True
assert json.loads((P/'REBUILD_RECIPE.json').read_text())['root_authorized'] is True
pins=json.loads((P/'manifest.json').read_text())['files']
assert q['host']=='hpc02'and q['cpus']==[24,25]and q['runtime_seconds']==600
assert all(Path(n).name==n and sha(P/n)==h for n,h in pins.items())
# One controller receipt, one actual worker receipt and one actual terminal closure.
R=P/'actual-native-r1';R.mkdir(exist_ok=False)
r={'status':'FAIL_RETAINED_NO_RETRY','namespace':S,'unit':UNIT,'expected_pins_sha256':a.expected_pins_sha256}
def gateway(code,timeout=35):
 z=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','HostKeyAlias=hpc00','100.103.134.47','python3 -'],input=code,capture_output=True,text=True,timeout=timeout)
 assert z.returncode==0,(z.returncode,z.stdout,z.stderr)
 return json.loads(z.stdout)
def onhost(argv,timeout=25):
 remote=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10',HOST,shlex.join(list(map(str,argv)))]
 code='import subprocess,json\nz=subprocess.run('+repr(remote)+',capture_output=True,text=True,timeout='+str(timeout)+')\nprint(json.dumps({"returncode":z.returncode,"stdout":z.stdout,"stderr":z.stderr}))\n'
 return gateway(code,timeout+15)
try:
 payload={n:base64.b64encode((P/n).read_bytes()).decode()for n in [*pins,'manifest.json']}
 code='''from pathlib import Path
import base64,hashlib,json
P=Path(DEST);assert not P.exists();P.mkdir()
a=json.loads(PAYLOAD)
for n,v in a.items():
 assert Path(n).name==n
 (P/n).write_bytes(base64.b64decode(v))
pins=json.loads((P/'manifest.json').read_text())['files']
assert hashlib.sha256((P/'manifest.json').read_bytes()).hexdigest()==EXPECTED
assert all(hashlib.sha256((P/n).read_bytes()).hexdigest()==h for n,h in pins.items())
print(json.dumps({'status':'PASS_EXACT_REVIEWED_INPUTS_STAGED'}))
'''.replace('DEST',repr(S)).replace('EXPECTED',repr(a.expected_pins_sha256)).replace('PAYLOAD',repr(json.dumps(payload)))
 r['staging']=gateway(code)
 # Root confirmed campaign idle before activating controller; bounded native accuracy only.
 # No WorkingDirectory or StandardOutput=file systemd properties: avoid manager-side NFS access.
 bootstrap='import os,runpy; p='+repr(S)+'; fd=os.open(p+"/service.log",os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600); os.dup2(fd,1); os.dup2(fd,2); os.close(fd); os.chdir(p); runpy.run_path(p+"/run_build.py",run_name="__main__")'
 argv=['sudo','-n','systemd-run','--quiet','--unit='+UNIT,'--uid=1000','--gid=1000',
       '--property=AllowedCPUs=24-25','--property=CPUAffinity=24 25','--property=CPUQuota=200%',
       '--property=MemoryMax=8G','--property=MemorySwapMax=0','--property=LimitSTACK=infinity',
       '--property=LimitMEMLOCK=infinity','--property=RuntimeMaxSec=600','--property=KillMode=control-group',
       '/usr/bin/python3','-u','-c',bootstrap]
 launch=onhost(argv);r['launch']=launch;assert launch['returncode']==0,launch
 show=['systemctl','show',UNIT,'-p','MainPID','-p','Result','-p','ExecMainStatus','-p','ControlGroup','-p','LoadState','-p','ActiveState','-p','InvocationID']
 def props():
  z=onhost(show);assert z['returncode']==0,z
  return dict(x.split('=',1)for x in z['stdout'].splitlines())
 initial=props();r['initial_properties']=initial
 (R/'controller.json').write_text(json.dumps(r,indent=2)+'\n')
 deadline=time.monotonic()+660
 while True:
  terminal=props()
  if terminal['MainPID']=='0'and terminal['ActiveState']not in ['active','activating','deactivating','reloading']:break
  assert time.monotonic()<deadline,'Unit still active after bounded deadline; retain actual state, no automatic retry'
  time.sleep(5)
 # Collect a single bounded result read and actual empty cgroup proof on the execution host.
 collect='''from pathlib import Path
import hashlib,json,subprocess
P=Path(DEST);unit=UNITNAME;props=PROPS
out={'properties':props,'receipt':None,'cgroup_processes':[]}
f=Path(BUILD)/'receipt.json'
if f.exists():
 b=f.read_bytes();assert len(b)<4*1024*1024
 out['receipt']=json.loads(b);out['receipt_sha256']=hashlib.sha256(b).hexdigest()
paths={Path('/sys/fs/cgroup/system.slice')/unit}
if props.get('ControlGroup'):paths.add(Path('/sys/fs/cgroup'+props['ControlGroup']))
for p in paths:
 if p.exists():
  for f in p.rglob('cgroup.procs'):out['cgroup_processes']+=f.read_text().split()
out['cgroup_paths_absent']=all(not p.exists()for p in paths)
inv=(out['receipt']or{}).get('invocation_id')orINITIAL_INV
out['invocation_id']=inv;events=[]
z=subprocess.run(['journalctl','--no-pager','-u',unit,'-n','12','-o','json'],capture_output=True,text=True,timeout=15)
assert z.returncode==0
for line in z.stdout.splitlines():
 row=json.loads(line);msg=row.get('MESSAGE')or''
 if inv and inv in row.values()and any(x in msg for x in ['Started ','Deactivated successfully.','Failed ','status=']):events.append({'invocation_id':inv,'message':msg})
out['manager_events']=events
print(json.dumps(out))
'''.replace('DEST',repr(S)).replace('UNITNAME',repr(UNIT)).replace('PROPS',repr(terminal)).replace('INITIAL_INV',repr(initial.get('InvocationID',''))).replace('BUILD',repr(D))
 # Python source travels as one shell-quoted argument; no raw arrays/source bodies retrieved.
 z=onhost(['/usr/bin/python3','-c',collect],30);assert z['returncode']==0,z
 closure=json.loads(z['stdout']);receipt=closure.pop('receipt')
 (R/'closure.json').write_text(json.dumps(closure,indent=2)+'\n')
 if receipt is not None:(R/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
 r['closure']='closure.json';r['worker_receipt']='receipt.json'
 assert terminal['MainPID']=='0'and terminal['Result']=='success'and terminal['ExecMainStatus']=='0'
 assert not closure['cgroup_processes'],'Cgroup not drained'
 assert closure['cgroup_paths_absent'],'Actual cgroup remains'
 assert receipt is not None and receipt['invocation_id']==closure['invocation_id']
 assert any('Deactivated successfully.'in x['message']for x in closure['manager_events'])
 assert receipt['status']==q['status_after_success'],receipt.get('error')
 r.update(status='PASS_ACTUAL_TWO_SOURCE_CALC_BC_REPRODUCTION_CLOSED',invocation_id=closure['invocation_id'],worker_status=receipt['status'])
except BaseException as error:
 r['error']=repr(error)
 raise
finally:
 (R/'controller.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r),flush=True)
