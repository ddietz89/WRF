MODULE wrf_rkscalar_later_fast_module
 USE module_configure, ONLY: grid_config_rec_type
 IMPLICIT NONE
CONTAINS
SUBROUTINE wrf_rkscalar_later_fast( scs, sce,                      &
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

   INTEGER :: i,j,k,im
   REAL    :: sc_middle, msfsq
   REAL, DIMENSION(its:ite) :: muold, munew

   REAL, DIMENSION(its:ite, kts:kte, jts:jte  ) :: tendency

   INTEGER :: i_start,i_end,j_start,j_end,k_start,k_end
   INTEGER :: i_start_spc,i_end_spc,j_start_spc,j_end_spc,k_start_spc,k_end_spc
   LOGICAL :: skip_clear
   INTEGER :: wrf_n
   INTERFACE
     SUBROUTINE wrf_rkscalar_consumer_ordered4(count,mo,mn,s1,tend,s2,c1v,c2v,dtv)
       INTEGER,INTENT(IN) :: count
       REAL,INTENT(IN) :: mo(*),mn(*),s1(*),tend(*),c1v,c2v,dtv
       REAL,INTENT(INOUT) :: s2(*)
     END SUBROUTINE
   END INTERFACE











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
    IF ( rk_step == 1 ) THEN

      
      

      DO  im = scs,sce
       IF ( .NOT. skip_clear ) THEN
       DO  j = jts, min(jte,jde-1)
       DO  k = kts, min(kte,kde-1)
       DO  i = its, min(ite,ide-1)
           tendency(i,k,j) = 0.
       ENDDO
       ENDDO
       ENDDO
       ENDIF
       IF ( skip_clear .AND.                                              &
            i_start == i_start_spc .AND. i_end == i_end_spc .AND.         &
            j_start == j_start_spc .AND. j_end == j_end_spc .AND.         &
            k_start == k_start_spc .AND. k_end == k_end_spc ) THEN
       DO  j = j_start,j_end

      DO  i = its, min(ite,ide-1)
        MUOLD(i) = MU_OLD(i,j) + MU_BASE(i,j)
        MUNEW(i) = MU_NEW(i,j) + MU_BASE(i,j)
      ENDDO

       DO  k = k_start,k_end
       DO  i = i_start,i_end
          
           tendency(i,k,j) = advect_tend(i,k,j) * msfty(i,j)
           tendency(i,k,j) = tendency(i,k,j) + sc_tend(i,k,j,im)
       ENDDO

      !$omp simd
      DO  i = its, min(ite,ide-1)

        scalar_1(i,k,j,im) = scalar_2(i,k,j,im)
        scalar_2(i,k,j,im) = ((c1(k)*muold(i)+c2(k))*scalar_1(i,k,j,im)   &
                             + dt*tendency(i,k,j))/(c1(k)*munew(i)+c2(k))

      ENDDO
       ENDDO
       ENDDO
       ELSE
       IF (i_start == i_start_spc .AND. i_end == i_end_spc .AND. &
           j_start == j_start_spc .AND. j_end == j_end_spc .AND. &
           k_start == k_start_spc .AND. k_end == k_end_spc) THEN
       DO  j = j_start,j_end
       DO  k = k_start,k_end
       DO  i = i_start,i_end
          
           tendency(i,k,j) = advect_tend(i,k,j) * msfty(i,j)
           tendency(i,k,j) = tendency(i,k,j) + sc_tend(i,k,j,im)
       ENDDO
       ENDDO
       ENDDO
       ELSE
       DO  j = j_start,j_end
       DO  k = k_start,k_end
       DO  i = i_start,i_end
          
           tendency(i,k,j) = advect_tend(i,k,j) * msfty(i,j)
       ENDDO
       ENDDO
       ENDDO
   
       DO  j = j_start_spc,j_end_spc
       DO  k = k_start_spc,k_end_spc
       DO  i = i_start_spc,i_end_spc
           tendency(i,k,j) = tendency(i,k,j) + sc_tend(i,k,j,im)
       ENDDO
       ENDDO
       ENDDO
   
       ENDIF

      DO  j = jts, min(jte,jde-1)

      DO  i = its, min(ite,ide-1)
        MUOLD(i) = MU_OLD(i,j) + MU_BASE(i,j)
        MUNEW(i) = MU_NEW(i,j) + MU_BASE(i,j)
      ENDDO

      DO  k = kts, min(kte,kde-1)
      !$omp simd
      DO  i = its, min(ite,ide-1)

        scalar_1(i,k,j,im) = scalar_2(i,k,j,im)
        scalar_2(i,k,j,im) = ((c1(k)*muold(i)+c2(k))*scalar_1(i,k,j,im)   &
                             + dt*tendency(i,k,j))/(c1(k)*munew(i)+c2(k))

      ENDDO
      ENDDO
      ENDDO
       ENDIF

      ENDDO

    ELSE

      

      DO  im = scs, sce
       IF ( .NOT. skip_clear ) THEN
       DO  j = jts, min(jte,jde-1)
       DO  k = kts, min(kte,kde-1)
       DO  i = its, min(ite,ide-1)
           tendency(i,k,j) = 0.
       ENDDO
       ENDDO
       ENDDO
       ENDIF
       IF (i_start == i_start_spc .AND. i_end == i_end_spc .AND. &
           j_start == j_start_spc .AND. j_end == j_end_spc .AND. &
           k_start == k_start_spc .AND. k_end == k_end_spc) THEN
       DO  j = j_start,j_end
       DO  k = k_start,k_end
       !$omp simd
       DO  i = i_start,i_end
           tendency(i,k,j) = advect_tend(i,k,j) * msfty(i,j)
           tendency(i,k,j) = tendency(i,k,j) + sc_tend(i,k,j,im)
       ENDDO
       ENDDO
       ENDDO
       ELSE
       DO  j = j_start,j_end
       DO  k = k_start,k_end
       DO  i = i_start,i_end
           
           tendency(i,k,j) = advect_tend(i,k,j) * msfty(i,j)
       ENDDO
       ENDDO
       ENDDO
   
       DO  j = j_start_spc,j_end_spc
       DO  k = k_start_spc,k_end_spc
       !$omp simd
       DO  i = i_start_spc,i_end_spc
           tendency(i,k,j) = tendency(i,k,j) + sc_tend(i,k,j,im)
       ENDDO
       ENDDO
       ENDDO
       ENDIF

      DO  j = jts, min(jte,jde-1)

      DO  i = its, min(ite,ide-1)
        MUOLD(i) = MU_OLD(i,j) + MU_BASE(i,j)
        MUNEW(i) = MU_NEW(i,j) + MU_BASE(i,j)
      ENDDO

      wrf_n = MIN(ite,ide-1)-its+1
      DO k = kts, min(kte,kde-1)
        CALL wrf_rkscalar_consumer_ordered4(wrf_n,muold(its),munew(its), &
             scalar_1(its,k,j,im),tendency(its,k,j),scalar_2(its,k,j,im), &
             c1(k),c2(k),dt)
      ENDDO

      
      IF ( PRESENT(advh_t) .AND. PRESENT(advz_t) ) THEN
        IF(tenddec.and.rk_step.eq.config_flags%rk_ord) THEN
          DO  k = kts, min(kte,kde-1)
          DO  i = its, min(ite,ide-1)

            advh_t(i,k,j) = advh_t(i,k,j) + (dt*h_tendency(i,k,j)* msfty(i,j))/(c1(k)*munew(i)+c2(k))
            advz_t(i,k,j) = advz_t(i,k,j) + (dt*z_tendency(i,k,j)* msfty(i,j))/(c1(k)*munew(i)+c2(k))

          ENDDO
          ENDDO
        END IF
      END IF
      
      ENDDO

      ENDDO

    END IF

END SUBROUTINE wrf_rkscalar_later_fast
END MODULE wrf_rkscalar_later_fast_module
