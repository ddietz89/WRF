/* Private default-off generated-serial Y receive prototype. No cancellation fallback. */
#include <mpi.h>
#include <stdlib.h>
#include "rsl_lite.h"
static struct {int active,fc,me,np,nx,ny,wm,wp,cm,cp,ym,yp,live_m,live_p;
 MPI_Comm comm;char *bm,*bp;MPI_Request rm,rp;unsigned long epochs,posts,retires;} y;
#ifdef WRF_RSL_EARLY_Y_NATIVE_3X3
#define Y_NATIVE_NOTE(expression) do{expression;}while(0)
#else
#define Y_NATIVE_NOTE(expression) do{}while(0)
#endif
/* One experimental admission line per process, charged to model wall.
 * Qualified GNU/Linux x86-64 raw write: no libc/errno/FP/timestamp operation. */
static void production_marker_once(void){
 static int emitted;
 static const char msg[]="WRF_RSL_EARLY_Y_8X60_ADMITTED\n";
 if(!emitted){long result;emitted=1;
  __asm__ __volatile__("syscall":"=a"(result):"0"(1L),"D"(2L),"S"(msg),"d"((long)sizeof(msg)-1):"rcx","r11","memory","cc");
  (void)result; /* Missing/partial marker fails later application admission proof. */
 }
}
static void bad(void){MPI_Abort(MPI_COMM_WORLD,97);abort();}
void rsl_early_y_before_init(void){if(y.active)bad();}
void rsl_early_y_begin(int fc,MPI_Comm comm,int me,int np,int nx,int ny,int wm,int wp,
 int cm,int cp,int ym,int yp,int axis){
 int topo,nd,d[2],period[2],coord[2],rank,size;
 if(y.active)bad();
 if(axis!=0||ny<=1||cm<=0||cp<=0||wm<0||wp<0||(!wm&&!wp))return;
 if(nx!=8||ny!=60||np!=480){
#ifdef WRF_RSL_EARLY_Y_NATIVE_3X3
  if(nx!=3||ny!=3||np!=9)return; /* component-test admission only, never production */
#else
  return;
#endif
 }
 if((ym!=MPI_PROC_NULL&&ym==me)||(yp!=MPI_PROC_NULL&&yp==me)||
    (ym!=MPI_PROC_NULL&&yp!=MPI_PROC_NULL&&ym==yp))return;
 if(MPI_Topo_test(comm,&topo)!=MPI_SUCCESS||topo!=MPI_CART)return;
 if(MPI_Cartdim_get(comm,&nd)!=MPI_SUCCESS||nd!=2)return;
 if(MPI_Cart_get(comm,2,d,period,coord)!=MPI_SUCCESS)return;
 if(d[0]!=ny||d[1]!=nx||period[0]||period[1])return;
 if(MPI_Comm_rank(comm,&rank)!=MPI_SUCCESS||MPI_Comm_size(comm,&size)!=MPI_SUCCESS)return;
 if(rank!=me||size!=np)return;
 y.bm=(ym!=MPI_PROC_NULL&&wm>0)?buffer_for_proc(ym,0,RSL_RECVBUF):0;
 y.bp=(yp!=MPI_PROC_NULL&&wp>0)?buffer_for_proc(yp,0,RSL_RECVBUF):0;
 if((ym!=MPI_PROC_NULL&&wm>0&&(!y.bm||buffer_size_for_proc(ym,RSL_RECVBUF)<cm))||
    (yp!=MPI_PROC_NULL&&wp>0&&(!y.bp||buffer_size_for_proc(yp,RSL_RECVBUF)<cp)))bad();
 y.fc=fc;y.comm=comm;y.me=me;y.np=np;y.nx=nx;y.ny=ny;
 y.wm=wm;y.wp=wp;y.cm=cm;y.cp=cp;y.ym=ym;y.yp=yp;
 y.rm=MPI_REQUEST_NULL;y.rp=MPI_REQUEST_NULL;y.live_m=0;y.live_p=0;
 y.active=1; /* no fallback after first successful post */
 /* Preserve original plus then minus posting order and exact capacities/tags. */
 if(yp!=MPI_PROC_NULL&&wp>0){if(MPI_Irecv(y.bp,cp,MPI_CHAR,yp,me,comm,&y.rp)!=MPI_SUCCESS)bad();y.live_p=1;Y_NATIVE_NOTE(++y.posts);}
 if(ym!=MPI_PROC_NULL&&wm>0){if(MPI_Irecv(y.bm,cm,MPI_CHAR,ym,me,comm,&y.rm)!=MPI_SUCCESS)bad();y.live_m=1;Y_NATIVE_NOTE(++y.posts);}
 Y_NATIVE_NOTE(++y.epochs);
 if((y.live_m||y.live_p)&&nx==8&&ny==60&&np==480)production_marker_once();
}
int rsl_early_y_take(int fc,MPI_Comm comm,int me,int np,int nx,int ny,int wm,int wp,
 int cm,int cp,int ym,int yp,MPI_Request *rm,MPI_Request *rp){
 if(!y.active)return 0;
 if(y.fc!=fc||y.comm!=comm||y.me!=me||y.np!=np||y.nx!=nx||y.ny!=ny||
    y.wm!=wm||y.wp!=wp||y.cm!=cm||y.cp!=cp||y.ym!=ym||y.yp!=yp)bad();
 if((y.live_m&&buffer_for_proc(ym,0,RSL_RECVBUF)!=y.bm)||
    (y.live_p&&buffer_for_proc(yp,0,RSL_RECVBUF)!=y.bp))bad();
 *rm=y.rm;*rp=y.rp;y.rm=MPI_REQUEST_NULL;y.rp=MPI_REQUEST_NULL;return 1;
}
void rsl_early_y_finish(MPI_Request *rm,MPI_Request *rp){
 if(!y.active||(y.live_m&&*rm!=MPI_REQUEST_NULL)||(y.live_p&&*rp!=MPI_REQUEST_NULL))bad();
 Y_NATIVE_NOTE(y.retires+=y.live_m+y.live_p);y.active=0;y.live_m=0;y.live_p=0;y.bm=0;y.bp=0;
}
/* Native route observations only: no MPI or fenv operation. */
#ifdef WRF_RSL_EARLY_Y_NATIVE_3X3
void rsl_early_y_native_stats(unsigned long *out){out[0]=y.active;out[1]=y.epochs;out[2]=y.posts;out[3]=y.retires;}

#endif
