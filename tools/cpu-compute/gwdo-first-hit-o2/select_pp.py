"""Exact qualified PP selection. No science/compiler execution except version probes."""
import argparse,hashlib,json,os,shlex,subprocess,tempfile
from pathlib import Path
HERE=Path(__file__).resolve().parent
ASSET_SHA='330ea3892bfb28d9a3c637ee223816177537eb89159dc90882c745451337f624'
ORIGINAL_SHA='1f568c136f9ef955349e4d2b5a265e1d27135c241d8006d866019ed4fe2a28be'
KIND_SHA='942f1d2b05d600f4e3096c91c195bd0c4e087610da3f6ac53cae5707fc98ba01'
FLAGS=['-mtune=generic', '-march=x86-64', '-g', '-O2', '-ffp-contract=off', '-fno-fast-math', '-ffp-contract=off', '-ffree-form', '-ffree-line-length-none', '-fconvert=big-endian', '-frecord-marker=4', '-fallow-argument-mismatch', '-fallow-invalid-boz']

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def module_dirs(text):
    t=shlex.split(text);paths=[Path.cwd()];i=0
    while i<len(t):
        v=t[i]
        if v=='-I':i+=1;assert i<len(t);paths.append(Path(t[i]))
        else:assert v.startswith('-I') and len(v)>2;paths.append(Path(v[2:]))
        i+=1
    return paths

def eligible(a):
    if a.knob!='1' or a.rword!='4' or a.iword!='4':return False
    if any((a.omp,a.ompcpp,a.promotion,a.double,a.suffix)):return False
    cpp=shlex.split(a.cpp);defs=[];i=0
    while i<len(cpp):
        x=cpp[i]
        # Any explicit DM undefinition is outside the qualified pure-MPI contract.
        if x=='-U':
            i+=1;assert i<len(cpp)
            if cpp[i].split('=')[0]=='DM_PARALLEL':return False
        elif x.startswith('-U') and x[2:].split('=')[0]=='DM_PARALLEL':return False
        elif x=='-D':i+=1;assert i<len(cpp);defs.append(cpp[i].split('=')[0])
        elif x.startswith('-D'):defs.append(x[2:].split('=')[0])
        i+=1
    if 'DM_PARALLEL' not in defs or '_OPENMP' in defs or 'WRF_GWDO_FIRSTHIT_O2_DISABLE' in defs:return False
    # Deliberately narrow: only the actual qualified argv is supported, including its duplicate off.
    if shlex.split(a.flags)!=FLAGS:return False
    module_dirs(a.modules)
    fc=shlex.split(a.fc)
    if len(fc)!=1:return False
    v=subprocess.run(fc+['--version'],capture_output=True,text=True,timeout=10,check=True)
    n=subprocess.run(fc+['-dumpfullversion','-dumpversion'],capture_output=True,text=True,timeout=10,check=True)
    return 'GNU Fortran' in v.stdout and n.stdout.strip()=='13.3.0'

def select(a):
    dest=Path(a.dest);assert dest.name=='bl_gwdo.tmp.f90'
    asset=HERE/'qualified_bl_gwdo.f90';assert sha(asset)==ASSET_SHA,'QUALIFIED_ASSET_DRIFT'
    original=sha(dest)
    mods=[x/'ccpp_kind_types.mod' for x in module_dirs(a.modules) if (x/'ccpp_kind_types.mod').is_file()]
    kind=sha(mods[0]) if mods else None
    mode='ON' if original==ORIGINAL_SHA and kind==KIND_SHA else 'ORIGINAL'
    if mode=='ON':
        fd,tmp=tempfile.mkstemp(prefix=dest.name+'.gwdo-',dir=dest.parent)
        try:
            with os.fdopen(fd,'wb')as f:f.write(asset.read_bytes())
            os.replace(tmp,dest)
        finally:
            if os.path.exists(tmp):os.unlink(tmp)
    Path(str(dest)+'.gwdo-selection.json').write_text(json.dumps({'mode':mode,'original_preimage_sha256':original,'expected_original_sha256':ORIGINAL_SHA,'kind_MOD_sha256':kind,'asset_sha256':ASSET_SHA,'selected_sha256':sha(dest),'scope':'exact PP replay; not cleanF-only build certificate'},indent=2)+'\n')
    print(mode)

def main():
    p=argparse.ArgumentParser();s=p.add_subparsers(dest='cmd',required=True)
    a=s.add_parser('probe')
    for key in ['knob','rword','iword','omp','ompcpp','promotion','double','suffix','cpp','flags','modules','fc']:a.add_argument('--'+key,default='')
    a=s.add_parser('select');a.add_argument('--dest',required=True);a.add_argument('--modules',default='')
    a=p.parse_args()
    if a.cmd=='probe':
        try:ok=eligible(a)
        except (AssertionError,ValueError,OSError,subprocess.SubprocessError):ok=False
        print('1' if ok else '0')
    else:select(a)
if __name__=='__main__':main()
