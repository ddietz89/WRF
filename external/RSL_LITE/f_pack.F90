      MODULE duplicate_of_driver_constants
! These definitions must be the same as frame/module_driver_constants
! and also the same as the definitions in rsl_lite.h
         INTEGER , PARAMETER :: DATA_ORDER_XYZ = 1
         INTEGER , PARAMETER :: DATA_ORDER_YXZ = 2
         INTEGER , PARAMETER :: DATA_ORDER_ZXY = 3
         INTEGER , PARAMETER :: DATA_ORDER_ZYX = 4
         INTEGER , PARAMETER :: DATA_ORDER_XZY = 5
         INTEGER , PARAMETER :: DATA_ORDER_YZX = 6
      END MODULE duplicate_of_driver_constants
! GPU port (2026-11-02): host/device switch for the device-side halo pack/unpack paths below.
      MODULE rsl_gpu_ctl
        LOGICAL :: rsl_gpu_on = .TRUE.
        ! managed-memory builds: fields are device-accessible without being in the present table
        LOGICAL :: rsl_gpu_managed = .FALSE.
        ! WRF_GPU_HALOBATCH (2026-11-06): RSL send/recv buffers mapped on the device; device-resident fields are
        ! packed/unpacked into the mapped buffers on queue 1 without a per-field transfer/sync; RSL_LITE_EXCH_X/Y
        ! moves the packed send segments to the host in one update (rsl_gpu_send_flush) and the whole received
        ! buffer to the device in one update (rsl_gpu_recv_push).
        INTEGER :: rsl_gpu_batch = -1          ! -1 unread, 0 off, 1 on
        LOGICAL :: rsl_gpu_need_wait = .TRUE.  ! first device pack of an exchange drains all queues
        INTEGER, PARAMETER :: rsl_gpu_maxseg = 4096
        INTEGER :: rsl_gpu_nseg = 0
        INTEGER*8 :: rsl_gpu_seg_a(rsl_gpu_maxseg), rsl_gpu_seg_n(rsl_gpu_maxseg)
      END MODULE rsl_gpu_ctl
      LOGICAL FUNCTION rsl_gpu_batch_on ()
        USE rsl_gpu_ctl
        CHARACTER(16) :: v
        INTEGER :: l, st
        IF ( rsl_gpu_batch < 0 ) THEN
          rsl_gpu_batch = 0
#if defined(_OPENACC) || defined(WRF_GPU)
          CALL get_environment_variable( 'WRF_GPU_HALOBATCH', v, l, st )
          IF ( st == 0 .AND. l > 0 ) THEN
            IF ( v(1:1) /= '0' ) rsl_gpu_batch = 1
          ENDIF
#endif
        ENDIF
        rsl_gpu_batch_on = rsl_gpu_batch == 1 .AND. rsl_gpu_on .AND. .NOT. rsl_gpu_managed
      END FUNCTION rsl_gpu_batch_on
      ! map/unmap a freshly allocated RSL buffer on the device (called from buffer_for_proc)
      SUBROUTINE rsl_gpu_buf_map ( addr, nbytes, onoff )
        USE iso_c_binding
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
#endif
        IMPLICIT NONE
        INTEGER*8 addr
        INTEGER nbytes, onoff
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER(1), POINTER :: bp(:)
        LOGICAL, EXTERNAL :: rsl_gpu_batch_on
        IF ( .NOT. rsl_gpu_batch_on() ) RETURN
        IF ( nbytes <= 0 ) RETURN
        CALL c_f_pointer( TRANSFER(addr, c_null_ptr), bp, (/ nbytes /) )
        IF ( onoff == 1 ) THEN
!$acc enter data create(bp)
        ELSE IF ( acc_is_present( bp ) ) THEN
!$acc exit data delete(bp)
        ENDIF
#endif
      END SUBROUTINE rsl_gpu_buf_map
      ! device pack/unpack target check: returns the async queue to use (1 = batched into the mapped buffer,
      ! acc_async_sync = classic per-field path). Pack: records the segment and drains queues once per exchange.
      INTEGER FUNCTION rsl_gpu_q ( addr, nbytes, ispack )
        USE iso_c_binding
        USE rsl_gpu_ctl
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
#endif
        IMPLICIT NONE
        INTEGER*8 addr
        INTEGER nbytes, ispack
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER(1), POINTER :: bp(:)
        LOGICAL, EXTERNAL :: rsl_gpu_batch_on
        rsl_gpu_q = acc_async_sync
        IF ( .NOT. rsl_gpu_batch_on() ) RETURN
        CALL c_f_pointer( TRANSFER(addr, c_null_ptr), bp, (/ nbytes /) )
        IF ( .NOT. acc_is_present( bp ) ) RETURN
        rsl_gpu_q = 1
        IF ( ispack == 1 ) THEN
          IF ( rsl_gpu_need_wait ) THEN
!$acc wait
            rsl_gpu_need_wait = .FALSE.
          ENDIF
          IF ( rsl_gpu_nseg > 0 ) THEN
            IF ( rsl_gpu_seg_a(rsl_gpu_nseg) + rsl_gpu_seg_n(rsl_gpu_nseg) == addr ) THEN
              rsl_gpu_seg_n(rsl_gpu_nseg) = rsl_gpu_seg_n(rsl_gpu_nseg) + nbytes
              RETURN
            ENDIF
          ENDIF
          IF ( rsl_gpu_nseg >= rsl_gpu_maxseg ) THEN
            CALL rsl_gpu_send_flush()
          ENDIF
          rsl_gpu_nseg = rsl_gpu_nseg + 1
          rsl_gpu_seg_a(rsl_gpu_nseg) = addr ; rsl_gpu_seg_n(rsl_gpu_nseg) = nbytes
        ENDIF
#else
        rsl_gpu_q = -1
#endif
      END FUNCTION rsl_gpu_q
      ! before MPI send: finish the queued device packs and copy the packed segments to the host
      SUBROUTINE rsl_gpu_send_flush ()
        USE iso_c_binding
        USE rsl_gpu_ctl
        IMPLICIT NONE
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER(1), POINTER :: bp(:)
        INTEGER :: n
        IF ( rsl_gpu_nseg == 0 ) RETURN
!$acc wait(1)
        DO n = 1, rsl_gpu_nseg
          CALL c_f_pointer( TRANSFER(rsl_gpu_seg_a(n), c_null_ptr), bp, (/ INT(rsl_gpu_seg_n(n)) /) )
!$acc update self(bp)
        ENDDO
        rsl_gpu_nseg = 0
#endif
      END SUBROUTINE rsl_gpu_send_flush
      ! after MPI receive: copy the received buffer to its device mirror (unpacks then run on queue 1);
      ! also re-arms the once-per-exchange queue drain for the next exchange's packs
      SUBROUTINE rsl_gpu_recv_push ( addr, nbytes )
        USE iso_c_binding
        USE rsl_gpu_ctl
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
#endif
        IMPLICIT NONE
        INTEGER*8 addr
        INTEGER nbytes
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER(1), POINTER :: bp(:)
        LOGICAL, EXTERNAL :: rsl_gpu_batch_on
        rsl_gpu_need_wait = .TRUE.
        IF ( nbytes <= 0 ) RETURN
        IF ( .NOT. rsl_gpu_batch_on() ) RETURN
        CALL c_f_pointer( TRANSFER(addr, c_null_ptr), bp, (/ nbytes /) )
        IF ( .NOT. acc_is_present( bp ) ) RETURN
!$acc update device(bp)
#endif
      END SUBROUTINE rsl_gpu_recv_push

      SUBROUTINE rsl_set_gpu_managed ( flag )
        USE rsl_gpu_ctl
        LOGICAL, INTENT(IN) :: flag
        rsl_gpu_managed = flag
      END SUBROUTINE rsl_set_gpu_managed
      SUBROUTINE rsl_set_gpu_on ( flag )
        USE rsl_gpu_ctl
        LOGICAL, INTENT(IN) :: flag
        rsl_gpu_on = flag
      END SUBROUTINE rsl_set_gpu_on


      SUBROUTINE f_pack_int ( inbuf, outbuf, memorder, js, je, ks, ke,            &
     &                    is, ie, jms, jme, kms, kme, ims, ime, curs )
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER ims, ime, jms, jme, kms, kme
        INTEGER inbuf(*), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_pack_int_ijk( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_pack_int_jik( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_pack_int_ikj( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_pack_int_jki( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_pack_int_kij( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_pack_int_kji( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_pack_int
     
      SUBROUTINE f_pack_lint ( inbuf, outbuf, memorder, js, je, ks, ke,           &
     &                     is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(*), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_pack_lint_ijk( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_pack_lint_jik( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_pack_lint_ikj( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_pack_lint_jki( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_pack_lint_kij( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_pack_lint_kji( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_pack_lint
     
      SUBROUTINE f_unpack_int ( inbuf, outbuf, memorder, js, je, ks, ke,           &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(*), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_unpack_int_ijk( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_unpack_int_jik( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_unpack_int_ikj( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_unpack_int_jki( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_unpack_int_kij( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_unpack_int_kji( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_unpack_int
     
      SUBROUTINE f_unpack_lint ( inbuf, outbuf, memorder, js, je, ks,               &
     &                 ke, is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(*), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_unpack_lint_ijk( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_unpack_lint_jik( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_unpack_lint_ikj( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_unpack_lint_jki( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_unpack_lint_kij( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_unpack_lint_kji( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_unpack_lint

!ikj
      SUBROUTINE f_pack_int_ikj ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(ims:ime,kms:kme,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nk_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo pack: field resident on device -> gather strip on device, copy out only the strip
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(inbuf) ) ) THEN
          ni_ = ie-is+1 ; nk_ = ke-ks+1 ; nn_ = ni_*nk_*(je-js+1)
          q_ = rsl_gpu_q( LOC(outbuf), nn_*4, 1 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyout(outbuf(1:nn_)) async(q_)
          DO j = js, je
          DO k = ks, ke
          DO i = is, ie
            outbuf((j-js)*nk_*ni_ + (k-ks)*ni_ + (i-is) + 1) = inbuf(i,k,j)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ie-is+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
            DO i = is, ie
              outbuf(p) = inbuf(i,k,j)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL

        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_ikj
     
      SUBROUTINE f_pack_lint_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(ims:ime,kms:kme,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nk_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo pack: field resident on device -> gather strip on device, copy out only the strip
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(inbuf) ) ) THEN
          ni_ = ie-is+1 ; nk_ = ke-ks+1 ; nn_ = ni_*nk_*(je-js+1)
          q_ = rsl_gpu_q( LOC(outbuf), nn_*8, 1 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyout(outbuf(1:nn_)) async(q_)
          DO j = js, je
          DO k = ks, ke
          DO i = is, ie
            outbuf((j-js)*nk_*ni_ + (k-ks)*ni_ + (i-is) + 1) = inbuf(i,k,j)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ie-is+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
            DO i = is, ie
              outbuf(p) = inbuf(i,k,j)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_ikj
     
      SUBROUTINE f_unpack_int_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(ims:ime,kms:kme,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nk_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo unpack: copy in only the strip, scatter into the device-resident field
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(outbuf) ) ) THEN
          ni_ = ie-is+1 ; nk_ = ke-ks+1 ; nn_ = ni_*nk_*(je-js+1)
          q_ = rsl_gpu_q( LOC(inbuf), nn_*4, 0 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyin(inbuf(1:nn_)) async(q_)
          DO j = js, je
          DO k = ks, ke
          DO i = is, ie
            outbuf(i,k,j) = inbuf((j-js)*nk_*ni_ + (k-ks)*ni_ + (i-is) + 1)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ie-is+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
            DO i = is, ie
              outbuf(i,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_ikj
     
      SUBROUTINE f_unpack_lint_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(ims:ime,kms:kme,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nk_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo unpack: copy in only the strip, scatter into the device-resident field
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(outbuf) ) ) THEN
          ni_ = ie-is+1 ; nk_ = ke-ks+1 ; nn_ = ni_*nk_*(je-js+1)
          q_ = rsl_gpu_q( LOC(inbuf), nn_*8, 0 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyin(inbuf(1:nn_)) async(q_)
          DO j = js, je
          DO k = ks, ke
          DO i = is, ie
            outbuf(i,k,j) = inbuf((j-js)*nk_*ni_ + (k-ks)*ni_ + (i-is) + 1)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ie-is+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
            DO i = is, ie
              outbuf(i,k,j) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_ikj

!jki
      SUBROUTINE f_pack_int_jki ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(jms:jme,kms:kme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
            DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(je-js+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
        DO j = js, je
              outbuf(p) = inbuf(j,k,i)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_jki
     
      SUBROUTINE f_pack_lint_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(jms:jme,kms:kme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
            DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(je-js+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
        DO j = js, je
              outbuf(p) = inbuf(j,k,i)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_jki
     
      SUBROUTINE f_unpack_int_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(jms:jme,kms:kme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
            DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(je-js+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
        DO j = js, je
              outbuf(j,k,i) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_jki
     
      SUBROUTINE f_unpack_lint_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(jms:jme,kms:kme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
            DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(je-js+1)*(ke-ks+1)+1
#endif
          DO k = ks, ke
        DO j = js, je
              outbuf(j,k,i) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_jki

!ijk
      SUBROUTINE f_pack_int_ijk ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(ims:ime,jms:jme,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nj_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo pack (2-D / XY-ordered fields resident on the device): only the strip crosses PCIe
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(inbuf) ) ) THEN
          ni_ = ie-is+1 ; nj_ = je-js+1 ; nn_ = ni_*nj_*(ke-ks+1)
          q_ = rsl_gpu_q( LOC(outbuf), nn_*4, 1 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyout(outbuf(1:nn_)) async(q_)
          DO k = ks, ke
          DO j = js, je
          DO i = is, ie
            outbuf((k-ks)*nj_*ni_ + (j-js)*ni_ + (i-is) + 1) = inbuf(i,j,k)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO j = js, je
            DO i = is, ie
              outbuf(p) = inbuf(i,j,k)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_ijk
     
      SUBROUTINE f_pack_lint_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(ims:ime,jms:jme,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nj_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo pack (2-D / XY-ordered fields resident on the device): only the strip crosses PCIe
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(inbuf) ) ) THEN
          ni_ = ie-is+1 ; nj_ = je-js+1 ; nn_ = ni_*nj_*(ke-ks+1)
          q_ = rsl_gpu_q( LOC(outbuf), nn_*8, 1 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyout(outbuf(1:nn_)) async(q_)
          DO k = ks, ke
          DO j = js, je
          DO i = is, ie
            outbuf((k-ks)*nj_*ni_ + (j-js)*ni_ + (i-is) + 1) = inbuf(i,j,k)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO j = js, je
            DO i = is, ie
              outbuf(p) = inbuf(i,j,k)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_ijk
     
      SUBROUTINE f_unpack_int_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(ims:ime,jms:jme,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nj_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo unpack (2-D / XY-ordered fields resident on the device): only the strip crosses PCIe
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(outbuf) ) ) THEN
          ni_ = ie-is+1 ; nj_ = je-js+1 ; nn_ = ni_*nj_*(ke-ks+1)
          q_ = rsl_gpu_q( LOC(inbuf), nn_*4, 0 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyin(inbuf(1:nn_)) async(q_)
          DO k = ks, ke
          DO j = js, je
          DO i = is, ie
            outbuf(i,j,k) = inbuf((k-ks)*nj_*ni_ + (j-js)*ni_ + (i-is) + 1)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO j = js, je
            DO i = is, ie
              outbuf(i,j,k) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_ijk
     
      SUBROUTINE f_unpack_lint_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
#if defined(_OPENACC) || defined(WRF_GPU)
        USE openacc
        USE rsl_gpu_ctl
#endif
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(ims:ime,jms:jme,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
#if defined(_OPENACC) || defined(WRF_GPU)
        INTEGER ni_, nj_, nn_, q_
        INTEGER, EXTERNAL :: rsl_gpu_q
        ! GPU halo unpack (2-D / XY-ordered fields resident on the device): only the strip crosses PCIe
        IF ( rsl_gpu_on .AND. ( rsl_gpu_managed .OR. acc_is_present(outbuf) ) ) THEN
          ni_ = ie-is+1 ; nj_ = je-js+1 ; nn_ = ni_*nj_*(ke-ks+1)
          q_ = rsl_gpu_q( LOC(inbuf), nn_*8, 0 )
          IF ( q_ == acc_async_sync ) THEN
!$acc wait   ! async (queue wrf_gpu_q) device work must finish before the strip is gathered/scattered
          ENDIF
!$acc parallel loop collapse(3) copyin(inbuf(1:nn_)) async(q_)
          DO k = ks, ke
          DO j = js, je
          DO i = is, ie
            outbuf(i,j,k) = inbuf((k-ks)*nj_*ni_ + (j-js)*ni_ + (i-is) + 1)
          ENDDO
          ENDDO
          ENDDO
          curs = nn_
          RETURN
        ENDIF
#endif
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO j = js, je
            DO i = is, ie
              outbuf(i,j,k) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_ijk
     
!jik
      SUBROUTINE f_pack_int_jik ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(jms:jme,ims:ime,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO j = js, je
              outbuf(p) = inbuf(j,i,k)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_jik
     
      SUBROUTINE f_pack_lint_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(jms:jme,ims:ime,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO j = js, je
              outbuf(p) = inbuf(j,i,k)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_jik
     
      SUBROUTINE f_unpack_int_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(jms:jme,ims:ime,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO j = js, je
              outbuf(j,i,k) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_jik
     
      SUBROUTINE f_unpack_lint_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(jms:jme,ims:ime,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO k = ks, ke
#ifdef _OPENMP
        p = (k-ks)*(je-js+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO j = js, je
              outbuf(j,i,k) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_jik

!kij
      SUBROUTINE f_pack_int_kij ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(kms:kme,ims:ime,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ke-ks+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO k = ks, ke
              outbuf(p) = inbuf(k,i,j)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_kij
     
      SUBROUTINE f_pack_lint_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(kms:kme,ims:ime,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ke-ks+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO k = ks, ke
              outbuf(p) = inbuf(k,i,j)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_kij
     
      SUBROUTINE f_unpack_int_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(kms:kme,ims:ime,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ke-ks+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO k = ks, ke
              outbuf(k,i,j) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_kij
     
      SUBROUTINE f_unpack_lint_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(kms:kme,ims:ime,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
        DO j = js, je
#ifdef _OPENMP
        p = (j-js)*(ke-ks+1)*(ie-is+1)+1
#endif
          DO i = is, ie
            DO k = ks, ke
              outbuf(k,i,j) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_kij

!kji
      SUBROUTINE f_pack_int_kji ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER inbuf(kms:kme,jms:jme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
          DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(ke-ks+1)*(je-js+1)+1
#endif
        DO j = js, je
            DO k = ks, ke
              outbuf(p) = inbuf(k,j,i)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_int_kji
     
      SUBROUTINE f_pack_lint_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(kms:kme,jms:jme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
          DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(ke-ks+1)*(je-js+1)+1
#endif
        DO j = js, je
            DO k = ks, ke
              outbuf(p) = inbuf(k,j,i)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_pack_lint_kji
     
      SUBROUTINE f_unpack_int_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(kms:kme,jms:jme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
          DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(ke-ks+1)*(je-js+1)+1
#endif
        DO j = js, je
            DO k = ks, ke
              outbuf(k,j,i) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_int_kji
     
      SUBROUTINE f_unpack_lint_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(kms:kme,jms:jme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
!$OMP PARALLEL PRIVATE (i,j,k,p) 
#ifndef _OPENMP
        p = 1
#endif
!$OMP DO SCHEDULE(RUNTIME) 
          DO i = is, ie
#ifdef _OPENMP
        p = (i-is)*(ke-ks+1)*(je-js+1)+1
#endif
        DO j = js, je
            DO k = ks, ke
              outbuf(k,j,i) = inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
!$OMP END DO
!$OMP END PARALLEL
        curs = (ie-is+1)*(je-js+1)*(ke-ks+1)
        RETURN
      END SUBROUTINE f_unpack_lint_kji

#if ( WRFPLUS == 1 )
!--------------------------------------------------------------------------------
      SUBROUTINE f_pack_int_ad ( inbuf, outbuf, memorder, js, je, ks, ke,            &
     &                    is, ie, jms, jme, kms, kme, ims, ime, curs )
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER ims, ime, jms, jme, kms, kme
        INTEGER inbuf(*), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_pack_real_ad_ijk( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_pack_real_ad_jik( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_pack_real_ad_ikj( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_pack_real_ad_jki( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_pack_real_ad_kij( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_pack_real_ad_kji( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_pack_int_ad
     
      SUBROUTINE f_pack_lint_ad ( inbuf, outbuf, memorder, js, je, ks, ke,           &
     &                     is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 inbuf(*), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_pack_lreal_ad_ijk( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_pack_lreal_ad_jik( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_pack_lreal_ad_ikj( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_pack_lreal_ad_jki( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_pack_lreal_ad_kij( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_pack_lreal_ad_kji( inbuf, outbuf, js, je, ks, ke, is, ie,           &
     &                           jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_pack_lint_ad
     
      SUBROUTINE f_unpack_int_ad ( inbuf, outbuf, memorder, js, je, ks, ke,           &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER outbuf(*), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_unpack_real_ad_ijk( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_unpack_real_ad_jik( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_unpack_real_ad_ikj( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_unpack_real_ad_jki( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_unpack_real_ad_kij( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_unpack_real_ad_kji( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_unpack_int_ad
     
      SUBROUTINE f_unpack_lint_ad ( inbuf, outbuf, memorder, js, je, ks,               &
     &                 ke, is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        USE duplicate_of_driver_constants
        IMPLICIT NONE
        INTEGER, INTENT(IN) ::  memorder
        INTEGER jms, jme, kms, kme, ims, ime
        INTEGER*8 outbuf(*), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        SELECT CASE ( memorder )
          CASE ( DATA_ORDER_XYZ )
            CALL f_unpack_lreal_ad_ijk( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YXZ )
            CALL f_unpack_lreal_ad_jik( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_XZY )
            CALL f_unpack_lreal_ad_ikj( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_YZX )
            CALL f_unpack_lreal_ad_jki( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZXY )
            CALL f_unpack_lreal_ad_kij( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
          CASE ( DATA_ORDER_ZYX )
            CALL f_unpack_lreal_ad_kji( inbuf, outbuf, js, je, ks, ke,                   &
     &                      is, ie, jms, jme, kms, kme, ims, ime, curs )
        END SELECT
        RETURN
      END SUBROUTINE f_unpack_lint_ad

!ikj
      SUBROUTINE f_pack_real_ad_ikj ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(ims:ime,kms:kme,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO k = ks, ke
            DO i = is, ie
              outbuf(p) = inbuf(i,k,j)
              inbuf(i,k,j) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_ikj
     
      SUBROUTINE f_pack_lreal_ad_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(ims:ime,kms:kme,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO k = ks, ke
            DO i = is, ie
              outbuf(p) = inbuf(i,k,j)
              inbuf(i,k,j) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_ikj
     
      SUBROUTINE f_unpack_real_ad_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(ims:ime,kms:kme,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO k = ks, ke
            DO i = is, ie
              outbuf(i,k,j) = outbuf(i,k,j) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_ikj
     
      SUBROUTINE f_unpack_lreal_ad_ikj ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(ims:ime,kms:kme,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO k = ks, ke
            DO i = is, ie
              outbuf(i,k,j) = outbuf(i,k,j) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_ikj

!jki
      SUBROUTINE f_pack_real_ad_jki ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(jms:jme,kms:kme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
            DO i = is, ie
          DO k = ks, ke
        DO j = js, je
              outbuf(p) = inbuf(j,k,i)
              inbuf(j,k,i) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_jki
     
      SUBROUTINE f_pack_lreal_ad_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(jms:jme,kms:kme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
            DO i = is, ie
          DO k = ks, ke
        DO j = js, je
              outbuf(p) = inbuf(j,k,i)
              inbuf(j,k,i) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_jki
     
      SUBROUTINE f_unpack_real_ad_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(jms:jme,kms:kme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
            DO i = is, ie
          DO k = ks, ke
        DO j = js, je
              outbuf(j,k,i) = outbuf(j,k,i) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_jki
     
      SUBROUTINE f_unpack_lreal_ad_jki ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(jms:jme,kms:kme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
            DO i = is, ie
          DO k = ks, ke
        DO j = js, je
              outbuf(j,k,i) = outbuf(j,k,i) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_jki

!ijk
      SUBROUTINE f_pack_real_ad_ijk ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(ims:ime,jms:jme,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO j = js, je
            DO i = is, ie
              outbuf(p) = inbuf(i,j,k)
              inbuf(i,j,k) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_ijk
     
      SUBROUTINE f_pack_lreal_ad_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(ims:ime,jms:jme,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO j = js, je
            DO i = is, ie
              outbuf(p) = inbuf(i,j,k)
              inbuf(i,j,k) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_ijk
     
      SUBROUTINE f_unpack_real_ad_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(ims:ime,jms:jme,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO j = js, je
            DO i = is, ie
              outbuf(i,j,k) = outbuf(i,j,k) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_ijk
     
      SUBROUTINE f_unpack_lreal_ad_ijk ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(ims:ime,jms:jme,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO j = js, je
            DO i = is, ie
              outbuf(i,j,k) = outbuf(i,j,k) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_ijk
     
!jik
      SUBROUTINE f_pack_real_ad_jik ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(jms:jme,ims:ime,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO i = is, ie
            DO j = js, je
              outbuf(p) = inbuf(j,i,k)
              inbuf(j,i,k) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_jik
     
      SUBROUTINE f_pack_lreal_ad_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(jms:jme,ims:ime,kms:kme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO i = is, ie
            DO j = js, je
              outbuf(p) = inbuf(j,i,k)
              inbuf(j,i,k) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_jik
     
      SUBROUTINE f_unpack_real_ad_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(jms:jme,ims:ime,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO i = is, ie
            DO j = js, je
              outbuf(j,i,k) = outbuf(j,i,k) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_jik
     
      SUBROUTINE f_unpack_lreal_ad_jik ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(jms:jme,ims:ime,kms:kme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO k = ks, ke
          DO i = is, ie
            DO j = js, je
              outbuf(j,i,k) = outbuf(j,i,k) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_jik

!kij
      SUBROUTINE f_pack_real_ad_kij ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(kms:kme,ims:ime,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO i = is, ie
            DO k = ks, ke
              outbuf(p) = inbuf(k,i,j)
              inbuf(k,i,j) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_kij
     
      SUBROUTINE f_pack_lreal_ad_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(kms:kme,ims:ime,jms:jme), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO i = is, ie
            DO k = ks, ke
              outbuf(p) = inbuf(k,i,j)
              inbuf(k,i,j) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_kij
     
      SUBROUTINE f_unpack_real_ad_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(kms:kme,ims:ime,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO i = is, ie
            DO k = ks, ke
              outbuf(k,i,j) = outbuf(k,i,j) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_kij
     
      SUBROUTINE f_unpack_lreal_ad_kij ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(kms:kme,ims:ime,jms:jme), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
        DO j = js, je
          DO i = is, ie
            DO k = ks, ke
              outbuf(k,i,j) = outbuf(k,i,j) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_kij

!kji
      SUBROUTINE f_pack_real_ad_kji ( inbuf, outbuf, js, je, ks, ke,              &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    inbuf(kms:kme,jms:jme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
          DO i = is, ie
        DO j = js, je
            DO k = ks, ke
              outbuf(p) = inbuf(k,j,i)
              inbuf(k,j,i) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_real_ad_kji
     
      SUBROUTINE f_pack_lreal_ad_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  inbuf(kms:kme,jms:jme,ims:ime), outbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
          DO i = is, ie
        DO j = js, je
            DO k = ks, ke
              outbuf(p) = inbuf(k,j,i)
              inbuf(k,j,i) = 0.0
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_pack_lreal_ad_kji
     
      SUBROUTINE f_unpack_real_ad_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL    outbuf(kms:kme,jms:jme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
          DO i = is, ie
        DO j = js, je
            DO k = ks, ke
              outbuf(k,j,i) = outbuf(k,j,i) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_real_ad_kji
     
      SUBROUTINE f_unpack_lreal_ad_kji ( inbuf, outbuf, js, je, ks, ke,            &
     &                is, ie, jms, jme, kms, kme, ims, ime, curs ) 
        IMPLICIT NONE
        INTEGER jms, jme, kms, kme, ims, ime
        REAL*8  outbuf(kms:kme,jms:jme,ims:ime), inbuf(*)
        INTEGER js, je, ks, ke, is, ie, curs
        ! Local
        INTEGER i,j,k,p
        p = 1
          DO i = is, ie
        DO j = js, je
            DO k = ks, ke
              outbuf(k,j,i) = outbuf(k,j,i) + inbuf(p)
              p = p + 1
            ENDDO
          ENDDO
        ENDDO
        curs = p - 1
        RETURN
      END SUBROUTINE f_unpack_lreal_ad_kji
#endif
