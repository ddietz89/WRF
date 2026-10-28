#include <xmmintrin.h>
/* n is a positive multiple of four. prev/current rows are disjoint K rows.
 * CMP_LT is signaling, ordered threshold<previous: NaN false -> ELSE.
 * Suppress inactive COPY-lane arithmetic with bitwise +0/1 operands before MUL. */
void wrf_lw_overlap_ordered4(int n,const float*prev,float*cur,const float*t){
 __m128 th=_mm_set1_ps(*t),one=_mm_set1_ps(1.0f);
 for(int j=0;j<n;j+=4){
   __m128 p=_mm_loadu_ps(prev+j),c=_mm_loadu_ps(cur+j),copy=th;
   __asm__("cmpltps %1,%0":"+x"(copy):"x"(p));
   __m128 cm=_mm_andnot_ps(copy,c);
   __m128 tm=_mm_or_ps(_mm_andnot_ps(copy,th),_mm_and_ps(copy,one));
   __asm__("mulps %1,%0":"+x"(cm):"x"(tm));
   __m128 result=_mm_or_ps(_mm_and_ps(copy,p),_mm_andnot_ps(copy,cm));
   _mm_storeu_ps(cur+j,result);
 }
}
