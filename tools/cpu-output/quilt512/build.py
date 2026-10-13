#!/usr/bin/env python3
"""Proposed build-only recipe; never installs, launches, or qualifies a model."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess
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
 ap=argparse.ArgumentParser();ap.add_argument('--shared-dir',type=Path,default=HERE.parent);ap.add_argument('--output-dir',required=True,type=Path);a=ap.parse_args()
 shared=a.shared_dir.resolve();pins=json.loads((HERE/'shared-source-pins.json').read_text());qualification=json.loads((HERE/'qualification.json').read_text())
 assert sha(HERE/'wrf_quilt_thread_shim.c')==qualification['variant_source_sha256']
 for n,h in pins.items():assert sha(shared/n)==h,(n,'shared source changed')
 for n,h in DEPENDENCIES.items():assert sha(n)==h,(n,'dependency changed')
 out=a.output_dir.absolute();assert not out.exists() and not out.is_symlink()
 assert all(not q.is_symlink()for q in out.parents);out.mkdir(parents=True,exist_ok=False)
 env=os.environ.copy();env.pop('LD_PRELOAD',None);env.update(PATH=str(GNU/'bin')+':'+str(MPI/'bin')+':'+env.get('PATH',''),OPAL_PREFIX=str(MPI),OMPI_CC=str(GNU/'bin/gcc'),LD_LIBRARY_PATH=str(MPI/'lib')+':'+str(GNU/'deps/lib')+':'+str(GNU/'lib64'))
 # Exact qualified C policy: O2/default IEEE, no fast-math enabled. Byte work only.
 flags=['-O2','-I'+str(GNU/'deps/include'),'-I'+str(shared),'-L'+str(MPI/'lib'),'-L'+str(GNU/'deps/lib'),'-Wl,-rpath,'+str(GNU/'deps/lib'),'-std=c11','-Wall','-Wextra','-Werror=implicit-function-declaration','-pthread','-fPIC','-shared']
 binary=out/'wrf_quilt_thread_shim.so';cmd=[str(MPI/'bin/mpicc'),*flags,str(HERE/'wrf_quilt_thread_shim.c'),str(shared/'root_chunk_provider.c'),'-lz','-ldl','-lm','-o',str(binary)]
 r=subprocess.run(cmd,env=env,capture_output=True,text=True)
 receipt={'status':'BUILD_ONLY_PENDING_RUNTIME_QUALIFICATION'if r.returncode==0 else'BUILD_FAILED','command':cmd,'returncode':r.returncode,'stdout':r.stdout,'stderr':r.stderr,'source_sha256':qualification['variant_source_sha256'],'shared_sha256':pins,'dependencies':DEPENDENCIES,'reproduces_native_binary_hash':False,'runtime_qualified':False}
 if r.returncode==0:
  receipt['binary_sha256']=sha(binary);receipt['matches_retained_native_binary']=receipt['binary_sha256']==qualification['native_artifact']['sha256']
  for name,args in [('dynamic',['readelf','-d',str(binary)]),('symbols',['nm','-D',str(binary)]),('closure',['ldd',str(binary)]),('compiler',[str(GNU/'bin/gcc'),'--version'])]:
   q=subprocess.run(args,env=env,capture_output=True,text=True);receipt[name]={'returncode':q.returncode,'stdout':q.stdout,'stderr':q.stderr}
 (out/'build-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');return r.returncode
if __name__=='__main__':raise SystemExit(main())
