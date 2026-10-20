from pathlib import Path
import os,json,hashlib,shutil,subprocess,shlex,re,time,argparse
S=Path(__file__).resolve().parent
Z=Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng')
ap=argparse.ArgumentParser();ap.add_argument('--output-dir',type=Path,required=True);ap.add_argument('--variant',choices=['slide-hash','huffman','guarded','inline'],default='slide-hash');a=ap.parse_args();
if a.variant in ['slide-hash','huffman','guarded']:
 import sys
 sys.exit(subprocess.call([sys.executable,str(S/({'slide-hash':'build_slide_hash.py','huffman':'build_huffman.py','guarded':'build_guarded.py'}[a.variant])),'--output-dir',str(a.output_dir)]))
D=a.output_dir.absolute();assert not D.is_symlink()and all(not p.is_symlink()for p in D.parents)
LIB='libz.so.1.3.1.zlib-ng'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for n,h in json.loads((S/'source-pins.json').read_text()).items():assert sha(S/n)==h,n
assert not D.exists();D.mkdir(parents=True)
r={'status':'FAIL','invocation_id':os.environ.get('INVOCATION_ID'),'source_manifest_sha256':sha(S/'source-pins.json'),'started_monotonic':time.monotonic()}
try:
 m=json.loads((S/'original-build-metadata.json').read_text());b=Z/'build';src=Z/'source'
 assert sha(b/'Makefile')==m['makefile_sha256'] and sha(m['compiler_path'])==m['compiler_sha256']
 for n,h in m['source_headers'].items():assert sha(src/n)==h,n
 for n,h in m['pic_objects'].items():assert sha(b/n)==h,n
 assert sha(Z/'install/lib'/LIB)=='5d69c44314f30e4a6f6c76ee26a454538f7e1b019afe5782e67a6b94ba794b64'
 proof=json.loads((S/'candidate-proof.json').read_text());old=(S/'parent_deflate_fast.c').read_text();new=(S/'candidate_deflate_fast.c').read_text()
 helper=new[new.index('static inline Pos '):new.index('/* ===========================================================================')]
 assert new.replace(helper,'',1).replace('deflate_fast_quick_insert_string(s,','quick_insert_string(s,')==old
 assert sha(src/'deflate_fast.c')==proof['parent_sha256']==sha(S/'parent_deflate_fast.c')
 work=D/'build';shutil.copytree(b,work,symlinks=True)
 candidate=D/'deflate_fast.c';shutil.copyfile(S/'candidate_deflate_fast.c',candidate)
 makefile=m['makefile'];flags=shlex.split(re.search(r'^SFLAGS=(.*)$',makefile,re.M)[1]);includes=shlex.split(re.search(r'^INCLUDES=(.*)$',makefile,re.M)[1])
 env=json.loads(subprocess.check_output(['bash','-c','source "$1"; python3 -c "import os,json;print(json.dumps(dict(os.environ)))"','env','/pool/wrf-experiment/toolchains/gnu/13.3.0/env.sh'],text=True))
 argv=[m['compiler_path'],*flags,'-DPIC',*includes,'-c','-o',str(work/'deflate_fast.lo'),str(candidate)]
 with (D/'build.log').open('w')as log:
  subprocess.run(argv,cwd=work,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=60)
  (work/LIB).unlink()
  link=['make',*[x for n in m['pic_objects']for x in ['-o',n]],LIB]
  subprocess.run(link,cwd=work,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=60)
 differences=[n for n,h in m['pic_objects'].items()if sha(work/n)!=h];assert differences==['deflate_fast.lo'],differences
 for n,h in m['pic_objects'].items():assert sha(b/n)==h,n
 for n,h in m['source_headers'].items():assert sha(src/n)==h,n
 def exports(p):
  return sorted(' '.join(x.split()[1:])for x in subprocess.check_output(['nm','-D','--defined-only',str(p)],text=True).splitlines())
 def dynamic(p):
  return re.findall(r'\((NEEDED|SONAME)\).*?\[(.*?)\]',subprocess.check_output(['readelf','-d',str(p)],text=True))
 original=Z/'install/lib'/LIB;candidate_lib=work/LIB
 assert exports(original)==exports(candidate_lib)
 assert dynamic(original)==dynamic(candidate_lib)
 asm=subprocess.check_output(['objdump','-d','--disassemble=deflate_fast',str(candidate_lib)],text=True);(D/'deflate_fast.asm').write_text(asm)
 assert not any('call'in l and 'quick_insert_string'in l for l in asm.splitlines()),'insertion call not eliminated'
 r.update(status='BUILD_PASS_PENDING_EXACT_CODEC_CALLER',compile_command=argv,link_command=link,unchanged_pic_objects=70,total_pic_objects=71,changed_objects=differences,codegen_insertion_calls_removed=True,exports_unchanged=True,dynamic_dependencies_unchanged=True,artifacts={str(p):sha(p)for p in [candidate,work/'deflate_fast.lo',candidate_lib,D/'deflate_fast.asm']},original_library_sha256=sha(original),matches_qualified_library=sha(candidate_lib)==json.loads((S/'selection.json').read_text())['variants']['inline']['sha256'])
 assert r['matches_qualified_library'],'Private rebuild must reproduce qualified library bytes'
except BaseException as e:
 r.update(status='FAIL',error=repr(e));raise
finally:
 r['elapsed_seconds']=time.monotonic()-r['started_monotonic'];(D/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
