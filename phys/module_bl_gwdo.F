!=================================================================================================================
 module module_bl_gwdo
 use ccpp_kind_types,only: kind_phys

 use bl_gwdo,only: bl_gwdo_run


 implicit none
 private
 public:: gwdo
#ifdef WRF_GPU_RESIDENT
 public:: gwdo_gpu
#ifdef WRF_GPU_KCOL
 integer, parameter:: KTG_GWD = WRF_GPU_KCOL   ! max levels of the device column routine (kcol.py)
#else
 integer, parameter:: KTG_GWD = 64   ! max levels of the device column routine (fixed-size locals)
#endif
#endif


 contains


!=================================================================================================================
 subroutine gwdo(u3d,v3d,t3d,qv3d,p3d,p3di,pi3d,z,                            &
                 rublten,rvblten,                                             &
                 dtaux3d,dtauy3d,dusfcg,dvsfcg,                               &
                 var2d,oc12d,oa2d1,oa2d2,oa2d3,oa2d4,ol2d1,ol2d2,ol2d3,ol2d4, &
                 elvmax,sina,cosa,znu,znw,p_top,                              &
                 cp,g,rd,rv,ep1,pi,                                           &
                 dt,dx,kpbl2d,itimestep,                                      &
                 dx_factor,if_nonhyd,                                         &
                 ids,ide, jds,jde, kds,kde,                                   &
                 ims,ime, jms,jme, kms,kme,                                   &
                 its,ite, jts,jte, kts,kte,                                   &
                 errmsg,errflg                                                &
                )
!=================================================================================================================
!                                                                       
!-- u3d         3d u-velocity interpolated to theta points (m/s)
!-- v3d         3d v-velocity interpolated to theta points (m/s)
!-- t3d         temperature (k)
!-- qv3d        3d water vapor mixing ratio (kg/kg)
!-- p3d         3d pressure (pa)
!-- p3di        3d pressure (pa) at interface level
!-- pi3d        3d exner function (dimensionless)
!-- rublten     u tendency due to pbl parameterization (m/s/s) 
!-- rvblten     v tendency due to pbl parameterization (m/s/s)
!-- sina        sine rotation angle
!-- cosa        cosine rotation angle
!-- znu         eta values (sigma values)
!-- cp          heat capacity at constant pressure for dry air (j/kg/k)
!-- g           acceleration due to gravity (m/s^2)
!-- rd          gas constant for dry air (j/kg/k)
!-- z           height above sea level (m)
!-- rv          gas constant for water vapor (j/kg/k)
!-- dt          time step (s)
!-- dx          model grid interval (m)
!-- ep1         constant for virtual temperature (r_v/r_d - 1) (dimensionless)
!-- ids         start index for i in domain
!-- ide         end index for i in domain
!-- jds         start index for j in domain
!-- jde         end index for j in domain
!-- kds         start index for k in domain
!-- kde         end index for k in domain
!-- ims         start index for i in memory
!-- ime         end index for i in memory
!-- jms         start index for j in memory
!-- jme         end index for j in memory
!-- kms         start index for k in memory
!-- kme         end index for k in memory
!-- its         start index for i in tile
!-- ite         end index for i in tile
!-- jts         start index for j in tile
!-- jte         end index for j in tile
!-- kts         start index for k in tile
!-- kte         end index for k in tile
!
!=================================================================================================================

!--- input arguments:
 integer,intent(in):: ids,ide,jds,jde,kds,kde, &
                      ims,ime,jms,jme,kms,kme, &
                      its,ite,jts,jte,kts,kte
 integer,intent(in):: itimestep

 integer,intent(in),dimension(ims:ime,jms:jme):: kpbl2d

 real(kind=kind_phys),intent(in):: dt,cp,g,rd,rv,ep1,pi
 real(kind=kind_phys),intent(in):: dx_factor
 logical             ,intent(in):: if_nonhyd
 real(kind=kind_phys),intent(in),optional:: p_top

 real(kind=kind_phys),intent(in),dimension(kms:kme),optional:: &
                                                                 znu, &
                                                                 znw

 real(kind=kind_phys),intent(in),dimension(ims:ime,jms:jme):: &
                                                                  dx, &
                                                               var2d, &
                                                               oc12d, &
                                             oa2d1,oa2d2,oa2d3,oa2d4, &
                                             ol2d1,ol2d2,ol2d3,ol2d4, &
                                                              elvmax, &
                                                           sina,cosa

 real(kind=kind_phys),intent(in),dimension(ims:ime,kms:kme,jms:jme):: &
                                                                qv3d, &
                                                                 p3d, &
                                                                pi3d, &
                                                                 t3d, &
                                                                 u3d, &
                                                                 v3d, &
                                                                   z

 real(kind=kind_phys),intent(in),dimension(ims:ime,kms:kme,jms:jme):: &
                                                                 p3di

!--- output arguments:
 character(len=*),intent(out)::  errmsg

 integer,intent(out):: errflg

 real(kind=kind_phys),intent(out),dimension(ims:ime,jms:jme):: &
                                                              dusfcg, &
                                                              dvsfcg

 real(kind=kind_phys),intent(out),dimension(ims:ime,kms:kme,jms:jme ):: &
                                                             dtaux3d, &
                                                             dtauy3d

!--- inout arguments:
 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme):: &
                                                             rublten, &
                                                             rvblten

!--- local variables and arrays:
 integer:: i,j,k

 real(kind=kind_phys),dimension(its:ite):: &
    var2d_hv,oc12d_hv,dx_hv,sina_hv,cosa_hv,elvmax_hv
 real(kind=kind_phys),dimension(its:ite):: &
    oa2d1_hv,oa2d2_hv,oa2d3_hv,oa2d4_hv,ol2d1_hv,ol2d2_hv,ol2d3_hv,ol2d4_hv
 real(kind=kind_phys),dimension(its:ite):: &
    dusfcg_hv,dvsfcg_hv

 real(kind=kind_phys),dimension(its:ite,kts:kte):: &
     u3d_hv,v3d_hv,t3d_hv,qv3d_hv,pi3d_hv,p3d_hv,z_hv

 real(kind=kind_phys),dimension(its:ite,kts:kte):: &
     rublten_hv,rvblten_hv,dtaux3d_hv,dtauy3d_hv

 real(kind=kind_phys),dimension(its:ite,kms:kme):: &
     p3di_hv

!-----------------------------------------------------------------------------------------------------------------

!  Outer j-loop. Allows consistency between WRF and MPAS in the driver.

 do j = jts,jte

    !  All variables for gwdo2d are tile-sized and have only a single
    !  horizontal dimension. The _hv suffix refers to "horizontal vertical",
    !  a reminder that there is a single horizontal index. Yes, we know that 
    !  variables that have only a horizontal index are not *really* _hv.

    !  All of the following 3d and 2d variables are declared intent(in) in the
    !  gwdo2d subroutine, so there is no need to put the updated values back
    !  from the temporary arrays back into the original arrays.

    !  Variables that are INTENT(IN) or INTENT(INOUT)

    !  3d, interface levels:
    do k = kts,kte+1
       do i = its,ite
          p3di_hv(i,k) = p3di(i,k,j)
       enddo
    enddo

    !  3d, layers:
    do k = kts,kte
       do i = its,ite
          rublten_hv(i,k) = rublten(i,k,j)
          rvblten_hv(i,k) = rvblten(i,k,j)
              u3d_hv(i,k) =     u3d(i,k,j)
              v3d_hv(i,k) =     v3d(i,k,j)
              t3d_hv(i,k) =     t3d(i,k,j)
             qv3d_hv(i,k) =    qv3d(i,k,j)
              p3d_hv(i,k) =     p3d(i,k,j)
             pi3d_hv(i,k) =    pi3d(i,k,j)
                z_hv(i,k) =       z(i,k,j)
       enddo
    enddo

    !  2d:
    do i = its,ite
          dx_hv(i) =    dx(i,j)
       var2d_hv(i) = var2d(i,j)
       oc12d_hv(i) = oc12d(i,j)
        sina_hv(i) =  sina(i,j)
        cosa_hv(i) =  cosa(i,j)
       oa2d1_hv(i) = oa2d1(i,j)
       oa2d2_hv(i) = oa2d2(i,j)
       oa2d3_hv(i) = oa2d3(i,j)
       oa2d4_hv(i) = oa2d4(i,j)
       ol2d1_hv(i) = ol2d1(i,j)
       ol2d2_hv(i) = ol2d2(i,j)
       ol2d3_hv(i) = ol2d3(i,j)
       ol2d4_hv(i) = ol2d4(i,j)
       elvmax_hv(i) =elvmax(i,j)
    enddo

    call bl_gwdo_run(sina=sina_hv,cosa=cosa_hv                &
                    ,rublten=rublten_hv,rvblten=rvblten_hv    &
                    ,dtaux3d=dtaux3d_hv,dtauy3d=dtauy3d_hv    &
                    ,dusfcg=dusfcg_hv,dvsfcg=dvsfcg_hv        &
                    ,uproj=u3d_hv,vproj=v3d_hv                &
                    ,t1=t3d_hv,q1=qv3d_hv                     &
                    ,prsi=p3di_hv                             &
                    ,prsl=p3d_hv,prslk=pi3d_hv                &
                    ,zl=z_hv                                  &
                    ,var=var2d_hv,oc1=oc12d_hv                &
                    ,oa2d1=oa2d1_hv, oa2d2=oa2d2_hv           &
                    ,oa2d3=oa2d3_hv, oa2d4=oa2d4_hv           &
                    ,ol2d1=ol2d1_hv, ol2d2=ol2d2_hv           &
                    ,ol2d3=ol2d3_hv, ol2d4=ol2d4_hv           &
                    ,omax=elvmax_hv                           &
                    ,dx_factor=dx_factor,if_nonhyd=if_nonhyd  &
                    ,g_=g,cp_=cp,rd_=rd,rv_=rv,fv_=ep1,pi_=pi &
                    ,dxmeter=dx_hv,deltim=dt                  &
                    ,its=its,ite=ite,kte=kte,kme=kte+1        &
                    ,errmsg=errmsg,errflg=errflg)

    !  Variables that are INTENT(OUT) or INTENT(INOUT):

    !  3d, layers:
    do k = kts,kte
       do i = its,ite
          rublten(i,k,j) = rublten_hv(i,k)
          rvblten(i,k,j) = rvblten_hv(i,k)
          dtaux3d(i,k,j) = dtaux3d_hv(i,k)
          dtauy3d(i,k,j) = dtauy3d_hv(i,k)
       enddo
    enddo

    !  2d:
    do i = its,ite
       dusfcg(i,j) = dusfcg_hv(i)
       dvsfcg(i,j) = dvsfcg_hv(i)
    enddo

 enddo ! Outer J-loop

 end subroutine gwdo

!=================================================================================================================
#ifdef WRF_GPU_RESIDENT
!=================================================================================================================
! GPU residency builds: gwdo on the device, one column per thread (bl_gwdo_run_g with its=ite=1); all arrays
! present on the device. Same per-column arithmetic as gwdo/bl_gwdo_run.
 subroutine gwdo_gpu(u3d,v3d,t3d,qv3d,p3d,p3di,pi3d,z,                        &
                 rublten,rvblten,                                             &
                 dtaux3d,dtauy3d,dusfcg,dvsfcg,                               &
                 var2d,oc12d,oa2d1,oa2d2,oa2d3,oa2d4,ol2d1,ol2d2,ol2d3,ol2d4, &
                 elvmax,sina,cosa,                                            &
                 cp,g,rd,rv,ep1,pi,                                           &
                 dt,dx,dx_factor,if_nonhyd,                                   &
                 ims,ime, jms,jme, kms,kme,                                   &
                 its,ite, jts,jte, kts,kte)
 integer,intent(in):: ims,ime,jms,jme,kms,kme,its,ite,jts,jte,kts,kte
 real(kind=kind_phys),intent(in):: dt,cp,g,rd,rv,ep1,pi,dx_factor
 logical,intent(in):: if_nonhyd
 real(kind=kind_phys),intent(in),dimension(ims:ime,jms:jme):: dx,var2d,oc12d,oa2d1,oa2d2,oa2d3,oa2d4, &
                                                             ol2d1,ol2d2,ol2d3,ol2d4,elvmax,sina,cosa
 real(kind=kind_phys),intent(in),dimension(ims:ime,kms:kme,jms:jme):: qv3d,p3d,pi3d,t3d,u3d,v3d,z,p3di
 real(kind=kind_phys),intent(out),dimension(ims:ime,jms:jme):: dusfcg,dvsfcg
 real(kind=kind_phys),intent(out),dimension(ims:ime,kms:kme,jms:jme):: dtaux3d,dtauy3d
 real(kind=kind_phys),intent(inout),dimension(ims:ime,kms:kme,jms:jme):: rublten,rvblten
 integer:: i,j,k
 real(kind=kind_phys),dimension(1,KTG_GWD+1):: uc,vc,tc,qc,pc,pic,zc,p8c,rub,rvb,dtx,dty
 real(kind=kind_phys),dimension(1):: dxc,varc,occ,sinc,cosc,oa1c,oa2c,oa3c,oa4c,ol1c,ol2c,ol3c,ol4c,omc,dusc,dvsc
 ! WRF_GPU_GWCOMPACT=1 (default 0: measured no gain on big1000, bit-identical): column list with the orographic columns first (var2d > 0 and elvmax > hmt_min,
 ! the scheme's static ldrag conditions); flat/ocean columns take the scheme's no-drag path. Per-column arithmetic
 ! unchanged (bit-identical).
 integer, save :: gw_compact = -1
 integer, allocatable, save :: gw_li(:), gw_lj(:), gw_flag(:,:), gw_nact(:), gw_offa(:), gw_offi(:)
 integer :: nx_, ny_, ncol_, n_, jj_, cnt_, act_, pa_, pi_, tot_, st_
 character(len=8) :: cv_
      IF ( gw_compact < 0 ) THEN
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_GWCOMPACT', cv_, STATUS=st_ )
         gw_compact = 0
         IF ( st_ == 0 ) READ( cv_, *, IOSTAT=st_ ) gw_compact
         IF ( st_ /= 0 ) gw_compact = 0
      ENDIF
           IF ( kte > KTG_GWD ) CALL wrf_error_fatal('gwdo_gpu: kte > KTG_GWD (rebuild with a larger GPU_KCOL)')
 nx_ = ite - its + 1 ; ny_ = jte - jts + 1 ; ncol_ = nx_*ny_
      IF ( ALLOCATED(gw_li) ) THEN
         IF ( SIZE(gw_li) /= ncol_ .OR. SIZE(gw_nact) /= ny_ .OR. SIZE(gw_flag,1) /= nx_ ) THEN
!$acc exit data delete(gw_li, gw_lj, gw_flag, gw_nact, gw_offa, gw_offi)
            DEALLOCATE( gw_li, gw_lj, gw_flag, gw_nact, gw_offa, gw_offi )
         ENDIF
      ENDIF
      IF ( .NOT. ALLOCATED(gw_li) ) THEN
         ALLOCATE( gw_li(ncol_), gw_lj(ncol_), gw_flag(nx_,ny_), gw_nact(ny_), gw_offa(ny_), gw_offi(ny_) )
!$acc enter data create(gw_li, gw_lj, gw_flag, gw_nact, gw_offa, gw_offi)
      ENDIF
      IF ( gw_compact == 1 ) THEN
!$acc parallel loop gang present(gw_flag, gw_nact, var2d, elvmax)
         do j = jts, jte
            cnt_ = 0
!$acc loop vector reduction(+:cnt_) private(act_)
            do i = its, ite
               act_ = 0
               if ( var2d(i,j) .gt. 0. .and. elvmax(i,j) .gt. 50. ) act_ = 1
               gw_flag(i-its+1, j-jts+1) = act_
               cnt_ = cnt_ + act_
            enddo
            gw_nact(j-jts+1) = cnt_
         enddo
!$acc parallel num_gangs(1) num_workers(1) vector_length(1) present(gw_nact, gw_offa, gw_offi)
         tot_ = 0
!$acc loop seq
         do jj_ = 1, ny_
            gw_offa(jj_) = tot_ ; tot_ = tot_ + gw_nact(jj_)
         enddo
!$acc loop seq
         do jj_ = 1, ny_
            gw_offi(jj_) = tot_ ; tot_ = tot_ + nx_ - gw_nact(jj_)
         enddo
!$acc end parallel
!$acc parallel loop gang vector_length(1) present(gw_flag, gw_offa, gw_offi, gw_li, gw_lj) private(pa_, pi_)
         do j = jts, jte
            pa_ = gw_offa(j-jts+1) ; pi_ = gw_offi(j-jts+1)
!$acc loop seq
            do i = its, ite
               if ( gw_flag(i-its+1, j-jts+1) == 1 ) then
                  pa_ = pa_ + 1 ; gw_li(pa_) = i ; gw_lj(pa_) = j
               else
                  pi_ = pi_ + 1 ; gw_li(pi_) = i ; gw_lj(pi_) = j
               endif
            enddo
         enddo
      ELSE
!$acc parallel loop gang present(gw_li, gw_lj)
         do j = jts, jte
!$acc loop vector
         do i = its, ite
            gw_li((j-jts)*nx_ + i-its+1) = i ; gw_lj((j-jts)*nx_ + i-its+1) = j
         enddo
         enddo
      ENDIF
!$acc parallel loop gang vector private(uc,vc,tc,qc,pc,pic,zc,p8c,rub,rvb,dtx,dty) &
!$acc private(dxc,varc,occ,sinc,cosc,oa1c,oa2c,oa3c,oa4c,ol1c,ol2c,ol3c,ol4c,omc,dusc,dvsc) &
!$acc present(u3d,v3d,t3d,qv3d,p3d,p3di,pi3d,z,rublten,rvblten,dtaux3d,dtauy3d,dusfcg,dvsfcg) &
!$acc present(var2d,oc12d,oa2d1,oa2d2,oa2d3,oa2d4,ol2d1,ol2d2,ol2d3,ol2d4,elvmax,sina,cosa,dx,gw_li,gw_lj)
 do n_ = 1, ncol_
    i = gw_li(n_) ; j = gw_lj(n_)
    do k = kts,kte
       uc(1,k)  = u3d(i,k,j)
       vc(1,k)  = v3d(i,k,j)
       tc(1,k)  = t3d(i,k,j)
       qc(1,k)  = qv3d(i,k,j)
       pc(1,k)  = p3d(i,k,j)
       pic(1,k) = pi3d(i,k,j)
       zc(1,k)  = z(i,k,j)
       rub(1,k) = rublten(i,k,j)
       rvb(1,k) = rvblten(i,k,j)
    enddo
    do k = kts,kte+1
       p8c(1,k) = p3di(i,k,j)
    enddo
    dxc(1) = dx(i,j) ; varc(1) = var2d(i,j) ; occ(1) = oc12d(i,j)
    sinc(1) = sina(i,j) ; cosc(1) = cosa(i,j)
    oa1c(1) = oa2d1(i,j) ; oa2c(1) = oa2d2(i,j) ; oa3c(1) = oa2d3(i,j) ; oa4c(1) = oa2d4(i,j)
    ol1c(1) = ol2d1(i,j) ; ol2c(1) = ol2d2(i,j) ; ol3c(1) = ol2d3(i,j) ; ol4c(1) = ol2d4(i,j)
    omc(1) = elvmax(i,j)
    call bl_gwdo_run_g(sina=sinc,cosa=cosc                     &
                    ,rublten=rub,rvblten=rvb                  &
                    ,dtaux3d=dtx,dtauy3d=dty                  &
                    ,dusfcg=dusc,dvsfcg=dvsc                  &
                    ,uproj=uc,vproj=vc                        &
                    ,t1=tc,q1=qc                              &
                    ,prsi=p8c                                 &
                    ,prsl=pc,prslk=pic                        &
                    ,zl=zc                                    &
                    ,var=varc,oc1=occ                         &
                    ,oa2d1=oa1c, oa2d2=oa2c                   &
                    ,oa2d3=oa3c, oa2d4=oa4c                   &
                    ,ol2d1=ol1c, ol2d2=ol2c                   &
                    ,ol2d3=ol3c, ol2d4=ol4c                   &
                    ,omax=omc                                 &
                    ,dx_factor=dx_factor,if_nonhyd=if_nonhyd  &
                    ,g_=g,cp_=cp,rd_=rd,rv_=rv,fv_=ep1,pi_=pi &
                    ,dxmeter=dxc,deltim=dt                    &
                    ,its=1,ite=1,kte=kte,kme=kte+1)
    do k = kts,kte
       rublten(i,k,j) = rub(1,k)
       rvblten(i,k,j) = rvb(1,k)
       dtaux3d(i,k,j) = dtx(1,k)
       dtauy3d(i,k,j) = dty(1,k)
    enddo
    dusfcg(i,j) = dusc(1)
    dvsfcg(i,j) = dvsc(1)
 enddo
 end subroutine gwdo_gpu
#endif

#ifdef WRF_GPU_RESIDENT
 subroutine bl_gwdo_run_g(sina, cosa,                                          &
                     rublten,rvblten,                                          &
                     dtaux3d,dtauy3d,                                          &
                     dusfcg,dvsfcg,                                            &
                     uproj, vproj,                                             &
                     t1, q1,                                                   &
                     prsi, prsl, prslk, zl,                                    &
                     var, oc1,                                                 &
                     oa2d1, oa2d2,                                             &
                     oa2d3, oa2d4,                                             &
                     ol2d1, ol2d2,                                             &
                     ol2d3, ol2d4, omax,                                       &
                     dx_factor, if_nonhyd,                                     &
                     g_, cp_, rd_, rv_, fv_, pi_,                              &
                     dxmeter, deltim,                                          &
                     its, ite, kte, kme                                       &
                     )
!$acc routine seq
!-------------------------------------------------------------------------------
!
!  abstract :
!    this code handles the time tendencies of u v due to the effect of
!    mountain induced gravity wave drag from sub-grid scale orography.
!    this routine not only treats the traditional upper-level wave breaking due
!    to mountain variance, but also the enhanced lower-tropospheric wave 
!    breaking due to mountain convexity and asymmetry (kim and arakawa 1995). 
!    thus, in addition to the terrain height data in a model grid gox, 
!    additional 10-2d topographic statistics files are needed, including 
!    orographic standard  deviation (var), convexity (oc1),asymmetry (oa4) and 
!    ol (ol4). the current scheme was implmented as in choi and hong (2015) and 
!    revised as in hong et al (2025), which names kim gwdo since it has been 
!    developed by kiaps staffs for kiaps integrated model system (kim) 
!
!  history log :
!    1996-11-27  implemented onto ncep mrf model 
!                song-you hong, young-joon kim and jordan alpert 
!    2015-07-01  added flow-blocking drag and orographic anisotropy
!                hyun-joo choi
!    2024-11-27  introduced elevation maximum (omax) and numerous revisions
!                song-you hong
!
!  references :
!    hong et al. (2025), wea. forecasting
!    koo and hong (2025), wea. forecasting
!    xu et al. (2024), j. atmos. sci.
!    choi and hong (2015), j.geophys. res.
!    hong et al. (2008), wea. forecasting
!    kim and doyle (2005), q. j. r. meteor. soc.
!    kim and arakawa (1995), j. atmos. sci.
!
!  input :
!    dudt, dvdt       - non-lin tendency for u and v wind component
!    uproj, vproj     - projection-relative U and V m/sec
!    u1, v1           - zonal and meridional wind m/sec  at t0-dt
!    t1               - temperature deg k at t0-dt
!    q1               - mixing ratio at t0-dt
!    deltim           - time step (s)
!    del              - positive increment of pressure across layer (pa)
!    prslk, zl, prsl, prsi    - pressure and height variables
!    oa4, ol4, omax, var, oc1 - orographic statistics
!    if_nonhyd        - logical nonhydrostatic effect of xu et al.
!    dx_factor        - effective grid spacing for gwd stress (=2, default)
!
!  output :
!    dudt, dvdt - wind tendency due to gwdo
!    dtaux2d, dtauy2d - diagnoised orographic gwd
!    dusfc, dvsfc     - gw stress
!
!-------------------------------------------------------------------------------
   implicit none
!
   integer               , intent(in   ) ::                                    &
                                            its, ite, kte, kme
   logical               , intent(in   ) ::                                    &
                                            if_nonhyd
   real(kind=kind_phys)  , intent(in   ) ::                                    &
                                            g_, pi_, rd_, rv_, fv_, cp_,       &
                                            deltim, dx_factor
!
   real(kind=kind_phys), dimension(its:ite)  , intent(in   ) ::                   &
                                            dxmeter,sina, cosa,var, oc1, omax, &
                                            oa2d1, oa2d2, oa2d3, oa2d4,        &
                                            ol2d1, ol2d2, ol2d3, ol2d4
!
   real(kind=kind_phys), dimension(its:ite,kme), intent(in   ) ::                   &
                                            uproj, vproj,t1, q1, prslk, zl,    &
                                            prsl, prsi
!
   real(kind=kind_phys), dimension(its:ite,kme), intent(inout) ::                   &
                                            rublten, rvblten
!
   real(kind=kind_phys), dimension(its:ite),   intent(out)   ::                   &
                                            dusfcg, dvsfcg
   real(kind=kind_phys), dimension(its:ite,kme), intent(out)   ::                   &
                                            dtaux3d, dtauy3d
!
!
   integer, parameter       ::            &
                        kts     = 1      ,&
                        kgwdmin = 2      ,&  !< minim level for reference level
                        mdir    = 8          !< number of wind rose
!
   real(kind=kind_phys), parameter     :: &
                        qmin    = 1.0e-30,&  !< a minimum   
                        ric     = 0.25   ,&  !< critical richadson number
                        velmin  = 1.     ,&  !< minimum wind speed
                        rimin   = -100.  ,&  !< minimum richardson number
                        bnv2min = 1.0e-5 ,&  !< minimum of brunt vaisalla square
                        efacmin = 0.     ,&  !< minimum of enhancement factor
                        efacmax = 10.    ,&  !< maximum of enhancement factor
                        frc     = 1.0    ,&  !< critical Froude number
                        frmax   = 10.    ,&  !< maximum of Frounde number
                        ce      = 0.8    ,&  !< paramter from mesoscacle model
                        cg      = 1.     ,&  !< paramter from mesoscacle model
                        var_min = 10.    ,&  !< minimum of standard deviation [m]
                        hmt_min = 50.    ,&  !< minimum of orographic height  [m]
                        oc_min  = 1.     ,&  !< minimum of convexity
                        oc_max  = 10.    ,&  !< maximum of convexity 
                        olmin   = 1.0e-5 ,&  !< minimum of orographic length
                        odmin   = 0.1    ,&  !< minimum of origraphic direction
                        odmax   = 10.    ,&  !< maximum of origraphic direction
                        cdmin   = 0.     ,&  !< minimum of bulk drag coefficent
                        pcutoff  = 7.5e2 ,&  !< 7.5 mb (33 km) 0.76 mb (50km) 0.1 mb (65km)
                        pcutoff_den  = 0.01  !< 0.01 kgm-3     0.001 kgm-3    0.0001 kgm-3
!
! local variables
!
   integer                              ::                                                     &
                        kgwdmax, latd, lond, i, k, lcap, lcapp1, nwd, idir, klcap, kp1, kblk
!
   real(kind=kind_phys)                 ::                                                     &
                        fdir, cs, rcsks, wdir, ti, rdz, tem1, tem2, temc, tem, temv, dw2, shr2,&
                        bvf2, rdelks, wtkbj, gfac, hd, fro, rim, efac, dtaux, dtauy, denfac,   &
                        fbdcd, zblk, tautem, fbdpe, fbdke, xlinv
!
   real(kind=kind_phys), dimension(1:1)           ::                                       &
                         dusfc, dvsfc, coefm, taub, xn, yn, ubar, vbar, fr, ulow, rulow, bnv,  &
                         oa, ol, oc, rhobar, brvf, delks,delks1, zref, dx_eff
!
   real(kind=kind_phys), dimension(1:1,kts:KTG_GWD)   ::                                       &
                         dudt, dvdt, dtaux2d, dtauy2d
   logical, dimension(1:1)                        :: ldrag, icrilv, flag
!
! option for nonhydrostatic effect (xu et al. 2024)
!
   real(kind=kind_phys)                               :: nhd_effect
!
   real(kind=kind_phys), dimension(1:1,kts:KTG_GWD+1) :: taup
   real(kind=kind_phys), dimension(1:1,kts:KTG_GWD-1) :: velco
   real(kind=kind_phys), dimension(1:1,kts:KTG_GWD)   ::                                       &
                         bnv2, usqj, taud, rho, vtk, vtj, dtfac, del, u1, v1
   real(kind=kind_phys), dimension(1:1,4)         ::                                       &
                         oa4, ol4
!
   integer, dimension(1:1)                        :: kref, komax, kbomax
!
   real(kind=kind_phys), dimension(1:1)           ::                                       &
                         delx, dely, dxy, dxyp, olp, od, area
!
   real(kind=kind_phys), dimension(1:1,4)         ::                                       &
                         dxy4, dxy4p
   real(kind=kind_phys), dimension(4)                 ::                                       &
                         ol4p
   real(kind=kind_phys), dimension(1:1,kts:KTG_GWD+1) :: taufb
!
   integer, parameter, dimension(mdir)                           :: nwdir = (/6,7,5,8,2,3,1,4/)
!-------------------------------------------------------------------------------
!
! constants
!
   lcap   = kte
   lcapp1 = lcap + 1
   fdir   = mdir / (2.0*pi_)
   kgwdmax = kte / 2 ! maximum height for gwd stress : # of vertical levels / 2
!
! initialize CCPP error flag and message
!
!
! calculate length of grid for flow-blocking drag
!
   delx(its:ite) = dxmeter(its:ite)
   dely(its:ite) = dxmeter(its:ite)
   area(its:ite) = delx(its:ite)*dely(its:ite)
   dxy4(its:ite,1)  = delx(its:ite)
   dxy4(its:ite,2)  = dely(its:ite)
   dxy4(its:ite,3)  = sqrt(delx(its:ite)**2. + dely(its:ite)**2.)
   dxy4(its:ite,4)  = dxy4(its:ite,3)
   dxy4p(its:ite,1) = dxy4(its:ite,2)
   dxy4p(its:ite,2) = dxy4(its:ite,1)
   dxy4p(its:ite,3) = dxy4(its:ite,4)
   dxy4p(its:ite,4) = dxy4(its:ite,3)
!
   dx_eff(its:ite) = dx_factor*(delx(its:ite)+dely(its:ite))*0.5
!
! initialize arrays, array syntax is OK for OpenMP since these are local
!
   ldrag   = .false. ; icrilv = .false. ; flag    = .true.
   kref    = 0       ; komax  = 0       ; kbomax = 0
   taufb   = 0.      ; dtaux  = 0.      ; dtauy  = 0.
   xn      = 0.      ; yn     = 0.
   ubar    = 0.      ; vbar   = 0.      ; rhobar  = 0.     ; ulow    = 0.
   oa      = 0.      ; ol     = 0.      ; oc      = 0.     ; taub    = 0.
   usqj    = 0.      ; bnv2   = 0.      ; vtj     = 0.     ; vtk     = 0.
   taup    = 0.      ; taud   = 0.      ; dtaux2d = 0.     ; dtauy2d = 0.
   dtfac   = 1.0     ; xlinv  = 1.0     ; denfac =  1.0
   nhd_effect = 1.0
!
   do k = kts,kte
     do i = its,ite
       vtj(i,k) = t1(i,k)  * (1.+fv_*q1(i,k))
       vtk(i,k) = vtj(i,k) / prslk(i,k)
       !  Density (kg/m^3)
       rho(i,k) = 1./rd_ * prsl(i,k) / vtj(i,k)
       !  Delta p (positive) between interfaces levels (Pa)
       del(i,k) = prsi(i,k) - prsi(i,k+1)
       !  Earth-relative zonal and meridional winds (m/s)
       u1(i,k) = uproj(i,k)*cosa(i) - vproj(i,k)*sina(i)
       v1(i,k) = uproj(i,k)*sina(i) + vproj(i,k)*cosa(i)
     enddo
   enddo
!
   do i = its,ite
       zref(i) = 2. * var(i)
   enddo
!
   do i = its,ite
     flag(i) = .true.
   enddo
!
   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)-zl(i,1)>=zref(i)) then
         kref(i) = k+1
         flag(i) = .false.
       endif
     enddo
   enddo
!
   do i = its,ite
     kref(i) = max(min(kref(i),kgwdmax),kgwdmin)
   enddo
!
!  omax and zl are the heights from the sea level in mpas/wrf
!  whereas in kim/ufs they are defined the values from the model surface 
!
   do i = its,ite
     flag(i) = .true.
   enddo
!
   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)>=omax(i)) then
         komax(i) = k+1
         flag(i)  = .false.
       endif
     enddo
   enddo
!
   do i = its,ite
     komax(i) = max(komax(i),kref(i))
   enddo
!
! kbomax is the starting level computing blocking
!
   do i = its,ite
     flag(i) = .true.
   enddo
!
   do k = kts+1,kte
     do i = its,ite
       if (flag(i) .and. zl(i,k)>=(omax(i)+zref(i))) then
         kbomax(i) = k+1
         flag(i)  = .false.
       endif
     enddo
   enddo
!
   do i = its,ite
     delks(i)  = 1.0 / (prsi(i,1) - prsi(i,kref(i)))
     delks1(i) = 1.0 / (prsl(i,1) - prsl(i,kref(i)))
   enddo
!
! compute low level average below the reference level
!
   do k = kts,kgwdmax
     do i = its,ite
       if (k < kref(i)) then
         rcsks     = del(i,k) * delks(i)
         rdelks    = del(i,k)  * delks(i)
         ubar(i)   = ubar(i) + rcsks  * u1(i,k)      ! u  mean
         vbar(i)   = vbar(i) + rcsks  * v1(i,k)      ! v  mean
         rhobar(i) = rhobar(i) + rdelks * rho(i,k)   ! ho mean
       endif
     enddo
   enddo
!
! figure out low-level horizontal wind direction
!
! nwd  1   2   3   4   5   6   7   8
! wd   w   s  sw  nw   e   n  ne  se
!
   do i = its,ite
     oa4(i,1) = oa2d1(i)
     oa4(i,2) = oa2d2(i)
     oa4(i,3) = oa2d3(i)
     oa4(i,4) = oa2d4(i)
     ol4(i,1) = ol2d1(i)
     ol4(i,2) = ol2d2(i)
     ol4(i,3) = ol2d3(i)
     ol4(i,4) = ol2d4(i)
     wdir  = atan2(ubar(i),vbar(i)) + pi_
     idir  = mod(nint(fdir*wdir),mdir) + 1
     nwd   = nwdir(idir)
     oa(i) = (1-2*int( (nwd-1)/4 )) * oa4(i,mod(nwd-1,4)+1)
     ol(i) = max(ol4(i,mod(nwd-1,4)+1),olmin)
     oc(i) = min(max(oc1(i),oc_min),oc_max)
!
! compute orographic width along (ol) and perpendicular (olp) the wind direction
!
     ol4p(1) = ol4(i,2)
     ol4p(2) = ol4(i,1)
     ol4p(3) = ol4(i,4)
     ol4p(4) = ol4(i,3)
     olp(i)  = max(ol4p(mod(nwd-1,4)+1),olmin)
!
! compute orographic direction (horizontal orographic aspect ratio)
!
     od(i) = olp(i)/ol(i)
     od(i) = min(od(i),odmax)
     od(i) = max(od(i),odmin)
!
! compute grid length in the along(dxy) and cross(dxyp) wind directions
!
     dxy(i)  = dxy4(i,MOD(nwd-1,4)+1)
     dxyp(i) = dxy4p(i,MOD(nwd-1,4)+1)
   enddo
!
! save richardson number in usqj
!
   do k = kts,kte-1
     do i = its,ite
       ti        = 2.0 / (t1(i,k)+t1(i,k+1))
       rdz       = 1./(zl(i,k+1) - zl(i,k))
       tem1      = u1(i,k) - u1(i,k+1)
       tem2      = v1(i,k) - v1(i,k+1)
       dw2       = tem1*tem1 + tem2*tem2
       shr2      = max(dw2,velmin) * rdz * rdz
       bvf2      = g_*(g_/cp_+rdz*(vtj(i,k+1)-vtj(i,k))) * ti
       usqj(i,k) = max(bvf2/shr2,rimin)
       bnv2(i,k) = 2.0*g_*rdz*(vtk(i,k+1)-vtk(i,k))/(vtk(i,k+1)+vtk(i,k))
     enddo
   enddo
!
! compute the low-level wind speed
!
   do i = its,ite
     ulow(i) = max(sqrt(ubar(i)*ubar(i) + vbar(i)*vbar(i)), 1.0)
     rulow(i) = 1./ulow(i)
   enddo
!
! compute the horizontal wind speed projected to the low-level wind
!
   do k = kts,kte-1
     do i = its,ite
       velco(i,k) = 0.5 * ((u1(i,k)+u1(i,k+1)) * ubar(i)                       &
                         + (v1(i,k)+v1(i,k+1)) * vbar(i))
       velco(i,k) = velco(i,k) * rulow(i)
       if ((velco(i,k) < velmin) .and. (velco(i,k) >0. )) then
         velco(i,k) = velmin
       endif
     enddo
   enddo
!
   do i = its,ite
     ldrag(i) = omax(i) <= hmt_min               ! no drag when too small mtn
     ldrag(i) = ldrag(i) .or. var(i) <= 0.       ! no drag when too small std
     ldrag(i) = ldrag(i) .or. velco(i,1)<=0.     ! no drag when critical level
     ldrag(i) = ldrag(i) .or. ulow(i)==1.0       ! no drag when wind calms
   enddo
!
!  no drag when velco<0 or bnv2 < 0 below the reference level
!
   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) ldrag(i) = ldrag(i) .or. velco(i,k)<=0.                &
                                            .or. bnv2(i,k)<0.
     enddo
   enddo
!
!  the low level weighted average ri (sqj) and n**2 (bnv2)
!
   do i = its,ite
     wtkbj     = (prsl(i,1)-prsl(i,2)) * delks1(i)
     bnv2(i,1) = wtkbj * bnv2(i,1)
     usqj(i,1) = wtkbj * usqj(i,1)
   enddo
!
   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) then
         rdelks    = (prsl(i,k)-prsl(i,k+1)) * delks1(i)
         bnv2(i,1) = bnv2(i,1) + bnv2(i,k) * rdelks
         usqj(i,1) = usqj(i,1) + usqj(i,k) * rdelks
       endif
     enddo
   enddo
!
   do i = its,ite
     ldrag(i) = ldrag(i) .or. bnv2(i,1)<=0.     ! no drag when unstable
   enddo
!
! set all ri low level values to the low level value
!
   do k = kgwdmin,kgwdmax
     do i = its,ite
       if (k < kref(i)) usqj(i,k) = usqj(i,1)
     enddo
   enddo
!
   do i = its,ite
     if (.not.ldrag(i))   then
       bnv(i) = sqrt( bnv2(i,1) )
       fr(i) = bnv(i)  * rulow(i) * var(i) * od(i)
       fr(i) = min(fr(i),frmax)
       xn(i)  = ubar(i) * rulow(i)
       yn(i)  = vbar(i) * rulow(i)
     endif
   enddo
!
! compute the base level stress and store it in taub
!
   do i = its,ite
     if (.not. ldrag(i))   then
       efac    = (oa(i) + 2.) ** (ce*fr(i)/frc)
       efac    = min( max(efac,efacmin), efacmax )
       coefm(i) = (1. + ol(i)) ** (oa(i)+1.)
       xlinv    = coefm(i) / dx_eff(i)
       tem      = fr(i) * fr(i) * oc(i)
       gfac     = tem / (tem + cg)
       taub(i)  = rhobar(i) * efac * xlinv * gfac * ulow(i)*ulow(i)*ulow(i)    &
                  / bnv(i)
       if (if_nonhyd) then
         tem = fr(i) * fr(i)
         nhd_effect = -9./8.*tem + exp(-2./fr(i))                              &
                   *(-5./4./tem-0.5/fr(i)+5./4.+9./4.*fr(i)+9./8.*tem)
         taub(i)  = taub(i) * (1.+nhd_effect)
       endif
     else
       taub(i) = 0.
       xn(i)   = 0.
       yn(i)   = 0.
     endif
   enddo
!
! now compute vertical structure of the stress.
!
   do k = kts,kgwdmax
     do i = its,ite
       if (k <= kref(i)) taup(i,k) = taub(i)
     enddo
   enddo
!
   do k = kgwdmin, kte-1                   ! vertical level k loop!
     kp1 = k + 1
     do i = its,ite
!
! unstable if ri < ric or (u-c)=0 crit layer exists
!
       if (k >= kref(i)) then
         icrilv(i) = icrilv(i) .or. ( usqj(i,k) < ric)                         &
                               .or. (velco(i,k) <= 0.)
         brvf(i) = max(bnv2(i,k),bnv2min) ! brunt-vaisala frequency squared
         brvf(i) = sqrt(brvf(i))          ! brunt-vaisala frequency
       endif
     enddo
!
     do i = its,ite
       if (k >= kref(i) .and. (.not. ldrag(i)))   then
         if (.not.icrilv(i) .and. taup(i,k) > 0. ) then
           temv = 1.0 / velco(i,k)
           tem1 = coefm(i)/dxy(i)*(rho(i,kp1)+rho(i,k))*brvf(i)*velco(i,k)*0.5
           hd   = sqrt(taup(i,k) / tem1)
           fro  = brvf(i) * hd * temv
!
! rim is the  minimum-richardson number by shutts (1985)
!
           tem2 = sqrt(usqj(i,k))
           tem  = 1. + tem2 * fro
           rim  = usqj(i,k) * (1.-fro) / (tem * tem)
!
! check stability to employ the 'saturation hypothesis'
!
           if (rim <= ric) then  ! saturation hypothesis!
             temc = 2.0 + 1.0 / tem2
             hd   = velco(i,k) * (2.*sqrt(temc)-temc) / brvf(i)
             taup(i,kp1) = tem1 * hd * hd
           else                    ! no wavebreaking!
             taup(i,kp1) = taup(i,k)
           endif
         endif
       endif
     enddo
   enddo
!
   if (lcap < kte) then
     do klcap = lcapp1,kte
       do i = its,ite
         taup(i,klcap) = prsi(i,klcap) / prsi(i,lcap) * taup(i,lcap)
       enddo
     enddo
   endif
   do i = its,ite
     if (.not.ldrag(i)) then
!
! determine the height of flow-blocking layer
!
       kblk = 0
       fbdpe = 0.
       fbdke = 0.
       do k = kte, kgwdmin, -1
         if (kblk==0 .and. k<=kbomax(i)) then
           fbdpe = fbdpe + bnv2(i,k)*(zl(i,komax(i))-zl(i,k))                  &
                   *del(i,k)/g_/rho(i,k)
           fbdke = 0.5*(u1(i,k)**2.+v1(i,k)**2.)
!
! apply flow-blocking drag when fbdpe >= fbdke
!
           if (fbdpe>=fbdke .and. k<=komax(i)) then
             kblk = k
             zblk = zl(i,kblk)-zl(i,kts)
           endif
         endif
       enddo
       if (kblk /= 0) then
!
! compute flow-blocking stress
!
         fbdcd = max(2.0-1.0/od(i),0.)
         taufb(i,kts) = 0.5*rhobar(i)*coefm(i)/area(i)*fbdcd*dxyp(i)           &
                        *olp(i)*zblk*ulow(i)**2
         tautem = taufb(i,kts)/real(kblk-kts)
         do k = kts+1, kblk
           taufb(i,k) = taufb(i,k-1) - tautem
         enddo
!
! sum orographic GW stress and flow-blocking stress
!
         taup(i,:) = taup(i,:) + taufb(i,:)
       endif
     endif
   enddo
!
! calculate - (g)*d(tau)/d(pressure) and deceleration terms dtaux, dtauy
!
   do k = kts,kte
     do i = its,ite
       taud(i,k) = 1. * (taup(i,k+1) - taup(i,k)) * g_ / del(i,k)
     enddo
   enddo
!
! apply damping factor to prevent wind reversal 
!
   do k = kts,kgwdmax-1
     do i = its,ite
       if (abs(taud(i,k)) >= qmin) then
         dtfac(i,k) = min(dtfac(i,k),abs(velco(i,k)/(deltim*taud(i,k))))
       endif
     enddo
   enddo
!
! apply limiter to mesosphere drag, reduce the drag by a density factor
!
   do k = kgwdmax,kte-1
     do i = its,ite
       if (abs(taud(i,k)) >= qmin .and. prsl(i,k) <= pcutoff) then
         denfac = min(rho(i,k)/pcutoff_den,1.)
         dtfac(i,k) = min(dtfac(i,k),denfac*abs(velco(i,k)                     &
                     /(deltim*taud(i,k))))
       endif
     enddo
   enddo
   dtfac(:,kte) = dtfac(:,kte-1)
!
   do i = its,ite
     dusfc(i) = 0.
     dvsfc(i) = 0.
   enddo
!
   do k = kts,kte
     do i = its,ite
       taud(i,k) = taud(i,k) * dtfac(i,k)
       dtaux = taud(i,k) * xn(i)
       dtauy = taud(i,k) * yn(i)
       dtaux2d(i,k) = dtaux
       dtauy2d(i,k) = dtauy
       dudt(i,k) = dtaux
       dvdt(i,k) = dtauy
       dusfc(i)  = dusfc(i) + dtaux * del(i,k)
       dvsfc(i)  = dvsfc(i) + dtauy * del(i,k)
     enddo
   enddo
!
   do i = its,ite
     dusfc(i) = (-1./g_) * dusfc(i)
     dvsfc(i) = (-1./g_) * dvsfc(i)
   enddo
!
! rotate tendencies from zonal/meridional back to model grid
!
   do k = kts,kte
      do i = its,ite
         rublten(i,k) = rublten(i,k)+dudt(i,k)*cosa(i) + dvdt(i,k)*sina(i)
         rvblten(i,k) = rvblten(i,k)-dudt(i,k)*sina(i) + dvdt(i,k)*cosa(i)
         dtaux3d(i,k) = dtaux2d(i,k)*cosa(i) + dtauy2d(i,k)*sina(i)
         dtauy3d(i,k) =-dtaux2d(i,k)*sina(i) + dtauy2d(i,k)*cosa(i)
     enddo
   enddo
   do i = its,ite
      dusfcg(i) = dusfc(i)*cosa(i) + dvsfc(i)*sina(i)
      dvsfcg(i) =-dusfc(i)*sina(i) + dvsfc(i)*cosa(i)
   enddo
   return
   end subroutine bl_gwdo_run_g
#endif

end module module_bl_gwdo
!=================================================================================================================
