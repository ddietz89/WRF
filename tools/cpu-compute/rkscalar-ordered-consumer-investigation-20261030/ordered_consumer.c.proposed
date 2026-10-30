/* Candidate only: fixed actual scalar operand roles, four independent I columns.
 * The Fortran caller must admit the supported REAL4/int32 contiguous row and all
 * exception masks before calling. The original compiled procedure handles other
 * executions. No scientific qualification follows from this source proposal.
 */
#include <emmintrin.h>
#define OP4(name,insn) static inline __m128 name(__m128 a,__m128 b){__asm__ volatile(insn " %1,%0":"+x"(a):"x"(b));return a;}
OP4(m4,"mulps") OP4(a4,"addps") OP4(d4,"divps")
OP4(m1,"mulss") OP4(a1,"addss") OP4(d1,"divss")
void wrf_rkscalar_consumer_ordered4_(const int *count,
 const float *muold,const float *munew,const float *scalar1,
 const float *tendency,float *scalar2,const float *c1,
 const float *c2,const float *dt)
{
 int i=0,n=*count;__m128 C1=_mm_set1_ps(*c1),C2=_mm_set1_ps(*c2),DT=_mm_set1_ps(*dt);
 for(;n-i>=4;i+=4){
  __m128 x=m4(_mm_loadu_ps(muold+i),C1);
  __m128 y=m4(_mm_loadu_ps(tendency+i),DT);
  x=a4(x,C2);x=m4(x,_mm_loadu_ps(scalar1+i));x=a4(x,y);
  y=m4(_mm_loadu_ps(munew+i),C1);y=a4(y,C2);
  _mm_storeu_ps(scalar2+i,d4(x,y));
 }
 for(;i<n;++i){
  __m128 x=m1(_mm_load_ss(muold+i),C1);
  __m128 y=m1(_mm_load_ss(tendency+i),DT);
  x=a1(x,C2);x=m1(x,_mm_load_ss(scalar1+i));x=a1(x,y);
  y=m1(_mm_load_ss(munew+i),C1);y=a1(y,C2);
  _mm_store_ss(scalar2+i,d1(x,y));
 }
}
