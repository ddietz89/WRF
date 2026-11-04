! GENERATED (2026-11-03): allocate the persistent i1 temporaries once (single domain: bounds fixed)
   IF ( .NOT. ALLOCATED(ru_tendf) ) THEN
      ALLOCATE( ru_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ru_tendf)
!$acc kernels present(ru_tendf)
      ru_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rv_tendf) ) THEN
      ALLOCATE( rv_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rv_tendf)
!$acc kernels present(rv_tendf)
      rv_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ww1) ) THEN
      ALLOCATE( ww1(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ww1)
!$acc kernels present(ww1)
      ww1 = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwe) ) THEN
      ALLOCATE( wwe(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwe)
!$acc kernels present(wwe)
      wwe = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwi) ) THEN
      ALLOCATE( wwi(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwi)
!$acc kernels present(wwi)
      wwi = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwp) ) THEN
      ALLOCATE( wwp(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwp)
!$acc kernels present(wwp)
      wwp = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rw_tend) ) THEN
      ALLOCATE( rw_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rw_tend)
!$acc kernels present(rw_tend)
      rw_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rw_tendf) ) THEN
      ALLOCATE( rw_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rw_tendf)
!$acc kernels present(rw_tendf)
      rw_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(w_save) ) THEN
      ALLOCATE( w_save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(w_save)
!$acc kernels present(w_save)
      w_save = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_tend) ) THEN
      ALLOCATE( ph_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_tend)
!$acc kernels present(ph_tend)
      ph_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_tendf) ) THEN
      ALLOCATE( ph_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_tendf)
!$acc kernels present(ph_tendf)
      ph_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_save) ) THEN
      ALLOCATE( ph_save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_save)
!$acc kernels present(ph_save)
      ph_save = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_tend) ) THEN
      ALLOCATE( t_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_tend)
!$acc kernels present(t_tend)
      t_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_tendf) ) THEN
      ALLOCATE( t_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_tendf)
!$acc kernels present(t_tendf)
      t_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_2save) ) THEN
      ALLOCATE( t_2save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_2save)
!$acc kernels present(t_2save)
      t_2save = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(muave) ) THEN
      ALLOCATE( muave(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(muave)
!$acc kernels present(muave)
      muave = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_save) ) THEN
      ALLOCATE( mu_save(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_save)
!$acc kernels present(mu_save)
      mu_save = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_tend) ) THEN
      ALLOCATE( mu_tend(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_tend)
!$acc kernels present(mu_tend)
      mu_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_tendf) ) THEN
      ALLOCATE( mu_tendf(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_tendf)
!$acc kernels present(mu_tendf)
      mu_tendf = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(tke_tend) ) THEN
      ALLOCATE( tke_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tke_tend)
!$acc kernels present(tke_tend)
      tke_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(advect_tend) ) THEN
      ALLOCATE( advect_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(advect_tend)
!$acc kernels present(advect_tend)
      advect_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(alpha) ) THEN
      ALLOCATE( alpha(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(alpha)
!$acc kernels present(alpha)
      alpha = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(a) ) THEN
      ALLOCATE( a(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(a)
!$acc kernels present(a)
      a = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(gamma) ) THEN
      ALLOCATE( gamma(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(gamma)
!$acc kernels present(gamma)
      gamma = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(c2a) ) THEN
      ALLOCATE( c2a(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(c2a)
!$acc kernels present(c2a)
      c2a = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(phm) ) THEN
      ALLOCATE( phm(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(phm)
!$acc kernels present(phm)
      phm = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqu) ) THEN
      ALLOCATE( cqu(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqu)
!$acc kernels present(cqu)
      cqu = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqv) ) THEN
      ALLOCATE( cqv(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqv)
!$acc kernels present(cqv)
      cqv = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqw) ) THEN
      ALLOCATE( cqw(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqw)
!$acc kernels present(cqw)
      cqw = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(pm1) ) THEN
      ALLOCATE( pm1(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(pm1)
!$acc kernels present(pm1)
      pm1 = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(psim) ) THEN
      ALLOCATE( psim(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(psim)
!$acc kernels present(psim)
      psim = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(psih) ) THEN
      ALLOCATE( psih(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(psih)
!$acc kernels present(psih)
      psih = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(gz1oz0) ) THEN
      ALLOCATE( gz1oz0(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(gz1oz0)
!$acc kernels present(gz1oz0)
      gz1oz0 = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(chklowq) ) THEN
      ALLOCATE( chklowq(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chklowq)
!$acc kernels present(chklowq)
      chklowq = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ht_loc) ) THEN
      ALLOCATE( ht_loc(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ht_loc)
!$acc kernels present(ht_loc)
      ht_loc = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(th_phy) ) THEN
      ALLOCATE( th_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(th_phy)
!$acc kernels present(th_phy)
      th_phy = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(pi_phy) ) THEN
      ALLOCATE( pi_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(pi_phy)
!$acc kernels present(pi_phy)
      pi_phy = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(p_phy) ) THEN
      ALLOCATE( p_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(p_phy)
!$acc kernels present(p_phy)
      p_phy = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(dz8w) ) THEN
      ALLOCATE( dz8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dz8w)
!$acc kernels present(dz8w)
      dz8w = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(p8w) ) THEN
      ALLOCATE( p8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(p8w)
!$acc kernels present(p8w)
      p8w = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t8w) ) THEN
      ALLOCATE( t8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t8w)
!$acc kernels present(t8w)
      t8w = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cu_act_flag) ) THEN
      ALLOCATE( cu_act_flag(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cu_act_flag)
!$acc kernels present(cu_act_flag)
      cu_act_flag = .FALSE.   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(hol) ) THEN
      ALLOCATE( hol(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(hol)
!$acc kernels present(hol)
      hol = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(moist_tend) ) THEN
      ALLOCATE( moist_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(moist_tend)
!$acc kernels present(moist_tend)
      moist_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(moist_old) ) THEN
      ALLOCATE( moist_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(moist_old)
!$acc kernels present(moist_old)
      moist_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(dfi_moist_tend) ) THEN
      ALLOCATE( dfi_moist_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_moist_tend)
!$acc kernels present(dfi_moist_tend)
      dfi_moist_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(dfi_moist_old) ) THEN
      ALLOCATE( dfi_moist_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_moist_old)
!$acc kernels present(dfi_moist_old)
      dfi_moist_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(scalar_tend) ) THEN
      ALLOCATE( scalar_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(scalar_tend)
!$acc kernels present(scalar_tend)
      scalar_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(scalar_old) ) THEN
      ALLOCATE( scalar_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(scalar_old)
!$acc kernels present(scalar_old)
      scalar_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(dfi_scalar_tend) ) THEN
      ALLOCATE( dfi_scalar_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_scalar_tend)
!$acc kernels present(dfi_scalar_tend)
      dfi_scalar_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(dfi_scalar_old) ) THEN
      ALLOCATE( dfi_scalar_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_scalar_old)
!$acc kernels present(dfi_scalar_old)
      dfi_scalar_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(tracer_tend) ) THEN
      ALLOCATE( tracer_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_tracer) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tracer_tend)
!$acc kernels present(tracer_tend)
      tracer_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(tracer_old) ) THEN
      ALLOCATE( tracer_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_tracer) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tracer_old)
!$acc kernels present(tracer_old)
      tracer_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(chem_tend) ) THEN
      ALLOCATE( chem_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_chem) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chem_tend)
!$acc kernels present(chem_tend)
      chem_tend = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(chem_old) ) THEN
      ALLOCATE( chem_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_chem) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chem_old)
!$acc kernels present(chem_old)
      chem_old = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif
   ENDIF
#endif
