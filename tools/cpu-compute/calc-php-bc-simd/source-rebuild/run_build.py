"""Create-only canonical two-module source reproduction; one ordinary WRF link, no execution."""
from pathlib import Path
import os,json,hashlib,subprocess,time,socket,shutil,traceback,shlex
import canonical_compile as cc
from elf_semantics import compare_objects
from archive_occurrences import inventory,verify_only
P=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def closed(r,c):
 assert r['invocation_id']==c['invocation_id']
 assert c['properties']['MainPID']=='0'and c['properties']['ActiveState']=='inactive'and c['properties']['Result']=='success'and c['properties']['ExecMainStatus']=='0'
 assert c['cgroup_paths_absent']and not c['cgroup_processes']
 assert any(e['invocation_id']==r['invocation_id']and'Deactivated successfully.'in e['message']for e in c['manager_events'])
def main():
 q=json.loads((P/'REBUILD_RECIPE.json').read_text());assert q['ready']is True and q['root_authorized']is True and q['source_commit']is None
 assert socket.gethostname().split('.')[0]==q['host']and sorted(os.sched_getaffinity(0))==q['cpus']and not os.environ.get('LD_PRELOAD')
 cg=Path('/sys/fs/cgroup'+Path('/proc/self/cgroup').read_text().strip().split('::')[-1]);a,b=map(int,(cg/'cpu.max').read_text().split());assert a==2*b and int((cg/'memory.max').read_text())==8*2**30 and(cg/'memory.swap.max').read_text().strip()=='0'
 pins=json.loads((P/'manifest.json').read_text())['files'];assert all(sha(P/n)==h for n,h in pins.items())
 D=Path(q['output']);assert not D.exists();D.mkdir();(D/'logs').mkdir();start=time.monotonic();r={'status':'FAIL_RETAINED_NO_RETRY','invocation_id':os.environ['INVOCATION_ID'],'commands':[],'source_commit':None,'application_science_qualified':False};env={k:v for k,v in os.environ.items()if k in ['PATH','HOME','USER','LOGNAME','SHELL','LANG','TMPDIR']or k.startswith('LC_')}
 def run(argv,label,cwd,out=None,stdin=None):
  remaining=580-(time.monotonic()-start);assert remaining>0
  z=subprocess.run(list(map(str,argv)),cwd=cwd,env=env,input=None if stdin is None else Path(stdin).read_bytes(),capture_output=True,timeout=min(180,remaining));log=D/'logs'/(label+'.log');log.write_bytes(z.stderr if out is not None else z.stdout+z.stderr)
  r['commands'].append({'label':label,'argv':list(map(str,argv)),'returncode':z.returncode,'log_sha256':sha(log)});assert z.returncode==0,(label,z.stderr[-2000:])
  if out is not None:Path(out).write_bytes(z.stdout)
  return z.stdout.decode()
 try:
  bc=json.loads((P/'bc-recipe.json').read_text());calc=json.loads((P/'calc-recipe.json').read_text());pr=json.loads((P/'original-build-receipt.json').read_text());closed(pr,json.loads((P/'original-build-closure.json').read_text()))
  natives={}
  for kind in ['bc','calc']:
   n=json.loads((P/(kind+'-native-receipt.json')).read_text());closed(n,json.loads((P/(kind+'-native-closure.json')).read_text()));assert n['status'].startswith('PASS_');natives[kind]=n
  assert natives['bc']['strict_current_parent_reproduction']and natives['bc']['flag_only_allocated_ABI_unchanged']and all(x['cases']==672 and x['raw_and_five_state']=='PASS'for x in natives['bc']['caller_results'].values())
  assert natives['calc']['cases']==96 and natives['calc']['public_module_interface_exact']and natives['calc']['source_inverse_exact']
  A=Path(calc['parent_archive']);E=Path(calc['parent_executable']);assert sha(A)==calc['parent_archive_sha256']and sha(E)==calc['parent_executable_sha256'];before=inventory(A);assert before==json.loads((P/'original-ordered-proof.json').read_text())['candidate']and len(before)==584
  assert before[116]['name']=='module_bc.o'and before[116]['sha256']==bc['parent_member_sha256'];assert before[559]['name']=='module_big_step_utilities_em.o'and before[559]['sha256']==calc['parent_member_sha256']
  inputs={}
  for k in ['unchanged_main_objects','unchanged_owner_helper_inputs','unchanged_nonmain_link_inputs','unchanged_IO_archive']:
   assert bc[k]==calc[k];inputs.update(calc[k])
  assert all(sha(f)==h for f,h in inputs.items())
  script='import os,json;print(json.dumps({k:os.environ[k]for k in ["PATH","LD_LIBRARY_PATH","OPAL_PREFIX"]if k in os.environ}))'
  safe=D/'safe-env.json';run(['/bin/bash','-c','source "$1";python3 -c "$2"','env','/pool/wrf-experiment/tooling/m6-parallel/mpi-ib-env.sh',script],'qualified-env',D,safe);env.update(json.loads(safe.read_text()));env.update(bc['qualified_core_environment']);assert env.get('WRF_PLUS_CORE')=='0'
  support=Path(bc['support']);assert support==Path(calc['support'])and sha(support/'configure.wrf')==sha(P/'configure.wrf.qualified')==bc['qualified_configuration_sha256']==calc['qualified_configuration_sha256'];assert sha(support/'compile')==bc['qualified_compile_frontend_sha256']==calc['qualified_compile_frontend_sha256']
  v=cc.expand(support,P/'configure.wrf.qualified',D,run);assert v==natives['bc']['expanded_current_generic_flags'];original_v=dict(v)
  objects={};r['source_reproductions']={}
  for kind,stem,recipe in [('calc','module_big_step_utilities_em',calc),('bc','module_bc',bc)]:
   parent=P/('parent_'+stem+'.F');child=P/('candidate_'+stem+'.F');assert sha(parent)==recipe['canonical_parent_sha256']and sha(child)==recipe['canonical_candidate_sha256']
   directive='!$OMP SIMD PRIVATE(bc_source)\n'if kind=='bc'else'!$OMP SIMD\n';assert child.read_text().replace(directive,'',1)==parent.read_text()
   work=D/kind;work.mkdir();flags=v if kind=='bc'else json.loads((P/'calc-canonical-flags.json').read_text())['expanded_canonical_flags'];pp=cc.preprocess(child,stem,work,support,flags,False,run,'preprocess-'+kind);assert sha(pp)==recipe['preprocessed_candidate_sha256'],'Canonical source PP mismatch; no normalization'
   if kind=='bc':
    local=dict(v);local['FCFLAGS']=v['FCFLAGS']+' -fopenmp-simd';obj=cc.compile_f(pp,stem,work,support,local,[],run,'compile-bc')
   else:
    argv=natives['calc']['native_flags'];assert all(x in argv for x in ['-O2','-fopenmp-simd','-fno-fast-math','-ffp-contract=off']);assert not any(x.startswith(('-march','-mtune','-mavx','-mfma','-ffast-math'))for x in argv)
    run(['/pool/wrf-experiment/toolchains/gnu/13.3.0/mpi-ucx-xpmem/bin/mpif90',*argv,'-c',stem+'.f90','-o',stem+'.o'],'compile-calc',work);obj=work/(stem+'.o')
   ref=Path(recipe['qualified_object']);assert sha(ref)==recipe['qualified_object_sha256'];semantic=compare_objects(ref,obj);proof=work/'allocated-equivalence.json';proof.write_text(json.dumps(semantic,indent=2)+'\n');mod=work/(stem+'.mod');assert sha(mod)==recipe['module_interface_sha256'];objects[kind]=obj
   r['source_reproductions'][kind]={'canonical_source_sha256':sha(child),'preprocessed_sha256':sha(pp),'object_sha256':sha(obj),'qualified_reference_sha256':sha(ref),'allocated_relocations_nonfile_symbols_exact':True,'module_sha256':sha(mod),'semantic_proof_sha256':sha(proof)}
  assert v==original_v,'Global flags mutated'
  shutil.copy2(A,D/'libwrflib.a');intermediate=D/'after-calc.a'
  run(['/usr/bin/ar','r',D/'libwrflib.a',objects['calc']],'replace-calc',D);run(['/usr/bin/ranlib',D/'libwrflib.a'],'index-calc',D);verify_only(A,D/'libwrflib.a','module_big_step_utilities_em.o',objects['calc']);shutil.copy2(D/'libwrflib.a',intermediate)
  run(['/usr/bin/ar','r',D/'libwrflib.a',objects['bc']],'replace-bc',D);run(['/usr/bin/ranlib',D/'libwrflib.a'],'index-bc',D);verify_only(intermediate,D/'libwrflib.a','module_bc.o',objects['bc']);after=inventory(D/'libwrflib.a')
  assert len(after)==584 and all(x==y for i,(x,y)in enumerate(zip(before,after))if i not in [116,559]);assert after[116]['sha256']==sha(objects['bc'])and after[559]['sha256']==sha(objects['calc'])
  proof=D/'ordered-libwrflib-proof.json';proof.write_text(json.dumps({'parent':before,'candidate':after,'replaced_indices':[116,559],'unchanged_occurrences':582},indent=2)+'\n')
  link=list(pr['link_command']);assert link[1:3]==['-o',str(E)]and link.count(str(A))==1;link[2]=str(D/'wrf.exe');link=[str(D/'libwrflib.a')if x==str(A)else x for x in link];assert all(link.count(f)==pr['link_command'].count(f)for f in inputs);run(link,'one-ordinary-combined-link',D)
  assert sha(A)==calc['parent_archive_sha256']and sha(E)==calc['parent_executable_sha256']and inventory(A)==before and all(sha(f)==h for f,h in inputs.items())
  r.update(status=q['status_after_success'],source_compiles=2,full_WRF_links=1,qualified_objects_copied=False,unchanged_archive_occurrences=582,module_local_new_flag_only_BC='-fopenmp-simd',existing_calc_flags_preserved=True,link_command=link,artifacts={str(D/n):sha(D/n)for n in ['wrf.exe','libwrflib.a','ordered-libwrflib-proof.json']})
 except BaseException as e:r.update(error=repr(e),traceback=traceback.format_exc())
 finally:
  r['elapsed_seconds_context_only']=time.monotonic()-start;r['source_pins_after']={n:sha(P/n)for n in pins};assert r['source_pins_after']==pins;(D/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'status':r['status'],'error':r.get('error'),'build_directory':str(D)}),flush=True)
 if not r['status'].startswith('BUILT_'):raise SystemExit(1)
if __name__=='__main__':main()
