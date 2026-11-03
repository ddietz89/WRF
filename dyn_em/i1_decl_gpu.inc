! GENERATED (2026-11-03) from inc/i1_decl.inc: solve_em i1 temporaries as persistent allocatables (GPU builds)
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: ru_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: rv_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: ww1
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: wwe
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: wwi
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: wwp
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: rw_tend
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: rw_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: w_save
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: ph_tend
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: ph_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: ph_save
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: t_tend
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: t_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: t_2save
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: muave
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: mu_save
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: mu_tend
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: mu_tendf
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: tke_tend
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: advect_tend
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: alpha
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: a
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: gamma
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: c2a
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: phm
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: cqu
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: cqv
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: cqw
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: pm1
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: psim
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: psih
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: gz1oz0
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: chklowq
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: ht_loc
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: th_phy
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: pi_phy
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: p_phy
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: dz8w
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: p8w
real, DIMENSION(:,:,:), ALLOCATABLE, SAVE :: t8w
logical, DIMENSION(:,:), ALLOCATABLE, SAVE :: cu_act_flag
real, DIMENSION(:,:), ALLOCATABLE, SAVE :: hol
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: moist_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: moist_old
#endif
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: dfi_moist_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: dfi_moist_old
#endif
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: scalar_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: scalar_old
#endif
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: dfi_scalar_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: dfi_scalar_old
#endif
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: tracer_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: tracer_old
#endif
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: chem_tend
#ifndef NO_I1_OLD
real, DIMENSION(:,:,:,:), ALLOCATABLE, SAVE :: chem_old
#endif
