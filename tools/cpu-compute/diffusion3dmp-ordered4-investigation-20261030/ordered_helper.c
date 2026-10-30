#include <xmmintrin.h>
#include <stddef.h>
#define BIN(name,insn) static inline __m128 name(__m128 a,__m128 b){__asm__ volatile(insn " %1,%0":"+x"(a):"x"(b));return a;}
BIN(a4,"addps") BIN(s4,"subps") BIN(m4,"mulps") BIN(d4,"divps")
BIN(a1,"addss") BIN(s1,"subss") BIN(m1,"mulss") BIN(d1,"divss")
#define BODY(TAG,LOAD,STORE) \
static inline void row##TAG(int i,int di,int dj,const float*f,float*t,const float*mu,const float*b,const float*ux,const float*uy,const float*vi,const float*vy,const float*tx,const float*ty,const float*x,__m128 c1,__m128 c2,__m128 dx,__m128 dy){ \
 const __m128 half=_mm_set1_ps(0.5f); \
 __m128 xc=LOAD(x+i),fc=LOAD(f+i),bc=LOAD(b+i); \
 __m128 mc=a##TAG(m##TAG(c1,LOAD(mu+i)),c2); \
 __m128 xm=d##TAG(LOAD(ux+i),LOAD(uy+i)); \
 xm=m##TAG(xm,half);xm=m##TAG(xm,a##TAG(LOAD(x+i-1),xc));xm=m##TAG(xm,half); \
 xm=m##TAG(xm,a##TAG(a##TAG(m##TAG(LOAD(mu+i-1),c1),c2),mc));xm=m##TAG(xm,dx); \
 __m128 xp=d##TAG(LOAD(ux+i+1),LOAD(uy+i+1)); \
 xp=m##TAG(xp,half);xp=m##TAG(xp,a##TAG(LOAD(x+i+1),xc));xp=m##TAG(xp,half); \
 xp=m##TAG(xp,a##TAG(a##TAG(m##TAG(LOAD(mu+i+1),c1),c2),mc));xp=m##TAG(xp,dx); \
 __m128 yp=m##TAG(LOAD(vy+i+di),LOAD(vi+i+di)); \
 yp=m##TAG(yp,half);yp=m##TAG(yp,a##TAG(LOAD(x+i+dj),xc));yp=m##TAG(yp,half); \
 yp=m##TAG(yp,a##TAG(a##TAG(m##TAG(LOAD(mu+i+di),c1),c2),mc));yp=m##TAG(yp,dy); \
 __m128 ym=m##TAG(LOAD(vy+i),LOAD(vi+i)); \
 ym=m##TAG(ym,half);ym=m##TAG(ym,a##TAG(LOAD(x+i-dj),xc));ym=m##TAG(ym,half); \
 ym=m##TAG(ym,a##TAG(a##TAG(m##TAG(LOAD(mu+i-di),c1),c2),mc));ym=m##TAG(ym,dy); \
 __m128 gyP=a##TAG(s##TAG(s##TAG(LOAD(f+i+dj),fc),LOAD(b+i+dj)),bc); \
 __m128 gyM=a##TAG(s##TAG(s##TAG(fc,LOAD(f+i-dj)),bc),LOAD(b+i-dj)); \
 __m128 gxP=a##TAG(s##TAG(s##TAG(LOAD(f+i+1),fc),LOAD(b+i+1)),bc); \
 __m128 gxM=a##TAG(s##TAG(s##TAG(fc,LOAD(f+i-1)),bc),LOAD(b+i-1)); \
 __m128 maps=m##TAG(LOAD(tx+i),LOAD(ty+i)); \
 __m128 yy=m##TAG(s##TAG(m##TAG(gyP,yp),m##TAG(ym,gyM)),m##TAG(dy,maps)); \
 __m128 xx=m##TAG(s##TAG(m##TAG(xp,gxP),m##TAG(gxM,xm)),m##TAG(maps,dx)); \
 STORE(t+i,a##TAG(a##TAG(yy,xx),LOAD(t+i))); \
}
BODY(4,_mm_loadu_ps,_mm_storeu_ps)
BODY(1,_mm_load_ss,_mm_store_ss)
void wrf_diffusion3d_ordered4(int n,int di,int dj,const float*f,float*t,const float*mu,const float*b,const float*ux,const float*uy,const float*vi,const float*vy,const float*tx,const float*ty,const float*x,float c1s,float c2s,float dxs,float dys){
 if(n<=0)return;
 __m128 c1=_mm_set1_ps(c1s),c2=_mm_set1_ps(c2s),dx=_mm_set1_ps(dxs),dy=_mm_set1_ps(dys);
 int i=0;
 for(;i<=n-4;i+=4)row4(i,di,dj,f,t,mu,b,ux,uy,vi,vy,tx,ty,x,c1,c2,dx,dy);
 for(;i<n;i++)row1(i,di,dj,f,t,mu,b,ux,uy,vi,vy,tx,ty,x,c1,c2,dx,dy);
}
