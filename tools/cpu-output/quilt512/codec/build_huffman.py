"""Create-only reproduction of the qualified one-object paired Code/Len codec."""
from pathlib import Path
import json,os,subprocess,hashlib,re,shlex,shutil,time,traceback,argparse
from elf_semantics import compare_objects
S=Path(__file__).resolve().parent
P=Path('/pool/wrf-experiment/wrf-cpu/builds/codec-avx2-caller-specialization-r1')
Z=Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng');G=Path('/pool/wrf-experiment/toolchains/gnu/13.3.0')
LIB='libz.so.1.3.1.zlib-ng';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
ap=argparse.ArgumentParser();ap.add_argument('--output-dir',type=Path,required=True);a=ap.parse_args();D=a.output_dir.absolute()
assert not D.is_symlink()and all(not p.is_symlink()for p in D.parents)
pins=json.loads((S/'source-pins.json').read_text());assert all(sha(S/n)==h for n,h in pins.items());assert not D.exists();D.mkdir(parents=True);start=time.monotonic()
r={'status':'RUNNING','invocation_id':os.environ.get('INVOCATION_ID'),'scope':'Build-only exact881d reproduction; no runtime qualification or activation','source_manifest_sha256':sha(S/'source-pins.json')}
def run(cmd,cwd,label,env):
 with(D/(label+'.stdout')).open('w')as out,(D/(label+'.stderr')).open('w')as err:z=subprocess.run(list(map(str,cmd)),cwd=cwd,env=env,stdout=out,stderr=err,timeout=120)
 assert z.returncode==0,(label,z.returncode,(D/(label+'.stderr')).read_text()[-4096:]);return(D/(label+'.stdout')).read_text()
try:
 assert sha(P/'receipt.json')=='49668156237de1f04f30c0971be2279ce8cce09641ef862c6e24d2542d08a6e6'and sha(P/'closure.json')=='bf89fa259cdcf64bb92d41a03705f516014b7b60046bf2a7250dfcec04390b53'
 pr=json.loads((P/'receipt.json').read_text());pc=json.loads((P/'closure.json').read_text());assert pc['invocation_id']==pr['invocation_id']and pc['actual_properties']['MainPID']=='0'and pc['actual_properties']['Result']=='success'and not pc['cgroup_processes']
 b=P/'build';assert sha(b/LIB)=='f85f24ba39b67ddb799b3bfcd7e01f9e1c0371fdac24ba7f0e6f400105bc738d';assert sha(b/'trees.lo')=='fd176126c965cf4f232fe914b16f1694952b1db4381c6f3a33b9813d7a40e567'
 m=json.loads((S/'original-build-metadata.json').read_text());assert sha(m['compiler_path'])==m['compiler_sha256']and sha(b/'Makefile')==m['makefile_sha256'];objects=dict(m['pic_objects'])
 for path,h in pr['artifacts'].items():
  p=Path(path)
  if p.is_relative_to(b)and str(p.relative_to(b))in objects:objects[str(p.relative_to(b))]=h
 assert len(objects)==71 and all(sha(b/n)==h for n,h in objects.items())
 for n,h in m['source_headers'].items():assert sha(Z/'source'/n)==h,n
 assert sha(S/'parent_trees.c')==sha(Z/'source/trees.c')
 proof=json.loads((S/'huffman-source-proof.json').read_text());assert proof['full_header_inverse_exact'];assert sha(Z/'source/trees_emit.h')==proof['parent_sha256']and sha(S/'candidate_trees_emit.h')==proof['candidate_sha256']
 var=lambda name:shlex.split(re.search(r'^'+re.escape(name)+r'=(.*)$',m['makefile'],re.M)[1]);flags=var('SFLAGS');includes=var('INCLUDES');assert not any(x.startswith(('-march','-mtune','-mavx','-mbmi'))for x in flags)and not any('ZLIB_DEBUG'in x for x in flags)
 env=os.environ.copy();env['PATH']=str(G/'bin')+':'+env['PATH'];env['LD_LIBRARY_PATH']=str(G/'lib64')+':'+str(G/'deps/lib');env.pop('LD_PRELOAD',None)
 work=D/'build';shutil.copytree(b,work,symlinks=True);src=D/'source';src.mkdir();shutil.copyfile(S/'parent_trees.c',src/'trees.c');shutil.copyfile(S/'candidate_trees_emit.h',src/'trees_emit.h');commands=[]
 def compile_one(source,target,label,extra=()):
  cmd=[m['compiler_path'],*flags,'-DPIC',*includes,*extra,'-c',source,'-o',target];commands.append(list(map(str,cmd)));return run(cmd,work,label,env)
 parent_obj=D/'fresh-parent-trees.lo';compile_one(Z/'source/trees.c',parent_obj,'compile-parent');parentproof=compare_objects(b/'trees.lo',parent_obj);(D/'parent-code-equivalence.json').write_text(json.dumps(parentproof,indent=2)+'\n')
 compile_one(src/'trees.c',work/'trees.lo','compile-candidate');assert sha(work/'trees.lo')!=objects['trees.lo']
 linked=pr['ordered_shared_link_inputs'];assert len(linked)==52 and len(set(linked))==52
 (work/LIB).unlink();link=['make',*[x for n in objects for x in ['-o',n]],LIB];run(link,work,'relink',env);diff=sorted(n for n,h in objects.items()if sha(work/n)!=h);assert diff==['trees.lo'];assert all(sha(b/n)==h for n,h in objects.items())
 def exports(q):return sorted(' '.join(x.split()[1:])for x in subprocess.check_output(['nm','-D','--defined-only',str(q)],text=True).splitlines())
 def dynamic(q):return re.findall(r'\((NEEDED|SONAME)\).*?\[(.*?)\]',subprocess.check_output(['readelf','-d',str(q)],text=True))
 assert exports(b/LIB)==exports(work/LIB)and dynamic(b/LIB)==dynamic(work/LIB)
 assert all(sha(S/n)==h for n,h in pins.items())
 assert sha(work/LIB)==json.loads((S/'selection.json').read_text())['variants']['huffman']['sha256'],'Private build must reproduce qualified881d bytes'
 r.update(matches_qualified_library=True,status='BUILD_PASS_HUFFMAN_CODEC_REPRODUCES_QUALIFIED_BYTES',parent_library_sha256=sha(b/LIB),candidate_library_sha256=sha(work/LIB),parent_object_reproduction=parentproof,compile_commands=commands,codec_link_command=link,changed_objects=diff,unchanged_pic_objects=70,total_pic_objects=71,ordered_shared_link_inputs=linked,shared_link_input_count=52,unchanged_shared_link_inputs=51,exports_unchanged=True,dynamic_dependencies_unchanged=True,artifacts={str(q):sha(q)for q in [work/LIB,work/'trees.lo',src/'trees_emit.h',D/'parent-code-equivalence.json']})
except BaseException:r.update(status='FAIL',error=traceback.format_exc());raise
finally:
 r.update(elapsed_seconds=time.monotonic()-start);(D/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
