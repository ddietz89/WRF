! GENERATED (2026-11-03): allocate the persistent i1 temporaries once (single domain: bounds fixed)
   IF ( .NOT. ALLOCATED(ru_tendf) ) THEN
      ALLOCATE( ru_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ru_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rv_tendf) ) THEN
      ALLOCATE( rv_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rv_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ww1) ) THEN
      ALLOCATE( ww1(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ww1)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwe) ) THEN
      ALLOCATE( wwe(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwe)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwi) ) THEN
      ALLOCATE( wwi(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwi)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(wwp) ) THEN
      ALLOCATE( wwp(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(wwp)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rw_tend) ) THEN
      ALLOCATE( rw_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rw_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(rw_tendf) ) THEN
      ALLOCATE( rw_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(rw_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(w_save) ) THEN
      ALLOCATE( w_save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(w_save)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_tend) ) THEN
      ALLOCATE( ph_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_tendf) ) THEN
      ALLOCATE( ph_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ph_save) ) THEN
      ALLOCATE( ph_save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ph_save)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_tend) ) THEN
      ALLOCATE( t_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_tendf) ) THEN
      ALLOCATE( t_tendf(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t_2save) ) THEN
      ALLOCATE( t_2save(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t_2save)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(muave) ) THEN
      ALLOCATE( muave(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(muave)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_save) ) THEN
      ALLOCATE( mu_save(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_save)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_tend) ) THEN
      ALLOCATE( mu_tend(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(mu_tendf) ) THEN
      ALLOCATE( mu_tendf(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(mu_tendf)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(tke_tend) ) THEN
      ALLOCATE( tke_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tke_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(advect_tend) ) THEN
      ALLOCATE( advect_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(advect_tend)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(alpha) ) THEN
      ALLOCATE( alpha(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(alpha)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(a) ) THEN
      ALLOCATE( a(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(a)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(gamma) ) THEN
      ALLOCATE( gamma(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(gamma)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(c2a) ) THEN
      ALLOCATE( c2a(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(c2a)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(phm) ) THEN
      ALLOCATE( phm(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(phm)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqu) ) THEN
      ALLOCATE( cqu(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqu)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqv) ) THEN
      ALLOCATE( cqv(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqv)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cqw) ) THEN
      ALLOCATE( cqw(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cqw)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(pm1) ) THEN
      ALLOCATE( pm1(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(pm1)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(psim) ) THEN
      ALLOCATE( psim(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(psim)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(psih) ) THEN
      ALLOCATE( psih(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(psih)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(gz1oz0) ) THEN
      ALLOCATE( gz1oz0(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(gz1oz0)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(chklowq) ) THEN
      ALLOCATE( chklowq(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chklowq)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(ht_loc) ) THEN
      ALLOCATE( ht_loc(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(ht_loc)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(th_phy) ) THEN
      ALLOCATE( th_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(th_phy)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(pi_phy) ) THEN
      ALLOCATE( pi_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(pi_phy)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(p_phy) ) THEN
      ALLOCATE( p_phy(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(p_phy)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(dz8w) ) THEN
      ALLOCATE( dz8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dz8w)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(p8w) ) THEN
      ALLOCATE( p8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(p8w)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(t8w) ) THEN
      ALLOCATE( t8w(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(t8w)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(cu_act_flag) ) THEN
      ALLOCATE( cu_act_flag(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(cu_act_flag)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(hol) ) THEN
      ALLOCATE( hol(grid%sm31:grid%em31,grid%sm33:grid%em33) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(hol)
#endif
   ENDIF
   IF ( .NOT. ALLOCATED(moist_tend) ) THEN
      ALLOCATE( moist_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(moist_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(moist_old) ) THEN
      ALLOCATE( moist_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(moist_old)
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(dfi_moist_tend) ) THEN
      ALLOCATE( dfi_moist_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_moist_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(dfi_moist_old) ) THEN
      ALLOCATE( dfi_moist_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_moist) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_moist_old)
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(scalar_tend) ) THEN
      ALLOCATE( scalar_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(scalar_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(scalar_old) ) THEN
      ALLOCATE( scalar_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(scalar_old)
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(dfi_scalar_tend) ) THEN
      ALLOCATE( dfi_scalar_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_scalar_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(dfi_scalar_old) ) THEN
      ALLOCATE( dfi_scalar_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_dfi_scalar) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(dfi_scalar_old)
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(tracer_tend) ) THEN
      ALLOCATE( tracer_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_tracer) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tracer_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(tracer_old) ) THEN
      ALLOCATE( tracer_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_tracer) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(tracer_old)
#endif
   ENDIF
#endif
   IF ( .NOT. ALLOCATED(chem_tend) ) THEN
      ALLOCATE( chem_tend(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_chem) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chem_tend)
#endif
   ENDIF
#ifndef NO_I1_OLD
   IF ( .NOT. ALLOCATED(chem_old) ) THEN
      ALLOCATE( chem_old(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33,num_chem) )
#ifdef WRF_GPU_RESIDENT
!$acc enter data create(chem_old)
#endif
   ENDIF
#endif
