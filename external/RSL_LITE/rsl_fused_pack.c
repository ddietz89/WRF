/* WRF_GPU_FUSEDPACK: one device kernel per halo exchange instead of one per field and side.
   f_pack_int_ikj records a descriptor (device address of the field strip origin, device address of the mapped RSL
   buffer segment, bounds, memory strides) and returns; rsl_fused_flush launches a single OpenACC kernel over all
   recorded strips on the given async queue (the drain/send-flush points of the batched halo path).
   Compiled with the OpenACC C compiler (see rsl_build.cmd). Pointers in the descriptors are raw device addresses. */
#include <stdio.h>
#include <stdlib.h>
#include <openacc.h>
#define MAXD 1024
#define CHUNK 4096
typedef struct { float *fld; float *buf; int ni, nk, nj; long sk, sj; long n; int pu; } pkd_t;
static pkd_t tab[MAXD] ;
static int ntab = 0 ;
static int fused_on = -1 ;
static long chunk_d_cap = 0 ; static int *chunk_d = NULL ; static long *chunk_s = NULL ;

int rsl_fused_on_ ( void ) {
  if ( fused_on < 0 ) { char *e = getenv("WRF_GPU_FUSEDPACK") ; fused_on = !( e && e[0] == '0' ) ;   /* default on (2026-11-08): -2.3 ms/step on the 2-node 16-rank MPS layout (leave-one-out); 0 = off */ }
  return fused_on ;
}

void rsl_fused_flush_ ( int * q ) ;

/* fld: device address of field(is,ks,js); buf: device address of the buffer start for this strip;
   sk/sj: element strides of the field in k and j; pu: 0 pack (buf <- fld), 1 unpack (fld <- buf) */
void rsl_fused_add_ ( long long * fld, long long * buf, int * ni, int * nk, int * nj, long long * sk, long long * sj, int * pu, int * q ) {
  if ( ntab >= MAXD ) rsl_fused_flush_( q ) ;
  pkd_t *d = &tab[ntab++] ;
  d->fld = (float*)(*fld) ; d->buf = (float*)(*buf) ; d->ni = *ni ; d->nk = *nk ; d->nj = *nj ;
  d->sk = *sk ; d->sj = *sj ; d->n = (long)(*ni) * (*nk) * (*nj) ; d->pu = *pu ;
}

void rsl_fused_flush_ ( int * q ) {
  if ( ntab == 0 ) return ;
  long nch = 0 ; int d ;
  for ( d = 0 ; d < ntab ; d++ ) nch += ( tab[d].n + CHUNK - 1 ) / CHUNK ;
  if ( nch > chunk_d_cap ) { chunk_d_cap = nch + 1024 ; chunk_d = (int*)realloc( chunk_d, chunk_d_cap * sizeof(int) ) ; chunk_s = (long*)realloc( chunk_s, chunk_d_cap * sizeof(long) ) ; }
  long c = 0 ;
  for ( d = 0 ; d < ntab ; d++ ) { long s ; for ( s = 0 ; s < tab[d].n ; s += CHUNK ) { chunk_d[c] = d ; chunk_s[c] = s ; c++ ; } }
  int n = ntab ; int qq = *q ;
  pkd_t *t = tab ; int *cd = chunk_d ; long *cs = chunk_s ; long nc = nch ;
  #pragma acc parallel loop gang copyin(t[0:n], cd[0:nc], cs[0:nc]) async(qq)
  for ( long ch = 0 ; ch < nc ; ch++ ) {
    int dd = cd[ch] ; long s0 = cs[ch] ;
    float *fld = t[dd].fld ; float *buf = t[dd].buf ;
    int ni = t[dd].ni, nk = t[dd].nk ; long sk = t[dd].sk, sj = t[dd].sj, nn = t[dd].n ; int pu = t[dd].pu ;
    long s1 = s0 + CHUNK ; if ( s1 > nn ) s1 = nn ;
    #pragma acc loop vector
    for ( long l = s0 ; l < s1 ; l++ ) {
      long i = l % ni ; long r = l / ni ; long k = r % nk ; long j = r / nk ;
      long fo = i + k * sk + j * sj ;
      if ( pu == 0 ) buf[l] = fld[fo] ; else fld[fo] = buf[l] ;
    }
  }
  ntab = 0 ;
}

/* WRF_GPU_P2PASYNC=3 counter flags (rsl_p2p.c): write / spin-wait on an int in (possibly peer, IPC-mapped) device
   memory from a 1-thread kernel on queue 1 */
void rsl_fl_put ( unsigned long long a, int v )
{
  int * p = (int *)a ;
  #pragma acc serial deviceptr(p) async(1)
  { p[0] = v ; }
}
void rsl_fl_wait ( unsigned long long a, int v, unsigned long long sinka )
{
  /* the observed value is stored to a sink word: with an unused loop result nvc removed the whole spin loop
     (one ld.volatile, no loop) */
  int * p = (int *)a ; int * sk = (int *)sinka ;
  #pragma acc serial deviceptr(p, sk) async(1)
  { int x ;
    do {
      #pragma acc atomic read
      x = p[0] ;
    } while ( x < v ) ;
    sk[0] = x ; }
}
void rsl_fl_zero ( unsigned long long a, int n )
{
  int * p = (int *)a ;
  #pragma acc parallel loop deviceptr(p)
  for ( int i = 0 ; i < n ; i++ ) p[i] = 0 ;
}
