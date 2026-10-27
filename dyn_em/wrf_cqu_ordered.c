/* Private strict prototype. One exported component entry; no allocation/state writes. */
#include <cpuid.h>
#include <immintrin.h>
#include <stddef.h>
#include <stdint.h>
#define V __attribute__((target("avx2"),always_inline)) static inline
#define S __attribute__((always_inline)) static inline
V __m256 add8(__m256 a,__m256 b){__asm__ volatile("vaddps %1,%0,%0":"+x"(a):"x"(b));return a;}
V __m256 mul8(__m256 a,__m256 b){__asm__ volatile("vmulps %1,%0,%0":"+x"(a):"x"(b));return a;}
V __m256 div8(__m256 a,__m256 b){__asm__ volatile("vdivps %1,%0,%0":"+x"(a):"x"(b));return a;}
S __m128 add1(__m128 a,__m128 b){__asm__ volatile("vaddss %1,%0,%0":"+x"(a):"x"(b));return a;}
S __m128 mul1(__m128 a,__m128 b){__asm__ volatile("vmulss %1,%0,%0":"+x"(a):"x"(b));return a;}
S __m128 div1(__m128 a,__m128 b){__asm__ volatile("vdivss %1,%0,%0":"+x"(a):"x"(b));return a;}
__attribute__((target("avx2"),noinline))
static void component(const float*m,float*o,float*q,int n,int ns,int nk,int nj,
                      int64_t sk,int64_t sj,int64_t ss){
 const __m256 z=_mm256_setzero_ps(),half=_mm256_set1_ps(.5f),one=_mm256_set1_ps(1.f);
 const __m128 zs=_mm_setzero_ps(),hs=_mm_set_ss(.5f),os=_mm_set_ss(1.f);
 const int end=n-n%8;
 for(int j=0;j<nj;j++)for(int k=0;k<nk;k++){
  const float*r=m+(int64_t)j*sj+(int64_t)k*sk;float*out=o+(int64_t)j*sj+(int64_t)k*sk;int i;
  for(i=0;i<end;i+=8){__m256 a=add8(_mm256_loadu_ps(r+i),z);a=add8(a,_mm256_loadu_ps(r+i-1));_mm256_storeu_ps(q+i,a);}
  for(;i<n;i++){__m128 a=add1(_mm_load_ss(r+i),zs);a=add1(a,_mm_load_ss(r+i-1));_mm_store_ss(q+i,a);}
  for(int s=1;s<ns-1;s++){
   const float*t=r+(int64_t)s*ss;
   for(i=0;i<end;i+=8){__m256 a=add8(_mm256_loadu_ps(q+i),_mm256_loadu_ps(t+i));a=add8(a,_mm256_loadu_ps(t+i-1));_mm256_storeu_ps(q+i,a);}
   for(;i<n;i++){__m128 a=add1(_mm_load_ss(q+i),_mm_load_ss(t+i));a=add1(a,_mm_load_ss(t+i-1));_mm_store_ss(q+i,a);}
  }
  const float*t=r+(int64_t)(ns-1)*ss;
  for(i=0;i<end;i+=8){
   __m256 a=_mm256_loadu_ps(q+i);
   if(ns>1){a=add8(a,_mm256_loadu_ps(t+i));a=add8(a,_mm256_loadu_ps(t+i-1));_mm256_storeu_ps(q+i,a);}
   a=mul8(a,half);a=add8(a,one);a=div8(one,a);_mm256_storeu_ps(out+i,a);
  }
  for(;i<n;i++){
   __m128 a=_mm_load_ss(q+i);
   if(ns>1){a=add1(a,_mm_load_ss(t+i));a=add1(a,_mm_load_ss(t+i-1));_mm_store_ss(q+i,a);}
   a=mul1(a,hs);a=add1(a,os);a=div1(os,a);_mm_store_ss(out+i,a);
  }
 }
}
__attribute__((target("no-avx,no-avx2")))
int wrf_cqu_ordered(const float*m,float*o,float*q,int n,int ns,int nk,int nj,
                    int64_t sk,int64_t sj,int64_t ss){
 unsigned a,b,c,d,lo,hi,mx;unsigned short cw;
 if(n<8||ns<1||nk<1||nj<1)return 0;
 __asm__ volatile("fnstcw %0":"=m"(cw));__asm__ volatile("stmxcsr %0":"=m"(mx));
 if((cw&63)!=63||(mx&0x1f80)!=0x1f80)return 0;
 if(!__get_cpuid(1,&a,&b,&c,&d)||(c&((1u<<27)|(1u<<28)))!=((1u<<27)|(1u<<28)))return 0;
 __asm__ volatile("xgetbv":"=a"(lo),"=d"(hi):"c"(0));if((lo&6)!=6)return 0;
 if(!__get_cpuid_count(7,0,&a,&b,&c,&d)||!(b&(1u<<5)))return 0;
 component(m,o,q,n,ns,nk,nj,sk,sj,ss);return 1;
}
