/* Exact legacy SSE operand roles observed at current0dd6 +0x22a8..22c3.
 * Full four-lane prefixes only; both hardware units masked by caller.
 * No alignment/alias strengthening, padding loads, FMA, or precision change. */
#include <stdint.h>
#include <stddef.h>
#include <xmmintrin.h>
typedef struct __attribute__((packed,may_alias)) { float x[4]; } lanes4;
__attribute__((target("sse2,no-avx,no-fma"),noinline))
void postpow4(int32_t ni,int32_t nj,int32_t nk,int32_t mi,int32_t mk,
 float *p,const float *pb,float p0){
 __m128 scale=_mm_set1_ps(p0);
 for(int32_t j=0;j<nj;j++)for(int32_t k=0;k<nk;k++)for(int32_t i=0;i<ni;i+=4){
  ptrdiff_t at=((ptrdiff_t)j*mk+k)*mi+i;__m128 x,b;
  __asm__ volatile("movups %[p],%[x]\n\t"
                   "movups %[pb],%[b]\n\t"
                   "mulps %[s],%[x]\n\t"
                   "subps %[b],%[x]"
   :[x]"=&x"(x),[b]"=&x"(b)
   :[p]"m"(*(const lanes4*)(p+at)),[pb]"m"(*(const lanes4*)(pb+at)),[s]"x"(scale));
  _mm_storeu_ps(p+at,x);
 }
}
