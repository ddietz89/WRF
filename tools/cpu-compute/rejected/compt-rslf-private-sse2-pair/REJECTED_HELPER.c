/* Actual provider outline completed locally: explicit scalar-matching destinations. */
#if (defined(WRF_COMPT_RSLF_PAIR_OPT_O2) + defined(WRF_COMPT_RSLF_PAIR_OPT_O0)) != 1
#error "define exactly one matching Fortran optimization mode"
#endif
#include <xmmintrin.h>
#include <emmintrin.h>
#define OP(name, insn) \
static __inline__ __attribute__((__always_inline__)) __m128 name(__m128 a, __m128 b) { \
 __asm__ volatile(insn " %1,%0" : "+&x"(a) : "x"(b)); return a; }
OP(add_ordered,"addps")
OP(mul_ordered,"mulps")
OP(sub_ordered,"subps")
OP(div_ordered,"divps")
OP(max_ordered,"maxps")
OP(min_ordered,"minps")
#undef OP
void wrf_compt_rslf_pair_ordered_(const float *p,const float *t0,
 const float *t1,float *w0,float *w1) {
 const __m128 a=_mm_load_ss(t0), b=_mm_load_ss(t1);
 const __m128 ab=_mm_unpacklo_ps(a,b);
 const __m128 tt=_mm_movelh_ps(ab,ab); /* [T0,T1,T0,T1], no FP arithmetic */
 const __m128 pp=_mm_set1_ps(*p);
 const __m128 xx=max_ordered(sub_ordered(tt,_mm_set1_ps(273.16f)),_mm_set1_ps(-80.0f));
 __m128 e;
#if defined(WRF_COMPT_RSLF_PAIR_OPT_O2)
 e=mul_ordered(_mm_set1_ps(-.321582393E-13f),xx);
#define STAGE(c) e=mul_ordered(add_ordered(e,_mm_set1_ps(c)),xx)
#else
 e=mul_ordered(xx,_mm_set1_ps(-.321582393E-13f));
#define STAGE(c) e=mul_ordered(add_ordered(_mm_set1_ps(c),e),xx)
#endif
 STAGE(.379534310E-11f);
 STAGE(.702620698E-8f);
 STAGE(.203154182E-5f);
 STAGE(.299291081E-3f);
 STAGE(.264224321E-1f);
 STAGE(.143177157E1f);
 STAGE(.444606896E2f);
#undef STAGE
#if defined(WRF_COMPT_RSLF_PAIR_OPT_O2)
 e=add_ordered(e,_mm_set1_ps(.611583699E3f));
#else
 e=add_ordered(_mm_set1_ps(.611583699E3f),e);
#endif
 e=min_ordered(e,mul_ordered(_mm_set1_ps(.15f),pp));
 const __m128 result=div_ordered(mul_ordered(_mm_set1_ps(.622f),e),sub_ordered(pp,e));
 _mm_store_ss(w0,result);
 _mm_store_ss(w1,_mm_shuffle_ps(result,result,_MM_SHUFFLE(1,1,1,1)));
}
