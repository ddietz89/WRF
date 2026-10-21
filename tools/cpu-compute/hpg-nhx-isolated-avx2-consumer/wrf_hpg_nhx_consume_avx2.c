/* wrf_hpg_nhx_consume_avx2.c -- literal IEEE-ordered X-consumer.
 * Private ABI, AVX2, no FMA, -ffp-contract=off, no fast-math.
 * Loop k0=0..ktf-1, i0=0..n_i-1; q=(k_offset+k0)*ld_i+i_offset+i0. */
#include <stddef.h>
#include <immintrin.h>

void wrf_hpg_nhx_consume_avx2(int n_i, int ld_i, int ktf,
    int i_offset, int k_offset, float rdx,
    float *ru, const float *ph, const float *alt, const float *p,
    const float *pb, const float *al, const float *php, const float *cqu,
    const float *muu, const float *mu, const float *ratio, const float *dpn,
    const float *c1h, const float *c2h, const float *c1, const float *rdnw)
{
  const ptrdiff_t LD  = (ptrdiff_t)ld_i;
  const ptrdiff_t IO  = (ptrdiff_t)i_offset;
  const ptrdiff_t KO  = (ptrdiff_t)k_offset;
  int k0, i0;

  if (n_i <= 0 || ktf <= 0) return;   /* before ANY load/store/FP */
  const __m256 vrdx = _mm256_set1_ps(rdx);
  const __m256 vhalf = _mm256_set1_ps(0.5f);

  /* Preserve original traversal: K outer, contiguous-I vector blocks then tails. */
  for (k0 = 0; k0 < ktf; ++k0) {
    i0 = 0;
    for (; i0 + 7 < n_i; i0 += 8) {
      const ptrdiff_t q  = (KO + (ptrdiff_t)k0) * LD;
      const ptrdiff_t q0 = q + IO + (ptrdiff_t)i0;      /* base element for lane0 */
      const ptrdiff_t kq = KO + (ptrdiff_t)k0;
      __m256 dpx, tmp;
      __m256 vbracket, vc2h;

      /* factor1 = (ratio*.5f) */
      const __m256 vratio = _mm256_loadu_ps(ratio + IO + i0);
      const __m256 vmuu   = _mm256_loadu_ps(muu   + IO + i0);
      __m256 factor = _mm256_mul_ps(vratio, vhalf);          /* ratio*.5f  */
      factor = _mm256_mul_ps(factor, vrdx);                  /* *rdx       */
      {
        const float c1hk = c1h[kq];                          /* scalar broadcast, bits only */
        const float c2hk = c2h[kq];
        const __m256 vc1h = _mm256_set1_ps(c1hk);
        vc2h = _mm256_set1_ps(c2hk);
        tmp  = _mm256_mul_ps(vc1h, vmuu);                    /* c1h*muu    */
        tmp  = _mm256_add_ps(tmp, vc2h);                     /* +c2h       */
      }
      factor = _mm256_mul_ps(factor, tmp);                   /* *(c1h*muu+c2h) */

      /* bracket = ((ph_up - ph_left_up) + ph_here) - ph_left_here ; left-associated */
      {
        const __m256 ph_up        = _mm256_loadu_ps(ph  + q0 + LD);
        const __m256 ph_left_up   = _mm256_loadu_ps(ph  + q0 + LD - 1);
        const __m256 ph_here      = _mm256_loadu_ps(ph  + q0);
        const __m256 ph_left_here = _mm256_loadu_ps(ph  + q0 - 1);
        __m256 b = _mm256_sub_ps(ph_up, ph_left_up);         /* ph_up-ph_left_up */
        b = _mm256_add_ps(b, ph_here);                       /* +ph_here         */
        b = _mm256_sub_ps(b, ph_left_here);                  /* -ph_left_here    */
        /* term2 = (alt+alt_left)*(p-p_left) */
        const __m256 alt_here      = _mm256_loadu_ps(alt + q0);
        const __m256 alt_left      = _mm256_loadu_ps(alt + q0 - 1);
        const __m256 p_here        = _mm256_loadu_ps(p   + q0);
        const __m256 p_left        = _mm256_loadu_ps(p   + q0 - 1);
        const __m256 alt_sum = _mm256_add_ps(alt_here, alt_left);
        const __m256 p_diff  = _mm256_sub_ps(p_here, p_left);
        const __m256 term2   = _mm256_mul_ps(alt_sum, p_diff);
        b = _mm256_add_ps(b, term2);
        /* term3 = (al+al_left)*(pb-pb_left) */
        const __m256 al_here  = _mm256_loadu_ps(al + q0);
        const __m256 al_left  = _mm256_loadu_ps(al + q0 - 1);
        const __m256 pb_here  = _mm256_loadu_ps(pb + q0);
        const __m256 pb_left  = _mm256_loadu_ps(pb + q0 - 1);
        const __m256 al_sum = _mm256_add_ps(al_here, al_left);
        const __m256 pb_diff= _mm256_sub_ps(pb_here, pb_left);
        const __m256 term3  = _mm256_mul_ps(al_sum, pb_diff);
        b = _mm256_add_ps(b, term3);
        vbracket = b;
      }
      dpx = _mm256_mul_ps(factor, vbracket);

      /* second term: ratio*rdx*(php-php_left)*(rdnw*(dpn_up-dpn)-.5f*((c1*mu_left)+(c1*mu_here))) */
      {
        const __m256 php_here     = _mm256_loadu_ps(php    + q0);
        const __m256 php_left     = _mm256_loadu_ps(php    + q0 - 1);
        const __m256 dpn_here     = _mm256_loadu_ps(dpn    + q0);
        const __m256 dpn_up       = _mm256_loadu_ps(dpn    + q0 + LD);
        const __m256 mu_left      = _mm256_loadu_ps(mu     + IO + i0 - 1);
        const __m256 mu_here      = _mm256_loadu_ps(mu     + IO + i0);
        const float  rdnwk        = rdnw[kq];
        const float  c1k          = c1[kq];
        const __m256 vrdnw        = _mm256_set1_ps(rdnwk);
        const __m256 vc1          = _mm256_set1_ps(c1k);
        const __m256 php_diff     = _mm256_sub_ps(php_here, php_left);
        __m256 s = _mm256_mul_ps(vratio, vrdx);               /* ratio*rdx */
        s = _mm256_mul_ps(s, php_diff);                       /* *php_diff */
        const __m256 dpn_diff = _mm256_sub_ps(dpn_up, dpn_here);
        __m256 inner = _mm256_mul_ps(vrdnw, dpn_diff);        /* rdnw*(dpn_up-dpn) */
        const __m256 c1mu_left = _mm256_mul_ps(vc1, mu_left); /* c1*mu_left  */
        const __m256 c1mu_here = _mm256_mul_ps(vc1, mu_here); /* c1*mu_here  */
        const __m256 c1sum = _mm256_add_ps(c1mu_left, c1mu_here);
        const __m256 halfc = _mm256_mul_ps(vhalf, c1sum);     /* .5f*(...)   */
        inner = _mm256_sub_ps(inner, halfc);
        const __m256 term2b = _mm256_mul_ps(s, inner);
        dpx = _mm256_add_ps(dpx, term2b);
      }

      /* ru_tend = ru_tend - cqu*dpx ; same left-to-right operand roles */
      {
        const __m256 cqu_v = _mm256_loadu_ps(cqu + q0);
        const __m256 ru_v  = _mm256_loadu_ps(ru  + q0);
        const __m256 cqu_dpx = _mm256_mul_ps(cqu_v, dpx);
        const __m256 res = _mm256_sub_ps(ru_v, cqu_dpx);
        _mm256_storeu_ps(ru + q0, res);
      }
    
    }
    for (; i0 < n_i; ++i0) {
      const ptrdiff_t v = IO + (ptrdiff_t)i0;
      const ptrdiff_t q  = (KO + (ptrdiff_t)k0) * LD;
      const ptrdiff_t q0 = q + v;
      const ptrdiff_t kq = KO + (ptrdiff_t)k0;
      const float ratio_i = ratio[v];
      float dpx, factor, bracket, s, inner, c1sum;
      factor = ratio_i * 0.5f;
      factor = factor * rdx;
      factor = factor * (c1h[kq] * muu[v] + c2h[kq]);
      bracket = (ph[q0 + LD] - ph[q0 + LD - 1]) + ph[q0];
      bracket = bracket - ph[q0 - 1];
      bracket = bracket + (alt[q0] + alt[q0 - 1]) * (p[q0] - p[q0 - 1]);
      bracket = bracket + (al[q0] + al[q0 - 1]) * (pb[q0] - pb[q0 - 1]);
      dpx = factor * bracket;
      s = ratio_i * rdx;
      s = s * (php[q0] - php[q0 - 1]);
      c1sum = c1[kq] * mu[v - 1];
      c1sum = c1sum + c1[kq] * mu[v];
      inner = rdnw[kq] * (dpn[q0 + LD] - dpn[q0]);
      inner = inner - 0.5f * c1sum;
      dpx = dpx + s * inner;
      ru[q0] = ru[q0] - cqu[q0] * dpx;
    
    }
  }
}
