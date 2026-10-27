/* Private source-only prototype. No qualification or default change.
 * Only a positive, multiple-of-four prefix is passed by the masked Fortran
 * wrapper. The original Fortran scalar tail and unmasked path remain outside.
 * Arrays are disjoint current-SPC scratch/input columns, REAL4/INTEGER4.
 */
#include <stdint.h>
#if !defined(__x86_64__) || !defined(__GNUC__)
#error This private prototype requires the reviewed GNU x86-64 SSE2 path.
#endif
typedef struct __attribute__((packed, may_alias)) { float x[4]; } lanes4;

__attribute__((target("sse2,no-avx,no-fma"), noinline))
void wrf_spc_mix_ordered4(int32_t klev, int32_t nvec,
                        const float *ct, const float *co, const float *ca,
                        const float *dt, const float *domega, const float *da,
                        float *to, float *omega, float *asym)
{
    /* Contract: 0 < nvec <= klev, nvec % 4 == 0. No per-lane calls.
     * j+0..3 clear layers pair with klev-1-j .. klev-4-j cloud layers.
     */
    for (int32_t j = 0; j < nvec; j += 4) {
        const int32_t rev = klev - j - 4;
        __asm__ volatile (
            /* tau = clear_tau(dest) + cloud_tau(src), then original store. */
            "movups %[ct], %%xmm0\n\t"
            "movups %[dt], %%xmm3\n\t"
            "shufps $0x1b, %%xmm3, %%xmm3\n\t"
            "addps %%xmm3, %%xmm0\n\t"
            "movups %%xmm0, %[to]\n\t"
            /* denominator = (ct*co)(dest) + (dt*domega)(src). */
            "movups %[ct], %%xmm1\n\t"
            "movups %[co], %%xmm3\n\t"
            "mulps %%xmm3, %%xmm1\n\t"
            "movups %[dt], %%xmm0\n\t"
            "movups %[domega], %%xmm3\n\t"
            "shufps $0x1b, %%xmm0, %%xmm0\n\t"
            "shufps $0x1b, %%xmm3, %%xmm3\n\t"
            "mulps %%xmm3, %%xmm0\n\t"
            "addps %%xmm0, %%xmm1\n\t"
            "movups %%xmm1, %[omega]\n\t"
            /* Repeated products retained, not reused from denominator. */
            "movups %[ct], %%xmm2\n\t"
            "movups %[co], %%xmm3\n\t"
            "mulps %%xmm3, %%xmm2\n\t"
            "movups %[ca], %%xmm3\n\t"
            "mulps %%xmm3, %%xmm2\n\t"
            "movups %[dt], %%xmm0\n\t"
            "movups %[domega], %%xmm3\n\t"
            "shufps $0x1b, %%xmm0, %%xmm0\n\t"
            "shufps $0x1b, %%xmm3, %%xmm3\n\t"
            "mulps %%xmm3, %%xmm0\n\t"
            "movups %[da], %%xmm3\n\t"
            "shufps $0x1b, %%xmm3, %%xmm3\n\t"
            "mulps %%xmm3, %%xmm0\n\t"
            /* numerator = cloud_product(dest) + clear_product(src). */
            "addps %%xmm2, %%xmm0\n\t"
            "divps %%xmm1, %%xmm0\n\t"
            "movups %%xmm0, %[asym]\n\t"
            /* Normalization rereads original denominator/tau stores. */
            "movups %[omega], %%xmm0\n\t"
            "movups %[to], %%xmm3\n\t"
            "divps %%xmm3, %%xmm0\n\t"
            "movups %%xmm0, %[omega]\n\t"
            : [to] "=m" (*(lanes4 *)(to + j)),
              [omega] "=m" (*(lanes4 *)(omega + j)),
              [asym] "=m" (*(lanes4 *)(asym + j))
            : [ct] "m" (*(const lanes4 *)(ct + j)),
              [co] "m" (*(const lanes4 *)(co + j)),
              [ca] "m" (*(const lanes4 *)(ca + j)),
              [dt] "m" (*(const lanes4 *)(dt + rev)),
              [domega] "m" (*(const lanes4 *)(domega + rev)),
              [da] "m" (*(const lanes4 *)(da + rev))
            : "xmm0", "xmm1", "xmm2", "xmm3", "memory"
        );
    }
}
