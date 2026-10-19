#define _GNU_SOURCE
#include "shared_table.h"
#include <sched.h>
#include <dirent.h>
#include <errno.h>
#include <fenv.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
_Static_assert(_Generic((MPI_Fint)0, int:1, default:0), "ISO interface requires MPI_Fint == C int on qualified MPI stack");
#define MAGIC UINT64_C(0x737461626c653031)
struct st_owner {
 uint64_t magic; MPI_Comm all,node,cohort; MPI_Win win;
 void *base; size_t bytes; int epoch,rank,node_rank,numa,crank,csize,ncpu;
};
struct observation { int err; fenv_t env; };
static void checked(MPI_Comm c,int rc) {
 if(rc!=MPI_SUCCESS){ MPI_Abort(c,rc); abort(); }
}
#define MC(c,x) checked((c),(x))
static int capture(struct observation *o) {
 o->err=errno;return fegetenv(&o->env);
}
static int done(MPI_Comm c,struct observation *o,int status) {
 if(fesetenv(&o->env)){ MPI_Abort(c,92); abort(); } errno=o->err; return status;
}
static int maximum(MPI_Comm c,int value) {
 int r=0; MC(c,MPI_Allreduce(&value,&r,1,MPI_INT,MPI_MAX,c)); return r;
}
static int minimum(MPI_Comm c,int value) {
 int r=0; MC(c,MPI_Allreduce(&value,&r,1,MPI_INT,MPI_MIN,c)); return r;
}
/* Dynamic affinity, no pinning or NUMA-policy writes. CPU->node symlinks avoid
 * accepting partial cpulist parses. Inaccessible/ambiguous topology rejects. */
static int affinity(int *node,int *count,unsigned char **mask,size_t *maskbytes) {
#ifdef __linux__
 size_t cpus=128,sz=0; cpu_set_t *set=NULL;
 for(;cpus<=1048576;cpus*=2){
  sz=CPU_ALLOC_SIZE(cpus); set=CPU_ALLOC(cpus); if(!set)return 0;
  CPU_ZERO_S(sz,set);
  if(sched_getaffinity(0,sz,set)==0)break;
  int e=errno;CPU_FREE(set);set=NULL;if(e!=EINVAL)return 0;
 }
 if(!set)return 0;
 int common=-1,total=0,ok=1;
 for(size_t cpu=0;cpu<cpus;cpu++)if(CPU_ISSET_S(cpu,sz,set)){
  char path[128];int n=snprintf(path,sizeof(path),"/sys/devices/system/cpu/cpu%zu",cpu);
  if(n<0||(size_t)n>=sizeof(path)){ok=0;break;}
  DIR *d=opendir(path);if(!d){ok=0;break;}
  struct dirent *e;int found=-1,hits=0;
  for(;;){
   errno=0;e=readdir(d);if(!e){if(errno)ok=0;break;}
   if(strncmp(e->d_name,"node",4)||!e->d_name[4])continue;
   char *end=NULL;errno=0;long v=strtol(e->d_name+4,&end,10);
   if(errno||!end||*end||v<0||v>INT_MAX)continue;
   found=(int)v;hits++;
  }
  closedir(d);
  if(!ok||hits!=1||(common>=0&&common!=found)){ok=0;break;}
  common=found;total++;
 }
 if(!ok||total==0){CPU_FREE(set);return 0;}
 *mask=malloc(sz);if(!*mask){CPU_FREE(set);return 0;}
 memcpy(*mask,set,sz);CPU_FREE(set);*maskbytes=sz;*node=common;*count=total;return 1;
#else
 (void)node;(void)count;(void)mask;(void)maskbytes;return 0;
#endif
}
static int same_affinity(int node,int count,const unsigned char *mask,size_t size) {
 int n=-1,c=0;unsigned char *m=NULL;size_t z=0;
 int ok=affinity(&n,&c,&m,&z)&&n==node&&c==count&&z==size&&!memcmp(mask,m,z);
 free(m);return ok;
}
static void dispose(MPI_Comm caller,st_owner *o) {
 if(o->win!=MPI_WIN_NULL){
  MC(caller,MPI_Barrier(o->cohort));
  if(o->epoch)MC(caller,MPI_Win_unlock_all(o->win));
  MC(caller,MPI_Win_free(&o->win));
 }
 if(o->cohort!=MPI_COMM_NULL)MC(caller,MPI_Comm_free(&o->cohort));
 if(o->node!=MPI_COMM_NULL)MC(caller,MPI_Comm_free(&o->node));
 if(o->all!=MPI_COMM_NULL)MC(caller,MPI_Comm_free(&o->all));
 o->magic=0;free(o);
}
int st_create(MPI_Fint f,const void *staging,size_t bytes,int opt,
              st_owner **slot,void **view) {
 struct observation obs;int envrc=capture(&obs);MPI_Comm c=MPI_Comm_f2c(f);
 if(envrc){MPI_Abort(c,91);abort();} int inter=0;
 MC(c,MPI_Comm_test_inter(c,&inter));
 if(maximum(c,inter||!slot||!view))return done(c,&obs,ST_ARGUMENT);
 int live=*slot!=NULL;
 if(maximum(c,live))return done(c,&obs,ST_STATE); /* preserve old live view */
 if(maximum(c,*view!=NULL))return done(c,&obs,ST_ARGUMENT);
 int omin=minimum(c,opt),omax=maximum(c,opt);
 if(omin!=omax||(opt!=0&&opt!=1))return done(c,&obs,ST_ARGUMENT);
 if(!opt)return done(c,&obs,ST_PRIVATE);
 /* size_t transfer is raw same-stack scalar; all members use same MPI ABI. */
 unsigned long long b=(unsigned long long)bytes,bmin,bmax;
 MC(c,MPI_Allreduce(&b,&bmin,1,MPI_UNSIGNED_LONG_LONG,MPI_MIN,c));
 MC(c,MPI_Allreduce(&b,&bmax,1,MPI_UNSIGNED_LONG_LONG,MPI_MAX,c));
 MPI_Aint extent=(MPI_Aint)bytes;
 int bad=bytes==0||!staging||bmin!=bmax||(size_t)b!=bytes||extent<=0||(size_t)extent!=bytes;
 if(maximum(c,bad))return done(c,&obs,ST_ARGUMENT);
 int numa=-1,ncpu=0;unsigned char *mask=NULL;size_t maskbytes=0;
 int admitted=affinity(&numa,&ncpu,&mask,&maskbytes);
 if(!minimum(c,admitted)){free(mask);return done(c,&obs,ST_UNSUPPORTED);}
 st_owner *o=calloc(1,sizeof(*o));
 if(maximum(c,o==NULL)){free(mask);free(o);return done(c,&obs,ST_RESOURCE);}
 o->all=o->node=o->cohort=MPI_COMM_NULL;o->win=MPI_WIN_NULL;
 o->bytes=bytes;o->numa=numa;o->ncpu=ncpu;
 MC(c,MPI_Comm_dup(c,&o->all));
 MC(c,MPI_Comm_set_errhandler(o->all,MPI_ERRORS_RETURN));
 MC(c,MPI_Comm_rank(o->all,&o->rank));
 MC(c,MPI_Comm_split_type(o->all,MPI_COMM_TYPE_SHARED,o->rank,MPI_INFO_NULL,&o->node));
 MC(c,MPI_Comm_rank(o->node,&o->node_rank));
 MC(c,MPI_Comm_split(o->node,numa,o->rank,&o->cohort));
 MC(c,MPI_Comm_rank(o->cohort,&o->crank));MC(c,MPI_Comm_size(o->cohort,&o->csize));
 void *local=NULL;MPI_Aint localbytes=o->crank==0?extent:0;
 MC(c,MPI_Win_allocate_shared(localbytes,1,MPI_INFO_NULL,o->cohort,&local,&o->win));
 MC(c,MPI_Win_set_errhandler(o->win,MPI_ERRORS_RETURN));
 int *model=NULL,flag=0,disp=0;MPI_Aint query=0;
 MC(c,MPI_Win_get_attr(o->win,MPI_WIN_MODEL,&model,&flag));
 MC(c,MPI_Win_shared_query(o->win,0,&query,&disp,&o->base));
 bad=!flag||!model||*model!=MPI_WIN_UNIFIED||query!=extent||disp!=1||!o->base;
 if(maximum(o->all,bad)){free(mask);dispose(c,o);return done(c,&obs,ST_UNSUPPORTED);}
 MC(c,MPI_Win_lock_all(0,o->win));o->epoch=1;
 MC(c,MPI_Barrier(o->cohort));
 if(o->crank==0){memcpy(o->base,staging,bytes);MC(c,MPI_Win_sync(o->win));}
 MC(c,MPI_Barrier(o->cohort));MC(c,MPI_Win_sync(o->win));
 bad=memcmp(o->base,staging,bytes)!=0;
 int changed=!same_affinity(numa,ncpu,mask,maskbytes);free(mask);
 bad=maximum(o->all,bad);changed=maximum(o->all,changed);
 if(bad||changed){dispose(c,o);return done(c,&obs,bad?ST_MISMATCH:ST_UNSUPPORTED);}
 MC(c,MPI_Barrier(o->all)); /* all comparisons commit before private release */
 o->magic=MAGIC;*slot=o;*view=o->base;return done(c,&obs,ST_SHARED);
}
int st_destroy(MPI_Fint f,st_owner **slot,void **view) {
 struct observation obs;int envrc=capture(&obs);MPI_Comm c=MPI_Comm_f2c(f);
 if(envrc){MPI_Abort(c,91);abort();}
 if(maximum(c,!slot||!view))return done(c,&obs,ST_ARGUMENT);
 int live=*slot!=NULL,lo=minimum(c,live),hi=maximum(c,live);
 if(lo!=hi)return done(c,&obs,ST_STATE);
 if(!hi){if(maximum(c,*view!=NULL))return done(c,&obs,ST_ARGUMENT);return done(c,&obs,ST_PRIVATE);}
 st_owner *o=*slot;int relation=MPI_UNEQUAL;
 MC(c,MPI_Comm_compare(c,o->all,&relation));
 int bad=o->magic!=MAGIC||*view!=o->base||(relation!=MPI_IDENT&&relation!=MPI_CONGRUENT);
 if(maximum(c,bad))return done(c,&obs,ST_STATE);
 MC(c,MPI_Barrier(o->all));dispose(c,o);*slot=NULL;*view=NULL;
 return done(c,&obs,ST_SHARED);
}
int st_describe(const st_owner *o,int *r,int *nr,int *n,int *cr,int *cs,int *cp,size_t *b) {
 if(!o||o->magic!=MAGIC)return ST_STATE;
 *r=o->rank;*nr=o->node_rank;*n=o->numa;*cr=o->crank;*cs=o->csize;*cp=o->ncpu;*b=o->bytes;
 return ST_SHARED;
}
