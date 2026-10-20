#define _GNU_SOURCE
#include "raw_chunk_decode.h"
#include "netcdf_predecoded.h"
#include <netcdf.h>
#include <hdf5.h>
#include <pthread.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fenv.h>
#include <xmmintrin.h>
#include <sched.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <float.h>
#include <inttypes.h>
_Static_assert(sizeof(hid_t)==sizeof(int64_t),"dataset ID ABI");
_Static_assert(sizeof(float)==4&&sizeof(double)==8&&FLT_RADIX==2,"fixture float ABI");
#define BYTES ((size_t)218542208)
#define WORDS ((size_t)54635552)
#define GUARD 64u
static const size_t DIMS[4]={1,32,1139,1499};
static int fault,private_active,creates,joins,raw_reads,backend_reads,api_active;
static int attempts,supplied,unchanged_failed,private_state_dirtied;
static int error_handler_calls,error_token,private_token;
static herr_t private_errors(hid_t id,void*u){(void)id;(void)u;return 0;}
static herr_t quiet_errors(hid_t id,void*u){(void)id;if(u==&error_token)error_handler_calls++;return 0;}
static int cpus[4];
static herr_t (*real_read)(hid_t,hid_t,hid_t,hid_t,hid_t,void*);
static void hard(int v,const char*s){if(!v){fprintf(stderr,"FAIL %s\n",s);exit(2);}}
/* Fixture-only wrappers: no modified provider/helper, no mutated input file. */
void *__real_malloc(size_t);
void *__wrap_malloc(size_t n){if(private_active&&fault==1&&n>400000000u){errno=ENOMEM;return NULL;}return __real_malloc(n);}
int __real_pthread_create(pthread_t*,const pthread_attr_t*,void*(*)(void*),void*);
int __wrap_pthread_create(pthread_t*t,const pthread_attr_t*a,void*(*fn)(void*),void*x){
 if(private_active&&fault==2&&creates==2)return EAGAIN;
 int r=__real_pthread_create(t,a,fn,x);if(private_active&&!r)creates++;return r;
}
int __real_pthread_join(pthread_t,void**);
int __wrap_pthread_join(pthread_t t,void**p){int r=__real_pthread_join(t,p);if(private_active&&!r)joins++;return r;}
herr_t __real_H5Dread_chunk(hid_t,hid_t,const hsize_t*,uint32_t*,void*);
herr_t __wrap_H5Dread_chunk(hid_t d,hid_t x,const hsize_t*o,uint32_t*m,void*b){
 herr_t r=__real_H5Dread_chunk(d,x,o,m,b);
 if(private_active){if(r>=0&&fault==3&&raw_reads==0)((unsigned char*)b)[0]^=1u;raw_reads++;}return r;
}
/* Executable symbol exported for this native fixture only. It observes realNC's backend. */
herr_t H5Dread(hid_t d,hid_t t,hid_t m,hid_t f,hid_t x,void*b){
 if(api_active)backend_reads++;hard(real_read!=NULL,"resolved H5Dread");return real_read(d,t,m,f,x,b);
}
static int callback(int64_t dataset,void*out,size_t n,void*u){
 (void)u;attempts++;hard(n==BYTES,"callback bytes");
 unsigned char*before=NULL;
 if(fault){before=malloc(n);hard(before!=NULL,"failure snapshot");memcpy(before,out,n);}
 char why[160]={0};private_active=1;
 int r=raw_parallel_read((hid_t)dataset,out,n,cpus,why,sizeof why);
 private_active=0;
 if(r==1)supplied++;
 if(r!=1&&before){hard(!memcmp(before,out,n),"failed private call changed output");unchanged_failed++;}
 if(before)free(before);
 if(r!=1&&fault){
  hard(H5Eset_auto2(H5E_DEFAULT,private_errors,&private_token)>=0,"private handler dirty");
  hard(H5Epush2(H5E_DEFAULT,__FILE__,__func__,__LINE__,H5E_ERR_CLS,H5E_IO,H5E_READERROR,"private fallback rollback marker")>=0,"private stack dirty");
  hard(!fesetround(FE_DOWNWARD)&&!feraiseexcept(FE_OVERFLOW),"private FP dirty");private_state_dirtied++;errno=EOVERFLOW;
 }
 return r;
}
struct state{int err,round,flags;unsigned csr;unsigned short cw;};
static struct state state(void){struct state s;s.err=errno;s.csr=_mm_getcsr();__asm__ volatile("fnstcw %0":"=m"(s.cw));s.round=fegetround();s.flags=fetestexcept(FE_ALL_EXCEPT);return s;}
static void emit_state(const char*k,struct state s){printf("\"%s\":{\"errno\":%d,\"round\":%d,\"flags\":%d,\"mxcsr\":%u,\"x87cw\":%u}",k,s.err,s.round,s.flags,s.csr,s.cw);}
/* Bounded exact HDF error records, observed AFTER public five-state capture. */
struct erecord{int64_t cls,major,minor;unsigned line;char file[256],func[128],desc[256];};
struct estack{unsigned n;struct erecord records[8];};
static herr_t stack_record(unsigned i,const H5E_error2_t*e,void*u){
 struct estack*s=u;if(!e||!e->file_name||!e->func_name||!e->desc||i>=8||strlen(e->file_name)>=256||strlen(e->func_name)>=128||strlen(e->desc)>=256)return -1;
 struct erecord*r=&s->records[s->n++];r->cls=e->cls_id;r->major=e->maj_num;r->minor=e->min_num;r->line=e->line;
 strcpy(r->file,e->file_name);strcpy(r->func,e->func_name);strcpy(r->desc,e->desc);return 0;
}
static struct estack stack_snapshot(void){struct estack s={0};hard(H5Ewalk2(H5E_DEFAULT,H5E_WALK_DOWNWARD,stack_record,&s)>=0,"bounded HDF stack observation");return s;}
static void json_string(const char*s){putchar('"');for(const unsigned char*p=(const unsigned char*)s;*p;p++){if(*p=='"'||*p=='\\')printf("\\%c",*p);else if(*p<32)printf("\\u%04x",*p);else putchar(*p);}putchar('"');}
static void emit_stack(const char*k,const struct estack*s){
 printf("\"%s\":[",k);for(unsigned i=0;i<s->n;i++){const struct erecord*r=&s->records[i];if(i)putchar(',');
 printf("{\"class\":%" PRId64 ",\"major\":%" PRId64 ",\"minor\":%" PRId64 ",\"line\":%u,\"file\":",r->cls,r->major,r->minor,r->line);json_string(r->file);printf(",\"function\":");json_string(r->func);printf(",\"description\":");json_string(r->desc);putchar('}');}putchar(']');
}
static int thread_count(void){DIR*d=opendir("/proc/self/task");hard(d!=NULL,"task dir");int n=0;struct dirent*e;while((e=readdir(d)))if(e->d_name[0]!='.')n++;hard(!closedir(d),"task close");return n;}
static uint32_t gen(size_t i){static const uint32_t edge[16]={0,0x80000000u,1,0x80000001u,0x007fffffu,0x807fffffu,0x00800000u,0x80800000u,0x3f800000u,0xbf800000u,0x7f800000u,0xff800000u,0x7fc12345u,0xffc54321u,0x7f812345u,0xff854321u};
 if(i%65536u<16)return edge[i%65536u];uint32_t x=(uint32_t)i;x^=x>>13;x*=UINT32_C(0x85ebca6b);x^=x>>16;return UINT32_C(0x3f000000)|(((uint32_t)i&65535u)<<7)|(x&127u);}
static int same_file(struct stat a,struct stat b){return a.st_dev==b.st_dev&&a.st_ino==b.st_ino&&a.st_size==b.st_size&&a.st_mtim.tv_sec==b.st_mtim.tv_sec&&a.st_mtim.tv_nsec==b.st_mtim.tv_nsec&&(a.st_mode&07777)==(b.st_mode&07777);}
int main(int argc,char**argv){
 hard(argc==9,"usage ordinary_nc_driver control|hook CASE immutable.nc RAW cpu0 cpu1 cpu2 cpu3");
 int hooked=!strcmp(argv[1],"hook");hard(hooked||!strcmp(argv[1],"control"),"route");const char*which=argv[2];
 int seeded=!strcmp(which,"seeded"),partial=!strcmp(which,"partial"),dbl=!strcmp(which,"double"),zero=!strcmp(which,"zero");
 if(!strcmp(which,"alloc-fail"))fault=1;else if(!strcmp(which,"partial-create"))fault=2;else if(!strcmp(which,"corrupt-copy"))fault=3;
 else hard(seeded||partial||dbl||zero||!strcmp(which,"full"),"case");
 if(fault)seeded=1; /* exercise rollback with nondefault errno/FENV/HDF caller state */
 cpu_set_t expected,mask,after_mask;CPU_ZERO(&expected);
 for(int k=0;k<4;k++){errno=0;char*e=NULL;long v=strtol(argv[5+k],&e,10);hard(!errno&&e&&e!=argv[5+k]&&!*e&&v>=0&&v<CPU_SETSIZE,"cpu");cpus[k]=(int)v;hard(!CPU_ISSET(v,&expected),"distinct CPU");CPU_SET(v,&expected);}
 hard(!pthread_getaffinity_np(pthread_self(),sizeof mask,&mask)&&CPU_EQUAL(&mask,&expected),"fixture exactfourCPU mask");
 struct stat before_file,after_file;hard(!lstat(argv[3],&before_file)&&S_ISREG(before_file.st_mode)&&!(before_file.st_mode&0222),"immutable readonlyregular fixture");
 real_read=(herr_t(*)(hid_t,hid_t,hid_t,hid_t,hid_t,void*))dlsym(RTLD_NEXT,"H5Dread");hard(real_read!=NULL,"H5Dread binding");
 int (*begin)(nc_predecoded_float_provider,void*)=NULL;int(*end)(void)=NULL;
 if(hooked){begin=(int(*)(nc_predecoded_float_provider,void*))dlsym(RTLD_DEFAULT,"nc_predecoded_provider_begin");end=(int(*)(void))dlsym(RTLD_DEFAULT,"nc_predecoded_provider_end");hard(begin&&end,"privateNC actual provider API exports");}
 int nc=-1,var=-1;hard(nc_open(argv[3],NC_NOWRITE,&nc)==NC_NOERR,"nc_open");hard(nc_inq_varid(nc,"data",&var)==NC_NOERR,"var data");
 size_t start[4]={0},count[4];memcpy(count,DIMS,sizeof count);size_t bytes=BYTES;
 if(partial){start[1]=31;start[2]=1137;start[3]=1497;count[0]=1;count[1]=1;count[2]=2;count[3]=2;bytes=16;}
 if(dbl)bytes=2*BYTES;
 if(zero){count[1]=0;bytes=64;}
 unsigned char*buf=malloc(bytes+2*GUARD);hard(buf!=NULL,"out alloc");unsigned char*out=buf+GUARD;memset(buf,0xa5,GUARD);memset(out,0xcc,bytes);memset(out+bytes,0xa5,GUARD);
 int nt=thread_count();hard(nt==1,"single owner before");
 if(hooked)hard(begin(callback,NULL)==NC_NOERR,"provider begin");
 hard(attempts==0&&supplied==0&&creates==0&&joins==0,"begin must not invoke provider");
 H5E_auto2_t saved_handler=NULL,after_handler=NULL;void*saved_user=NULL,*after_user=NULL;
 hard(H5Eget_auto2(H5E_DEFAULT,&saved_handler,&saved_user)>=0,"get HDF handler");
 hard(H5Eset_auto2(H5E_DEFAULT,quiet_errors,&error_token)>=0&&H5Eclear2(H5E_DEFAULT)>=0,"HDF handler seed");
 if(seeded)hard(H5Epush2(H5E_DEFAULT,__FILE__,__func__,__LINE__,H5E_ERR_CLS,H5E_IO,H5E_READERROR,"ordinary caller native seed")>=0,"HDF stack seed");
 ssize_t hdf_before=H5Eget_num(H5E_DEFAULT);hard(hdf_before==(seeded?1:0),"HDF seed count");
 struct estack stack_before=stack_snapshot();hard(stack_before.n==(unsigned)hdf_before,"HDF seed snapshot");
 hard(!fesetround(seeded?FE_UPWARD:FE_TONEAREST),"round seed");hard(!feclearexcept(FE_ALL_EXCEPT),"flag seed");if(seeded)hard(!feraiseexcept(FE_DIVBYZERO|FE_INEXACT),"exception seed");/* Fixture INITIAL state only, identical control/hook. feraiseexcept's
  * portable union does not specify x87 versus SSE; force the intended SSE
  * sticky initial condition without changing any production/admission code. */
 if(seeded)_mm_setcsr(_mm_getcsr()|(1u<<5));
 errno=seeded?EILSEQ:0;
 struct state before=state();
 if(seeded)hard((before.csr&(1u<<5))&&
  (before.csr&(0x3fu<<7))==(0x3fu<<7)&&(before.cw&0x3fu)==0x3fu,
  "fixture preexisting SSE inexact and all SSE/x87 masks");
 api_active=1;
 int rc=dbl?nc_get_vara_double(nc,var,start,count,(double*)out):nc_get_vara_float(nc,var,start,count,(float*)out);
 /* Capture API state before end/close/counters/verification/logging. No repair/normalization. */
 struct state after=state();api_active=0;
 int read_attempts=attempts,read_supplied=supplied,read_backend=backend_reads,read_creates=creates,read_joins=joins,read_raw=raw_reads,read_unchanged=unchanged_failed,read_dirty=private_state_dirtied;
 ssize_t hdf_after=H5Eget_num(H5E_DEFAULT);
 struct estack stack_after=stack_snapshot();hard(hdf_after>=0&&stack_after.n==(unsigned)hdf_after,"HDF returned stack snapshot");
 hard(H5Eget_auto2(H5E_DEFAULT,&after_handler,&after_user)>=0,"get returned HDF handler");
 int handler_restored=after_handler==quiet_errors&&after_user==&error_token;
 int handler_kind=handler_restored?0:((after_handler==private_errors&&after_user==&private_token)?1:(!after_handler?2:((after_handler==saved_handler&&after_user==saved_user)?3:4)));
 hard(handler_kind!=4,"unclassified returned HDF handler");
 int hdf_handler_calls=error_handler_calls;
 if(hooked)hard(end()==NC_NOERR,"provider end");
 hard(attempts==read_attempts&&supplied==read_supplied&&backend_reads==read_backend&&creates==read_creates&&joins==read_joins&&raw_reads==read_raw&&unchanged_failed==read_unchanged&&private_state_dirtied==read_dirty,"end must not perform read/provider work");
 hard(rc==NC_NOERR,"public read status");/* Baseline ordinaryNC determines actual returned HDF state; comparator checks exact paired snapshots. */
 hard(nc_close(nc)==NC_NOERR,"nc_close");hard(H5Eset_auto2(H5E_DEFAULT,saved_handler,saved_user)>=0,"cleanup HDF handler");
 hard(thread_count()==1&&creates==joins,"all private workers joined");hard(!pthread_getaffinity_np(pthread_self(),sizeof after_mask,&after_mask)&&CPU_EQUAL(&mask,&after_mask),"caller mask restored");
 hard(!lstat(argv[3],&after_file)&&same_file(before_file,after_file),"fixture stat unchanged");
 for(size_t i=0;i<GUARD;i++)hard(buf[i]==0xa5&&out[bytes+i]==0xa5,"guards");
 int provided=hooked&&seeded&&!partial&&!dbl&&!zero&&!fault;
 if(provided){hard(attempts==1&&supplied==1&&backend_reads==0&&creates==4&&joins==4&&raw_reads==4,"actual hook provided without originalH5Dread");}
 else if(hooked&&fault){hard(attempts==1&&supplied==0&&unchanged_failed==1&&private_state_dirtied==1&&backend_reads==1,"private failure fell through original backend");if(fault==1)hard(creates==0,"alloc failure worker count");if(fault==2)hard(creates==2&&joins==2,"partial-create join count");if(fault==3)hard(creates==4&&joins==4,"corrupt copy join count");}
 else{hard(attempts==0&&supplied==0&&creates==0&&joins==0,"unsupported/control bypass provider");hard(backend_reads==(zero?0:1),"original backend observed");}
 if(zero){for(size_t i=0;i<bytes;i++)hard(out[i]==0xcc,"zero count no writes");}
 else if(!dbl){size_t nw=bytes/4;for(size_t i=0;i<nw;i++){size_t gi=partial?((size_t)31*1139u+(1137u+i/2u))*1499u+1497u+i%2u:i;uint32_t v;memcpy(&v,out+4*i,4);hard(v==gen(gi),"full or selected word oracle");}}
 FILE*f=fopen(argv[4],"wbx");hard(f!=NULL,"createonly raw result");size_t nwritten=fwrite(out,1,bytes,f);int close_status=fclose(f);hard(nwritten==bytes&&close_status==0,"raw result write/close");
 printf("{\"route\":\"%s\",\"case\":\"%s\",\"api_rc\":%d,\"output_bytes\":%zu,\"callback_attempts\":%d,\"callback_supplied\":%d,\"private_failure_unchanged\":%d,\"original_backend_reads\":%d,\"workers_created\":%d,\"workers_joined\":%d,\"raw_reads\":%d,\"guards_ok\":true,\"file_stat_unchanged\":true,\"thread_count_after\":1,\"mask_restored\":true,",argv[1],which,rc,bytes,attempts,supplied,unchanged_failed,backend_reads,creates,joins,raw_reads);
 printf("\"private_state_dirtied\":%d,\"counts_frozen_at_public_return\":true,\"hdf_handler_kind\":%d,",private_state_dirtied,handler_kind);
 emit_stack("hdf_stack_before_records",&stack_before);printf(",");emit_stack("hdf_stack_after_records",&stack_after);printf(",");
 printf("\"hdf_stack_before\":%zd,\"hdf_stack_after\":%zd,\"hdf_handler_restored\":%s,\"hdf_handler_calls\":%d,",hdf_before,hdf_after,handler_restored?"true":"false",hdf_handler_calls);
 emit_state("before",before);printf(",");emit_state("after",after);puts("}");free(buf);return 0;
}
