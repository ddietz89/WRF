#if defined(WRF_PHY_HEIGHT_PARENT_O2) == defined(WRF_PHY_HEIGHT_PARENT_O0)
#error "Select exactly one qualified GNU13 original-parent operand mode"
#endif
/* Standalone experiment only. No WRF/public-interface integration. */
#include <xmmintrin.h>
#include <immintrin.h>
static inline float ordered_scalar(const float *b,const float *p,float g){
 float r;
#if defined(WRF_PHY_HEIGHT_PARENT_O0)
 __asm__ volatile("movss %[p],%[r]\n\taddss %[b],%[r]\n\tdivss %[g],%[r]"
 :[r]"=&x"(r):[b]"m"(*b),[p]"m"(*p),[g]"x"(g));
#else
 __asm__ volatile("movss %[b],%[r]\n\taddss %[p],%[r]\n\tdivss %[g],%[r]"
 :[r]"=&x"(r):[b]"m"(*b),[p]"m"(*p),[g]"x"(g));
#endif
 return r;
}
static inline void phy_height_row_core(float *out,const float *phb,const float *ph,int n,float g){
 if(n<=0)return;
 int i=0;
 if(n>=8){
 __m256 vg8=_mm256_set1_ps(g);
 for(;i<=n-8;i+=8){
  __m256 b=_mm256_loadu_ps(phb+i),p=_mm256_loadu_ps(ph+i);
#if defined(WRF_PHY_HEIGHT_PARENT_O0)
  __asm__ volatile("vaddps %[b],%[p],%[p]\n\tvdivps %[g],%[p],%[p]"
   :[p]"+&x"(p):[b]"x"(b),[g]"x"(vg8));
  _mm256_storeu_ps(out+i,p);
#else
  __asm__ volatile("vaddps %[p],%[b],%[b]\n\tvdivps %[g],%[b],%[b]"
   :[b]"+&x"(b):[p]"x"(p),[g]"x"(vg8));
  _mm256_storeu_ps(out+i,b);
#endif
 }
 _mm256_zeroupper();
 }
 __m128 vg=_mm_set1_ps(g);
 for(;i<=n-4;i+=4){
  __m128 b=_mm_loadu_ps(phb+i),p=_mm_loadu_ps(ph+i);
#if defined(WRF_PHY_HEIGHT_PARENT_O0)
  __asm__ volatile("addps %[b],%[p]\n\tdivps %[g],%[p]"
   :[p]"+&x"(p):[b]"x"(b),[g]"x"(vg));
  _mm_storeu_ps(out+i,p);
#else
  __asm__ volatile("addps %[p],%[b]\n\tdivps %[g],%[b]"
   :[b]"+&x"(b):[p]"x"(p),[g]"x"(vg));
  _mm_storeu_ps(out+i,b);
#endif
 }
 for(;i<n;i++)out[i]=ordered_scalar(phb+i,ph+i,g);
}
/* GNU13 legacy Fortran REAL32/INTEGER32 by-reference private row ABI.
 * The public phy_prep signature is unchanged; no descriptors or hidden lengths.
 * PURE Fortran interface is truthful: only explicit OUT elements are written.
 * No allocation, globals, errno/FP-environment mutations, or restrict promises.
 */
void wrf_phy_height_row_ordered_(float *out,const float *phb,const float *ph,const int *n,const float *g){
 int count=*n;
 if(count<=0)return;
 phy_height_row_core(out,phb,ph,count,*g);
}
