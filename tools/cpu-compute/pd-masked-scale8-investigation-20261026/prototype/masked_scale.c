#include <immintrin.h>
/* Return only the processed full-vector prefix. The caller runs the exact
 * scalar source for tails and when IEEE traps are enabled. No control writes. */
int pd_masked_scale8(int n,const float *flux,const float *phlow,float eps,float *out){
    if ((_mm_getcsr() & 0x1f80u) != 0x1f80u) return 0;
    int end=n-(n%8);
    __m256 z=_mm256_setzero_ps(),one=_mm256_set1_ps(1.0f);
    __m256 e=_mm256_set1_ps(eps),minusone=_mm256_set1_ps(-1.0f);
    for(int i=0;i<end;i+=8){
        __m256 f=_mm256_loadu_ps(flux+i),p=_mm256_loadu_ps(phlow+i);
        __m256 active=_mm256_cmp_ps(f,p,_CMP_GT_OS);
        if (_mm256_movemask_ps(active)==0) {
            _mm256_storeu_ps(out+i,minusone);
            continue;
        }
        __m256 numerator=_mm256_and_ps(active,p);
        __m256 left=_mm256_and_ps(active,f);
        __m256 right=_mm256_blendv_ps(one,e,active);
        __m256 denominator=_mm256_add_ps(left,right);
        __m256 ratio=_mm256_div_ps(numerator,denominator);
        __m256 nonnegative=_mm256_max_ps(ratio,z);
        _mm256_storeu_ps(out+i,_mm256_blendv_ps(minusone,nonnegative,active));
    }
    return end;
}
