#define _GNU_SOURCE
#include <mpi.h>
#include <netcdf.h>
#include <hdf5.h>
#include <pthread.h>
#include <sched.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdatomic.h>
#include <fenv.h>
#include <time.h>
#include "netcdf_predecoded.h"
#include "input_owner_binding.h"
#include "raw_chunk_decode.h"
/* LOCAL UNCOMPILED INPUT-only adapter. New opt-in/authority, not output375.
 * Four already-occupied same-job CPUs are borrowed; no spare-core claim. */
static int (*get_real)(int,int,const size_t*,const size_t*,float*);
static int (*begin_real)(nc_predecoded_float_provider,void*),(*end_real)(void);
static pthread_t main_thread;
static int enabled,actual_rank=-1,mpi_level=-1,activation_logged;
static char owner_path[PATH_MAX];static FILE*logfile;
static struct {int cpus[4];} opt={{0,1,2,3}};
static _Thread_local int busy;
static unsigned long scopes,callbacks,supplied,declines,widens,restores;
static void fatal(const char*why){if(logfile){fprintf(logfile,"{\"event\":\"fatal\",\"rank\":%d,\"reason\":\"%s\"}\n",actual_rank,why);fflush(logfile);}abort();}
typedef int (*create_fn)(pthread_t*,const pthread_attr_t*,void*(*)(void*),void*);
typedef int (*join_fn)(pthread_t,void**);
typedef int (*affinity_fn)(pthread_t,size_t,const cpu_set_t*);
static _Atomic(create_fn) real_create;
static _Atomic(join_fn) real_join;
static _Atomic(affinity_fn) real_affinity;
typedef struct {pthread_t handle;int valid,slot,cpu;unsigned long generation;long tid;unsigned long long startticks;void*(*fn)(void*);void*arg;} owned_worker;
static owned_worker workers[4];static _Thread_local owned_worker *observed_worker;
static int observing,expected_workers,create_slot;static unsigned long generation;
static unsigned long long monotonic_ns(void){struct timespec t;if(clock_gettime(CLOCK_MONOTONIC,&t))fatal("log_clock");return (unsigned long long)t.tv_sec*1000000000ULL+(unsigned long long)t.tv_nsec;}
static unsigned long long thread_ticks(long tid){char path[128],line[4096];if(snprintf(path,sizeof path,"/proc/self/task/%ld/stat",tid)>=(int)sizeof path)return 0;FILE*f=fopen(path,"r");if(!f)return 0;int ok=fgets(line,sizeof line,f)!=NULL;fclose(f);if(!ok)return 0;char*p=strrchr(line,')'),*save,*tok;if(!p)return 0;p+=2;int field=0;for(tok=strtok_r(p," ", &save);tok;tok=strtok_r(NULL," ",&save),field++)if(field==19){char*end;unsigned long long v=strtoull(tok,&end,10);return *end?0:v;}return 0;}
static void log_mask(const cpu_set_t*m){int first=1;fputc('[',logfile);for(int i=0;i<CPU_SETSIZE;i++)if(CPU_ISSET(i,m)){fprintf(logfile,"%s%d",first?"":",",i);first=0;}fputc(']',logfile);}
static void worker_event(const char*event,owned_worker*w,int rc){
 int saved_errno=errno;fenv_t env;if(fegetenv(&env))fatal("worker_log_fenv");cpu_set_t mask;CPU_ZERO(&mask);int mask_rc=pthread_getaffinity_np(pthread_self(),sizeof mask,&mask);
 if(!logfile||!w||!w->startticks)fatal("worker_log_identity");
 flockfile(logfile);fprintf(logfile,"{\"event\":\"%s\",\"rank\":%d,\"generation\":%lu,\"slot\":%d,\"tid\":%ld,\"startticks\":%llu,\"expected_cpu\":%d,\"monotonic_ns\":%llu,\"status\":%d,\"affinity_status\":%d,\"observed_mask\":",event,actual_rank,w->generation,w->slot,w->tid,w->startticks,w->cpu,monotonic_ns(),rc,mask_rc);log_mask(&mask);fputs("}\n",logfile);fflush(logfile);funlockfile(logfile);
 if(fesetenv(&env))fatal("worker_log_fenv_restore");errno=saved_errno;
}
static void main_event(const char*event,int slot,int rc){
 int saved_errno=errno;fenv_t env;if(fegetenv(&env))fatal("main_log_fenv");long tid=syscall(SYS_gettid);unsigned long long ticks=thread_ticks(tid);cpu_set_t mask;CPU_ZERO(&mask);int mask_rc=pthread_getaffinity_np(pthread_self(),sizeof mask,&mask);
 if(!logfile||!ticks)fatal("main_log_identity");
 flockfile(logfile);fprintf(logfile,"{\"event\":\"%s\",\"rank\":%d,\"generation\":%lu,\"slot\":%d,\"tid\":%ld,\"startticks\":%llu,\"monotonic_ns\":%llu,\"status\":%d,\"affinity_status\":%d,\"worker_mask\":[%d,%d,%d,%d],\"observed_mask\":",event,actual_rank,generation,slot,tid,ticks,monotonic_ns(),rc,mask_rc,opt.cpus[0],opt.cpus[1],opt.cpus[2],opt.cpus[3]);log_mask(&mask);fputs("}\n",logfile);fflush(logfile);funlockfile(logfile);
 if(fesetenv(&env))fatal("main_log_fenv_restore");errno=saved_errno;
}
static void* observed_start(void*arg){
 owned_worker*w=arg;observed_worker=w;w->tid=syscall(SYS_gettid);w->startticks=thread_ticks(w->tid);worker_event("worker_register",w,0);
 void*result=w->fn(w->arg);int saved_errno=errno;worker_event("worker_exit",w,0);observed_worker=NULL;errno=saved_errno;return result;
}
int pthread_create(pthread_t*t,const pthread_attr_t*a,void*(*fn)(void*),void*arg){
 int saved_errno=errno;create_fn real=atomic_load(&real_create);if(!real){real=(create_fn)dlsym(RTLD_NEXT,"pthread_create");atomic_store(&real_create,real);}if(!real){errno=saved_errno;return EAGAIN;}
 if(!pthread_equal(pthread_self(),main_thread)||!observing){errno=saved_errno;return real(t,a,fn,arg);}
 if(create_slot>=expected_workers||create_slot>=4)fatal("worker_create_count");
 Dl_info worker_info,provider_info;if(!dladdr((void*)fn,&worker_info)||!dladdr((void*)raw_parallel_read,&provider_info)||worker_info.dli_fbase!=provider_info.dli_fbase)fatal("worker_start_owner");
 owned_worker*w=&workers[create_slot];memset(w,0,sizeof*w);w->slot=create_slot;w->cpu=opt.cpus[create_slot];w->generation=generation;w->fn=fn;w->arg=arg;
 main_event("worker_create_begin",create_slot,0);errno=saved_errno;int rc=real(t,a,observed_start,w);int result_errno=errno;
 if(!rc){w->handle=*t;w->valid=1;create_slot++;}main_event("worker_create_return",w->slot,rc);errno=result_errno;return rc;
}
int pthread_setaffinity_np(pthread_t t,size_t n,const cpu_set_t*m){
 int saved_errno=errno;affinity_fn real=atomic_load(&real_affinity);if(!real){real=(affinity_fn)dlsym(RTLD_NEXT,"pthread_setaffinity_np");atomic_store(&real_affinity,real);}if(!real){errno=saved_errno;return EINVAL;}
 errno=saved_errno;int rc=real(t,n,m);int result_errno=errno;
 if(observed_worker&&pthread_equal(t,pthread_self()))worker_event("worker_bound",observed_worker,rc);
 errno=result_errno;return rc;
}
int pthread_join(pthread_t t,void**ret){
 int saved_errno=errno;join_fn real=atomic_load(&real_join);if(!real){real=(join_fn)dlsym(RTLD_NEXT,"pthread_join");atomic_store(&real_join,real);}if(!real){errno=saved_errno;return EINVAL;}
 owned_worker*w=NULL;if(pthread_equal(pthread_self(),main_thread)&&observing)for(int i=0;i<create_slot;i++)if(workers[i].valid&&pthread_equal(t,workers[i].handle)){w=&workers[i];break;}
 errno=saved_errno;int rc=real(t,ret);int result_errno=errno;
 if(w&&rc){main_event("worker_join_error",w->slot,rc);errno=result_errno;return rc;}
 if(w){fenv_t env;if(fegetenv(&env))fatal("join_log_fenv");if(logfile){fprintf(logfile,"{\"event\":\"worker_join\",\"rank\":%d,\"generation\":%lu,\"slot\":%d,\"tid\":%ld,\"startticks\":%llu,\"expected_cpu\":%d,\"monotonic_ns\":%llu,\"status\":%d}\n",actual_rank,w->generation,w->slot,w->tid,w->startticks,w->cpu,monotonic_ns(),rc);fflush(logfile);}if(!rc)w->valid=0;if(fesetenv(&env))fatal("join_log_fenv_restore");}
 errno=result_errno;return rc;
}

static int read_text(const char*p,char*out,size_t n){
 int fd=open(p,O_RDONLY|O_CLOEXEC|O_NOFOLLOW);if(fd<0)return 0;
 ssize_t k=read(fd,out,n-1);int ok=k>0&&(size_t)k<n-1;
 if(close(fd))ok=0;if(!ok)return 0;out[k]=0;return 1;
}
static int singleton(cpu_set_t*m){return !pthread_getaffinity_np(pthread_self(),sizeof*m,m)&&CPU_COUNT(m)==1&&CPU_ISSET(0,m);}
static int cgroup_ok(void){
 char line[4096],base[PATH_MAX],path[PATH_MAX],text[128],extra;
 if(!read_text("/proc/self/cgroup",line,sizeof line)||strncmp(line,"0::/",4)||strchr(line+4,'\n')!=line+strlen(line)-1)return 0;
 line[strcspn(line,"\n")]=0;if(strstr(line+3,".."))return 0;
 if(snprintf(base,sizeof base,"/sys/fs/cgroup%s",line+3)>=(int)sizeof base)return 0;
 #define READ_CGROUP(name) (snprintf(path,sizeof path,"%s/" name,base)<(int)sizeof path&&read_text(path,text,sizeof text))
 if(!READ_CGROUP("cpuset.cpus.effective")||strcmp(text,"0-127\n"))return 0;
 unsigned long long q,p,m,swap;
 if(!READ_CGROUP("cpu.max")||sscanf(text,"%llu %llu %c",&q,&p,&extra)!=2||!p||p>ULLONG_MAX/128||q!=128*p)return 0;
 if(!READ_CGROUP("memory.max")||sscanf(text,"%llu %c",&m,&extra)!=1||m!=100ULL*1024*1024*1024)return 0;
 if(!READ_CGROUP("memory.swap.max")||sscanf(text,"%llu %c",&swap,&extra)!=1||swap)return 0;
 #undef READ_CGROUP
 return 1;
}
static int same_owner(void*sym){Dl_info d;char p[PATH_MAX];return sym&&dladdr(sym,&d)&&d.dli_fname&&realpath(d.dli_fname,p)&&!strcmp(p,owner_path);}
static int root_authority(void){
 int initialized=0,finalized=0,is_main=0,size=0;char host[128];cpu_set_t mask;
 if(!enabled||!logfile||getuid()!=1000||geteuid()!=1000||syscall(SYS_gettid)!=getpid()||!pthread_equal(pthread_self(),main_thread))return 0;
 if(gethostname(host,sizeof host)||!memchr(host,0,sizeof host))return 0;host[strcspn(host,".")]=0;if(strcmp(host,"hpc01"))return 0;
 if(!singleton(&mask)||!cgroup_ok()||!same_owner((void*)get_real)||!same_owner((void*)begin_real)||!same_owner((void*)end_real))return 0;
 if(MPI_Initialized(&initialized)!=MPI_SUCCESS||!initialized||MPI_Finalized(&finalized)!=MPI_SUCCESS||finalized||MPI_Is_thread_main(&is_main)!=MPI_SUCCESS||!is_main||MPI_Query_thread(&mpi_level)!=MPI_SUCCESS||mpi_level<MPI_THREAD_FUNNELED||MPI_Comm_rank(MPI_COMM_WORLD,&actual_rank)!=MPI_SUCCESS||actual_rank!=0||MPI_Comm_size(MPI_COMM_WORLD,&size)!=MPI_SUCCESS||size!=512)return 0;
 if(!activation_logged){
  fprintf(logfile,"{\"event\":\"activation\",\"rank\":0,\"size\":512,\"mpi_thread\":%d,\"root_cpu\":0,\"cgroup_cpu_count\":128,\"memory_max\":107374182400,\"swap_max\":0,\"uid\":1000,\"host\":\"hpc01\",\"owner\":\"%s\"}\n",mpi_level,owner_path);fflush(logfile);activation_logged=1;
 }
 return 1;
}
static void callback_event(int rc){
 int e=errno;fenv_t env;if(fegetenv(&env))fatal("callback_log_env");
 fprintf(logfile,"{\"event\":\"callback\",\"rank\":0,\"generation\":%lu,\"status\":%d,\"workers\":[0,1,2,3],\"created\":%d,\"restored_singleton\":true,\"borrowed_occupied_cores\":true}\n",generation,rc,create_slot);fflush(logfile);
 if(fesetenv(&env))fatal("callback_log_env_restore");errno=e;
}
static int input_provider(int64_t ds,void*out,size_t n,void*u){
 (void)u;int entry_errno=errno;fenv_t entry,post;cpu_set_t saved,want,check;
 if(fegetenv(&entry))fatal("callback_entry_env");
 if(!busy||!pthread_equal(pthread_self(),main_thread)||!root_authority()){
  if(fesetenv(&entry))fatal("callback_decline_env");errno=entry_errno;return 0;
 }
 if(!singleton(&saved))fatal("callback_owner_mask");CPU_ZERO(&want);for(int k=0;k<4;k++)CPU_SET(k,&want);
 generation++;main_event("widen_begin",-1,0);
 int er=pthread_setaffinity_np(pthread_self(),sizeof want,&want);
 if(er){
  if(pthread_setaffinity_np(pthread_self(),sizeof saved,&saved)||!singleton(&check))fatal("failed_widen_restore");
  main_event("widen_end",-1,0);if(fesetenv(&entry))fatal("failed_widen_env");errno=entry_errno;return 0;
 }
 if(pthread_getaffinity_np(pthread_self(),sizeof check,&check)||!CPU_EQUAL(&check,&want))fatal("widen_exact_mask");widens++;
 memset(workers,0,sizeof workers);create_slot=0;expected_workers=4;observing=1;
 if(fesetenv(&entry))fatal("helper_entry_env");errno=entry_errno;
 char why[160]={0};int rc=raw_parallel_read((hid_t)ds,out,n,opt.cpus,why,sizeof why),post_errno=errno;
 if(fegetenv(&post))fatal("helper_post_env");
 for(int k=0;k<create_slot;k++)if(workers[k].valid)fatal("unjoined_input_worker");observing=0;
 if(pthread_setaffinity_np(pthread_self(),sizeof saved,&saved)||pthread_getaffinity_np(pthread_self(),sizeof check,&check)||!CPU_EQUAL(&check,&saved))fatal("restore_input_singleton");
 restores++;callbacks++;if(rc==1)supplied++;else declines++;
 main_event("widen_end",-1,rc);callback_event(rc);
 /* Preserve helper POST, not entry. The owner hook rolls back only non1. */
 if(fesetenv(&post))fatal("callback_post_env_restore");errno=post_errno;return rc;
}
int nc_get_vara_float(int id,int var,const size_t*s,const size_t*c,float*out){
 if(!get_real)return NC_EINVAL;
 if(!enabled||!pthread_equal(pthread_self(),main_thread)||busy)return get_real(id,var,s,c,out);
 int entry_errno=errno;fenv_t entry,post;if(fegetenv(&entry))fatal("api_entry_env");
 if(!root_authority()){
  if(fesetenv(&entry))fatal("api_decline_env");errno=entry_errno;return get_real(id,var,s,c,out);
 }
 int begin=begin_real(input_provider,NULL);
 if(begin!=NC_NOERR){if(fesetenv(&entry))fatal("api_begin_env");errno=entry_errno;return get_real(id,var,s,c,out);}
 busy=1;scopes++;
 if(fesetenv(&entry))fatal("api_native_entry_env");errno=entry_errno;
 int rc=get_real(id,var,s,c,out),post_errno=errno;if(fegetenv(&post))fatal("api_post_env");
 cpu_set_t mask;if(!singleton(&mask))fatal("api_return_mask");if(end_real()!=NC_NOERR)fatal("scope_end");busy=0;
 fprintf(logfile,"{\"event\":\"read\",\"rank\":0,\"ncid\":%d,\"varid\":%d,\"status\":%d}\n",id,var,rc);fflush(logfile);
 if(fesetenv(&post))fatal("api_post_env_restore");errno=post_errno;return rc;
}
static void init_impl(void){
 main_thread=pthread_self();get_real=dlsym(RTLD_NEXT,"nc_get_vara_float");begin_real=dlsym(RTLD_NEXT,"nc_predecoded_provider_begin");end_real=dlsym(RTLD_NEXT,"nc_predecoded_provider_end");
 const char*on=getenv("WRF_INPUT_PREDECODE_OPTIN"),*owner=getenv("WRF_INPUT_PREDECODE_OWNER"),*dir=getenv("WRF_INPUT_SCOPE_LOGDIR"),*hint=getenv("OMPI_COMM_WORLD_RANK");char host[128];
 /* Environment rank is only a constructor hint. Permission is actual MPI
  * rank/world/main+host+UID+cgroup checked afresh before every public scope. */
 if(!on||strcmp(on,"1")||!owner||!dir||!hint||strcmp(hint,"0")||getuid()!=1000||geteuid()!=1000||!realpath(owner,owner_path)||strcmp(owner_path,INPUT_OWNER_EXPECTED_PATH))return;
 if(gethostname(host,sizeof host)||!memchr(host,0,sizeof host))return;host[strcspn(host,".")]=0;if(strcmp(host,"hpc01"))return;
 if(strpbrk(owner_path,"\"\\\n")||!same_owner((void*)get_real)||!same_owner((void*)begin_real)||!same_owner((void*)end_real))return;
 int fd=open(dir,O_RDONLY|O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC);struct stat st;
 if(fd<0)return;if(fstat(fd,&st)||st.st_uid!=1000||(st.st_mode&0022)){close(fd);return;}
 char name[80];if(snprintf(name,sizeof name,"input-rank0-%ld.jsonl",(long)getpid())>=(int)sizeof name){close(fd);return;}
 int logfd=openat(fd,name,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW|O_CLOEXEC,0600);close(fd);if(logfd<0)return;
 logfile=fdopen(logfd,"w");if(!logfile){close(logfd);return;}
 fprintf(logfile,"{\"event\":\"constructor\",\"environment_rank_hint\":0,\"pid\":%ld,\"mpi_calls\":0,\"authority\":\"UNVALIDATED_UNTIL_ACTUAL_MPI_SCOPE\"}\n",(long)getpid());fflush(logfile);enabled=1;
}
/* Private constructor bookkeeping must not manufacture PREEXISTING flags. */
__attribute__((constructor))static void init(void){
 int entry_errno=errno;fenv_t entry_env;
 if(fegetenv(&entry_env))abort();
 init_impl();
 if(fesetenv(&entry_env))abort();
 errno=entry_errno;
}
__attribute__((destructor))static void finish(void){
 if(logfile){fprintf(logfile,"{\"event\":\"final\",\"rank\":%d,\"scopes\":%lu,\"callbacks\":%lu,\"supplied\":%lu,\"declines\":%lu,\"widens\":%lu,\"restores\":%lu}\n",actual_rank,scopes,callbacks,supplied,declines,widens,restores);fclose(logfile);}
}
