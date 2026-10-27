/* Four independent adjacent-I columns, exact original ascending-K operation roles.
 * Legacy SSE only. Every input vector uses MOVUPS; no alignment precondition.
 * Caller admits all six masks in both hardware units and positive extents.
 */
#include <stdint.h>
#include <stddef.h>
#include <xmmintrin.h>
typedef struct __attribute__((packed,may_alias)) { float x[4]; } lanes4;
__attribute__((target("sse2,no-avx,no-fma"),noinline))
void wrf_pwat_column4(int32_t ni,int32_t nj,int32_t nk,int32_t mi,int32_t mk,
 const float *qv,const float *dz,const float *rho,float *out){
 for(int32_t j=0;j<nj;j++)for(int32_t i=0;i<ni;i+=4){
  __m128 sum=_mm_setzero_ps();
  for(int32_t k=0;k<nk;k++){
   ptrdiff_t p=((ptrdiff_t)j*mk+k)*mi+i;
   __m128 product,d,r;
   __asm__ volatile("movups %[q],%[p]\n\t"
                    "movups %[dz],%[d]\n\t"
                    "movups %[rho],%[r]\n\t"
                    "mulps %[d],%[p]\n\t"
                    "mulps %[r],%[p]\n\t"
                    "addps %[p],%[sum]"
    : [sum]"+x"(sum),[p]"=&x"(product),[d]"=&x"(d),[r]"=&x"(r)
    : [q]"m"(*(const lanes4*)(qv+p)),[dz]"m"(*(const lanes4*)(dz+p)),[rho]"m"(*(const lanes4*)(rho+p)));
  }
  _mm_storeu_ps(out+(ptrdiff_t)j*mi+i,sum);
 }
}
