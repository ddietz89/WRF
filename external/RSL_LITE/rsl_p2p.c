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
typedef struct { int alldev ; int nbytes ; int rexp ; int cap ; ipch_t h ; unsigned long long host ; } tok_t ;
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
  tok_t mine[2], theirs[2] ; MPI_Request q[4] ; int nq = 0, i, totsend = 0, any = 0 ;
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
    if ( mine[i].nbytes <= 0 ) continue ;
    if ( !popen_[P] || memcmp( &ph[P], &theirs[i].h, sizeof(ipch_t) ) ) {
      if ( popen_[P] ) cu_ipc_close( pdev[P] ) ;
      int r = cu_ipc_open( &pdev[P], theirs[i].h, 1 /* CU_IPC_MEM_LAZY_ENABLE_PEER_ACCESS */ ) ;
      if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuIpcOpenMemHandle rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 98) ; }
      ph[P] = theirs[i].h ; popen_[P] = 1 ;
    }
    char * sbuf = buffer_for_proc( P, 0, RSL_SENDBUF ) ;
    void * sd = acc_dptr( sbuf ) ;
    int r = cu_d2d( pdev[P], (unsigned long long)sd, (size_t)mine[i].nbytes ) ;
    if ( r != 0 ) { fprintf(stderr,"RSL P2P: cuMemcpyDtoD rc=%d\n",r) ; MPI_Abort(MPI_COMM_WORLD, 97) ; }
  }
  if ( !any ) return ;
  cu_sync() ;   /* device-to-device copies are asynchronous to the host */
  nq = 0 ;
  { static int ds[2], dr[2] ;
    for ( i = 0 ; i < 2 ; i++ ) {
      if ( nbr[i] < 0 || !done[i] ) continue ;
      MPI_Irecv( &dr[i], 1, MPI_INT, nbr[i], 7102, comm, &q[nq++] ) ;
      MPI_Isend( &ds[i], 1, MPI_INT, nbr[i], 7102, comm, &q[nq++] ) ;
    }
    MPI_Waitall( nq, q, MPI_STATUSES_IGNORE ) ; }
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
  MPI_Request rr[2*XP_MAXCH], sr[2*XP_MAXCH] ; int ri[2*XP_MAXCH], rc[2*XP_MAXCH] ; int nr = 0, ns = 0, i, c, off, len ;
  void * st = acc_stream( 1 ) ;
  rsl_xpipe_wait() ;
  /* size headers: the receive count rn is only an upper bound of what the neighbour sends (staggered rows), and
     both sides must cut the message at the same chunk boundaries, so each side first sends its exact byte count */
  { MPI_Request hq[4] ; static int hs[2], hr[2] ; int nh = 0 ;
    for ( i = 0 ; i < 2 ; i++ ) {
      if ( !use[i] ) continue ;
      hr[i] = 0 ; hs[i] = sn[i] > 0 ? sn[i] : 0 ;
      /* sn/rn < 0: no message in that direction (sendw/recvw off); 0: an empty message is still exchanged */
      if ( rn[i] >= 0 ) MPI_Irecv( &hr[i], 1, MPI_INT, nbr[i], XP_TAG0 - 1, comm, &hq[nh++] ) ;
      if ( sn[i] >= 0 ) MPI_Isend( &hs[i], 1, MPI_INT, nbr[i], XP_TAG0 - 1, comm, &hq[nh++] ) ;
    }
    if ( nh > 0 ) MPI_Waitall( nh, hq, MPI_STATUSES_IGNORE ) ;
    for ( i = 0 ; i < 2 ; i++ ) if ( use[i] && rn[i] >= 0 ) {
      if ( hr[i] > rn[i] ) { fprintf(stderr,"RSL XPIPE: neighbour %d sends %d > expected %d\n", nbr[i], hr[i], rn[i]) ; MPI_Abort(MPI_COMM_WORLD, 96) ; }
      rn[i] = hr[i] ;
    } }
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( !use[i] || rn[i] <= 0 ) continue ;
    for ( c = 0 ; c < xp_nch( rn[i] ) ; c++ ) {
      xp_chunk( rn[i], c, &off, &len ) ; if ( len <= 0 ) continue ;
      ri[nr] = i ; rc[nr] = c ;
      MPI_Irecv( rb[i] + off, len, MPI_CHAR, nbr[i], XP_TAG0 + me * XP_MAXCH + c, comm, &rr[nr++] ) ;
    }
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
