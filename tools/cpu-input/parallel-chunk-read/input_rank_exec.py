"""Actual rank-exec binding: only root0 receives input NC/DSO, never Python preload."""
from pathlib import Path
import os,sys,json,hashlib,socket
lease_path=Path(sys.argv[1]);assert hashlib.sha256(lease_path.read_bytes()).hexdigest()==sys.argv[2];l=json.loads(lease_path.read_text());r=int(os.environ['OMPI_COMM_WORLD_RANK']);assert int(os.environ['OMPI_COMM_WORLD_SIZE'])==512 and 0<=r<512 and os.getuid()==1000
m=l['rank_map'][r];assert socket.gethostname().split('.')[0]==m['host']and os.sched_getaffinity(0)=={m['cpu']}
assert sys.argv[3]==l['executable'];e=dict(os.environ);assert not e.get('LD_PRELOAD')
pre=l['shim_path']+':'+l['ng_path'];expected=l['mpi_prefix']+'/lib:'+l['rank_runtime_ld_library_path'];assert e['LD_LIBRARY_PATH']==expected
for k in ['WRF_INPUT_PREDECODE_OPTIN','WRF_INPUT_PREDECODE_OWNER','WRF_INPUT_SCOPE_LOGDIR']:e.pop(k,None)
if r==0:
 a=l['input_read'];assert a['pending_component']is False and m['host']=='hpc01'and m['cpu']==0
 pre=a['adapter_path']+':'+pre;e['LD_LIBRARY_PATH']=str(Path(a['owner_path']).parent)+':'+expected
 e.update(WRF_INPUT_PREDECODE_OPTIN='1',WRF_INPUT_PREDECODE_OWNER=a['owner_path'],WRF_INPUT_SCOPE_LOGDIR=str(Path(l['run_directory'])/'input-logs'))
e['LD_PRELOAD']=pre
os.execve(sys.argv[3],sys.argv[3:],e)
