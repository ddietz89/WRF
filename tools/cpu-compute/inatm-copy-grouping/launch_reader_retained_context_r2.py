"""One original comparison after all eight model units have actually closed."""
from pathlib import Path
import subprocess,json,argparse
ap=argparse.ArgumentParser();ap.add_argument('--execute-approved',action='store_true');a=ap.parse_args();assert a.execute_approved,'Await root activation';B=Path('/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-current-inatm-grouping3h-runtime-r1');assert json.loads((B/'application-binding.json').read_text())['ready']is True,'Draft only: actual candidate prerequisites pending'
code='''from pathlib import Path
import subprocess,json,hashlib,shlex,datetime,sys
S=Path('/pool/wrf-experiment/wrf-cpu/science-prep/production512-current-inatm-grouping3h-r1');U='wrf-cpu-production512-current-inatm-grouping3h-exact-check-hpc03-r1';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
sys.path.insert(0,str(S));from closed_unit_proof import verify_closed
models={}
for arm in ['control','candidate']:
 context=Path(json.loads((S/'application-binding.json').read_text())['retained_threehour_control']['stage'])if arm=='control'else S
 leasepath=context/('lease-'+arm+'-granted.json');lease=json.loads(leasepath.read_text())
 if arm=='control':
  retained=json.loads((S/'application-binding.json').read_text())['retained_threehour_control'];assert sha(leasepath)==retained['grant_sha256']and sha(context/'source-pins.json')==retained['source_manifest_sha256']and lease['run_directory']==retained['run_directory']and lease['wall_cap_seconds']==1200
 D=Path(lease['run_directory']);closures=json.loads((D/'model-closures.json').read_text());assert len(closures)==4 and all(r['main_pid']==0 and r['result']=='success'and r['exit_code']==0 and not r['cgroup_processes']for r in closures.values());models[arm]=lease
for h in ['hpc01','hpc02','hpc03','hpc04']:
 for arm in ['control','candidate']:
  lease=models[arm];D=Path(lease['run_directory']);r=json.loads((D/('mpi-launch.json'if h=='hpc01'else h+'-node.json')).read_text());assert r['exit_code']==0 and r['unit']==lease['nodes'][h]['unit']+'.service'
  script='import sys,json;sys.path.insert(0,'+repr(str(S))+');from closed_unit_proof import verify_closed;print(json.dumps(verify_closed('+repr(r['unit'])+','+repr(r['invocation_id'])+')))'
  z=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=15',h,'python3 -'],input=script,text=True,capture_output=True,timeout=25);assert z.returncode==0,z.stderr
units=subprocess.check_output(['systemctl','list-units','wrf-cpu-*','--state=running','--no-legend','--no-pager'],text=True);caps=[];total=0
for line in units.splitlines():
 u=line.split()[0];p=dict(x.split('=',1)for x in subprocess.check_output(['systemctl','show',u,'-p','MainPID','-p','AllowedCPUs','-p','MemoryMax','-p','InvocationID'],text=True).splitlines());used=set();total+=int(p['MemoryMax'])
 for t in p['AllowedCPUs'].replace(',',' ').split():
  if '-'in t:
   lo,hi=map(int,t.split('-'));used.update(range(lo,hi+1))
  else:used.add(int(t))
 assert not used.intersection(set(range(8,16)));caps.append({'unit':u,'properties':p})
assert total+16*2**30<=100*2**30
for n,h in json.loads((S/'source-pins.json').read_text()).items():assert sha(S/n)==h
out=S/'science-receipt.json';assert not out.exists();(S/'reader-admission.json').write_text(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'active_caps':caps},indent=2));cmd='exec /pool/wrf-experiment/tooling/m1/venv/bin/python '+shlex.quote(str(S/'check_pair.py'))+' '+shlex.quote(str(out))
z=subprocess.run(['sudo','-n','systemd-run','--unit='+U,'--uid=ddietz','--gid=ddietz','--property=AllowedCPUs=8-15','--property=CPUAffinity=8-15','--property=CPUQuota=800%','--property=MemoryMax=16G','--property=MemorySwapMax=0','--property=LimitMEMLOCK=infinity','--property=LimitSTACK=infinity','--property=StandardOutput=journal','--property=StandardError=journal','--property=RuntimeMaxSec=900','--property=KillMode=control-group','/usr/bin/taskset','-c','8-15','/bin/bash','-c',cmd],text=True,capture_output=True,check=True);print(json.dumps({'launch':z.stdout+z.stderr,'actual_reader':subprocess.check_output(['systemctl','show',U,'-p','MainPID','-p','InvocationID','-p','ActiveState'],text=True)}))
'''
z=subprocess.run(['ssh','-o','ConnectTimeout=15','-o','BatchMode=yes','-o','HostKeyAlias=hpc00','100.103.134.47','ssh -o ConnectTimeout=15 hpc03 python3 -'],input=code,text=True,capture_output=True,timeout=60);(Path(__file__).resolve().parent/'reader-launch-r2.txt').write_text(z.stdout+z.stderr);print(z.stdout,z.stderr);z.check_returncode()
