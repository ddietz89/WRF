"""Actual-only direct three-hour component science consolidation. No source/default/job actions."""
from pathlib import Path
import ast,json,hashlib,datetime,math
B=Path('/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-current-calc-php-bc3h-runtime-r1');O=Path(__file__).resolve().parent/'APPLICATION_QUALIFICATION.json'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
load=lambda p:json.loads(Path(p).read_text())
def closed(c,inv,reader=False):
 assert c['invocation_id']==inv and c['main_pid']==0 and c['active_state']=='inactive'and c['result']=='success'
 assert c['exit_code']in([0,None]if reader else[0])and c['cgroup_path_absent']and c['cgroup_processes']==[]and c['manager_success_invocation_bound']is True
 assert any(x.get('INVOCATION_ID')==inv and x.get('MESSAGE')==c['unit']+': Deactivated successfully.'for x in c['journal_rows'])
def validate_actual():
 r=load(B/'RESULT.json');s=load(B/'science-receipt.json');reader=load(B/'reader-closure.json');cl=load(B/'candidate-metadata/model-closures.json');b=load(B/'application-binding.json');l=load(B/'lease-candidate-proposed.json');a=b['bc_artifact']
 status='PASS_ORIGINAL_FOUR_HISTORY_AND_512_DIRECT_STOCK_LATEST_THREE_HOUR_SEQUENCE';assert r['status']==s['status']==status
 assert len(s['comparisons'])==4 and all(x['status']=='PASS'for x in s['comparisons'])and s['observed_step_count']==545 and s['observed_last_step']=='2026-10-12_09:00:00'
 closed(reader,s['invocation_id'],True);assert set(cl)=={'hpc01','hpc02','hpc03','hpc04'}
 rt=s['runtime']['candidate']
 for h,c in cl.items():closed(c,rt['invocations'][h]['invocation_id'])
 assert sorted(map(int,rt['rank_maps']))==list(range(512))and sum(x['role']=='compute'for x in rt['rank_maps'].values())==480
 assert sorted(map(int,rt['owned_field_view_admission']['observed_markers']))==list(range(480,512))and rt['owned_field_view_environment']['expected_literal']=='1'and rt['owned_field_view_environment']['observed_ranks']==512
 assert s['tile_proofs']['status']=='PASS_ACTUAL_480_DISJOINT_TILE_UNIONS_AND_ALL512_OBSERVED_ENVS'and s['tile_proofs']['compute_ranks']==480
 f=lambda p:ast.dump(next(x for x in ast.parse(Path(p).read_text()).body if isinstance(x,ast.FunctionDef)and x.name=='compare_one'),include_attributes=False)
 assert f(B/'check_pair.py')==f(B.parent/'production512-current-uvb-batch3h-runtime-r1/check_pair.py')
 assert all(sha(B/n)==h for n,h in load(B/'source-pins.json').items())
 assert a['pending']is False and a['source_commit']is None and l['source_commit']is None and l['bc_artifact']==a
 assert l['executable_sha256']==a['executable_sha256']=='f4b3c348c12c4863a869a7f9da0ede6516406989758e7a320fb6042ba5ee55c8'and a['archive_sha256']=='a43a8357752c00966880e39951d9bd8036d30a480a2468b98a9673b77b28c7f2'
 assert a['object_sha256']=='adde8c7bac270eeecbdace96492e76cc7c81802cb35e250ae9f38ea04697ff83'and b['calc_php_artifact']['object_sha256']=='271644d493078964eca5b2316556b5db2e59d55a1052398c3a67e5ddfff87a45'
 assert l['calc_php_artifact']==b['calc_php_artifact']and b['calc_php_artifact']['source_commit']is None
 assert l['ng_sha256']=='937130c2a2d53e1d11c978dce1b661400daca9da7b8ae99029333dbc1103d178'and l['shim_sha256']=='51a31b3c137a2161700c9930a1e250021b34c598c887a7551e87d304b2ce4d31'
 for key,native,caller,build in [('bc_artifact','bc-native-qualification.json','bc-official-root-caller-qualification.json','bc-build-qualification.json'),('calc_php_artifact','calc-php-native-qualification.json','calc-php-caller-qualification.json','calc-php-build-qualification.json')]:
  x=b[key];assert sha(B/native)==x['native_qualification_sha256']and sha(B/caller)==x['caller_qualification_sha256']and sha(B/build)==x['build_qualification_sha256']
  for path,h in load(B/build)['raw_refs'].items():assert sha(path)==h,(path,h)
 writers={str(k):rt['shim_lifecycle'][str(k)]for k in [487,495,503,511]}
 for k,v in writers.items():assert v['callbacks']==v['supplied']==v['releases']==v['widens']==v['restores']>0 and v['pending']==v['errors']==0
 memory={};metadata=[]
 for arm in['control','candidate']:
  D=B/(arm+'-metadata');steps=load(D/'adaptive-steps.json');assert len(steps)==545 and steps[-1]['time']=='2026-10-12_09:00:00';nodes={h:load(D/n)for h,n in [('hpc01','mpi-launch.json'),('hpc02','hpc02-node.json'),('hpc03','hpc03-node.json'),('hpc04','hpc04-node.json')]};assert all(x['exit_code']==0 for x in nodes.values())
  cpu=0
  for h in ['hpc01','hpc02','hpc03','hpc04']:cpu+=int(dict(z.split()for z in nodes[h]['cpu_stat'].splitlines())['usage_usec'])/1e6
  m={'wall_seconds':nodes['hpc01']['wall_seconds'],'cpu_seconds':cpu,'main_step_sum_seconds':sum(x['wall_seconds']for x in steps)};assert m==r['metrics'][arm]and all(math.isfinite(x)and x>0 for x in m.values())
  if arm=='candidate':
   for h,x in nodes.items():assert x['invocation_id']==cl[h]['invocation_id'];memory[h]={'limit_bytes':int(l['nodes'][h]['memory_bytes']),'peak_bytes':x['memory_peak_bytes'],'events':dict((k,int(v))for k,v in(z.split()for z in x['memory_events'].splitlines()))}
  metadata +=[D/n for n in ['completion.json','model-closures.json','mpi-launch.json','hpc02-node.json','hpc03-node.json','hpc04-node.json','adaptive-steps.json','cache-start-context.json','lease.json']]
 for x in memory.values():assert isinstance(x['peak_bytes'],int)and 0<x['peak_bytes']<=x['limit_bytes']
 refs=[B/n for n in ['RESULT.json','science-receipt.json','reader-closure.json','source-pins.json','application-binding.json','lease-candidate-proposed.json','cache-clear-candidate.json','launch-candidate.txt','reader-launch-r2.txt','check_pair.py','bc-native-qualification.json','bc-official-root-caller-qualification.json','bc-build-qualification.json','calc-php-native-qualification.json','calc-php-caller-qualification.json','calc-php-build-qualification.json','candidate-closures.json']]+metadata
 refs +=[Path(p)for p in load(B/'bc-build-qualification.json')['raw_refs']if Path(p).name in ['receipt.json','closure.json','ordered-libwrflib-proof.json']]
 assert all(x.is_file()for x in refs)
 grant=load(B/'candidate-metadata/lease.json');assert grant['source_manifest_sha256']==sha(B/'source-pins.json')and grant['executable_sha256']==l['executable_sha256']and grant['run_directory']==l['run_directory']
 assert r['science_sha256']==sha(B/'science-receipt.json')and r['reader_closure_sha256']==sha(B/'reader-closure.json')
 reference=b['latest_original_control'];assert reference['grant_sha256']=='2aefb8b550bf1b05fbed6e8299c68b476ccfb317079bbf3f4453ceb3955a505b'and reference['expected_products']==4 and reference['expected_steps']==545 and reference['wall_cap_seconds']==1200
 assert sha(B/'control-metadata/lease.json')==reference['grant_sha256']
 reductions={k:100*(1-r['metrics']['candidate'][k]/r['metrics']['control'][k])for k in r['metrics']['control']};assert reductions==r['reductions_percent']
 q={'status':'PASS_CURRENT_CALC_PHP_BC_PACKED_COPY_ORIGINAL_FOUR_PRODUCT_545_STEP_APPLICATION','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'candidate_artifacts':{k:l[k]for k in ['executable','executable_sha256','ng_path','ng_sha256','shim_path','shim_sha256']},'bc_producer':a,'calc_php_producer':b['calc_php_artifact'],'distance_codec_producer':b['distance_codec'],'raw_producer_source_commit':None,'own_short_science_qualified':False,'own_threehour_science_qualified':True,'own_ninehour_science_qualified':False,'fresh_control_run':False,'profiling':False,'science':{'products':4,'ordered_steps':545,'last_step':'2026-10-12_09:00:00','world':512,'compute':480,'quilt':32,'tiles':2,'positive_writer_roots':[487,495,503,511],'zero_activity_writer_roots':[],'actual_field_markers':32,'all32_quilt_FIELDVIEW1':True,'protected_compare_one_AST_unchanged':True,'original_comparisons_all_pass':True},'model_invocations':{h:c['invocation_id']for h,c in cl.items()},'reader_invocation_id':reader['invocation_id'],'reader_exit_code_raw':reader['exit_code'],'writer_lifecycle_actual':writers,'input_lifecycle_actual':rt['input_lifecycle'],'candidate_metrics':r['metrics']['candidate'],'retained_original_metrics':r['metrics']['control'],'reductions_percent':reductions,'wall_speedup_ratio':r['metrics']['control']['wall_seconds']/r['metrics']['candidate']['wall_seconds'],'candidate_memory':memory,'reference':reference,'comparison_design':r['comparison_design'],'raw_result_label_disclosure':{'raw_order':r['order'],'correct_current_candidate':'Actual combined calc_php+BC f4b/a43 with all prior changes and selected9371 IO; rawRESULT preserved.'},'limits':['Own direct original4/545 three-hour SCI only; own separate shortFALSE and own9hFALSE. Historical component/application records retain their own scope.','UNPAIRED candidate-only versus retained original2aef; wholeMPI wall/aggregateprocessCPU/main-step elapsed are separate scopes, no matched-new-control/perkernel/isolatedincrement/repeatability claim.','Calc_php96 strict native cases and4096restore+whole calls; BC672cases and262144complete synthetic calls remain separate native/caller scopes, no forecast percent transfer.','RawproducerNULL; posttestsourcecommit pending and separate only after actual root source-only commit. No source/selector mutation by assembler.'],'raw_refs':{str(p):sha(p)for p in sorted(set(refs))}}

 return q
if __name__=='__main__':
 assert not O.exists();q=validate_actual();q['raw_refs'][str(Path(__file__))]=sha(Path(__file__))
 with O.open('x')as f:f.write(json.dumps(q,indent=2)+chr(10))
 print(json.dumps({'qualification':str(O),'sha256':sha(O),'raw_refs':len(q['raw_refs'])}))
