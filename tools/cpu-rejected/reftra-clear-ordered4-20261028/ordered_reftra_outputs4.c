/* Private four-layer post-table consumer. No branch/table speculation.
 * Legacy SSE destination/source roles follow actual selected 1d16 instructions.
 * w is Fortran real(17,4); o is real(4,4). No alignment precondition. */
#include <xmmintrin.h>
static inline __attribute__((always_inline)) __m128 M(__m128 a,__m128 b) { __asm__("mulps %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 A(__m128 a,__m128 b) { __asm__("addps %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 S(__m128 a,__m128 b) { __asm__("subps %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 D(__m128 a,__m128 b) { __asm__("divps %1,%0":"+x"(a):"x"(b));return a; }
static inline __m128 L(const float*w,int k) { return _mm_set_ps(w[51+k],w[34+k],w[17+k],w[k]); }
static inline void O(float*o,int k,__m128 v) { float t[4];_mm_storeu_ps(t,v);for(int i=0;i<4;i++)o[4*i+k]=t[i]; }
void wrf_reftra_clear_outputs4(const float*w,float*o) {
 __m128 zw=L(w,0),zr1=L(w,1),zr2=L(w,2),zr3=L(w,3),zt1=L(w,4),zt2=L(w,5),zt3=L(w,6);
 __m128 em1=L(w,7),em2=L(w,8),ep1=L(w,9),ep2=L(w,10),den=L(w,11),beta=L(w,12),rkg=L(w,13),g2=L(w,14),rk2=L(w,15);
 __m128 one=_mm_set1_ps(1.0f);
 __m128 r=M(zr1,ep1); r=S(r,M(zr2,em1)); r=S(r,M(zr3,em2));r=M(r,zw);r=D(r,den);
 __m128 t=M(ep1,zt1);t=S(t,M(zt2,em1));t=S(t,M(ep2,zt3));t=M(t,M(zw,em2));t=D(t,L(w,16));t=S(em2,t);
 __m128 emm=M(em1,em1);__m128 dend=D(one,M(S(one,M(beta,emm)),rkg));
 __m128 rd=M(M(S(one,emm),g2),dend);__m128 td=M(M(em1,rk2),dend);
 O(o,1,t);O(o,0,r);O(o,3,td);O(o,2,rd);
}

/* Direct consumer witness oracle: exact measured legacy scalar operand roles. */
static inline __attribute__((always_inline)) __m128 MS(__m128 a,__m128 b) { __asm__("mulss %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 AS(__m128 a,__m128 b) { __asm__("addss %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 SS(__m128 a,__m128 b) { __asm__("subss %1,%0":"+x"(a):"x"(b));return a; }
static inline __attribute__((always_inline)) __m128 DS(__m128 a,__m128 b) { __asm__("divss %1,%0":"+x"(a):"x"(b));return a; }
static inline __m128 LS(const float*w,int k) { return _mm_set_ss(w[k]); }
static inline void OS(float*o,int k,__m128 v) { _mm_store_ss(o+k,v); }
void wrf_reftra_clear_outputs_scalar(const float*w,float*o) {
 for(int lane=0;lane<4;lane++,w+=17,o+=4) {
 __m128 zw=LS(w,0),zr1=LS(w,1),zr2=LS(w,2),zr3=LS(w,3),zt1=LS(w,4),zt2=LS(w,5),zt3=LS(w,6);
 __m128 em1=LS(w,7),em2=LS(w,8),ep1=LS(w,9),ep2=LS(w,10),den=LS(w,11),beta=LS(w,12),rkg=LS(w,13),g2=LS(w,14),rk2=LS(w,15);
 __m128 one=_mm_set1_ps(1.0f);
 __m128 r=MS(zr1,ep1); r=SS(r,MS(zr2,em1)); r=SS(r,MS(zr3,em2));r=MS(r,zw);r=DS(r,den);
 __m128 t=MS(ep1,zt1);t=SS(t,MS(zt2,em1));t=SS(t,MS(ep2,zt3));t=MS(t,MS(zw,em2));t=DS(t,LS(w,16));t=SS(em2,t);
 __m128 emm=MS(em1,em1);__m128 dend=DS(one,MS(SS(one,MS(beta,emm)),rkg));
 __m128 rd=MS(MS(SS(one,emm),g2),dend);__m128 td=MS(MS(em1,rk2),dend);
 OS(o,1,t);OS(o,0,r);OS(o,3,td);OS(o,2,rd);
}
}
