/* One current GNU13/x86 scalar-SSE cumulus row; no global state or alias extension.
   Current actual1281736c directions: RU/RV/RTH target*factor;
   QV/QC/QR/QI/QS factor*target; factor=MUT*C1+C2. */
void wrf_cu_fused_row(int n,float c1,float c2,const float *mu,
 float *ru,float *rv,float *rt,float *qv,float *qc,float *qr,float *qi,float *qs) {
 for(int i=0;i<n;i++) {
  float f,t;
  __asm__ volatile("movss %[m],%[f]\n\tmulss %[c1],%[f]\n\taddss %[c2],%[f]"
    : [f] "=&x"(f) : [m] "m"(mu[i]),[c1] "x"(c1),[c2] "x"(c2));
#define BASE(p) __asm__ volatile("movss %[m],%[t]\n\tmulss %[f],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
#define FACTOR(p) __asm__ volatile("movaps %[f],%[t]\n\tmulss %[m],%[t]\n\tmovss %[t],%[m]" : [t] "=&x"(t),[m] "+m"((p)[i]) : [f] "x"(f))
  BASE(ru); BASE(rv); BASE(rt); FACTOR(qv); FACTOR(qc); FACTOR(qr); FACTOR(qi); FACTOR(qs);
#undef BASE
#undef FACTOR
 }
}
