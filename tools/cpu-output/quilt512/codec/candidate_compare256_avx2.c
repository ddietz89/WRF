/* compare256_avx2.c -- AVX2 version of compare256
 * Copyright Mika T. Lindqvist  <postmaster@raasu.org>
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "zbuild.h"
#include "zmemory.h"
#include "deflate.h"
#include "fallback_builtins.h"

#if defined(X86_AVX2) && defined(HAVE_BUILTIN_CTZ)

#include <immintrin.h>
#ifdef _MSC_VER
#  include <nmmintrin.h>
#endif

static inline uint32_t compare256_avx2_static(const uint8_t *src0, const uint8_t *src1) {
    uint32_t len = 0;

    do {
        __m256i ymm_src0, ymm_src1, ymm_cmp;
        ymm_src0 = _mm256_loadu_si256((__m256i*)src0);
        ymm_src1 = _mm256_loadu_si256((__m256i*)src1);
        ymm_cmp = _mm256_cmpeq_epi8(ymm_src0, ymm_src1); /* non-identical bytes = 00, identical bytes = FF */
        unsigned mask = (unsigned)_mm256_movemask_epi8(ymm_cmp);
        if (mask != 0xFFFFFFFF) {
            uint32_t match_byte = (uint32_t)__builtin_ctz(~mask); /* Invert bits so identical = 0 */
            return len + match_byte;
        }

        src0 += 32, src1 += 32, len += 32;

        ymm_src0 = _mm256_loadu_si256((__m256i*)src0);
        ymm_src1 = _mm256_loadu_si256((__m256i*)src1);
        ymm_cmp = _mm256_cmpeq_epi8(ymm_src0, ymm_src1);
        mask = (unsigned)_mm256_movemask_epi8(ymm_cmp);
        if (mask != 0xFFFFFFFF) {
            uint32_t match_byte = (uint32_t)__builtin_ctz(~mask);
            return len + match_byte;
        }

        src0 += 32, src1 += 32, len += 32;
    } while (len < 256);

    return 256;
}

Z_INTERNAL uint32_t compare256_avx2(const uint8_t *src0, const uint8_t *src1) {
    return compare256_avx2_static(src0, src1);
}

#define LONGEST_MATCH       longest_match_avx2
#define COMPARE256          compare256_avx2_static

#include "match_tpl.h"

#define LONGEST_MATCH_SLOW
#define LONGEST_MATCH       longest_match_slow_avx2
#define COMPARE256          compare256_avx2_static

#include "match_tpl.h"


/* Private whole-caller clone. Existing normal/slow matchers above are unchanged. */
#if !defined(ZLIB_DEBUG) && !defined(DISABLE_RUNTIME_CPU_DETECTION)
#include "deflate_p.h"
#include "functable.h"

#pragma push_macro("Z_INTERNAL")
#pragma push_macro("LONGEST_MATCH")
#pragma push_macro("LONGEST_MATCH_SLOW")
#pragma push_macro("COMPARE256")
#pragma push_macro("GOTO_NEXT_CHAIN")
#undef Z_INTERNAL
#define Z_INTERNAL static Z_FORCEINLINE
#undef LONGEST_MATCH
#define LONGEST_MATCH zng_private_longest_match_avx2_inline
#undef LONGEST_MATCH_SLOW
#undef COMPARE256
#define COMPARE256 compare256_avx2_static
#include "match_tpl.h"
#pragma pop_macro("GOTO_NEXT_CHAIN")
#pragma pop_macro("COMPARE256")
#pragma pop_macro("LONGEST_MATCH_SLOW")
#pragma pop_macro("LONGEST_MATCH")
#pragma pop_macro("Z_INTERNAL")

#pragma push_macro("deflate_fast")
#pragma push_macro("ZNG_PRIVATE_FAST_MATCH")
#define deflate_fast zng_private_deflate_fast_avx2
#define ZNG_PRIVATE_FAST_MATCH zng_private_longest_match_avx2_inline
#include "deflate_fast_shared.h"
#pragma pop_macro("ZNG_PRIVATE_FAST_MATCH")
#pragma pop_macro("deflate_fast")
#endif

#endif
