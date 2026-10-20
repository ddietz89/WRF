#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <pthread.h>
#include <zlib.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <netcdf.h>
#include <sched.h>
#include <errno.h>
#include <stdio.h>
#include "netcdf_precompressed.h"
#include "root_chunk_provider.h"

#ifndef WPS_ROOT_PROVIDER_MAX_THREADS
#define WPS_ROOT_PROVIDER_MAX_THREADS 4
#endif
#define WPS_CHUNK_LIMIT (64u*1024u*1024u)

static int wps_mult(size_t a,size_t b,size_t*out){if(b&&a>SIZE_MAX/b)return 0;*out=a*b;return 1;}

static int layout_valid(const nc_precompressed_float_layout *l,size_t bytes,size_t *chunk_bytes){
 size_t raw=1,n=1;uint32_t one=1;
 if(!l||l->abi_version!=1||l->ndims<1||l->ndims>4||!l->batch_count||l->batch_count>4||
    l->batch_first>l->total_chunks||l->batch_count>l->total_chunks-l->batch_first||
    *(unsigned char*)&one!=1||sizeof(float)!=4||FLT_RADIX!=2||FLT_MANT_DIG!=24||FLT_MAX_EXP!=128)return 0;
 for(int d=0;d<l->ndims;d++){
  if(!l->request_count[d]||!l->chunk_dims[d]||l->request_start[d]>SIZE_MAX-l->request_count[d]||
     !wps_mult(raw,l->request_count[d],&raw)||!wps_mult(n,l->chunk_dims[d],&n))return 0;
  for(size_t c=0;c<l->batch_count;c++)if(l->offsets[c][d]%l->chunk_dims[d]||
     l->offsets[c][d]>SIZE_MAX-l->chunk_dims[d]||
     l->offsets[c][d]>=l->request_start[d]+l->request_count[d]||
     l->offsets[c][d]+l->chunk_dims[d]<=l->request_start[d])return 0;
 }
 if(!wps_mult(raw,4,&raw)||raw!=bytes||!wps_mult(n,4,&n)||n>WPS_CHUNK_LIMIT||n>INT_MAX/4)return 0;
 *chunk_bytes=n;return 1;
}

typedef struct { size_t nbytes; unsigned char*comp; size_t cap; size_t out; int err; int cpu; const nc_precompressed_float_layout*layout; const unsigned char*raw; size_t chunk; } wps_job;

/* shuffle4_candidate.c
 * Standalone four-byte-plane transpose kernel, C11.
 * dst[b*stride + i] = src[4*i + b], where items = nbytes/4 and stride is the
 * destination plane stride (distinct from items for row sub-spans).
 */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#if defined(__x86_64__) || defined(__i386__)
#  define SHUF4_X86 1
#  include <immintrin.h>
#else
#  define SHUF4_X86 0
#endif

static void shuffle4_scalar(unsigned char *dst, size_t stride, const unsigned char *src, size_t nbytes) {
    size_t items = nbytes >> 2;
    size_t i;
    for (i = 0; i < items; i++) {
        const unsigned char *s = src + 4u * i;
        dst[i] = s[0];
        dst[stride + i] = s[1];
        dst[2u * stride + i] = s[2];
        dst[3u * stride + i] = s[3];
    }
}

#if SHUF4_X86
__attribute__((target("avx2")))
static void shuffle4_avx2(unsigned char *dst, size_t stride, const unsigned char *src, size_t nbytes) {
    size_t items = nbytes >> 2;
    size_t i = 0;

    /* Four lane-local transposes, then assemble 32 consecutive bytes/plane. */
    const __m256i transpose = _mm256_setr_epi8(
        0,4,8,12, 1,5,9,13, 2,6,10,14, 3,7,11,15,
        0,4,8,12, 1,5,9,13, 2,6,10,14, 3,7,11,15);
    const __m256i order = _mm256_setr_epi32(0,4,1,5,2,6,3,7);
    for (; i + 32 <= items; i += 32) {
        const unsigned char *s = src + 4u * i;
        __m256i a = _mm256_shuffle_epi8(_mm256_loadu_si256((const __m256i *)(const void *)(s)), transpose);
        __m256i b = _mm256_shuffle_epi8(_mm256_loadu_si256((const __m256i *)(const void *)(s + 32)), transpose);
        __m256i c = _mm256_shuffle_epi8(_mm256_loadu_si256((const __m256i *)(const void *)(s + 64)), transpose);
        __m256i d = _mm256_shuffle_epi8(_mm256_loadu_si256((const __m256i *)(const void *)(s + 96)), transpose);
        __m256i ab0 = _mm256_unpacklo_epi32(a, b);
        __m256i ab1 = _mm256_unpackhi_epi32(a, b);
        __m256i cd0 = _mm256_unpacklo_epi32(c, d);
        __m256i cd1 = _mm256_unpackhi_epi32(c, d);
        __m256i p0 = _mm256_permutevar8x32_epi32(_mm256_unpacklo_epi64(ab0, cd0), order);
        __m256i p1 = _mm256_permutevar8x32_epi32(_mm256_unpackhi_epi64(ab0, cd0), order);
        __m256i p2 = _mm256_permutevar8x32_epi32(_mm256_unpacklo_epi64(ab1, cd1), order);
        __m256i p3 = _mm256_permutevar8x32_epi32(_mm256_unpackhi_epi64(ab1, cd1), order);
        _mm256_storeu_si256((__m256i *)(void *)(dst + i), p0);
        _mm256_storeu_si256((__m256i *)(void *)(dst + stride + i), p1);
        _mm256_storeu_si256((__m256i *)(void *)(dst + 2u * stride + i), p2);
        _mm256_storeu_si256((__m256i *)(void *)(dst + 3u * stride + i), p3);
    }

    for (; i + 8 <= items; i += 8) {
        const unsigned char *s0 = src + 4u * i;
        __m256i v = _mm256_loadu_si256((const __m256i *)(const void *)s0);

        const __m256i k0 = _mm256_setr_epi8(
            0,4,8,12, 0,4,8,12, 0,4,8,12, 0,4,8,12,
            0,4,8,12, 0,4,8,12, 0,4,8,12, 0,4,8,12);
        const __m256i k1 = _mm256_setr_epi8(
            1,5,9,13, 1,5,9,13, 1,5,9,13, 1,5,9,13,
            1,5,9,13, 1,5,9,13, 1,5,9,13, 1,5,9,13);
        const __m256i k2 = _mm256_setr_epi8(
            2,6,10,14, 2,6,10,14, 2,6,10,14, 2,6,10,14,
            2,6,10,14, 2,6,10,14, 2,6,10,14, 2,6,10,14);
        const __m256i k3 = _mm256_setr_epi8(
            3,7,11,15, 3,7,11,15, 3,7,11,15, 3,7,11,15,
            3,7,11,15, 3,7,11,15, 3,7,11,15, 3,7,11,15);

        __m256i p0 = _mm256_shuffle_epi8(v, k0);
        __m256i p1 = _mm256_shuffle_epi8(v, k1);
        __m256i p2 = _mm256_shuffle_epi8(v, k2);
        __m256i p3 = _mm256_shuffle_epi8(v, k3);

        __m128i a0 = _mm256_castsi256_si128(p0);
        __m128i b0 = _mm256_extracti128_si256(p0, 1);
        __m128i a1 = _mm256_castsi256_si128(p1);
        __m128i b1 = _mm256_extracti128_si256(p1, 1);
        __m128i a2 = _mm256_castsi256_si128(p2);
        __m128i b2 = _mm256_extracti128_si256(p2, 1);
        __m128i a3 = _mm256_castsi256_si128(p3);
        __m128i b3 = _mm256_extracti128_si256(p3, 1);

        _mm_storel_epi64((__m128i *)(void *)(dst + i), _mm_unpacklo_epi32(a0, b0));
        _mm_storel_epi64((__m128i *)(void *)(dst + stride + i), _mm_unpacklo_epi32(a1, b1));
        _mm_storel_epi64((__m128i *)(void *)(dst + 2u * stride + i), _mm_unpacklo_epi32(a2, b2));
        _mm_storel_epi64((__m128i *)(void *)(dst + 3u * stride + i), _mm_unpacklo_epi32(a3, b3));
    }

    for (; i < items; i++) {
        const unsigned char *s = src + 4u * i;
        dst[i] = s[0];
        dst[stride + i] = s[1];
        dst[2u * stride + i] = s[2];
        dst[3u * stride + i] = s[3];
    }
}
#endif

static void wps_shuffle4(unsigned char *dst, size_t stride, const unsigned char *src, size_t nbytes) {
    if (nbytes == 0) return;

#if SHUF4_X86
    if (__builtin_cpu_supports("avx2")) {
        shuffle4_avx2(dst, stride, src, nbytes);
        return;
    }
#endif
    shuffle4_scalar(dst, stride, src, nbytes);
}

/* Direct pack into four byte planes; full fill and active row bytes unchanged. */
static void wps_pack_shuffle4(const nc_precompressed_float_layout*l,size_t c,
                     const unsigned char*raw,unsigned char*out,size_t nbytes){
    size_t items=nbytes/4;
    int last=l->ndims-1;
    size_t width=l->chunk_dims[last];
    size_t rows=nbytes/4/width;
    size_t lo=l->offsets[c][last]>l->request_start[last]?l->offsets[c][last]:l->request_start[last];
    size_t hi=l->offsets[c][last]+width;
    size_t limit=l->request_start[last]+l->request_count[last];
    if(hi>limit)hi=limit;
    if(hi<=lo){
        for(size_t byte=0;byte<4;byte++)memset(out+byte*items,l->fill_le[byte],items);
        return;
    }
    size_t row_off=lo-l->offsets[c][last];
    size_t act=hi-lo;
    for(size_t row=0;row<rows;row++){
        size_t rem=row,index=0,pos[4]={0};int inside=1;
        for(int d=last-1;d>=0;d--){
            pos[d]=l->offsets[c][d]+rem%l->chunk_dims[d];
            rem/=l->chunk_dims[d];
            if(pos[d]<l->request_start[d]||pos[d]>=l->request_start[d]+l->request_count[d])inside=0;
        }
        unsigned char*dst=out+row*width;
        if(!inside){
            for(size_t byte=0;byte<4;byte++){
                unsigned char bv=l->fill_le[byte];
                memset(dst+byte*items,bv,width);
            }
            continue;
        }
        for(int d=0;d<last;d++)index=index*l->request_count[d]+pos[d]-l->request_start[d];
        index=index*l->request_count[last]+lo-l->request_start[last];
        for(size_t byte=0;byte<4;byte++){
            unsigned char bv=l->fill_le[byte];
            if(row_off>0)memset(dst+byte*items,bv,row_off);
            size_t tail=row_off+act;
            if(tail<width)memset(dst+byte*items+tail,bv,width-tail);
        }
        wps_shuffle4(dst+row_off,items,raw+4*index,4*act);
    }
}


/* Each thread: private shuffle scratch + private z_stream, deflate level 2. */
static void* wps_worker(void*a){
    wps_job*j=(wps_job*)a;
    cpu_set_t wanted,actual;CPU_ZERO(&wanted);CPU_SET(j->cpu,&wanted);
    if(pthread_setaffinity_np(pthread_self(),sizeof wanted,&wanted)||pthread_getaffinity_np(pthread_self(),sizeof actual,&actual)||!CPU_EQUAL(&wanted,&actual)){j->err=1;return NULL;}
    unsigned char*shuf=(unsigned char*)malloc(j->nbytes?j->nbytes:1);
    if(!shuf){j->err=1;return NULL;}
    wps_pack_shuffle4(j->layout,j->chunk,j->raw,shuf,j->nbytes);
    z_stream zs; memset(&zs,0,sizeof zs);
    if(deflateInit2(&zs,2,Z_DEFLATED,15,8,Z_DEFAULT_STRATEGY)!=Z_OK){free(shuf);j->err=1;return NULL;}
    zs.next_in=shuf; zs.avail_in=(uInt)j->nbytes; zs.next_out=j->comp; zs.avail_out=(uInt)j->cap;
    int rc=deflate(&zs,Z_FINISH);
    if(rc!=Z_STREAM_END){deflateEnd(&zs);free(shuf);j->err=1;return NULL;}
    j->out=zs.total_out;
    deflateEnd(&zs); free(shuf);
    return NULL;
}

typedef struct { unsigned char*buffers[4]; } wps_storage;
static void wps_release(void*u){wps_storage*s=u;if(s){for(int i=0;i<4;i++)free(s->buffers[i]);free(s);}}

int wps_root_provider(const nc_precompressed_float_layout*layout,const void*raw,size_t bytes,
                      nc_precompressed_float_batch*result,void*user){
    const root_chunk_options*opt=user;
    if(!layout||!result)return NC_EINVAL;
    memset(result,0,sizeof *result);
#ifdef WPS_ROOT_PROVIDER_DISABLED
    return 0;
#endif
    if(!raw||!opt||(opt->threads!=1&&opt->threads!=4))return NC_EINVAL;
    size_t chunk_bytes=0;if(!layout_valid(layout,bytes,&chunk_bytes))return NC_EINVAL;
    if(layout->ndims<3||layout->chunk_dims[0]!=1||layout->request_count[0]!=1)return NC_EINVAL;
    cpu_set_t allowed;if(sched_getaffinity(0,sizeof allowed,&allowed))return NC_EINVAL;
    for(int i=0;i<4;i++){if(opt->cpus[i]<0||opt->cpus[i]>=CPU_SETSIZE||!CPU_ISSET(opt->cpus[i],&allowed))return NC_EINVAL;for(int k=0;k<i;k++)if(opt->cpus[i]==opt->cpus[k])return NC_EINVAL;}


    wps_job jobs[NC_PRECOMPRESSED_BATCH_MAX];
    pthread_t tid[NC_PRECOMPRESSED_BATCH_MAX];
    for(size_t c=0;c<layout->batch_count;c++){
        jobs[c].nbytes=chunk_bytes; jobs[c].cap=compressBound((uLong)chunk_bytes);
        jobs[c].comp=(unsigned char*)malloc(jobs[c].cap?jobs[c].cap:1); jobs[c].err=0; jobs[c].out=0; jobs[c].cpu=opt->cpus[c];
        jobs[c].layout=layout; jobs[c].raw=(const unsigned char*)raw; jobs[c].chunk=c;
        if(!jobs[c].comp){for(size_t k=0;k<c;k++)free(jobs[k].comp);return NC_ENOMEM;}
    }
    size_t started=0;int bad=0;
    if(opt->threads==1){for(size_t c=0;c<layout->batch_count;c++){jobs[c].cpu=opt->cpus[0];wps_worker(&jobs[c]);if(jobs[c].err)bad=1;}if(pthread_setaffinity_np(pthread_self(),sizeof allowed,&allowed))abort();}
    else {
      for(size_t c=0;c<layout->batch_count;c++){if(pthread_create(&tid[c],NULL,wps_worker,&jobs[c])!=0)break;started++;}
      bad=(started!=layout->batch_count);
      for(size_t c=0;c<started;c++){if(pthread_join(tid[c],NULL)){/* unsafe to return/free while an unjoined worker may live */ abort();}if(jobs[c].err)bad=1;}
    }
    if(bad){for(size_t c=0;c<layout->batch_count;c++)free(jobs[c].comp);return NC_EIO;}
    wps_storage*st=(wps_storage*)calloc(1,sizeof *st);
    if(!st){for(size_t c=0;c<layout->batch_count;c++)free(jobs[c].comp);return NC_ENOMEM;}
    for(size_t c=0;c<layout->batch_count;c++){
        st->buffers[c]=jobs[c].comp;result->data[c]=jobs[c].comp;result->nbytes[c]=jobs[c].out;
    }
    
    result->count=layout->batch_count; result->release=wps_release; result->release_user=st;
    return 1;
}
