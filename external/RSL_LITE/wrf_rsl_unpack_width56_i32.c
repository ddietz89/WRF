/* Private whole-block width5/6 INTEGER32 unpack. No FP, allocation, restrict,
 * output reads, overlapping-buffer extension, or row dispatch calls. */
#include <stdint.h>
#include <stddef.h>
#include <limits.h>
_Static_assert(CHAR_BIT == 8, "8-bit bytes required");
_Static_assert(sizeof(uint32_t) == 4 && sizeof(int) == 4, "INTEGER32 required");
_Static_assert(PTRDIFF_MAX >= INT64_MAX, "64-bit ptrdiff_t required");
typedef uint32_t v4u32 __attribute__((vector_size(16),aligned(1),may_alias));
int wrf_rsl_unpack_width56_i32(const int *src_base, int *dst_base,
    int js,int je,int ks,int ke,int is,int ie,
    int jms,int jme,int kms,int kme,int ims,int ime)
{
    /* Cast before differences. Check every product before any pointer access.
     * Failure is no-access and allows the original Fortran fallback. */
    if (js>je || ks>ke || is>ie || is<ims || ie>ime ||
        ks<kms || ke>kme || js<jms || je>jme) return 0;
    const int64_t width=(int64_t)ie-(int64_t)is+1;
    const int64_t nk=(int64_t)ke-(int64_t)ks+1;
    const int64_t nj=(int64_t)je-(int64_t)js+1;
    const int64_t nx=(int64_t)ime-(int64_t)ims+1;
    const int64_t nz=(int64_t)kme-(int64_t)kms+1;
    const int64_t ny=(int64_t)jme-(int64_t)jms+1;
    const int64_t word_limit=PTRDIFF_MAX/(int64_t)sizeof(uint32_t);
    if ((width!=5 && width!=6) || nx<=0 || nz<=0 || ny<=0 || nx>word_limit ||
        nz>word_limit/nx) return 0;
    const int64_t jstride=nx*nz;
    if (ny>word_limit/jstride || width>INT_MAX || nk>INT_MAX/width)
        return 0;
    const int64_t per_j=width*nk;
    if (nj>INT_MAX/per_j) return 0;
    const uint32_t *src=(const uint32_t *)src_base;
    uint32_t *dst=(uint32_t *)dst_base;
    /* src is WHOLE packed input base; dst is full outbuf(ims,kms,jms). */
    int64_t packed=0;
    for (int64_t j=0;j<nj;++j) {
        const int64_t jo=((int64_t)js-(int64_t)jms+j)*jstride;
        for (int64_t k=0;k<nk;++k) {
            const int64_t off=((int64_t)is-(int64_t)ims)+
                ((int64_t)ks-(int64_t)kms+k)*nx+jo;
            const uint32_t *row=src+(ptrdiff_t)packed;
            uint32_t *to=dst+(ptrdiff_t)off;
            int64_t i=0;
            for (;i+4<=width;i+=4)
                *(v4u32 *)(to+i)=*(const v4u32 *)(row+i);
            if (i<width) { to[i]=row[i]; ++i; }
            if (i<width) { to[i]=row[i]; ++i; }
            if (i<width) { to[i]=row[i]; }
            packed+=width;
        }
    }
    return 1;
}
