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
      }
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
typedef struct { int alldev ; int nbytes ; int rexp ; int cap ; ipch_t h ; } tok_t ;
/* p2p exchange for up to two neighbours (index 0/1) of one axis. sendb/recvb: send/recv byte counts per
   neighbour. devb: device-packed bytes recorded for this exchange. done[i] = 1 where the neighbour pair used
   P2P (decided symmetrically from both tokens); the caller does the MPI data path for the others. */
void rsl_p2p_exch ( MPI_Comm comm, int nbr[2], int sendb[2], int recvb[2], long long devb, int done[2] )
{
  tok_t mine[2], theirs[2] ; MPI_Request q[4] ; int nq = 0, i, totsend = 0, any = 0 ;
  done[0] = done[1] = 0 ;
  for ( i = 0 ; i < 2 ; i++ ) if ( nbr[i] >= 0 ) totsend += sendb[i] ;
  int alldev = ( devb == (long long)totsend ) ;
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( nbr[i] < 0 ) continue ;
    memset( &mine[i], 0, sizeof(tok_t) ) ;
    mine[i].alldev = alldev && rdev[nbr[i]] != 0 ; mine[i].nbytes = sendb[i] ; mine[i].rexp = recvb[i] ;
    mine[i].cap = rsize[nbr[i]] ; mine[i].h = rh[nbr[i]] ;
    MPI_Irecv( &theirs[i], sizeof(tok_t), MPI_BYTE, nbr[i], 7101, comm, &q[nq++] ) ;
    MPI_Isend( &mine[i],   sizeof(tok_t), MPI_BYTE, nbr[i], 7101, comm, &q[nq++] ) ;
  }
  if ( nq == 0 ) return ;
  MPI_Waitall( nq, q, MPI_STATUSES_IGNORE ) ;
  for ( i = 0 ; i < 2 ; i++ ) {
    if ( nbr[i] < 0 ) continue ;
    done[i] = mine[i].alldev && theirs[i].alldev
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
#endif
