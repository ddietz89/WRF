"""Compare one ordinary control/hook case; no launch, tolerance or state repair."""
from pathlib import Path
import argparse,hashlib,json,subprocess
p=argparse.ArgumentParser();p.add_argument('case');p.add_argument('control_json',type=Path);p.add_argument('hook_json',type=Path);p.add_argument('control_raw',type=Path);p.add_argument('hook_raw',type=Path);p.add_argument('--oracle',type=Path,required=True);p.add_argument('--oracle-python',required=True);a=p.parse_args()
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
c=json.loads(a.control_json.read_text());h=json.loads(a.hook_json.read_text())
assert c['case']==h['case']==a.case and c['route']=='control'and h['route']=='hook'
assert c['api_rc']==h['api_rc']==0 and c['before']==h['before'] and c['after']==h['after'],'Actual same publicAPI return/fullfive-state differs'
for r in [c,h]:
 assert r['guards_ok']and r['file_stat_unchanged']and r['thread_count_after']==1 and r['mask_restored']
 assert r['workers_created']==r['workers_joined']and r['counts_frozen_at_public_return']
 assert r['hdf_handler_kind'] in [0,2,3]
for key in ['hdf_stack_before','hdf_stack_after','hdf_stack_before_records','hdf_stack_after_records','hdf_handler_kind','hdf_handler_restored','hdf_handler_calls']:
 assert c[key]==h[key],('OrdinaryNC authoritative HDF state mismatch',key)
assert a.control_raw.stat().st_size==c['output_bytes']==h['output_bytes']==a.hook_raw.stat().st_size
assert sha(a.control_raw)==sha(a.hook_raw),'Every returned byte must match ordinaryNC control'
full=a.case in ['full','seeded','alloc-fail','partial-create','corrupt-copy']
proof=[]
if full:
 assert c['output_bytes']==218542208
 assert sha(a.control_raw)==sha(a.hook_raw)=='22290594ec9fd9181622c3598f636ebfa0b3f9a0b4fed944a9b873207c763b19'
 for raw in [a.control_raw,a.hook_raw]:
  z=subprocess.run([a.oracle_python,str(a.oracle),str(raw)],text=True,capture_output=True,check=True)
  q=json.loads(z.stdout);assert q['status']=='PASS_EVERY_PUBLIC_SYNTHETIC_UINT32_WORD'and q['words']==54635552;proof.append(q)
assert c['callback_attempts']==c['callback_supplied']==0
if a.case=='full':
 assert h['callback_attempts']==h['callback_supplied']==h['workers_created']==h['workers_joined']==h['raw_reads']==h['private_state_dirtied']==0 and h['original_backend_reads']==1
elif a.case=='seeded':
 assert h['callback_attempts']==h['callback_supplied']==1 and h['original_backend_reads']==0 and h['workers_created']==h['workers_joined']==4 and h['raw_reads']==4 and h['private_state_dirtied']==0
elif a.case in ['alloc-fail','partial-create','corrupt-copy']:
 assert h['callback_attempts']==1 and h['callback_supplied']==0 and h['private_failure_unchanged']==1 and h['original_backend_reads']==1 and h['private_state_dirtied']==1
 expected_creates={'alloc-fail':0,'partial-create':2,'corrupt-copy':4}[a.case]
 assert h['workers_created']==h['workers_joined']==expected_creates
 assert h['raw_reads']==(0 if a.case=='alloc-fail'else 4)
else:
 assert h['callback_attempts']==h['callback_supplied']==0
 assert h['original_backend_reads']==(0 if a.case=='zero'else 1)
print(json.dumps({'status':'PASS_ORDINARY_NC_CASE_FULL_BYTES_AND_FIVE_STATE','case':a.case,'raw_sha256':sha(a.hook_raw),'bytes':h['output_bytes'],'fullword_oracles':proof,'hook_counts':{k:h[k]for k in ['callback_attempts','callback_supplied','original_backend_reads','workers_created','workers_joined','private_failure_unchanged','private_state_dirtied','raw_reads']}}))
