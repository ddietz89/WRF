#include <stdint.h>
int wrf_pbl_all_masked(void) {
 uint16_t cw; uint32_t mx;
 __asm__ volatile("fnstcw %0" : "=m"(cw));
 __asm__ volatile("stmxcsr %0" : "=m"(mx));
 return (cw&0x3f)==0x3f && (mx&0x1f80)==0x1f80;
}
/* Scalar SSE operand directions reproduce actual selected PBL code:
   factor = mut*c1 + c2; RU/RV = target*factor; RTH/QV/QC/QI = factor*target.
   No packed FP lanes, reciprocal, reassociation, alias promise or unused load. */
void wrf_pbl_fused_row(int n,float c1,float c2,const float *mu,
 float *ru,float *rv,float *rt,float *rqv,float *rqc,float *rqi) {
 for(int i=0;i<n;i++) {
  float f,t;
  __asm__ volatile("movss %[m],%[f]\n\tmulss %[c1],%[f]\n\taddss %[c2],%[f]"
    : [f] "=&x"(f) : [m] "m"(mu[i]),[c1] "x"(c1),[c2] "x"(c2));
#define BASE(p) __asm__ volatile("movss %[m],%[t]\n\tmulss %[f],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
#define OPT(p) __asm__ volatile("movaps %[f],%[t]\n\tmulss %[m],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
  BASE(ru); BASE(rv); OPT(rt); OPT(rqv); OPT(rqc); OPT(rqi);
#undef BASE
#undef OPT
 }
}
