#define _GNU_SOURCE
#include <mpi.h>
#include <netcdf.h>
#include <pthread.h>
#include <sched.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <limits.h>
#include <stdatomic.h>
#include "root_chunk_provider.h"
/* Experimental rank-only preload. No NC/HDF/MPI call inside provider or release. */
static int (*put_real)(int,int,const size_t*,const size_t*,const float*);
static int (*begin_real)(nc_precompressed_float_provider,void*),(*end_real)(void);
static pthread_t main_thread;
static int configured_world=16,world_config_ok=1;
static int enabled,closure_ok,root_cpu=-1;static root_chunk_options opt;
static cpu_set_t expected_cgroup;static char owner_path[PATH_MAX],logdir[PATH_MAX];
static FILE *logfile;static int actual_rank=-1,mpi_level=-1;static _Thread_local int busy;
static unsigned long scopes,callbacks,supplied,declines,releases,pending,errors,widens,restores;
static _Atomic unsigned long calls,foreign_calls;
static void fatal(const char *why){if(logfile){fprintf(logfile,"{\"event\":\"fatal\",\"reason\":\"%s\"}\n",why);fflush(logfile);}abort();}
static int number(const char*s,int*out){char*e;long n;errno=0;if(!s||!*s)return 0;n=strtol(s,&e,10);if(errno||*e||n<0||n>=CPU_SETSIZE)return 0;*out=(int)n;return 1;}
static int cpulist(const char*s,cpu_set_t*m){char b[4096],*tok,*save;CPU_ZERO(m);if(!s||!*s||strlen(s)>=sizeof b)return 0;strcpy(b,s);for(tok=strtok_r(b,",\n",&save);tok;tok=strtok_r(NULL,",\n",&save)){char*d=strchr(tok,'-');int a,z;if(d){*d=0;if(!number(tok,&a)||!number(d+1,&z)||z<a)return 0;}else{if(!number(tok,&a))return 0;z=a;}for(int i=a;i<=z;i++)CPU_SET(i,m);}return CPU_COUNT(m)>0;}
static int cg_ok(void){char line[4096],path[PATH_MAX],cpus[4096];FILE*f=fopen("/proc/self/cgroup","r");int found=0;if(!f)return 0;while(fgets(line,sizeof line,f)){if(!strncmp(line,"0::/",4)){line[strcspn(line,"\n")]=0;if(strstr(line+3,".."))break;if(snprintf(path,sizeof path,"/sys/fs/cgroup%s/cpuset.cpus.effective",line+3)>=(int)sizeof path)break;found=1;break;}}fclose(f);if(!found)return 0;f=fopen(path,"r");if(!f)return 0;int ok=fgets(cpus,sizeof cpus,f)!=NULL;fclose(f);cpu_set_t set;return ok&&cpulist(cpus,&set)&&CPU_EQUAL(&set,&expected_cgroup);}
static int same_owner(void*sym){Dl_info di;char p[PATH_MAX];return sym&&dladdr(sym,&di)&&di.dli_fname&&realpath(di.dli_fname,p)&&!strcmp(p,owner_path);}
static int singleton(cpu_set_t*m){return !pthread_getaffinity_np(pthread_self(),sizeof*m,m)&&CPU_COUNT(m)==1&&CPU_ISSET(root_cpu,m);}
static void trace_callback(const nc_precompressed_float_layout*l,int rc){if(!logfile)return;fprintf(logfile,"{\"event\":\"callback\",\"rank\":0,\"ncid\":%d,\"varid\":%d,\"ndims\":%d,\"batch_first\":%zu,\"batch_count\":%zu,\"total_chunks\":%zu,\"status\":%d,\"root_cpu\":%d,\"workers\":[%d,%d,%d,%d],\"restored_singleton\":true}\n",l->ncid,l->varid,l->ndims,l->batch_first,l->batch_count,l->total_chunks,rc,root_cpu,opt.cpus[0],opt.cpus[1],opt.cpus[2],opt.cpus[3]);}
typedef struct{void(*release)(void*);void*user;} release_state;
static void release_batch(void*u){int release_errno=errno;release_state*r=u;if(!pthread_equal(pthread_self(),main_thread)||!busy||pending==0)fatal("release_state");cpu_set_t now;if(!singleton(&now))fatal("release_affinity");r->release(r->user);pending--;releases++;free(r);errno=release_errno;}
static int provider(const nc_precompressed_float_layout*l,const void*raw,size_t n,nc_precompressed_float_batch*b,void*u){
 int callback_errno=errno;
 (void)u;if(!pthread_equal(pthread_self(),main_thread)||!busy||!l||!b){errno=callback_errno;return NC_EINVAL;}
 cpu_set_t saved,want,check;if(!singleton(&saved)||!cg_ok()){errors++;errno=callback_errno;return NC_EINVAL;}
 CPU_ZERO(&want);for(int i=0;i<4;i++)CPU_SET(opt.cpus[i],&want);
 int err=pthread_setaffinity_np(pthread_self(),sizeof want,&want);
 /* Even a failed change is followed by checked restore: never return widened. */
 if(err){if(pthread_setaffinity_np(pthread_self(),sizeof saved,&saved)||!singleton(&check))fatal("widen_failure_restore");errors++;errno=callback_errno;return NC_EINVAL;}
 widens++;if(pthread_getaffinity_np(pthread_self(),sizeof check,&check)||!CPU_EQUAL(&want,&check)){if(pthread_setaffinity_np(pthread_self(),sizeof saved,&saved)||!singleton(&check))fatal("widen_mask_restore");restores++;errors++;errno=callback_errno;return NC_EINVAL;}
 int rc=wps_root_provider(l,raw,n,b,&opt);
 /* Pure-byte workers have all joined. Restore before owner sees the batch/HDF writes. */
 if(pthread_setaffinity_np(pthread_self(),sizeof saved,&saved)||pthread_getaffinity_np(pthread_self(),sizeof check,&check)||!CPU_EQUAL(&saved,&check))fatal("provider_restore");restores++;callbacks++;
 if(rc==1){if(!b->release)fatal("missing_release");release_state*r=malloc(sizeof*r);if(!r){b->release(b->release_user);memset(b,0,sizeof*b);errors++;errno=callback_errno;return NC_ENOMEM;}r->release=b->release;r->user=b->release_user;b->release=release_batch;b->release_user=r;pending++;supplied++;}else if(rc==0)declines++;else errors++;
 trace_callback(l,rc);errno=callback_errno;return rc;
}
static int activate(void){int initialized=0,finalized=0,is_main=0,size=0;if(!enabled||!closure_ok||syscall(SYS_gettid)!=getpid())return 0;
 if(MPI_Initialized(&initialized)!=MPI_SUCCESS||!initialized)return 0;
 if(MPI_Finalized(&finalized)!=MPI_SUCCESS||finalized)return 0;
 if(MPI_Is_thread_main(&is_main)!=MPI_SUCCESS||!is_main)return 0;
 if(MPI_Query_thread(&mpi_level)!=MPI_SUCCESS||mpi_level<MPI_THREAD_FUNNELED)return 0;
 if(MPI_Comm_rank(MPI_COMM_WORLD,&actual_rank)!=MPI_SUCCESS||MPI_Comm_size(MPI_COMM_WORLD,&size)!=MPI_SUCCESS||size!=configured_world||actual_rank!=0)return 0;
 cpu_set_t mask;if(!singleton(&mask)||!cg_ok())return 0;
 if(!logfile)return 0;
 if(scopes==0){char file[PATH_MAX];(void)file;fprintf(logfile,"{\"event\":\"activation\",\"rank\":0,\"size\":%d,\"mpi_thread\":%d,\"root_cpu\":%d,\"cgroup_cpu_count\":%d,\"owner\":\"%s\"}\n",configured_world,mpi_level,root_cpu,CPU_COUNT(&expected_cgroup),owner_path);fflush(logfile);}
 return 1;
}
int nc_put_vara_float(int id,int var,const size_t*s,const size_t*c,const float*p){
 atomic_fetch_add(&calls,1);if(!put_real)return NC_EINVAL;
 /* Check pthread before any MPI call. Disabled/foreign/reentrant ordinary path untouched. */
 if(!enabled||!pthread_equal(pthread_self(),main_thread)||busy){if(!pthread_equal(pthread_self(),main_thread))atomic_fetch_add(&foreign_calls,1);return put_real(id,var,s,c,p);}
 int before_errno=errno;if(!activate()){errno=before_errno;return put_real(id,var,s,c,p);}
 int begin=begin_real(provider,NULL);if(begin!=NC_NOERR){errors++;return begin;}busy=1;scopes++;errno=before_errno;
 int rc=put_real(id,var,s,c,p),put_errno=errno;
 cpu_set_t mask;if(!singleton(&mask)||pending)fatal("put_exit_state");int end=end_real();busy=0;
 if(end!=NC_NOERR)errors++;if(rc!=NC_NOERR)errors++;
 if(logfile){fprintf(logfile,"{\"event\":\"put\",\"ncid\":%d,\"varid\":%d,\"status\":%d,\"end_status\":%d,\"pending\":%lu}\n",id,var,rc,end,pending);fflush(logfile);}
 errno=put_errno;return rc!=NC_NOERR?rc:end;
}
__attribute__((constructor))static void init(void){
 const char*world=getenv("WRF_ROOT_SHIM_WORLD");int value;
 if(world){if(number(world,&value)&&(value==16||value==64))configured_world=value;else world_config_ok=0;}
 main_thread=pthread_self();put_real=dlsym(RTLD_NEXT,"nc_put_vara_float");begin_real=dlsym(RTLD_NEXT,"nc_precompressed_provider_begin");end_real=dlsym(RTLD_NEXT,"nc_precompressed_provider_end");
 const char*dir_early=getenv("WRF_ROOT_SHIM_LOGDIR");int env_rank=-1;
 if(dir_early&&strlen(dir_early)<PATH_MAX&&!strchr(dir_early,'"')&&!strchr(dir_early,'\n')&&number(getenv("OMPI_COMM_WORLD_RANK"),&env_rank)&&env_rank<configured_world){char file[PATH_MAX];if(snprintf(file,sizeof file,"%s/rank%d-%ld.jsonl",dir_early,env_rank,(long)getpid())<(int)sizeof file)logfile=fopen(file,"wx");if(logfile){actual_rank=env_rank;fprintf(logfile,"{\"event\":\"constructor\",\"environment_rank\":%d,\"pid\":%ld,\"configured_world\":%d,\"mpi_calls\":0}\n",env_rank,(long)getpid(),configured_world);}}
 const char*on=getenv("WRF_ROOT_SHIM_OPTIN"),*off=getenv("WRF_ROOT_SHIM_OPTOUT");if(!world_config_ok||!on||strcmp(on,"1")||(off&&!strcmp(off,"1")))return;
 const char*owner=getenv("WRF_ROOT_SHIM_OWNER"),*dir=getenv("WRF_ROOT_SHIM_LOGDIR"),*cg=getenv("WRF_ROOT_SHIM_CPUS");
 if(!owner||!realpath(owner,owner_path)||!dir||strlen(dir)>=sizeof logdir||strchr(dir,'\n')||strchr(dir,'"')||!number(getenv("WRF_ROOT_SHIM_ROOTCPU"),&root_cpu)||!cpulist(cg,&expected_cgroup)||CPU_COUNT(&expected_cgroup)!=19)return;
 if(root_cpu==24||root_cpu==25||root_cpu==26||!CPU_ISSET(root_cpu,&expected_cgroup))return;for(int i=24;i<=26;i++)if(!CPU_ISSET(i,&expected_cgroup))return;
 const char*lvl=getenv("OMPI_MPI_THREAD_LEVEL");if(!lvl||strcmp(lvl,"1"))return;
 strcpy(logdir,dir);closure_ok=same_owner((void*)put_real)&&same_owner((void*)begin_real)&&same_owner((void*)end_real);if(!closure_ok)return;
 opt.threads=4;opt.cpus[0]=root_cpu;opt.cpus[1]=24;opt.cpus[2]=25;opt.cpus[3]=26;enabled=1;
}
__attribute__((destructor))static void finish(void){if(logfile){fprintf(logfile,"{\"event\":\"final\",\"rank\":%d,\"scopes\":%lu,\"callbacks\":%lu,\"supplied\":%lu,\"declines\":%lu,\"releases\":%lu,\"pending\":%lu,\"errors\":%lu,\"widens\":%lu,\"restores\":%lu,\"calls\":%lu,\"foreign_calls\":%lu}\n",actual_rank,scopes,callbacks,supplied,declines,releases,pending,errors,widens,restores,atomic_load(&calls),atomic_load(&foreign_calls));fclose(logfile);}}
