/* deflate_fast.c -- compress data using the fast strategy of deflation algorithm
 *
 * Copyright (C) 1995-2024 Jean-loup Gailly and Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "zbuild.h"
#include "deflate.h"
#include "deflate_p.h"
#include "functable.h"

#if defined(X86_AVX2) && defined(HAVE_BUILTIN_CTZ) && !defined(ZLIB_DEBUG) && !defined(DISABLE_RUNTIME_CPU_DETECTION)
#include "arch_functions.h"
Z_INTERNAL block_state zng_private_deflate_fast_avx2(deflate_state *s, int flush);
#define deflate_fast zng_private_deflate_fast_generic
#define ZNG_PRIVATE_FAST_MATCH FUNCTABLE_CALL(longest_match)
#include "deflate_fast_shared.h"
#undef ZNG_PRIVATE_FAST_MATCH
#undef deflate_fast

Z_INTERNAL block_state deflate_fast(deflate_state *s, int flush) {
    if (FUNCTABLE_FPTR(longest_match) == longest_match_avx2)
        return zng_private_deflate_fast_avx2(s, flush);
    return zng_private_deflate_fast_generic(s, flush);
}
#else
#define ZNG_PRIVATE_FAST_MATCH FUNCTABLE_CALL(longest_match)
#include "deflate_fast_shared.h"
#undef ZNG_PRIVATE_FAST_MATCH
#endif
