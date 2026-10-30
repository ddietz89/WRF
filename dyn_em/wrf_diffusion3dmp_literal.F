SUBROUTINE wrf_diffusion3dmp_literal ( name, field, tendency, MUT, c1, c2,  &
                                       config_flags, base_3d,               &
                                       msfux, msfuy, msfvx, msfvx_inv,      &
                                       msfvy, msftx, msfty,                 &
                                       khdif, xkmhd, rdx, rdy,              &
                                       ids, ide, jds, jde, kds, kde,        &
                                       ims, ime, jms, jme, kms, kme,        &
                                       its, ite, jts, jte, kts, kte        )

   USE module_configure, ONLY: grid_config_rec_type
   IMPLICIT NONE
   
   ! Input data
   
   TYPE(grid_config_rec_type), INTENT(IN   ) :: config_flags

   INTEGER ,        INTENT(IN   ) :: ids, ide, jds, jde, kds, kde, &
                                     ims, ime, jms, jme, kms, kme, &
                                     its, ite, jts, jte, kts, kte

   CHARACTER(LEN=1) ,                          INTENT(IN   ) :: name

   REAL , DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(IN   ) :: field, &
                                                                      xkmhd, &
                                                                      base_3d

   REAL , DIMENSION( ims:ime , kms:kme , jms:jme ) , INTENT(INOUT) :: tendency

   REAL , DIMENSION( ims:ime , jms:jme ) , INTENT(IN   ) :: MUT

   REAL , DIMENSION( ims:ime , jms:jme ) ,         INTENT(IN   ) :: msfux,      &
                                                                    msfuy,      &
                                                                    msfvx,      &
                                                                    msfvx_inv,  &
                                                                    msfvy,      &
                                                                    msftx,      &
                                                                    msfty

   REAL , DIMENSION( kms:kme )           , INTENT(IN   ) :: c1, c2

   REAL ,                                      INTENT(IN   ) :: rdx,       &
                                                                rdy,       &
                                                                khdif

   ! Local data
   
   INTEGER :: i, j, k, itf, jtf, ktf

   INTEGER :: i_start, i_end, j_start, j_end

   REAL :: mrdx, mkrdxm, mkrdxp, &
           mrdy, mkrdym, mkrdyp

   LOGICAL :: specified

!<DESCRIPTION>
!
!  horizontal_diffusion_3dmp computes the horizontal diffusion tendency
!  on model horizontal coordinate surfaces.  This routine computes diffusion
!  a perturbation scalar (field-base_3d).
!
!</DESCRIPTION>

   specified = .false.
   if(config_flags%specified .or. config_flags%nested) specified = .true.

   ktf=MIN(kte,kde-1)
   
      i_start = its
      i_end   = MIN(ite,ide-1)
      j_start = jts
      j_end   = MIN(jte,jde-1)

      IF ( config_flags%open_xs .or. specified ) i_start = MAX(ids+1,its)
      IF ( config_flags%open_xe .or. specified ) i_end   = MIN(ide-2,ite)
      IF ( config_flags%open_ys .or. specified ) j_start = MAX(jds+1,jts)
      IF ( config_flags%open_ye .or. specified ) j_end   = MIN(jde-2,jte)
      IF ( config_flags%periodic_x ) i_start = its
      IF ( config_flags%periodic_x ) i_end = MIN(ite,ide-1)

      DO j = j_start, j_end
      DO k=kts,ktf
      DO i = i_start, i_end

         mkrdxm=(msfux(i,j)/msfuy(i,j))*0.5*(xkmhd(i,k,j)+xkmhd(i-1,k,j))*0.5*((c1(k)*MUT(i,j)+c2(k))+(c1(k)*MUT(i-1,j)+c2(k)))*rdx
         mkrdxp=(msfux(i+1,j)/msfuy(i+1,j))*0.5*(xkmhd(i+1,k,j)+xkmhd(i,k,j))*0.5*((c1(k)*MUT(i+1,j)+c2(k))+(c1(k)*MUT(i,j)+c2(k)))*rdx
         mrdx=msftx(i,j)*msfty(i,j)*rdx
!         mkrdym=(msfvy(i,j)/msfvx(i,j))*0.5*(xkmhd(i,k,j)+xkmhd(i,k,j-1))*0.5*((c1(k)*MUT(i,j)+c2(k))+(c1(k)*MUT(i,j-1)+c2(k)))*rdy
!         mkrdyp=(msfvy(i,j+1)/msfvx(i,j+1))*0.5*(xkmhd(i,k,j+1)+xkmhd(i,k,j))*0.5*((c1(k)*MUT(i,j+1)+c2(k))+(c1(k)*MUT(i,j)+c2(k)))*rdy
         mkrdym=(msfvy(i,j)*msfvx_inv(i,j))*0.5*(xkmhd(i,k,j)+xkmhd(i,k,j-1))*0.5*((c1(k)*MUT(i,j)+c2(k))+(c1(k)*MUT(i,j-1)+c2(k)))*rdy
         mkrdyp=(msfvy(i,j+1)*msfvx_inv(i,j+1))*0.5*(xkmhd(i,k,j+1)+xkmhd(i,k,j))*0.5*((c1(k)*MUT(i,j+1)+c2(k))+(c1(k)*MUT(i,j)+c2(k)))*rdy
         mrdy=msftx(i,j)*msfty(i,j)*rdy

            tendency(i,k,j)=tendency(i,k,j)+(                        &
                    mrdx*( mkrdxp*(   field(i+1,k,j)  -field(i  ,k,j)      &
                                   -base_3d(i+1,k,j)+base_3d(i  ,k,j) )    &
                          -mkrdxm*(   field(i  ,k,j)  -field(i-1,k,j)      &
                                   -base_3d(i  ,k,j)+base_3d(i-1,k,j) )  ) &
                   +mrdy*( mkrdyp*(   field(i,k,j+1)  -field(i,k,j  )      &
                                   -base_3d(i,k,j+1)+base_3d(i,k,j  ) )    &
                          -mkrdym*(   field(i,k,j  )  -field(i,k,j-1)      &
                                   -base_3d(i,k,j  )+base_3d(i,k,j-1) )  ) &
                                                                         )
      ENDDO
      ENDDO
      ENDDO

END SUBROUTINE wrf_diffusion3dmp_literal
