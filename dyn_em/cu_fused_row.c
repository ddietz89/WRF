#include <stdint.h>
#include <stddef.h>
#include <xmmintrin.h>
typedef float wrf_v4u __attribute__((vector_size(16), aligned(1), may_alias));
/* Only disjoint complete rows use packed arithmetic. Integer range checks
   preserve the selected scalar schedule for every possible overlap. */
static int disjoint_rows(int n,const float *mu,float *ru,float *rv,float *rt,
                         float *rqv,float *rqc,float *rqr,float *rqi,float *rqs) {
 const float *p[9]={mu,ru,rv,rt,rqv,rqc,rqr,rqi,rqs};
 uintptr_t lo[9],hi[9];
 if(n<4 || (uint64_t)(unsigned)n > UINTPTR_MAX/sizeof(float)) return 0;
 uintptr_t bytes=(uintptr_t)(unsigned)n*sizeof(float);
 for(int a=0;a<9;a++) {
  lo[a]=(uintptr_t)p[a];
  if(lo[a]>UINTPTR_MAX-bytes) return 0;
  hi[a]=lo[a]+bytes;
 }
 for(int a=0;a<9;a++) for(int b=a+1;b<9;b++)
  if(lo[a]<hi[b] && lo[b]<hi[a]) return 0;
 return 1;
}
/* Per-lane SSE operand directions match the selected scalar helper exactly.
   No arithmetic reassociation, reciprocal, FMA, unused lane or alias promise. */
void wrf_cu_fused_row(int n,float c1,float c2,const float *mu,
 float *ru,float *rv,float *rt,float *rqv,float *rqc,float *rqr,float *rqi,float *rqs) {
 int i=0;
 if(disjoint_rows(n,mu,ru,rv,rt,rqv,rqc,rqr,rqi,rqs)) {
  __m128 a=_mm_set1_ps(c1),b=_mm_set1_ps(c2),f,t,u;
  for(;i<=n-4;i+=4) {
   __asm__ volatile("movups %[m],%[f]\n\tmulps %[a],%[f]\n\taddps %[b],%[f]"
    : [f] "=&x"(f) : [m] "m"(*(const wrf_v4u *)(mu+i)),[a] "x"(a),[b] "x"(b));
#define BASE4(p) __asm__ volatile("movups %[m],%[t]\n\tmulps %[f],%[t]\n\tmovups %[t],%[m]" : [t] "=&x"(t),[m] "+m"(*(wrf_v4u *)((p)+i)) : [f] "x"(f))
#define OPT4(p) __asm__ volatile("movups %[m],%[u]\n\tmovaps %[f],%[t]\n\tmulps %[u],%[t]\n\tmovups %[t],%[m]" : [t] "=&x"(t),[u] "=&x"(u),[m] "+m"(*(wrf_v4u *)((p)+i)) : [f] "x"(f))
   BASE4(ru);BASE4(rv);BASE4(rt);OPT4(rqv);OPT4(rqc);OPT4(rqr);OPT4(rqi);OPT4(rqs);
#undef BASE4
#undef OPT4
  }
 }
 for(;i<n;i++) {
  float f,t;
  __asm__ volatile("movss %[m],%[f]\n\tmulss %[c1],%[f]\n\taddss %[c2],%[f]"
    : [f] "=&x"(f) : [m] "m"(mu[i]),[c1] "x"(c1),[c2] "x"(c2));
#define BASE(p) __asm__ volatile("movss %[m],%[t]\n\tmulss %[f],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
#define OPT(p) __asm__ volatile("movaps %[f],%[t]\n\tmulss %[m],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
  BASE(ru); BASE(rv); BASE(rt); OPT(rqv); OPT(rqc); OPT(rqr); OPT(rqi); OPT(rqs);
#undef BASE
#undef OPT
 }
}
