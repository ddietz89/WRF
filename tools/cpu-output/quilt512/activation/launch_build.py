#!/usr/bin/env python3
"""Stage only pinned experimental sources and submit one bounded package build."""
from pathlib import Path
import base64,hashlib,json,subprocess
HERE=Path(__file__).resolve().parent
m=json.loads((HERE/'activation-manifest.json').read_text())
assert hashlib.sha256((HERE/'activation-manifest.json').read_bytes()).hexdigest()=='2aefd27777d3b8f40ebf90004a11d4965b225f7b109faf0246eb11401c233fa3'
files={}
for relative,item in m['files'].items():
 data=Path(item['local']).read_bytes();assert hashlib.sha256(data).hexdigest()==item['sha256'];files[relative]=base64.b64encode(data).decode()
payload={'manifest':m,'files':files}
remote='''import base64,hashlib,json,os,socket,subprocess
from pathlib import Path
p=json.loads(base64.b64decode(PAYLOAD));m=p['manifest'];D=Path(m['directory']);unit=m['unit']
assert socket.gethostname().split('.')[0]=='hpc02'
assert os.getuid()==1000
mem={x.split(':')[0]:int(x.split()[1])*1024 for x in Path('/proc/meminfo').read_text().splitlines() if x.startswith('MemAvailable:')}
assert mem['MemAvailable']>=4*1024**3
# Prevent duplicate submission or accidental adoption of a prior owned namespace.
assert not D.exists() and not D.is_symlink()
q=subprocess.run(['systemctl','show',unit+'.service','-p','MainPID','-p','ActiveState'],capture_output=True,text=True,check=True)
assert 'MainPID=0' in q.stdout and 'ActiveState=active' not in q.stdout and 'ActiveState=activating' not in q.stdout
live=subprocess.run(['systemctl','list-units','--state=running','--no-legend','--plain','wrf-cpu-*'],capture_output=True,text=True,check=True).stdout
assert not live.strip(),('unexpected live hpc02 campaign unit',live)
D.mkdir(parents=True,exist_ok=False)
pins={}
for relative,data in p['files'].items():
 path=D/relative;assert not Path(relative).is_absolute() and '..' not in Path(relative).parts
 path.parent.mkdir(parents=True,exist_ok=True);raw=base64.b64decode(data);assert hashlib.sha256(raw).hexdigest()==m['files'][relative]['sha256'];path.write_bytes(raw);path.chmod(0o444);pins[relative]=hashlib.sha256(raw).hexdigest()
(D/'stage-source-pins.json').write_text(json.dumps(pins,indent=2)+'\\n')
(D/'activation-manifest.json').write_text(json.dumps(m,indent=2)+'\\n')
cmd=['sudo','-n','systemd-run','--unit='+unit,'--uid=1000','--gid=1000','--property=AllowedCPUs=24,25','--property=CPUAffinity=24 25','--property=CPUQuota=200%','--property=MemoryMax=2G','--property=MemorySwapMax=0','--property=RuntimeMaxSec=300','--property=LimitMEMLOCK=infinity','--property=KillMode=control-group','--property=WorkingDirectory='+str(D),'/usr/bin/python3',str(D/'run_build.py')]
r=subprocess.run(cmd,capture_output=True,text=True);assert r.returncode==0,(r.stdout,r.stderr)
state=subprocess.run(['systemctl','show',unit+'.service','-p','MainPID','-p','ControlGroup','-p','ActiveState','-p','InvocationID'],capture_output=True,text=True,check=True).stdout
print(json.dumps({'unit':unit+'.service','directory':str(D),'launch_command':cmd,'state':state,'source_count':len(pins)}))
'''.replace('PAYLOAD',repr(base64.b64encode(json.dumps(payload).encode()).decode()))
# SSH carries source bytes privately; no credentials or scientific payload is present.
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','HostKeyAlias=hpc00','100.103.134.47','ssh hpc02 python3 -'],input=remote,text=True,capture_output=True)
(HERE/'launch-output-r1.txt').write_text(r.stdout+r.stderr)
print(r.stdout,end='');print(r.stderr,end='');raise SystemExit(r.returncode)
