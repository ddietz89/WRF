MODULE wrf_rkscalar_dispatch_module
  USE module_configure, ONLY: grid_config_rec_type
  USE ISO_C_BINDING, ONLY: C_INT
  USE ISO_FORTRAN_ENV, ONLY: INT64
  USE wrf_rkscalar_later_fast_module, ONLY: wrf_rkscalar_later_fast
  IMPLICIT NONE
CONTAINS
SUBROUTINE rk_update_scalar( scs, sce,                      &
                             scalar_1, scalar_2, sc_tend,   &
                             advh_t, advz_t,                &
                             advect_tend,                   &
                             h_tendency, z_tendency,        &
                             msftx, msfty, c1, c2,          &
                             mu_old, mu_new, mu_base,       &
                             rk_step, dt, spec_zone,        &
                             config_flags,                  &
                             tenddec,                      &
                             ids, ide, jds, jde, kds, kde,  &
                             ims, ime, jms, jme, kms, kme,  &
                             its, ite, jts, jte, kts, kte  )

   IMPLICIT NONE

   

   TYPE(grid_config_rec_type   ) ,   INTENT(IN   ) :: config_flags

   LOGICAL ,                INTENT(IN   ) :: tenddec

   INTEGER ,                INTENT(IN   ) :: scs, sce, rk_step, spec_zone
   INTEGER ,                INTENT(IN   ) :: ids, ide, jds, jde, kds, kde, &
                                             ims, ime, jms, jme, kms, kme, &
                                             its, ite, jts, jte, kts, kte

   REAL,                    INTENT(IN   ) :: dt

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme , scs:sce),                &
         INTENT(INOUT)                                  :: scalar_1,    &
                                                           scalar_2

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme , scs:sce),                &
         INTENT(IN)                                     :: sc_tend

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ),                &
         INTENT(IN)                                  :: advect_tend

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ), INTENT(INOUT) , OPTIONAL :: advh_t,  advz_t 
   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ), INTENT(IN   ) :: h_tendency, z_tendency 

   REAL, DIMENSION(ims:ime, jms:jme  ), INTENT(IN   ) ::  mu_old,  &
                                                          mu_new,  &
                                                          mu_base, &
                                                          msftx,   &
                                                          msfty

   REAL, DIMENSION(kms:kme ), INTENT(IN   ) ::  c1, c2

   INTEGER :: i_start,i_end,j_start,j_end,k_start,k_end
   INTEGER :: i_start_spc,i_end_spc,j_start_spc,j_end_spc,k_start_spc,k_end_spc
   LOGICAL :: skip_clear, fast_ok, diag_active
   INTEGER(INT64) :: row_count64
   INTERFACE
SUBROUTINE wrf_rkscalar_original( scs, sce,                      &
                             scalar_1, scalar_2, sc_tend,   &
                             advh_t, advz_t,                &
                             advect_tend,                   &
                             h_tendency, z_tendency,        &
                             msftx, msfty, c1, c2,          &
                             mu_old, mu_new, mu_base,       &
                             rk_step, dt, spec_zone,        &
                             config_flags,                  &
                             tenddec,                      &
                             ids, ide, jds, jde, kds, kde,  &
                             ims, ime, jms, jme, kms, kme,  &
                             its, ite, jts, jte, kts, kte  )

     USE module_configure, ONLY: grid_config_rec_type
   IMPLICIT NONE

   

   TYPE(grid_config_rec_type   ) ,   INTENT(IN   ) :: config_flags

   LOGICAL ,                INTENT(IN   ) :: tenddec

   INTEGER ,                INTENT(IN   ) :: scs, sce, rk_step, spec_zone
   INTEGER ,                INTENT(IN   ) :: ids, ide, jds, jde, kds, kde, &
                                             ims, ime, jms, jme, kms, kme, &
                                             its, ite, jts, jte, kts, kte

   REAL,                    INTENT(IN   ) :: dt

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme , scs:sce),                &
         INTENT(INOUT)                                  :: scalar_1,    &
                                                           scalar_2

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme , scs:sce),                &
         INTENT(IN)                                     :: sc_tend

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ),                &
         INTENT(IN)                                  :: advect_tend

   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ), INTENT(INOUT) , OPTIONAL :: advh_t,  advz_t 
   REAL, DIMENSION(ims:ime, kms:kme, jms:jme ), INTENT(IN   ) :: h_tendency, z_tendency 

   REAL, DIMENSION(ims:ime, jms:jme  ), INTENT(IN   ) ::  mu_old,  &
                                                          mu_new,  &
                                                          mu_base, &
                                                          msftx,   &
                                                          msfty

   REAL, DIMENSION(kms:kme ), INTENT(IN   ) ::  c1, c2

END SUBROUTINE wrf_rkscalar_original
     PURE FUNCTION wrf_rkscalar_all_masked() BIND(C, NAME="wrf_phy_interp_all_masked") RESULT(masked)
       IMPORT C_INT
       INTEGER(C_INT) :: masked
     END FUNCTION wrf_rkscalar_all_masked
   END INTERFACE
   fast_ok = .FALSE.
   IF (rk_step /= 1 .AND. scs <= sce) THEN
      i_start = its
      i_end   = min(ite,ide-1)
      j_start = jts
      j_end   = min(jte,jde-1)
      k_start = kts
      k_end   = kte-1

      i_start_spc = i_start
      i_end_spc   = i_end
      j_start_spc = j_start
      j_end_spc   = j_end
      k_start_spc = k_start
      k_end_spc   = k_end

    IF( config_flags%nested .or. config_flags%specified ) THEN
      IF( .NOT. config_flags%periodic_x)i_start = max( its,ids+spec_zone )
      IF( .NOT. config_flags%periodic_x)i_end   = min( ite,ide-spec_zone-1 )
      j_start = max( jts,jds+spec_zone )
      j_end   = min( jte,jde-spec_zone-1 )
      k_start = kts
      k_end   = min( kte, kde-1 )
    ENDIF
    skip_clear = i_start==its .AND. i_end==MIN(ite,ide-1) .AND. j_start==jts .AND. j_end==MIN(jte,jde-1) .AND. k_start==kts .AND. k_end==MIN(kte,kde-1)
     IF (skip_clear .AND. i_start <= i_end .AND. j_start <= j_end .AND. k_start <= k_end) THEN
       row_count64 = INT(i_end,INT64)-INT(i_start,INT64)+1_INT64
       IF (row_count64 >= 4_INT64 .AND. row_count64 <= INT(HUGE(0),INT64) .AND. &
           i_start == i_start_spc .AND. i_end == i_end_spc .AND. &
           j_start == j_start_spc .AND. j_end == j_end_spc .AND. &
           k_start == k_start_spc .AND. k_end == k_end_spc) THEN
         diag_active = .FALSE.
         IF (PRESENT(advh_t) .AND. PRESENT(advz_t)) THEN
           diag_active = tenddec .AND. rk_step == config_flags%rk_ord
         ENDIF
         IF (.NOT. diag_active) fast_ok = wrf_rkscalar_all_masked() == 1_C_INT
       ENDIF
     ENDIF
   ENDIF
   IF (fast_ok) THEN
     CALL wrf_rkscalar_later_fast( &
      scs, sce, scalar_1, scalar_2, sc_tend, &
      advh_t, advz_t, advect_tend, h_tendency, z_tendency, &
      msftx, msfty, c1, c2, mu_old, &
      mu_new, mu_base, rk_step, dt, spec_zone, &
      config_flags, tenddec, ids, ide, jds, &
      jde, kds, kde, ims, ime, &
      jms, jme, kms, kme, its, &
      ite, jts, jte, kts, kte)
   ELSE
     CALL wrf_rkscalar_original( &
      scs, sce, scalar_1, scalar_2, sc_tend, &
      advh_t, advz_t, advect_tend, h_tendency, z_tendency, &
      msftx, msfty, c1, c2, mu_old, &
      mu_new, mu_base, rk_step, dt, spec_zone, &
      config_flags, tenddec, ids, ide, jds, &
      jde, kds, kde, ims, ime, &
      jms, jme, kms, kme, its, &
      ite, jts, jte, kts, kte)
   ENDIF
END SUBROUTINE rk_update_scalar
END MODULE wrf_rkscalar_dispatch_module
