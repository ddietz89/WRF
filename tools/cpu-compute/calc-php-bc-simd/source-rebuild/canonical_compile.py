"""Finite corrected provider-helper adaptation of existing qualified WRF recipes.
No execution except through caller run(argv,label,cwd,out,stdin). No discovery.
"""
from pathlib import Path
import shlex,hashlib
VARS='CPP CPPFLAGS OMPCPP TRADFLAG SED_FTN FC DM_FC FCFLAGS FCNOOPT FCBASEOPTS OMP PROMOTION FCSUFFIX INCLUDE_MODULES'.split()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def expand(support,config,work,run):
 # Existing top Makefile sets ALL_MODULES=EM_MODULE_DIR+INCLUDE_MODULES.
 # Resolve qualified relative ../dyn_em against its original target directories.
 text=(support/'Makefile').read_text();assert 'EM_MODULE_DIR = -I../dyn_em'in text and '$(EM_MODULE_DIR)'in text
 assert config.read_bytes()==(support/'configure.wrf').read_bytes()
 mk=work/'dump.mk';mk.write_text('WRF_SRC_ROOT_DIR := '+str(support)+'\ninclude '+str(config)+'\n'+''.join('$(info '+v+'=$('+v+'))\n'for v in VARS)+'dump:\n\t@true\n')
 out=work/'expanded-flags.txt';run(['/usr/bin/make','-s','-f',mk,'dump'],'qualified-expanded-flags',work,out)
 v=dict(x.split('=',1)for x in out.read_text().splitlines()if'='in x);assert all(k in v for k in VARS)
 assert shlex.split(v['DM_FC'])==['/pool/wrf-experiment/toolchains/gnu/13.3.0/mpi-ucx-xpmem/bin/mpif90']
 assert shlex.split(v['CPP'])==['/usr/bin/cpp','-P','-traditional-cpp']
 assert shlex.split(v['OMP'])==[]and shlex.split(v['OMPCPP'])==[]
 assert '-O2'in shlex.split(v['FCFLAGS'])and '-O0'in shlex.split(v['FCNOOPT'])
 assert not any(x.startswith(('-march','-mtune','-mavx','-mfma','-ffast-math','-fopenmp','-fstack-arrays'))for k in ['FCFLAGS','FCNOOPT','FCBASEOPTS']for x in shlex.split(v[k]))
 return v
def preprocess(source,stem,cwd,support,v,enabled,run,label):
 a=lambda k:shlex.split(v[k]);src=cwd/(stem+'.F');src.write_bytes(Path(source).read_bytes());bb=cwd/(stem+'.bb');std=cwd/(stem+'.std');f90=cwd/(stem+'.f90')
 if stem=='module_physics_init':cppin=src
 else:
  cppin=cwd/(stem+'.G');run(['/bin/sed','-e',"s/^\\!.*'.*//",'-e',"s/^ *\\!.*'.*//",src],label+'-sed',cwd,cppin)
 subdir='main'if stem in ['wrf','module_wrf_top']else'dyn_em'if stem=='start_em'else'phys'
 # Original quoted includes search its source cwd (e.g. main/version_decl).
 cpp=[*a('CPP'),'-I'+str(support/subdir),'-I'+str(support/'inc'),*a('CPPFLAGS'),*a('OMPCPP')]
 if enabled:cpp+=['-DWRF_EXPERIMENTAL_TPI_NUMA']
 run([*cpp,cppin],label+'-cpp',cwd,bb)
 run([*a('SED_FTN'),bb],label+'-standard',cwd,std)
 # Genuine Make pipeline uses stdin; passing .std filename would change __FILE__.
 run([*a('CPP'),*a('TRADFLAG')],label+'-final-cpp',cwd,f90,std)
 return f90
def compile_f(f90,stem,cwd,support,v,owned_mods,run,label):
 a=lambda k:shlex.split(v[k]);includes=['-I'+str(x)for x in owned_mods]+['-I'+str(support/'dyn_em'),*a('INCLUDE_MODULES')]
 # Same FC command as qualified Make (including its `time` wrapper).
 if stem=='module_physics_init':args=[*a('FC'),'-c',*a('PROMOTION'),*a('FCSUFFIX'),*a('FCNOOPT'),*a('FCBASEOPTS'),*includes,*a('OMP'),Path(f90).name]
 else:args=[*a('FC'),'-o',stem+'.o','-c',*a('FCFLAGS'),*a('OMP'),*includes,*a('PROMOTION'),*a('FCSUFFIX'),Path(f90).name]
 run(args,label,cwd)
 return cwd/(stem+'.o')
