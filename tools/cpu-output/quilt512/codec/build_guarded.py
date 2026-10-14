from pathlib import Path
import os,socket,json,hashlib,shutil,subprocess,shlex,re,time
S=Path(__file__).resolve().parent;Z=Path('/pool/wrf-experiment/builds/cpu-investigation/zlib-ng')
import argparse
ap=argparse.ArgumentParser();ap.add_argument('--output-dir',type=Path,required=True);a=ap.parse_args();D=a.output_dir.absolute();assert not D.is_symlink()and all(not x.is_symlink()for x in D.parents)
LIB='libz.so.1.3.1.zlib-ng'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for n,h in json.loads((S/'source-pins.json').read_text()).items():assert sha(S/n)==h,n
assert not D.exists();D.mkdir(parents=True);start=time.monotonic();r={'status':'FAIL','invocation_id':os.environ.get('INVOCATION_ID'),'source_manifest_sha256':sha(S/'source-pins.json')}
try:
 b=Z/'build';src=Z/'source';m=json.loads((S/'original-build-metadata.json').read_text());am=json.loads((S/'arch-build-metadata.json').read_text());objects=dict(m['pic_objects'])
 linked=['arch/generic/adler32_c.lo', 'arch/generic/adler32_fold_c.lo', 'arch/generic/chunkset_c.lo', 'arch/generic/compare256_c.lo', 'arch/generic/crc32_braid_c.lo', 'arch/generic/crc32_fold_c.lo', 'arch/generic/slide_hash_c.lo', 'adler32.lo', 'compress.lo', 'crc32.lo', 'crc32_braid_comb.lo', 'deflate.lo', 'deflate_fast.lo', 'deflate_huff.lo', 'deflate_medium.lo', 'deflate_quick.lo', 'deflate_rle.lo', 'deflate_slow.lo', 'deflate_stored.lo', 'functable.lo', 'infback.lo', 'inflate.lo', 'inftrees.lo', 'insert_string.lo', 'insert_string_roll.lo', 'trees.lo', 'uncompr.lo', 'zutil.lo', 'arch/generic/crc32_chorba_c.lo', 'cpu_features.lo', 'x86_features.lo', 'chunkset_sse2.lo', 'chorba_sse2.lo', 'compare256_sse2.lo', 'slide_hash_sse2.lo', 'adler32_ssse3.lo', 'chunkset_ssse3.lo', 'chorba_sse41.lo', 'adler32_sse42.lo', 'crc32_pclmulqdq.lo', 'slide_hash_avx2.lo', 'chunkset_avx2.lo', 'compare256_avx2.lo', 'adler32_avx2.lo', 'adler32_avx512.lo', 'chunkset_avx512.lo', 'compare256_avx512.lo', 'adler32_avx512_vnni.lo', 'crc32_vpclmulqdq.lo', 'gzlib.lo', 'gzread.lo', 'gzwrite.lo']
 assert len(objects)==71 and sha(b/LIB)=='5d69c44314f30e4a6f6c76ee26a454538f7e1b019afe5782e67a6b94ba794b64'
 assert sha(b/'Makefile')==m['makefile_sha256']and sha(m['compiler_path'])==m['compiler_sha256']and sha(b/'arch/x86/Makefile')==am['arch_makefile_sha256']
 for n,h in objects.items():assert sha(b/n)==h,n
 for n,h in am['source_headers'].items():assert sha(src/n)==h,n
 proof=json.loads((S/'guarded-candidate-proof.json').read_text());assert proof['shared_caller_inverse_exact']and proof['original_avx2_source_inverse_exact']
 old=(S/'parent_inline_deflate_fast.c').read_text();prefix,body=old.split('#include "functable.h"\n');assert prefix+'#include "functable.h"\n'+(S/'deflate_fast_shared.h').read_text().replace('ZNG_PRIVATE_FAST_MATCH(s, hash_head)','FUNCTABLE_CALL(longest_match)(s, hash_head)')==old
 assert sha(S/'parent_inline_deflate_fast.c')==proof['parent_caller_sha256']and sha(src/'arch/x86/compare256_avx2.c')==proof['parent_avx2_sha256']
 work=D/'build';shutil.copytree(b,work,symlinks=True);ownsrc=D/'source';(ownsrc/'arch/x86').mkdir(parents=True)
 for source,target in [('candidate_guarded_deflate_fast.c','deflate_fast.c'),('candidate_compare256_avx2.c','arch/x86/compare256_avx2.c'),('deflate_fast_shared.h','deflate_fast_shared.h')]:shutil.copyfile(S/source,ownsrc/target)
 (ownsrc/'arch/x86/deflate_fast_shared.h').symlink_to('../../deflate_fast_shared.h');assert (ownsrc/'arch/x86/deflate_fast_shared.h').resolve()==ownsrc/'deflate_fast_shared.h'
 var=lambda text,name:shlex.split(re.search(r'^'+re.escape(name)+r'=(.*)$',text,re.M)[1])
 flags=var(m['makefile'],'SFLAGS');aflags=var(am['arch_makefile'],'SFLAGS');isa=var(am['arch_makefile'],'AVX2FLAG');nolto=var(am['arch_makefile'],'NOLTOFLAG');assert flags==aflags and isa==['-mavx2','-mbmi2']and nolto==['-fno-lto']and not any('ZLIB_DEBUG'in x for x in flags)
 env=json.loads(subprocess.check_output(['bash','-c','source "$1"; python3 -c "import os,json;print(json.dumps(dict(os.environ)))"','env','/pool/wrf-experiment/toolchains/gnu/13.3.0/env.sh'],text=True))
 commands=[[m['compiler_path'],*flags,'-DPIC',*var(m['makefile'],'INCLUDES'),'-c','-o',str(work/'deflate_fast.lo'),str(ownsrc/'deflate_fast.c')],[m['compiler_path'],*aflags,*isa,*nolto,'-DPIC',*var(am['arch_makefile'],'INCLUDES'),'-c','-o',str(work/'arch/x86/compare256_avx2.lo'),str(ownsrc/'arch/x86/compare256_avx2.c')]]
 with(D/'build.log').open('w')as log:
  for argv,cwd in zip(commands,[work,work/'arch/x86']):subprocess.run(argv,cwd=cwd,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=60)
  shutil.copyfile(work/'arch/x86/compare256_avx2.lo',work/'compare256_avx2.lo')
  (work/LIB).unlink();link=['make',*[x for n in objects for x in ['-o',n]],LIB];subprocess.run(link,cwd=work,env=env,stdout=log,stderr=subprocess.STDOUT,check=True,timeout=45)
 differences=[n for n,h in objects.items()if sha(work/n)!=h];assert sorted(differences)==['arch/x86/compare256_avx2.lo','compare256_avx2.lo','deflate_fast.lo']
 for n,h in objects.items():assert sha(b/n)==h,n
 for n,h in am['source_headers'].items():assert sha(src/n)==h,n
 def exports(p):return sorted(' '.join(x.split()[1:])for x in subprocess.check_output(['nm','-D','--defined-only',str(p)],text=True).splitlines())
 def dynamic(p):return re.findall(r'\((NEEDED|SONAME)\).*?\[(.*?)\]',subprocess.check_output(['readelf','-d',str(p)],text=True))
 original=b/LIB;lib=work/LIB;assert exports(original)==exports(lib)and dynamic(original)==dynamic(lib)
 assemblies={}
 for name in ['deflate_fast','zng_private_deflate_fast_generic','zng_private_deflate_fast_avx2','longest_match_avx2','longest_match_slow_avx2']:
  text=subprocess.check_output(['objdump','-d','--no-show-raw-insn','--disassemble='+name,str(lib)],text=True);(D/(name+'.asm')).write_text(text);assemblies[name]=text
 generic_object=subprocess.check_output(['objdump','-d','--no-show-raw-insn',str(work/'deflate_fast.lo')],text=True);(D/'generic-object.asm').write_text(generic_object)
 instructions=lambda text:re.findall(r'^\s*[0-9a-f]+:\s+(\S+)\s*(.*)$',text,re.M)
 assert not any(op.startswith('v')for op,args in instructions(generic_object)),'AVX instruction in generic object'
 wrapper=assemblies['deflate_fast'];assert '<longest_match_avx2>'in wrapper and 'functable'in wrapper and '<zng_private_deflate_fast_avx2>'in wrapper,'selected-pointer dispatch proof missing'
 assert any(op.startswith('cmp')for op,args in instructions(wrapper))and any(op in ['je','jne']for op,args in instructions(wrapper))
 private=assemblies['zng_private_deflate_fast_avx2'];assert '<zng_private_deflate_fast_avx2>:'in private
 assert 'vpcmpeqb'in private and 'vpmovmskb'in private,'original AVX2 comparison absent'
 assert not any(op.startswith('call')and('longest_match'in args or '*'in args)for op,args in instructions(private)),'Residual matcher/indirect call'
 assert 'zng_private_longest_match_avx2_inline'not in subprocess.check_output(['nm',str(lib)],text=True),'private matcher emitted out of line'
 native={'generic_object_has_no_avx':True,'private_matcher_has_no_out_of_line_symbol':True,'private_caller_has_avx2_compare':True,'private_caller_has_no_matcher_or_indirect_call':True,'wrapper_pointer_guard_and_avx2_target_present':True,'dispatch_branch_direction_independent_review_pending':True}
 (D/'codegen-proof.json').write_text(json.dumps(native,indent=2)+'\n')
 artifacts=[lib,work/'deflate_fast.lo',work/'compare256_avx2.lo',work/'arch/x86/compare256_avx2.lo',ownsrc/'deflate_fast.c',ownsrc/'arch/x86/compare256_avx2.c',ownsrc/'deflate_fast_shared.h',D/'codegen-proof.json',D/'generic-object.asm',*[D/(n+'.asm')for n in assemblies]]
 assert sha(lib)==json.loads((S/'selection.json').read_text())['variants']['guarded']['sha256'],'Private build must reproduce qualified f85 bytes'
 r.update(matches_qualified_library=True,status='BUILD_PASS_GUARDED_CODEC_REPRODUCES_QUALIFIED_BYTES',parent_library_sha256=sha(original),compile_commands=commands,link_command=link,changed_objects=differences,unchanged_pic_objects=68,total_pic_objects=71,changed_logical_objects=['deflate_fast.lo','compare256_avx2.lo'],changed_logical_object_count=2,ordered_shared_link_inputs=linked,shared_link_input_count=len(linked),unchanged_shared_link_inputs=len(linked)-2,arch_duplicate_path='arch/x86/compare256_avx2.lo',exports_unchanged=True,dynamic_dependencies_unchanged=True,codegen=native,source_proof=proof,artifacts={str(p):sha(p)for p in artifacts})
except BaseException as e:r.update(error=repr(e));raise
finally:
 r['elapsed_seconds']=time.monotonic()-start;(D/'receipt.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r))
