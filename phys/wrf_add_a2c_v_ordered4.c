/* Experimental row prefix; n is a positive multiple of four. Original
 * SSE operand roles: neighbor destination + current; multiply by .5;
 * computed term destination + old left. Caller retains scalar tails and
 * literal fallback whenever any FP trap is enabled. No alignment promise. */
#include <xmmintrin.h>
void wrf_add_a2c_v_ordered4(int n,float*l,const float*cur,const float*prev){
 const __m128 half=_mm_set1_ps(.5f);
 for(int i=0;i<n;i+=4){
  __m128 t=_mm_loadu_ps(prev+i),c=_mm_loadu_ps(cur+i),a=_mm_loadu_ps(l+i);
  __asm__ volatile("addps %1,%0":"+x"(t):"x"(c));
  __asm__ volatile("mulps %1,%0":"+x"(t):"x"(half));
  __asm__ volatile("addps %1,%0":"+x"(t):"x"(a));
  _mm_storeu_ps(l+i,t);
 }
}
