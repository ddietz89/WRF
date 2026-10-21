"""Reproduce qualified private FAST distance9371 from exact retained e1d8 inputs.
No WRF rebuild, timing, science acceptance or source-commit inference.
"""
from pathlib import Path
import argparse,json,hashlib,subprocess,shutil,shlex,re,os,time,traceback
S=Path(__file__).resolve().parent;C=S/'private-fast-distance-range';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True,type=Path);a=ap.parse_args();D=a.output_dir.absolute();assert not D.exists()and not D.is_symlink()and all(not p.is_symlink()for p in D.parents)
for n,h in json.loads((S/'source-pins.json').read_text()).items():assert sha(S/n)==h,n
D.mkdir(parents=True);r={'status':'FAIL_RETAINED_NO_RETRY','invocation_id':os.environ.get('INVOCATION_ID'),'source_commit':None,'application_science_qualified':False,'commands':[]};start=time.monotonic()
try:
 meta=json.loads((S/'original-build-metadata.json').read_text());arch=json.loads((S/'arch-build-metadata.json').read_text());ordered=json.loads((C/'parent-ordered-inputs.json').read_text());P=D/'parent-source-build'/'build';LIB='libz.so.1.3.1.zlib-ng';names=ordered['ordered_shared_link_inputs'];expected=ordered['object_sha256'];assert len(names)==len(set(names))==52 and set(names)==set(expected)
 # Invoke the unchanged parent source builder in fresh output, never require an orphaned e1d8 objectdir.
 parent_builder=S/'build_compress_block.py';assert sha(parent_builder)=='1bd199c6171bd374be1175c3fc328495ba78404262854baa41f900abd7c8a2a4'
 parentenv={k:v for k,v in os.environ.items()if k not in ['LD_PRELOAD','LD_LIBRARY_PATH']}
 pa=['/usr/bin/python3',str(parent_builder),'--output-dir',str(D/'parent-source-build')]
 z=subprocess.run(pa,env=parentenv,capture_output=True,text=True,timeout=90);(D/'parent-source-builder.stdout').write_text(z.stdout);(D/'parent-source-builder.stderr').write_text(z.stderr);r['commands'].append({'label':'invoke-unchanged-parent-source-builder','argv':pa,'returncode':z.returncode});assert z.returncode==0,z.stderr[-2000:]
 pr=json.loads((D/'parent-source-build/receipt.json').read_text());assert pr['status']=='BUILD_PASS_EXACT_COMPRESS_BLOCK_CARRY_REPRODUCTION'and pr['candidate_library_sha256']=='e1d8bc0774b7c54b4b63e7d6892c6485bec9b3c7032985a229961ba0569cc450'
 r['parent_source_build']={'builder_sha256':sha(parent_builder),'receipt_path':str(D/'parent-source-build/receipt.json'),'receipt_sha256':sha(D/'parent-source-build/receipt.json'),'scope':'Fresh trees sourcecompile+52link via unchanged qualified parentbuilder; that existingbuilder honestly depends on pinned3edf/source/toolchain inputs in its REPRODUCTION_INPUTS. No orphaned e1d8directory dependency.'}
 assert sha(P/LIB)==ordered['parent_library_sha256']=='e1d8bc0774b7c54b4b63e7d6892c6485bec9b3c7032985a229961ba0569cc450';assert all(sha(P/n)==expected[n]for n in names)
 assert sha(S/'candidate_compare256_avx2.c')=='1bb168cb744f6bb18927aa4f9f49fd15bdfd0c3ec855cc7174f46cdd522cdc1b'and sha(S/'deflate_fast_shared.h')=='7c9f3c9204ff84ca8d7189768941e7ff9939d210a7e627886c6f5dd699562af1'
 proof=json.loads((C/'SOURCE_PROOF.json').read_text());assert proof['inverse_exact']and all(sha(C/n)==h for n,h in proof['files_sha256'].items()if n in ['candidate_compare256_avx2.c','deflate_fast_shared.h'])
 cc=meta['compiler_path'];assert sha(cc)==meta['compiler_sha256']=='360898b5e41799b7a5fcaf7acb2dfb4cab0017c5b3debc91e330636f1d0d37b9';src=Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng/source');gen=src.parent/'build'
 for n,h in arch['source_headers'].items():assert sha(src/n)==h,n
 var=lambda text,n:shlex.split(re.search(r'^'+n+r'=(.*)$',text,re.M)[1]);flags=var(arch['arch_makefile'],'SFLAGS');isa=var(arch['arch_makefile'],'AVX2FLAG');assert isa==['-mavx2','-mbmi2']and var(arch['arch_makefile'],'NOLTOFLAG')==['-fno-lto'];inc=['-I'+str(gen),'-I'+str(src),'-I'+str(src/'arch/x86')]
 env={k:v for k,v in os.environ.items()if k not in ['LD_PRELOAD','LD_LIBRARY_PATH']};env.update(PATH='/pool/wrf-experiment/toolchains/gnu/13.3.0/bin:'+env.get('PATH',''),LD_LIBRARY_PATH='/pool/wrf-experiment/toolchains/gnu/13.3.0/lib64:/pool/wrf-experiment/toolchains/gnu/13.3.0/deps/lib')
 def run(argv,label,cwd=None):
  z=subprocess.run(list(map(str,argv)),env=env,cwd=cwd or D,capture_output=True,text=True,timeout=min(60,max(1,170-(time.monotonic()-start))));(D/(label+'.stdout')).write_text(z.stdout);(D/(label+'.stderr')).write_text(z.stderr);r['commands'].append({'label':label,'argv':list(map(str,argv)),'returncode':z.returncode});assert z.returncode==0,(label,z.stderr[-2000:]);return z.stdout
 assert '13.3.0'in run([cc,'--version'],'compiler-version');B=D/'build';B.mkdir()
 for n in names:f=B/n;f.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(P/n,f)
 def compile_one(mode,source,header):
  d=D/(mode+'-source');d.mkdir();shutil.copyfile(source,d/'compare256_avx2.c');shutil.copyfile(header,d/'deflate_fast_shared.h');out=D/(mode+'-compare256_avx2.lo');run([cc,*flags,*isa,'-fno-lto','-DPIC',*inc,'-c',d/'compare256_avx2.c','-o',out],'compile-'+mode);return out
 def link(out,label):run([cc,*var(meta['makefile'],'CFLAGS'),'-shared','-Wl,-soname,libz.so.1','-Wl,--version-script,'+str(gen/'zlib.map'),'-o',out,*[B/n for n in names]],label)
 parent=compile_one('parent',S/'candidate_compare256_avx2.c',S/'deflate_fast_shared.h');assert sha(parent)==expected['compare256_avx2.lo']=='6b297292d4753341901c72dcca22568219b0b71fa219197d38805811c968c763';link(D/'parent-library.so','link-exact-parent');assert sha(D/'parent-library.so')==ordered['parent_library_sha256']
 candidate=compile_one('candidate',C/'candidate_compare256_avx2.c',C/'deflate_fast_shared.h');assert sha(candidate)=='9c528a300ee599e74de3e6d8605df98d48e23e4f8e96ffd2c6aee4c0a20cc9d1';shutil.copyfile(candidate,B/'compare256_avx2.lo');(B/'arch/x86').mkdir(parents=True,exist_ok=True);shutil.copyfile(candidate,B/'arch/x86/compare256_avx2.lo');link(B/LIB,'link-one-candidate');assert sha(B/LIB)=='937130c2a2d53e1d11c978dce1b661400daca9da7b8ae99029333dbc1103d178'
 changed=[n for n,h in expected.items()if sha(B/n)!=h];assert changed==['compare256_avx2.lo']and all(sha(P/n)==h for n,h in expected.items())
 exports=lambda p:sorted(' '.join(x.split()[1:])for x in subprocess.check_output(['nm','-D','--defined-only',p],text=True).splitlines());dynamic=lambda p:re.findall(r'\((NEEDED|SONAME)\).*?\[(.*?)\]',subprocess.check_output(['readelf','-d',p],text=True));assert exports(P/LIB)==exports(B/LIB)and dynamic(P/LIB)==dynamic(B/LIB)
 r.update(status='BUILD_PASS_PRIVATE_DISTANCE9371_REPRODUCES_EXACT_NATIVE_NO_APPLICATION_CLAIM',parent_library_sha256=sha(D/'parent-library.so'),candidate_library_sha256=sha(B/LIB),parent_object_sha256=sha(parent),candidate_object_sha256=sha(candidate),ordered_shared_link_inputs=names,unchanged_shared_link_inputs=51,changed_shared_link_inputs=changed,parent_reproduction_compiles=1,candidate_production_compiles=1,whole_WRF_compiles=0,whole_WRF_links=0,exports_unchanged=True,dependencies_unchanged=True,artifacts={str(p):sha(p)for p in [B/LIB,B/'compare256_avx2.lo',B/'arch/x86/compare256_avx2.lo',D/'parent-library.so']})
except BaseException as e:r.update(error=repr(e),traceback=traceback.format_exc());raise
finally:
 r['elapsed_seconds_context_only']=time.monotonic()-start;(D/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r),flush=True)
