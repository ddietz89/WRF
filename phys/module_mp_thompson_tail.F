!.. Submodule of module_mp_thompson (WRF GPU port): the column tail kernel of mp_gt_driver's THLEV path with its
!.. device routines thom_tail and thom_fin, compiled on its own for a separate register cap (phys/Makefile
!.. THOMPSON_TAIL_REGCAP). Code moved verbatim from module_mp_thompson.F (2026-11-10).
#ifdef WRF_GPU
      SUBMODULE (module_mp_thompson) module_mp_thompson_tail
      implicit none
      CONTAINS

      MODULE SUBROUTINE thom_tail_band( gpu_aer, gpu_wif, gpu_do_refl, gpu_do_re, kediagloc, thb0, thb1, dt,      &
                           qv, qc, qr, qi, qs, qg, ni, nr, th, pii, p, dz,                       &
                           RAINNC, RAINNCV, SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV, SR,            &
                           refl_10cm, re_cloud, re_ice, re_snow, mp_li, mp_lj, nmp,               &
                           ims, ime, jms, jme, kms, kme, kts, kte )
      INTEGER, INTENT(IN):: gpu_aer, gpu_wif, kediagloc, thb0, thb1, nmp
      LOGICAL, INTENT(IN):: gpu_do_refl, gpu_do_re
      REAL, INTENT(IN):: dt
      INTEGER, INTENT(IN):: ims, ime, jms, jme, kms, kme, kts, kte
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: qv, qc, qr, qi, qs, qg, ni, nr, th
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN):: pii, p, dz
      REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT):: RAINNC, RAINNCV, SR
      REAL, DIMENSION(ims:ime, jms:jme), OPTIONAL, INTENT(INOUT):: SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: refl_10cm, re_cloud, re_ice, re_snow
      INTEGER, DIMENSION(nmp), INTENT(IN):: mp_li, mp_lj
      REAL, DIMENSION(1:KTGPU):: &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d,     &
                          ni1d, nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d,&
                          t1d, p1d, w1d, dz1d, rho, dBZ
      REAL, DIMENSION(1:KTGPU):: re_qc1d, re_qi1d, re_qs1d
      REAL:: pptrain, pptsnow, pptgraul, pptice
      INTEGER:: i, j, k, n_, thjj

!$acc parallel loop gang vector present(mp_li, mp_lj) &
!$acc private(qv1d,qc1d,qi1d,qr1d,qs1d,qg1d,qb1d,ni1d,nr1d,nc1d,ng1d,nwfa1d,nifa1d,nbca1d) &
!$acc private(t1d,p1d,w1d,dz1d,rho,re_qc1d,re_qi1d,re_qs1d,dBZ,thjj)
      do n_ = thb0, thb1
         i = mp_li(n_) ; j = mp_lj(n_)
         thjj = 1
         pptrain = 0.
         pptsnow = 0.
         pptgraul = 0.
         pptice = 0.
         ! only p1d and dz1d survive: every other column array is overwritten from the level kernel's hand-off
         ! below (the loads of th/pii/w/qv..nr and the rho/ng1d/qb1d computation were dead, 2026-11-08)
         do k = kts, kte
            p1d(k) = p(i,k,j)
            dz1d(k) = dz(i,k,j)
         enddo
         do k = kts, kte
            qv1d(k) = thb_qv1d(n_-thb0+1,k-kts+1,thjj)
            qc1d(k) = thb_qc1d(n_-thb0+1,k-kts+1,thjj)
            qi1d(k) = thb_qi1d(n_-thb0+1,k-kts+1,thjj)
            qr1d(k) = thb_qr1d(n_-thb0+1,k-kts+1,thjj)
            qs1d(k) = thb_qs1d(n_-thb0+1,k-kts+1,thjj)
            qg1d(k) = thb_qg1d(n_-thb0+1,k-kts+1,thjj)
            qb1d(k) = thb_qb1d(n_-thb0+1,k-kts+1,thjj)
            ni1d(k) = thb_ni1d(n_-thb0+1,k-kts+1,thjj)
            nr1d(k) = thb_nr1d(n_-thb0+1,k-kts+1,thjj)
            nc1d(k) = thb_nc1d(n_-thb0+1,k-kts+1,thjj)
            ng1d(k) = thb_ng1d(n_-thb0+1,k-kts+1,thjj)
            nwfa1d(k) = thb_nwfa1d(n_-thb0+1,k-kts+1,thjj)
            nifa1d(k) = thb_nifa1d(n_-thb0+1,k-kts+1,thjj)
            nbca1d(k) = thb_nbca1d(n_-thb0+1,k-kts+1,thjj)
            t1d(k) = thb_t1d(n_-thb0+1,k-kts+1,thjj)
            w1d(k) = thb_w1d(n_-thb0+1,k-kts+1,thjj)
         enddo
         IF ( .NOT. thb_nmc(n_-thb0+1,thjj) ) THEN
          IF ( thsplit_on == 1 ) THEN
           pptrain = thb_ppt(n_-thb0+1,1) ; pptice = thb_ppt(n_-thb0+1,2)
           pptsnow = thb_ppt(n_-thb0+1,3) ; pptgraul = thb_ppt(n_-thb0+1,4)
           CALL thom_fin(gpu_aer, gpu_wif, &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d, ni1d,     &
                          nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, w1d, dz1d,  &
                      pptrain, pptsnow, pptgraul, pptice, &
                      kts, kte, dt, i, j, n_-thb0+1, thjj)
          ELSE
           CALL thom_tail(gpu_aer, gpu_wif, &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d, ni1d,     &
                          nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, w1d, dz1d,  &
                      pptrain, pptsnow, pptgraul, pptice, &
                      kts, kte, dt, i, j, n_-thb0+1, thjj)
          ENDIF
         ENDIF
         RAINNCV(i,j) = pptrain + pptsnow + pptgraul + pptice
         RAINNC(i,j) = RAINNC(i,j) + pptrain + pptsnow + pptgraul + pptice
         SNOWNCV(i,j) = pptsnow + pptice
         SNOWNC(i,j) = SNOWNC(i,j) + pptsnow + pptice
         GRAUPELNCV(i,j) = pptgraul
         GRAUPELNC(i,j) = GRAUPELNC(i,j) + pptgraul
         SR(i,j) = (pptsnow + pptgraul + pptice)/(RAINNCV(i,j)+1.e-12)
         do k = kts, kte
            qv(i,k,j) = qv1d(k)
            qc(i,k,j) = qc1d(k)
            qi(i,k,j) = qi1d(k)
            qr(i,k,j) = qr1d(k)
            qs(i,k,j) = qs1d(k)
            qg(i,k,j) = qg1d(k)
            ni(i,k,j) = ni1d(k)
            nr(i,k,j) = nr1d(k)
            th(i,k,j) = t1d(k)/pii(i,k,j)
            if (qv1d(k) .lt. 0.0) then
             if (k.lt.kte-2 .and. k.gt.kts+1) then
                qv(i,k,j) = MAX(1.E-7, 0.5*(qv(i,k-1,j) + qv(i,k+1,j)))
             else
                qv(i,k,j) = 1.E-7
             endif
            endif
         enddo
         IF ( gpu_do_refl ) THEN
          call thtl_refl10cm (qv1d, qc1d, qr1d, nr1d, qs1d, qg1d,       &
                      ng1d, qb1d, t1d, p1d, dBZ, kts, kte, i, j, kediagloc)
          do k = kts, kte
             refl_10cm(i,k,j) = MAX(-35., dBZ(k))
          enddo
         ENDIF
         IF ( gpu_do_re .AND. th_probe /= 5 ) THEN
          do k = kts, kte
             re_qc1d(k) = RE_QC_BG
             re_qi1d(k) = RE_QI_BG
             re_qs1d(k) = RE_QS_BG
          enddo
          call thtl_effectRad (t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d,  &
                      re_qc1d, re_qi1d, re_qs1d, kts, kte)
          do k = kts, kte
             re_cloud(i,k,j) = MAX(RE_QC_BG, MIN(re_qc1d(k), 50.E-6))
             re_ice(i,k,j)   = MAX(RE_QI_BG, MIN(re_qi1d(k), 125.E-6))
             re_snow(i,k,j)  = MAX(RE_QS_BG, MIN(re_qs1d(k), 999.E-6))
          enddo
         ENDIF
      enddo
      END SUBROUTINE thom_tail_band

      subroutine thom_tail(aer_init_opt, wif_input_opt, qv1d, qc1d, qi1d, qr1d, &
                          qs1d, qg1d, qb1d, ni1d, nr1d, nc1d, &
                          ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, &
                          w1d, dzq, pptrain, pptsnow, pptgraul, pptice, &
                          kts, kte, dt, ii, jj, thic, &
                          thjjb)
!$acc routine seq
      implicit none
      INTEGER, INTENT(IN):: aer_init_opt
      INTEGER, INTENT(IN):: wif_input_opt
      INTEGER, INTENT(IN):: kts
      INTEGER, INTENT(IN):: kte
      INTEGER, INTENT(IN):: ii
      INTEGER, INTENT(IN):: jj
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qv1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qc1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qi1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qr1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qs1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qg1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qb1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: ni1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nr1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nc1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: ng1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nwfa1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nifa1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nbca1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: t1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: p1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: w1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: dzq
      REAL, INTENT(INOUT):: pptrain
      REAL, INTENT(INOUT):: pptsnow
      REAL, INTENT(INOUT):: pptgraul
      REAL, INTENT(INOUT):: pptice
      REAL, INTENT(IN):: dt
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prw_vcd
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_wcd
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_wau
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_rcw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_scw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_gcw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pna_rca
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pna_sca
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pna_gca
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnd_rcd
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnd_scd
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnd_gcd
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnb_rcb
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnb_scb
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnb_gcb
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_wau
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_rcw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_rcg
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_gml
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prv_rev
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_wau
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rcg
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_sml
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_gml
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rev
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rcr
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnr_rfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_inu
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_inu
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_ihm
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_ihm
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_wfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_wfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_rfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_rfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_ide
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_ide
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_sci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_iau
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_iha
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pni_iha
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_iau
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_sci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_scw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_sde
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_ihm
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_ide
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_scw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_rfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_gde
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_gcw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_rcg
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_ihm
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: png_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: png_rcg
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: png_scw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: png_gde
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_scw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_rfz
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_gcw
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_rci
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_rcs
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_rcg
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_sml
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pbg_gml
      DOUBLE PRECISION, PARAMETER:: zerod0 = 0.0d0
      DOUBLE PRECISION:: pnc_wau_s
      DOUBLE PRECISION:: pnc_rcw_s
      DOUBLE PRECISION:: pnc_scw_s
      DOUBLE PRECISION:: pnc_gcw_s
      DOUBLE PRECISION:: prr_rcs_s
      DOUBLE PRECISION:: prr_rcg_s
      DOUBLE PRECISION:: prr_rci_s
      DOUBLE PRECISION:: pnr_wau_s
      DOUBLE PRECISION:: pnr_rcs_s
      DOUBLE PRECISION:: pnr_rcg_s
      DOUBLE PRECISION:: pnr_rci_s
      DOUBLE PRECISION:: pnr_sml_s
      DOUBLE PRECISION:: pnr_gml_s
      DOUBLE PRECISION:: pnr_rcr_s
      DOUBLE PRECISION:: pnr_rfz_s
      DOUBLE PRECISION:: pri_inu_s
      DOUBLE PRECISION:: pni_inu_s
      DOUBLE PRECISION:: pri_ihm_s
      DOUBLE PRECISION:: pni_ihm_s
      DOUBLE PRECISION:: pri_wfz_s
      DOUBLE PRECISION:: pni_wfz_s
      DOUBLE PRECISION:: pri_rfz_s
      DOUBLE PRECISION:: pni_rfz_s
      DOUBLE PRECISION:: pri_ide_s
      DOUBLE PRECISION:: pni_ide_s
      DOUBLE PRECISION:: pni_rci_s
      DOUBLE PRECISION:: pni_sci_s
      DOUBLE PRECISION:: pni_iau_s
      DOUBLE PRECISION:: pri_iha_s
      DOUBLE PRECISION:: pni_iha_s
      DOUBLE PRECISION:: prs_rcs_s
      DOUBLE PRECISION:: prs_ihm_s
      DOUBLE PRECISION:: prs_ide_s
      DOUBLE PRECISION:: prg_rfz_s
      DOUBLE PRECISION:: prg_rci_s
      DOUBLE PRECISION:: prg_rcs_s
      DOUBLE PRECISION:: prg_rcg_s
      DOUBLE PRECISION:: prg_ihm_s
      DOUBLE PRECISION:: png_scw_s
      DOUBLE PRECISION:: png_rcs_s
      DOUBLE PRECISION:: png_rcg_s
      DOUBLE PRECISION:: png_gde_s
      DOUBLE PRECISION:: pbg_scw_s
      DOUBLE PRECISION:: pbg_rfz_s
      DOUBLE PRECISION:: pbg_gcw_s
      DOUBLE PRECISION:: pbg_rci_s
      DOUBLE PRECISION:: pbg_rcs_s
      DOUBLE PRECISION:: pbg_rcg_s
      DOUBLE PRECISION:: pbg_sml_s
      DOUBLE PRECISION:: pbg_gml_s
      DOUBLE PRECISION:: pna_rca_s
      DOUBLE PRECISION:: pna_sca_s
      DOUBLE PRECISION:: pna_gca_s
      DOUBLE PRECISION:: pnd_rcd_s
      DOUBLE PRECISION:: pnd_scd_s
      DOUBLE PRECISION:: pnd_gcd_s
      DOUBLE PRECISION:: pnb_rcb_s
      DOUBLE PRECISION:: pnb_scb_s
      DOUBLE PRECISION:: pnb_gcb_s
      REAL, DIMENSION(1:KTGPU):: twet
      REAL, DIMENSION(1:KTGPU):: pres
      REAL, DIMENSION(1:KTGPU):: qv
      REAL, DIMENSION(1:KTGPU):: ns
      REAL, DIMENSION(1:KTGPU):: nwfa
      REAL, DIMENSION(1:KTGPU):: nifa
      REAL, DIMENSION(1:KTGPU):: nbca
      REAL, DIMENSION(1:KTGPU):: rhof2
      REAL, DIMENSION(1:KTGPU):: qvs
      REAL, DIMENSION(1:KTGPU):: qvsi
      REAL, DIMENSION(1:KTGPU):: delqvs
      REAL, DIMENSION(1:KTGPU):: satw
      REAL, DIMENSION(1:KTGPU):: sati
      REAL, DIMENSION(1:KTGPU):: ssatw
      REAL, DIMENSION(1:KTGPU):: ssati
      REAL, DIMENSION(1:KTGPU):: diffu
      REAL, DIMENSION(1:KTGPU):: vsc2
      REAL, DIMENSION(1:KTGPU):: tcond
      REAL, DIMENSION(1:KTGPU):: lvt2
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: ilamr
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: n0_r
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: n0_g
      DOUBLE PRECISION:: n0_melt
      REAL, DIMENSION(1:KTGPU):: mvd_c
      REAL, DIMENSION(1:KTGPU):: smo2
      REAL, DIMENSION(1:KTGPU):: smo1
      REAL, DIMENSION(1:KTGPU):: smo0
      REAL, DIMENSION(1:KTGPU):: smod
      REAL, DIMENSION(1:KTGPU):: smoe
      REAL, DIMENSION(1:KTGPU):: smof
      REAL, DIMENSION(1:KTGPU):: smog
      REAL, DIMENSION(1:KTGPU):: sed_r
      REAL, DIMENSION(1:KTGPU):: sed_s
      REAL, DIMENSION(1:KTGPU):: sed_g
      REAL, DIMENSION(1:KTGPU):: sed_i
      REAL, DIMENSION(1:KTGPU):: sed_n
      REAL, DIMENSION(1:KTGPU):: sed_c
      REAL, DIMENSION(1:KTGPU):: sed_b
      REAL:: rgvm
      REAL:: delta_tp
      REAL:: orho
      REAL:: lfus2
      REAL, DIMENSION(5):: onstep
      DOUBLE PRECISION:: n0_exp
      DOUBLE PRECISION:: n0_min
      DOUBLE PRECISION:: lam_exp
      DOUBLE PRECISION:: lamc
      DOUBLE PRECISION:: lamr
      DOUBLE PRECISION:: lamg
      DOUBLE PRECISION:: lami
      DOUBLE PRECISION:: ilami
      DOUBLE PRECISION:: ilamc
      REAL:: xdc
      REAL:: dc_b
      REAL:: dc_g
      REAL:: xdi
      REAL:: xdr
      REAL:: xds
      REAL:: xdg
      REAL:: ds_m
      REAL:: dg_m
      DOUBLE PRECISION:: dr_star
      DOUBLE PRECISION:: dc_star
      REAL:: zeta1
      REAL:: zeta
      REAL:: taud
      REAL:: tau
      REAL:: stoke_r
      REAL:: stoke_s
      REAL:: stoke_g
      REAL:: stoke_i
      REAL:: vti
      REAL:: vtr
      REAL:: vts
      REAL:: vtg
      REAL:: vtc
      REAL:: xrho_g
      REAL:: afall
      REAL:: vtg1
      REAL:: vtg2
      REAL:: bfall
      REAL, DIMENSION(1:KTGPU+1):: vtik
      REAL, DIMENSION(1:KTGPU+1):: vtnik
      REAL, DIMENSION(1:KTGPU+1):: vtrk
      REAL, DIMENSION(1:KTGPU+1):: vtnrk
      REAL, DIMENSION(1:KTGPU+1):: vtsk
      REAL, DIMENSION(1:KTGPU+1):: vtgk
      REAL, DIMENSION(1:KTGPU+1):: vtngk
      REAL, DIMENSION(1:KTGPU+1):: vtck
      REAL, DIMENSION(1:KTGPU+1):: vtnck
      REAL:: m0
      REAL:: slam1
      REAL:: slam2
      REAL:: mrat
      REAL:: ils1
      REAL:: ils2
      REAL:: t1_vts
      REAL:: t2_vts
      REAL:: t3_vts
      REAL:: t4_vts
      REAL:: c_snow
      REAL:: a_
      REAL:: b_
      REAL:: loga_
      REAL:: a1
      REAL:: a2
      REAL:: tf
      REAL:: tempc
      REAL:: tc0
      REAL:: r_mvd1
      REAL:: r_mvd2
      REAL:: xkrat
      REAL:: dew_t
      REAL:: tlcl
      REAL:: the
      REAL:: twet_k
      REAL:: tempc_s
      REAL:: rhof_s
      REAL:: rhof2_s
      REAL:: qvs_s
      REAL:: delqvs_s
      REAL:: qvsi_s
      REAL:: satw_s
      REAL:: sati_s
      REAL:: ssatw_s
      REAL:: ssati_s
      REAL:: diffu_s
      REAL:: visco_s
      REAL:: ocp_s
      REAL:: vsc2_s
      REAL:: lvap_s
      REAL:: tcond_s
      REAL:: xnc
      REAL:: xri
      REAL:: xni
      REAL:: xmi
      REAL:: oxmi
      REAL:: xrc
      REAL:: xrr
      REAL:: xnr
      REAL:: xrg
      REAL:: xng
      REAL:: xrb
      REAL:: xsat
      REAL:: rate_max
      REAL:: sump
      REAL:: ratio
      REAL:: clap
      REAL:: fcd
      REAL:: dfcd
      REAL:: otemp
      REAL:: rvs
      REAL:: rvs_p
      REAL:: rvs_pp
      REAL:: gamsc
      REAL:: alphsc
      REAL:: t1_evap
      REAL:: t1_subl
      REAL:: r_frac
      REAL:: g_frac
      REAL:: const_ri
      REAL:: rime_dens
      REAL:: ef_rw
      REAL:: ef_sw
      REAL:: ef_gw
      REAL:: ef_rr
      REAL:: ef_ra
      REAL:: ef_sa
      REAL:: ef_ga
      REAL:: dtsave
      REAL:: odts
      REAL:: odt
      REAL:: odzq
      REAL:: hgt_agl
      REAL:: xslw1
      REAL:: ygra1
      REAL:: zans1
      REAL:: eva_factor
      REAL:: sr
      REAL:: melt_f
      INTEGER:: i
      INTEGER:: k
      INTEGER:: k2
      INTEGER:: n
      INTEGER:: nn
      INTEGER:: nstep
      INTEGER:: k_0
      INTEGER:: kbot
      INTEGER:: it
      INTEGER:: iexfrq
      INTEGER:: k_melting
      INTEGER, DIMENSION(5):: ksed1
      INTEGER:: nir
      INTEGER:: nis
      INTEGER:: nig
      INTEGER:: nii
      INTEGER:: nic
      INTEGER:: niin
      INTEGER:: idx_tc
      INTEGER:: idx_t
      INTEGER:: idx_s
      INTEGER:: idx_g1
      INTEGER:: idx_g
      INTEGER:: idx_r1
      INTEGER:: idx_r
      INTEGER:: idx_i1
      INTEGER:: idx_i
      INTEGER:: idx_c
      INTEGER:: idx
      INTEGER:: idx_d
      INTEGER:: idx_n
      INTEGER:: idx_in
      LOGICAL:: melti
      LOGICAL:: no_micro
      LOGICAL:: debug_flag
      CHARACTER*256:: mp_debug
      INTEGER:: nu_c
      INTEGER, INTENT(IN):: thic, thjjb
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1
      nstep = 0
      onstep(:) = 1.0
      ksed1(:) = 1
      do k = kte+1, kts, -1
         vtrk(k) = 0.
         vtnrk(k) = 0.
         vtik(k) = 0.
         vtnik(k) = 0.
         vtsk(k) = 0.
         vtgk(k) = 0.
         vtngk(k) = 0.
         vtck(k) = 0.
         vtnck(k) = 0.
      enddo

      if (ANY(thb_l_qr(thic,kts:kte,thjjb))) then
      do k = kte, kts, -1
         vtr = 0.
         thb_rhof(thic,k,thjjb) = SQRT(RHO_NOT/thb_rho(thic,k,thjjb))

         if (thb_rr(thic,k,thjjb).gt. R1) then
          lamr = (am_r*crg(3)*org2*thb_nr(thic,k,thjjb)/thb_rr(thic,k,thjjb))**obmr
          vtr = thb_rhof(thic,k,thjjb)*av_r*crg(6)*org3 * lamr**cre(3)                 &
                      *((lamr+fv_r)**(-cre(6)))
          vtrk(k) = vtr





          vtr = thb_rhof(thic,k,thjjb)*av_r*crg(7)/crg(12) * lamr**cre(12)             &
                      *((lamr+fv_r)**(-cre(7)))
          vtnrk(k) = vtr
         else
          vtrk(k) = vtrk(k+1)
          vtnrk(k) = vtnrk(k+1)
         endif

         if (MAX(vtrk(k),vtnrk(k)) .gt. 1.E-3) then
            ksed1(1) = MAX(ksed1(1), k)
            delta_tp = dzq(k)/(MAX(vtrk(k),vtnrk(k)))
            nstep = MAX(nstep, INT(DT/delta_tp + 1.))
         endif
      enddo
      if (ksed1(1) .eq. kte) ksed1(1) = kte-1
      if (nstep .gt. 0) onstep(1) = 1./REAL(nstep)
      endif



      if (ANY(thb_l_qc(thic,kts:kte,thjjb))) then
      hgt_agl = 0.
      do k = kts, kte-1
         if (thb_rc(thic,k,thjjb) .gt. R2) ksed1(5) = k
         hgt_agl = hgt_agl + dzq(k)
         if (hgt_agl .gt. 500.0) goto 151
      enddo
 151  continue

      do k = ksed1(5), kts, -1
         vtc = 0.
         if (thb_rc(thic,k,thjjb) .gt. R1 .and. w1d(k) .lt. 1.E-1) then
          nu_c = MIN(15, NINT(1000.E6/thb_nc(thic,k,thjjb)) + 2)
          lamc = (thb_nc(thic,k,thjjb)*am_r*ccg(2,nu_c)*ocg1(nu_c)/thb_rc(thic,k,thjjb))**obmr
          ilamc = 1./lamc
          vtc = thb_rhof(thic,k,thjjb)*av_c*ccg(5,nu_c)*ocg2(nu_c) * ilamc**bv_c
          vtck(k) = vtc
          vtc = thb_rhof(thic,k,thjjb)*av_c*ccg(4,nu_c)*ocg1(nu_c) * ilamc**bv_c
          vtnck(k) = vtc
         endif
      enddo
      endif



      if (.not. iiwarm) then

       if (ANY(thb_l_qi(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vti = 0.

          if (thb_ri(thic,k,thjjb).gt. R1) then
           lami = (am_i*cig(2)*oig1*thb_ni(thic,k,thjjb)/thb_ri(thic,k,thjjb))**obmi
           ilami = 1./lami
           vti = thb_rhof(thic,k,thjjb)*av_i*cig(3)*oig2 * ilami**bv_i
           vtik(k) = vti



           vti = thb_rhof(thic,k,thjjb)*av_i*cig(6)/cig(7) * ilami**bv_i
           vtnik(k) = vti
          else
           vtik(k) = vtik(k+1)
           vtnik(k) = vtnik(k+1)
          endif

          if (vtik(k) .gt. 1.E-3) then
             ksed1(2) = MAX(ksed1(2), k)
             delta_tp = dzq(k)/vtik(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(2) .eq. kte) ksed1(2) = kte-1
       if (nstep .gt. 0) onstep(2) = 1./REAL(nstep)
       endif



       if (ANY(thb_l_qs(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vts = 0.

          if (thb_rs(thic,k,thjjb).gt. R1) then
           xDs = thb_smoc(thic,k,thjjb) / thb_smob(thic,k,thjjb)
           Mrat = 1./xDs
           ils1 = 1./(Mrat*Lam0 + fv_s)
           ils2 = 1./(Mrat*Lam1 + fv_s)
           t1_vts = Kap0*csg(4)*ils1**cse(4)
           t2_vts = Kap1*Mrat**mu_s*csg(10)*ils2**cse(10)
           ils1 = 1./(Mrat*Lam0)
           ils2 = 1./(Mrat*Lam1)
           t3_vts = Kap0*csg(1)*ils1**cse(1)
           t4_vts = Kap1*Mrat**mu_s*csg(7)*ils2**cse(7)
           vts = thb_rhof(thic,k,thjjb)*av_s * (t1_vts+t2_vts)/(t3_vts+t4_vts)
           if (thb_prr_sml(thic,k,thjjb) .gt. 0.0) then 
            SR = thb_rs(thic,k,thjjb)/(thb_rs(thic,k,thjjb)+thb_rr(thic,k,thjjb))
            vtsk(k) = vts*SR + (1.-SR)*vtrk(k)
           else
            vtsk(k) = vts*thb_vts_boost(thic,k,thjjb)
           endif
          else
            vtsk(k) = vtsk(k+1)
          endif

          if (vtsk(k) .gt. 1.E-3) then
             ksed1(3) = MAX(ksed1(3), k)
             delta_tp = dzq(k)/vtsk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(3) .eq. kte) ksed1(3) = kte-1
       if (nstep .gt. 0) onstep(3) = 1./REAL(nstep)
       endif



       if (ANY(thb_l_qg(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vtg = 0.

          if (thb_rg(thic,k,thjjb).gt. R1) then
           if (is_hail_aware) then
              xrho_g = MAX(rho_g(1),MIN(thb_rg(thic,k,thjjb)/thb_rho(thic,k,thjjb)/thb_rb(thic,k,thjjb),rho_g(NRHG)))
              afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*thb_rho(thic,k,thjjb)))**b_coeff
              afall = afall * thb_visco(thic,k,thjjb)**(1.0-2.0*b_coeff)
           else
              afall = av_g_old
              bfall = bv_g_old
           endif
           vtg = thb_rhof(thic,k,thjjb)*afall*cgg(6,thb_idx_bg(thic,k,thjjb))*ogg3 * thb_ilamg(thic,k,thjjb)**bfall
            vtgk(k) = vtg


           if (mu_g .eq. 0) then
              vtg = thb_rhof(thic,k,thjjb)*afall*cgg(7,thb_idx_bg(thic,k,thjjb))/cgg(12,thb_idx_bg(thic,k,thjjb)) * thb_ilamg(thic,k,thjjb)**bfall
           else
              vtg = thb_rhof(thic,k,thjjb)*afall*cgg(8,thb_idx_bg(thic,k,thjjb))*ogg2 * thb_ilamg(thic,k,thjjb)**bfall
           endif
           vtngk(k) = vtg
          else
            vtgk(k) = vtgk(k+1)
           vtngk(k) = vtngk(k+1)
          endif

          if (vtgk(k) .gt. 1.E-3) then
             ksed1(4) = MAX(ksed1(4), k)
             delta_tp = dzq(k)/vtgk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(4) .eq. kte) ksed1(4) = kte-1
       if (nstep .gt. 0) onstep(4) = 1./REAL(nstep)
       endif
      endif







      if (ANY(thb_l_qr(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(1))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_r(k) = vtrk(k)*thb_rr(thic,k,thjjb)
            sed_n(k) = vtnrk(k)*thb_nr(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qrten(thic,k,thjjb) = thb_qrten(thic,k,thjjb) - sed_r(k)*odzq*onstep(1)*orho
         thb_nrten(thic,k,thjjb) = thb_nrten(thic,k,thjjb) - sed_n(k)*odzq*onstep(1)*orho
         thb_rr(thic,k,thjjb) = MAX(R1, thb_rr(thic,k,thjjb) - sed_r(k)*odzq*DT*onstep(1))
         thb_nr(thic,k,thjjb) = MAX(R2, thb_nr(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(1))
         do k = ksed1(1), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qrten(thic,k,thjjb) = thb_qrten(thic,k,thjjb) + (sed_r(k+1)-sed_r(k))                 &
                                               *odzq*onstep(1)*orho
            thb_nrten(thic,k,thjjb) = thb_nrten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(1)*orho
            thb_rr(thic,k,thjjb) = MAX(R1, thb_rr(thic,k,thjjb) + (sed_r(k+1)-sed_r(k)) &
                                           *odzq*DT*onstep(1))
            thb_nr(thic,k,thjjb) = MAX(R2, thb_nr(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(1))
         enddo

         if (thb_rr(thic,kts,thjjb).gt.R1*1000.) &
         pptrain = pptrain + sed_r(kts)*DT*onstep(1)
      enddo
      endif



      if (ANY(thb_l_qc(thic,kts:kte,thjjb))) then
      do k = kte, kts, -1
         sed_c(k) = vtck(k)*thb_rc(thic,k,thjjb)
         sed_n(k) = vtnck(k)*thb_nc(thic,k,thjjb)
      enddo
      do k = ksed1(5), kts, -1
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) + (sed_c(k+1)-sed_c(k)) *odzq*orho
         thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) *odzq*orho
         thb_rc(thic,k,thjjb) = MAX(R1, thb_rc(thic,k,thjjb) + (sed_c(k+1)-sed_c(k)) *odzq*DT)
         thb_nc(thic,k,thjjb) = MAX(10., thb_nc(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) *odzq*DT)
      enddo
      endif



      if (ANY(thb_l_qi(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(2))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_i(k) = vtik(k)*thb_ri(thic,k,thjjb)
            sed_n(k) = vtnik(k)*thb_ni(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) - sed_i(k)*odzq*onstep(2)*orho
         thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) - sed_n(k)*odzq*onstep(2)*orho
         thb_ri(thic,k,thjjb) = MAX(R1, thb_ri(thic,k,thjjb) - sed_i(k)*odzq*DT*onstep(2))
         thb_ni(thic,k,thjjb) = MAX(R2, thb_ni(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(2))
         do k = ksed1(2), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) + (sed_i(k+1)-sed_i(k))                 &
                                               *odzq*onstep(2)*orho
            thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(2)*orho
            thb_ri(thic,k,thjjb) = MAX(R1, thb_ri(thic,k,thjjb) + (sed_i(k+1)-sed_i(k)) &
                                           *odzq*DT*onstep(2))
            thb_ni(thic,k,thjjb) = MAX(R2, thb_ni(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(2))
         enddo

         if (thb_ri(thic,kts,thjjb).gt.R1*1000.) &
         pptice = pptice + sed_i(kts)*DT*onstep(2)
      enddo
      endif



      if (ANY(thb_l_qs(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(3))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_s(k) = vtsk(k)*thb_rs(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qsten(thic,k,thjjb) = thb_qsten(thic,k,thjjb) - sed_s(k)*odzq*onstep(3)*orho
         thb_rs(thic,k,thjjb) = MAX(R1, thb_rs(thic,k,thjjb) - sed_s(k)*odzq*DT*onstep(3))
         do k = ksed1(3), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qsten(thic,k,thjjb) = thb_qsten(thic,k,thjjb) + (sed_s(k+1)-sed_s(k))                 &
                                               *odzq*onstep(3)*orho
            thb_rs(thic,k,thjjb) = MAX(R1, thb_rs(thic,k,thjjb) + (sed_s(k+1)-sed_s(k)) &
                                           *odzq*DT*onstep(3))
         enddo

         if (thb_rs(thic,kts,thjjb).gt.R1*1000.) &
         pptsnow = pptsnow + sed_s(kts)*DT*onstep(3)
      enddo
      endif



      if (ANY(thb_l_qg(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(4))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_g(k) = vtgk(k)*thb_rg(thic,k,thjjb)
            sed_n(k) = vtngk(k)*thb_ng(thic,k,thjjb)
            sed_b(k) = vtgk(k)*thb_rb(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qgten(thic,k,thjjb) = thb_qgten(thic,k,thjjb) - sed_g(k)*odzq*onstep(4)*orho
         thb_ngten(thic,k,thjjb) = thb_ngten(thic,k,thjjb) - sed_n(k)*odzq*onstep(4)*orho
         thb_qbten(thic,k,thjjb) = thb_qbten(thic,k,thjjb) - sed_b(k)*odzq*onstep(4)
         thb_rg(thic,k,thjjb) = MAX(R1, thb_rg(thic,k,thjjb) - sed_g(k)*odzq*DT*onstep(4))
         thb_ng(thic,k,thjjb) = MAX(R2, thb_ng(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(4))
         thb_rb(thic,k,thjjb) = MAX(R1/thb_rho(thic,k,thjjb)/rho_g(NRHG), thb_rb(thic,k,thjjb) - sed_b(k)*odzq*DT*onstep(4))
         do k = ksed1(4), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qgten(thic,k,thjjb) = thb_qgten(thic,k,thjjb) + (sed_g(k+1)-sed_g(k))                 &
                                               *odzq*onstep(4)*orho
            thb_ngten(thic,k,thjjb) = thb_ngten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(4)*orho
            thb_qbten(thic,k,thjjb) = thb_qbten(thic,k,thjjb) + (sed_b(k+1)-sed_b(k))                 &
                                               *odzq*onstep(4)
            thb_rg(thic,k,thjjb) = MAX(R1, thb_rg(thic,k,thjjb) + (sed_g(k+1)-sed_g(k)) &
                                           *odzq*DT*onstep(4))
            thb_ng(thic,k,thjjb) = MAX(R2, thb_ng(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(4))
            thb_rb(thic,k,thjjb) = MAX(thb_rg(thic,k,thjjb)/thb_rho(thic,k,thjjb)/rho_g(NRHG), thb_rb(thic,k,thjjb) + (sed_b(k+1)-sed_b(k))  &
                                           *odzq*DT*onstep(4))
         enddo

         if (thb_rg(thic,kts,thjjb).gt.R1*1000.) &
         pptgraul = pptgraul + sed_g(kts)*DT*onstep(4)
      enddo
      endif





      if (.not. iiwarm) then
      do k = kts, kte
         xri = MAX(0.0, qi1d(k) + thb_qiten(thic,k,thjjb)*DT)
         if ( (thb_temp(thic,k,thjjb).gt. T_0) .and. (xri.gt. 0.0) ) then
          thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) + xri*odt
          thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) + ni1d(k)*odt
          thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) - xri*odt
          thb_niten(thic,k,thjjb) = -ni1d(k)*odt
          thb_tten(thic,k,thjjb) = thb_tten(thic,k,thjjb) - lfus*thb_ocp(thic,k,thjjb)*xri*odt*(1-IFDRY)
         endif

         xrc = MAX(0.0, qc1d(k) + thb_qcten(thic,k,thjjb)*DT)
         if ( (thb_temp(thic,k,thjjb).lt. HGFR) .and. (xrc.gt. 0.0) ) then
          lfus2 = lsub - thb_lvap(thic,k,thjjb)
          xnc = nc1d(k) + thb_ncten(thic,k,thjjb)*DT
          thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) + xrc*odt
          thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) + xnc*odt
          thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) - xrc*odt
          thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) - xnc*odt
          thb_tten(thic,k,thjjb) = thb_tten(thic,k,thjjb) + lfus2*thb_ocp(thic,k,thjjb)*xrc*odt*(1-IFDRY)
         endif
      enddo
      endif




      do k = kts, kte
         t1d(k)  = t1d(k) + thb_tten(thic,k,thjjb)*DT
         qv1d(k) = MAX(1.E-10, qv1d(k) + thb_qvten(thic,k,thjjb)*DT)
         qc1d(k) = qc1d(k) + thb_qcten(thic,k,thjjb)*DT
         nc1d(k) = MAX(2./thb_rho(thic,k,thjjb), MIN(nc1d(k) + thb_ncten(thic,k,thjjb)*DT, Nt_c_max))
         if (is_aerosol_aware) then
            if (aer_init_opt .lt. 2) then
               nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                             (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT)))
               nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                             (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT)))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                        &
                                (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT)))
               else
                  nbca1d(k) = 0.0
               endif
            else
               nwfa1d(k) = MAX(0.0, (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT))
               nifa1d(k) = MAX(0.0, (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(0.0, (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT))
               else
                  nbca1d(k) = 0.0
               endif
            endif
         else
            nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                          (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT)))
            nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                          (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT)))
            nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                           &
                          (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT)))
         endif

         if (qc1d(k) .le. R1) then
           qc1d(k) = 0.0
           nc1d(k) = 0.0
         else
           nu_c = MIN(15, NINT(1000.E6/(nc1d(k)*thb_rho(thic,k,thjjb))) + 2)
           lamc = (am_r*ccg(2,nu_c)*ocg1(nu_c)*nc1d(k)/qc1d(k))**obmr
           xDc = (bm_r + nu_c + 1.) / lamc
           if (xDc.lt. D0c) then
            lamc = cce(2,nu_c)/D0c
           elseif (xDc.gt. D0r*2.) then
            lamc = cce(2,nu_c)/(D0r*2.)
           endif
           nc1d(k) = MIN(ccg(1,nu_c)*ocg2(nu_c)*qc1d(k)/am_r*lamc**bm_r,&
                         DBLE(Nt_c_max)/thb_rho(thic,k,thjjb))
         endif

         qi1d(k) = qi1d(k) + thb_qiten(thic,k,thjjb)*DT
         ni1d(k) = MAX(R2/thb_rho(thic,k,thjjb), ni1d(k) + thb_niten(thic,k,thjjb)*DT)
         if (qi1d(k) .le. R1) then
           qi1d(k) = 0.0
           ni1d(k) = 0.0
         else
           lami = (am_i*cig(2)*oig1*ni1d(k)/qi1d(k))**obmi
           ilami = 1./lami
           xDi = (bm_i + mu_i + 1.) * ilami
           if (xDi.lt. 5.E-6) then
            lami = cie(2)/5.E-6
           elseif (xDi.gt. 300.E-6) then
            lami = cie(2)/300.E-6
           endif
           ni1d(k) = MIN(cig(1)*oig2*qi1d(k)/am_i*lami**bm_i,           &
                         999.D3/thb_rho(thic,k,thjjb))
         endif
         qr1d(k) = qr1d(k) + thb_qrten(thic,k,thjjb)*DT
         nr1d(k) = MAX(R2/thb_rho(thic,k,thjjb), nr1d(k) + thb_nrten(thic,k,thjjb)*DT)
         if (qr1d(k) .le. R1) then
           qr1d(k) = 0.0
           nr1d(k) = 0.0
         else
           lamr = (am_r*crg(3)*org2*nr1d(k)/qr1d(k))**obmr
           thb_mvd_r(thic,k,thjjb) = (3.0 + mu_r + 0.672) / lamr
           if (thb_mvd_r(thic,k,thjjb) .gt. 2.5E-3) then
              thb_mvd_r(thic,k,thjjb) = 2.5E-3
           elseif (thb_mvd_r(thic,k,thjjb) .lt. D0r*0.75) then
              thb_mvd_r(thic,k,thjjb) = D0r*0.75
           endif
           lamr = (3.0 + mu_r + 0.672) / thb_mvd_r(thic,k,thjjb)
           nr1d(k) = crg(2)*org3*qr1d(k)*lamr**bm_r / am_r
         endif
         qs1d(k) = qs1d(k) + thb_qsten(thic,k,thjjb)*DT
         if (qs1d(k) .le. R1) qs1d(k) = 0.0
         qg1d(k) = qg1d(k) + thb_qgten(thic,k,thjjb)*DT
         ng1d(k) = MAX(R2/thb_rho(thic,k,thjjb), ng1d(k) + thb_ngten(thic,k,thjjb)*DT)
         if (qg1d(k) .le. R1) then
           qg1d(k) = 0.0
           ng1d(k) = 0.0
           qb1d(k) = 0.0
         else
           qb1d(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k) + thb_qbten(thic,k,thjjb)*DT)
           qb1d(k) = MIN(qg1d(k)/rho_g(1), qb1d(k))
           thb_idx_bg(thic,k,thjjb) = MAX(1,MIN(NINT(qg1d(k)/qb1d(k) *0.01)+1,NRHG))
           if (.not. is_hail_aware) thb_idx_bg(thic,k,thjjb) = idx_bg1
           lamg = (am_g(thb_idx_bg(thic,k,thjjb))*cgg(3,1)*ogg2*ng1d(k)/qg1d(k))**obmg
           thb_mvd_g(thic,k,thjjb) = (3.0 + mu_g + 0.672) / lamg
           if (thb_mvd_g(thic,k,thjjb) .gt. 25.4E-3) then
              thb_mvd_g(thic,k,thjjb) = 25.4E-3
           elseif (thb_mvd_g(thic,k,thjjb) .lt. D0r) then
              thb_mvd_g(thic,k,thjjb) = D0r
           endif
           lamg = (3.0 + mu_g + 0.672) / thb_mvd_g(thic,k,thjjb)
           ng1d(k) = cgg(2,1)*ogg3*qg1d(k)*lamg**bm_g / am_g(thb_idx_bg(thic,k,thjjb))
         endif

      enddo

      end subroutine thom_tail

      subroutine thom_fin(aer_init_opt, wif_input_opt, qv1d, qc1d, qi1d, qr1d, &
                          qs1d, qg1d, qb1d, ni1d, nr1d, nc1d, &
                          ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, &
                          w1d, dzq, pptrain, pptsnow, pptgraul, pptice, &
                          kts, kte, dt, ii, jj, thic, &
                          thjjb)
!$acc routine seq
      implicit none
      INTEGER, INTENT(IN):: aer_init_opt
      INTEGER, INTENT(IN):: wif_input_opt
      INTEGER, INTENT(IN):: kts
      INTEGER, INTENT(IN):: kte
      INTEGER, INTENT(IN):: ii
      INTEGER, INTENT(IN):: jj
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qv1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qc1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qi1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qr1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qs1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qg1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qb1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: ni1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nr1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nc1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: ng1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nwfa1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nifa1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: nbca1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: t1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: p1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: w1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: dzq
      REAL, INTENT(INOUT):: pptrain
      REAL, INTENT(INOUT):: pptsnow
      REAL, INTENT(INOUT):: pptgraul
      REAL, INTENT(INOUT):: pptice
      REAL, INTENT(IN):: dt
      REAL:: lfus2
      REAL, DIMENSION(5):: onstep
      DOUBLE PRECISION:: lamc
      DOUBLE PRECISION:: lamr
      DOUBLE PRECISION:: lamg
      DOUBLE PRECISION:: lami
      DOUBLE PRECISION:: ilami
      REAL:: xdc
      REAL:: xdi
      REAL:: the
      REAL:: xnc
      REAL:: xri
      REAL:: xrc
      REAL:: dtsave
      REAL:: odts
      REAL:: odt
      INTEGER:: k
      INTEGER:: nstep
      INTEGER:: iexfrq
      INTEGER, DIMENSION(5):: ksed1
      INTEGER:: nu_c
      INTEGER, INTENT(IN):: thic, thjjb
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1
      nstep = 0
      onstep(:) = 1.0
      ksed1(:) = 1
      if (.not. iiwarm) then
      do k = kts, kte
         xri = MAX(0.0, qi1d(k) + thb_qiten(thic,k,thjjb)*DT)
         if ( (thb_temp(thic,k,thjjb).gt. T_0) .and. (xri.gt. 0.0) ) then
          thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) + xri*odt
          thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) + ni1d(k)*odt
          thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) - xri*odt
          thb_niten(thic,k,thjjb) = -ni1d(k)*odt
          thb_tten(thic,k,thjjb) = thb_tten(thic,k,thjjb) - lfus*thb_ocp(thic,k,thjjb)*xri*odt*(1-IFDRY)
         endif

         xrc = MAX(0.0, qc1d(k) + thb_qcten(thic,k,thjjb)*DT)
         if ( (thb_temp(thic,k,thjjb).lt. HGFR) .and. (xrc.gt. 0.0) ) then
          lfus2 = lsub - thb_lvap(thic,k,thjjb)
          xnc = nc1d(k) + thb_ncten(thic,k,thjjb)*DT
          thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) + xrc*odt
          thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) + xnc*odt
          thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) - xrc*odt
          thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) - xnc*odt
          thb_tten(thic,k,thjjb) = thb_tten(thic,k,thjjb) + lfus2*thb_ocp(thic,k,thjjb)*xrc*odt*(1-IFDRY)
         endif
      enddo
      endif




      do k = kts, kte
         t1d(k)  = t1d(k) + thb_tten(thic,k,thjjb)*DT
         qv1d(k) = MAX(1.E-10, qv1d(k) + thb_qvten(thic,k,thjjb)*DT)
         qc1d(k) = qc1d(k) + thb_qcten(thic,k,thjjb)*DT
         nc1d(k) = MAX(2./thb_rho(thic,k,thjjb), MIN(nc1d(k) + thb_ncten(thic,k,thjjb)*DT, Nt_c_max))
         if (is_aerosol_aware) then
            if (aer_init_opt .lt. 2) then
               nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                             (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT)))
               nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                             (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT)))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                        &
                                (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT)))
               else
                  nbca1d(k) = 0.0
               endif
            else
               nwfa1d(k) = MAX(0.0, (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT))
               nifa1d(k) = MAX(0.0, (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(0.0, (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT))
               else
                  nbca1d(k) = 0.0
               endif
            endif
         else
            nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                          (nwfa1d(k)+thb_nwfaten(thic,k,thjjb)*DT)))
            nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                          (nifa1d(k)+thb_nifaten(thic,k,thjjb)*DT)))
            nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                           &
                          (nbca1d(k)+thb_nbcaten(thic,k,thjjb)*DT)))
         endif

         if (qc1d(k) .le. R1) then
           qc1d(k) = 0.0
           nc1d(k) = 0.0
         else
           nu_c = MIN(15, NINT(1000.E6/(nc1d(k)*thb_rho(thic,k,thjjb))) + 2)
           lamc = (am_r*ccg(2,nu_c)*ocg1(nu_c)*nc1d(k)/qc1d(k))**obmr
           xDc = (bm_r + nu_c + 1.) / lamc
           if (xDc.lt. D0c) then
            lamc = cce(2,nu_c)/D0c
           elseif (xDc.gt. D0r*2.) then
            lamc = cce(2,nu_c)/(D0r*2.)
           endif
           nc1d(k) = MIN(ccg(1,nu_c)*ocg2(nu_c)*qc1d(k)/am_r*lamc**bm_r,&
                         DBLE(Nt_c_max)/thb_rho(thic,k,thjjb))
         endif

         qi1d(k) = qi1d(k) + thb_qiten(thic,k,thjjb)*DT
         ni1d(k) = MAX(R2/thb_rho(thic,k,thjjb), ni1d(k) + thb_niten(thic,k,thjjb)*DT)
         if (qi1d(k) .le. R1) then
           qi1d(k) = 0.0
           ni1d(k) = 0.0
         else
           lami = (am_i*cig(2)*oig1*ni1d(k)/qi1d(k))**obmi
           ilami = 1./lami
           xDi = (bm_i + mu_i + 1.) * ilami
           if (xDi.lt. 5.E-6) then
            lami = cie(2)/5.E-6
           elseif (xDi.gt. 300.E-6) then
            lami = cie(2)/300.E-6
           endif
           ni1d(k) = MIN(cig(1)*oig2*qi1d(k)/am_i*lami**bm_i,           &
                         999.D3/thb_rho(thic,k,thjjb))
         endif
         qr1d(k) = qr1d(k) + thb_qrten(thic,k,thjjb)*DT
         nr1d(k) = MAX(R2/thb_rho(thic,k,thjjb), nr1d(k) + thb_nrten(thic,k,thjjb)*DT)
         if (qr1d(k) .le. R1) then
           qr1d(k) = 0.0
           nr1d(k) = 0.0
         else
           lamr = (am_r*crg(3)*org2*nr1d(k)/qr1d(k))**obmr
           thb_mvd_r(thic,k,thjjb) = (3.0 + mu_r + 0.672) / lamr
           if (thb_mvd_r(thic,k,thjjb) .gt. 2.5E-3) then
              thb_mvd_r(thic,k,thjjb) = 2.5E-3
           elseif (thb_mvd_r(thic,k,thjjb) .lt. D0r*0.75) then
              thb_mvd_r(thic,k,thjjb) = D0r*0.75
           endif
           lamr = (3.0 + mu_r + 0.672) / thb_mvd_r(thic,k,thjjb)
           nr1d(k) = crg(2)*org3*qr1d(k)*lamr**bm_r / am_r
         endif
         qs1d(k) = qs1d(k) + thb_qsten(thic,k,thjjb)*DT
         if (qs1d(k) .le. R1) qs1d(k) = 0.0
         qg1d(k) = qg1d(k) + thb_qgten(thic,k,thjjb)*DT
         ng1d(k) = MAX(R2/thb_rho(thic,k,thjjb), ng1d(k) + thb_ngten(thic,k,thjjb)*DT)
         if (qg1d(k) .le. R1) then
           qg1d(k) = 0.0
           ng1d(k) = 0.0
           qb1d(k) = 0.0
         else
           qb1d(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k) + thb_qbten(thic,k,thjjb)*DT)
           qb1d(k) = MIN(qg1d(k)/rho_g(1), qb1d(k))
           thb_idx_bg(thic,k,thjjb) = MAX(1,MIN(NINT(qg1d(k)/qb1d(k) *0.01)+1,NRHG))
           if (.not. is_hail_aware) thb_idx_bg(thic,k,thjjb) = idx_bg1
           lamg = (am_g(thb_idx_bg(thic,k,thjjb))*cgg(3,1)*ogg2*ng1d(k)/qg1d(k))**obmg
           thb_mvd_g(thic,k,thjjb) = (3.0 + mu_g + 0.672) / lamg
           if (thb_mvd_g(thic,k,thjjb) .gt. 25.4E-3) then
              thb_mvd_g(thic,k,thjjb) = 25.4E-3
           elseif (thb_mvd_g(thic,k,thjjb) .lt. D0r) then
              thb_mvd_g(thic,k,thjjb) = D0r
           endif
           lamg = (3.0 + mu_g + 0.672) / thb_mvd_g(thic,k,thjjb)
           ng1d(k) = cgg(2,1)*ogg3*qg1d(k)*lamg**bm_g / am_g(thb_idx_bg(thic,k,thjjb))
         endif

      enddo

      end subroutine thom_fin


!.. copies of calc_effectRad and calc_refl10cm (module_mp_thompson.F) for the tail kernel: a device call across
!.. files needs the callee within the caller's register cap, and inside one file they inline as before the split
      subroutine thtl_effectRad (t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d,   &
     &                re_qc1d, re_qi1d, re_qs1d, kts, kte)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE

!..Sub arguments
      INTEGER, INTENT(IN):: kts, kte
      REAL, DIMENSION(kts:kte), INTENT(IN)::                            &
     &                    t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: re_qc1d, re_qi1d, re_qs1d
!..Local variables
      INTEGER:: k
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rho, rc, nc, ri, ni, rs
#else
      REAL, DIMENSION(kts:kte):: rho, rc, nc, ri, ni, rs
#endif
      REAL:: smo2, smob, smoc
      REAL:: tc0, loga_, a_, b_
      DOUBLE PRECISION:: lamc, lami
      LOGICAL:: has_qc, has_qi, has_qs
      INTEGER:: inu_c
      real, dimension(15), parameter:: g_ratio = (/24,60,120,210,336,   &
     &                504,720,990,1320,1716,2184,2730,3360,4080,4896/)

      has_qc = .false.
      has_qi = .false.
      has_qs = .false.

      re_qc1d(:) = RE_QC_BG
      re_qi1d(:) = RE_QI_BG
      re_qs1d(:) = RE_QS_BG

      do k = kts, kte
         rho(k) = 0.622*p1d(k)/(R*t1d(k)*(qv1d(k)+0.622))
         rc(k) = MAX(R1, qc1d(k)*rho(k))
         nc(k) = MAX(2., MIN(nc1d(k)*rho(k), Nt_c_max))
         if (.NOT. is_aerosol_aware) nc(k) = Nt_c
         if (rc(k).gt.R1 .and. nc(k).gt.R2) has_qc = .true.
         ri(k) = MAX(R1, qi1d(k)*rho(k))
         ni(k) = MAX(R2, ni1d(k)*rho(k))
         if (ri(k).gt.R1 .and. ni(k).gt.R2) has_qi = .true.
         rs(k) = MAX(R1, qs1d(k)*rho(k))
         if (rs(k).gt.R1) has_qs = .true.
      enddo

      if (has_qc) then
      do k = kts, kte
         if (rc(k).le.R1 .or. nc(k).le.R2) CYCLE
         if (nc(k).lt.100) then
            inu_c = 15
         elseif (nc(k).gt.1.E10) then
            inu_c = 2
         else
            inu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
         endif
         lamc = (nc(k)*am_r*g_ratio(inu_c)/rc(k))**obmr
         re_qc1d(k) = MAX(2.51E-6, MIN(SNGL(0.5D0 * DBLE(3.+inu_c)/lamc), 50.E-6))
      enddo
      endif

      if (has_qi) then
      do k = kts, kte
         if (ri(k).le.R1 .or. ni(k).le.R2) CYCLE
         lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
         re_qi1d(k) = MAX(2.51E-6, MIN(SNGL(0.5D0 * DBLE(3.+mu_i)/lami), 125.E-6))
      enddo
      endif

      if (has_qs) then
      do k = kts, kte
         if (rs(k).le.R1) CYCLE
         tc0 = MIN(-0.1, t1d(k)-273.15)
         smob = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2 = smob
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
     &         + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
     &         + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
     &         + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
     &         + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
     &         + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
     &         + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
     &         + sb(10)*bm_s*bm_s*bm_s
            smo2 = (smob/a_)**(1./b_)
         endif
!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
     &         + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
     &         + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
     &        + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc = a_ * smo2**b_
         re_qs1d(k) = MAX(5.01E-6, MIN(0.5*(smoc/smob), 999.E-6))
      enddo
      endif

      end subroutine thtl_effectRad

      subroutine thtl_refl10cm (qv1d, qc1d, qr1d, nr1d, qs1d, qg1d,     &
                          ng1d, qb1d, t1d, p1d, dBZ, kts, kte, ii, jj, ke_diag)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE

!..Sub arguments
      INTEGER, INTENT(IN):: kts, kte, ii, jj, ke_diag
      REAL, DIMENSION(kts:kte), INTENT(IN)::                            &
                qv1d, qc1d, qr1d, nr1d, qs1d, qg1d, ng1d, qb1d, t1d, p1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: dBZ
!     REAL, DIMENSION(kts:kte), INTENT(INOUT):: vt_dBZ

!..Local variables
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: temp, pres, qv, rho, rhof
#else
      REAL, DIMENSION(kts:kte):: temp, pres, qv, rho, rhof
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rc, rr, nr, rs, rg, ng, rb
#else
      REAL, DIMENSION(kts:kte):: rc, rr, nr, rs, rg, ng, rb
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: ilamr, ilamg, N0_r, N0_g
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: ilamr, ilamg, N0_r, N0_g
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: mvd_r
#else
      REAL, DIMENSION(kts:kte):: mvd_r
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: smob, smo2, smoc, smoz
#else
      REAL, DIMENSION(kts:kte):: smob, smo2, smoc, smoz
#endif
      REAL:: oM3, M0, Mrat, slam1, slam2, xDs
      REAL:: ils1, ils2, t1_vts, t2_vts, t3_vts, t4_vts
      REAL:: vtr_dbz_wt, vts_dbz_wt, vtg_dbz_wt

#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: ze_rain, ze_snow, ze_graupel
#else
      REAL, DIMENSION(kts:kte):: ze_rain, ze_snow, ze_graupel
#endif
#ifdef WRF_GPU
      INTEGER, DIMENSION(1:KTGPU):: idx_bg
#else
      INTEGER, DIMENSION(kts:kte):: idx_bg
#endif

      DOUBLE PRECISION:: N0_exp, N0_min, lam_exp, lamr, lamg
      REAL:: a_, b_, loga_, tc0
      DOUBLE PRECISION:: fmelt_s, fmelt_g

      INTEGER:: i, k, k_0, kbot, n, ktop
      LOGICAL:: melti
#ifdef WRF_GPU
      LOGICAL, DIMENSION(1:KTGPU):: L_qr, L_qs, L_qg
#else
      LOGICAL, DIMENSION(kts:kte):: L_qr, L_qs, L_qg
#endif

      DOUBLE PRECISION:: cback, x, eta, f_d
      REAL:: xslw1, ygra1, zans1
      INTEGER :: k_0loop

!+---+

      do k = kts, kte
         dBZ(k) = -35.0
      enddo

!+---+-----------------------------------------------------------------+
!..Put column of data into local arrays.
!+---+-----------------------------------------------------------------+

      do k = kts, kte
         temp(k) = t1d(k)
         qv(k) = MAX(1.E-10, qv1d(k))
         pres(k) = p1d(k)
         rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
         rhof(k) = SQRT(RHO_NOT/rho(k))
         rc(k) = MAX(R1, qc1d(k)*rho(k))
         if (qr1d(k) .gt. R1) then
            rr(k) = qr1d(k)*rho(k)
            nr(k) = MAX(R2, nr1d(k)*rho(k))
            lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
            ilamr(k) = 1./lamr
            N0_r(k) = nr(k)*org2*lamr**cre(2)
            mvd_r(k) = (3.0 + mu_r + 0.672) * ilamr(k)
            L_qr(k) = .true.
         else
            rr(k) = R1
            nr(k) = R1
            mvd_r(k) = 50.E-6
            L_qr(k) = .false.
         endif
         if (qs1d(k) .gt. R2) then
            rs(k) = qs1d(k)*rho(k)
            L_qs(k) = .true.
         else
            rs(k) = R1
            L_qs(k) = .false.
         endif
         if (qg1d(k) .gt. R2) then
            rg(k) = qg1d(k)*rho(k)
            ng(k) = MAX(R2, ng1d(k)*rho(k))
            rb(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k))
            rb(k) = MIN(qg1d(k)/rho_g(1), rb(k))
            idx_bg(k) = MAX(1,MIN(NINT(qg1d(k)/rb(k) *0.01)+1,NRHG))
            if (.not. is_hail_aware) idx_bg(k) = idx_bg1
            L_qg(k) = .true.
         else
            rg(k) = R1
            ng(k) = R2
            idx_bg(k) = idx_bg1
            L_qg(k) = .false.
         endif
      enddo

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope, and useful moments for snow.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         smo2(k) = 0.
         smob(k) = 0.
         smoc(k) = 0.
         smoz(k) = 0.
      enddo
      if ( ( ke_diag > kts .and. ANY(L_qs(kts:kte)) ) .or.  &
            (ke_diag == kts .and. L_qs(kts) .eqv. .true. ) ) then
      do k = kts, ke_diag ! kte
         if (.not. L_qs(k)) CYCLE
         tc0 = MIN(-0.1, temp(k)-273.15)
         smob(k) = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2(k) = smob(k)
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
     &         + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
     &         + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
     &         + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
     &         + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
     &         + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
     &         + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
     &         + sb(10)*bm_s*bm_s*bm_s
            smo2(k) = (smob(k)/a_)**(1./b_)
         endif

!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
     &         + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
     &         + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
     &        + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc(k) = a_ * smo2(k)**b_

!..Calculate bm_s*2 (th) moment.  Useful for reflectivity.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(3) &
     &         + sa(4)*tc0*cse(3) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(3)*cse(3) + sa(7)*tc0*tc0*cse(3) &
     &         + sa(8)*tc0*cse(3)*cse(3) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(3)*cse(3)*cse(3)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(3) + sb(4)*tc0*cse(3) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(3)*cse(3) &
     &        + sb(7)*tc0*tc0*cse(3) + sb(8)*tc0*cse(3)*cse(3) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(3)*cse(3)*cse(3)
         smoz(k) = a_ * smo2(k)**b_
      enddo
      endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for graupel.
!+---+-----------------------------------------------------------------+

      if (ANY(L_qg(kts:kte))) then
      do k = kte, kts, -1
         lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng(k)/rg(k))**obmg
         ilamg(k) = 1./lamg
         N0_g(k) = ng(k)*ogg2*lamg**cge(2,1)
      enddo
      else
         ilamg(:) = 0.
         N0_g(:) = 0.
      endif

!+---+-----------------------------------------------------------------+
!..Locate K-level of start of melting (k_0 is level above).
!+---+-----------------------------------------------------------------+
      melti = .false.
      k_0 = kts
      do k = kte-1, kts, -1
         if ( (temp(k).gt.273.15) .and. L_qr(k)                         &
     &                            .and. (L_qs(k+1).or.L_qg(k+1)) ) then
            k_0 = MAX(k+1, k_0)
            melti=.true.
            goto 195
         endif
      enddo
 195  continue

! Set loop limit for wet ice according to whether the full 3D field is needed or just k=1
      k_0loop = Min(k_0, ke_diag+1)

!+---+-----------------------------------------------------------------+
!..Do not do the so-called bright band if using the variable density
!.. graupel-hail category since the density increases during melting and
!.. will account for bright band behavior explicitly.
!+---+-----------------------------------------------------------------+
!     if (is_hail_aware) melti = .false.

!+---+-----------------------------------------------------------------+
!..Assume Rayleigh approximation at 10 cm wavelength. Rain (all temps)
!.. and non-water-coated snow and graupel when below freezing are
!.. simple. Integrations of m(D)*m(D)*N(D)*dD.
!+---+-----------------------------------------------------------------+

      do k = kts, ke_diag ! kte
         ze_rain(k) = 1.e-22
         ze_snow(k) = 1.e-22
         ze_graupel(k) = 1.e-22
         if (L_qr(k)) ze_rain(k) = N0_r(k)*crg(4)*ilamr(k)**cre(4)
         if (L_qs(k)) ze_snow(k) = (0.176/0.93) * (6.0/PI)*(6.0/PI)     &
     &                           * (am_s/900.0)*(am_s/900.0)*smoz(k)
         if (L_qg(k)) ze_graupel(k) = (0.176/0.93) * (6.0/PI)*(6.0/PI)  &
     &               * (am_g(idx_bg(k))/900.0)*(am_g(idx_bg(k))/900.0)  &
     &               * N0_g(k)*cgg(4,1)*ilamg(k)**cge(4,1)
      enddo

!+---+-----------------------------------------------------------------+
!..Special case of melting ice (snow/graupel) particles.  Assume the
!.. ice is surrounded by the liquid water.  Fraction of meltwater is
!.. extremely simple based on amount found above the melting level.
!.. Uses code from Uli Blahak (rayleigh_soak_wetgraupel and supporting
!.. routines).
!+---+-----------------------------------------------------------------+

      if (.not. iiwarm .and. melti .and. k_0.ge.2) then
       do k = k_0loop-1, kts, -1

!..Reflectivity contributed by melting snow
          if (L_qs(k) .and. L_qs(k_0) ) then
           fmelt_s = MAX(0.05d0, MIN(1.0d0-rs(k)/rs(k_0), 0.99d0))
           eta = 0.d0
           oM3 = 1./smoc(k)
           M0 = (smob(k)*oM3)
           Mrat = smob(k)*M0*M0*M0
           slam1 = M0 * Lam0
           slam2 = M0 * Lam1
           do n = 1, nrbins
              x = am_s * xxDs(n)**bm_s
#ifdef WRF_GPU
              call rayleigh_soak_wetgraupel_g (x, DBLE(ocms), DBLE(obms), &
     &              fmelt_s, melt_outside_s, m_w_0, m_i_0, lamda_radar, &
     &              CBACK, rcode_s)
#else
              call rayleigh_soak_wetgraupel (x, DBLE(ocms), DBLE(obms), &
     &              fmelt_s, melt_outside_s, m_w_0, m_i_0, lamda_radar, &
     &              CBACK, mixingrulestring_s, matrixstring_s,          &
     &              inclusionstring_s, hoststring_s,                    &
     &              hostmatrixstring_s, hostinclusionstring_s)
#endif
              f_d = Mrat*(Kap0*DEXP(-slam1*xxDs(n))                     &
     &              + Kap1*(M0*xxDs(n))**mu_s * DEXP(-slam2*xxDs(n)))
              eta = eta + f_d * CBACK * simpson(n) * xdts(n)
           enddo
           ze_snow(k) = SNGL(lamda4 / (pi5 * K_w) * eta)
          endif

!..Reflectivity contributed by melting graupel

!         if (L_qg(k) .and. L_qg(k_0) ) then
!          fmelt_g = MAX(0.05d0, MIN(1.0d0-rg(k)/rg(k_0), 0.99d0))
!          eta = 0.d0
!          lamg = 1./ilamg(k)
!          do n = 1, nrbins
!             x = am_g(idx_bg(k)) * xxDg(n)**bm_g
!             call rayleigh_soak_wetgraupel (x, DBLE(ocmg(idx_bg(k))), DBLE(obmg), &
!    &              fmelt_g, melt_outside_g, m_w_0, m_i_0, lamda_radar, &
!    &              CBACK, mixingrulestring_g, matrixstring_g,          &
!    &              inclusionstring_g, hoststring_g,                    &
!    &              hostmatrixstring_g, hostinclusionstring_g)
!             f_d = N0_g(k)*xxDg(n)**mu_g * DEXP(-lamg*xxDg(n))
!             eta = eta + f_d * CBACK * simpson(n) * xdtg(n)
!          enddo
!          ze_graupel(k) = SNGL(lamda4 / (pi5 * K_w) * eta)
!         endif

       enddo
      endif

      do k = ke_diag, kts, -1
         dBZ(k) = 10.*log10((ze_rain(k)+ze_snow(k)+ze_graupel(k))*1.d18)
      enddo


!..Reflectivity-weighted terminal velocity (snow, rain, graupel, mix).
!     do k = kte, kts, -1
!        vt_dBZ(k) = 1.E-3
!        if (rs(k).gt.R2) then
!         Mrat = smob(k) / smoc(k)
!         ils1 = 1./(Mrat*Lam0 + fv_s)
!         ils2 = 1./(Mrat*Lam1 + fv_s)
!         t1_vts = Kap0*csg(5)*ils1**cse(5)
!         t2_vts = Kap1*Mrat**mu_s*csg(11)*ils2**cse(11)
!         ils1 = 1./(Mrat*Lam0)
!         ils2 = 1./(Mrat*Lam1)
!         t3_vts = Kap0*csg(6)*ils1**cse(6)
!         t4_vts = Kap1*Mrat**mu_s*csg(12)*ils2**cse(12)
!         vts_dbz_wt = rhof(k)*av_s * (t1_vts+t2_vts)/(t3_vts+t4_vts)
!         if (temp(k).ge.273.15 .and. temp(k).lt.275.15) then
!            vts_dbz_wt = vts_dbz_wt*1.5
!         elseif (temp(k).ge.275.15) then
!            vts_dbz_wt = vts_dbz_wt*2.0
!         endif
!        else
!         vts_dbz_wt = 1.E-3
!        endif

!        if (rr(k).gt.R1) then
!         lamr = 1./ilamr(k)
!         vtr_dbz_wt = rhof(k)*av_r*crg(13)*(lamr+fv_r)**(-cre(13))      &
!    &               / (crg(4)*lamr**(-cre(4)))
!        else
!         vtr_dbz_wt = 1.E-3
!        endif

!        if (rg(k).gt.R2) then
!         lamg = 1./ilamg(k)
!         vtg_dbz_wt = rhof(k)*av_g(idx_bg(k))*cgg(5,idx_bg(k))*lamg**(-cge(5,idx_bg(k)))               &
!    &               / (cgg(4,1)*lamg**(-cge(4,1)))
!        else
!         vtg_dbz_wt = 1.E-3
!        endif

!        vt_dBZ(k) = (vts_dbz_wt*ze_snow(k) + vtr_dbz_wt*ze_rain(k)      &
!    &                + vtg_dbz_wt*ze_graupel(k))                        &
!    &                / (ze_rain(k)+ze_snow(k)+ze_graupel(k))
!     enddo

      end subroutine thtl_refl10cm

      END SUBMODULE module_mp_thompson_tail
#endif
