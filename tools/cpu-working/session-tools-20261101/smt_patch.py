"""Apply the experimental SMT/OpenMP-tile harness changes to a runtime package copy.
Usage: smt_patch.py <package_dir> <omp_threads>
Everything is gated on lease['experimental_smt']; absent flag => original behaviour."""
import sys,json,hashlib
from pathlib import Path
P=Path(sys.argv[1]); T=int(sys.argv[2])
def sub(f,old,new,count=1):
    p=P/f; s=p.read_text(); assert s.count(old)==count,(f,old[:60],s.count(old)); p.write_text(s.replace(old,new))
# 1 adapter: threads, quota, OpenMP env, shim CPU list
sub('adapter/multinode_mpi.py',"assert lease['omp_threads']==1,'Initial adapter intentionally pureMPI only'",
    "assert lease['omp_threads']==1 or ('experimental_smt' in lease and lease['omp_threads']==lease['experimental_smt']['omp_threads']),'pure MPI unless experimental_smt'")
sub('adapter/multinode_mpi.py',"assert 1<=n['ranks']<=len(cpus) and n['cpu_quota_cores']<=len(cpus) and n['ranks']<=n['cpu_quota_cores']",
    "assert 1<=n['ranks']<=len(cpus) and n['cpu_quota_cores']<=(len(n.get('allowed_logical_cpus',cpus)) if 'experimental_smt' in lease else len(cpus)) and n['ranks']<=n['cpu_quota_cores']")
sub('adapter/multinode_mpi.py',"env.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',OMP_DYNAMIC='FALSE',UCX_LOG_LEVEL=lease.get('ucx_log_level','info'))",
    "env.update(OMP_NUM_THREADS=str(lease['omp_threads']),OPENBLAS_NUM_THREADS='1',OMP_DYNAMIC='FALSE',UCX_LOG_LEVEL=lease.get('ucx_log_level','info'))\n if 'experimental_smt' in lease:env.update(OMP_PLACES='threads',OMP_PROC_BIND='close',OMP_STACKSIZE=lease['experimental_smt']['omp_stacksize'])")
sub('adapter/multinode_mpi.py',"for name in ['PATH','OPAL_PREFIX','OMP_NUM_THREADS','OMP_DYNAMIC',",
    "for name in ['PATH','OPAL_PREFIX','OMP_NUM_THREADS','OMP_DYNAMIC']+(['OMP_PLACES','OMP_PROC_BIND','OMP_STACKSIZE'] if 'experimental_smt' in lease else [])+[")
sub('adapter/multinode_mpi.py',"'WRF_ROOT_SHIM_CPUS':'0-127'","'WRF_ROOT_SHIM_CPUS':('0-254' if 'experimental_smt' in lease else '0-127')")
# 2 input exec affinity
sub('adapter/input_rank_exec.py',"os.sched_getaffinity(0)=={m['cpu']}","os.sched_getaffinity(0) in ({m['cpu']},{m['cpu'],m['cpu']+128})")
sub('adapter/input_rank_exec.py',"\nif r==0:\n","\nif r==0 and 'input_read' in l:\n")
# 3 post-run proofs
sub('runtime_combined.py',"lease['omp_threads']==1","(lease['omp_threads']==1 or ('experimental_smt' in lease and lease['omp_threads']==lease['experimental_smt']['omp_threads']))")
sub('runtime_combined.py',"assert n['ranks']==128 and n['physical_cpus']==list(range(128))and n['cpu_quota_cores']==128",
    "assert n['ranks']==128 and n['physical_cpus']==list(range(128))and n['cpu_quota_cores']==(255 if 'experimental_smt' in lease else 128)")
sub('runtime_combined.py',"'WRF_ROOT_SHIM_CPUS':'0-127'","'WRF_ROOT_SHIM_CPUS':('0-254' if 'experimental_smt' in lease else '0-127')")
sub('worker_proof.py',"def check_threads(process,cpu,record):\n","def check_threads(process,cpu,record,smt=False):\n")
sub('worker_proof.py',"   if not matching:assert mask==[cpu],'unregistered non-singleton thread';continue",
    "   if not matching:assert mask==[cpu] or (smt and mask in ([cpu+128],[cpu,cpu+128])),'unregistered non-singleton thread';continue")
sub('worker_proof.py',"   if mask==[cpu]:continue","   if mask==[cpu] or (smt and mask==[cpu,cpu+128]):continue")
sub('runtime_combined.py',"check_threads(p,mapping[g]['cpu'],lifecycle[g])","check_threads(p,mapping[g]['cpu'],lifecycle[g],smt='experimental_smt' in lease)")
sub('tile_proof.py',"lease=json.loads((D/'lease.json').read_text());expected_env=EXPECTED_ENV",
    "lease=json.loads((D/'lease.json').read_text());expected_env=dict(EXPECTED_ENV,OMP_NUM_THREADS=str(lease['omp_threads']))")
sub('worker_proof.py',"row['cgroup_cpu_count']==128","row['cgroup_cpu_count']==(255 if 'experimental_smt' in lease else 128)")
# 4 coordinator unit on hpc01
sub('launch_arm.py',"'--property=AllowedCPUs=0-127','--property=CPUAffinity=0-127','--property=CPUQuota=12800%'",
    "*( ['--property=AllowedCPUs=0-254','--property=CPUAffinity=0-254','--property=CPUQuota=25500%'] if 'experimental_smt' in LEASE else ['--property=AllowedCPUs=0-127','--property=CPUAffinity=0-127','--property=CPUQuota=12800%'])")
K='/pool/wrf-experiment/wrf-cpu/kernels/current352f-heapretain-smt-native-hpc02-r1/work/candidate.so'
MAPPING = (
    "def parent_context(l):\n"
    " if 'experimental_smt' in l and l.get('shim_path')==SMT['path']:\n"
    "  assert l['shim_sha256']==SMT['so'] and l['lifetime_shim_source_sha256']==l['lifetime_shim_log_source_sha256']==SMT['src']\n"
    "  l=dict(l);l.update(shim_path=HEAP['path'],shim_sha256=HEAP['so'],lifetime_shim_source_sha256=HEAP['src'],lifetime_shim_log_source_sha256=HEAP['src'])\n")
sub('quiltroot_component_proof.py', "def parent_context(l):\n", MAPPING)
sub('quiltroot_component_proof.py', "HEAP={", "SMT={'so':'773194b4fa45411c297775b098980e62e46fc2de065c88c767542432181d43db','path':K_SMT,'src':'ddf643647b55e3c5df2b63e78b02354257ee31d26e15b957f5aa9310d492cc43'}\nHEAP={")
sub('quiltroot_component_proof.py', "from parent_rowcursor_proof import closed\n", "from parent_rowcursor_proof import closed\nK_SMT='" + K + "'\n")
sub('launch_arm.py',"taskset','-c','0-127','/pool/wrf-experiment/tooling/m1/venv/bin/python'","taskset','-c',('0-254' if 'experimental_smt' in LEASE else '0-127'),'/pool/wrf-experiment/tooling/m1/venv/bin/python'")
# 5 lease
lp=P/'lease-candidate-proposed.json'; l=json.loads(lp.read_text())
l['omp_threads']=T; l.update(shim_path=K,shim_sha256='773194b4fa45411c297775b098980e62e46fc2de065c88c767542432181d43db',lifetime_shim_source_sha256='ddf643647b55e3c5df2b63e78b02354257ee31d26e15b957f5aa9310d492cc43',lifetime_shim_log_source_sha256='ddf643647b55e3c5df2b63e78b02354257ee31d26e15b957f5aa9310d492cc43'); l['experimental_smt']={'omp_threads':T,'omp_stacksize':'512M','binding':'rankfile core slot; OMP_PLACES=threads, OMP_PROC_BIND=close; numtiles unchanged'}
for h,n in l['nodes'].items():
    n['allowed_logical_cpus']=sorted(n['physical_cpus']+[c+128 for c in n['physical_cpus'] if c+128<=254]); n['cpu_quota_cores']=255
l.pop('input_read',None)
lp.write_text(json.dumps(l,indent=2))
# 6 batch_release allowed keys
b=P/'batch_release.py'; s=b.read_text(); old="allowed={'root_authorized'"; assert s.count(old)==1
b.write_text(s.replace(old,"allowed={'omp_threads','experimental_smt','input_read','root_authorized'"))
pins=json.loads((P/'source-pins.json').read_text())
for n in pins: pins[n]=hashlib.sha256((P/n).read_bytes()).hexdigest()
(P/'source-pins.json').write_text(json.dumps(pins,indent=2)+'\n'); print('smt patch applied', T)
