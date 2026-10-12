#!/usr/bin/env python3
"""Build only this opt-in shim into a fresh owned directory; install nothing."""
from pathlib import Path
import argparse,hashlib,json,os,subprocess
HERE=Path(__file__).resolve().parent
GNU=Path('/pool/wrf-experiment/toolchains/gnu/13.3.0')
MPI=GNU/'mpi-ucx-xpmem'
OWNER=Path('/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19')
DEPS={str(OWNER.parent.parent/'include/netcdf_precompressed.h'):'f050797799f235dea8be9400198d0b8d44fbfca2acb45ed4a914b75b717311b4',str(OWNER):'8adc33059a98399cd8adea41de071598aaa2b09ff53eb3ae860cad0c6696b538',str(MPI/'lib/libmpi.so.40'):'239014e332e2a784c9b2e48ec7f440245a03e9d7bebe1de163a23929c9cdd9a7',str(GNU/'deps/lib/libhdf5.so.310'):'417b0a634947c27e2e096a2aa65e106030b33fa9b229869aa1325efe1386f98a',str(GNU/'deps/lib/libnetcdff.so.7'):'e271f9b96203b03c2e21f9e044b4cbe13534f309b100ae369dd0799fa7a2a6d6',str(GNU/'deps/lib/libz.so.1'):'b65f7f34c3180cbee93aeec785bba6b95beca585190e4a899c3b7648b7842830'}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--output-dir',required=True);args=ap.parse_args()
 pins=json.loads((HERE/'source-pins.json').read_text())
 for name,h in pins.items():
  if sha(HERE/name)!=h:raise SystemExit('source identity mismatch: '+name)
 for name,h in DEPS.items():
  if sha(name)!=h:raise SystemExit('dependency identity mismatch: '+name)
 out=Path(args.output_dir).resolve();out.mkdir(parents=True,exist_ok=False)
 env=os.environ.copy();env.pop('LD_PRELOAD',None)
 env.update(PATH=str(GNU/'bin')+':'+str(MPI/'bin')+':'+env.get('PATH',''),OPAL_PREFIX=str(MPI),OMPI_CC=str(GNU/'bin/gcc'),LD_LIBRARY_PATH=str(MPI/'lib')+':'+str(GNU/'deps/lib')+':'+str(GNU/'lib64'))
 flags=['-O2','-std=c11','-Wall','-Wextra','-Werror=implicit-function-declaration','-I'+str(GNU/'deps/include'),'-I'+str(HERE),'-L'+str(MPI/'lib'),'-L'+str(GNU/'deps/lib'),'-pthread']
 cmd=[str(MPI/'bin/mpicc'),*flags,'-fPIC','-shared',str(HERE/'wrf_root_thread_shim.c'),str(HERE/'root_chunk_provider.c'),'-lz','-ldl','-o',str(out/'shim.so')]
 p=subprocess.run(cmd,env=env,text=True,capture_output=True)
 receipt={'command':cmd,'returncode':p.returncode,'stdout':p.stdout,'stderr':p.stderr,'source_pins':pins,'dependencies':DEPS,'qualification':'BUILD_ONLY_NOT_RUNTIME_QUALIFIED','build_environment':{k:env[k] for k in ['PATH','OPAL_PREFIX','OMPI_CC','LD_LIBRARY_PATH']},'resolved_compiler':str((GNU/'bin/gcc').resolve()),'resolved_mpicc':str((MPI/'bin/mpicc').resolve())}
 if p.returncode==0:
  receipt['binary_sha256']=sha(out/'shim.so')
  for name,command in [('compiler',[str(GNU/'bin/gcc'),'--version']),('symbols',['nm','-D',str(out/'shim.so')]),('dynamic',['readelf','-d',str(out/'shim.so')]),('closure',['ldd',str(out/'shim.so')])]:
   q=subprocess.run(command,env=env,text=True,capture_output=True);receipt[name]={'returncode':q.returncode,'stdout':q.stdout,'stderr':q.stderr}
 (out/'build-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
 raise SystemExit(p.returncode)
if __name__=='__main__':main()
