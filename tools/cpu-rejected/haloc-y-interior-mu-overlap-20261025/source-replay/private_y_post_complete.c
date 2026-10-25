#include <mpi.h>
#include "rsl_lite.h"
extern int yp_curs,ym_curs,xp_curs,xm_curs,yp_curs_recv,ym_curs_recv,xp_curs_recv,xm_curs_recv;
extern MPI_Request yp_recv,ym_recv,yp_send,ym_send;
/* BEGIN ADDITIVE PRIVATE RSL_LITE_EXCH_Y_SPLIT POST/COMPLETE.
   Place in the same translation unit and after the existing static declarations,
   buffer allocator, RSL_LITE_INIT_EXCH, RSL_LITE_PACK and RSL_LITE_EXCH_Y.
   There is no executable/DSML here: this is the complete new C source.
   Original RSL_LITE_EXCH_Y and all public symbols remain unchanged. */

static int rsl_lite_y_split_pending = 0 ;
static int rsl_lite_y_split_yp = MPI_PROC_NULL ;
static int rsl_lite_y_split_ym = MPI_PROC_NULL ;
static int rsl_lite_y_split_act_rp = 0 ;
static int rsl_lite_y_split_act_rm = 0 ;
static int rsl_lite_y_split_act_sp = 0 ;
static int rsl_lite_y_split_act_sm = 0 ;

int
rsl_lite_y_post_exp_ ( int * Fcomm0, int *me0, int * np0 , int * np_x0 , int * np_y0 ,
                        int * sendw_m, int * sendw_p, int * recvw_m , int * recvw_p )
{
  int me, np, np_x, np_y ;
  int yp, ym, xp, xm, ierr ;
#ifndef STUBMPI
  MPI_Comm comm, *comm0, dummy_comm ;
#endif

#ifndef STUBMPI
  if ( rsl_lite_y_split_pending ) return 1 ;

  comm0 = &dummy_comm ;
  *comm0 = MPI_Comm_f2c( *Fcomm0 ) ;
  comm = *comm0 ; me = *me0 ; np = *np0 ; np_x = *np_x0 ; np_y = *np_y0 ;

  rsl_lite_y_split_yp = MPI_PROC_NULL ;
  rsl_lite_y_split_ym = MPI_PROC_NULL ;
  rsl_lite_y_split_act_rp = 0 ;
  rsl_lite_y_split_act_rm = 0 ;
  rsl_lite_y_split_act_sp = 0 ;
  rsl_lite_y_split_act_sm = 0 ;

  if ( np_y > 1 ) {
    MPI_Cart_shift( *comm0, 0, 1, &ym, &yp ) ;
    rsl_lite_y_split_yp = yp ;
    rsl_lite_y_split_ym = ym ;
    /* exact original eligible order: Irecv+, Irecv-, Isend+, Isend- */
    if ( yp != MPI_PROC_NULL && *recvw_p > 0 ) {
      ierr=MPI_Irecv ( buffer_for_proc( yp, yp_curs_recv, RSL_RECVBUF ), yp_curs_recv, MPI_CHAR, yp, me, comm, &yp_recv ) ;
      rsl_lite_y_split_act_rp = 1 ;
    }
    if ( ym != MPI_PROC_NULL && *recvw_m > 0 ) {
      ierr=MPI_Irecv ( buffer_for_proc( ym, ym_curs_recv, RSL_RECVBUF ), ym_curs_recv, MPI_CHAR, ym, me, comm, &ym_recv ) ;
      rsl_lite_y_split_act_rm = 1 ;
    }
    if ( yp != MPI_PROC_NULL && *sendw_p > 0 ) {
      ierr=MPI_Isend ( buffer_for_proc( yp, 0,       RSL_SENDBUF ), yp_curs, MPI_CHAR, yp, yp, comm, &yp_send ) ;
      rsl_lite_y_split_act_sp = 1 ;
    }
    if ( ym != MPI_PROC_NULL && *sendw_m > 0 ) {
      ierr=MPI_Isend ( buffer_for_proc( ym, 0,       RSL_SENDBUF ), ym_curs, MPI_CHAR, ym, ym, comm, &ym_send ) ;
      rsl_lite_y_split_act_sm = 1 ;
    }
  }

  /* All eight cursors remain unchanged while pending. */
  rsl_lite_y_split_pending = 1 ;
  return 0 ;
#else
  if ( rsl_lite_y_split_pending ) return 1 ;
  rsl_lite_y_split_yp = MPI_PROC_NULL ;
  rsl_lite_y_split_ym = MPI_PROC_NULL ;
  rsl_lite_y_split_act_rp = 0 ;
  rsl_lite_y_split_act_rm = 0 ;
  rsl_lite_y_split_act_sp = 0 ;
  rsl_lite_y_split_act_sm = 0 ;
  rsl_lite_y_split_pending = 1 ;
  return 0 ;
#endif
}

int
rsl_lite_y_complete_exp_ ( void )
{
#ifndef STUBMPI
  MPI_Status stat ;

  if ( ! rsl_lite_y_split_pending ) return 1 ;

  /* exact original completion eligibility and order: recv+, recv-, send+, send- */
  if ( rsl_lite_y_split_act_rp ) { MPI_Wait( &yp_recv, &stat ) ; }
  if ( rsl_lite_y_split_act_rm ) { MPI_Wait( &ym_recv, &stat ) ; }
  if ( rsl_lite_y_split_act_sp ) { MPI_Wait( &yp_send, &stat ) ; }
  if ( rsl_lite_y_split_act_sm ) { MPI_Wait( &ym_send, &stat ) ; }

  rsl_lite_y_split_act_rp = 0 ;
  rsl_lite_y_split_act_rm = 0 ;
  rsl_lite_y_split_act_sp = 0 ;
  rsl_lite_y_split_act_sm = 0 ;
  rsl_lite_y_split_pending = 0 ;

  /* exact original eight-cursor reset */
  yp_curs = 0 ; ym_curs = 0 ; xp_curs = 0 ; xm_curs = 0 ;
  yp_curs_recv = 0 ; ym_curs_recv = 0 ;
  xp_curs_recv = 0 ; xm_curs_recv = 0 ;
  return 0 ;
#else
  if ( ! rsl_lite_y_split_pending ) return 1 ;
  rsl_lite_y_split_act_rp = 0 ;
  rsl_lite_y_split_act_rm = 0 ;
  rsl_lite_y_split_act_sp = 0 ;
  rsl_lite_y_split_act_sm = 0 ;
  rsl_lite_y_split_pending = 0 ;
  yp_curs = 0 ; ym_curs = 0 ; xp_curs = 0 ; xm_curs = 0 ;
  yp_curs_recv = 0 ; ym_curs_recv = 0 ;
  xp_curs_recv = 0 ; xm_curs_recv = 0 ;
  return 0 ;
#endif
}
/* END ADDITIVE PRIVATE POST/COMPLETE. */
