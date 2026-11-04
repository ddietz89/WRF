! GENERATED: page-lock the persistent i1 temporaries (WRF_GPU_PIN)
         pin_nok = 0 ; pin_nfail = 0 ; pin_tot = 0
         IF ( ALLOCATED(ru_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(ru_tendf), INT(SIZE(ru_tendf),8)*INT(STORAGE_SIZE(ru_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(rv_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(rv_tendf), INT(SIZE(rv_tendf),8)*INT(STORAGE_SIZE(rv_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(ww1) ) CALL wrf_gpu_pin_addr( &
              LOC(ww1), INT(SIZE(ww1),8)*INT(STORAGE_SIZE(ww1)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(wwe) ) CALL wrf_gpu_pin_addr( &
              LOC(wwe), INT(SIZE(wwe),8)*INT(STORAGE_SIZE(wwe)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(wwi) ) CALL wrf_gpu_pin_addr( &
              LOC(wwi), INT(SIZE(wwi),8)*INT(STORAGE_SIZE(wwi)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(wwp) ) CALL wrf_gpu_pin_addr( &
              LOC(wwp), INT(SIZE(wwp),8)*INT(STORAGE_SIZE(wwp)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(rw_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(rw_tend), INT(SIZE(rw_tend),8)*INT(STORAGE_SIZE(rw_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(rw_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(rw_tendf), INT(SIZE(rw_tendf),8)*INT(STORAGE_SIZE(rw_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(w_save) ) CALL wrf_gpu_pin_addr( &
              LOC(w_save), INT(SIZE(w_save),8)*INT(STORAGE_SIZE(w_save)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(ph_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(ph_tend), INT(SIZE(ph_tend),8)*INT(STORAGE_SIZE(ph_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(ph_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(ph_tendf), INT(SIZE(ph_tendf),8)*INT(STORAGE_SIZE(ph_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(ph_save) ) CALL wrf_gpu_pin_addr( &
              LOC(ph_save), INT(SIZE(ph_save),8)*INT(STORAGE_SIZE(ph_save)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(t_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(t_tend), INT(SIZE(t_tend),8)*INT(STORAGE_SIZE(t_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(t_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(t_tendf), INT(SIZE(t_tendf),8)*INT(STORAGE_SIZE(t_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(t_2save) ) CALL wrf_gpu_pin_addr( &
              LOC(t_2save), INT(SIZE(t_2save),8)*INT(STORAGE_SIZE(t_2save)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(muave) ) CALL wrf_gpu_pin_addr( &
              LOC(muave), INT(SIZE(muave),8)*INT(STORAGE_SIZE(muave)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(mu_save) ) CALL wrf_gpu_pin_addr( &
              LOC(mu_save), INT(SIZE(mu_save),8)*INT(STORAGE_SIZE(mu_save)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(mu_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(mu_tend), INT(SIZE(mu_tend),8)*INT(STORAGE_SIZE(mu_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(mu_tendf) ) CALL wrf_gpu_pin_addr( &
              LOC(mu_tendf), INT(SIZE(mu_tendf),8)*INT(STORAGE_SIZE(mu_tendf)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(tke_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(tke_tend), INT(SIZE(tke_tend),8)*INT(STORAGE_SIZE(tke_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(advect_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(advect_tend), INT(SIZE(advect_tend),8)*INT(STORAGE_SIZE(advect_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(alpha) ) CALL wrf_gpu_pin_addr( &
              LOC(alpha), INT(SIZE(alpha),8)*INT(STORAGE_SIZE(alpha)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(a) ) CALL wrf_gpu_pin_addr( LOC(a), INT(SIZE(a),8)*INT(STORAGE_SIZE(a)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(gamma) ) CALL wrf_gpu_pin_addr( &
              LOC(gamma), INT(SIZE(gamma),8)*INT(STORAGE_SIZE(gamma)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(c2a) ) CALL wrf_gpu_pin_addr( &
              LOC(c2a), INT(SIZE(c2a),8)*INT(STORAGE_SIZE(c2a)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(phm) ) CALL wrf_gpu_pin_addr( &
              LOC(phm), INT(SIZE(phm),8)*INT(STORAGE_SIZE(phm)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(cqu) ) CALL wrf_gpu_pin_addr( &
              LOC(cqu), INT(SIZE(cqu),8)*INT(STORAGE_SIZE(cqu)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(cqv) ) CALL wrf_gpu_pin_addr( &
              LOC(cqv), INT(SIZE(cqv),8)*INT(STORAGE_SIZE(cqv)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(cqw) ) CALL wrf_gpu_pin_addr( &
              LOC(cqw), INT(SIZE(cqw),8)*INT(STORAGE_SIZE(cqw)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(pm1) ) CALL wrf_gpu_pin_addr( &
              LOC(pm1), INT(SIZE(pm1),8)*INT(STORAGE_SIZE(pm1)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(psim) ) CALL wrf_gpu_pin_addr( &
              LOC(psim), INT(SIZE(psim),8)*INT(STORAGE_SIZE(psim)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(psih) ) CALL wrf_gpu_pin_addr( &
              LOC(psih), INT(SIZE(psih),8)*INT(STORAGE_SIZE(psih)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(gz1oz0) ) CALL wrf_gpu_pin_addr( &
              LOC(gz1oz0), INT(SIZE(gz1oz0),8)*INT(STORAGE_SIZE(gz1oz0)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(chklowq) ) CALL wrf_gpu_pin_addr( &
              LOC(chklowq), INT(SIZE(chklowq),8)*INT(STORAGE_SIZE(chklowq)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(ht_loc) ) CALL wrf_gpu_pin_addr( &
              LOC(ht_loc), INT(SIZE(ht_loc),8)*INT(STORAGE_SIZE(ht_loc)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(th_phy) ) CALL wrf_gpu_pin_addr( &
              LOC(th_phy), INT(SIZE(th_phy),8)*INT(STORAGE_SIZE(th_phy)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(pi_phy) ) CALL wrf_gpu_pin_addr( &
              LOC(pi_phy), INT(SIZE(pi_phy),8)*INT(STORAGE_SIZE(pi_phy)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(p_phy) ) CALL wrf_gpu_pin_addr( &
              LOC(p_phy), INT(SIZE(p_phy),8)*INT(STORAGE_SIZE(p_phy)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(dz8w) ) CALL wrf_gpu_pin_addr( &
              LOC(dz8w), INT(SIZE(dz8w),8)*INT(STORAGE_SIZE(dz8w)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(p8w) ) CALL wrf_gpu_pin_addr( &
              LOC(p8w), INT(SIZE(p8w),8)*INT(STORAGE_SIZE(p8w)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(t8w) ) CALL wrf_gpu_pin_addr( &
              LOC(t8w), INT(SIZE(t8w),8)*INT(STORAGE_SIZE(t8w)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(cu_act_flag) ) CALL wrf_gpu_pin_addr( &
              LOC(cu_act_flag), INT(SIZE(cu_act_flag),8)*INT(STORAGE_SIZE(cu_act_flag)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(hol) ) CALL wrf_gpu_pin_addr( &
              LOC(hol), INT(SIZE(hol),8)*INT(STORAGE_SIZE(hol)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(moist_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(moist_tend), INT(SIZE(moist_tend),8)*INT(STORAGE_SIZE(moist_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(moist_old) ) CALL wrf_gpu_pin_addr( &
              LOC(moist_old), INT(SIZE(moist_old),8)*INT(STORAGE_SIZE(moist_old)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(dfi_moist_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(dfi_moist_tend), INT(SIZE(dfi_moist_tend),8)*INT(STORAGE_SIZE(dfi_moist_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(dfi_moist_old) ) CALL wrf_gpu_pin_addr( &
              LOC(dfi_moist_old), INT(SIZE(dfi_moist_old),8)*INT(STORAGE_SIZE(dfi_moist_old)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(scalar_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(scalar_tend), INT(SIZE(scalar_tend),8)*INT(STORAGE_SIZE(scalar_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(scalar_old) ) CALL wrf_gpu_pin_addr( &
              LOC(scalar_old), INT(SIZE(scalar_old),8)*INT(STORAGE_SIZE(scalar_old)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(dfi_scalar_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(dfi_scalar_tend), INT(SIZE(dfi_scalar_tend),8)*INT(STORAGE_SIZE(dfi_scalar_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(dfi_scalar_old) ) CALL wrf_gpu_pin_addr( &
              LOC(dfi_scalar_old), INT(SIZE(dfi_scalar_old),8)*INT(STORAGE_SIZE(dfi_scalar_old)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(tracer_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(tracer_tend), INT(SIZE(tracer_tend),8)*INT(STORAGE_SIZE(tracer_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(tracer_old) ) CALL wrf_gpu_pin_addr( &
              LOC(tracer_old), INT(SIZE(tracer_old),8)*INT(STORAGE_SIZE(tracer_old)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(chem_tend) ) CALL wrf_gpu_pin_addr( &
              LOC(chem_tend), INT(SIZE(chem_tend),8)*INT(STORAGE_SIZE(chem_tend)/8,8), pin_nok, pin_nfail, pin_tot )
         IF ( ALLOCATED(chem_old) ) CALL wrf_gpu_pin_addr( &
              LOC(chem_old), INT(SIZE(chem_old),8)*INT(STORAGE_SIZE(chem_old)/8,8), pin_nok, pin_nfail, pin_tot )
         WRITE(0,'(A,I6,A,I6,A,F9.1,A)') 'WRF_GPU_PIN i1: ', pin_nok, ' registered, ', pin_nfail, ' failed, ', DBLE(pin_tot)/1.d6, ' MB'
