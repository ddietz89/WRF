"""Original four complete histories and full545-step matched comparison; no exemptions."""
from pathlib import Path
import sys,json,hashlib,os,concurrent.futures,multiprocessing
sys.path.insert(0,'/pool/wrf-experiment/wrf-cpu/validation');sys.path.insert(0,'/pool/wrf-experiment/wrf-cpu/checker-runtime')
from runtime_checks import ROOT,sha,stat,source_pins,validate_lease,input_guard,runtime_proof
import wrf_exact,adaptive_chunk_cache
from prerequisite import check
def compare_one(pair):
 left,right=pair;records=[];restore=adaptive_chunk_cache.install(wrf_exact,records)
 try:return wrf_exact.compare(str(left),str(right),expected_times=[left.name.removeprefix('wrfout_d01_')]),records
 finally:restore()
S=Path(__file__).resolve().parent;source_pins(S);out=Path(sys.argv[1]);report={'status':'RUNNING_ORIGINAL_INITIAL_HISTORY_COMPARISON','scope':'Candidate-only three-hour four-history equality against frozen original control; no matched timing or per-kernel forecast claim','invocation_id':os.environ.get('INVOCATION_ID')};out.write_text(json.dumps(report)+'\n')
try:
 prerequisite=check()
 binding=json.loads((S/'application-binding.json').read_text())
 from retained_threehour_context import check_original_context
 assert sha(ROOT/'validation/protected_netcdf_exact_reference.py')=='0382bcbabfbc16b76114ef552206c6c558ea15cd3c3552dfaed98b977deea2b4'
 assert sha(ROOT/'validation/wrf_exact.py')=='847e3fb2ca611ffb62b8c2e1ce51a1c4f7a4e9f1438e899cf947a49e80045232'
 assert sha(ROOT/'checker-runtime/adaptive_chunk_cache.py')=='3a58cdbc78afe221a36af775d0aba81902705b9608b853541900efe8e1714892'
 reference=json.loads((S/'runtime-reference-pins.json').read_text());runs={};steps={};before={};proofs={};namelists=[]
 for arm in ['control','candidate']:
  context=Path(binding['latest_original_control']['stage'])if arm=='control'else S
  context_manifest=source_pins(context)
  L=context/('lease-'+arm+'-granted.json');lease=json.loads(L.read_text());assert lease['source_manifest_sha256']==context_manifest;D=Path(lease['run_directory']);assert sha(D/'lease.json')==sha(L);proposed=json.loads((context/('lease-'+arm+'-proposed.json')).read_text());assert lease['executable_sha256']==proposed['executable_sha256']and lease['executable']==proposed['executable']
  if arm=='candidate':validate_lease(lease)
  cl=json.loads((D/'model-closures.json').read_text());assert set(cl)==set(lease['nodes'])
  for h,row in cl.items():assert row['unit']==lease['nodes'][h]['unit']+'.service'and row['main_pid']==0 and row['result']=='success'and row['exit_code']==0 and row['cgroup_processes']==[]
  done=json.loads((D/'completion.json').read_text());assert done['status']=='EXECUTED_PENDING_ORIGINAL_FOUR_HISTORY_COMPARISON'and done['rank_maps']==512 and done['compute_ranks']==480 and done['quilt_ranks']==32
  assert done['outputs']==['wrfout_d01_2026-10-12_06:00:00', 'wrfout_d01_2026-10-12_07:00:00', 'wrfout_d01_2026-10-12_08:00:00', 'wrfout_d01_2026-10-12_09:00:00']and sorted(p.name for p in D.glob('wrfout_d01_*'))==done['outputs']
  preparation=json.loads((D/'preparation.json').read_text());input_guard(D,preparation);assert preparation['namelist_sha256']==sha(S/'three-hour.nml');namelists.append((D/'namelist.input').read_bytes())
  if lease['codec']=='ordinary-no-preload':libs=reference['libraries']
  else:
   libs={a:h for a,h in reference['candidate_libraries'].items()if 'wrf_quilt_thread_shim.so'not in a and a!='/pool/wrf/WPS_new/runtime/zlib-ng/lib/libz.so.1.3.1.zlib-ng'};libs[lease['ng_path']]=lease['ng_sha256'];libs[lease['shim_path']]=lease['shim_sha256']
  if arm=='control':
   original=check_original_context(S,{**binding,'retained_threehour_control':binding['latest_original_control']},libs);assert original['lease']==lease and original['source_manifest_sha256']==context_manifest;proofs[arm]=original['runtime_proof']
  else:proofs[arm]=runtime_proof(D,lease,libs)
  for h,r in proofs[arm]['invocations'].items():assert r['invocation_id']==cl[h]['invocation_id']
  files=[D/n for n in done['outputs']];before[arm]={}
  for file in files:
   st=file.stat();assert not file.is_symlink()and not st.st_mode&0o222;before[arm][file.name]=(st.st_dev,st.st_ino,st.st_size,st.st_mtime_ns,st.st_ctime_ns)
  runs[arm]=(D,files,preparation)
  steps[arm]=[{k:x[k]for k in ['time','dt_text','domain']}for x in json.loads((D/'adaptive-steps.json').read_text())];assert steps[arm]and len(steps[arm])==done['observed_step_count']==545 and steps[arm][-1]['time']=='2026-10-12_09:00:00'
 assert namelists[0]==namelists[1]==(S/'three-hour.nml').read_bytes();assert steps['control']==steps['candidate'],'observed ordered steps differ'
 from tile_proof import compare_actual_tiles
 tile_proofs=compare_actual_tiles(runs['control'][0],runs['candidate'][0])
 results=[];records=[]
 pairs=list(zip(runs['control'][1],runs['candidate'][1]))
 # At most two independent processes; protected comparison and cache policy unchanged.
 with concurrent.futures.ProcessPoolExecutor(max_workers=2,mp_context=multiprocessing.get_context('fork'))as pool:
  for i,(result,cache)in enumerate(pool.map(compare_one,pairs)):
   results.append(result);records.extend(cache);assert result['status']=='PASS'
 assert len(results)==4
 report.update(comparisons=results,cache_records=records,observed_step_count=len(steps['control']),observed_last_step=steps['control'][-1]['time'],runtime=proofs,prerequisite=prerequisite,tile_proofs=tile_proofs);assert result['status']=='PASS'
 for arm,(D,files,preparation)in runs.items():
  input_guard(D,preparation)
  for file in files:
   st=file.stat();assert before[arm][file.name]==(st.st_dev,st.st_ino,st.st_size,st.st_mtime_ns,st.st_ctime_ns)
 report['status']='PASS_ORIGINAL_FOUR_HISTORY_AND_512_DIRECT_STOCK_LATEST_THREE_HOUR_SEQUENCE';out.write_text(json.dumps(report,indent=2)+'\n')
except BaseException as e:report.update(status='FAIL_RETAINED_NO_EXEMPTIONS',error=repr(e));out.write_text(json.dumps(report,indent=2)+'\n');raise
