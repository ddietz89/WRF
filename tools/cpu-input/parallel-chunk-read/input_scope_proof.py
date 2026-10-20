"""Separate INPUT scope validation. Not yet native/runtime-qualified.

Original output375 log parser and worker_proof.check_threads remain unchanged.
Only this independently validated root record may contribute additional scopes.
No caller may use this parser to bypass original all-rank/runtime predicates.
"""
from pathlib import Path
import copy,hashlib,json,stat
MASK=[0,1,2,3]
def read_input_log(directory,owner_path,expected_pid):
 files=list(Path(directory).glob('input-rank*-*.jsonl'))
 assert len(files)==1
 p=files[0];st=p.lstat();assert stat.S_ISREG(st.st_mode)and st.st_uid==1000 and not(st.st_mode&0o077)
 assert p.name==f'input-rank0-{expected_pid}.jsonl'and st.st_size<=16*1024*1024
 raw=p.read_bytes();rows=[json.loads(x)for x in raw.splitlines()];assert len(rows)>=3
 first,last=rows[0],rows[-1]
 assert first=={'event':'constructor','environment_rank_hint':0,'pid':expected_pid,'mpi_calls':0,'authority':'UNVALIDATED_UNTIL_ACTUAL_MPI_SCOPE'}
 assert last['event']=='final'and last['rank']==0
 activations=[];reads=[];generations={}
 allowed={'widen_begin','widen_end','worker_create_begin','worker_create_return','worker_register','worker_bound','worker_exit','worker_join','callback'}
 for row in rows[1:-1]:
  e=row['event'];assert row['rank']==0
  if e=='activation':activations.append(row);continue
  if e=='read':assert row['status']==0;reads.append(row);continue
  assert e in allowed,(e,'fatal/join failure/unknown event is not qualified')
  g=row['generation'];assert isinstance(g,int)and g>0;generations.setdefault(g,[]).append(row)
 assert len(activations)==1
 a=activations[0];assert a['size']==512 and a['mpi_thread']>=1 and a['root_cpu']==0 and a['cgroup_cpu_count']==128 and a['memory_max']==100*2**30 and a['swap_max']==0 and a['uid']==1000 and a['host']=='hpc01'and a['owner']==owner_path
 scopes=[];supplied=0
 for g,events in sorted(generations.items()):
  def unique(event,slot=None):
   z=[r for r in events if r['event']==event and(slot is None or r.get('slot')==slot)];assert len(z)==1,(g,event,slot,len(z));return z[0]
  begin,end,callback=[unique(e)for e in ['widen_begin','widen_end','callback']]
  main=(begin['tid'],str(begin['startticks']));assert main[0]==expected_pid and begin['startticks']>0
  assert begin['status']==0 and end['status']==callback['status']
  assert (end['tid'],str(end['startticks']))==main and begin['monotonic_ns']<end['monotonic_ns']
  for r in [begin,end]:assert r['slot']==-1 and r['affinity_status']==0 and r['worker_mask']==MASK and r['observed_mask']==[0]
  assert callback['workers']==MASK and callback['restored_singleton']is True and callback['borrowed_occupied_cores']is True
  created=callback['created'];assert isinstance(created,int)and 0<=created<=4
  success=callback['status']==1
  if success:assert created==4;supplied+=1
  # At most one failed creation at the prefix end; no blind retry slots.
  starts=[r for r in events if r['event']=='worker_create_begin'];returns=[r for r in events if r['event']=='worker_create_return']
  assert len(starts)==len(returns)and len(starts)in [created,created+1]
  assert sorted(r['slot']for r in starts)==list(range(len(starts)))
  for slot in range(len(starts)):
   c,r=unique('worker_create_begin',slot),unique('worker_create_return',slot)
   assert c['status']==0 and r['status']==(0 if slot<created else r['status'])
   if slot==created:assert not success and r['status']!=0
   for x in [c,r]:assert(x['tid'],str(x['startticks']))==main and x['affinity_status']==0 and x['worker_mask']==MASK and x['observed_mask']==MASK
   assert begin['monotonic_ns']<=c['monotonic_ns']<=r['monotonic_ns']<=end['monotonic_ns']
  workers=[]
  for slot in range(created):
   c,reg,bound,exited,joined=[unique(e,slot)for e in ['worker_create_begin','worker_register','worker_bound','worker_exit','worker_join']]
   identity=(reg['tid'],str(reg['startticks']));assert identity[0]!=expected_pid and reg['startticks']>0
   for x in [reg,bound,exited,joined]:assert(x['tid'],str(x['startticks']))==identity and x['expected_cpu']==MASK[slot]and x['status']==0
   assert all(x['affinity_status']==0 for x in [reg,bound,exited])
   assert reg['observed_mask']==MASK and bound['observed_mask']==exited['observed_mask']==[MASK[slot]]
   a,b,c_,d,e=[r['monotonic_ns']for r in [c,reg,bound,exited,joined]]
   assert begin['monotonic_ns']<=a<=b<=c_<=d<=e<=end['monotonic_ns']
   workers.append({'identity':identity,'slot':slot,'cpu':MASK[slot],'birth_begin_ns':a,'register_ns':b,'bound_ns':c_,'join_ns':e})
  assert len({w['identity']for w in workers})==created
  known=len(starts)*2+created*4+3;assert len(events)==known,'extra/duplicate/orphan event'
  scopes.append({'generation':g,'main_identity':main,'begin_ns':begin['monotonic_ns'],'end_ns':end['monotonic_ns'],'mask':MASK,'workers':workers})
 assert len(reads)==last['scopes']and len(scopes)==last['callbacks']==last['widens']==last['restores']
 assert supplied==last['supplied']and len(scopes)-supplied==last['declines']and supplied>0
 assert all(a['end_ns']<b['begin_ns']for a,b in zip(scopes,scopes[1:]))
 return {'pid':expected_pid,'scopes':scopes,'final':last},{p.name:hashlib.sha256(raw).hexdigest()}

def merge_root_input_record(qualified_output_records,input_record):
 """Call ONLY after original 512 output records and this input log validate.

The resulting record goes to the BYTE-UNCHANGED original check_threads.
Its PID/ticks/window/mask rules remain hard for main and every other thread.
 """
 assert sorted(qualified_output_records)==list(range(512))
 assert qualified_output_records[0]['pid']==input_record['pid']and not qualified_output_records[0]['scopes']
 merged=copy.deepcopy(qualified_output_records)
 merged[0]['scopes']=copy.deepcopy(input_record['scopes'])
 assert all(merged[g]==qualified_output_records[g]for g in range(1,512))
 return merged
