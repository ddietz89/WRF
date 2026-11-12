/* GPU peer-to-peer halo exchange for RSL_LITE (WRF_GPU_HALOP2P=1, needs WRF_GPU_HALOBATCH=1).
   Receive buffers get their device mirror from cuMemAlloc (acc_map_data onto the RSL host buffer), so a
   neighbour rank can write into it through a CUDA IPC handle. Per exchange and neighbour:
     1. device packs are drained (rsl_gpu_send_flush-style wait, no D2H)
     2. token 1 (MPI): {all-device flag, send bytes, IPC handle of my receive mirror} both ways
     3. if both sides are all-device: cuMemcpyDtoD my packed send mirror -> peer's receive mirror
     4. token 2 (MPI): copy done; unpacks then read the receive mirror on queue 1
   Otherwise the batched path (D2H, MPI data, H2D) is used for that exchange.
   Both GPUs must be visible in each process (CUDA_VISIBLE_DEVICES=own,peer; device 0 = own).
   All CUDA/OpenACC entry points are resolved with dlsym, so non-GPU builds link unchanged. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#ifndef STUBMPI
#include "mpi.h"
#endif
#include "rsl_lite.h"

typedef struct { char r[64] ; } ipch_t ;
static int p2p_on = -1 ;
static int (*cu_alloc)(unsigned long long *, size_t) ;
static int (*cu_free)(unsigned long long) ;
static int (*cu_ipc_get)(ipch_t *, unsigned long long) ;
static int (*cu_ipc_open)(unsigned long long *, ipch_t, unsigned int) ;
static int (*cu_ipc_close)(unsigned long long) ;
static int (*cu_d2d)(unsigned long long, unsigned long long, size_t) ;
static int (*cu_sync)(void) ;
static void (*acc_map)(void *, void *, size_t) ;
static void (*acc_unmap)(void *) ;
static void * (*acc_dptr)(void *) ;
static int (*cu_d2h_async)(void *, unsigned long long, size_t, void *) ;
static int (*cu_h2d_async)(unsigned long long, const void *, size_t, void *) ;
static int (*cu_ev_create)(void **, unsigned int) ;
static int (*cu_ev_record)(void *, void *) ;
static int (*cu_ev_sync)(void *) ;
static void * (*acc_stream)(int) ;
/* WRF_GPU_P2PASYNC=1 */
static int (*cu_ipc_ev_get)(ipch_t *, void *) ;
static int (*cu_ipc_ev_open)(void **, ipch_t) ;
static int (*cu_wait_ev)(void *, void *, unsigned int) ;
static int (*cu_d2d_async)(unsigned long long, unsigned long long, size_t, void *) ;
static int (*cu_d2h)(void *, unsigned long long, size_t) ;

int rsl_p2p_enabled ( void )
{
  if ( p2p_on < 0 ) {
    char *e = getenv("WRF_GPU_HALOP2P"), *b = getenv("WRF_GPU_HALOBATCH") ;
    p2p_on = ( e && e[0] != '0' && b && b[0] != '0' ) ;
    if ( p2p_on ) {
      void *h = dlopen("libcuda.so.1", RTLD_NOW) ;
      if ( h ) {
        cu_alloc = (int(*)(unsigned long long*,size_t))dlsym(h,"cuMemAlloc_v2") ;
        cu_free = (int(*)(unsigned long long))dlsym(h,"cuMemFree_v2") ;
        cu_ipc_get = (int(*)(ipch_t*,unsigned long long))dlsym(h,"cuIpcGetMemHandle") ;
        cu_ipc_open = (int(*)(unsigned long long*,ipch_t,unsigned int))dlsym(h,"cuIpcOpenMemHandle_v2") ;
        if ( !cu_ipc_open ) cu_ipc_open = (int(*)(unsigned long long*,ipch_t,unsigned int))dlsym(h,"cuIpcOpenMemHandle") ;
        cu_ipc_close = (int(*)(unsigned long long))dlsym(h,"cuIpcCloseMemHandle") ;
        cu_d2d = (int(*)(unsigned long long,unsigned long long,size_t))dlsym(h,"cuMemcpyDtoD_v2") ;
        cu_sync = (int(*)(void))dlsym(h,"cuCtxSynchronize") ;
        cu_d2h_async = (int(*)(void*,unsigned long long,size_t,void*))dlsym(h,"cuMemcpyDtoHAsync_v2") ;
        cu_h2d_async = (int(*)(unsigned long long,const void*,size_t,void*))dlsym(h,"cuMemcpyHtoDAsync_v2") ;
        cu_ev_create = (int(*)(void**,unsigned int))dlsym(h,"cuEventCreate") ;
        cu_ev_record = (int(*)(void*,void*))dlsym(h,"cuEventRecord") ;
        cu_ev_sync = (int(*)(void*))dlsym(h,"cuEventSynchronize") ;
        cu_ipc_ev_get = (int(*)(ipch_t*,void*))dlsym(h,"cuIpcGetEventHandle") ;
        cu_ipc_ev_open = (int(*)(void**,ipch_t))dlsym(h,"cuIpcOpenEventHandle") ;
        cu_wait_ev = (int(*)(void*,void*,unsigned int))dlsym(h,"cuStreamWaitEvent") ;
        cu_d2d_async = (int(*)(unsigned long long,unsigned long long,size_t,void*))dlsym(h,"cuMemcpyDtoDAsync_v2") ;
        cu_d2h = (int(*)(void*,unsigned long long,size_t))dlsym(h,"cuMemcpyDtoH_v2") ;
      }
      acc_stream = (void*(*)(int))dlsym(RTLD_DEFAULT,"acc_get_cuda_stream") ;
      acc_map = (void(*)(void*,void*,size_t))dlsym(RTLD_DEFAULT,"acc_map_data") ;
      acc_unmap = (void(*)(void*))dlsym(RTLD_DEFAULT,"acc_unmap_data") ;
      acc_dptr = (void*(*)(void*))dlsym(RTLD_DEFAULT,"acc_deviceptr") ;
      if ( !h || !cu_alloc || !cu_free || !cu_ipc_get || !cu_ipc_open || !cu_ipc_close || !cu_d2d || !cu_sync || !acc_map || !acc_unmap || !acc_dptr ) {
        fprintf(stderr,"RSL P2P: CUDA/OpenACC entry points not found, P2P halos off\n") ; p2p_on = 0 ;
      } else fprintf(stderr,"RSL P2P: peer-to-peer device halos on\n") ;
    }
  }
  return p2p_on ;
}

/* receive-buffer device mirrors, by processor */
static unsigned long long rdev[RSL_MAXPROC] ; static int rsize[RSL_MAXPROC] ; static char *rhost[RSL_MAXPROC] ;
static ipch_t rh[RSL_MAXPROC] ;
/* opened peer mirrors, by processor */
static unsigned long long pdev[RSL_MAXPROC] ; static ipch_t ph[RSL_MAXPROC] ; static int popen_[RSL_MAXPROC] ;

/* called by buffer_for_proc for RSL_RECVBUF: map (on=1) or unmap (on=0). Returns 1 if handled. */
int rsl_p2p_recv_map ( int P, char * host, int n, int on )
{
  if ( !rsl_p2p_enabled() || P < 0 || P >= RSL_MAXPROC ) return 0 ;
  if ( on ) {
    unsigned long long d = 0 ; int r = cu_alloc( &d, (size_t)n ) ;
    if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuMemAlloc(%d) rc=%d\n",n,r) ; return 0 ; }
    acc_map( host, (void *)d, (size_t)n ) ;
    r = cu_ipc_get( &rh[P], d ) ; if ( r != 0 ) fprintf(stderr,"RSL P2P: cuIpcGetMemHandle rc=%d\n",r) ;
    rdev[P] = d ; rsize[P] = n ; rhost[P] = host ;
  } else {
    if ( rhost[P] != host || rdev[P] == 0 ) return 0 ;
    acc_unmap( host ) ; cu_free( rdev[P] ) ; rdev[P] = 0 ; rsize[P] = 0 ; rhost[P] = NULL ;
  }
  return 1 ;
}

#ifndef STUBMPI
typedef struct { int alldev ; int nbytes ; int rexp ; int cap ; ipch_t h ; unsigned long long host ; int async ; ipch_t evr ; ipch_t evd ; ipch_t fh ; } tok_t ;
/* WRF_GPU_P2PASYNC=1: no host wait in a P2P exchange. Per neighbour P this rank owns two interprocess events:
   evr[P] ("my receive buffer for P is free": recorded on the queue-1 stream when the exchange starts, i.e. after
   the unpacks of the previous exchange) and evd[P] ("my data is in P's receive buffer": recorded after the copy).
   The copy into P's buffer is an async DtoD on the queue-1 stream behind a wait on P's evr; the unpacks (queue 1)
   follow a stream wait on P's evd. The two MPI tokens only order the event records against the stream waits
   (each record happens before the token that announces it, each wait after the token is received), so the GPU
   queue is never drained for a P2P exchange. */
static int p2pasync_on = -1, p2pasync_sync = 0, p2pasync_flags = 0 ;
/* WRF_GPU_P2PASYNC=3: monotonic counters in device memory instead of IPC events (an event wait issued before the
   peer's record reaches the GPU sees the previous, completed record; =1 differs by 97 vars, =2 with a final context
   sync is exact). Each rank owns ints fl[P] = "my receive buffer from P is free for exchange k" and
   fl[RSL_MAXPROC+P] = "my data for exchange k is in P's buffer", written by 1-thread kernels on the queue-1 stream;
   the neighbour's queue-1 stream spins (1-thread kernel, volatile load of the IPC-mapped peer array) until the
   value reaches k. Counts only grow, so no host ordering is needed after the first token. */
static long rsl_p2p_nx = 0 ; static int p2p_endsync = 0 ;
static unsigned long long fl_dev = 0 ; static ipch_t fl_h ; static int fl_k[RSL_MAXPROC] ;
static unsigned long long pfl[RSL_MAXPROC] ; static ipch_t pfl_h[RSL_MAXPROC] ; static int pfl_open[RSL_MAXPROC] ;
/* 1-thread flag kernels on queue 1: rsl_fused_pack.c (OpenACC) */
void rsl_fl_put ( unsigned long long a, int v ) ;
void rsl_fl_wait ( unsigned long long a, int v, unsigned long long sinka ) ;
void rsl_fl_zero ( unsigned long long a, int n ) ;
#define fl_put rsl_fl_put
#define fl_wait(a_,v_) rsl_fl_wait( (a_), (v_), fl_dev + sizeof(int) * (unsigned long long)(2 * RSL_MAXPROC) )
static void fl_make ( void )
{
  if ( fl_dev ) return ;
  size_t n = ( 2 * RSL_MAXPROC + 1 ) * sizeof(int) ;   /* + sink word for rsl_fl_wait */
  if ( cu_alloc( &fl_dev, n ) || cu_ipc_get( &fl_h, fl_dev ) ) { fprintf(stderr,"RSL P2P: flag alloc failed\n") ; MPI_Abort(MPI_COMM_WORLD, 93) ; }
  rsl_fl_zero( fl_dev, 2 * RSL_MAXPROC + 1 ) ;
}
static void * evr[RSL_MAXPROC], * evd[RSL_MAXPROC] ; static ipch_t evr_h[RSL_MAXPROC], evd_h[RSL_MAXPROC] ;
static void * pevr[RSL_MAXPROC], * pevd[RSL_MAXPROC] ; static ipch_t pevr_h[RSL_MAXPROC], pevd_h[RSL_MAXPROC] ;
int rsl_p2p_async_enabled ( void )
{
  if ( p2pasync_on < 0 ) {
    char *e = getenv("WRF_GPU_P2PASYNC") ;
    p2pasync_sync = ( e && e[0] == '2' ) ;   /* =2 (bisect): async protocol + context sync at the end */
    p2pasync_flags = ( e && e[0] == '3' ) ;
    p2pasync_on = ( e && ( e[0] == '1' || e[0] == '2' || e[0] == '3' ) && rsl_p2p_enabled() && cu_ipc_ev_get && cu_ipc_ev_open && cu_wait_ev &&
                    cu_d2d_async && cu_ev_create && cu_ev_record && acc_stream ) ;
    if ( e && ( e[0] == '1' || e[0] == '2' || e[0] == '3' ) ) fprintf(stderr,"RSL P2P: async exchange %s%s%s\n", p2pasync_on ? "on" : "requested but unavailable", p2pasync_sync ? " (+ sync)" : "", p2pasync_flags ? " (counter flags)" : "") ;
  }
  return p2pasync_on ;
}
/* buffer_for_proc before freeing/remapping a buffer: async P2P copies on the stream may still use the mirrors */
void rsl_p2p_buf_sync ( void ) { if ( p2pasync_on > 0 ) cu_sync() ; }
/* Fortran: drain without waiting for the queue when the async P2P path is on */
int rsl_p2p_async_on_ ( void ) { return rsl_p2p_async_enabled() ; }
static int p2p_ev_make ( int P )
{
  if ( evr[P] ) return 1 ;
  int r1 = cu_ev_create( &evr[P], 2 | 4 /* DISABLE_TIMING | INTERPROCESS */ ) ;
  int r2 = cu_ev_create( &evd[P], 2 | 4 ) ;
  if ( r1 || r2 || cu_ipc_ev_get( &evr_h[P], evr[P] ) || cu_ipc_ev_get( &evd_h[P], evd[P] ) ) {
    fprintf(stderr,"RSL P2P: interprocess events unavailable (rc %d %d)\n", r1, r2) ; MPI_Abort(MPI_COMM_WORLD, 95) ;
  }
  return 1 ;
}
#include <unistd.h>
/* host id (FNV-1a of the hostname): CUDA IPC only works between processes on the same node, so a neighbour pair
   on different nodes uses the batched (host-staged MPI) path */
static unsigned long long rsl_host_id ( void )
{
  static unsigned long long hid = 0 ;
  if ( hid == 0 ) {
    char hn[256] ; size_t k ; hid = 1469598103934665603ULL ;
    memset( hn, 0, sizeof(hn) ) ; gethostname( hn, sizeof(hn)-1 ) ;
    for ( k = 0 ; hn[k] ; k++ ) { hid ^= (unsigned char)hn[k] ; hid *= 1099511628211ULL ; }
    if ( hid == 0 ) hid = 1 ;
  }
  return hid ;
}
/* p2p exchange for up to two neighbours (index 0/1) of one axis. sendb/recvb: send/recv byte counts per
   neighbour. devb: device-packed bytes recorded for this exchange. done[i] = 1 where the neighbour pair used
   P2P (decided symmetrically from both tokens); the caller does the MPI data path for the others. */
/* neighbours known to be on another node (learned symmetrically from the first token exchange with them):
   no token round trip any more, so the same-node P2P partner is not held back by the remote neighbour's
   arrival (that coupled the whole rank chain to the cross-node pair). WRF_GPU_XSKIP=0 keeps the tokens. */
static char rremote[RSL_MAXPROC] ; static int xskip_on = -1 ;
void rsl_p2p_exch ( MPI_Comm comm, int nbr[2], int sendb[2], int recvb[2], long long devb, int done[2] )
{
  tok_t mine[2], theirs[2] ; MPI_Request q[4] ; int nq = 0, i, totsend = 0, any = 0, async_pend = 0 ;
  done[0] = done[1] = 0 ;
  if ( xskip_on < 0 ) { char *e = getenv("WRF_GPU_XSKIP") ; xskip_on = !( e && e[0] == '0' ) ; }
  for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 ) totsend += sendb[i] ;
  int alldev = ( devb == (long long)totsend ) ;
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( nbr[i] < 0 ) continue ;
    if ( xskip_on && rremote[nbr[i]] ) continue ;
    memset( &mine[i], 0, sizeof(tok_t) ) ;
    mine[i].alldev = alldev && rdev[nbr[i]] != 0 ; mine[i].nbytes = sendb[i] ; mine[i].rexp = recvb[i] ;
    mine[i].cap = rsize[nbr[i]] ; mine[i].h = rh[nbr[i]] ;
    mine[i].host = rsl_host_id() ;
    if ( rsl_p2p_async_enabled() && mine[i].alldev ) {
      if ( p2pasync_flags ) { fl_make() ; mine[i].async = 2 ; mine[i].fh = fl_h ; }
      else {
      p2p_ev_make( nbr[i] ) ;
      cu_ev_record( evr[nbr[i]], acc_stream( 1 ) ) ;   /* my receive buffer for nbr is free behind this point */
      mine[i].async = 1 ; mine[i].evr = evr_h[nbr[i]] ; mine[i].evd = evd_h[nbr[i]] ;
      }
    }
    MPI_Irecv( &theirs[i], sizeof(tok_t), MPI_BYTE, nbr[i], 7101, comm, &q[nq++] ) ;
    MPI_Isend( &mine[i],   sizeof(tok_t), MPI_BYTE, nbr[i], 7101, comm, &q[nq++] ) ;
  }
  if ( nq == 0 ) return ;
  MPI_Waitall( nq, q, MPI_STATUSES_IGNORE ) ;
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( nbr[i] < 0 ) continue ;
    if ( xskip_on && rremote[nbr[i]] ) continue ;   /* done[i] = 0: MPI path */
    if ( mine[i].host != theirs[i].host ) rremote[nbr[i]] = 1 ;
    done[i] = mine[i].alldev && theirs[i].alldev && mine[i].host == theirs[i].host
           && mine[i].nbytes <= theirs[i].cap && theirs[i].nbytes <= mine[i].cap
           && mine[i].nbytes <= theirs[i].rexp && theirs[i].nbytes <= mine[i].rexp ;
    if ( !done[i] ) {
      static int ndbg = 0 ; static int dbg = -1 ;
      if ( dbg < 0 ) { char *e = getenv("RSL_P2PDBG") ; dbg = ( e && e[0] != '0' ) ; }
      if ( dbg && ndbg++ < 40 ) fprintf(stderr,"RSL P2P fallback: devb %lld totsend %d mine(alldev %d n %d rexp %d cap %d) theirs(alldev %d n %d rexp %d cap %d) rdev %d\n",
          devb, totsend, mine[i].alldev, mine[i].nbytes, mine[i].rexp, mine[i].cap, theirs[i].alldev, theirs[i].nbytes, theirs[i].rexp, theirs[i].cap, rdev[nbr[i]] != 0 ) ;
      continue ;
    }
    any = 1 ;
    int P = nbr[i] ;
    if ( mine[i].async == 2 && theirs[i].async == 2 ) {
      /* counter flags: free(k) now (queue position: after this exchange's packs = after the previous unpacks) */
      int me ; MPI_Comm_rank( comm, &me ) ;
      if ( !pfl_open[P] || memcmp( &pfl_h[P], &theirs[i].fh, sizeof(ipch_t) ) ) {
        if ( pfl_open[P] ) cu_ipc_close( pfl[P] ) ;
        if ( cu_ipc_open( &pfl[P], theirs[i].fh, 1 ) ) { fprintf(stderr,"RSL P2P: flag IPC open failed\n") ; MPI_Abort(MPI_COMM_WORLD, 92) ; }
        pfl_h[P] = theirs[i].fh ; pfl_open[P] = 1 ;
      }
      int k = ++fl_k[P] ;
      fl_put( fl_dev + sizeof(int) * (unsigned long long)P, k ) ;
      if ( mine[i].nbytes > 0 ) {
        if ( !popen_[P] || memcmp( &ph[P], &theirs[i].h, sizeof(ipch_t) ) ) {
          if ( popen_[P] ) cu_ipc_close( pdev[P] ) ;
          int r = cu_ipc_open( &pdev[P], theirs[i].h, 1 ) ;
          if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuIpcOpenMemHandle rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 98) ; }
          ph[P] = theirs[i].h ; popen_[P] = 1 ;
        }
        fl_wait( pfl[P] + sizeof(int) * (unsigned long long)me, k ) ;   /* P's receive buffer from me is free */
        void * sd = acc_dptr( buffer_for_proc( P, 0, RSL_SENDBUF ) ) ;
        static int fsc = -1 ; if ( fsc < 0 ) { char *e = getenv("WRF_GPU_P2PFLSYNCCOPY") ; fsc = ( e && e[0] == '1' ) ; }
        int r ;
        if ( fsc ) { cu_sync() ;
          { static int fck = -1 ; if ( fck < 0 ) { char *e = getenv("WRF_GPU_P2PFLCHECK") ; fck = ( e && e[0] == '1' ) ; }
            if ( fck ) { int v1 = -9, v2 = -9 ; static int nck = 0 ;
              cu_d2h( &v1, pfl[P] + sizeof(int) * (unsigned long long)me, sizeof(int) ) ;
              cu_d2h( &v2, fl_dev + sizeof(int) * (unsigned long long)P, sizeof(int) ) ;
              if ( ( v1 < k || v2 != k ) && nck++ < 40 ) fprintf(stderr,"RSL FLCHECK rank %d P %d k %d peer_free %d my_free %d pfl %llx fl %llx\n", me, P, k, v1, v2, pfl[P], fl_dev ) ; } }
          r = cu_d2d( pdev[P], (unsigned long long)sd, (size_t)mine[i].nbytes ) ; cu_sync() ; }
        else r = cu_d2d_async( pdev[P], (unsigned long long)sd, (size_t)mine[i].nbytes, acc_stream( 1 ) ) ;
        if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuMemcpyDtoDAsync rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 97) ; }
      }
      fl_put( fl_dev + sizeof(int) * (unsigned long long)(RSL_MAXPROC + P), k ) ;   /* my data for k is in P's buffer */
      continue ;
    }
    if ( mine[i].nbytes <= 0 ) continue ;
    if ( !popen_[P] || memcmp( &ph[P], &theirs[i].h, sizeof(ipch_t) ) ) {
      if ( popen_[P] ) cu_ipc_close( pdev[P] ) ;
      int r = cu_ipc_open( &pdev[P], theirs[i].h, 1 /* CU_IPC_MEM_LAZY_ENABLE_PEER_ACCESS */ ) ;
      if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuIpcOpenMemHandle rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 98) ; }
      ph[P] = theirs[i].h ; popen_[P] = 1 ;
    }
    char * sbuf = buffer_for_proc( P, 0, RSL_SENDBUF ) ;
    void * sd = acc_dptr( sbuf ) ;
    if ( mine[i].async == 1 && theirs[i].async == 1 ) {
      void * st = acc_stream( 1 ) ;
      if ( !pevr[P] || memcmp( &pevr_h[P], &theirs[i].evr, sizeof(ipch_t) ) ) {
        if ( cu_ipc_ev_open( &pevr[P], theirs[i].evr ) || cu_ipc_ev_open( &pevd[P], theirs[i].evd ) ) {
          fprintf(stderr,"RSL P2P: cuIpcOpenEventHandle failed\n") ; MPI_Abort(MPI_COMM_WORLD, 94) ; }
        pevr_h[P] = theirs[i].evr ; pevd_h[P] = theirs[i].evd ;
      }
      cu_wait_ev( st, pevr[P], 0 ) ;   /* P's receive buffer is free (its previous unpacks are done) */
      int r = cu_d2d_async( pdev[P], (unsigned long long)sd, (size_t)mine[i].nbytes, st ) ;
      if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuMemcpyDtoDAsync rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 97) ; }
      continue ;
    }
    int r = cu_d2d( pdev[P], (unsigned long long)sd, (size_t)mine[i].nbytes ) ;
    if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuMemcpyDtoD rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 97) ; }
  }
  if ( !any ) return ;
  /* bisect aids (2026-11-12): WRF_GPU_P2PSIZELOG=1 prints each distinct exchange size (send bytes to both
     neighbours) once; WRF_GPU_P2PSYNCRANGE=lo:hi adds a context sync at the end of the async exchanges whose total
     send size is in [lo,hi] */
  { static int szinit = 0, szlog = 0, nsz = 0 ; static long lo_ = -1, hi_ = -1 ; static int szs[256] ;
    if ( !szinit ) { char *e = getenv("WRF_GPU_P2PSIZELOG") ; szlog = ( e && e[0] == '1' ) ;
      e = getenv("WRF_GPU_P2PSYNCRANGE") ; if ( e ) sscanf( e, "%ld:%ld", &lo_, &hi_ ) ; szinit = 1 ; }
    if ( szlog ) { int k2, seen = 0 ; for ( k2 = 0 ; k2 < nsz ; k2++ ) if ( szs[k2] == totsend ) seen = 1 ;
      if ( !seen && nsz < 256 ) { szs[nsz++] = totsend ; int me_ ; MPI_Comm_rank( comm, &me_ ) ;
        fprintf(stderr,"RSL P2P size %d (%d,%d) first at exchange #%ld rank %d\n", totsend, sendb[0], sendb[1], rsl_p2p_nx, me_) ; } }
    rsl_p2p_nx++ ;
    if ( lo_ >= 0 && totsend >= lo_ && totsend <= hi_ ) p2p_endsync = 1 ; else p2p_endsync = 0 ; }
  { int nfl = 0, nother = 0, me ;
    for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] ) { if ( mine[i].async == 2 && theirs[i].async == 2 ) nfl++ ; else nother++ ; }
    if ( nfl > 0 ) {
      MPI_Comm_rank( comm, &me ) ;
      for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] && mine[i].async == 2 && theirs[i].async == 2 && theirs[i].nbytes > 0 )
        fl_wait( pfl[nbr[i]] + sizeof(int) * (unsigned long long)(RSL_MAXPROC + me), fl_k[nbr[i]] ) ;   /* P's data is in my buffer */
    }
    { static int ft2 = -1 ; if ( ft2 < 0 ) { char *e = getenv("WRF_GPU_P2PFLTOK2") ; ft2 = ( e && e[0] == '1' ) ; }
      if ( ft2 && nfl > 0 ) { MPI_Request q2[4] ; int n2 = 0 ; static int a2[2], b2[2] ;
        for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] && mine[i].async == 2 && theirs[i].async == 2 ) {
          MPI_Irecv( &b2[i], 1, MPI_INT, nbr[i], 7103, comm, &q2[n2++] ) ; MPI_Isend( &a2[i], 1, MPI_INT, nbr[i], 7103, comm, &q2[n2++] ) ; }
        MPI_Waitall( n2, q2, MPI_STATUSES_IGNORE ) ; } }
    if ( nother == 0 ) { if ( p2p_endsync ) cu_sync() ; return ; } }
  { int nas = 0, nsy = 0 ;
    for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] ) { if ( mine[i].async == 1 && theirs[i].async == 1 ) nas++ ; else nsy++ ; }
    /* async pairs: the copy (or nothing) is on the stream; mark it for the neighbour before announcing it */
    for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] && mine[i].async == 1 && theirs[i].async == 1 ) {
      if ( !pevr[nbr[i]] || memcmp( &pevr_h[nbr[i]], &theirs[i].evr, sizeof(ipch_t) ) ) {   /* nbytes was 0 above */
        if ( cu_ipc_ev_open( &pevr[nbr[i]], theirs[i].evr ) || cu_ipc_ev_open( &pevd[nbr[i]], theirs[i].evd ) ) {
          fprintf(stderr,"RSL P2P: cuIpcOpenEventHandle failed\n") ; MPI_Abort(MPI_COMM_WORLD, 94) ; }
        pevr_h[nbr[i]] = theirs[i].evr ; pevd_h[nbr[i]] = theirs[i].evd ;
      }
      cu_ev_record( evd[nbr[i]], acc_stream( 1 ) ) ;
    }
    if ( nsy > 0 ) cu_sync() ;   /* device-to-device copies are asynchronous to the host */
    if ( nas > 0 ) async_pend = 1 ; }
  nq = 0 ;
  { static int ds[2], dr[2] ;
    for ( i = 0 ; i < 2 ; i++ ) {
      if ( nbr[i] < 0 || !done[i] ) continue ;
      if ( mine[i].async == 2 && theirs[i].async == 2 ) continue ;   /* counter flags: no second token */
      MPI_Irecv( &dr[i], 1, MPI_INT, nbr[i], 7102, comm, &q[nq++] ) ;
      MPI_Isend( &ds[i], 1, MPI_INT, nbr[i], 7102, comm, &q[nq++] ) ;
    }
    MPI_Waitall( nq, q, MPI_STATUSES_IGNORE ) ; }
  /* async pairs: the unpacks (queue 1) wait on the neighbour's copy into my receive buffer */
  if ( async_pend ) {
    for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 && done[i] && mine[i].async == 1 && theirs[i].async == 1 && theirs[i].nbytes > 0 )
      cu_wait_ev( acc_stream( 1 ), pevd[nbr[i]], 0 ) ;
    async_pend = 0 ;
    if ( p2pasync_sync ) cu_sync() ;
  }
}

/* WRF_GPU_XPIPE=1: pipelined MPI data path for the neighbours that do not use P2P (cross-node pairs). The packed
   send buffer goes to the host in chunks (cuMemcpyDtoHAsync on the OpenACC queue-1 stream, which also carries the
   packs) and each chunk is sent as soon as its copy completes; receives are posted first and every arrived chunk is
   copied to the receive buffer's device mirror asynchronously on the same stream, so the unpacks (queue 1) follow it
   and the host does not wait for the H2D. Chunking and tags depend only on the message size, so both sides of a
   pair agree; the protocol is used for every MPI neighbour while the switch is on. cover[i] = 0: the send buffer
   is not fully device-packed and was flushed to the host by the caller (chunks are sent from the host). */
#define XP_MAXCH 8
#define XP_TAG0 20000
static int xpipe_on = -1 ;
static void * xp_ev[2][XP_MAXCH] ; static void * xp_pend_ev = NULL ; static int xp_pend = 0 ;
int rsl_xpipe_enabled ( void )
{
  if ( xpipe_on < 0 ) {
    char *e = getenv("WRF_GPU_XPIPE") ; xpipe_on = ( e && e[0] == '1' ) ;
    if ( xpipe_on && ( !rsl_p2p_enabled() || !cu_d2h_async || !cu_h2d_async || !cu_ev_create || !cu_ev_record || !cu_ev_sync || !acc_stream ) ) {
      fprintf(stderr,"RSL XPIPE: entry points missing, off\n") ; xpipe_on = 0 ;
    }
    if ( xpipe_on ) {
      int i, c ; for ( i = 0 ; i < 2 ; i++ ) for ( c = 0 ; c < XP_MAXCH ; c++ ) cu_ev_create( &xp_ev[i][c], 2 /* CU_EVENT_DISABLE_TIMING */ ) ;
      cu_ev_create( &xp_pend_ev, 2 ) ;
      fprintf(stderr,"RSL XPIPE: pipelined MPI halo path on\n") ;
    }
  }
  return xpipe_on ;
}
/* the async H2D of the last pipelined exchange may still read the host receive buffers */
void rsl_xpipe_wait ( void )
{
  if ( xp_pend ) { cu_ev_sync( xp_pend_ev ) ; xp_pend = 0 ; }
}
static int xp_nch ( int n ) { int c = n / ( 256 * 1024 ) ; if ( c > XP_MAXCH ) c = XP_MAXCH ; return c < 1 ? 1 : c ; }
static void xp_chunk ( int n, int c, int * off, int * len )
{
  int nch = xp_nch( n ) ; int base = ( ( ( n + nch - 1 ) / nch ) + 4095 ) & ~4095 ;
  *off = c * base ; *len = n - *off ; if ( *len > base ) *len = base ; if ( *len < 0 ) *len = 0 ;
}
void rsl_xpipe_exch ( MPI_Comm comm, int me, int nbr[2], int use[2], char * sb[2], int sn[2], char * rb[2], int rn[2], int cover[2] )
{
  MPI_Request rr[2*XP_MAXCH], sr[2*XP_MAXCH], hq[4] ; int ri[2*XP_MAXCH], rc[2*XP_MAXCH] ; int nr = 0, ns = 0, nh = 0, i, c, off, len ;
  static int hs[2], hr[2] ;
  void * st = acc_stream( 1 ) ;
  rsl_xpipe_wait() ;
  /* size headers: the receive count rn is only an upper bound of what the neighbour sends (staggered rows), and
     both sides must cut the message at the same chunk boundaries, so each side first sends its exact byte count.
     Order (2026-11-07): headers posted, then our D2H chunks and data sends - none of it depends on the neighbour -
     and only then the wait for the neighbour's header, so a rank that arrives early has its data on the wire
     before its partner shows up (the partner's arrival no longer waits for our D2H). */
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( !use[i] ) continue ;
    hr[i] = 0 ; hs[i] = sn[i] > 0 ? sn[i] : 0 ;
    /* sn/rn < 0: no message in that direction (sendw/recvw off); 0: an empty message is still exchanged */
    if ( rn[i] >= 0 ) MPI_Irecv( &hr[i], 1, MPI_INT, nbr[i], XP_TAG0 - 1, comm, &hq[nh++] ) ;
    if ( sn[i] >= 0 ) MPI_Isend( &hs[i], 1, MPI_INT, nbr[i], XP_TAG0 - 1, comm, &hq[nh++] ) ;
  }
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( !use[i] || sn[i] <= 0 || !cover[i] ) continue ;
    unsigned long long sd = (unsigned long long)acc_dptr( sb[i] ) ;
    for ( c = 0 ; c < xp_nch( sn[i] ) ; c++ ) {
      xp_chunk( sn[i], c, &off, &len ) ; if ( len <= 0 ) continue ;
      cu_d2h_async( sb[i] + off, sd + off, (size_t)len, st ) ; cu_ev_record( xp_ev[i][c], st ) ;
    }
  }
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( !use[i] || sn[i] <= 0 ) continue ;
    for ( c = 0 ; c < xp_nch( sn[i] ) ; c++ ) {
      xp_chunk( sn[i], c, &off, &len ) ; if ( len <= 0 ) continue ;
      if ( cover[i] ) cu_ev_sync( xp_ev[i][c] ) ;
      MPI_Isend( sb[i] + off, len, MPI_CHAR, nbr[i], XP_TAG0 + nbr[i] * XP_MAXCH + c, comm, &sr[ns++] ) ;
    }
  }
  if ( nh > 0 ) MPI_Waitall( nh, hq, MPI_STATUSES_IGNORE ) ;
  for ( i = 0 ; i < 2 ; i++ ) if ( use[i] && rn[i] >= 0 ) {
    if ( hr[i] > rn[i] ) { fprintf(stderr,"RSL XPIPE: neighbour %d sends %d > expected %d\n", nbr[i], hr[i], rn[i]) ; MPI_Abort(MPI_COMM_WORLD, 96) ; }
    rn[i] = hr[i] ;
  }
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( !use[i] || rn[i] <= 0 ) continue ;
    for ( c = 0 ; c < xp_nch( rn[i] ) ; c++ ) {
      xp_chunk( rn[i], c, &off, &len ) ; if ( len <= 0 ) continue ;
      ri[nr] = i ; rc[nr] = c ;
      MPI_Irecv( rb[i] + off, len, MPI_CHAR, nbr[i], XP_TAG0 + me * XP_MAXCH + c, comm, &rr[nr++] ) ;
    }
  }
  if ( nr > 0 ) {
    unsigned long long rd[2] = { 0, 0 } ;
    for ( i = 0 ; i < 2 ; i++ ) if ( use[i] && rn[i] > 0 ) rd[i] = (unsigned long long)acc_dptr( rb[i] ) ;
    int k, idx ;
    for ( k = 0 ; k < nr ; k++ ) {
      MPI_Waitany( nr, rr, &idx, MPI_STATUS_IGNORE ) ;
      i = ri[idx] ; xp_chunk( rn[i], rc[idx], &off, &len ) ;
      if ( rd[i] ) cu_h2d_async( rd[i] + off, rb[i] + off, (size_t)len, st ) ;
    }
    cu_ev_record( xp_pend_ev, st ) ; xp_pend = 1 ;
  }
  if ( ns > 0 ) MPI_Waitall( ns, sr, MPI_STATUSES_IGNORE ) ;
}
#endif
