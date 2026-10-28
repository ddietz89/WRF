#!/usr/bin/env python3
"""512-only vendored provider build; never installs or qualifies a model."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess,shlex
HERE=Path(__file__).resolve().parent
GNU=Path('/pool/wrf-experiment/toolchains/gnu/13.3.0');MPI=GNU/'mpi-ucx-xpmem'
DEPENDENCIES={
 '/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19':'8adc33059a98399cd8adea41de071598aaa2b09ff53eb3ae860cad0c6696b538',
 str(MPI/'lib/libmpi.so.40'):'239014e332e2a784c9b2e48ec7f440245a03e9d7bebe1de163a23929c9cdd9a7',
 str(GNU/'deps/lib/libhdf5.so.310'):'417b0a634947c27e2e096a2aa65e106030b33fa9b229869aa1325efe1386f98a',
 str(GNU/'deps/lib/libnetcdff.so.7'):'e271f9b96203b03c2e21f9e044b4cbe13534f309b100ae369dd0799fa7a2a6d6',
 str(GNU/'deps/lib/libz.so.1'):'b65f7f34c3180cbee93aeec785bba6b95beca585190e4a899c3b7648b7842830',
 '/pool/wrf/WPS_new/runtime/zlib-ng/lib/libz.so.1.3.1.zlib-ng':'5d69c44314f30e4a6f6c76ee26a454538f7e1b019afe5782e67a6b94ba794b64'}
def sha(p):
 h=hashlib.sha256()
 with Path(p).open('rb')as f:
  for b in iter(lambda:f.read(1024**2),b''):h.update(b)
 return h.hexdigest()
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--provider',choices=['original','simd-pack','fused-pack'],default='fused-pack');ap.add_argument('--codec',choices=['private-distance','block-carry','slide-hash','huffman','guarded','inline','original'],default='private-distance');ap.add_argument('--codec-library',type=Path);ap.add_argument('--shared-dir',type=Path,default=HERE.parent);ap.add_argument('--output-dir',required=True,type=Path);a=ap.parse_args()
 codec_spec=json.loads((HERE/'codec/selection.json').read_text())['variants'][a.codec];codec_path=a.codec_library.absolute()if a.codec_library else Path(codec_spec['path']);assert sha(codec_path)==codec_spec['sha256'],'selected codec bytes differ'
 shared=a.shared_dir.resolve();pins=json.loads((HERE/'shared-source-pins.json').read_text());qualification=json.loads((HERE/'qualification.json').read_text())
 current=json.loads((HERE/'row-cursor-current-build.json').read_text()) if a.provider=='fused-pack' else None
 shim_sha=current['guard_source_sha256'] if current else qualification['variant_source_sha256']
 assert sha(HERE/'wrf_quilt_thread_shim.c')==shim_sha
 variant=current if current else (qualification if a.provider=='original' else qualification['optional_build_variants'][a.provider])
 provider=shared/'root_chunk_provider.c' if a.provider=='original' else HERE/variant.get('provider_source_file','root_chunk_provider.c')
 provider_sha=pins['root_chunk_provider.c'] if a.provider=='original' else variant['provider_source_sha256']
 assert sha(provider)==provider_sha
 for n,h in pins.items():assert sha(shared/n)==h,(n,'shared source changed')
 # Current fused route links MPI/z/dl/m only; old netCDF/HDF dependency receipts remain historical.
 for n,h in (current['direct_dependency_pins'] if current else DEPENDENCIES).items():assert sha(n)==h,(n,'dependency changed')
 if current:assert subprocess.check_output([str(GNU/'bin/gcc'),'-dumpfullversion'],text=True).strip()=='13.3.0'
 out=a.output_dir.absolute();assert not out.exists() and not out.is_symlink()
 assert all(not q.is_symlink()for q in out.parents);out.mkdir(parents=True,exist_ok=False)
 env=os.environ.copy();env.pop('LD_PRELOAD',None);env.update(PATH=str(GNU/'bin')+':'+str(MPI/'bin')+':'+env.get('PATH',''),OPAL_PREFIX=str(MPI),OMPI_CC=str(GNU/'bin/gcc'),LD_LIBRARY_PATH=str(MPI/'lib')+':'+str(GNU/'deps/lib')+':'+str(GNU/'lib64'))
 # Exact qualified C policy: O2/default IEEE, no fast-math enabled. Byte work only.
 flags=['-O2','-I'+str(GNU/'deps/include'),'-I'+str(shared),'-L'+str(MPI/'lib'),'-L'+str(GNU/'deps/lib'),'-Wl,-rpath,'+str(GNU/'deps/lib'),'-std=c11','-Wall','-Wextra','-Werror=implicit-function-declaration','-pthread','-fPIC','-shared']
 if a.provider in ['simd-pack','fused-pack']:flags[1:1]=['-fno-fast-math','-ffp-contract=off']
 binary=out/'wrf_quilt_thread_shim.so';cmd=[str(MPI/'bin/mpicc'),*flags,str(HERE/'wrf_quilt_thread_shim.c'),str(provider),'-lz','-ldl','-lm','-o',str(binary)]
 commands=[cmd]
 if current:
  base=[x for x in flags if x!='-shared']
  commands=[[str(MPI/'bin/mpicc'),*base,'-c',str(HERE/'wrf_quilt_thread_shim.c'),'-o',str(out/'output_fp_shim.o')],[str(MPI/'bin/mpicc'),*base,'-c',str(provider),'-o',str(out/'root_chunk_provider.o')],[str(MPI/'bin/mpicc'),*flags,str(out/'output_fp_shim.o'),str(out/'root_chunk_provider.o'),'-lz','-ldl','-lm','-o',str(binary)]]
 command_records=[]
 for cmd in commands:
  r=subprocess.run(cmd,env=env,capture_output=True,text=True)
  command_records.append({'argv':cmd,'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
  if r.returncode:break
 receipt={'status':'BUILD_ONLY_PENDING_RUNTIME_QUALIFICATION'if r.returncode==0 else'BUILD_FAILED','command':cmd,'commands':command_records,'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr,'source_sha256':shim_sha,'provider':a.provider,'provider_source_sha256':provider_sha,'shared_sha256':pins,'dependencies':current['direct_dependency_pins'] if current else DEPENDENCIES,'selected_codec':{'variant':a.codec,'path':str(codec_path),'sha256':codec_spec['sha256'],'scope':'rank-only preload; build does not activate or qualify a model'},'recipe_scope':'current strict GNU13.3 fused source; public recipe byte identity unproven' if current else 'historical variant recipe','reproduces_native_binary_hash':False,'runtime_qualified':False}
 if r.returncode==0:
  receipt['binary_sha256']=sha(binary);receipt['matches_retained_native_binary']=receipt['binary_sha256']==variant['native_artifact']['sha256']
  for name,args in [('dynamic',['readelf','-d',str(binary)]),('symbols',['nm','-D',str(binary)]),('closure',['ldd',str(binary)]),('compiler',[str(GNU/'bin/gcc'),'--version'])]:
   q=subprocess.run(args,env=env,capture_output=True,text=True);receipt[name]={'returncode':q.returncode,'stdout':q.stdout,'stderr':q.stderr}
 if r.returncode==0:(out/'rank-preload.env').write_text('WRF_QUILT_RANK_PRELOAD='+shlex.quote(str(binary)+':'+str(codec_path))+'\n')
 (out/'build-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');return r.returncode
if __name__=='__main__':raise SystemExit(main())
