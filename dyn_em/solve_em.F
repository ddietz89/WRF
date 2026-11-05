!WRF:MEDIATION_LAYER:SOLVER

#ifdef WRF_SEG_TIMERS
! Per-segment wall clock (step 1 of the GPU decision plan): 1 dynamics, 2 physics (first_rk_step_part1/2),
! 3 post-RK microphysics block, 4 after_all_rk_steps, 0 outside solve_em (I/O, boundary input).
! Cumulative seconds are printed to stderr (rsl.error.*) every 20 solve_em calls.
MODULE wrf_seg_timers
   IMPLICIT NONE
   INTEGER(8), SAVE :: t_last = -1, rate = 1
   REAL(8), SAVE :: acc(0:6) = 0.d0
   INTEGER, SAVE :: prev_seg = 1
   INTEGER, SAVE :: cur = 0, ncalls = 0
CONTAINS
   SUBROUTINE seg_mark( id )
      INTEGER, INTENT(IN) :: id
      INTEGER(8) :: t
      CALL SYSTEM_CLOCK( t, rate )
      IF ( t_last >= 0 ) acc(cur) = acc(cur) + DBLE(t - t_last) / DBLE(rate)
      t_last = t ; cur = id
      IF ( id == 0 ) THEN
         ncalls = ncalls + 1
         IF ( MOD(ncalls, 20) == 0 ) WRITE(0,'(A,I6,A,5F11.3,A,2F11.3)') 'SEGTIME calls', ncalls, &
            ' out/dyn/phys/mp/diag', acc(0), acc(1), acc(2), acc(3), acc(4), ' xfer/part2', acc(5), acc(6)
      ENDIF
   END SUBROUTINE seg_mark
   ! nested interval charged to bucket id (5 host<->device updates, 6 part2), then back to the enclosing segment
   SUBROUTINE seg_enter( id )
      INTEGER, INTENT(IN) :: id
      INTEGER :: c
      c = cur
      CALL seg_mark( id )
      prev_seg = c
   END SUBROUTINE seg_enter
   SUBROUTINE seg_leave()
!$acc wait
      CALL seg_mark( prev_seg )
   END SUBROUTINE seg_leave
END MODULE wrf_seg_timers
#endif
SUBROUTINE solve_em ( grid , config_flags  &
! Arguments generated from Registry
#include "dummy_new_args.inc"
!
                    )
! Driver layer modules
   USE module_state_description
   USE module_domain, ONLY : &
                  domain, get_ijk_from_grid, get_ijk_from_subgrid                          &
                 ,domain_get_current_time, domain_get_start_time                           &
                 ,domain_get_sim_start_time, domain_clock_get,is_alarm_tstep
   USE module_domain_type, ONLY : history_alarm, restart_alarm, auxinput4_alarm            &
                 ,boundary_alarm
   USE module_configure, ONLY : grid_config_rec_type
   USE module_driver_constants
   USE module_machine
   USE module_tiles, ONLY : set_tiles
#ifdef DM_PARALLEL
   USE module_dm, ONLY : &
                  local_communicator, mytask, ntasks, ntasks_x, ntasks_y                   &
                 ,local_communicator_periodic, wrf_dm_maxval
   USE module_comm_dm, ONLY : &
                  halo_em_a_sub,halo_em_b_sub,halo_em_c2_sub,halo_em_chem_e_3_sub          &
                 ,halo_em_chem_e_5_sub,halo_em_chem_e_7_sub,halo_em_chem_old_e_5_sub       &
                 ,halo_em_chem_old_e_7_sub,halo_em_c_sub,halo_em_d2_3_sub                  &
                 ,halo_em_d2_5_sub,halo_em_d3_3_sub,halo_em_d3_5_sub,halo_em_d_sub         &
                 ,halo_em_e_3_sub,halo_em_e_5_sub,halo_em_hydro_uv_sub                     &
                 ,halo_em_moist_e_3_sub,halo_em_moist_e_5_sub,halo_em_moist_e_7_sub        &
                 ,halo_em_moist_old_e_5_sub,halo_em_moist_old_e_7_sub                      &
                 ,halo_em_scalar_e_3_sub,halo_em_scalar_e_5_sub,halo_em_scalar_e_7_sub     &
                 ,halo_em_scalar_old_e_5_sub,halo_em_scalar_old_e_7_sub,halo_em_tke_3_sub  &
                 ,halo_em_tke_5_sub,halo_em_tke_7_sub,halo_em_tke_advect_3_sub             &
                 ,halo_em_tke_advect_5_sub,halo_em_tke_old_e_5_sub                         &
                 ,halo_em_tke_old_e_7_sub,halo_em_tracer_e_3_sub,halo_em_tracer_e_5_sub    &
                 ,halo_em_tracer_e_7_sub,halo_em_tracer_old_e_5_sub                        &
                 ,halo_em_tracer_old_e_7_sub,halo_em_sbm_sub,period_bdy_em_a_sub                           &
                 ,period_bdy_em_b3_sub,period_bdy_em_b_sub,period_bdy_em_chem2_sub         &
                 ,period_bdy_em_chem_old_sub,period_bdy_em_chem_sub,period_bdy_em_d3_sub   &
                 ,period_bdy_em_d_sub,period_bdy_em_e_sub,period_bdy_em_moist2_sub         &
                 ,period_bdy_em_moist_old_sub,period_bdy_em_moist_sub                      &
                 ,period_bdy_em_scalar2_sub,period_bdy_em_scalar_old_sub                   &
                 ,period_bdy_em_scalar_sub,period_bdy_em_tke_old_sub, period_bdy_em_tke_sub  &
                 ,period_bdy_em_tracer2_sub,period_bdy_em_tracer_old_sub                   &
                 ,period_bdy_em_tracer_sub,period_em_da_sub,period_em_hydro_uv_sub         &
                 ,period_em_f_sub,period_em_g_sub                                          &
                 ,halo_em_f_1_sub,halo_em_init_4_sub,halo_em_thetam_sub,period_em_thetam_sub &
                 ,halo_em_d_pv_sub,halo_firebrand_spotting_5_sub
#endif
   USE module_utility
! Mediation layer modules
! Model layer modules
   USE module_model_constants
   USE module_small_step_em
   USE module_em
   USE module_big_step_utilities_em
   USE module_bc
   USE module_bc_em
   USE module_solvedebug_em
   USE module_physics_addtendc
   USE module_diffusion_em
   USE module_polarfft
   USE module_microphysics_driver
   USE module_microphysics_zero_out
!   USE module_lightning_driver, ONLY : lightning_driver
   USE module_fddaobs_driver
!   USE module_diagnostics
#if (WRF_CHEM == 1)
   USE module_input_chem_data
   USE module_input_tracer
   USE module_chem_utilities
#endif
   USE module_dust_emis
   USE module_first_rk_step_part1
   USE module_first_rk_step_part2
   USE module_after_all_rk_steps
#ifdef WRF_SEG_TIMERS
   USE wrf_seg_timers
#endif
#ifdef WRF_GPU
   USE module_wrf_error, ONLY : wrf_gpu_on, wrf_gpu_q
   USE module_bc, ONLY : wrf_gpu_xw_skip
#ifdef WRF_GPU_RESIDENT
   USE module_radiation_driver, ONLY : wrf_gpu_ra_ran, wrf_gpu_ra_pullre, wrf_gpu_ra_lw, wrf_gpu_ra_sw, wrf_gpu_lean_step
#ifdef WRF_GPU_RESIDENT
   USE module_diag_afwa, ONLY : afwa_time_flags
#endif
   USE module_diagnostics_driver, ONLY : wrf_gpu_diag
   USE module_surface_driver, ONLY : wrf_gpu_sfc, wrf_gpu_lsm
   USE module_cumulus_driver, ONLY : wrf_gpu_cu_ran, wrf_gpu_cu_pullbl, wrf_gpu_cu, wrf_gpu_cu_dev_ran
   USE module_pbl_driver, ONLY : wrf_gpu_bl_ran, wrf_gpu_pbl, wrf_gpu_pbl_ran
#endif
#endif
   USE module_llxy, ONLY : proj_cassini
   USE module_avgflx_em, ONLY : zero_avgflx, upd_avgflx
   USE module_cpl, ONLY : coupler_on, cpl_settime, cpl_store_input

#if (WRF_CMAQ == 1)
   use twoway_data_module
#endif
   USE module_firebrand_spotting, ONLY : firebrand_spotting_em_driver

   IMPLICIT NONE

   !  Input data.

   TYPE(domain) , TARGET          :: grid

   !  Definitions of dummy arguments to this routine (generated from Registry).
#include "dummy_new_decl.inc"

   !  Structure that contains run-time configuration (namelist) data for domain
   TYPE (grid_config_rec_type) , INTENT(IN)          :: config_flags

   ! Local data

   INTEGER                         :: k_start , k_end, its, ite, jts, jte
   INTEGER                         :: ids , ide , jds , jde , kds , kde , &
                                      ims , ime , jms , jme , kms , kme , &
                                      ips , ipe , jps , jpe , kps , kpe

   INTEGER                         :: sids , side , sjds , sjde , skds , skde , &
                                      sims , sime , sjms , sjme , skms , skme , &
                                      sips , sipe , sjps , sjpe , skps , skpe


   INTEGER ::              imsx, imex, jmsx, jmex, kmsx, kmex,    &
                           ipsx, ipex, jpsx, jpex, kpsx, kpex,    &
                           imsy, imey, jmsy, jmey, kmsy, kmey,    &
                           ipsy, ipey, jpsy, jpey, kpsy, kpey

   INTEGER                         :: ij , iteration
   INTEGER                         :: im , num_3d_m , ic , num_3d_c , is , num_3d_s
   INTEGER                         :: loop
   INTEGER                         :: sz
   INTEGER                         :: iswater

   LOGICAL                         :: specified_bdy, channel_bdy

   REAL                            :: t_new, time_duration_of_lbcs
   
! begin WRF-CMAQ twoway coupled model block
   integer       :: twoway_jdate,    &  ! CMAQ current job date
                    twoway_jtime,    &  ! CMAQ current job time
                    met_file_tstep      ! MCIP like MET file time step

   integer, save :: cmaq_nstep,      &  ! total number of CMAQ steps
                    wrf_end_step,    &  ! WRF ending step #
                    counter = -1,    &  ! step counter
                    wrf_cmaq_freq,   &  ! call frequency between WRF and CMAQ
                    wrf_cmaq_option     ! WRF-CMAQ coupled model option
                                        ! 0 = run WRF only
                                        ! 1 = run WRF only               w   producing MCIP like GRID and MET files
                                        ! 2 = run WRF-CMAQ coupled model w/o producing MCIP like GRID and MET files
                                        ! 3 = run WRF-CMAQ coupled model w   producing MCIP like GRID and MET files

   logical       :: cmaq_step           ! CMAQ step number

   logical, save :: firstime = .true.,   &  ! logical variable indicating first time
                    feedback_is_ready,   &  ! logical variable indicating feedback process can proceed
                    feedback_restart,    &  ! logical variable indicating feedback information is available
                    direct_sw_feedback      ! logical variable indicating direct aerosol sw feedback is on or not
! end WRF-CMAQ twoway coupled model block

   ! Changes in tendency at this timestep
   real ,DIMENSION(grid%sm31:grid%em31,grid%sm32:grid%em32,grid%sm33:grid%em33) :: h_tendency, &
                                                                                   z_tendency
                                                                                   
   ! Whether advection should produce decoupled horizontal and vertical advective tendency outputs
   LOGICAL                        :: tenddec
   
   ! Flag for producing diagnostic fields (e.g., radar reflectivity)
   LOGICAL                        :: diag_flag
   INTEGER                        :: ke_diag ! tells reflectivity calculation whether to do full depth or only k=1
   LOGICAL                        :: restart_flag !  tells if it is a restart timestep to write restart files. 
   
#if (WRF_CHEM == 1)
   ! Index cross-referencing array for tendency accumulation
   INTEGER, DIMENSION( num_chem ) :: adv_ct_indices
#endif

! storage for tendencies and decoupled state (generated from Registry)

#ifdef WRF_GPU
! GPU: persistent i1 temporaries (per-call automatic arrays churn the managed-memory pool)
#include "i1_decl_gpu.inc"
#else
#include "i1_decl.inc"
#endif
! Previous time level of tracer arrays now defined as i1 variables;
! the state 4d arrays now redefined as 1-time level arrays in Registry.
! Benefit: save memory in nested runs, since only 1 domain is active at a
! time.  Potential problem on stack-limited architectures: increases
! amount of data on program stack by making these automatic arrays.

   INTEGER :: rc
#ifdef WRF_GPU
   LOGICAL, EXTERNAL :: wrf_gpu_addrmap
   LOGICAL, EXTERNAL :: wrf_gpu_hostblocks
   INTEGER, EXTERNAL :: wrf_gpu_fullsync
   INTEGER, EXTERNAL :: wrf_gpu_xfer
   ! WRF_GPU_XFER bit 16 (with 2+4): physics tendencies are GPU-owned between scheme calls - part2 couples them
   ! with mu on the GPU, phy_prep_part2 decouples them on the GPU; the host pushes a scheme's tendencies only on
   ! steps the scheme ran (rad/cu/pbl), plus cumulus ones after advance_ppt when an NCA countdown may zero them
   LOGICAL :: gpu_tend_dev = .FALSE., gpu_push_ra = .TRUE., gpu_push_cu = .TRUE., gpu_push_bl = .TRUE.
   LOGICAL :: gpu_push_cu2 = .TRUE.
   ! WRF_GPU_XFER bit 32 (with 16): the microphysics block (H2) runs on the GPU (Thompson only) - no H2 transfers;
   ! the host keeps advance_ppt (cumulus rain) and gets the mp outputs it reads (precip, effective radii) at H3
   LOGICAL :: gpu_mp_dev = .FALSE.
   ! bit 64: skip H1 pushes of the diffusion fields part2 recomputes on the GPU before reading them (diff_opt>=1:
   ! compute_diff_metrics z/rdz/rdzw/zx/zy, cal_deform_and_div div/defor*, calculate_km_kh xk*/bn2)
   ! bit 128: H1 does not re-pull the state the previous step's H3 pulled and the GPU has not changed since
   ! (u/v/w/t_2, rho, moist, scalar); alt/p/ph_2 (rk_step_prep, boundary setters) and mu*/rqvften still pulled
   LOGICAL :: gpu_skip_diff = .FALSE., gpu_h1_reuse = .FALSE.
   LOGICAL, SAVE :: gpu_h3_done = .FALSE., gpu_bdy_pushed = .FALSE.
   ! bit 256: after host part1, the GPU re-runs init_zero_tendency + phy_prep itself (both GPU-ported) instead of
   ! receiving the zeroed tendencies and the phy_prep fields (needs no host physics writing them: no PBL
   ! scalar/tracer mixing, no grid nudging)
   LOGICAL :: gpu_prep_dev = .FALSE.
   LOGICAL :: lean_rad, lean_h3, ld_after, ld_out, ld_first
   LOGICAL, EXTERNAL :: wrf_gpu_h1chk
   LOGICAL, EXTERNAL :: wrf_gpu_async_mode
   LOGICAL, EXTERNAL :: gpu_p8wchk
   DOUBLE PRECISION :: h1ck(2,10)
   INTEGER :: ick
   CHARACTER(LEN=8), PARAMETER :: h1ck_name(10) = (/ 'alt     ','p       ','ph_2    ','rho     ','t_2     ', &
                                                     'u_2     ','v_2     ','w_2     ','moist   ','scalar  ' /)
   INTEGER, EXTERNAL :: wrf_gpu_pin_mode
   INTEGER :: pin_nok, pin_nfail
   INTEGER(8) :: pin_tot
   LOGICAL, SAVE :: gpu_fs_have_host = .FALSE.
   INTEGER, EXTERNAL :: wrf_gpu_prefetch_mode
   INTEGER, EXTERNAL :: wrf_gpu_advise_mode
   LOGICAL, SAVE :: gpu_advised_grid = .FALSE.
#endif
#ifdef WRF_GPU_RESIDENT
   LOGICAL, SAVE :: gpu_resident_in = .FALSE.
#endif
   INTEGER :: number_of_small_timesteps, rk_step
   INTEGER :: klevel,ijm,ijp,i,j,k,size1,size2    ! for prints/plots only
   INTEGER :: idum1, idum2, dynamics_option

   INTEGER :: rk_order, iwmax, jwmax, kwmax
   REAL :: dt_rk, dts_rk, dts, dtm, wmax
   REAL , ALLOCATABLE , DIMENSION(:)  :: max_vert_cfl_tmp, max_horiz_cfl_tmp
   LOGICAL :: leapfrog
   INTEGER :: l,kte,kk
   LOGICAL :: f_flux  ! flag for computing averaged fluxes in cu_gd
   REAL    :: curr_secs, curr_secs2, curr_mins2
   REAL(8) :: curr_secs_r8, curr_secs2_r8
   INTEGER :: num_sound_steps
   INTEGER :: idex, jdex
   REAL    :: max_msft
   REAL    :: spacing

   INTEGER :: ii, jj !kk is above after l,kte
   REAL    :: dclat
   INTEGER :: debug_level

! urban related variables
   INTEGER :: NUM_ROOF_LAYERS, NUM_WALL_LAYERS, NUM_ROAD_LAYERS   ! urban

   TYPE(WRFU_TimeInterval)                    :: tmpTimeInterval, tmpTimeInterval2
   REAL                                       :: real_time
   REAL(8)                                    :: real_time_r8
   LOGICAL                                    :: adapt_step_flag
   LOGICAL                                    :: fill_w_flag

! variables for flux-averaging code 20091223
   CHARACTER*256                              :: message, message2, message3
   REAL                                       :: old_dt
   TYPE(WRFU_Time)                            :: temp_time, CurrTime, restart_time
   INTEGER, PARAMETER                         :: precision = 100
   INTEGER                                    :: num, den
   TYPE(WRFU_TimeInterval)                    :: dtInterval, intervaltime,restartinterval

#if (WRF_CMAQ == 1)
   interface
      SUBROUTINE CMAQ_DRIVER ( MODEL_STDATE, MODEL_STTIME, MODEL_TSTEP,  &
                               MODEL_JDATE, MODEL_JTIME, LAST_STEP,      &
                               COUPLE_TSTEP, NCOLS_IN, NLAYS_IN)
        INTEGER, INTENT( IN )  :: MODEL_STDATE, MODEL_STTIME, MODEL_TSTEP
        INTEGER, INTENT( OUT ) :: MODEL_JDATE, MODEL_JTIME
        LOGICAL, INTENT( IN )  :: LAST_STEP
        INTEGER, INTENT( IN ), OPTIONAL :: COUPLE_TSTEP
        INTEGER, INTENT( IN ), OPTIONAL :: NCOLS_IN, NLAYS_IN
      END SUBROUTINE CMAQ_DRIVER
   end interface
#endif

#ifdef CORDEXDIAG
   INTEGER                                               :: i2, j2, k2
   INTEGER                                               :: ix, iy, iz
#endif

! Define benchmarking timers if -DBENCH is compiled
#include "bench_solve_em_def.h"

!----------------------
! Executable statements
!----------------------

!<DESCRIPTION>
!<pre>
! solve_em is the main driver for advancing a grid a single timestep.
! It is a mediation-layer routine -> DM and SM calls are made where 
! needed for parallel processing.  
!
! solve_em can integrate the equations using 3 time-integration methods
!      
!    - 3rd order Runge-Kutta time integration (recommended)
!      
!    - 2nd order Runge-Kutta time integration
!      
! The main sections of solve_em are
!     
! (1) Runge-Kutta (RK) loop
!     
! (2) Non-timesplit physics (i.e., tendencies computed for updating
!     model state variables during the first RK sub-step (loop)
!     
! (3) Small (acoustic, sound) timestep loop - within the RK sub-steps
!     
! (4) scalar advance for moist and chem scalar variables (and TKE)
!     within the RK sub-steps.
!     
! (5) time-split physics (after the RK step), currently this includes
!     only microphyics
!
! A more detailed description of these sections follows.
!</pre>
!</DESCRIPTION>

! Initialize timers if compiled with -DBENCH
#include "bench_solve_em_init.h"

#if (WRF_CMAQ == 1)
   if (firstime) then
      CALL nl_get_feedback_restart ( .false., feedback_restart )
      if (feedback_restart) then
         feedback_is_ready = .true.
      else
         feedback_is_ready = .false.
      end if
   end if
#else
   feedback_is_ready = .false.
#endif

!  set runge-kutta solver (2nd or 3rd order)

   dynamics_option = config_flags%rk_ord

!  Obtain dimension information stored in the grid data structure.

   CALL get_ijk_from_grid (  grid ,                   &
                             ids, ide, jds, jde, kds, kde,    &
                             ims, ime, jms, jme, kms, kme,    &
                             ips, ipe, jps, jpe, kps, kpe,    &
                             imsx, imex, jmsx, jmex, kmsx, kmex,    &
                             ipsx, ipex, jpsx, jpex, kpsx, kpex,    &
                             imsy, imey, jmsy, jmey, kmsy, kmey,    &
                             ipsy, ipey, jpsy, jpey, kpsy, kpey )
 
   CALL get_ijk_from_subgrid (  grid ,                   &
                             sids, side, sjds, sjde, skds, skde,    &
                             sims, sime, sjms, sjme, skms, skme,    &
                             sips, sipe, sjps, sjpe, skps, skpe    )
   k_start         = kps
   k_end           = kpe

   num_3d_m        = num_moist
   num_3d_c        = num_chem
   num_3d_s        = num_scalar

!  backward integration needs to advect only QV
   if (grid%dfi_stage .EQ. DFI_BCK) then
       num_3d_m    = P_QV
       num_3d_s    = PARAM_FIRST_SCALAR - 1
   endif

   f_flux = config_flags%do_avgflx_cugd .EQ. 1

!  Compute these starting and stopping locations for each tile and number of tiles.
!  See: https://www2.mmm.ucar.edu/wrf/WG2/topics/settiles
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 1 )
#endif
#ifdef WRF_GPU
#  include "i1_alloc_gpu.inc"
#endif
#ifdef WRF_GPU
   IF ( wrf_gpu_addrmap() ) THEN
      CALL wrf_gpu_addrmap_grid( grid )
      IF ( ALLOCATED(ru_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ru_tendf', LOC(ru_tendf), INT(SIZE(ru_tendf),8)*INT(STORAGE_SIZE(ru_tendf)/8,8)
      IF ( ALLOCATED(rv_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'rv_tendf', LOC(rv_tendf), INT(SIZE(rv_tendf),8)*INT(STORAGE_SIZE(rv_tendf)/8,8)
      IF ( ALLOCATED(ww1) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ww1', LOC(ww1), INT(SIZE(ww1),8)*INT(STORAGE_SIZE(ww1)/8,8)
      IF ( ALLOCATED(wwe) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'wwe', LOC(wwe), INT(SIZE(wwe),8)*INT(STORAGE_SIZE(wwe)/8,8)
      IF ( ALLOCATED(wwi) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'wwi', LOC(wwi), INT(SIZE(wwi),8)*INT(STORAGE_SIZE(wwi)/8,8)
      IF ( ALLOCATED(wwp) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'wwp', LOC(wwp), INT(SIZE(wwp),8)*INT(STORAGE_SIZE(wwp)/8,8)
      IF ( ALLOCATED(rw_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'rw_tend', LOC(rw_tend), INT(SIZE(rw_tend),8)*INT(STORAGE_SIZE(rw_tend)/8,8)
      IF ( ALLOCATED(rw_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'rw_tendf', LOC(rw_tendf), INT(SIZE(rw_tendf),8)*INT(STORAGE_SIZE(rw_tendf)/8,8)
      IF ( ALLOCATED(w_save) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'w_save', LOC(w_save), INT(SIZE(w_save),8)*INT(STORAGE_SIZE(w_save)/8,8)
      IF ( ALLOCATED(ph_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ph_tend', LOC(ph_tend), INT(SIZE(ph_tend),8)*INT(STORAGE_SIZE(ph_tend)/8,8)
      IF ( ALLOCATED(ph_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ph_tendf', LOC(ph_tendf), INT(SIZE(ph_tendf),8)*INT(STORAGE_SIZE(ph_tendf)/8,8)
      IF ( ALLOCATED(ph_save) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ph_save', LOC(ph_save), INT(SIZE(ph_save),8)*INT(STORAGE_SIZE(ph_save)/8,8)
      IF ( ALLOCATED(t_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 't_tend', LOC(t_tend), INT(SIZE(t_tend),8)*INT(STORAGE_SIZE(t_tend)/8,8)
      IF ( ALLOCATED(t_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 't_tendf', LOC(t_tendf), INT(SIZE(t_tendf),8)*INT(STORAGE_SIZE(t_tendf)/8,8)
      IF ( ALLOCATED(t_2save) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 't_2save', LOC(t_2save), INT(SIZE(t_2save),8)*INT(STORAGE_SIZE(t_2save)/8,8)
      IF ( ALLOCATED(muave) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'muave', LOC(muave), INT(SIZE(muave),8)*INT(STORAGE_SIZE(muave)/8,8)
      IF ( ALLOCATED(mu_save) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'mu_save', LOC(mu_save), INT(SIZE(mu_save),8)*INT(STORAGE_SIZE(mu_save)/8,8)
      IF ( ALLOCATED(mu_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'mu_tend', LOC(mu_tend), INT(SIZE(mu_tend),8)*INT(STORAGE_SIZE(mu_tend)/8,8)
      IF ( ALLOCATED(mu_tendf) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'mu_tendf', LOC(mu_tendf), INT(SIZE(mu_tendf),8)*INT(STORAGE_SIZE(mu_tendf)/8,8)
      IF ( ALLOCATED(tke_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'tke_tend', LOC(tke_tend), INT(SIZE(tke_tend),8)*INT(STORAGE_SIZE(tke_tend)/8,8)
      IF ( ALLOCATED(advect_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'advect_tend', LOC(advect_tend), INT(SIZE(advect_tend),8)*INT(STORAGE_SIZE(advect_tend)/8,8)
      IF ( ALLOCATED(alpha) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'alpha', LOC(alpha), INT(SIZE(alpha),8)*INT(STORAGE_SIZE(alpha)/8,8)
      IF ( ALLOCATED(a) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'a', LOC(a), INT(SIZE(a),8)*INT(STORAGE_SIZE(a)/8,8)
      IF ( ALLOCATED(gamma) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'gamma', LOC(gamma), INT(SIZE(gamma),8)*INT(STORAGE_SIZE(gamma)/8,8)
      IF ( ALLOCATED(c2a) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'c2a', LOC(c2a), INT(SIZE(c2a),8)*INT(STORAGE_SIZE(c2a)/8,8)
      IF ( ALLOCATED(phm) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'phm', LOC(phm), INT(SIZE(phm),8)*INT(STORAGE_SIZE(phm)/8,8)
      IF ( ALLOCATED(cqu) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'cqu', LOC(cqu), INT(SIZE(cqu),8)*INT(STORAGE_SIZE(cqu)/8,8)
      IF ( ALLOCATED(cqv) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'cqv', LOC(cqv), INT(SIZE(cqv),8)*INT(STORAGE_SIZE(cqv)/8,8)
      IF ( ALLOCATED(cqw) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'cqw', LOC(cqw), INT(SIZE(cqw),8)*INT(STORAGE_SIZE(cqw)/8,8)
      IF ( ALLOCATED(pm1) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'pm1', LOC(pm1), INT(SIZE(pm1),8)*INT(STORAGE_SIZE(pm1)/8,8)
      IF ( ALLOCATED(psim) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'psim', LOC(psim), INT(SIZE(psim),8)*INT(STORAGE_SIZE(psim)/8,8)
      IF ( ALLOCATED(psih) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'psih', LOC(psih), INT(SIZE(psih),8)*INT(STORAGE_SIZE(psih)/8,8)
      IF ( ALLOCATED(gz1oz0) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'gz1oz0', LOC(gz1oz0), INT(SIZE(gz1oz0),8)*INT(STORAGE_SIZE(gz1oz0)/8,8)
      IF ( ALLOCATED(chklowq) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'chklowq', LOC(chklowq), INT(SIZE(chklowq),8)*INT(STORAGE_SIZE(chklowq)/8,8)
      IF ( ALLOCATED(ht_loc) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'ht_loc', LOC(ht_loc), INT(SIZE(ht_loc),8)*INT(STORAGE_SIZE(ht_loc)/8,8)
      IF ( ALLOCATED(th_phy) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'th_phy', LOC(th_phy), INT(SIZE(th_phy),8)*INT(STORAGE_SIZE(th_phy)/8,8)
      IF ( ALLOCATED(pi_phy) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'pi_phy', LOC(pi_phy), INT(SIZE(pi_phy),8)*INT(STORAGE_SIZE(pi_phy)/8,8)
      IF ( ALLOCATED(p_phy) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'p_phy', LOC(p_phy), INT(SIZE(p_phy),8)*INT(STORAGE_SIZE(p_phy)/8,8)
      IF ( ALLOCATED(dz8w) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'dz8w', LOC(dz8w), INT(SIZE(dz8w),8)*INT(STORAGE_SIZE(dz8w)/8,8)
      IF ( ALLOCATED(p8w) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'p8w', LOC(p8w), INT(SIZE(p8w),8)*INT(STORAGE_SIZE(p8w)/8,8)
      IF ( ALLOCATED(t8w) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 't8w', LOC(t8w), INT(SIZE(t8w),8)*INT(STORAGE_SIZE(t8w)/8,8)
      IF ( ALLOCATED(cu_act_flag) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'cu_act_flag', LOC(cu_act_flag), INT(SIZE(cu_act_flag),8)*INT(STORAGE_SIZE(cu_act_flag)/8,8)
      IF ( ALLOCATED(hol) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'hol', LOC(hol), INT(SIZE(hol),8)*INT(STORAGE_SIZE(hol)/8,8)
      IF ( ALLOCATED(moist_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'moist_tend', LOC(moist_tend), INT(SIZE(moist_tend),8)*INT(STORAGE_SIZE(moist_tend)/8,8)
      IF ( ALLOCATED(moist_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'moist_old', LOC(moist_old), INT(SIZE(moist_old),8)*INT(STORAGE_SIZE(moist_old)/8,8)
      IF ( ALLOCATED(dfi_moist_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'dfi_moist_tend', LOC(dfi_moist_tend), INT(SIZE(dfi_moist_tend),8)*INT(STORAGE_SIZE(dfi_moist_tend)/8,8)
      IF ( ALLOCATED(dfi_moist_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'dfi_moist_old', LOC(dfi_moist_old), INT(SIZE(dfi_moist_old),8)*INT(STORAGE_SIZE(dfi_moist_old)/8,8)
      IF ( ALLOCATED(scalar_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'scalar_tend', LOC(scalar_tend), INT(SIZE(scalar_tend),8)*INT(STORAGE_SIZE(scalar_tend)/8,8)
      IF ( ALLOCATED(scalar_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'scalar_old', LOC(scalar_old), INT(SIZE(scalar_old),8)*INT(STORAGE_SIZE(scalar_old)/8,8)
      IF ( ALLOCATED(dfi_scalar_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'dfi_scalar_tend', LOC(dfi_scalar_tend), INT(SIZE(dfi_scalar_tend),8)*INT(STORAGE_SIZE(dfi_scalar_tend)/8,8)
      IF ( ALLOCATED(dfi_scalar_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'dfi_scalar_old', LOC(dfi_scalar_old), INT(SIZE(dfi_scalar_old),8)*INT(STORAGE_SIZE(dfi_scalar_old)/8,8)
      IF ( ALLOCATED(tracer_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'tracer_tend', LOC(tracer_tend), INT(SIZE(tracer_tend),8)*INT(STORAGE_SIZE(tracer_tend)/8,8)
      IF ( ALLOCATED(tracer_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'tracer_old', LOC(tracer_old), INT(SIZE(tracer_old),8)*INT(STORAGE_SIZE(tracer_old)/8,8)
      IF ( ALLOCATED(chem_tend) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'chem_tend', LOC(chem_tend), INT(SIZE(chem_tend),8)*INT(STORAGE_SIZE(chem_tend)/8,8)
      IF ( ALLOCATED(chem_old) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP i1:', 'chem_old', LOC(chem_old), INT(SIZE(chem_old),8)*INT(STORAGE_SIZE(chem_old)/8,8)
   ENDIF
#endif
   CALL set_tiles ( ZONE_SOLVE_EM, grid , ids , ide , jds , jde , ips , ipe , jps , jpe )
!   CALL set_tiles (  grid , ids , ide , jds , jde , ips , ipe , jps , jpe )

#ifdef WRF_GPU
   ! GPU: managed-memory placement advice (WRF_GPU_ADVISE); grid arrays once, i1 temporaries every call
   IF ( wrf_gpu_advise_mode() /= 0 ) THEN
      IF ( .NOT. gpu_advised_grid ) THEN
         CALL wrf_gpu_advise_grid( grid ) ; gpu_advised_grid = .TRUE.
      ENDIF
#     include "gpu_advise_i1.inc"
   ENDIF
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   CALL rsl_set_gpu_managed( .TRUE. )   ! managed memory: halo pack/unpack on the device
#endif
#ifdef WRF_GPU_RESIDENT
   ! GPU residency (-gpu=mem:separate): grid fields used by the dynamics live on the device for the whole run.
   ! Host blocks (physics, microphysics, after_all_rk_steps) run with wrf_gpu_on=.false. and are bracketed by
   ! update self / update device of the fields the GPU writes / the block writes (lists from the field trace).
   IF ( .NOT. gpu_resident_in ) THEN
#     include "gpu_enter_data.inc"
      gpu_resident_in = .TRUE.
      CALL wrf_message( 'GPU residency: grid fields entered on the device' )
      wrf_gpu_q = -1 ; IF ( wrf_gpu_async_mode() ) wrf_gpu_q = 1
      IF ( wrf_gpu_pin_mode() /= 0 ) THEN
         CALL wrf_gpu_pin_grid( grid )
#        include "gpu_pin_i1.inc"
         CALL wrf_gpu_pin_flush()
      ENDIF
   ENDIF
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   ! bit 4096: the lateral-boundary arrays only change when boundary data are read (dtbc reset to 0 there):
   ! push them on the first step and after each boundary read instead of every step
   IF ( IAND( wrf_gpu_xfer(), 4096 ) == 0 .OR. .NOT. gpu_bdy_pushed .OR. grid%dtbc == 0. ) THEN
#  include "gpu_upd_dev_bdy.inc"
   gpu_bdy_pushed = .TRUE.
   ENDIF
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
#endif
#ifdef WRF_GPU_RESIDENT
   ! WRF_GPU_FULLSYNC=7 (diagnostic): host copies were made current at the end of the previous solve_em; push them
   ! all so that anything the host changed between solve_em calls reaches the device
   IF ( IAND( wrf_gpu_fullsync(), 7 ) == 7 .AND. gpu_fs_have_host ) THEN
#    include "gpu_sync_dev_all.inc"
   ENDIF
#endif
#ifdef WRF_GPU_RESIDENT
   ! automatic (per-call) work arrays used inside compute regions: device copies for this call only
!$acc enter data create(h_tendency, z_tendency)
!$acc kernels present(h_tendency)
      h_tendency = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
!$acc kernels present(z_tendency)
      z_tendency = 0   ! device copy starts zeroed (pool memory is not)
!$acc end kernels
#endif

!  Max values of CFL for adaptive time step scheme

   ALLOCATE (max_vert_cfl_tmp(grid%num_tiles))
   ALLOCATE (max_horiz_cfl_tmp(grid%num_tiles))

  !
  ! Calculate current time in seconds since beginning of model run.
  !   Unfortunately, ESMF does not seem to have a way to return
  !   floating point seconds based on a TimeInterval.  So, we will
  !   calculate it here--but, this is not clean!!
  !
   tmpTimeInterval  = domain_get_current_time ( grid ) - domain_get_sim_start_time ( grid )
   tmpTimeInterval2 = domain_get_current_time ( grid ) - domain_get_start_time ( grid )
   curr_secs  = real_time(tmpTimeInterval)
   curr_secs2 = real_time(tmpTimeInterval2)
   curr_secs_r8  = real_time_r8(tmpTimeInterval)
   curr_secs2_r8 = real_time_r8(tmpTimeInterval2)
   curr_mins2 = REAL( curr_secs2_r8 / 60.0d0 )

   old_dt = grid%dt   ! store old time step for flux averaging code at end of RK loop

!-----------------------------------------------------------------------------
! Adaptive time step: Added by T. Hutchinson, WSI  3/5/07
!   In this call, we do the time-step adaptation and set time-dependent lateral
!   boundary condition nudging weights.
!
   IF ( (config_flags%use_adaptive_time_step) .and. &
        ( (.not. grid%nested) .or. &
        ( (grid%nested) .and. (abs(grid%dtbc) < 0.0001) ) ) )THEN
      CALL adapt_timestep(grid, config_flags)
#ifdef WRF_GPU_RESIDENT
      ! adapt_timestep (host) recomputed the lateral-boundary nudging weights for this step's dt
!$acc update device(grid%fcx) if(associated(grid%fcx))
!$acc update device(grid%gcx) if(associated(grid%gcx))
#endif
      adapt_step_flag = .TRUE.
   ELSE
      adapt_step_flag = .FALSE.
   ENDIF
! End of adaptive time step modifications
!-----------------------------------------------------------------------------
!
! Set restart flag value history output time
!-----------------------------------------------------------------------------
   restart_flag = .false.
   if ( Is_alarm_tstep(grid%domain_clock, grid%alarms(restart_alarm)) ) then
      restart_flag = .true.
   endif
!
! Set diagnostic flag value history output time
!-----------------------------------------------------------------------------

   ke_diag = kms ! default to ke_diag=1 in case of nwp_diagnostics == 1
   diag_flag = .false.
   if ( Is_alarm_tstep(grid%domain_clock, grid%alarms(HISTORY_ALARM)) ) then
      diag_flag = .true.
      ke_diag = min(k_end,kde-1) ! set depth to full domain for reflectivity field
   endif
   IF (config_flags%nwp_diagnostics == 1) diag_flag = .true.

   grid%itimestep = grid%itimestep + 1
   grid%dtbc = grid%dtbc + grid%dt

   IF( coupler_on ) CALL cpl_store_input( grid, config_flags )

   IF (config_flags%polar) dclat = 90./REAL(jde-jds) !(0.5 * 180/ny)

#if (WRF_CHEM == 1)

   kte=min(k_end,kde-1)
# ifdef DM_PARALLEL
   if ( num_chem >= PARAM_FIRST_SCALAR ) then
!-----------------------------------------------------------------------
! see matching halo calls below for stencils
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_CHEM' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_CHEM_E_3.inc"
       IF( config_flags%progn > 0 ) THEN
#         include "HALO_EM_SCALAR_E_3.inc"
       ENDIF
       IF( config_flags%cu_physics == CAMZMSCHEME ) THEN
#         include "HALO_EM_SCALAR_E_3.inc"
       ENDIF
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_CHEM_E_5.inc"
       IF( config_flags%cu_physics == CAMZMSCHEME ) THEN
#         include "HALO_EM_SCALAR_E_5.inc"
       ENDIF
       IF( config_flags%progn > 0 ) THEN
#         include "HALO_EM_SCALAR_E_5.inc"
      ENDIF
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
   if ( num_tracer >= PARAM_FIRST_SCALAR ) then
!-----------------------------------------------------------------------
! see matching halo calls below for stencils
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_tracer' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_TRACER_E_3.inc"
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_TRACER_E_5.inc"
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
# endif
!--------------------------------------------------------------
   adv_ct_indices(   :  ) = 1
   IF ( config_flags%chemdiag == USECHEMDIAG ) THEN
   ! modify tendency list here
   ! note that the referencing direction here is opposite of that in chem_driver
       adv_ct_indices(p_co  ) = p_advh_co
       adv_ct_indices(p_o3  ) = p_advh_o3
       adv_ct_indices(p_no  ) = p_advh_no
       adv_ct_indices(p_no2 ) = p_advh_no2
       adv_ct_indices(p_hno3) = p_advh_hno3
       adv_ct_indices(p_iso ) = p_advh_iso
       adv_ct_indices(p_ho  ) = p_advh_ho
       adv_ct_indices(p_ho2 ) = p_advh_ho2
   END IF
#endif

   rk_order = config_flags%rk_ord

   IF ( grid%time_step_sound == 0 ) THEN
! This function will give 4 for 6*dx and 6 for 10*dx and returns even numbers only
     spacing = min(grid%dx, grid%dy)
     IF ( ( config_flags%use_adaptive_time_step ) .AND. ( config_flags%map_proj == PROJ_CASSINI ) ) THEN
       max_msft=MIN ( MAX(grid%max_msftx, grid%max_msfty) , &
                      1.0/COS(config_flags%fft_filter_lat*degrad) )
       num_sound_steps = max ( 2 * ( INT (300. * grid%dt / (spacing / max_msft) - 0.01 ) + 1 ), 4 )
     ELSE IF  ( config_flags%use_adaptive_time_step ) THEN
       max_msft= MAX(grid%max_msftx, grid%max_msfty)
       num_sound_steps = max ( 2 * ( INT (300. * grid%dt / (spacing / max_msft) - 0.01 ) + 1 ), 4 )
     ELSE
       num_sound_steps = max ( 2 * ( INT (300. * grid%dt /  spacing             - 0.01 ) + 1 ), 4 )
     END IF
     WRITE(wrf_err_message,*)'grid spacing, dt, time_step_sound=',spacing,grid%dt,num_sound_steps
     CALL wrf_debug ( 50 , wrf_err_message )
   ELSE
     num_sound_steps = grid%time_step_sound
   ENDIF

   dts = grid%dt/float(num_sound_steps)

   IF (config_flags%use_adaptive_time_step) THEN
  
     CALL get_wrf_debug_level( debug_level )
     IF ((config_flags%time_step < 0) .AND. (debug_level.GE.50)) THEN
#ifdef DM_PARALLEL
       CALL wrf_dm_maxval(grid%max_vert_cfl, idex, jdex)
#endif
       WRITE(wrf_err_message,*)'variable dt, max horiz cfl, max vert cfl: ',&
            grid%dt, grid%max_horiz_cfl, grid%max_vert_cfl
       CALL wrf_debug ( 0 , wrf_err_message )
     ENDIF

     grid%max_cfl_val = 0
     grid%max_horiz_cfl = 0
     grid%max_vert_cfl = 0
   ENDIF

! setting bdy tendencies to zero for DFI if constant_bc = true

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

!      IF( config_flags%specified .AND. grid%dfi_opt .NE. DFI_NODFI   &
!          .AND. config_flags%constant_bc .AND. (grid%dfi_stage .EQ. DFI_BCK .OR. grid%dfi_stage .EQ. DFI_FWD) ) THEN
       IF( config_flags%specified .AND. config_flags%constant_bc ) THEN

       CALL zero_bdytend (grid%u_btxs,grid%u_btxe,grid%u_btys,grid%u_btye,     &
                          grid%v_btxs,grid%v_btxe,grid%v_btys,grid%v_btye,     &
                          grid%ph_btxs,grid%ph_btxe,grid%ph_btys,grid%ph_btye, &
                          grid%t_btxs,grid%t_btxe,grid%t_btys,grid%t_btye,     &
                          grid%w_btxs,grid%w_btxe,grid%w_btys,grid%w_btye,     &
                          grid%mu_btxs,grid%mu_btxe,grid%mu_btys,grid%mu_btye, &
                          moist_btxs,moist_btxe,                               &
                          moist_btys,moist_btye,                               &
                          scalar_btxs,scalar_btxe,                              &
                          scalar_btys,scalar_btye,                              &
                          grid%spec_bdy_width,num_3d_m,num_3d_s,                &
                          ids,ide, jds,jde, kds,kde,                   &
                          ims,ime, jms,jme, kms,kme,                   &
                          ips,ipe, jps,jpe, kps,kpe,                   &
                          grid%i_start(ij), grid%i_end(ij),            &
                          grid%j_start(ij), grid%j_end(ij),            &
                          k_start, k_end                               )

       ENDIF

       !  If the user has requested to optionally select the moist theta (use_theta_m==1)
       !  switch, the first setting of the "old" value of theta_m uses the "old"
       !  value of Qv.  The moist_old variable does not exist until after the advection
       !  towards the end of the RK loop.  For the first time in the RK loop, we need
       !  a reasonable value for moist_old.

       CALL initialize_moist_old ( moist_old(:,:,:,P_Qv),              &
                          moist(:,:,:,P_Qv) ,                          &
                          ids,ide, jds,jde, kds,kde,                   &
                          ims,ime, jms,jme, kms,kme,                   &
                          grid%i_start(ij), grid%i_end(ij),            &
                          grid%j_start(ij), grid%j_end(ij),            &
                          k_start, k_end                               )
     ENDDO
     !$OMP END PARALLEL DO

     !  Now that we have initialized the moist_old values with P_Qv for
     !  computing a moist t_tendf after rk_step part2, fill in the halo 
     !  and period boundaries.

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
#  include "HALO_EM_MOIST_OLD_E_7.inc"
#  include "PERIOD_BDY_EM_MOIST_OLD.inc"
#endif
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles
       im = P_Qv
       CALL set_physical_bc3d( moist_old(ims,kms,jms,im), 'p', config_flags,  &
                               ids, ide, jds, jde, kds, kde,                  &
                               ims, ime, jms, jme, kms, kme,                  &
                               ips, ipe, jps, jpe, kps, kpe,                  &
                               grid%i_start(ij), grid%i_end(ij),              &
                               grid%j_start(ij), grid%j_end(ij),              &
                               k_start    , k_end                             )
     END DO
     !$OMP END PARALLEL DO

!**********************************************************************
!
!  LET US BEGIN.......
!
!<DESCRIPTION>
!<pre>
! (1) RK integration loop is named the "Runge_Kutta_loop:"
!
!   Predictor-corrector type time integration.
!   Advection terms are evaluated at time t for the predictor step,
!   and advection is re-evaluated with the latest predicted value for
!   each succeeding time corrector step
!
!   2nd order Runge Kutta (rk_order = 2):
!   Step 1 is taken to the midpoint predictor, step 2 is the full step.
!
!   3rd order Runge Kutta (rk_order = 3):
!   Step 1 is taken to from t to dt/3, step 2 is from t to dt/2,
!   and step 3 is from t to dt.
!
!   non-timesplit physics are evaluated during first RK step and
!   these physics tendencies are stored for use in each RK pass.
!</pre>
!</DESCRIPTION>
!**********************************************************************

#ifdef WRF_GPU
   CALL gpu_ck( grid, 'a_prerk', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
   Runge_Kutta_loop:  DO rk_step = 1, rk_order

   !  Set the step size and number of small timesteps for
   !  each part of the timestep

     dtm = grid%dt
     IF ( rk_order == 1 ) THEN   

       write(wrf_err_message,*)' leapfrog removed, error exit for dynamics_option = ',dynamics_option
       CALL wrf_error_fatal( wrf_err_message )

     ELSE IF ( rk_order == 2 ) THEN   ! 2nd order Runge-Kutta timestep

       IF ( rk_step == 1) THEN
         dt_rk  = 0.5*grid%dt
         dts_rk = dts
         number_of_small_timesteps = num_sound_steps/2
       ELSE
         dt_rk = grid%dt
         dts_rk = dts
         number_of_small_timesteps = num_sound_steps
       ENDIF

     ELSE IF ( rk_order == 3 ) THEN ! third order Runge-Kutta

       IF ( rk_step == 1) THEN
         dt_rk = grid%dt/3.
         dts_rk = dt_rk
         number_of_small_timesteps = 1
       ELSE IF (rk_step == 2) THEN
         dt_rk  = 0.5*grid%dt
         dts_rk = dts
         number_of_small_timesteps = num_sound_steps/2
       ELSE
         dt_rk = grid%dt
         dts_rk = dts
         number_of_small_timesteps = num_sound_steps
       ENDIF

     ELSE

       write(wrf_err_message,*)' unknown solver, error exit for dynamics_option = ',dynamics_option
       CALL wrf_error_fatal( wrf_err_message )

     END IF

!  Ensure that polar meridional velocity is zero
     IF (config_flags%polar) THEN 
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles
         CALL zero_pole ( grid%v_1,                      &
                          ids, ide, jds, jde, kds, kde,     &
                          ims, ime, jms, jme, kms, kme,     &
                          grid%i_start(ij), grid%i_end(ij), &
                          grid%j_start(ij), grid%j_end(ij), &
                          k_start, k_end                   )
         CALL zero_pole ( grid%v_2,                      &
                          ids, ide, jds, jde, kds, kde,     &
                          ims, ime, jms, jme, kms, kme,     &
                          grid%i_start(ij), grid%i_end(ij), &
                          grid%j_start(ij), grid%j_end(ij), &
                          k_start, k_end                   )
       END DO
       !$OMP END PARALLEL DO
     END IF
!
!  Time level t is in the *_2 variable in the first part 
!  of the step, and in the *_1 variable after the predictor.
!  the latest predicted values are stored in the *_2 variables.
!
     CALL wrf_debug ( 200 , ' call rk_step_prep ' )

BENCH_START(step_prep_tim)
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )

     DO ij = 1 , grid%num_tiles

       CALL rk_step_prep  ( config_flags, rk_step,            &
                            grid%u_2, grid%v_2, grid%w_2, grid%t_2, grid%ph_2, grid%mu_2,   &
                            grid%c1h, grid%c2h, grid%c1f, grid%c2f, moist,   &
                            grid%ru, grid%rv, grid%rw, grid%ww, grid%php, grid%alt, grid%muu, grid%muv,   &
                            grid%mub, grid%mut, grid%phb, grid%pb, grid%p, grid%al, grid%alb,    &
                            cqu, cqv, cqw,                    &
                            grid%msfux, grid%msfuy, grid%msfvx, grid%msfvx_inv,        &
                            grid%msfvy, grid%msftx, grid%msfty,                        &
                            grid%fnm, grid%fnp, grid%dnw, grid%rdx, grid%rdy,          &
                            num_3d_m,                         &
                            ids, ide, jds, jde, kds, kde,     &
                            ims, ime, jms, jme, kms, kme,     &
                            grid%i_start(ij), grid%i_end(ij), &
                            grid%j_start(ij), grid%j_end(ij), &
                            k_start, k_end                   )

     END DO
     !$OMP END PARALLEL DO
BENCH_END(step_prep_tim)

#ifdef DM_PARALLEL
!-----------------------------------------------------------------------
!  Stencils for patch communications  (WCS, 29 June 2001)
!  Note:  the small size of this halo exchange reflects the 
!         fact that we are carrying the uncoupled variables 
!         as state variables in the mass coordinate model, as
!         opposed to the coupled variables as in the height
!         coordinate model.
!
!                           * * * * *
!         *        * * *    * * * * *
!       * + *      * + *    * * + * * 
!         *        * * *    * * * * *
!                           * * * * *
!
!  3D variables - note staggering!  ru(X), rv(Y), ww(Z), php(Z)
!
!  ru     x
!  rv     x
!  ww     x
!  php    x
!  alt    x
!  ph_2   x
!  phb    x
!
!  the following are 2D (xy) variables
!
!  muu    x
!  muv    x
!  mut    x
!--------------------------------------------------------------
#    include "HALO_EM_A.inc"
#endif

! set boundary conditions on variables 
! from big_step_prep for use in big_step_proc

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_A.inc"
#endif

BENCH_START(set_phys_bc_tim)
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, ii, jj, kk )

     DO ij = 1 , grid%num_tiles

       CALL wrf_debug ( 200 , ' call rk_phys_bc_dry_1' )

       CALL rk_phys_bc_dry_1( config_flags, grid%ru, grid%rv, grid%rw, grid%ww,      & 
                              grid%muu, grid%muv, grid%mut, grid%php, grid%alt, grid%p,        &
                              ids, ide, jds, jde, kds, kde,      &
                              ims, ime, jms, jme, kms, kme,      &
                              ips, ipe, jps, jpe, kps, kpe,      &
                              grid%i_start(ij), grid%i_end(ij),  &
                              grid%j_start(ij), grid%j_end(ij),  &
                              k_start, k_end                )
       CALL set_physical_bc3d( grid%rho, 'p', config_flags,            &
                              ids, ide, jds, jde, kds, kde,     &
                              ims, ime, jms, jme, kms, kme,     &
                              ips, ipe, jps, jpe, kps, kpe,     &
                              grid%i_start(ij), grid%i_end(ij), &
                              grid%j_start(ij), grid%j_end(ij), &
                              k_start    , k_end               )
       CALL set_physical_bc3d( grid%al, 'p', config_flags,            &
                              ids, ide, jds, jde, kds, kde,     &
                              ims, ime, jms, jme, kms, kme,     &
                              ips, ipe, jps, jpe, kps, kpe,     &
                              grid%i_start(ij), grid%i_end(ij), &
                              grid%j_start(ij), grid%j_end(ij), &
                              k_start    , k_end               )
       CALL set_physical_bc3d( grid%ph_2, 'w', config_flags,            &
                              ids, ide, jds, jde, kds, kde, &
                              ims, ime, jms, jme, kms, kme, &
                              ips, ipe, jps, jpe, kps, kpe, &
                              grid%i_start(ij), grid%i_end(ij),        &
                              grid%j_start(ij), grid%j_end(ij),        &
                              k_start, k_end                )

       IF (config_flags%polar) THEN 

!-------------------------------------------------------
! lat-lon grid pole-point (v) specification (extrapolate v, rv to the pole)
!-------------------------------------------------------

         CALL pole_point_bc ( grid%v_1,                      &
                              ids, ide, jds, jde, kds, kde,     &
                              ims, ime, jms, jme, kms, kme,     &
                              grid%i_start(ij), grid%i_end(ij), &
                              grid%j_start(ij), grid%j_end(ij), &
                              k_start, k_end                   )
 
         CALL pole_point_bc ( grid%v_2,                      &
                              ids, ide, jds, jde, kds, kde,     &
                              ims, ime, jms, jme, kms, kme,     &
                              grid%i_start(ij), grid%i_end(ij), &
                              grid%j_start(ij), grid%j_end(ij), &
                              k_start, k_end                   )
 
!-------------------------------------------------------
! end lat-lon grid pole-point (v) specification
!-------------------------------------------------------

       ENDIF
     END DO
     !$OMP END PARALLEL DO
BENCH_END(set_phys_bc_tim)

     rk_step_is_one : IF (rk_step == 1) THEN ! only need to initialize diffusion tendencies

BENCH_START(calc_p_rho_tim)

!<DESCRIPTION>
!<pre>
!(2) The non-timesplit physics begins with a call to "phy_prep"
!    (which computes some diagnostic variables such as temperature,
!    pressure, u and v at p points, etc).  This is followed by
!    calls to the physics drivers:
!
!              radiation,
!              surface,
!              pbl,
!              cumulus,
!              fddagd,
!              3D TKE and mixing.
!<pre>
!</DESCRIPTION>

       IF (coupler_on) CALL cpl_settime( curr_secs2 )

#ifdef WRF_GPU_FIELDTRACE
       CALL gpu_field_trace( grid, 'a_pre_physics' )
#endif
#ifdef WRF_GPU_RESIDENT
   ! GPU-side init_zero_tendency + phy_prep (bit 256) before the host physics block: their inputs (state, mu) do
   ! not change in part1, and the GPU PBL (bit 1024) needs the phy_prep fields during part1
   gpu_prep_dev = IAND( wrf_gpu_xfer(), 256 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 2 ) /= 0 .AND.          &
                  ( config_flags%scalar_pblmix == 0 .OR. num_scalar < PARAM_FIRST_SCALAR ) .AND.       &
                  ( config_flags%tracer_pblmix == 0 .OR. num_tracer < PARAM_FIRST_SCALAR ) .AND.       &
                  config_flags%grid_fdda == 0
   IF ( gpu_prep_dev ) THEN
     DO ij = 1 , grid%num_tiles
         CALL init_zero_tendency ( ru_tendf, rv_tendf, rw_tendf,     &
                                   ph_tendf, t_tendf, tke_tend,      &
                                   mu_tendf,                         &
                                   moist_tend,chem_tend,scalar_tend, &
                                   tracer_tend,num_tracer,           &
                                   num_moist,num_chem,num_scalar,    &
                                   rk_step,                          &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   grid%i_start(ij), grid%i_end(ij), &
                                   grid%j_start(ij), grid%j_end(ij), &
                                   k_start, k_end                   )
        CALL phy_prep ( config_flags,                                    &
                        grid%mut, grid%muu, grid%muv,                    &
                        grid%c1h, grid%c2h, grid%c1f, grid%c2f,          &
                        grid%u_2, grid%v_2, grid%p, grid%pb, grid%alt,   &
                        grid%ph_2, grid%phb, grid%t_2, moist, num_moist, &
                        grid%rho,th_phy, grid%th_phy_m_t0,               &
                        p_phy, pi_phy, grid%u_phy, grid%v_phy,           &
                        p8w, grid%t_phy, t8w, grid%z, grid%z_at_w, dz8w, &
                        grid%p_hyd, grid%p_hyd_w, grid%dnw,              &
                        grid%fnm, grid%fnp, grid%znw, grid%p_top,        &
                        ids, ide, jds, jde, kds, kde,                    &
                        ims, ime, jms, jme, kms, kme,                    &
                        grid%i_start(ij), grid%i_end(ij),                &
                        grid%j_start(ij), grid%j_end(ij),                &
                        k_start, k_end                                   )
     ENDDO
   ENDIF
   wrf_gpu_pbl = gpu_prep_dev .AND. IAND( wrf_gpu_xfer(), 1024 ) /= 0
   wrf_gpu_cu_pullbl = wrf_gpu_pbl
   wrf_gpu_cu = wrf_gpu_pbl .AND. IAND( wrf_gpu_xfer(), 8192 ) /= 0   ! Tiedtke on the GPU
   ! GPU Thompson (bit 32) writes the effective radii: radiation_driver pulls them on radiation steps only
   wrf_gpu_ra_pullre = IAND( wrf_gpu_xfer(), 16 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 6 ) == 6 .AND.          &
                       IAND( wrf_gpu_xfer(), 32 ) /= 0 .AND. config_flags%mp_physics == THOMPSON
   wrf_gpu_ra_lw = IAND( wrf_gpu_xfer(), 16384 ) /= 0   ! RRTMG LW core on the GPU
   wrf_gpu_ra_sw = IAND( wrf_gpu_xfer(), 32768 ) /= 0   ! RRTMG SW core on the GPU (with 16384)
   wrf_gpu_diag = IAND( wrf_gpu_xfer(), 65536 ) /= 0   ! every-step NWP + AFWA diagnostics on the GPU
   wrf_gpu_sfc = IAND( wrf_gpu_xfer(), 131072 ) /= 0  ! MYJ surface layer on the GPU
   wrf_gpu_lsm = IAND( wrf_gpu_xfer(), 262144 ) /= 0  ! Noah LSM point loop on the GPU
   ! lean step (bit 524288): no radiation this step and every other physics package on the GPU (bit 4194304: Noah may
   ! stay on the host - it reads levels 1-2 only) - the host gets
   ! levels 1-2 of the phy_prep fields / moisture only (gpu_lean_pull) and skips its phy_prep
   wrf_gpu_lean_step = .FALSE.
   IF ( IAND( wrf_gpu_xfer(), 524288 ) /= 0 .AND. gpu_prep_dev .AND. wrf_gpu_pbl .AND. wrf_gpu_cu .AND.        &
        wrf_gpu_sfc .AND. ( wrf_gpu_lsm .OR. IAND( wrf_gpu_xfer(), 4194304 ) /= 0 ) .AND. grid%itimestep > 1 .AND. &
        config_flags%shcu_physics == 0 .AND.                                                                 &
        config_flags%sf_urban_physics == 0 .AND. config_flags%fractional_seaice == 0 ) THEN
      ! radiation_driver's run_param (radtacttime is set on the first step)
      lean_rad = ( config_flags%radt == 0. ) .OR. ( grid%stepra == 1 )
      IF ( .NOT. lean_rad ) THEN
         IF ( config_flags%use_adaptive_time_step ) THEN
            lean_rad = curr_secs .GE. grid%radtacttime
         ELSE
            lean_rad = MOD( grid%itimestep, grid%stepra ) .EQ. 1 + grid%ra_call_offset
         ENDIF
      ENDIF
      wrf_gpu_lean_step = .NOT. lean_rad
   ENDIF
#endif
#ifdef WRF_GPU_RESIDENT
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   ! WRF_GPU_H1CHK=1 (diagnostic): which host state arrays does the H1 pull change after the previous step's H3 pull
   IF ( wrf_gpu_h1chk() .AND. gpu_h3_done ) THEN
     IF ( ASSOCIATED(grid%alt) ) h1ck(1,1) = SUM( DBLE(grid%alt) )
     IF ( ASSOCIATED(grid%p) ) h1ck(1,2) = SUM( DBLE(grid%p) )
     IF ( ASSOCIATED(grid%ph_2) ) h1ck(1,3) = SUM( DBLE(grid%ph_2) )
     IF ( ASSOCIATED(grid%rho) ) h1ck(1,4) = SUM( DBLE(grid%rho) )
     IF ( ASSOCIATED(grid%t_2) ) h1ck(1,5) = SUM( DBLE(grid%t_2) )
     IF ( ASSOCIATED(grid%u_2) ) h1ck(1,6) = SUM( DBLE(grid%u_2) )
     IF ( ASSOCIATED(grid%v_2) ) h1ck(1,7) = SUM( DBLE(grid%v_2) )
     IF ( ASSOCIATED(grid%w_2) ) h1ck(1,8) = SUM( DBLE(grid%w_2) )
     IF ( ASSOCIATED(grid%moist) ) h1ck(1,9) = SUM( DBLE(grid%moist) )
     IF ( ASSOCIATED(grid%scalar) ) h1ck(1,10) = SUM( DBLE(grid%scalar) )
   ENDIF
   gpu_h1_reuse = IAND( wrf_gpu_xfer(), 128 ) /= 0 .AND. gpu_h3_done
   IF ( wrf_gpu_lean_step ) THEN
!$acc wait
     CALL gpu_lean_pull( grid, th_phy, p_phy, pi_phy, p8w, t8w, dz8w, moist, num_moist, ims, ime, jms, jme, kms, kme )
   ELSE IF ( IAND( wrf_gpu_xfer(), 1 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 2048 ) /= 0 ) THEN
#  include "gpu_stage_host_h1.inc"
   ELSE IF ( IAND( wrf_gpu_xfer(), 1 ) /= 0 ) THEN
#  include "gpu_upd_host_h1.inc"
   ELSE
#  include "gpu_upd_host_pre_phys.inc"
   ENDIF
   IF ( wrf_gpu_h1chk() .AND. gpu_h3_done ) THEN
!$acc wait
     IF ( ASSOCIATED(grid%alt) ) h1ck(2,1) = SUM( DBLE(grid%alt) )
     IF ( ASSOCIATED(grid%p) ) h1ck(2,2) = SUM( DBLE(grid%p) )
     IF ( ASSOCIATED(grid%ph_2) ) h1ck(2,3) = SUM( DBLE(grid%ph_2) )
     IF ( ASSOCIATED(grid%rho) ) h1ck(2,4) = SUM( DBLE(grid%rho) )
     IF ( ASSOCIATED(grid%t_2) ) h1ck(2,5) = SUM( DBLE(grid%t_2) )
     IF ( ASSOCIATED(grid%u_2) ) h1ck(2,6) = SUM( DBLE(grid%u_2) )
     IF ( ASSOCIATED(grid%v_2) ) h1ck(2,7) = SUM( DBLE(grid%v_2) )
     IF ( ASSOCIATED(grid%w_2) ) h1ck(2,8) = SUM( DBLE(grid%w_2) )
     IF ( ASSOCIATED(grid%moist) ) h1ck(2,9) = SUM( DBLE(grid%moist) )
     IF ( ASSOCIATED(grid%scalar) ) h1ck(2,10) = SUM( DBLE(grid%scalar) )
     DO ick = 1, 10
       IF ( h1ck(1,ick) /= h1ck(2,ick) ) WRITE(0,'(A,I6,1X,A,2ES24.15)') 'H1CHK step', grid%itimestep, &
          TRIM(h1ck_name(ick)), h1ck(1,ick), h1ck(2,ick)
     ENDDO
   ENDIF
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 1 ) /= 0 ) THEN
#    include "gpu_sync_host_all.inc"
#    include "gpu_upd_host_i1_all.inc"
   ENDIF
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   IF ( wrf_gpu_prefetch_mode() > 0 ) THEN
#  include "gpu_pf_host_pre_phys.inc"
   ENDIF
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'b_preH1', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 2 )
#endif
#ifdef WRF_GPU
       IF ( wrf_gpu_hostblocks() ) THEN ; wrf_gpu_on = .FALSE. ; CALL rsl_set_gpu_on( .FALSE. ) ; ENDIF
       CALL gpu_retile( grid, .TRUE., ids, ide, jds, jde, ips, ipe, jps, jpe )
#endif
#ifdef WRF_GPU_RESIDENT
       wrf_gpu_ra_ran = .FALSE. ; wrf_gpu_cu_ran = .FALSE. ; wrf_gpu_bl_ran = .FALSE.
#endif
       CALL first_rk_step_part1 (    grid, config_flags         &
                             , moist , moist_tend               &
                             , chem  , chem_tend                &
                             , tracer, tracer_tend              &
                             , scalar , scalar_tend             &
                             , fdda3d, fdda2d                   &
                             , aerod                            &
                             , ru_tendf, rv_tendf               &
                             , rw_tendf, t_tendf                &
                             , ph_tendf, mu_tendf               &
                             , tke_tend                         &
                             , config_flags%use_adaptive_time_step &
                             , curr_secs, curr_mins2            &
                             , psim , psih , gz1oz0             &
                             , chklowq                          &
                             , cu_act_flag , hol , th_phy       &
                             , pi_phy , p_phy , grid%t_phy      &
                             , dz8w , p8w , t8w                 &
                             , ids, ide, jds, jde, kds, kde     &
                             , ims, ime, jms, jme, kms, kme     &
                             , ips, ipe, jps, jpe, kps, kpe     &
                             , imsx, imex, jmsx, jmex, kmsx, kmex    &
                             , ipsx, ipex, jpsx, jpex, kpsx, kpex    &
                             , imsy, imey, jmsy, jmey, kmsy, kmey    &
                             , ipsy, ipey, jpsy, jpey, kpsy, kpey    &
                             , k_start , k_end                  &
                             , f_flux=f_flux                    &
                             , aerocu=aerocu                    &
                             , restart_flag=restart_flag        &
                             , feedback_is_ready=feedback_is_ready    &
                            )
#ifdef WRF_GPU_RESIDENT
       ! WRF_GPU_P8WCHK=1 (diagnostic): device vs host level-1/2 phy_prep fields after the host phy_prep
       IF ( gpu_p8wchk() .AND. .NOT. wrf_gpu_lean_step ) CALL gpu_lean_check( grid, th_phy, p_phy, pi_phy, p8w, t8w, &
            dz8w, moist, num_moist, ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe )
#endif

#ifdef DM_PARALLEL
       IF ( config_flags%bl_pbl_physics == MYNNPBLSCHEME ) THEN
#        include "HALO_EM_SCALAR_E_5.inc"
       ENDIF
#endif

#ifdef WRF_GPU
       ! part2 (diffusion coefficients, tendency updates) uses dyn_em routines with persistent (shared) work arrays:
       ! run it on the solve_em tiling with compute regions on the GPU; only part1 (physics drivers) is multi-tiled.
       CALL gpu_retile( grid, .FALSE., ids, ide, jds, jde, ips, ipe, jps, jpe )
       wrf_gpu_on = .TRUE. ; CALL rsl_set_gpu_on( .TRUE. )
#endif
#ifdef WRF_GPU_RESIDENT
       ! physics (part1, host) wrote grid fields and the i1 temporaries (zeroed tendencies, th_phy/pi_phy/...):
       ! push them to the device before part2 runs on the GPU
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   gpu_tend_dev = IAND( wrf_gpu_xfer(), 16 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 6 ) == 6
   gpu_push_ra = .NOT. gpu_tend_dev .OR. wrf_gpu_ra_ran
   gpu_push_cu = ( .NOT. gpu_tend_dev .OR. wrf_gpu_cu_ran ) .AND. .NOT. wrf_gpu_cu_dev_ran
   gpu_push_bl = ( .NOT. gpu_tend_dev .OR. wrf_gpu_bl_ran ) .AND. .NOT. wrf_gpu_pbl_ran
   gpu_skip_diff = IAND( wrf_gpu_xfer(), 64 ) /= 0 .AND. config_flags%diff_opt >= 1
   IF ( IAND( wrf_gpu_xfer(), 2 ) /= 0 ) THEN
#  include "gpu_upd_dev_h1.inc"
   ELSE
#  include "gpu_upd_dev_post_phys.inc"
   ENDIF
#      include "gpu_upd_dev_i1_part1.inc"
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 3 ) == 3 ) THEN
#    include "gpu_sync_dev_all.inc"
#    include "gpu_upd_dev_i1_all.inc"
   ENDIF
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'c_prep2', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 6 )
#endif
       CALL first_rk_step_part2 (    grid, config_flags         &
                             , moist , moist_old , moist_tend   &
                             , chem  , chem_tend                &
                             , tracer, tracer_tend              &
                             , scalar , scalar_tend             &
                             , fdda3d, fdda2d                   &
                             , ru_tendf, rv_tendf               &
                             , rw_tendf, t_tendf                &
                             , ph_tendf, mu_tendf               &
                             , tke_tend                         &
                             , adapt_step_flag , curr_secs      &
                             , psim , psih , gz1oz0             &
                             , chklowq                          &
                             , cu_act_flag , hol , th_phy       &
                             , pi_phy , p_phy , grid%t_phy      &
                             , dz8w , p8w , t8w                 &
                             , nba_mij, num_nba_mij             & !JDM 
                             , nba_rij, num_nba_rij             & !JDM 
                             , ids, ide, jds, jde, kds, kde     &
                             , ims, ime, jms, jme, kms, kme     &
                             , ips, ipe, jps, jpe, kps, kpe     &
                             , imsx, imex, jmsx, jmex, kmsx, kmex    &
                             , ipsx, ipex, jpsx, jpex, kpsx, kpex    &
                             , imsy, imey, jmsy, jmey, kmsy, kmey    &
                             , ipsy, ipey, jpsy, jpey, kpsy, kpey    &
                             , k_start , k_end                  &
                            )
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif

#ifdef WRF_GPU_RESIDENT
#endif
#ifdef WRF_GPU
       wrf_gpu_on = .TRUE. ; CALL rsl_set_gpu_on( .TRUE. )
       CALL gpu_retile( grid, .FALSE., ids, ide, jds, jde, ips, ipe, jps, jpe )
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 1 )
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'd_postp2', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   IF ( wrf_gpu_prefetch_mode() > 0 ) THEN
#  include "gpu_pf_dev_post_phys.inc"
#  include "gpu_pf_dev_i1_tend.inc"
   ENDIF
#endif
     END IF rk_step_is_one
#ifdef WRF_GPU_RESIDENT
     ! RK dynamics: one tile, launched by this thread on queue wrf_gpu_q -> routines skip their exit waits
     wrf_gpu_xw_skip = IAND( wrf_gpu_xfer(), 1048576 ) /= 0 .AND. wrf_gpu_q == 1 .AND. grid%num_tiles == 1 .AND. wrf_gpu_on
#endif
#ifdef WRF_GPU_FIELDTRACE
     IF (rk_step == 1) CALL gpu_field_trace( grid, 'b_post_physics' )
#endif

BENCH_START(rk_tend_tim)
#ifdef WRF_GPU
   IF ( grid%itimestep <= 1 .AND. rk_step == 1 ) THEN
      CALL gpu_ckv( grid, 'ru_tendf', 3, ru_tendf, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'rv_tendf', 3, rv_tendf, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'rw_tendf', 3, rw_tendf, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'ph_tendf', 3, ph_tendf, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 't_tendf', 3, t_tendf, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'u_save', 3, grid%u_save, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'v_save', 3, grid%v_save, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'w_save', 3, w_save, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'ph_save', 3, ph_save, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 't_save', 3, grid%t_save, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'rthften', 3, grid%rthften, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'ru', 3, grid%ru, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'rv', 3, grid%rv, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'rw', 3, grid%rw, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'ww', 3, grid%ww, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'wwE', 3, wwE, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'wwI', 3, wwI, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'u_1', 3, grid%u_1, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'v_1', 3, grid%v_1, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'w_1', 3, grid%w_1, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 't_1', 3, grid%t_1, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'ph_1', 3, grid%ph_1, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'h_diabatic', 3, grid%h_diabatic, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'phb', 3, grid%phb, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 't_init', 3, grid%t_init, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'al', 3, grid%al, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'alt', 3, grid%alt, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'pb', 3, grid%pb, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'php', 3, grid%php, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'cqu', 3, cqu, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'cqv', 3, cqv, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'cqw', 3, cqw, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'xkmh', 3, grid%xkmh, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'xkhh', 3, grid%xkhh, ims, ime, kms, kme, jms, jme, ips, ipe, kps, kpe, jps, jpe )
      CALL gpu_ckv( grid, 'mu_save', 2, mu_save, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'mu_1', 2, grid%mu_1, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'mut', 2, grid%mut, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'muu', 2, grid%muu, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'muv', 2, grid%muv, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'mub', 2, grid%mub, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'ht', 2, grid%ht, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfux', 2, grid%msfux, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfuy', 2, grid%msfuy, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfvx', 2, grid%msfvx, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfvx_inv', 2, grid%msfvx_inv, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfvy', 2, grid%msfvy, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msftx', 2, grid%msftx, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'msfty', 2, grid%msfty, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'f', 2, grid%f, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'e', 2, grid%e, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'sina', 2, grid%sina, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'cosa', 2, grid%cosa, ims, ime, 1, 1, jms, jme, ips, ipe, 1, 1, jps, jpe )
      CALL gpu_ckv( grid, 'c1h', 1, grid%c1h, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'c2h', 1, grid%c2h, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'c1f', 1, grid%c1f, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'c2f', 1, grid%c2f, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'fnm', 1, grid%fnm, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'fnp', 1, grid%fnp, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'rdn', 1, grid%rdn, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'rdnw', 1, grid%rdnw, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'u_base', 1, grid%u_base, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'v_base', 1, grid%v_base, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 't_base', 1, grid%t_base, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'qv_base', 1, grid%qv_base, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
      CALL gpu_ckv( grid, 'z_base', 1, grid%z_base, kms, kme, 1, 1, 1, 1, kps, kpe, 1, 1, 1, 1 )
   ENDIF
#endif
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

       CALL wrf_debug ( 200 , ' call rk_tendency' )
       CALL rk_tendency ( config_flags, rk_step                                                                &
                         ,grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend                                 &
                         ,ru_tendf, rv_tendf, rw_tendf, ph_tendf, t_tendf                                      &
                         ,mu_tend, grid%u_save, grid%v_save, w_save, ph_save                                   &
                         ,grid%t_save, mu_save, grid%rthften                                                   &
                         ,grid%ru, grid%rv, grid%rw, grid%ww, wwE, wwI                                         &
                         ,grid%u_2, grid%v_2, grid%w_2, grid%t_2, grid%ph_2                                    &
                         ,grid%u_1, grid%v_1, grid%w_1, grid%t_1, grid%ph_1                                    &
                         ,grid%h_diabatic, grid%phb, grid%t_init                                               &
                         ,grid%mu_1, grid%mu_2, grid%mut, grid%muu, grid%muv, grid%mub                         & 
                         ,grid%c1h, grid%c2h, grid%c1f, grid%c2f                                               &
                         ,grid%al, grid%ht, grid%alt, grid%p, grid%pb, grid%php, cqu, cqv, cqw                 & 
                         ,grid%u_base, grid%v_base, grid%t_base, grid%qv_base, grid%z_base                     &
                         ,grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv                                    &
                         ,grid%msfvy, grid%msftx,grid%msfty, grid%clat, grid%f, grid%e, grid%sina, grid%cosa   &
                         ,grid%fnm, grid%fnp, grid%rdn, grid%rdnw                                              &
                         ,grid%dt, grid%rdx, grid%rdy, grid%khdif, grid%kvdif, grid%xkmh, grid%xkhh            &
                         ,grid%diff_6th_opt, grid%diff_6th_factor                                              &
                         ,config_flags%momentum_adv_opt                                                        &
                         ,grid%dampcoef,grid%zdamp,config_flags%damp_opt,config_flags%rad_nudge                &
                         ,grid%cf1, grid%cf2, grid%cf3, grid%cfn, grid%cfn1, num_3d_m                          &
                         ,config_flags%non_hydrostatic, config_flags%top_lid                                   &
                         ,grid%u_frame, grid%v_frame                                                           &
                         ,ids, ide, jds, jde, kds, kde                                                         &
                         ,ims, ime, jms, jme, kms, kme                                                         &
                         ,grid%i_start(ij), grid%i_end(ij)                                                     &
                         ,grid%j_start(ij), grid%j_end(ij)                                                     &
                         ,k_start, k_end                                                                       &
                         ,max_vert_cfl_tmp(ij), max_horiz_cfl_tmp(ij)                                         )
     END DO
     !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k1_rktend', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   CALL gpu_ckt( grid, 'k1_rktend', rk_step, grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend, mu_tend, &
        ims, ime, jms, jme, kms, kme, ips, MIN(ipe,ide-1), jps, MIN(jpe,jde-1), kps, kpe )
#endif
BENCH_END(rk_tend_tim)

     IF (config_flags%use_adaptive_time_step) THEN
       DO ij = 1 , grid%num_tiles
         IF (max_horiz_cfl_tmp(ij) .GT. grid%max_horiz_cfl) THEN
           grid%max_horiz_cfl = max_horiz_cfl_tmp(ij)
         ENDIF
         IF (max_vert_cfl_tmp(ij) .GT. grid%max_vert_cfl) THEN
           grid%max_vert_cfl = max_vert_cfl_tmp(ij)
         ENDIF
       END DO
     
       IF (grid%max_horiz_cfl .GT. grid%max_cfl_val) THEN
         grid%max_cfl_val = grid%max_horiz_cfl
       ENDIF
       IF (grid%max_vert_cfl .GT. grid%max_cfl_val) THEN
         grid%max_cfl_val = grid%max_vert_cfl
       ENDIF
     ENDIF

BENCH_START(relax_bdy_dry_tim)
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

       IF ( (config_flags%specified .or. config_flags%nested) .and. ( rk_step == 1 ) ) THEN 

         CALL relax_bdy_dry ( config_flags,                                &
                              grid%u_save, grid%v_save, ph_save, grid%t_save,             &
                              w_save, mu_tend, grid%c1h, grid%c2h, grid%c1f, grid%c2f, &
                              grid%ru, grid%rv, grid%ph_2, grid%t_2,                           &
                              grid%w_2, grid%mu_2, grid%mut,                              &
                              grid%u_bxs,grid%u_bxe,grid%u_bys,grid%u_bye, &
                              grid%v_bxs,grid%v_bxe,grid%v_bys,grid%v_bye, &
                              grid%ph_bxs,grid%ph_bxe,grid%ph_bys,grid%ph_bye, &
                              grid%t_bxs,grid%t_bxe,grid%t_bys,grid%t_bye, &
                              grid%w_bxs,grid%w_bxe,grid%w_bys,grid%w_bye, &
                              grid%mu_bxs,grid%mu_bxe,grid%mu_bys,grid%mu_bye, &
                              grid%u_btxs,grid%u_btxe,grid%u_btys,grid%u_btye, &
                              grid%v_btxs,grid%v_btxe,grid%v_btys,grid%v_btye, &
                              grid%ph_btxs,grid%ph_btxe,grid%ph_btys,grid%ph_btye, &
                              grid%t_btxs,grid%t_btxe,grid%t_btys,grid%t_btye, &
                              grid%w_btxs,grid%w_btxe,grid%w_btys,grid%w_btye, &
                              grid%mu_btxs,grid%mu_btxe,grid%mu_btys,grid%mu_btye, &
                              config_flags%spec_bdy_width, grid%spec_zone, grid%relax_zone,       &
                              grid%dtbc, grid%fcx, grid%gcx,                              &
                              ids,ide, jds,jde, kds,kde,                   &
                              ims,ime, jms,jme, kms,kme,                   &
                              ips,ipe, jps,jpe, kps,kpe,                   &
                              grid%i_start(ij), grid%i_end(ij),            &
                              grid%j_start(ij), grid%j_end(ij),            &
                              k_start, k_end                              )

       ENDIF

       CALL rk_addtend_dry( grid%ru_tend,  grid%rv_tend,  rw_tend,  ph_tend,  t_tend,  &
                            ru_tendf, rv_tendf, rw_tendf, ph_tendf, t_tendf, &
                            grid%u_save, grid%v_save, w_save, ph_save, grid%t_save, &
                            mu_tend, mu_tendf, rk_step,                      &
                            grid%c1h, grid%c2h,                              &
                            grid%h_diabatic, grid%mut, grid%msftx,           &
                            grid%msfty, grid%msfux,grid%msfuy,               &
                            grid%msfvx, grid%msfvx_inv, grid%msfvy,          &
                            ids,ide, jds,jde, kds,kde,                       &
                            ims,ime, jms,jme, kms,kme,                       &
                            ips,ipe, jps,jpe, kps,kpe,                       &
                            grid%i_start(ij), grid%i_end(ij),                &
                            grid%j_start(ij), grid%j_end(ij),                &
                            k_start, k_end                                  )

       IF( config_flags%specified .or. config_flags%nested ) THEN 
         CALL spec_bdy_dry ( config_flags,                                    &
                             grid%ru_tend, grid%rv_tend, ph_tend, t_tend,               &
                             rw_tend, mu_tend,                                &
                             grid%u_bxs,grid%u_bxe,grid%u_bys,grid%u_bye, &
                             grid%v_bxs,grid%v_bxe,grid%v_bys,grid%v_bye, &
                             grid%ph_bxs,grid%ph_bxe,grid%ph_bys,grid%ph_bye, &
                             grid%t_bxs,grid%t_bxe,grid%t_bys,grid%t_bye, &
                             grid%w_bxs,grid%w_bxe,grid%w_bys,grid%w_bye, &
                             grid%mu_bxs,grid%mu_bxe,grid%mu_bys,grid%mu_bye, &
                             grid%u_btxs,grid%u_btxe,grid%u_btys,grid%u_btye, &
                             grid%v_btxs,grid%v_btxe,grid%v_btys,grid%v_btye, &
                             grid%ph_btxs,grid%ph_btxe,grid%ph_btys,grid%ph_btye, &
                             grid%t_btxs,grid%t_btxe,grid%t_btys,grid%t_btye, &
                             grid%w_btxs,grid%w_btxe,grid%w_btys,grid%w_btye, &
                             grid%mu_btxs,grid%mu_btxe,grid%mu_btys,grid%mu_btye, &
                             config_flags%spec_bdy_width, grid%spec_zone,                       &
                             ids,ide, jds,jde, kds,kde,  & ! domain dims
                             ims,ime, jms,jme, kms,kme,  & ! memory dims
                             ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                             grid%i_start(ij), grid%i_end(ij),                &
                             grid%j_start(ij), grid%j_end(ij),                &
                             k_start, k_end                                  )


       ENDIF

!---------------------------------------------------------------------------------------------
! KRS 9/12/2012: Inserted new IF block calls to spec_bdy_dry_perturb. If peturb_bdy=1, SKEBS 
! pattern passed in for perturbing the specified boundry conditions.  If peturb_bdy=2, user
! must provide pattern.  mu_2, mub, msf* also passed in for coupling needed for tendecies.
!---------------------------------------------------------------------------------------------
       IF( config_flags%specified .and. config_flags%perturb_bdy==1 ) THEN 
         CALL spec_bdy_dry_perturb ( config_flags,                                 &
                             grid%ru_tend, grid%rv_tend, t_tend,                   &
                             grid%mu_2, grid%mub, grid%c1h, grid%c2h,              &
                             grid%msfux, grid%msfvx, grid%msft,	                   &
                             grid%ru_tendf_stoch, grid%rv_tendf_stoch, grid%rt_tendf_stoch, &
                             config_flags%spec_bdy_width, grid%spec_zone,                   &
                             grid%num_stoch_levels,      & ! stoch dims
                             ids,ide, jds,jde, kds,kde,  & ! domain dims
                             ims,ime, jms,jme, kms,kme,  & ! memory dims
                             ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                             grid%i_start(ij), grid%i_end(ij),                &
                             grid%j_start(ij), grid%j_end(ij),                &
                             k_start, k_end                                  )
     
       ENDIF

       IF( config_flags%specified .and. config_flags%perturb_bdy==2 ) THEN
         CALL spec_bdy_dry_perturb ( config_flags,                                 &
                             grid%ru_tend, grid%rv_tend, t_tend,                   &
                             grid%mu_2, grid%mub, grid%c1h, grid%c2h,              &
                             grid%msfux, grid%msfvx, grid%msft,                    &
                             grid%field_u_tend_perturb, grid%field_v_tend_perturb, grid%field_t_tend_perturb, &
                             config_flags%spec_bdy_width, grid%spec_zone,                   &
                             grid%num_stoch_levels,      & ! stoch dims
                             ids,ide, jds,jde, kds,kde,  & ! domain dims
                             ims,ime, jms,jme, kms,kme,  & ! memory dims
                             ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                             grid%i_start(ij), grid%i_end(ij),                &
                             grid%j_start(ij), grid%j_end(ij),                &
                             k_start, k_end                                  )
  
       ENDIF

     END DO
     !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k2_addbdy', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   CALL gpu_ckt( grid, 'k2_addbdy', rk_step, grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend, mu_tend, &
        ims, ime, jms, jme, kms, kme, ips, MIN(ipe,ide-1), jps, MIN(jpe,jde-1), kps, kpe )
#endif
BENCH_END(relax_bdy_dry_tim)

!<DESCRIPTION>
!<pre>
! (3) Small (acoustic,sound) steps.
!
!    Several acoustic steps are taken each RK pass.  A small step 
!    sequence begins with calculating perturbation variables 
!    and coupling them to the column dry-air-mass mu 
!    (call to small_step_prep).  This is followed by computing
!    coefficients for the vertically implicit part of the
!    small timestep (call to calc_coef_w).  
!
!    The small steps are taken
!    in the named loop "small_steps:".  In the small_steps loop, first 
!    the horizontal momentum (u and v) are advanced (call to advance_uv),
!    next mu and theta are advanced (call to advance_mu_t) followed by
!    advancing w and the geopotential (call to advance_w).  Diagnostic
!    values for pressure and inverse density are updated at the end of
!    each small_step.
!
!    The small-step section ends with the change of the perturbation variables
!    back to full variables (call to small_step_finish).
!</pre>
!</DESCRIPTION>

BENCH_START(small_step_prep_tim)
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

    ! Calculate coefficients for the vertically implicit acoustic/gravity wave
    ! integration.  We only need calculate these for the first pass through -
    ! the predictor step.  They are reused as is for the corrector step.
    ! For third-order RK, we need to recompute these after the first 
    ! predictor because we may have changed the small timestep -> grid%dts.

       CALL wrf_debug ( 200 , ' call small_step_prep ' )

       CALL small_step_prep( grid%u_1,grid%u_2,grid%v_1,grid%v_2,grid%w_1,grid%w_2,   &
                             grid%t_1,grid%t_2,grid%ph_1,grid%ph_2,                   &
                             grid%mub, grid%mu_1, grid%mu_2,                          &
                             grid%muu, grid%muus, grid%muv, grid%muvs,                &
                             grid%mut, grid%muts, grid%mudf,                          &
                             grid%c1h, grid%c2h, grid%c1f, grid%c2f,                  &
                             grid%c3h, grid%c4h, grid%c3f, grid%c4f,                  &
                             grid%u_save, grid%v_save, w_save,                        &
                             grid%t_save, ph_save, mu_save,                           &
                             grid%ww, ww1,                                            &
                             c2a, grid%pb, grid%p, grid%alt,                          &
                             grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv,       &
                             grid%msfvy, grid%msftx,grid%msfty,                       &
                             grid%rdx, grid%rdy, rk_step,                             &
                             ids, ide, jds, jde, kds, kde,                            &
                             ims, ime, jms, jme, kms, kme,                            &
                             grid%i_start(ij), grid%i_end(ij),                        &
                             grid%j_start(ij), grid%j_end(ij),                        &
                             k_start    , k_end                                       )
 
       CALL calc_p_rho( grid%al, grid%p, grid%ph_2,                 &
                        grid%alt, grid%t_2, grid%t_save, c2a, pm1,  &
                        grid%mu_2, grid%muts,                       &
                        grid%c1h, grid%c2h, grid%c1f, grid%c2f,     &
                        grid%c3h, grid%c4h, grid%c3f, grid%c4f,     &
                        grid%znu, t0,                               &
                        grid%rdnw, grid%dnw, grid%smdiv,            &
                        config_flags%non_hydrostatic, 0,            &
                        ids, ide, jds, jde, kds, kde,               &
                        ims, ime, jms, jme, kms, kme,               &
                        grid%i_start(ij), grid%i_end(ij),           &
                        grid%j_start(ij), grid%j_end(ij),           &
                        k_start    , k_end                          )

       IF (config_flags%non_hydrostatic) THEN
         CALL calc_coef_w( a,alpha,gamma,                    &
                           grid%mut,                         &
                           grid%c1h, grid%c2h, grid%c1f, grid%c2f, &
                           grid%c3h, grid%c4h, grid%c3f, grid%c4f, &
                           cqw, grid%rdn, grid%rdnw, c2a,    &
                           dts_rk, g, grid%epssm,            &
                           config_flags%top_lid,             &
                           ids, ide, jds, jde, kds, kde,     &
                           ims, ime, jms, jme, kms, kme,     &
                           grid%i_start(ij), grid%i_end(ij), &
                           grid%j_start(ij), grid%j_end(ij), &
                           k_start    , k_end               )
       ENDIF

     ENDDO
     !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k3_ssprep', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   CALL gpu_ckt( grid, 'k3_ssprep', rk_step, grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend, mu_tend, &
        ims, ime, jms, jme, kms, kme, ips, MIN(ipe,ide-1), jps, MIN(jpe,jde-1), kps, kpe )
#endif
BENCH_END(small_step_prep_tim)

#ifdef DM_PARALLEL
!-----------------------------------------------------------------------
!  Stencils for patch communications  (WCS, 29 June 2001)
!  Note:  the small size of this halo exchange reflects the 
!         fact that we are carrying the uncoupled variables 
!         as state variables in the mass coordinate model, as
!         opposed to the coupled variables as in the height
!         coordinate model.
!
!                              * * * * *
!            *        * * *    * * * * *
!          * + *      * + *    * * + * * 
!            *        * * *    * * * * *
!                              * * * * *
!
!  3D variables - note staggering!  ph_2(Z), u_save(X), v_save(Y)
!
!  ph_2      x
!  al        x
!  p         x
!  t_1       x
!  t_save    x
!  u_save    x
!  v_save    x
!
!  the following are 2D (xy) variables
!
!  mu_1      x
!  mu_2      x
!  mudf      x
!  php       x
!  alt       x
!  pb        x
!--------------------------------------------------------------
#      include "HALO_EM_B.inc"
#      include "PERIOD_BDY_EM_B.inc"
#endif

BENCH_START(set_phys_bc2_tim)
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )

     DO ij = 1 , grid%num_tiles

       CALL set_physical_bc3d( grid%ru_tend, 'u', config_flags,      &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%rv_tend, 'v', config_flags,      &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%ph_2, 'w', config_flags,         &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%al, 'p', config_flags,           &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%p, 'p', config_flags,            &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%t_1, 'p', config_flags,          &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc3d( grid%t_save, 't', config_flags,       &
                               ids, ide, jds, jde, kds, kde,         &
                               ims, ime, jms, jme, kms, kme,         &
                               ips, ipe, jps, jpe, kps, kpe,         &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij),     &
                               k_start    , k_end                    )

       CALL set_physical_bc2d( grid%mu_1, 't', config_flags,         &
                               ids, ide, jds, jde,                   &
                               ims, ime, jms, jme,                   &
                               ips, ipe, jps, jpe,                   &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij)      )

       CALL set_physical_bc2d( grid%mu_2, 't', config_flags,         &
                               ids, ide, jds, jde,                   &
                               ims, ime, jms, jme,                   &
                               ips, ipe, jps, jpe,                   &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij)      )

       CALL set_physical_bc2d( grid%mudf, 't', config_flags,         &
                               ids, ide, jds, jde,                   &
                               ims, ime, jms, jme,                   &
                               ips, ipe, jps, jpe,                   &
                               grid%i_start(ij), grid%i_end(ij),     &
                               grid%j_start(ij), grid%j_end(ij)      )

     END DO
     !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k4_pressp', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   CALL gpu_ckt( grid, 'k4_pressp', rk_step, grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend, mu_tend, &
        ims, ime, jms, jme, kms, kme, ips, MIN(ipe,ide-1), jps, MIN(jpe,jde-1), kps, kpe )
#endif
BENCH_END(set_phys_bc2_tim)
     small_steps : DO iteration = 1 , number_of_small_timesteps

       ! Boundary condition time (or communication time).  
#ifdef DM_PARALLEL
#      include "PERIOD_BDY_EM_B.inc"
#endif

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )

       DO ij = 1 , grid%num_tiles

BENCH_START(advance_uv_tim)
         CALL advance_uv ( grid%u_2, grid%ru_tend, grid%v_2, grid%rv_tend,        &
                           grid%p, grid%pb,                                       &
                           grid%ph_2, grid%php, grid%alt,  grid%al,               &
                           grid%mu_2, grid%muu, cqu, grid%muv, cqv, grid%mudf,    &
                           grid%c1h, grid%c2h, grid%c1f, grid%c2f,                &
                           grid%c3h, grid%c4h, grid%c3f, grid%c4f,                &
                           grid%msfux, grid%msfuy, grid%msfvx,                    &
                           grid%msfvx_inv, grid%msfvy,                            &
                           grid%rdx, grid%rdy, dts_rk,                            &
                           grid%cf1, grid%cf2, grid%cf3, grid%fnm, grid%fnp,      &
                           grid%emdiv,                                            &
                           grid%rdnw, config_flags,grid%spec_zone,                &
                           config_flags%non_hydrostatic, config_flags%top_lid,    &
                           ids, ide, jds, jde, kds, kde,                          &
                           ims, ime, jms, jme, kms, kme,                          &
                           grid%i_start(ij), grid%i_end(ij),                      &
                           grid%j_start(ij), grid%j_end(ij),                      &
                           k_start    , k_end                                     )
BENCH_END(advance_uv_tim)

       END DO
       !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k5_advuv', rk_step*100+iteration, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   CALL gpu_ckt( grid, 'k5_advuv', rk_step*100+iteration, grid%ru_tend, grid%rv_tend, rw_tend, ph_tend, t_tend, mu_tend, &
        ims, ime, jms, jme, kms, kme, ips, MIN(ipe,ide-1), jps, MIN(jpe,jde-1), kps, kpe )
#endif

!-----------------------------------------------------------
!  acoustic integration polar filter for smallstep u, v
!-----------------------------------------------------------

       IF (config_flags%polar) THEN

         CALL pxft ( grid=grid                                              &
               ,lineno=__LINE__                                             &
               ,flag_uv            = 1                                      &
               ,flag_rurv          = 0                                      &
               ,flag_wph           = 0                                      &
               ,flag_ww            = 0                                      &
               ,flag_t             = 0                                      &
               ,flag_mu            = 0                                      &
               ,flag_mut           = 0                                      &
               ,flag_moist         = 0                                      &
               ,flag_chem          = 0                                      &
               ,flag_tracer        = 0                                      &
               ,flag_scalar        = 0                                      &
               ,actual_distance_average  = .FALSE.                          &
               ,pos_def            = .FALSE.                                &
               ,swap_pole_with_next_j = .FALSE.                             &
               ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
               ,fft_filter_lat = config_flags%fft_filter_lat                &
               ,dclat = dclat                                               &
               ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
               ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
               ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
               ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
               ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

       END IF

!-----------------------------------------------------------
!  end acoustic integration polar filter for smallstep u, v
!-----------------------------------------------------------

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

BENCH_START(spec_bdy_uv_tim)
         IF( config_flags%specified .or. config_flags%nested ) THEN
           CALL spec_bdyupdate(grid%u_2, grid%ru_tend, dts_rk,      &
                               'u'         , config_flags, &
                                grid%spec_zone,                  &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),         &
                                grid%j_start(ij), grid%j_end(ij),         &
                                k_start    , k_end             )

           CALL spec_bdyupdate(grid%v_2, grid%rv_tend, dts_rk,      &
                                'v'         , config_flags, &
                                grid%spec_zone,                  &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),         &
                                grid%j_start(ij), grid%j_end(ij),         &
                                k_start    , k_end             )

         ENDIF
BENCH_END(spec_bdy_uv_tim)

       END DO
       !$OMP END PARALLEL DO

#ifdef DM_PARALLEL
!
!  Stencils for patch communications  (WCS, 29 June 2001)
!
!         *                     *
!       * + *      * + *        +
!         *                     *
!
!  u_2               x
!  v_2                          x
!
#     include "HALO_EM_C.inc"
#endif

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

        !  advance the mass in the column, theta, and calculate ww

BENCH_START(advance_mu_t_tim)
         CALL advance_mu_t( grid%ww, ww1, grid%u_2, grid%u_save, grid%v_2, grid%v_save, &
                          grid%mu_2, grid%mut, muave, grid%muts, grid%muu, grid%muv,    &
                          grid%mudf,                                                    &
                          grid%c1h, grid%c2h, grid%c1f, grid%c2f,                       &
                          grid%c3h, grid%c4h, grid%c3f, grid%c4f,                       &
                          grid%ru_m, grid%rv_m, grid%ww_m,                              &
                          grid%t_2, grid%t_save, t_2save, t_tend,                       &
                          mu_tend,                                                      &
                          grid%rdx, grid%rdy, dts_rk, grid%epssm,                       &
                          grid%dnw, grid%fnm, grid%fnp, grid%rdnw,                      &
                          grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv,            &
                          grid%msfvy, grid%msftx,grid%msfty,                            &
                          iteration, config_flags,                                      &
                          ids, ide, jds, jde, kds, kde,      &
                          ims, ime, jms, jme, kms, kme,      &
                          grid%i_start(ij), grid%i_end(ij),  &
                          grid%j_start(ij), grid%j_end(ij),  &
                          k_start    , k_end                )
BENCH_END(advance_mu_t_tim)
       ENDDO
       !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k6_advmt', rk_step*100+iteration, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif

!-----------------------------------------------------------
!  acoustic integration polar filter for smallstep mu, t
!-----------------------------------------------------------

       IF ( (config_flags%polar) ) THEN

         CALL pxft ( grid=grid                                               &
                ,lineno=__LINE__                                             &
                ,flag_uv            = 0                                      &
                ,flag_rurv          = 0                                      &
                ,flag_wph           = 0                                      &
                ,flag_ww            = 0                                      &
                ,flag_t             = 1                                      &
                ,flag_mu            = 1                                      &
                ,flag_mut           = 0                                      &
                ,flag_moist         = 0                                      &
                ,flag_chem          = 0                                      &
                ,flag_tracer        = 0                                      &
                ,flag_scalar        = 0                                      &
                ,actual_distance_average  = .FALSE.                          &
                ,pos_def            = .FALSE.                                &
                ,swap_pole_with_next_j = .FALSE.                             &
                ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                ,fft_filter_lat = config_flags%fft_filter_lat                &
                ,dclat = dclat                                               &
                ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

         grid%muts = grid%mut + grid%mu_2  ! reset muts using filtered mu_2
 
       END IF

!-----------------------------------------------------------
!  end acoustic integration polar filter for smallstep mu, t
!-----------------------------------------------------------

BENCH_START(spec_bdy_t_tim)

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

         IF( config_flags%specified .or. config_flags%nested ) THEN

           CALL spec_bdyupdate(grid%t_2, t_tend, dts_rk,        &
                               't'         , config_flags,      &
                               grid%spec_zone,                  &
                               ids,ide, jds,jde, kds,kde,       &
                               ims,ime, jms,jme, kms,kme,       &
                               ips,ipe, jps,jpe, kps,kpe,       &
                               grid%i_start(ij), grid%i_end(ij),&
                               grid%j_start(ij), grid%j_end(ij),&
                               k_start    , k_end              )

           CALL spec_bdyupdate(grid%mu_2, mu_tend, dts_rk,       &
                               'm'         , config_flags,      &
                               grid%spec_zone,                  &
                               ids,ide, jds,jde, 1  ,1  ,       &
                               ims,ime, jms,jme, 1  ,1  ,       &
                               ips,ipe, jps,jpe, 1  ,1  ,       &
                               grid%i_start(ij), grid%i_end(ij),&
                               grid%j_start(ij), grid%j_end(ij),&
                               1    , 1             )

           CALL spec_bdyupdate(grid%muts, mu_tend, dts_rk,      &
                              'm'         , config_flags, &
                              grid%spec_zone,                  &
                              ids,ide, jds,jde, 1  ,1  ,  & ! domain dims
                              ims,ime, jms,jme, 1  ,1  ,  & ! memory dims
                              ips,ipe, jps,jpe, 1  ,1  ,  & ! patch  dims
                              grid%i_start(ij), grid%i_end(ij),         &
                              grid%j_start(ij), grid%j_end(ij),         &
                              1    , 1             )
         ENDIF
BENCH_END(spec_bdy_t_tim)

         ! small (acoustic) step for the vertical momentum,
         ! density and coupled potential temperature.


BENCH_START(advance_w_tim)
         IF ( config_flags%non_hydrostatic ) THEN
           CALL advance_w( grid%w_2, rw_tend, grid%ww, w_save,         &
                           grid%u_2, grid%v_2,                         &
                           grid%mu_2, grid%mut, muave, grid%muts,      &
                           grid%c1h, grid%c2h, grid%c1f, grid%c2f,     &
                           grid%c3h, grid%c4h, grid%c3f, grid%c4f,     &
                           t_2save, grid%t_2, grid%t_save,             &
                           grid%ph_2, ph_save, grid%phb, ph_tend,      &
                           grid%ht, c2a, cqw, grid%alt, grid%alb,      &
                           a, alpha, gamma,                            &
                           grid%rdx, grid%rdy, dts_rk, t0, grid%epssm, &
                           grid%dnw, grid%fnm, grid%fnp, grid%rdnw,    &
                           grid%rdn, grid%cf1, grid%cf2, grid%cf3,     &
                           grid%msftx, grid%msfty,                     &
                           config_flags,  config_flags%top_lid,        &
                           ids,ide, jds,jde, kds,kde,                  &
                           ims,ime, jms,jme, kms,kme,                  &
                           grid%i_start(ij), grid%i_end(ij),           &
                           grid%j_start(ij), grid%j_end(ij),           &
                           k_start    , k_end                          )
         ENDIF
BENCH_END(advance_w_tim)

       ENDDO
       !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k7_advw', rk_step*100+iteration, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif

!-----------------------------------------------------------
!  acoustic integration polar filter for smallstep w, geopotential
!-----------------------------------------------------------

       IF ( (config_flags%polar) .AND. (config_flags%non_hydrostatic) ) THEN

         CALL pxft ( grid=grid                                               &
                ,lineno=__LINE__                                             &
                ,flag_uv            = 0                                      &
                ,flag_rurv          = 0                                      &
                ,flag_wph           = 1                                      &
                ,flag_ww            = 0                                      &
                ,flag_t             = 0                                      &
                ,flag_mu            = 0                                      &
                ,flag_mut           = 0                                      &
                ,flag_moist         = 0                                      &
                ,flag_chem          = 0                                      &
                ,flag_tracer        = 0                                      &
                ,flag_scalar        = 0                                      &
                ,actual_distance_average  = .FALSE.                          &
                ,pos_def            = .FALSE.                                &
                ,swap_pole_with_next_j = .FALSE.                             &
                ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                ,fft_filter_lat = config_flags%fft_filter_lat                &
                ,dclat = dclat                                               &
                ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

       END IF

!-----------------------------------------------------------
!  end acoustic integration polar filter for smallstep w, geopotential
!-----------------------------------------------------------

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

BENCH_START(sumflux_tim)
         CALL sumflux ( grid%u_2, grid%v_2, grid%ww,          &
                        grid%u_save, grid%v_save, ww1,        &
                        grid%muu, grid%muv,                   &
                        grid%c1h, grid%c2h, grid%c1f, grid%c2f, &
                        grid%c3h, grid%c4h, grid%c3f, grid%c4f, &
                        grid%ru_m, grid%rv_m, grid%ww_m, grid%epssm,  &
                        grid%msfux, grid% msfuy, grid%msfvx,  &
                        grid%msfvx_inv, grid%msfvy,           &
                        iteration, number_of_small_timesteps, &
                        ids, ide, jds, jde, kds, kde,         &
                        ims, ime, jms, jme, kms, kme,         &
                        grid%i_start(ij), grid%i_end(ij),     &
                        grid%j_start(ij), grid%j_end(ij),     &
                        k_start    , k_end                   )
BENCH_END(sumflux_tim)

         IF( config_flags%specified .or. config_flags%nested ) THEN

BENCH_START(spec_bdynhyd_tim)
           IF (config_flags%non_hydrostatic)  THEN
             CALL spec_bdyupdate_ph( ph_save, grid%ph_2, ph_tend,     &
                                     mu_tend, grid%muts,              &
                                     grid%c1f, grid%c2f, dts_rk,      &
                                     'h'         , config_flags,      &
                                     grid%spec_zone,                  &
                                     ids,ide, jds,jde, kds,kde,       &
                                     ims,ime, jms,jme, kms,kme,       &
                                     ips,ipe, jps,jpe, kps,kpe,       &
                                     grid%i_start(ij), grid%i_end(ij),&
                                     grid%j_start(ij), grid%j_end(ij),&
                                     k_start    , k_end               )
             IF( config_flags%specified ) THEN
               CALL zero_grad_bdy ( grid%w_2,                         &
                                    'w'         , config_flags,       &
                                    grid%spec_zone,                   &
                                    ids,ide, jds,jde, kds,kde,        &
                                    ims,ime, jms,jme, kms,kme,        &
                                    ips,ipe, jps,jpe, kps,kpe,        &
                                    grid%i_start(ij), grid%i_end(ij), &
                                    grid%j_start(ij), grid%j_end(ij), &
                                    k_start    , k_end                )
             ELSE
               CALL spec_bdyupdate ( grid%w_2, rw_tend, dts_rk,       &
                                     'h'         , config_flags,      &
                                     grid%spec_zone,                  &
                                     ids,ide, jds,jde, kds,kde,       &
                                     ims,ime, jms,jme, kms,kme,       &
                                     ips,ipe, jps,jpe, kps,kpe,       &
                                     grid%i_start(ij), grid%i_end(ij),&
                                     grid%j_start(ij), grid%j_end(ij),&
                                     k_start    , k_end               )
             ENDIF
           ENDIF
BENCH_END(spec_bdynhyd_tim)
         ENDIF

BENCH_START(cald_p_rho_tim)
         CALL calc_p_rho( grid%al, grid%p, grid%ph_2,                 &
                          grid%alt, grid%t_2, grid%t_save, c2a, pm1,  &
                          grid%mu_2, grid%muts,                       &
                          grid%c1h, grid%c2h, grid%c1f, grid%c2f,     &
                          grid%c3h, grid%c4h, grid%c3f, grid%c4f,     &
                          grid%znu, t0,                               &
                          grid%rdnw, grid%dnw, grid%smdiv,            &
                          config_flags%non_hydrostatic, iteration,    &
                          ids, ide, jds, jde, kds, kde,     &
                          ims, ime, jms, jme, kms, kme,     &
                          grid%i_start(ij), grid%i_end(ij), &
                          grid%j_start(ij), grid%j_end(ij), &
                          k_start    , k_end               )
BENCH_END(cald_p_rho_tim)

       ENDDO
       !$OMP END PARALLEL DO

#ifdef DM_PARALLEL
!
!  Stencils for patch communications  (WCS, 29 June 2001)
!
!         *                     *
!       * + *      * + *        +
!         *                     *
!
!  ph_2   x
!  al     x
!  p      x
!
!  2D variables (x,y)
!
!  mu_2   x
!  muts   x
!  mudf   x

#      include "HALO_EM_C2.inc"
#      include "PERIOD_BDY_EM_B3.inc"
#endif

BENCH_START(phys_bc_tim)
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

       ! boundary condition set for next small timestep

         CALL set_physical_bc3d( grid%ph_2, 'w', config_flags,          &
                                 ids, ide, jds, jde, kds, kde,     &
                                 ims, ime, jms, jme, kms, kme,     &
                                 ips, ipe, jps, jpe, kps, kpe,     &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij), &
                                 k_start    , k_end               )

         CALL set_physical_bc3d( grid%al, 'p', config_flags,            &
                                 ids, ide, jds, jde, kds, kde,     &
                                 ims, ime, jms, jme, kms, kme,     &
                                 ips, ipe, jps, jpe, kps, kpe,     &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij), &
                                 k_start    , k_end               )

         CALL set_physical_bc3d( grid%p, 'p', config_flags,             &
                                 ids, ide, jds, jde, kds, kde,     &
                                 ims, ime, jms, jme, kms, kme,     &
                                 ips, ipe, jps, jpe, kps, kpe,     &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij), &
                                 k_start    , k_end               )

         CALL set_physical_bc2d( grid%muts, 't', config_flags,          &
                                 ids, ide, jds, jde,               &
                                 ims, ime, jms, jme,               &
                                 ips, ipe, jps, jpe,               &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij) )

         CALL set_physical_bc2d( grid%mu_2, 't', config_flags,          &
                                 ids, ide, jds, jde,               &
                                 ims, ime, jms, jme,               &
                                 ips, ipe, jps, jpe,               &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij) )

         CALL set_physical_bc2d( grid%mudf, 't', config_flags,          &
                                 ids, ide, jds, jde,               &
                                 ims, ime, jms, jme,               &
                                 ips, ipe, jps, jpe,               &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij) )

       END DO
       !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k8_ssend', rk_step*100+iteration, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
BENCH_END(phys_bc_tim)

     END DO small_steps

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

       CALL wrf_debug ( 200 , ' call rk_small_finish' )

      ! change time-perturbation variables back to 
      ! full perturbation variables.
      ! first get updated mu at u and v points

BENCH_START(calc_mu_uv_tim)
       CALL calc_mu_uv_1 ( config_flags,                     &
                           grid%muts, grid%muus, grid%muvs,  &
                           ids, ide, jds, jde, kds, kde,     &
                           ims, ime, jms, jme, kms, kme,     &
                           grid%i_start(ij), grid%i_end(ij), &
                           grid%j_start(ij), grid%j_end(ij), &
                           k_start    , k_end               )
BENCH_END(calc_mu_uv_tim)
BENCH_START(small_step_finish_tim)
       CALL small_step_finish( grid%u_2, grid%u_1, grid%v_2, grid%v_1, grid%w_2, grid%w_1,     &
                               grid%t_2, grid%t_1, grid%ph_2, grid%ph_1, grid%ww, ww1,    &
                               grid%mu_2, grid%mu_1,                       &
                               grid%mut, grid%muts, grid%muu, grid%muus, grid%muv, grid%muvs,  & 
                               grid%c1h, grid%c2h, grid%c1f, grid%c2f, &
                               grid%c3h, grid%c4h, grid%c3f, grid%c4f, &
                               grid%u_save, grid%v_save, w_save,           &
                               grid%t_save, ph_save, mu_save,         &
                               grid%msfux,grid%msfuy, grid%msfvx,grid%msfvy, grid%msftx,grid%msfty, &
                               grid%h_diabatic,                       &
                               number_of_small_timesteps,dts_rk, &
                               rk_step, rk_order,                &
                               ids, ide, jds, jde, kds, kde,     &
                               ims, ime, jms, jme, kms, kme,     &
                               grid%i_start(ij), grid%i_end(ij), &
                               grid%j_start(ij), grid%j_end(ij), &
                               k_start    , k_end               )
!  call  to set ru_m, rv_m and ww_m b.c's for PD advection

       IF (rk_step == rk_order) THEN

         CALL set_physical_bc3d( grid%ru_m, 'u', config_flags,   &
                                 ids, ide, jds, jde, kds, kde,      &
                                 ims, ime, jms, jme, kms, kme,      &
                                 ips, ipe, jps, jpe, kps, kpe,      &
                                 grid%i_start(ij), grid%i_end(ij),  &
                                 grid%j_start(ij), grid%j_end(ij),  &
                                 k_start    , k_end                )

         CALL set_physical_bc3d( grid%rv_m, 'v', config_flags,   &
                                 ids, ide, jds, jde, kds, kde,      &
                                 ims, ime, jms, jme, kms, kme,      &
                                 ips, ipe, jps, jpe, kps, kpe,      &
                                 grid%i_start(ij), grid%i_end(ij),  &
                                 grid%j_start(ij), grid%j_end(ij),  &
                                 k_start    , k_end                )

         CALL set_physical_bc3d( grid%ww_m, 'w', config_flags,   &
                                 ids, ide, jds, jde, kds, kde,      &
                                 ims, ime, jms, jme, kms, kme,      &
                                 ips, ipe, jps, jpe, kps, kpe,      &
                                 grid%i_start(ij), grid%i_end(ij),  &
                                 grid%j_start(ij), grid%j_end(ij),  &
                                 k_start    , k_end                )

         CALL set_physical_bc2d( grid%mut, 't', config_flags,   &
                                 ids, ide, jds, jde,               &
                                 ims, ime, jms, jme,                &
                                 ips, ipe, jps, jpe,                &
                                 grid%i_start(ij), grid%i_end(ij),  &
                                 grid%j_start(ij), grid%j_end(ij) )

         CALL set_physical_bc2d( grid%muts, 't', config_flags,   &
                                 ids, ide, jds, jde,               &
                                 ims, ime, jms, jme,                &
                                 ips, ipe, jps, jpe,                &
                                 grid%i_start(ij), grid%i_end(ij),  &
                                 grid%j_start(ij), grid%j_end(ij) )
 
       END IF

BENCH_END(small_step_finish_tim)

     END DO
     !$OMP END PARALLEL DO
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'k9_ssfin', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif

!-----------------------------------------------------------
!  polar filter for full dynamics variables and time-averaged mass fluxes 
!-----------------------------------------------------------

     IF (config_flags%polar) THEN

       CALL pxft ( grid=grid                                                   &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 1                                      &
                  ,flag_rurv          = 1                                      &
                  ,flag_wph           = 1                                      &
                  ,flag_ww            = 1                                      &
                  ,flag_t             = 1                                      &
                  ,flag_mu            = 1                                      &
                  ,flag_mut           = 1                                      &
                  ,flag_moist         = 0                                      &
                  ,flag_chem          = 0                                      &
                  ,flag_tracer        = 0                                      &
                  ,flag_scalar        = 0                                      &
                  ,actual_distance_average  = .FALSE.                          &
                  ,pos_def            = .FALSE.                                &
                  ,swap_pole_with_next_j = .FALSE.                             &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

     END IF

!-----------------------------------------------------------
!  end polar filter for full dynamics variables and time-averaged mass fluxes 
!-----------------------------------------------------------

!-----------------------------------------------------------------------
!  add in physics tendency first if positive definite advection is used.
!  pd advection applies advective flux limiter on last runge-kutta step
!-----------------------------------------------------------------------
! first moisture

     IF ((config_flags%moist_adv_opt /= ORIGINAL .and. config_flags%moist_adv_opt /= WENO_SCALAR) .and. &
         (rk_step == rk_order)) THEN

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles
         CALL wrf_debug ( 200 , ' call rk_update_scalar_pd' )
         DO im = PARAM_FIRST_SCALAR, num_3d_m
           CALL rk_update_scalar_pd( im, im,                                   &
                                     moist_old(ims,kms,jms,im),                &
                                     moist_tend(ims,kms,jms,im),               &
                                     grid%c1h, grid%c2h,                       &
                                     grid%mu_1, grid%mu_1, grid%mub,  &
                                     rk_step, dt_rk, grid%spec_zone,           &
                                     config_flags,                             &
                                     ids, ide, jds, jde, kds, kde,             &
                                     ims, ime, jms, jme, kms, kme,             &
                                     grid%i_start(ij), grid%i_end(ij),         &
                                     grid%j_start(ij), grid%j_end(ij),         &
                                     k_start    , k_end                       )
         ENDDO
       END DO
       !$OMP END PARALLEL DO

!---------------------- positive definite bc call
#ifdef DM_PARALLEL
       IF (config_flags%moist_adv_opt /= ORIGINAL .and. config_flags%moist_adv_opt /= WENO_SCALAR) THEN
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#     include "HALO_EM_MOIST_OLD_E_5.inc"
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#     include "HALO_EM_MOIST_OLD_E_7.inc"
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
       ENDIF
#endif

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_MOIST_OLD.inc"
#endif

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles
         IF (num_3d_m >= PARAM_FIRST_SCALAR) THEN
           DO im = PARAM_FIRST_SCALAR , num_3d_m
             CALL set_physical_bc3d( moist_old(ims,kms,jms,im), 'p', config_flags,   &
                                     ids, ide, jds, jde, kds, kde,                  &
                                     ims, ime, jms, jme, kms, kme,                  &
                                     ips, ipe, jps, jpe, kps, kpe,                  &
                                     grid%i_start(ij), grid%i_end(ij),              &
                                     grid%j_start(ij), grid%j_end(ij),              &
                                     k_start    , k_end                            )
           END DO
         ENDIF
       END DO
       !$OMP END PARALLEL DO

     END IF  ! end if for moist_adv_opt

! scalars

     IF ((config_flags%scalar_adv_opt /= ORIGINAL .and. config_flags%scalar_adv_opt /= WENO_SCALAR) .and. &
         (rk_step == rk_order)) THEN

       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles
         CALL wrf_debug ( 200 , ' call rk_update_scalar_pd' )
         DO im = PARAM_FIRST_SCALAR, num_3d_s
           CALL rk_update_scalar_pd( im, im,                                  &
                                     scalar_old(ims,kms,jms,im),              &
                                     scalar_tend(ims,kms,jms,im),             &
                                     grid%c1h, grid%c2h,                      &
                                     grid%mu_1, grid%mu_1, grid%mub, &
                                     rk_step, dt_rk, grid%spec_zone,          &
                                     config_flags,                            &
                                     ids, ide, jds, jde, kds, kde,            &
                                     ims, ime, jms, jme, kms, kme,            &
                                     grid%i_start(ij), grid%i_end(ij),        &
                                     grid%j_start(ij), grid%j_end(ij),        &
                                     k_start    , k_end                      )
         ENDDO
       ENDDO
       !$OMP END PARALLEL DO

!---------------------- positive definite bc call
#ifdef DM_PARALLEL
       IF (config_flags%scalar_adv_opt /= ORIGINAL .and. config_flags%scalar_adv_opt /= WENO_SCALAR) THEN
#ifndef RSL
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#     include "HALO_EM_SCALAR_OLD_E_5.inc"
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#     include "HALO_EM_SCALAR_OLD_E_7.inc"
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
#else
         WRITE(wrf_err_message,*)'cannot use pd scheme with RSL - use RSL-LITE'
         CALL wrf_error_fatal(TRIM(wrf_err_message))
#endif   
  endif
#endif

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_SCALAR_OLD.inc"
#endif
         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )

         DO ij = 1 , grid%num_tiles
           IF (num_3d_s >= PARAM_FIRST_SCALAR) THEN
             DO im = PARAM_FIRST_SCALAR , num_3d_s
               CALL set_physical_bc3d(  scalar_old(ims,kms,jms,im), 'p', config_flags, &
                                        ids, ide, jds, jde, kds, kde,                    &
                                        ims, ime, jms, jme, kms, kme,                    &
                                        ips, ipe, jps, jpe, kps, kpe,                    &
                                        grid%i_start(ij), grid%i_end(ij),                &
                                        grid%j_start(ij), grid%j_end(ij),                &
                                        k_start    , k_end                              )
             END DO
           ENDIF
         END DO
         !$OMP END PARALLEL DO

       END IF  ! end if for scalar_adv_opt

! chem

       IF ((config_flags%chem_adv_opt /= ORIGINAL .and. config_flags%chem_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order)) THEN

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           CALL wrf_debug ( 200 , ' call rk_update_scalar_pd' )
           DO im = PARAM_FIRST_SCALAR, num_3d_c
             CALL rk_update_scalar_pd( im, im,                                  &
                                       chem_old(ims,kms,jms,im),                &
                                       chem_tend(ims,kms,jms,im),               &
                                       grid%c1h, grid%c2h,                      &
                                       grid%mu_1, grid%mu_1, grid%mub, &
                                       rk_step, dt_rk, grid%spec_zone,          &
                                       config_flags,                            &
                                       ids, ide, jds, jde, kds, kde,            &
                                       ims, ime, jms, jme, kms, kme,            &
                                       grid%i_start(ij), grid%i_end(ij),        &
                                       grid%j_start(ij), grid%j_end(ij),        &
                                       k_start    , k_end                      )
           ENDDO
         END DO
         !$OMP END PARALLEL DO

!---------------------- positive definite bc call
#ifdef DM_PARALLEL
         IF (config_flags%chem_adv_opt /= ORIGINAL .and. config_flags%chem_adv_opt /= WENO_SCALAR) THEN
           IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#     include "HALO_EM_CHEM_OLD_E_5.inc"
           ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#     include "HALO_EM_CHEM_OLD_E_7.inc"
           ELSE
             WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
             CALL wrf_error_fatal(TRIM(wrf_err_message))
           ENDIF
         ENDIF
#endif

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_CHEM_OLD.inc"
#endif

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           IF (num_3d_c >= PARAM_FIRST_SCALAR) THEN
             DO im = PARAM_FIRST_SCALAR , num_3d_c
               CALL set_physical_bc3d(  chem_old(ims,kms,jms,im), 'p', config_flags,     &
                                        ids, ide, jds, jde, kds, kde,                    &
                                        ims, ime, jms, jme, kms, kme,                    &
                                        ips, ipe, jps, jpe, kps, kpe,                    &
                                        grid%i_start(ij), grid%i_end(ij),                &
                                        grid%j_start(ij), grid%j_end(ij),                &
                                        k_start    , k_end                              )
             END DO 
           ENDIF
         END DO
         !$OMP END PARALLEL DO

       ENDIF  ! end if for chem_adv_opt

! tracer

       IF ((config_flags%tracer_adv_opt /= ORIGINAL .and. config_flags%tracer_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order)) THEN

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           CALL wrf_debug ( 200 , ' call rk_update_scalar_pd' )
           DO im = PARAM_FIRST_SCALAR, num_tracer
             CALL rk_update_scalar_pd( im, im,                                  &
                                       tracer_old(ims,kms,jms,im),                &
                                       tracer_tend(ims,kms,jms,im),               &
                                       grid%c1h, grid%c2h,                      &
                                       grid%mu_1, grid%mu_1, grid%mub, &
                                       rk_step, dt_rk, grid%spec_zone,          &
                                       config_flags,                            &
                                       ids, ide, jds, jde, kds, kde,            &
                                       ims, ime, jms, jme, kms, kme,            &
                                       grid%i_start(ij), grid%i_end(ij),        &
                                       grid%j_start(ij), grid%j_end(ij),        &
                                       k_start    , k_end                      )
           ENDDO
         END DO
         !$OMP END PARALLEL DO

!---------------------- positive definite bc call
#ifdef DM_PARALLEL
         IF (config_flags%tracer_adv_opt /= ORIGINAL .and. config_flags%tracer_adv_opt /= WENO_SCALAR) THEN
           IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#     include "HALO_EM_TRACER_OLD_E_5.inc"
           ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#     include "HALO_EM_TRACER_OLD_E_7.inc"
           ELSE
             WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
             CALL wrf_error_fatal(TRIM(wrf_err_message))
           ENDIF
         ENDIF
#endif

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_TRACER_OLD.inc"
#endif

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           IF (num_tracer >= PARAM_FIRST_SCALAR) THEN
             DO im = PARAM_FIRST_SCALAR , num_tracer
               CALL set_physical_bc3d(  tracer_old(ims,kms,jms,im), 'p', config_flags,   &
                                        ids, ide, jds, jde, kds, kde,                    &
                                        ims, ime, jms, jme, kms, kme,                    &
                                        ips, ipe, jps, jpe, kps, kpe,                    &
                                        grid%i_start(ij), grid%i_end(ij),                &
                                        grid%j_start(ij), grid%j_end(ij),                &
                                        k_start    , k_end                              )
             END DO 
           ENDIF
         END DO
         !$OMP END PARALLEL DO

       ENDIF  ! end if for tracer_adv_opt

! tke

       IF ((config_flags%tke_adv_opt /= ORIGINAL .and. config_flags%tke_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order) &
           .and. (config_flags%km_opt .eq. 2)                ) THEN

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           CALL wrf_debug ( 200 , ' call rk_update_scalar_pd' )
           CALL rk_update_scalar_pd( 1, 1,                                    &
                                     grid%tke_1,                              &
                                     tke_tend(ims,kms,jms),                   &
                                     grid%c1h, grid%c2h,                      &
                                     grid%mu_1, grid%mu_1, grid%mub,          &
                                     rk_step, dt_rk, grid%spec_zone,          &
                                     config_flags,                            &
                                     ids, ide, jds, jde, kds, kde,            &
                                     ims, ime, jms, jme, kms, kme,            &
                                     grid%i_start(ij), grid%i_end(ij),        &
                                     grid%j_start(ij), grid%j_end(ij),        &
                                     k_start    , k_end                       )
         ENDDO
         !$OMP END PARALLEL DO

!---------------------- positive definite bc call
#ifdef DM_PARALLEL
         IF (config_flags%tke_adv_opt /= ORIGINAL .and. config_flags%tke_adv_opt /= WENO_SCALAR) THEN
           IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#     include "HALO_EM_TKE_OLD_E_5.inc"
           ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#     include "HALO_EM_TKE_OLD_E_7.inc"
           ELSE
             WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
             CALL wrf_error_fatal(TRIM(wrf_err_message))
           ENDIF
         ENDIF
#endif

#ifdef DM_PARALLEL
#  include "PERIOD_BDY_EM_TKE_OLD.inc"
#endif

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij )
         DO ij = 1 , grid%num_tiles
           CALL set_physical_bc3d(  grid%tke_1, 'p', config_flags,  &
                                    ids, ide, jds, jde, kds, kde,      &
                                    ims, ime, jms, jme, kms, kme,      &
                                    ips, ipe, jps, jpe, kps, kpe,      &
                                    grid%i_start(ij), grid%i_end(ij),  &
                                    grid%j_start(ij), grid%j_end(ij),  &
                                    k_start    , k_end                )
         END DO
         !$OMP END PARALLEL DO

!---  end of positive definite physics tendency update

       END IF  ! end if for tke_adv_opt

#ifdef DM_PARALLEL
!
!  Stencils for patch communications  (WCS, 29 June 2001)
!
!          * * * * *            
!          * * * * *            
!          * * + * *            
!          * * * * *            
!          * * * * *            
!
! ru_m         x
! rv_m         x
! ww_m         x
! mut          x
!
!--------------------------------------------------------------

#  include "HALO_EM_D.inc"
! WCS addition 11/19/08
#  include "PERIOD_EM_DA.inc"
#endif

!<DESCRIPTION>
!<pre>
! (4) Still within the RK loop, the scalar variables are advanced.
!
!    For the moist and chem variables, each one is advanced
!    individually, using named loops "moist_variable_loop:"
!    and "chem_variable_loop:".  Each RK substep begins by
!    calculating the advective tendency, and, for the first RK step, 
!    3D mixing (calling rk_scalar_tend) followed by an update
!    of the scalar (calling rk_update_scalar).
!</pre>
!</DESCRIPTION>

#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4

       ! L. Fita, CIMA. Feb. 2018
       ! Initializing values it gives unitialize values on that unconsidered
       ! species
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij, tenddec )
       moist_tile_loop_ini: DO ij = 1 , grid%num_tiles
         DO iz=kms,kme
           grid%qv_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qv_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qvttend = 0.
           grid%qc_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qc_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qcttend = 0.
           grid%qr_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qr_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qrttend = 0.
           grid%qs_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qs_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qsttend = 0.
           grid%qi_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qi_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qittend = 0.
           grid%qg_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qg_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qgttend = 0.
           grid%qh_hadv(ims:ime,iz,jms:jme) = 0.
           grid%qh_zadv(ims:ime,iz,jms:jme) = 0.
           grid%qhttend = 0.
         END DO
       END DO moist_tile_loop_ini
       !$OMP END PARALLEL DO
#endif
#endif
#endif
       moist_scalar_advance: IF (num_3d_m >= PARAM_FIRST_SCALAR )  THEN

         moist_variable_loop: DO im = PARAM_FIRST_SCALAR, num_3d_m

! adv_moist_cond is set in module_physics_init based on mp_physics choice
!       true except for Ferrier scheme

           IF (grid%adv_moist_cond .or. im==p_qv ) THEN

             !$OMP PARALLEL DO   &
             !$OMP PRIVATE ( ij, tenddec )
             moist_tile_loop_1: DO ij = 1 , grid%num_tiles

               CALL wrf_debug ( 200 , ' call rk_scalar_tend' )
#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4
               tenddec = .true.
#endif
#endif
#else
               tenddec = .false.
#endif

BENCH_START(rk_scalar_tend_tim)
               CALL rk_scalar_tend (  im, im, config_flags, tenddec,         & 
                           rk_step, dt_rk,                                   &
                           grid%ru_m, grid%rv_m, grid%ww_m, wwE, wwI,        &
                           grid%u_1, grid%v_1,                               &  
                           grid%muts, grid%mub, grid%mu_1,                   &
                           grid%c1h, grid%c2h,  grid%c1f, grid%c2f,          &
                           grid%alt,                                         &
                           moist_old(ims,kms,jms,im),                        &
                           moist(ims,kms,jms,im),                            &
                           moist_tend(ims,kms,jms,im),                       &
                           advect_tend,h_tendency,z_tendency,grid%rqvften,   & 
                           grid%qv_base, .true., grid%fnm, grid%fnp,         &
                           grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv,&
                           grid%msfvy, grid%msftx,grid%msfty,                & 
                           grid%rdx, grid%rdy, grid%rdn, grid%rdnw, grid%khdif, &
                           grid%kvdif, grid%xkhh,                            &
                           grid%diff_6th_opt, grid%diff_6th_factor,          &
                           config_flags%moist_adv_opt,                       &
                           grid%phb, grid%ph_2,                              &
                           config_flags%moist_mix2_off,                      &
                           config_flags%moist_mix6_off,                      &
                           ids, ide, jds, jde, kds, kde,     &
                           ims, ime, jms, jme, kms, kme,     &
                           grid%i_start(ij), grid%i_end(ij), &
                           grid%j_start(ij), grid%j_end(ij), &
                           k_start    , k_end               )

               IF( rk_step == 1 .AND. config_flags%use_q_diabatic == 1 )THEN
               IF( im.eq.p_qv .or. im.eq.p_qc )THEN
                   CALL q_diabatic_add  ( im, im,            & 
                           dt_rk, grid%mut,                  &
                           grid%c1h, grid%c2h,               &
                           grid%qv_diabatic,                 &
                           grid%qc_diabatic,                 &
                           moist_tend(ims,kms,jms,im),       &
                           ids, ide, jds, jde, kds, kde,     &
                           ims, ime, jms, jme, kms, kme,     &
                           grid%i_start(ij), grid%i_end(ij), &
                           grid%j_start(ij), grid%j_end(ij), &
                           k_start    , k_end               )
               ENDIF
               ENDIF

BENCH_END(rk_scalar_tend_tim)

BENCH_START(rlx_bdy_scalar_tim)
               IF( ( config_flags%specified .or. config_flags%nested ) .and. rk_step == 1 ) THEN 
                 IF ( im .EQ. P_QV .OR. config_flags%nested .OR. &
                    ( config_flags%specified .AND. config_flags%have_bcs_moist ) ) THEN
                   CALL relax_bdy_scalar ( moist_tend(ims,kms,jms,im),            & 
                                     moist(ims,kms,jms,im),  grid%mut,         &
                                     grid%c1h, grid%c2h,                       &
                                     moist_bxs(jms,kms,1,im),moist_bxe(jms,kms,1,im), &
                                     moist_bys(ims,kms,1,im),moist_bye(ims,kms,1,im), &
                                     moist_btxs(jms,kms,1,im),moist_btxe(jms,kms,1,im), &
                                     moist_btys(ims,kms,1,im),moist_btye(ims,kms,1,im), &
                                     config_flags%spec_bdy_width, grid%spec_zone, grid%relax_zone, &
                                     grid%dtbc, grid%fcx, grid%gcx,             &
                                     config_flags,               &
                                     ids,ide, jds,jde, kds,kde,  & ! domain dims
                                     ims,ime, jms,jme, kms,kme,  & ! memory dims
                                     ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                     grid%i_start(ij), grid%i_end(ij),      &
                                     grid%j_start(ij), grid%j_end(ij),      &
                                     k_start, k_end                        )

                   CALL spec_bdy_scalar  ( moist_tend(ims,kms,jms,im),                &
                                     moist_bxs(jms,kms,1,im),moist_bxe(jms,kms,1,im), &
                                     moist_bys(ims,kms,1,im),moist_bye(ims,kms,1,im), &
                                     moist_btxs(jms,kms,1,im),moist_btxe(jms,kms,1,im), &
                                     moist_btys(ims,kms,1,im),moist_btye(ims,kms,1,im), &
                                     config_flags%spec_bdy_width, grid%spec_zone,                 &
                                     config_flags,               &
                                     ids,ide, jds,jde, kds,kde,  & ! domain dims
                                     ims,ime, jms,jme, kms,kme,  & ! memory dims
                                     ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                     grid%i_start(ij), grid%i_end(ij),          &
                                     grid%j_start(ij), grid%j_end(ij),          &
                                     k_start, k_end                               )
                 ENDIF
               ENDIF
BENCH_END(rlx_bdy_scalar_tim)

             ENDDO moist_tile_loop_1
             !$OMP END PARALLEL DO

             !$OMP PARALLEL DO   &
             !$OMP PRIVATE ( ij, tenddec )
             moist_tile_loop_2: DO ij = 1 , grid%num_tiles

               CALL wrf_debug ( 200 , ' call rk_update_scalar' )
#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4
               tenddec = .true.
#endif
#endif
#else
               tenddec = .false.
#endif

BENCH_START(update_scal_tim)
               CALL rk_update_scalar( scs=im, sce=im,                                  &
                               scalar_1=moist_old(ims,kms,jms,im),                     &
                               scalar_2=moist(ims,kms,jms,im),                         &
                               sc_tend=moist_tend(ims,kms,jms,im),                     &
#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4
                               advh_t=advh_t(ims:ime,kms:kme,jms:jme,1),               &
                               advz_t=advz_t(ims:ime,kms:kme,jms:jme,1),               &
#endif
#endif
#endif
                               advect_tend=advect_tend,                                &
                               h_tendency=h_tendency, z_tendency=z_tendency,           & 
                               msftx=grid%msftx,msfty=grid%msfty,                      &
                               c1=grid%c1h, c2=grid%c2h,                               &
                               mu_old=grid%mu_1, mu_new=grid%mu_2, mu_base=grid%mub,   &
                               rk_step=rk_step, dt=dt_rk, spec_zone=grid%spec_zone,    &
                               config_flags=config_flags, tenddec=tenddec,             & 
                               ids=ids, ide=ide, jds=jds, jde=jde, kds=kds, kde=kde,   &
                               ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, kme=kme,   &
                               its=grid%i_start(ij), ite=grid%i_end(ij),               &
                               jts=grid%j_start(ij), jte=grid%j_end(ij),               &
                               kts=k_start    , kte=k_end                              )
               IF( rk_step == rk_order .AND. config_flags%use_q_diabatic == 1 )THEN
               IF( im.eq.p_qv .or. im.eq.p_qc )THEN
                   CALL q_diabatic_subtr( im, im,            & 
                           dt_rk,                            &
                           grid%qv_diabatic,                 &
                           grid%qc_diabatic,                 &
                           moist(ims,kms,jms,im),            &
                           ids, ide, jds, jde, kds, kde,     &
                           ims, ime, jms, jme, kms, kme,     &
                           grid%i_start(ij), grid%i_end(ij), &
                           grid%j_start(ij), grid%j_end(ij), &
                           k_start    , k_end               )
               ENDIF
               ENDIF
#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4
               IF (rk_step .eq. config_flags%rk_ord .AND. curr_secs2 > 0. .AND.  &
                 config_flags%output_cordex == 1 .AND. config_flags%output_wb == 1) THEN
! L. Fita, January 2018. CIMA
! There is a need to keep the results for each specie since module provides
! accumulated values
                 IF (im == P_QV) THEN
                   DO iz=kms,kme
                     grid%qv_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qv_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qv_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qv_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QC) THEN
                   DO iz=kms,kme
                     grid%qc_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qc_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qc_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qc_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QR) THEN
                   DO iz=kms,kme
                     grid%qr_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qr_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qr_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qr_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QS) THEN
                   DO iz=kms,kme
                     grid%qs_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qs_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qs_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qs_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QI) THEN
                   DO iz=kms,kme
                     grid%qi_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qi_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qi_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qi_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QH) THEN
                   DO iz=kms,kme
                     grid%qh_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qh_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qh_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qh_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
                 IF (im == P_QG) THEN
                   DO iz=kms,kme
                     grid%qg_hadv(ims:ime,iz,jms:jme) = h_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     grid%qg_zadv(ims:ime,iz,jms:jme) = z_tendency(ims:ime,iz,jms:jme)*               &
                       grid%msfty(ims:ime,jms:jme)/(grid%mu_2(ims:ime,jms:jme)+grid%mub(ims:ime,jms:jme))
                     !grid%qg_hadv(ims:ime,iz,jms:jme) = advh_t(ims:ime,iz,jms:jme,1)
                     !grid%qg_zadv(ims:ime,iz,jms:jme) = advz_t(ims:ime,iz,jms:jme,1)
                   END DO
                 END IF
!                i2 = INT((ime + ims)/2)
!                j2 = INT((jme + jms)/2)
!                 WRITE(message,*)'    Lluis P_QV:', P_QV,' P_QC:',P_QC, ' P_QR:',P_QR,' P_QS:',P_QS,' P_QI:',P_QI,' P_QH:',P_QH,' P_QG:',P_QG
!                 CALL wrf_debug(100,message)
!                 WRITE(message,*)'    Lluis im:', im, ' 2 h_tend:', h_tendency(i2,2,j2), ' v_tend:', z_tendency(i2,2,j2), ' advh_t:', advh_t(i2,2,j2,1), ' advz_t 2:', advz_t(i2,2,j2,1) 
!                 CALL wrf_debug(100,message)
!                 WRITE(message,*)'    Lluis qvh:', grid%qv_hadv(i2,2,j2), ' qch:', grid%qc_hadv(i2,2,j2), ' qrh:', grid%qr_hadv(i2,2,j2), ' qsh:', grid%qs_hadv(i2,2,j2), ' qih:', grid%qh_hadv(i2,2,j2), ' qhh:', grid%qh_hadv(i2,2,j2), ' qgh:', grid%qg_hadv(i2,2,j2)
!                 CALL wrf_debug(100,message)
               END IF
#endif
#endif
#endif
BENCH_END(update_scal_tim)

BENCH_START(flow_depbdy_tim)
               IF( config_flags%specified .AND. ( .NOT. config_flags%have_bcs_moist ) ) THEN
                 IF(im .ne. P_QV)THEN
                   CALL flow_dep_bdy  (  moist(ims,kms,jms,im),                 &
                                grid%ru_m, grid%rv_m, config_flags,             &
                                grid%spec_zone,                                 &
                                ids,ide, jds,jde, kds,kde,                      &
                                ims,ime, jms,jme, kms,kme,                      &
                                ips,ipe, jps,jpe, kps,kpe,                      &
                                grid%i_start(ij), grid%i_end(ij),               &
                                grid%j_start(ij), grid%j_end(ij),               &
                                k_start, k_end                               )
                 ENDIF
               ENDIF
BENCH_END(flow_depbdy_tim)

             ENDDO moist_tile_loop_2
             !$OMP END PARALLEL DO

           ENDIF  !-- if (grid%adv_moist_cond .or. im==p_qv ) then

         ENDDO moist_variable_loop

       ENDIF moist_scalar_advance

BENCH_START(tke_adv_tim)
       TKE_advance: IF (config_flags%km_opt .eq. 2.or.config_flags%km_opt.eq.5) then ! XZ
#ifdef DM_PARALLEL
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#       include "HALO_EM_TKE_ADVECT_3.inc"
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#       include "HALO_EM_TKE_ADVECT_5.inc"
         ELSE
          WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
          CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
#endif
         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )
         tke_tile_loop_1: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_scalar_tend for tke' )
           tenddec = .false.
           CALL rk_scalar_tend ( 1, 1, config_flags, tenddec,                      & 
                            rk_step, dt_rk,                                        &
                            grid%ru_m, grid%rv_m, grid%ww_m, wwE, wwI,             &
                            grid%u_1, grid%v_1,                                    &  
                            grid%muts, grid%mub, grid%mu_1,                        &
                            grid%c1h, grid%c2h,  grid%c1f, grid%c2f,               &
                            grid%alt,                                              &
                            grid%tke_1,                                            &
                            grid%tke_2,                                            &
                            tke_tend(ims,kms,jms),                                 &
                            advect_tend,h_tendency,z_tendency,grid%rqvften,        & 
                            grid%qv_base, .false., grid%fnm, grid%fnp,             &
                            grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv,     &
                            grid%msfvy, grid%msftx,grid%msfty,                     &
                            grid%rdx, grid%rdy, grid%rdn, grid%rdnw, grid%khdif,   &
                            grid%kvdif, grid%xkhh,                                 &
                            grid%diff_6th_opt, grid%diff_6th_factor,               &
                            config_flags%tke_adv_opt,                              &
                            grid%phb, grid%ph_2,                                   &
                            config_flags%tke_mix2_off,                             &
                            config_flags%tke_mix6_off,                             &
                            ids, ide, jds, jde, kds, kde,     &
                            ims, ime, jms, jme, kms, kme,     &
                            grid%i_start(ij), grid%i_end(ij), &
                            grid%j_start(ij), grid%j_end(ij), &
                            k_start    , k_end               )

         ENDDO tke_tile_loop_1
         !$OMP END PARALLEL DO

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )
         tke_tile_loop_2: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_update_scalar' )
           tenddec = .false.
           CALL rk_update_scalar( scs=1,  sce=1,                                          &
                                  scalar_1=grid%tke_1,                                    &
                                  scalar_2=grid%tke_2,                                    &
                                  sc_tend=tke_tend(ims,kms,jms),                          &
                                  advect_tend=advect_tend,                                &
                                  h_tendency=h_tendency, z_tendency=z_tendency,           & 
                                  msftx=grid%msftx,msfty=grid%msfty,                      &
                                  c1=grid%c1h, c2=grid%c2h,                               &
                                  mu_old=grid%mu_1, mu_new=grid%mu_2, mu_base=grid%mub,   &
                                  rk_step=rk_step, dt=dt_rk, spec_zone=grid%spec_zone,    &
                                  config_flags=config_flags, tenddec=tenddec,             & 
                                  ids=ids, ide=ide, jds=jds, jde=jde, kds=kds, kde=kde,   &
                                  ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, kme=kme,   &
                                  its=grid%i_start(ij), ite=grid%i_end(ij),               &
                                  jts=grid%j_start(ij), jte=grid%j_end(ij),               &
                                  kts=k_start    , kte=k_end                              )

! bound the tke (greater than 0, less than tke_upper_bound)

           CALL bound_tke( grid%tke_2, grid%tke_upper_bound,    &
                           ids, ide, jds, jde, kds, kde,        &
                           ims, ime, jms, jme, kms, kme,        &
                           grid%i_start(ij), grid%i_end(ij),    &
                           grid%j_start(ij), grid%j_end(ij),    &
                           k_start    , k_end                  )

           IF( config_flags%specified .or. config_flags%nested ) THEN
              CALL flow_dep_bdy (  grid%tke_2,                     &
                                   grid%ru_m, grid%rv_m, config_flags,               &
                                   grid%spec_zone,                              &
                                   ids,ide, jds,jde, kds,kde,  & ! domain dims
                                   ims,ime, jms,jme, kms,kme,  & ! memory dims
                                   ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                   grid%i_start(ij), grid%i_end(ij),       &
                                   grid%j_start(ij), grid%j_end(ij),       &
                                   k_start, k_end                               )
           ENDIF
         ENDDO tke_tile_loop_2
         !$OMP END PARALLEL DO

       ENDIF TKE_advance
BENCH_END(tke_adv_tim)

#if (WRF_CHEM == 1)
!  next the chemical species
BENCH_START(chem_adv_tim)
       chem_scalar_advance: IF (num_3d_c >= PARAM_FIRST_SCALAR)  THEN

         chem_variable_loop: DO ic = PARAM_FIRST_SCALAR, num_3d_c

           !$OMP PARALLEL DO   &
           !$OMP PRIVATE ( ij, tenddec )
           chem_tile_loop_1: DO ij = 1 , grid%num_tiles

             CALL wrf_debug ( 200 , ' call rk_scalar_tend in chem_tile_loop_1' )
             tenddec = (( config_flags%chemdiag == USECHEMDIAG ) .and. &
                        ( adv_ct_indices(ic) >= PARAM_FIRST_SCALAR ))
             CALL rk_scalar_tend ( ic, ic, config_flags, tenddec,                & 
                              rk_step, dt_rk,                                    &
                              grid%ru_m, grid%rv_m, grid%ww_m, wwE, wwI,         &
                              grid%u_1, grid%v_1,                                &  
                              grid%muts, grid%mub, grid%mu_1,                    &
                              grid%c1h, grid%c2h,  grid%c1f, grid%c2f,           &
                              grid%alt,                                          &
                              chem_old(ims,kms,jms,ic),                          &
                              chem(ims,kms,jms,ic),                              &
                              chem_tend(ims,kms,jms,ic),                         &
                              advect_tend,h_tendency,z_tendency,grid%rqvften,    & 
                              grid%qv_base, .false., grid%fnm, grid%fnp,         &
                              grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv, &
                              grid%msfvy, grid%msftx,grid%msfty,                 &
                              grid%rdx, grid%rdy, grid%rdn, grid%rdnw,           &
                              grid%khdif, grid%kvdif, grid%xkhh,                 &
                              grid%diff_6th_opt, grid%diff_6th_factor,           &
                              config_flags%chem_adv_opt,                         &
                              grid%phb, grid%ph_2,                               &
                              config_flags%chem_mix2_off,                        &
                              config_flags%chem_mix6_off,                        &
                              ids, ide, jds, jde, kds, kde,                      &
                              ims, ime, jms, jme, kms, kme,                      &
                              grid%i_start(ij), grid%i_end(ij),                  &
                              grid%j_start(ij), grid%j_end(ij),                  &
                              k_start    , k_end                                )
!
! Currently, chemistry species with specified boundaries (i.e. the mother
! domain)  are being over written by flow_dep_bdy_chem. So, relax_bdy and
! spec_bdy are only called for nests. For boundary conditions from global model or larger domain,
! chem is uncoupled, and only used for one row/column on inflow (if have_bcs_chem=.true.) 
!
           IF( ( config_flags%nested ) .and. rk_step == 1 ) THEN
             IF(ic.eq.1)CALL wrf_debug ( 10 , ' have_bcs_chem' )
             CALL relax_bdy_scalar ( chem_tend(ims,kms,jms,ic),                                    &
                                     chem(ims,kms,jms,ic),  grid%mut,                              &
                                     grid%c1h, grid%c2h,                       &
                                     chem_bxs(jms,kms,1,ic),chem_bxe(jms,kms,1,ic),                &
                                     chem_bys(ims,kms,1,ic),chem_bye(ims,kms,1,ic),                &
                                     chem_btxs(jms,kms,1,ic),chem_btxe(jms,kms,1,ic),              &
                                     chem_btys(ims,kms,1,ic),chem_btye(ims,kms,1,ic),              &
                                     config_flags%spec_bdy_width, grid%spec_zone, grid%relax_zone, &
                                     grid%dtbc, grid%fcx, grid%gcx,                                &
                                     config_flags,                                                 &
                                     ids,ide, jds,jde, kds,kde,                                    &
                                     ims,ime, jms,jme, kms,kme,                                    &
                                     ips,ipe, jps,jpe, kps,kpe,                                    &
                                     grid%i_start(ij), grid%i_end(ij),                             &
                                     grid%j_start(ij), grid%j_end(ij),                             &
                                     k_start, k_end                                                )
             CALL spec_bdy_scalar  ( chem_tend(ims,kms,jms,ic),                 &
                                     chem_bxs(jms,kms,1,ic),chem_bxe(jms,kms,1,ic),                &
                                     chem_bys(ims,kms,1,ic),chem_bye(ims,kms,1,ic),                &
                                     chem_btxs(jms,kms,1,ic),chem_btxe(jms,kms,1,ic),              &
                                     chem_btys(ims,kms,1,ic),chem_btye(ims,kms,1,ic),              &
                                     config_flags%spec_bdy_width, grid%spec_zone,                  &
                                     config_flags,                                                 &
                                     ids,ide, jds,jde, kds,kde,                                    &
                                     ims,ime, jms,jme, kms,kme,                                    &
                                     ips,ipe, jps,jpe, kps,kpe,                                    &
                                     grid%i_start(ij), grid%i_end(ij),                             &
                                     grid%j_start(ij), grid%j_end(ij),                             &
                                     k_start, k_end                                                )
           ENDIF

         ENDDO chem_tile_loop_1
         !$OMP END PARALLEL DO

if ( config_flags%do_pvozone ) then
#ifdef DM_PARALLEL
#  include "HALO_EM_D_PV.inc"
#endif
end if

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )

         chem_tile_loop_2: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_update_scalar' )
           tenddec = (( config_flags%chemdiag == USECHEMDIAG ) .and. &
                      ( adv_ct_indices(ic) >= PARAM_FIRST_SCALAR ))
           CALL rk_update_scalar( scs=ic, sce=ic,                                         &
                                  scalar_1=chem_old(ims,kms,jms,ic),                      &
                                  scalar_2=chem(ims,kms,jms,ic),                          &
                                  sc_tend=chem_tend(ims,kms,jms,ic),                      &
                                  advh_t=advh_ct(ims,kms,jms,adv_ct_indices(ic)),         &
                                  advz_t=advz_ct(ims,kms,jms,adv_ct_indices(ic)),         &
                                  advect_tend=advect_tend,                                &
                                  h_tendency=h_tendency, z_tendency=z_tendency,           & 
                                  msftx=grid%msftx,msfty=grid%msfty,                      &
                                  c1=grid%c1h, c2=grid%c2h,                               &
                                  mu_old=grid%mu_1, mu_new=grid%mu_2, mu_base=grid%mub,   &
                                  rk_step=rk_step, dt=dt_rk, spec_zone=grid%spec_zone,    &
                                  config_flags=config_flags, tenddec=tenddec,             & 
                                  ids=ids, ide=ide, jds=jds, jde=jde, kds=kds, kde=kde,   &
                                  ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, kme=kme,   &
                                  its=grid%i_start(ij), ite=grid%i_end(ij),               &
                                  jts=grid%j_start(ij), jte=grid%j_end(ij),               &
                                  kts=k_start    , kte=k_end                              )

           IF( config_flags%specified  ) THEN

             IF( config_flags%perturb_chem_bdy==1 ) THEN

                 IF(ic.eq.PARAM_FIRST_SCALAR .and. ij.eq.1) &
                 CALL wrf_debug (10 , ' spec_bdy_chem_perturb' )

                 CALL spec_bdy_chem_perturb ( config_flags%periodic_x,   &
                      chem_btxs(jms,kms,1,ic), chem_btxe(jms,kms,1,ic),  &
                      chem_btys(ims,kms,1,ic), chem_btye(ims,kms,1,ic),  &
                      grid%rand_pert,                                    &
                      config_flags%spec_bdy_width, grid%spec_zone,       &
                      grid%num_stoch_levels,      & ! stoch  dims
                      ids,ide, jds,jde, kds,kde,  & ! domain dims
                      ims,ime, jms,jme, kms,kme,  & ! memory dims
                      ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                      grid%i_start(ij), grid%i_end(ij),                  &
                      grid%j_start(ij), grid%j_end(ij),                  &
                      k_start, k_end                                  )
             ENDIF

             CALL flow_dep_bdy_chem( chem(ims,kms,jms,ic),                          &
                                     chem_bxs(jms,kms,1,ic), chem_btxs(jms,kms,1,ic),  &
                                     chem_bxe(jms,kms,1,ic), chem_btxe(jms,kms,1,ic),  &
                                     chem_bys(ims,kms,1,ic), chem_btys(ims,kms,1,ic),  &
                                     chem_bye(ims,kms,1,ic), chem_btye(ims,kms,1,ic),  &
                                     dt_rk+grid%dtbc,                                  &
                                     config_flags%spec_bdy_width,grid%z,      &
                                     grid%have_bcs_chem,      &
                                     grid%ru_m, grid%rv_m, config_flags,grid%alt,       &
                                     grid%t_1,grid%pb,grid%p,t0,p1000mb,rcp,grid%ph_2,grid%phb,g, &
                                     grid%spec_zone,ic,grid%julday,      &
                                     ids,ide, jds,jde, kds,kde,  & ! domain dims
                                     ims,ime, jms,jme, kms,kme,  & ! memory dims
                                     ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                     grid%i_start(ij), grid%i_end(ij),   &
                                     grid%j_start(ij), grid%j_end(ij),   &
                                     k_start, k_end,                     &
                                     grid%u_2,grid%v_2,grid%t_2,grid%znu,grid%msft, &
                                     grid%msfu,grid%msfv,grid%f,grid%mub,grid%dx,grid%xlat,grid%pv)

              ENDIF
         ENDDO chem_tile_loop_2
         !$OMP END PARALLEL DO

       ENDDO chem_variable_loop
     ENDIF chem_scalar_advance
BENCH_END(chem_adv_tim)
#endif
!  next the chemical species
BENCH_START(tracer_adv_tim)
       tracer_advance: IF (num_tracer >= PARAM_FIRST_SCALAR)  THEN

         tracer_variable_loop: DO ic = PARAM_FIRST_SCALAR, num_tracer

           !$OMP PARALLEL DO   &
           !$OMP PRIVATE ( ij, tenddec )
           tracer_tile_loop_1: DO ij = 1 , grid%num_tiles

             CALL wrf_debug ( 15 , ' call rk_scalar_tend in tracer_tile_loop_1' )
             tenddec = .false.
             CALL rk_scalar_tend ( ic, ic, config_flags, tenddec,                & 
                              rk_step, dt_rk,                                    &
                              grid%ru_m, grid%rv_m, grid%ww_m, wwE, wwI,         &
                              grid%u_1, grid%v_1,                                &  
                              grid%muts, grid%mub, grid%mu_1,                    &
                              grid%c1h, grid%c2h,  grid%c1f, grid%c2f,           &
                              grid%alt,                                          &
                              tracer_old(ims,kms,jms,ic),                        &
                              tracer(ims,kms,jms,ic),                            &
                              tracer_tend(ims,kms,jms,ic),                       &
                              advect_tend,h_tendency,z_tendency,grid%rqvften,    & 
                              grid%qv_base, .false., grid%fnm, grid%fnp,         &
                              grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv, &
                              grid%msfvy, grid%msftx,grid%msfty,                 &
                              grid%rdx, grid%rdy, grid%rdn, grid%rdnw,           &
                              grid%khdif, grid%kvdif, grid%xkhh,                 &
                              grid%diff_6th_opt, grid%diff_6th_factor,           &
                              config_flags%tracer_adv_opt,                       &
                              grid%phb, grid%ph_2,                               &
                              config_flags%tracer_mix2_off,                      &
                              config_flags%tracer_mix6_off,                      &
                              ids, ide, jds, jde, kds, kde,                      &
                              ims, ime, jms, jme, kms, kme,                      &
                              grid%i_start(ij), grid%i_end(ij),                  &
                              grid%j_start(ij), grid%j_end(ij),                  &
                              k_start    , k_end                                )
!
! Currently, chemistry species with specified boundaries (i.e. the mother
! domain)  are being over written by flow_dep_bdy_chem. So, relax_bdy and
! spec_bdy are only called for nests. For boundary conditions from global model or larger domain,
! chem is uncoupled, and only used for one row/column on inflow (if have_bcs_chem=.true.) 
!
           IF( ( config_flags%nested ) .and. rk_step == 1 ) THEN
             IF(ic.eq.1)CALL wrf_debug ( 10 , ' have_bcs_tracer' )
             CALL relax_bdy_scalar ( tracer_tend(ims,kms,jms,ic),                                    &
                                     tracer(ims,kms,jms,ic),  grid%mut,                              &
                                     grid%c1h, grid%c2h,                       &
                                     tracer_bxs(jms,kms,1,ic),tracer_bxe(jms,kms,1,ic),                &
                                     tracer_bys(ims,kms,1,ic),tracer_bye(ims,kms,1,ic),                &
                                     tracer_btxs(jms,kms,1,ic),tracer_btxe(jms,kms,1,ic),              &
                                     tracer_btys(ims,kms,1,ic),tracer_btye(ims,kms,1,ic),              &
                                     config_flags%spec_bdy_width, grid%spec_zone, grid%relax_zone, &
                                     grid%dtbc, grid%fcx, grid%gcx,                                &
                                     config_flags,                                                 &
                                     ids,ide, jds,jde, kds,kde,                                    &
                                     ims,ime, jms,jme, kms,kme,                                    &
                                     ips,ipe, jps,jpe, kps,kpe,                                    &
                                     grid%i_start(ij), grid%i_end(ij),                             &
                                     grid%j_start(ij), grid%j_end(ij),                             &
                                     k_start, k_end                                                )
             CALL spec_bdy_scalar  ( tracer_tend(ims,kms,jms,ic),                 &
                                     tracer_bxs(jms,kms,1,ic),tracer_bxe(jms,kms,1,ic),                &
                                     tracer_bys(ims,kms,1,ic),tracer_bye(ims,kms,1,ic),                &
                                     tracer_btxs(jms,kms,1,ic),tracer_btxe(jms,kms,1,ic),              &
                                     tracer_btys(ims,kms,1,ic),tracer_btye(ims,kms,1,ic),              &
                                     config_flags%spec_bdy_width, grid%spec_zone,                  &
                                     config_flags,                                                 &
                                     ids,ide, jds,jde, kds,kde,                                    &
                                     ims,ime, jms,jme, kms,kme,                                    &
                                     ips,ipe, jps,jpe, kps,kpe,                                    &
                                     grid%i_start(ij), grid%i_end(ij),                             &
                                     grid%j_start(ij), grid%j_end(ij),                             &
                                     k_start, k_end                                                )
           ENDIF

         ENDDO tracer_tile_loop_1
         !$OMP END PARALLEL DO

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )

         tracer_tile_loop_2: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_update_scalar' )
           tenddec = .false.
           CALL rk_update_scalar( scs=ic, sce=ic,                                         &
                                  scalar_1=tracer_old(ims,kms,jms,ic),                    &
                                  scalar_2=tracer(ims,kms,jms,ic),                        &
                                  sc_tend=tracer_tend(ims,kms,jms,ic),                    &
!                                 advh_t=advh_t(ims,kms,jms,1),                           & 
!                                 advz_t=advz_t(ims,kms,jms,1),                           & 
                                  advect_tend=advect_tend,                                &
                                  h_tendency=h_tendency, z_tendency=z_tendency,           & 
                                  msftx=grid%msftx,msfty=grid%msfty,                      &
                                  c1=grid%c1h, c2=grid%c2h,                               &
                                  mu_old=grid%mu_1, mu_new=grid%mu_2, mu_base=grid%mub,   &
                                  rk_step=rk_step, dt=dt_rk, spec_zone=grid%spec_zone,    &
                                  config_flags=config_flags, tenddec=tenddec,             & 
                                  ids=ids, ide=ide, jds=jds, jde=jde, kds=kds, kde=kde,   &
                                  ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, kme=kme,   &
                                  its=grid%i_start(ij), ite=grid%i_end(ij),               &
                                  jts=grid%j_start(ij), jte=grid%j_end(ij),               &
                                  kts=k_start    , kte=k_end                              )

           IF( config_flags%specified  ) THEN
#if (WRF_CHEM == 1)
             CALL flow_dep_bdy_tracer( tracer(ims,kms,jms,ic),                             &
                                     tracer_bxs(jms,kms,1,ic), tracer_btxs(jms,kms,1,ic),  &
                                     tracer_bxe(jms,kms,1,ic), tracer_btxe(jms,kms,1,ic),  &
                                     tracer_bys(ims,kms,1,ic), tracer_btys(ims,kms,1,ic),  &
                                     tracer_bye(ims,kms,1,ic), tracer_btye(ims,kms,1,ic),  &
                                     dt_rk+grid%dtbc,                                  &
                                     config_flags%spec_bdy_width,grid%z,      &
                                     grid%have_bcs_tracer,      &
                                     grid%ru_m, grid%rv_m, config_flags%tracer_opt,grid%alt,       &
                                     grid%t_1,grid%pb,grid%p,t0,p1000mb,rcp,grid%ph_2,grid%phb,g, &
                                     grid%spec_zone,ic,                  &
                                     ids,ide, jds,jde, kds,kde,  & ! domain dims
                                     ims,ime, jms,jme, kms,kme,  & ! memory dims
                                     ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                     grid%i_start(ij), grid%i_end(ij),   &
                                     grid%j_start(ij), grid%j_end(ij),   &
                                     k_start, k_end                      )
#else
             CALL flow_dep_bdy  ( tracer(ims,kms,jms,ic),     &
                                  grid%ru_m, grid%rv_m, config_flags,   &
                                  grid%spec_zone,                  &
                                  ids,ide, jds,jde, kds,kde,  & ! domain dims
                                  ims,ime, jms,jme, kms,kme,  & ! memory dims
                                  ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                  grid%i_start(ij), grid%i_end(ij),  &
                                  grid%j_start(ij), grid%j_end(ij),  &
                                  k_start, k_end                    )
#endif
           ENDIF
         ENDDO tracer_tile_loop_2
         !$OMP END PARALLEL DO

       ENDDO tracer_variable_loop
     ENDIF tracer_advance
BENCH_END(tracer_adv_tim)

!  next the other scalar species
     other_scalar_advance: IF (num_3d_s >= PARAM_FIRST_SCALAR)  THEN

       scalar_variable_loop: do is = PARAM_FIRST_SCALAR, num_3d_s
         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )
         scalar_tile_loop_1: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_scalar_tend' )
           tenddec = .false.
           CALL rk_scalar_tend ( is, is, config_flags, tenddec,                   & 
                                 rk_step, dt_rk,                                  &
                                 grid%ru_m, grid%rv_m, grid%ww_m, wwE, wwI,       &
                                 grid%u_1, grid%v_1,                              &  
                                 grid%muts, grid%mub, grid%mu_1,                  &
                                 grid%c1h, grid%c2h,  grid%c1f, grid%c2f,         &
                                 grid%alt,                                        &
                                 scalar_old(ims,kms,jms,is),                      &
                                 scalar(ims,kms,jms,is),                          &
                                 scalar_tend(ims,kms,jms,is),                     &
                                 advect_tend,h_tendency,z_tendency,grid%rqvften,  & 
                                 grid%qv_base, .false., grid%fnm, grid%fnp,       &
                                 grid%msfux,grid%msfuy, grid%msfvx, grid%msfvx_inv, &
                                 grid%msfvy, grid%msftx,grid%msfty,               &
                                 grid%rdx, grid%rdy, grid%rdn, grid%rdnw,         &
                                 grid%khdif, grid%kvdif, grid%xkhh,               &
                                 grid%diff_6th_opt, grid%diff_6th_factor,         &
                                 config_flags%scalar_adv_opt,                     &
                                 grid%phb, grid%ph_2,                             &
                                 config_flags%scalar_mix2_off,                    &
                                 config_flags%scalar_mix6_off,                    &
                                 ids, ide, jds, jde, kds, kde,     &
                                 ims, ime, jms, jme, kms, kme,     &
                                 grid%i_start(ij), grid%i_end(ij), &
                                 grid%j_start(ij), grid%j_end(ij), &
                                 k_start    , k_end               )

           IF( rk_step == 1 ) THEN
             IF ( config_flags%nested .OR. &
                ( config_flags%specified .AND. config_flags%have_bcs_scalar ) .OR. &
                ( ( is .EQ. P_QNWFA .OR. is .EQ. P_QNIFA .OR. is .EQ. P_QNBCA) .AND. config_flags%aer_init_opt .GT. 0) ) THEN

               CALL relax_bdy_scalar ( scalar_tend(ims,kms,jms,is),                            &
                                       scalar(ims,kms,jms,is),  grid%mut,                      &
                                       grid%c1h, grid%c2h,                       &
                                       scalar_bxs(jms,kms,1,is),scalar_bxe(jms,kms,1,is),      &
                                       scalar_bys(ims,kms,1,is),scalar_bye(ims,kms,1,is),      &
                                       scalar_btxs(jms,kms,1,is),scalar_btxe(jms,kms,1,is),    &
                                       scalar_btys(ims,kms,1,is),scalar_btye(ims,kms,1,is),    &
                                       config_flags%spec_bdy_width, grid%spec_zone, grid%relax_zone, &
                                       grid%dtbc, grid%fcx, grid%gcx,                          &
                                       config_flags,                                           &
                                       ids,ide, jds,jde, kds,kde,                              &
                                       ims,ime, jms,jme, kms,kme,                              &
                                       ips,ipe, jps,jpe, kps,kpe,                              &
                                       grid%i_start(ij), grid%i_end(ij),                       &
                                       grid%j_start(ij), grid%j_end(ij),                       &
                                       k_start, k_end                                          )

               CALL spec_bdy_scalar  ( scalar_tend(ims,kms,jms,is),                            &
                                       scalar_bxs(jms,kms,1,is),scalar_bxe(jms,kms,1,is),      &
                                       scalar_bys(ims,kms,1,is),scalar_bye(ims,kms,1,is),      &
                                       scalar_btxs(jms,kms,1,is),scalar_btxe(jms,kms,1,is),    &
                                       scalar_btys(ims,kms,1,is),scalar_btye(ims,kms,1,is),    &
                                       config_flags%spec_bdy_width, grid%spec_zone,            &
                                       config_flags,                                           &
                                       ids,ide, jds,jde, kds,kde,                              &
                                       ims,ime, jms,jme, kms,kme,                              &
                                       ips,ipe, jps,jpe, kps,kpe,                              &
                                       grid%i_start(ij), grid%i_end(ij),                       &
                                       grid%j_start(ij), grid%j_end(ij),                       &
                                       k_start, k_end                                          )

             ENDIF
           ENDIF ! b.c test for scalars

         ENDDO scalar_tile_loop_1
         !$OMP END PARALLEL DO

         !$OMP PARALLEL DO   &
         !$OMP PRIVATE ( ij, tenddec )
         scalar_tile_loop_2: DO ij = 1 , grid%num_tiles

           CALL wrf_debug ( 200 , ' call rk_update_scalar' )
           tenddec = .false.
           CALL rk_update_scalar( scs=is, sce=is,                                         &
                                  scalar_1=scalar_old(ims,kms,jms,is),                    &
                                  scalar_2=scalar(ims,kms,jms,is),                        &
                                  sc_tend=scalar_tend(ims,kms,jms,is),                    &
!                                 advh_t=advh_t(ims,kms,jms,1),                           & 
!                                 advz_t=advz_t(ims,kms,jms,1),                           & 
                                  advect_tend=advect_tend,                                &
                                  h_tendency=h_tendency, z_tendency=z_tendency,           & 
                                  msftx=grid%msftx,msfty=grid%msfty,                      &
                                  c1=grid%c1h, c2=grid%c2h,                               &
                                  mu_old=grid%mu_1, mu_new=grid%mu_2, mu_base=grid%mub,   &
                                  rk_step=rk_step, dt=dt_rk, spec_zone=grid%spec_zone,    &
                                  config_flags=config_flags, tenddec=tenddec,             & 
                                  ids=ids, ide=ide, jds=jds, jde=jde, kds=kds, kde=kde,   &
                                  ims=ims, ime=ime, jms=jms, jme=jme, kms=kms, kme=kme,   &
                                  its=grid%i_start(ij), ite=grid%i_end(ij),               &
                                  jts=grid%j_start(ij), jte=grid%j_end(ij),               &
                                  kts=k_start    , kte=k_end                              )

! bound the aerosol fields (greater than 0) when using first guess aerosol
! as fields may be highly heterogeneous compared to climatology

           IF ( ( ( is .EQ. P_QNWFA ) .OR. ( is .EQ. P_QNIFA ) .OR. ( is .EQ. P_QNBCA ) ) .AND. &
                         ( config_flags%aer_init_opt .EQ. 2 ) ) THEN
             CALL bound_qna( scalar(ims,kms,jms,is),              &
                             ids, ide, jds, jde, kds, kde,        &
                             ims, ime, jms, jme, kms, kme,        &
                             grid%i_start(ij), grid%i_end(ij),    &
                             grid%j_start(ij), grid%j_end(ij),    &
                             k_start    , k_end                  )
           END IF

           IF ( config_flags%specified ) THEN
              IF (is.EQ.P_QDCN.OR.is.EQ.P_QTCN.OR.is.EQ.P_QNIN) THEN       ! for ntu3m
                 CALL flow_dep_bdy_fixed_inflow(scalar(ims,kms,jms,is), &
                                       grid%ru_m,grid%rv_m,config_flags,&
                                       grid%spec_zone,ids,ide,jds,jde,  &
                                       kds,kde,ims,ime,jms,jme,kms,kme, &
                                       ips,ipe,jps,jpe,kps,kpe,         &
                                       grid%i_start(ij),grid%i_end(ij), &
                                       grid%j_start(ij),grid%j_end(ij), &
                                       k_start,k_end)
              ELSEIF (is.EQ.P_QNN) THEN                                    ! for ntu3m
               CALL flow_dep_bdy_qnn  ( scalar(ims,kms,jms,is),     &
                                  grid%ru_m, grid%rv_m, config_flags,   &
                                  grid%spec_zone,                  &
                                  grid%ccn_conc,              & ! RAS
                                  ids,ide, jds,jde, kds,kde,  & ! domain dims
                                  ims,ime, jms,jme, kms,kme,  & ! memory dims
                                  ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                  grid%i_start(ij), grid%i_end(ij),  &
                                  grid%j_start(ij), grid%j_end(ij),  &
                                  k_start, k_end                    )
             ELSE IF ( ( ( ( is .EQ. P_QNWFA ) .OR. ( is .EQ. P_QNIFA ) .OR. ( is .EQ. P_QNBCA ) ) .AND. &
                         ( config_flags%aer_init_opt .EQ. 0 ) ) &
                         .OR. &
                       ( ( .NOT. ( ( is .EQ. P_QNWFA ) .OR. ( is .EQ. P_QNIFA ) .OR. ( is .EQ. P_QNBCA ) ) ) .AND. &
                         ( .NOT. config_flags%have_bcs_scalar ) ) ) THEN

!     A = ( is .EQ. P_QNWFA ) .OR. ( is .EQ. P_QNIFA ) .OR. ( is .EQ. P_QNBCA )
!     B = config_flags%aer_init_opt .GT. 0
!     C = config_glags%have_bcs_scalar

! Test| A  | B  | C | ( A AND NOT B ) OR ( NOT A AND NOT C ) 
! ----+----+----+---+-----------------------------------------------
!  1  | T  | T  | T |                 F = DO NOT CALL flow_dep_bdy
!  2  | T  | T  | F |                 F = DO NOT CALL flow_dep_bdy
!  3  | T  | F  | T |                 T =        CALL flow_dep_bdy
!  4  | T  | F  | F |                 T =        CALL flow_dep_bdy
!  5  | F  | T  | T |                 F = DO NOT CALL flow_dep_bdy
!  6  | F  | T  | F |                 T =        CALL flow_dep_bdy
!  7  | F  | F  | T |                 F = DO NOT CALL flow_dep_bdy
!  8  | F  | F  | F |                 T =        CALL flow_dep_bdy
! ----+----+----+---+-----------------------------------------------

!  If this is     the special friendly fields AND are to use the aero icbc, then NO calls to flow dep: tests 1 and 2
!  If this is     the special friendly fields AND do not use the aero icbc, then    call     flow dep: tests 3 and 4
!  If this is not the special friendly fields AND: 
!           If we        have bcs for scalars, do not call flow dep: tests 5 and 7
!           If we do not have bcs for scalars,        call flow dep: tests 6 and 8

               CALL flow_dep_bdy  ( scalar(ims,kms,jms,is),     &
                                  grid%ru_m, grid%rv_m, config_flags,   &
                                  grid%spec_zone,                  &
                                  ids,ide, jds,jde, kds,kde,  & ! domain dims
                                  ims,ime, jms,jme, kms,kme,  & ! memory dims
                                  ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                  grid%i_start(ij), grid%i_end(ij),  &
                                  grid%j_start(ij), grid%j_end(ij),  &
                                  k_start, k_end                    )
             ENDIF

           ENDIF

         ENDDO scalar_tile_loop_2
         !$OMP END PARALLEL DO

       ENDDO scalar_variable_loop

     ENDIF other_scalar_advance

 !  update the pressure and density at the new time level

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles

BENCH_START(calc_p_rho_tim)

       CALL calc_p_rho_phi( moist, num_3d_m, config_flags%hypsometric_opt,                    &
                            grid%al, grid%alb, grid%mu_2, grid%muts,                          &
                            grid%c1h, grid%c2h, grid%c3h, grid%c4h, grid%c3f, grid%c4f,       &
                            grid%ph_2, grid%phb, grid%p, grid%pb, grid%t_2,                   &
                            p0, t0, grid%p_top, grid%znu, grid%znw, grid%dnw, grid%rdnw,      &
                            grid%rdn, config_flags%non_hydrostatic,config_flags%use_theta_m,  &
                            ids, ide, jds, jde, kds, kde,                                     &
                            ims, ime, jms, jme, kms, kme,                                     &
                            grid%i_start(ij), grid%i_end(ij),                                 &
                            grid%j_start(ij), grid%j_end(ij),                                 &
                            k_start    , k_end                                                )

BENCH_END(calc_p_rho_tim)

     ENDDO
     !$OMP END PARALLEL DO

!  Reset the boundary conditions if there is another corrector step.
!  (rk_step < rk_order), else we'll handle it at the end of everything
!  (after the split physics, before exiting the timestep).

     rk_step_1_check: IF ( rk_step < rk_order ) THEN

!-----------------------------------------------------------
!  rk3 substep polar filter for scalars (moist,chem,scalar)
!-----------------------------------------------------------

       IF (config_flags%polar) THEN 
         IF ( num_3d_m >= PARAM_FIRST_SCALAR ) THEN
           CALL wrf_debug ( 200 , ' call filter moist ' )
           DO im = PARAM_FIRST_SCALAR, num_3d_m
             IF ( config_flags%coupled_filtering ) THEN
             CALL couple_scalars_for_filter ( FIELD=moist(ims,kms,jms,im)        &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
             CALL pxft ( grid=grid                                               &
                    ,lineno=__LINE__                                             &
                    ,flag_uv            = 0                                      &
                    ,flag_rurv          = 0                                      &
                    ,flag_wph           = 0                                      &
                    ,flag_ww            = 0                                      &
                    ,flag_t             = 0                                      &
                    ,flag_mu            = 0                                      &
                    ,flag_mut           = 0                                      &
                    ,flag_moist         = im                                     &
                    ,flag_chem          = 0                                      &
                    ,flag_scalar        = 0                                      &
                    ,flag_tracer        = 0                                      &
                    ,actual_distance_average=config_flags%actual_distance_average&
                    ,pos_def            = config_flags%pos_def                   &
                    ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                    ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                    ,fft_filter_lat = config_flags%fft_filter_lat                &
                    ,dclat = dclat                                               &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                    ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                    ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )
             IF ( config_flags%coupled_filtering ) THEN
             CALL uncouple_scalars_for_filter ( FIELD=moist(ims,kms,jms,im)      &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
           END DO
         END IF
   
         IF ( num_3d_c >= PARAM_FIRST_SCALAR ) THEN
           CALL wrf_debug ( 200 , ' call filter chem ' )
           DO im = PARAM_FIRST_SCALAR, num_3d_c
             IF ( config_flags%coupled_filtering ) THEN
             CALL couple_scalars_for_filter ( FIELD=chem(ims,kms,jms,im)               &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe           )
             END IF
             CALL pxft ( grid=grid                                               &
                    ,lineno=__LINE__                                             &
                    ,flag_uv            = 0                                      &
                    ,flag_rurv          = 0                                      &
                    ,flag_wph           = 0                                      &
                    ,flag_ww            = 0                                      &
                    ,flag_t             = 0                                      &
                    ,flag_mu            = 0                                      &
                    ,flag_mut           = 0                                      &
                    ,flag_moist         = 0                                      &
                    ,flag_chem          = im                                     &
                    ,flag_tracer        = 0                                      &
                    ,flag_scalar        = 0                                      &
                    ,actual_distance_average=config_flags%actual_distance_average&
                    ,pos_def            = config_flags%pos_def                   &
                    ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                    ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                    ,fft_filter_lat = config_flags%fft_filter_lat                &
                    ,dclat = dclat                                               &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                    ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                    ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )
             IF ( config_flags%coupled_filtering ) THEN
             CALL uncouple_scalars_for_filter ( FIELD=chem(ims,kms,jms,im)       &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
           END DO
         END IF
         IF ( num_tracer >= PARAM_FIRST_SCALAR ) THEN
           CALL wrf_debug ( 200 , ' call filter tracer ' )
           DO im = PARAM_FIRST_SCALAR, num_tracer
             IF ( config_flags%coupled_filtering ) THEN
             CALL couple_scalars_for_filter ( FIELD=tracer(ims,kms,jms,im)               &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe           )
             END IF
             CALL pxft ( grid=grid                                               &
                    ,lineno=__LINE__                                             &
                    ,flag_uv            = 0                                      &
                    ,flag_rurv          = 0                                      &
                    ,flag_wph           = 0                                      &
                    ,flag_ww            = 0                                      &
                    ,flag_t             = 0                                      &
                    ,flag_mu            = 0                                      &
                    ,flag_mut           = 0                                      &
                    ,flag_moist         = 0                                      &
                    ,flag_chem          = 0                                      &
                    ,flag_tracer        = im                                     &
                    ,flag_scalar        = 0                                      &
                    ,actual_distance_average=config_flags%actual_distance_average&
                    ,pos_def            = config_flags%pos_def                   &
                    ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                    ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                    ,fft_filter_lat = config_flags%fft_filter_lat                &
                    ,dclat = dclat                                               &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                    ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                    ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )
             IF ( config_flags%coupled_filtering ) THEN
             CALL uncouple_scalars_for_filter ( FIELD=tracer(ims,kms,jms,im)     &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
           END DO
         END IF
   
         IF ( num_3d_s >= PARAM_FIRST_SCALAR ) THEN
           CALL wrf_debug ( 200 , ' call filter scalar ' )
           DO im = PARAM_FIRST_SCALAR, num_3d_s
             IF ( config_flags%coupled_filtering ) THEN
             CALL couple_scalars_for_filter ( FIELD=scalar(ims,kms,jms,im)           &
                  ,MU=grid%mu_2 , MUB=grid%mub                                 &
                  ,C1=grid%c1h , C2=grid%c2h                                   &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
             CALL pxft ( grid=grid                                             &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 0                                      &
                  ,flag_rurv          = 0                                      &
                  ,flag_wph           = 0                                      &
                  ,flag_ww            = 0                                      &
                  ,flag_t             = 0                                      &
                  ,flag_mu            = 0                                      &
                  ,flag_mut           = 0                                      &
                  ,flag_moist         = 0                                      &
                  ,flag_chem          = 0                                      &
                  ,flag_tracer        = 0                                      &
                  ,flag_scalar        = im                                     &
                  ,actual_distance_average=config_flags%actual_distance_average&
                  ,pos_def            = config_flags%pos_def                   &
                  ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )
             IF ( config_flags%coupled_filtering ) THEN
             CALL uncouple_scalars_for_filter ( FIELD=scalar(ims,kms,jms,im)   &
                  ,MU=grid%mu_2 , MUB=grid%mub                                 &
                  ,C1=grid%c1h , C2=grid%c2h                                   &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
             END IF
           END DO
         END IF
       END IF ! polar filter test

!-----------------------------------------------------------
!  END rk3 substep polar filter for scalars (moist,chem,scalar)
!-----------------------------------------------------------

!-----------------------------------------------------------
!  Stencils for patch communications  (WCS, 29 June 2001)
!
!  here's where we need a wide comm stencil - these are the 
!  uncoupled variables so are used for high order calc in
!  advection and mixong routines.
!
!
!                                  * * * * * * *
!                     * * * * *    * * * * * * *
!            *        * * * * *    * * * * * * *
!          * + *      * * + * *    * * * + * * *
!            *        * * * * *    * * * * * * *
!                     * * * * *    * * * * * * *
!                                  * * * * * * *
!
! al        x
!
!  2D variable
! mu_2      x
!
! (adv order <=4)
! u_2                     x
! v_2                     x
! w_2                     x
! t_2                     x
! ph_2                    x
!
! (adv order <=6)
! u_2                                    x
! v_2                                    x
! w_2                                    x
! t_2                                    x
! ph_2                                   x
!
!  4D variable
! moist                   x
! chem                    x
! scalar                  x

#ifdef DM_PARALLEL
       IF      ( config_flags%h_mom_adv_order <= 4 .and. config_flags%h_sca_adv_order <= 4 ) THEN
#    include "HALO_EM_D2_3.inc"
       ELSE IF ( config_flags%h_mom_adv_order <= 6 .and. config_flags%h_sca_adv_order <= 6 ) THEN
#    include "HALO_EM_D2_5.inc"
       ELSE 
         WRITE(wrf_err_message,*)'solve_em: invalid h_mom_adv_order or h_sca_adv_order = ', &
               config_flags%h_mom_adv_order, config_flags%h_sca_adv_order
         CALL wrf_error_fatal(TRIM(wrf_err_message))
       ENDIF
#  include "PERIOD_BDY_EM_D.inc"
#  include "PERIOD_BDY_EM_MOIST2.inc"
#  include "PERIOD_BDY_EM_CHEM2.inc"
#  include "PERIOD_BDY_EM_TRACER2.inc"
#  include "PERIOD_BDY_EM_SCALAR2.inc"
#  include "PERIOD_BDY_EM_TKE.inc"
#endif

BENCH_START(bc_end_tim)
       !$OMP PARALLEL DO   &
       !$OMP PRIVATE ( ij )
       tile_bc_loop_1: DO ij = 1 , grid%num_tiles
         CALL wrf_debug ( 200 , ' call rk_phys_bc_dry_2' )

         CALL rk_phys_bc_dry_2( config_flags,                     &
                                grid%u_2, grid%v_2, grid%w_2,     &
                                grid%t_2, grid%ph_2, grid%mu_2,   &
                                ids, ide, jds, jde, kds, kde,     &
                                ims, ime, jms, jme, kms, kme,     &
                                ips, ipe, jps, jpe, kps, kpe,     &
                                grid%i_start(ij), grid%i_end(ij), &
                                grid%j_start(ij), grid%j_end(ij), &
                                k_start    , k_end               )

BENCH_START(diag_w_tim)
         IF (.not. config_flags%non_hydrostatic) THEN
           CALL diagnose_w( ph_tend, grid%ph_2, grid%ph_1, grid%w_2, grid%muts, &
                            grid%c1f, grid%c2f, dt_rk,              &
                            grid%u_2, grid%v_2, grid%ht,            &
                            grid%cf1, grid%cf2, grid%cf3, grid%rdx, grid%rdy, grid%msftx, grid%msfty, &
                            ids, ide, jds, jde, kds, kde,           &
                            ims, ime, jms, jme, kms, kme,           &
                            grid%i_start(ij), grid%i_end(ij),       &
                            grid%j_start(ij), grid%j_end(ij),       &
                            k_start    , k_end                     )
         ENDIF
BENCH_END(diag_w_tim)

         IF (num_3d_m >= PARAM_FIRST_SCALAR) THEN

           moisture_loop_bdy_1 : DO im = PARAM_FIRST_SCALAR , num_3d_m
  
             CALL set_physical_bc3d( moist(ims,kms,jms,im), 'p', config_flags,   &
                                     ids, ide, jds, jde, kds, kde,             &
                                     ims, ime, jms, jme, kms, kme,             &
                                     ips, ipe, jps, jpe, kps, kpe,             &
                                     grid%i_start(ij), grid%i_end(ij),                   &
                                     grid%j_start(ij), grid%j_end(ij),                   &
                                     k_start    , k_end                       )
           END DO moisture_loop_bdy_1

         ENDIF

         IF (num_3d_c >= PARAM_FIRST_SCALAR) THEN

           chem_species_bdy_loop_1 : DO ic = PARAM_FIRST_SCALAR , num_3d_c

             CALL set_physical_bc3d( chem(ims,kms,jms,ic), 'p', config_flags,   &
                                     ids, ide, jds, jde, kds, kde,            &
                                     ims, ime, jms, jme, kms, kme,            &
                                     ips, ipe, jps, jpe, kps, kpe,            &
                                     grid%i_start(ij), grid%i_end(ij),                  &
                                     grid%j_start(ij), grid%j_end(ij),                  &
                                     k_start    , k_end-1                    )

           END DO chem_species_bdy_loop_1

         END IF

         IF (num_tracer >= PARAM_FIRST_SCALAR) THEN

           tracer_species_bdy_loop_1 : DO ic = PARAM_FIRST_SCALAR , num_tracer

             CALL set_physical_bc3d( tracer(ims,kms,jms,ic), 'p', config_flags,   &
                                     ids, ide, jds, jde, kds, kde,            &
                                     ims, ime, jms, jme, kms, kme,            &
                                     ips, ipe, jps, jpe, kps, kpe,            &
                                     grid%i_start(ij), grid%i_end(ij),                  &
                                     grid%j_start(ij), grid%j_end(ij),                  &
                                     k_start    , k_end-1                    )

           END DO tracer_species_bdy_loop_1

         END IF

         IF (num_3d_s >= PARAM_FIRST_SCALAR) THEN

           scalar_species_bdy_loop_1 : DO is = PARAM_FIRST_SCALAR , num_3d_s

             CALL set_physical_bc3d( scalar(ims,kms,jms,is), 'p', config_flags,   &
                                     ids, ide, jds, jde, kds, kde,            &
                                     ims, ime, jms, jme, kms, kme,            &
                                     ips, ipe, jps, jpe, kps, kpe,            &
                                     grid%i_start(ij), grid%i_end(ij),                  &
                                     grid%j_start(ij), grid%j_end(ij),                  &
                                     k_start    , k_end-1                    )

           END DO scalar_species_bdy_loop_1

         END IF

         IF (config_flags%km_opt .eq. 2) THEN

           CALL set_physical_bc3d( grid%tke_2 , 'p', config_flags,  &
                                   ids, ide, jds, jde, kds, kde,            &
                                   ims, ime, jms, jme, kms, kme,            &
                                   ips, ipe, jps, jpe, kps, kpe,            &
                                   grid%i_start(ij), grid%i_end(ij),        &
                                   grid%j_start(ij), grid%j_end(ij),        &
                                   k_start    , k_end                      )
         END IF

       END DO tile_bc_loop_1
       !$OMP END PARALLEL DO
BENCH_END(bc_end_tim)


#ifdef DM_PARALLEL

!                           * * * * *
!         *        * * *    * * * * *
!       * + *      * + *    * * + * *
!         *        * * *    * * * * *
!                           * * * * *

! moist, chem, scalar, tke      x


       IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
         IF ( (config_flags%tke_adv_opt /= ORIGINAL .and. config_flags%tke_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#         include "HALO_EM_TKE_5.inc"
         ELSE
#         include "HALO_EM_TKE_3.inc"
         ENDIF
       ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
         IF ( (config_flags%tke_adv_opt /= ORIGINAL .and. config_flags%tke_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#         include "HALO_EM_TKE_7.inc"
         ELSE
#         include "HALO_EM_TKE_5.inc"
         ENDIF
       ELSE
         WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
         CALL wrf_error_fatal(TRIM(wrf_err_message))
       ENDIF

       IF ( num_moist .GE. PARAM_FIRST_SCALAR ) THEN
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
           IF ( (config_flags%moist_adv_opt /= ORIGINAL .and. config_flags%moist_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_MOIST_E_5.inc"
           ELSE
#        include "HALO_EM_MOIST_E_3.inc"
           END IF
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
           IF ( (config_flags%moist_adv_opt /= ORIGINAL .and. config_flags%moist_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_MOIST_E_7.inc"
           ELSE
#        include "HALO_EM_MOIST_E_5.inc"
           END IF
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
       ENDIF
       IF ( num_chem >= PARAM_FIRST_SCALAR ) THEN
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
           IF ( (config_flags%chem_adv_opt /= ORIGINAL .and. config_flags%chem_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_CHEM_E_5.inc"
           ELSE
#        include "HALO_EM_CHEM_E_3.inc"
           ENDIF
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
           IF ( (config_flags%chem_adv_opt /= ORIGINAL .and. config_flags%chem_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_CHEM_E_7.inc"
           ELSE
#        include "HALO_EM_CHEM_E_5.inc"
           ENDIF
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
       ENDIF
       IF ( num_tracer >= PARAM_FIRST_SCALAR ) THEN
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
           IF ( (config_flags%tracer_adv_opt /= ORIGINAL .and. config_flags%tracer_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_TRACER_E_5.inc"
           ELSE
#        include "HALO_EM_TRACER_E_3.inc"
           ENDIF
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
           IF ( (config_flags%tracer_adv_opt /= ORIGINAL .and. config_flags%tracer_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_TRACER_E_7.inc"
           ELSE
#        include "HALO_EM_TRACER_E_5.inc"
           ENDIF
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
       ENDIF
       IF ( num_scalar >= PARAM_FIRST_SCALAR ) THEN
         IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
           IF ( (config_flags%scalar_adv_opt /= ORIGINAL .and. config_flags%scalar_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_SCALAR_E_5.inc"
           ELSE
#        include "HALO_EM_SCALAR_E_3.inc"
           ENDIF
         ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
           IF ( (config_flags%scalar_adv_opt /= ORIGINAL .and. config_flags%scalar_adv_opt /= WENO_SCALAR) .and. (rk_step == rk_order-1) ) THEN
#        include "HALO_EM_SCALAR_E_7.inc"
           ELSE
#        include "HALO_EM_SCALAR_E_5.inc"
           ENDIF
         ELSE
           WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
           CALL wrf_error_fatal(TRIM(wrf_err_message))
         ENDIF
       ENDIF
#endif

     ENDIF rk_step_1_check


!**********************************************************
!
!  end of RK predictor-corrector loop
!
!**********************************************************

#ifdef WRF_GPU
   CALL gpu_ck( grid, 'e_rkend', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_GPU_RESIDENT
     IF ( wrf_gpu_xw_skip ) THEN
!$acc wait
       wrf_gpu_xw_skip = .FALSE.
     ENDIF
#endif
   END DO Runge_Kutta_loop
#ifdef WRF_GPU_FIELDTRACE
       CALL gpu_field_trace( grid, 'c_post_rk' )
#endif
!  grid%dmudt=grid%mu_2 - grid%mu_1

#if ( WRFPLUS != 1 )
   IF      ( config_flags%traj_opt .EQ. UM_TRAJECTORY ) THEN
#ifdef DM_PARALLEL
#    include "HALO_EM_F_1.inc"
#    include "HALO_EM_D.inc"
#    include "HALO_EM_INIT_4.inc"
     IF( config_flags%periodic_x ) THEN
#    include "PERIOD_EM_DA.inc"
#    include "PERIOD_EM_F.inc"
#    include "PERIOD_EM_G.inc"
     ENDIF
#endif
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
       DO ij = 1 , grid%num_tiles

           call trajectory (grid,config_flags,                                     &
                            grid%dt,grid%itimestep,grid%ru_m, grid%rv_m, grid%ww_m,&
                            grid%muts,grid%muus,grid%muvs,                         &
                            grid%c1h, grid%c2h, grid%c1f, grid%c2f,                &
                            grid%rdx, grid%rdy, grid%rdn, grid%rdnw,grid%rdzw,     &
                            grid%traj_i,grid%traj_j,grid%traj_k,                   &
                            grid%traj_long,grid%traj_lat,                          &
                            grid%xlong,grid%xlat,                                  &
                            grid%msftx,grid%msfux,grid%msfvy,                      &
                            ids, ide, jds, jde, kds, kde,                          &
                            ims, ime, jms, jme, kms, kme,                          &
                            grid%i_start(ij), grid%i_end(ij),                      &
                            grid%j_start(ij), grid%j_end(ij),                      &
                            k_start  , k_end                                       )
        ENDDO
     !$OMP END PARALLEL DO
   ENDIF
#endif
!-----------------------------------------------------------

#ifdef WRF_GPU_RESIDENT
   ! GPU-owned tendencies: decouple them where part2 coupled them (on the GPU), before the host microphysics block
   gpu_tend_dev = IAND( wrf_gpu_xfer(), 16 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 6 ) == 6
   gpu_mp_dev = gpu_tend_dev .AND. IAND( wrf_gpu_xfer(), 32 ) /= 0 .AND. config_flags%mp_physics == THOMPSON
   IF ( gpu_tend_dev ) THEN
   DO ij = 1 , grid%num_tiles
        CALL wrf_debug ( 200 , ' call phy_prep_part2' )
        CALL phy_prep_part2 ( config_flags,                              &
                        grid%muts, grid%muus, grid%muvs,                 &
                        grid%c1h, grid%c2h, grid%c1f, grid%c2f,          &
                        grid%rthraten,                                   &
                        grid%rthblten, grid%rublten, grid%rvblten,       &
                        grid%rqvblten, grid%rqcblten, grid%rqiblten,     &
                        grid%rucuten,  grid%rvcuten,  grid%rthcuten,     &
                        grid%rqvcuten, grid%rqccuten, grid%rqrcuten,     &
                        grid%rqicuten, grid%rqscuten,                    &
                        grid%rushten,  grid%rvshten,  grid%rthshten,     &
                        grid%rqvshten, grid%rqcshten, grid%rqrshten,     &
                        grid%rqishten, grid%rqsshten, grid%rqgshten,     &
                        grid%rthften,  grid%rqvften,                     &
                        grid%RUNDGDTEN, grid%RVNDGDTEN, grid%RTHNDGDTEN, &
                        grid%RPHNDGDTEN,grid%RQVNDGDTEN, grid%RMUNDGDTEN,&
                        grid%t_2, th_phy, moist(ims,kms,jms,P_QV),       &
                        ids, ide, jds, jde, kds, kde,                    &
                        ims, ime, jms, jme, kms, kme,                    &
                        grid%i_start(ij), grid%i_end(ij),                &
                        grid%j_start(ij), grid%j_end(ij),                &
                        k_start, k_end                                   )
   ENDDO
   ENDIF
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( .NOT. gpu_mp_dev ) THEN
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   IF ( IAND( wrf_gpu_xfer(), 4 ) /= 0 ) THEN
#  include "gpu_upd_host_h2.inc"
   ELSE
#  include "gpu_upd_host_pre_mp.inc"
   ENDIF
#  include "gpu_upd_host_i1_mp.inc"
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
   ENDIF
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 1 ) /= 0 ) THEN
#    include "gpu_sync_host_all.inc"
#    include "gpu_upd_host_i1_all.inc"
   ENDIF
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   IF ( wrf_gpu_prefetch_mode() > 0 ) THEN
#  include "gpu_pf_host_pre_mp.inc"
   ENDIF
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'f_preH2', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 3 )
#endif
#ifdef WRF_GPU
   IF ( .NOT. gpu_mp_dev ) THEN
   IF ( wrf_gpu_hostblocks() ) THEN ; wrf_gpu_on = .FALSE. ; CALL rsl_set_gpu_on( .FALSE. ) ; ENDIF
       CALL gpu_retile( grid, .TRUE., ids, ide, jds, jde, ips, ipe, jps, jpe )
   ENDIF
#endif
#ifdef WRF_GPU_RESIDENT
#endif
   IF (config_flags%do_avgflx_em .EQ. 1) THEN
! Reinitialize time-averaged fluxes if history output was written after the previous time step:
      CALL WRFU_ALARMGET(grid%alarms( HISTORY_ALARM ),prevringtime=temp_time)
      CALL domain_clock_get ( grid, current_time=CurrTime, &
           current_timestr=message2 )
! use overloaded -, .LT. operator to check whether to initialize avgflx:
! reinitialize after each history output (detect this here by comparing current time
! against last history time and time step - this code follows what's done in adapt_timestep_em):
      WRITE ( message , FMT = '("solve_em: old_dt =",g15.6,", dt=",g15.6," on domain ",I3)' ) &
           & old_dt,grid%dt,grid%id
      CALL wrf_debug(200,message)
      old_dt=min(old_dt,grid%dt)
      num = INT(old_dt * precision)
      den = precision
      CALL WRFU_TimeIntervalSet(dtInterval, Sn=num, Sd=den)
      IF (CurrTime .lt. temp_time + dtInterval) THEN
         WRITE ( message , FMT = '("solve_em: initializing avgflx at time ",A," on domain ",I3)' ) &
              & TRIM(message2), grid%id
         CALL wrf_message(trim(message)) 
         grid%avgflx_count = 0
!tile-loop for zero_avgflx
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )

         DO ij = 1 , grid%num_tiles
            CALL wrf_debug(200,'In solve_em, before zero_avgflx call')
            CALL zero_avgflx(grid%avgflx_rum,grid%avgflx_rvm,grid%avgflx_wwm, &
                 &   ids, ide, jds, jde, kds, kde,           &
                 &   ims, ime, jms, jme, kms, kme,           &
                 &   grid%i_start(ij), grid%i_end(ij), grid%j_start(ij), grid%j_end(ij), &
                 &   k_start    , k_end, f_flux, &
                 &   grid%avgflx_cfu1,grid%avgflx_cfd1,grid%avgflx_dfu1, &
                 &   grid%avgflx_efu1,grid%avgflx_dfd1,grid%avgflx_efd1 )
            CALL wrf_debug(200,'In solve_em, after zero_avgflx call')
         ENDDO
         !$OMP END PARALLEL DO
      ENDIF

! Update avgflx quantities
!tile-loop for upd_avgflx
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )

      DO ij = 1 , grid%num_tiles
         CALL wrf_debug(200,'In solve_em, before upd_avgflx call')
         CALL upd_avgflx(grid%avgflx_count,grid%avgflx_rum,grid%avgflx_rvm,grid%avgflx_wwm, &
              &   grid%ru_m, grid%rv_m, grid%ww_m, &
              &   ids, ide, jds, jde, kds, kde,           &
              &   ims, ime, jms, jme, kms, kme,           &
              &   grid%i_start(ij), grid%i_end(ij), grid%j_start(ij), grid%j_end(ij), &
              &   k_start    , k_end, f_flux, &
              &   grid%cfu1,grid%cfd1,grid%dfu1,grid%efu1,grid%dfd1,grid%efd1,          &
              &   grid%avgflx_cfu1,grid%avgflx_cfd1,grid%avgflx_dfu1, &
              &   grid%avgflx_efu1,grid%avgflx_dfd1,grid%avgflx_efd1 )
         CALL wrf_debug(200,'In solve_em, after upd_avgflx call')
         
      ENDDO
      !$OMP END PARALLEL DO
      grid%avgflx_count = grid%avgflx_count + 1
   ENDIF
!
#ifdef WRF_GPU_RESIDENT
   ! advance_ppt zeroes cumulus tendencies when an NCA countdown ends (KF family): push them after H2 then
   gpu_push_cu2 = .NOT. gpu_tend_dev
   IF ( .NOT. gpu_push_cu2 .AND. ASSOCIATED( grid%nca ) ) gpu_push_cu2 = ANY( grid%nca > 0. )
#endif
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )
   DO ij = 1 , grid%num_tiles

BENCH_START(advance_ppt_tim)
     CALL wrf_debug ( 200 , ' call advance_ppt' )
     CALL advance_ppt(grid%rthcuten,grid%rqvcuten,grid%rqccuten,grid%rqrcuten, &
                      grid%cldfra_cup,                                         & !BSINGH -  Added for CuP scheme
                      grid%rqicuten,grid%rqscuten,           &
                      grid%rainc,grid%raincv,grid%rainsh,grid%pratec,grid%pratesh, &
                      grid%nca,grid%htop,grid%hbot,grid%cutop,grid%cubot,  &
                      grid%cuppt, grid%dt, config_flags,                   &
                      ids,ide, jds,jde, kds,kde,             &
                      ims,ime, jms,jme, kms,kme,             &
                      grid%i_start(ij), grid%i_end(ij),      &
                      grid%j_start(ij), grid%j_end(ij),      &
                      k_start    , k_end                    )
BENCH_END(advance_ppt_tim)

   ENDDO
  !$OMP END PARALLEL DO

#ifdef WRF_GPU_RESIDENT
   IF ( .NOT. gpu_tend_dev ) THEN
#endif
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )
   DO ij = 1 , grid%num_tiles
        CALL wrf_debug ( 200 , ' call phy_prep_part2' )
        CALL phy_prep_part2 ( config_flags,                              &
                        grid%muts, grid%muus, grid%muvs,                 &
                        grid%c1h, grid%c2h, grid%c1f, grid%c2f,          &
                        grid%rthraten,                                   &
                        grid%rthblten, grid%rublten, grid%rvblten,       &
                        grid%rqvblten, grid%rqcblten, grid%rqiblten,     &
                        grid%rucuten,  grid%rvcuten,  grid%rthcuten,     &
                        grid%rqvcuten, grid%rqccuten, grid%rqrcuten,     &
                        grid%rqicuten, grid%rqscuten,                    &
                        grid%rushten,  grid%rvshten,  grid%rthshten,     &
                        grid%rqvshten, grid%rqcshten, grid%rqrshten,     &
                        grid%rqishten, grid%rqsshten, grid%rqgshten,     &
                        grid%rthften,  grid%rqvften,                     &
                        grid%RUNDGDTEN, grid%RVNDGDTEN, grid%RTHNDGDTEN, &
                        grid%RPHNDGDTEN,grid%RQVNDGDTEN, grid%RMUNDGDTEN,&
                        grid%t_2, th_phy, moist(ims,kms,jms,P_QV),       &
                        ids, ide, jds, jde, kds, kde,                    &
                        ims, ime, jms, jme, kms, kme,                    &
                        grid%i_start(ij), grid%i_end(ij),                &
                        grid%j_start(ij), grid%j_end(ij),                &
                        k_start, k_end                                   )
   ENDDO
  !$OMP END PARALLEL DO
#ifdef WRF_GPU_RESIDENT
   ENDIF
#endif

!<DESCRIPTION>
!<pre>
! (5) time-split physics.
!
!     Microphysics are the only time  split physics in the WRF model 
!     at this time.  Split-physics begins with the calculation of
!     needed diagnostic quantities (pressure, temperature, etc.)
!     followed by a call to the microphysics driver, 
!     and finishes with a clean-up, storing off of a diabatic tendency
!     from the moist physics, and a re-calulation of the  diagnostic
!     quantities pressure and density.
!</pre>
!</DESCRIPTION>

   IF( config_flags%specified .or. config_flags%nested ) THEN
     sz = grid%spec_zone
   ELSE
     sz = 0
   ENDIF

   IF (config_flags%mp_physics /= 0)  then

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, its, ite, jts, jte )

     scalar_tile_loop_1a: DO ij = 1 , grid%num_tiles

       IF ( config_flags%periodic_x ) THEN
         its = max(grid%i_start(ij),ids)
         ite = min(grid%i_end(ij),ide-1)
       ELSE
         its = max(grid%i_start(ij),ids+sz)
         ite = min(grid%i_end(ij),ide-1-sz)
       ENDIF
       jts = max(grid%j_start(ij),jds+sz)
       jte = min(grid%j_end(ij),jde-1-sz)

       if (config_flags%madwrf_opt == 2) then
         CALL wrf_debug ( 200 , ' call cloud_tracer_nudge' )

         CALL cloud_tracer_nudge(  dtm, config_flags%madwrf_dt_relax, &
                                   config_flags%madwrf_dt_nudge,     &
                                   grid%xtime,                       &
                                   moist(ims,kms,jms,P_QC),          &
                                   moist(ims,kms,jms,P_QI),          &
                                   moist(ims,kms,jms,P_QS),          &
                                   tracer(ims,kms,jms,P_tr_qc),      &
                                   tracer(ims,kms,jms,P_tr_qi),      &
                                   tracer(ims,kms,jms,P_tr_qs),      &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   its, ite, jts, jte,               &
                                   k_start    , k_end                )
       end if

       CALL wrf_debug ( 200 , ' call moist_physics_prep' )
BENCH_START(moist_physics_prep_tim)
       CALL moist_physics_prep_em( grid%t_2, grid%t_1, t0, grid%rho,           &
                                   grid%al, grid%alb, grid%p, p8w, p0, grid%pb,          &
                                   grid%ph_2, grid%phb, th_phy, pi_phy , p_phy, &
                                   grid%z, grid%z_at_w, dz8w,        &
                                   dtm, grid%h_diabatic,                       &
                                   moist(ims,kms,jms,P_QV),grid%qv_diabatic,   &
                                   moist(ims,kms,jms,P_QC),grid%qc_diabatic,   &
                                   config_flags,grid%fnm, grid%fnp,            &
                                   ids, ide, jds, jde, kds, kde,     &
                                   ims, ime, jms, jme, kms, kme,     &
                                   its, ite, jts, jte,               &
                                   k_start    , k_end               )

       IF (config_flags%dust_emis.eq.1 .AND. config_flags%mp_physics.eq.thompsonaero)  then
         CALL wrf_debug ( 200 , ' call bulk_dust_emis' )
         CALL bulk_dust_emis (grid%itimestep,dtm,config_flags%num_soil_layers  &
               ,grid%u_phy,grid%v_phy,grid%rho,grid%alt                        &
               ,grid%u10,grid%v10,p8w,dz8w,grid%smois,grid%erod                &
               ,grid%ivgtyp,grid%isltyp,grid%vegfra,grid%albbck,grid%xland     &
               ,grid%dx, g, grid%qnifa2d, ids,ide, jds,jde, kds,kde            &
               ,ims,ime, jms,jme, kms,kme                                      &
               ,its,ite, jts,jte, k_start,k_end )
       ENDIF

BENCH_END(moist_physics_prep_tim)
     END DO scalar_tile_loop_1a
     !$OMP END PARALLEL DO

     CALL wrf_debug ( 200 , ' call microphysics_driver' )

#ifdef WRF_GPU_RESIDENT
     IF ( gpu_mp_dev ) THEN
!$acc kernels
       grid%sr = 0.
!$acc end kernels
     ELSE
       grid%sr = 0.
     ENDIF
#else
     grid%sr = 0.
#endif
     specified_bdy = config_flags%specified .OR. config_flags%nested
     channel_bdy = config_flags%specified .AND. config_flags%periodic_x

BENCH_START(micro_driver_tim)

!
! WRFU_AlarmIsRinging always returned false, so using an alternate  method to find out if it is time 
! to dump history/restart files so microphysics can be told to calculate things like radar reflectivity.
!
!     diagflag = .false.
!     CALL WRFU_ALARMGET(grid%alarms( HISTORY_ALARM ),prevringtime=temp_time,RingInterval=intervaltime)
!     CALL WRFU_ALARMGET(grid%alarms( RESTART_ALARM ),prevringtime=restart_time,RingInterval=restartinterval)
!     CALL domain_clock_get ( grid, current_time=CurrTime )
!     old_dt=min(old_dt,grid%dt)
!     num = INT(old_dt * precision)
!     den = precision
!     CALL WRFU_TimeIntervalSet(dtInterval, Sn=num, Sd=den)
!     IF (CurrTime .ge. temp_time + intervaltime - dtInterval .or. &
!         CurrTime .ge. restart_time + restartinterval - dtInterval ) THEN
!       diagflag = .true.
!     ENDIF
!     WRITE(wrf_err_message,*)'diag_flag=',diag_flag
!     CALL wrf_debug ( 0 , wrf_err_message )
#ifdef DM_PARALLEL
#      include "HALO_EM_SBM.inc"
#endif


     CALL microphysics_driver(                                            &
      &         DT=dtm             ,DX=grid%dx              ,DY=grid%dy   &
      &        ,DZ8W=dz8w          ,F_ICE_PHY=grid%f_ice_phy              &
      &        ,ITIMESTEP=grid%itimestep             ,LOWLYR=grid%lowlyr  &
      &        ,P8W=p8w            ,P=p_phy            ,PI_PHY=pi_phy     &
      &        ,RHO=grid%rho       ,SPEC_ZONE=grid%spec_zone              &
      &        ,SR=grid%sr              ,TH=th_phy                        &
      &        ,ssat=grid%ssat, ssati=grid%ssati                          &
      &        ,refl_10cm=grid%refl_10cm                                  & ! hm, 9/22/09 for refl
      &        ,vmi3d=grid%vmi3d                                          & ! for P3
      &        ,di3d=grid%di3d                                            & ! for P3
      &        ,rhopo3d=grid%rhopo3d                                      & ! for P3
      &        ,phii3d=grid%phii3d                                        & ! for Jensen ISHMAEL
      &        ,vmi3d_2=grid%vmi3d_2                                      & ! for P3
      &        ,di3d_2=grid%di3d_2                                        & ! for P3
      &        ,rhopo3d_2=grid%rhopo3d_2                                  & ! for P3
      &        ,phii3d_2=grid%phii3d_2                                    & ! for Jensen ISHMAEL
      &        ,vmi3d_3=grid%vmi3d_3                                      & ! for Jensen ISHMAEL
      &        ,di3d_3=grid%di3d_3                                        & ! for Jensen ISHMAEL
      &        ,rhopo3d_3=grid%rhopo3d_3                                  & ! for Jensen ISHMAEL
      &        ,phii3d_3=grid%phii3d_3                                    & ! for Jensen ISHMAEL
      &        ,itype=grid%itype                                          & ! for Jensen ISHMAEL
      &        ,itype_2=grid%itype_2                                      & ! for Jensen ISHMAEL
      &        ,itype_3=grid%itype_3                                      & ! for Jensen ISHMAEL
      &        ,WARM_RAIN=grid%warm_rain                                  &
      &        ,T8W=t8w                                                   &
      &        ,CLDFRA=grid%cldfra, EXCH_H=grid%exch_h &
      &        ,NSOURCE=grid%qndropsource                                 &
#if (WRF_CHEM == 1)
      &        ,QLSINK=grid%qlsink,CLDFRA_OLD=grid%cldfra_old             &
      &        ,PRECR=grid%precr, PRECI=grid%preci, PRECS=grid%precs, PRECG=grid%precg &
      &        ,CHEM_OPT=config_flags%chem_opt, PROGN=config_flags%progn  &
!======================
      ! Variables required for CAMMGMP Scheme when run with WRF_CHEM
      &        ,CHEM=chem                                                 &
      &        ,QME3D=grid%qme3d,PRAIN3D=grid%prain3d                     &
      &        ,NEVAPR3D=grid%nevapr3d                                    &
      &        ,RATE1ORD_CW2PR_ST3D=grid%rate1ord_cw2pr_st3d              &
      &        ,DGNUM4D=grid%dgnum4d,DGNUMWET4D=grid%dgnumwet4d           &
!======================
#endif
      &        ,XLAND=grid%xland,SNOWH=grid%SNOW,XICE=grid%XICE           &
      &        ,SPECIFIED=specified_bdy, CHANNEL_SWITCH=channel_bdy       &
      &        ,F_RAIN_PHY=grid%f_rain_phy                                &
      &        ,F_RIMEF_PHY=grid%f_rimef_phy                              &
      &        ,MP_PHYSICS=config_flags%mp_physics                        &
      &        ,ID=grid%id                                                &
      &        ,IDS=ids,IDE=ide, JDS=jds,JDE=jde, KDS=kds,KDE=kde         &
      &        ,IMS=ims,IME=ime, JMS=jms,JME=jme, KMS=kms,KME=kme         &
      &        ,IPS=ips,IPE=ipe, JPS=jps,JPE=jpe, KPS=kps,KPE=kpe         &
      &        ,I_START=grid%i_start,I_END=min(grid%i_end, ide-1)         &
      &        ,J_START=grid%j_start,J_END=min(grid%j_end, jde-1)         &
      &        ,KTS=k_start, KTE=min(k_end,kde-1)                         &
      &        ,NUM_TILES=grid%num_tiles                                  &
      &        ,NAER=grid%naer                                            &
!===================== IRRIGATION =========================
      &        ,IRRIGATION=grid%irrigation                                &
      &        ,SF_SURF_IRR_SCHEME=config_flags%sf_surf_irr_scheme        &
      &        ,IRR_DAILY_AMOUNT=config_flags%irr_daily_amount            & 
      &        ,IRR_START_HOUR=config_flags%irr_start_hour                &
      &        ,IRR_NUM_HOURS=config_flags%irr_num_hours                  &
      &        ,JULIAN_IN=grid%julian                                     &
      &        ,IRR_START_JULIANDAY=config_flags%irr_start_julianday      &
      &        ,IRR_END_JULIANDAY=config_flags%irr_end_julianday          &
      &        ,IRR_FREQ=config_flags%irr_freq,IRR_PH=config_flags%irr_ph &
      &        ,IRR_RAND_FIELD=grid%irr_rand_field                        &
      &        ,GMT=grid%gmt,XTIME=grid%xtime                             & 
!======================
      ! Variables required for CAMMGMP Scheme
      &        ,DLF=grid%dlf,DLF2=grid%dlf2,T_PHY=grid%t_phy,P_HYD=grid%p_hyd  &
      &        ,P8W_HYD=grid%p_hyd_w,TKE_PBL=grid%tke_pbl,PBLH=grid%PBLH  &
      &        ,Z_AT_MASS=grid%z,Z_AT_W=grid%z_at_w                       &
      &        ,QFX=grid%qfx,RLIQ=grid%rliq                               &
      &        ,TURBTYPE3D=grid%turbtype3d,SMAW3D=grid%smaw3d             &
      &        ,WSEDL3D=grid%wsedl3d,CLDFRA_OLD_MP=grid%cldfra_old_mp     &
      &        ,CLDFRA_MP=grid%cldfra_mp,CLDFRA_MP_ALL=grid%cldfra_mp_ALL &
      &        ,LRADIUS=grid%LRADIUS, IRADIUS=grid%IRADIUS                & !BSINGH(01/20/2014): Added for RRTMG<->CAMMGMP
      &        ,CLDFRAI=grid%cldfrai                                      &
      &        ,CLDFRAL=grid%cldfral,CLDFRA_CONV=grid%CLDFRA_CONV         &
      &        ,ALT=grid%alt                                              &
      &        ,ACCUM_MODE=config_flags%accum_mode                        &
      &        ,AITKEN_MODE=config_flags%aitken_mode                      &
      &        ,COARSE_MODE=config_flags%coarse_mode                      &
      &        ,ICWMRSH3D=grid%icwmrsh,ICWMRDP3D=grid%icwmrdp3d           &
      &        ,SHFRC3D=grid%shfrc3d,CMFMC3D=grid%cmfmc                   &
      &        ,CMFMC2_3D=grid%cmfmc2,CONFIG_FLAGS=config_flags           &
      &        ,FNM=grid%fnm,FNP=grid%fnp,RH_OLD_MP=grid%rh_old_mp        &
      &        ,LCD_OLD_MP=grid%lcd_old_mp                                &
!======================
                 ! Optional
      &        , RAINNC=grid%rainnc, RAINNCV=grid%rainncv                 &
      &        , SNOWNC=grid%snownc, SNOWNCV=grid%snowncv                 &
      &        , GRAUPELNC=grid%graupelnc, GRAUPELNCV=grid%graupelncv     & ! for milbrandt2mom
      &        , HAILNC=grid%hailnc, HAILNCV=grid%hailncv                 &
      &        , HAIL_MAXK1=grid%hail_maxk1,HAIL_MAX2D=grid%hail_max2d    &
      &        , W=grid%w_2, Z=grid%z, HT=grid%ht                         &
      &        , MP_RESTART_STATE=grid%mp_restart_state                   &
      &        , TBPVS_STATE=grid%tbpvs_state                             & ! etampnew
      &        , TBPVS0_STATE=grid%tbpvs0_state                           & ! etampnew
      &        , QV_CURR=moist(ims,kms,jms,P_QV), F_QV=F_QV               &
      &        , QC_CURR=moist(ims,kms,jms,P_QC), F_QC=F_QC               &
      &        , QR_CURR=moist(ims,kms,jms,P_QR), F_QR=F_QR               &
      &        , QI_CURR=moist(ims,kms,jms,P_QI), F_QI=F_QI               &
      &        , QS_CURR=moist(ims,kms,jms,P_QS), F_QS=F_QS               &
      &        , QG_CURR=moist(ims,kms,jms,P_QG), F_QG=F_QG               &
      &        , QH_CURR=moist(ims,kms,jms,P_QH), F_QH=F_QH               & ! for milbrandt2mom
      &        , QIC_CURR=moist(ims,kms,jms,P_QIC), F_QIC=F_QIC               &
      &        , QIP_CURR=moist(ims,kms,jms,P_QIP), F_QIP=F_QIP               &
      &        , QID_CURR=moist(ims,kms,jms,P_QID), F_QID=F_QID               &
      &        , QNDROP_CURR=scalar(ims,kms,jms,P_QNDROP), F_QNDROP=F_QNDROP &
#if (WRF_CHEM == 1)
      &        , RAINPROD=wetscav_frcing(ims,kms,jms,p_rainprod)          &
      &        , EVAPPROD=wetscav_frcing(ims,kms,jms,p_evapprod)          &
      &        , QV_B4MP=grid%qv_b4mp,QC_B4MP=grid%qc_b4mp                &
      &        , QI_B4MP=grid%qi_b4mp, QS_B4MP=grid%qs_b4mp               &
#endif
      &        , QT_CURR=scalar(ims,kms,jms,P_QT), F_QT=F_QT              &
      &        , QNN_CURR=scalar(ims,kms,jms,P_QNN), F_QNN=F_QNN          &
      &        , QNI_CURR=scalar(ims,kms,jms,P_QNI), F_QNI=F_QNI          &
      &        , QNC_CURR=scalar(ims,kms,jms,P_QNC), F_QNC=F_QNC          &
      &        , QNR_CURR=scalar(ims,kms,jms,P_QNR), F_QNR=F_QNR          &
      &        , QNS_CURR=scalar(ims,kms,jms,P_QNS), F_QNS=F_QNS          &
      &        , QNG_CURR=scalar(ims,kms,jms,P_QNG), F_QNG=F_QNG          &
      &        , QNWFA_CURR=scalar(ims,kms,jms,P_QNWFA), F_QNWFA=F_QNWFA  & ! for Thompson water-friendly aerosol
      &        , QNIFA_CURR=scalar(ims,kms,jms,P_QNIFA), F_QNIFA=F_QNIFA  & ! for Thompson ice-friendly aerosol
      &        , QNBCA_CURR=scalar(ims,kms,jms,P_QNBCA), F_QNBCA=F_QNBCA  & ! for Thompson black carbon aerosol
      &        , QNH_CURR=scalar(ims,kms,jms,P_QNH), F_QNH=F_QNH          & ! for milbrandt2mom and nssl_2mom
      &        , QNIC_CURR=scalar(ims,kms,jms,P_QNIC), F_QNIC=F_QNIC          &
      &        , QNIP_CURR=scalar(ims,kms,jms,P_QNIP), F_QNIP=F_QNIP          &
      &        , QNID_CURR=scalar(ims,kms,jms,P_QNID), F_QNID=F_QNID          &
      &        , QIR_CURR=scalar(ims,kms,jms,P_QIR), F_QIR=F_QIR          & ! for P3
      &        , QIB_CURR=scalar(ims,kms,jms,P_QIB), F_QIB=F_QIB          & ! for P3
      &        , QVOLI_CURR=scalar(ims,kms,jms,P_QVOLI), F_QVOLI=F_QVOLI  & ! for Jensen ISHMAEL
      &        , QAOLI_CURR=scalar(ims,kms,jms,P_QAOLI), F_QAOLI=F_QAOLI  & ! for Jensen ISHMAEL
      &        , QI2_CURR=moist(ims,kms,jms,P_QI2), F_QI2=F_QI2           & ! for P3
      &        , QNI2_CURR=scalar(ims,kms,jms,P_QNI2), F_QNI2=F_QNI2      & ! for P3
      &        , QIR2_CURR=scalar(ims,kms,jms,P_QIR2), F_QIR2=F_QIR2      & ! for P3
      &        , QIB2_CURR=scalar(ims,kms,jms,P_QIB2), F_QIB2=F_QIB2      & ! for P3
      &        , QVOLI2_CURR=scalar(ims,kms,jms,P_QVOLI2), F_QVOLI2=F_QVOLI2  & ! for Jensen ISHMAEL
      &        , QAOLI2_CURR=scalar(ims,kms,jms,P_QAOLI2), F_QAOLI2=F_QAOLI2  & ! for Jensen ISHMAEL
      &        , QI3_CURR=moist(ims,kms,jms,P_QI3), F_QI3=F_QI3           & ! for Jensen ISHMAEL
      &        , QNI3_CURR=scalar(ims,kms,jms,P_QNI3), F_QNI3=F_QNI3      & ! for Jensen ISHMAEL
      &        , QVOLI3_CURR=scalar(ims,kms,jms,P_QVOLI3), F_QVOLI3=F_QVOLI3  & ! for Jensen ISHMAEL
      &        , QAOLI3_CURR=scalar(ims,kms,jms,P_QAOLI3), F_QAOLI3=F_QAOLI3  & ! for Jensen ISHMAEL
       &        , QZR_CURR=scalar(ims,kms,jms,P_QZR), F_QZR=F_QZR          & ! for milbrandt3mom
       &        , QZI_CURR=scalar(ims,kms,jms,P_QZI), F_QZI=F_QZI          & ! for 3-moment P3
!       &        , QZS_CURR=scalar(ims,kms,jms,P_QZS), F_QZS=F_QZS          & ! "
       &        , QZG_CURR=scalar(ims,kms,jms,P_QZG), F_QZG=F_QZG          & ! "
       &        , QZH_CURR=scalar(ims,kms,jms,P_QZH), F_QZH=F_QZH          & ! "
      &        , QVOLG_CURR=scalar(ims,kms,jms,P_QVOLG), F_QVOLG=F_QVOLG    & ! for nssl_2mom
      &        , QVOLH_CURR=scalar(ims,kms,jms,P_QVOLH), F_QVOLH=F_QVOLH    & ! for nssl_2mom
      &        , QDCN_CURR=scalar(ims,kms,jms,P_QDCN), F_QDCN=F_QDCN      & ! for ntu3m
      &        , QTCN_CURR=scalar(ims,kms,jms,P_QTCN), F_QTCN=F_QTCN      & ! for ntu3m
      &        , QCCN_CURR=scalar(ims,kms,jms,P_QCCN), F_QCCN=F_QCCN      & ! for ntu3m
      &        , QRCN_CURR=scalar(ims,kms,jms,P_QRCN), F_QRCN=F_QRCN      & ! for ntu3m
      &        , QNIN_CURR=scalar(ims,kms,jms,P_QNIN), F_QNIN=F_QNIN      & ! for ntu3m
      &        , FI_CURR=scalar(ims,kms,jms,P_FI), F_FI=F_FI              & ! for ntu3m
      &        , FS_CURR=scalar(ims,kms,jms,P_FS), F_FS=F_FS              & ! for ntu3m
      &        , VI_CURR=scalar(ims,kms,jms,P_VI), F_VI=F_VI              & ! for ntu3m
      &        , VS_CURR=scalar(ims,kms,jms,P_VS), F_VS=F_VS              & ! for ntu3m
      &        , VG_CURR=scalar(ims,kms,jms,P_VG), F_VG=F_VG              & ! for ntu3m
      &        , AI_CURR=scalar(ims,kms,jms,P_AI), F_AI=F_AI              & ! for ntu3m
      &        , AS_CURR=scalar(ims,kms,jms,P_AS), F_AS=F_AS              & ! for ntu3m
      &        , AG_CURR=scalar(ims,kms,jms,P_AG), F_AG=F_AG              & ! for ntu3m
      &        , AH_CURR=scalar(ims,kms,jms,P_AH), F_AH=F_AH              & ! for ntu3m
      &        , I3M_CURR=scalar(ims,kms,jms,P_I3M), F_I3M=F_I3m          & ! for ntu3m
      &        , cu_used=config_flags%cu_used                             &
      &        , qrcuten=grid%rqrcuten, qscuten=grid%rqscuten             &
      &        , qicuten=grid%rqicuten, qccuten=grid%rqccuten             &
      &        , HAIL=config_flags%gsfcgce_hail                           & ! for gsfcgce
      &        , ICE2=config_flags%gsfcgce_2ice                           & ! for gsfcgce
      &        , PHYS_TOT=grid%phys_tot                                   & ! for gsfcgce
      &        , PHYSC=grid%physc                                         & ! for gsfcgce
      &        , PHYSE=grid%physe                                         & ! for gsfcgce
      &        , PHYSD=grid%physd                                         & ! for gsfcgce
      &        , PHYSS=grid%physs                                         & ! for gsfcgce
      &        , PHYSM=grid%physm                                         & ! for gsfcgce
      &        , PHYSF=grid%physf                                         & ! for gsfcgce

      &        , ACPHYS_TOT=grid%acphys_tot                               & ! for gsfcgce
      &        , ACPHYSC=grid%acphysc                                     & ! for gsfcgce
      &        , ACPHYSE=grid%acphyse                                     & ! for gsfcgce
      &        , ACPHYSD=grid%acphysd                                     & ! for gsfcgce
      &        , ACPHYSS=grid%acphyss                                     & ! for gsfcgce
      &        , ACPHYSM=grid%acphysm                                     & ! for gsfcgce
      &        , ACPHYSF=grid%acphysf                                     & ! for gsfcgce

      &        , RE_CLOUD_GSFC=grid%re_cloud_gsfc                         & ! for gsfcgce
      &        , RE_RAIN_GSFC=grid%re_rain_gsfc                           & ! for gsfcgce
      &        , RE_ICE_GSFC=grid%re_ice_gsfc                             & ! for gsfcgce
      &        , RE_SNOW_GSFC=grid%re_snow_gsfc                           & ! for gsfcgce
      &        , RE_GRAUPEL_GSFC=grid%re_graupel_gsfc                     & ! for gsfcgce
      &        , RE_HAIL_GSFC=grid%re_hail_gsfc                           & ! for gsfcgce
      &        , PRECR3D=grid%precr3d, PRECI3D=grid%preci3d, PRECS3D=grid%precs3d  &
      &        , PRECG3D=grid%precg3d, PRECH3D=grid%prech3d               &
#if ( WRF_CHEM == 1)
      &        , GSFCGCE_GOCART_COUPLING=config_flags%gsfcgce_gocart_coupling &
      &        , ICN_DIAG=grid%icn_diag                                   & ! inline gocart
      &        , NC_DIAG=grid%nc_diag                                     & ! inline gocart
#endif
!NUWRF JJS 20110525 ^^^^^
!     &        , ccntype=config_flags%milbrandt_ccntype                   & ! for milbrandt (2mom)
! YLIN
! RI_CURR INPUT
      &        , RI_CURR=grid%rimi                                          &
      &        , re_cloud=grid%re_cloud, re_ice=grid%re_ice, re_snow=grid%re_snow & ! G. Thompson
      &        , has_reqc=grid%has_reqc, has_reqi=grid%has_reqi, has_reqs=grid%has_reqs & ! G. Thompson
      &        , qnwfa2d=grid%qnwfa2d, qnifa2d=grid%qnifa2d, qnbca2d=grid%qnbca2d       & ! G. Thompson
      &        , qnocbb2d=grid%qnocbb2d, qnbcbb2d=grid%qnbcbb2d             & ! for biomass burning emissions
      &        , diagflag=diag_flag, do_radar_ref=config_flags%do_radar_ref &
      &        , ke_diag=ke_diag                                           &
      &        ,u=grid%u_phy,v=grid%v_phy &
      &        ,scalar=scalar,num_scalar=num_scalar                             &
      &        ,TH_OLD=grid%th_old                                        &
      &        ,QV_OLD=grid%qv_old                                        &
      &        ,xlat=grid%xlat,xlong=grid%xlong,IVGTYP=grid%ivgtyp  &
      &        , EFFR_CURR=scalar(ims,kms,jms,P_EFFR), F_EFFR=F_EFFR          & ! for SBM
      &        , ICE_EFFR_CURR=scalar(ims,kms,jms,P_ICE_EFFR), F_ICE_EFFR=F_ICE_EFFR          & ! for SBM
      &        , TOT_EFFR_CURR=scalar(ims,kms,jms,P_TOT_EFFR), F_TOT_EFFR=F_TOT_EFFR          & ! for SBM
      &        , QIC_EFFR_CURR=scalar(ims,kms,jms,P_QIC_EFFR), F_QIC_EFFR=F_QIC_EFFR          & ! for SBM
      &        , QIP_EFFR_CURR=scalar(ims,kms,jms,P_QIP_EFFR), F_QIP_EFFR=F_QIP_EFFR          & ! for SBM
      &        , QID_EFFR_CURR=scalar(ims,kms,jms,P_QID_EFFR), F_QID_EFFR=F_QID_EFFR          & ! for SBM
      &        ,kext_ql=grid%kext_ql                                       &
      &        ,kext_qs=grid%kext_qs                                       &
      &        ,kext_qg=grid%kext_qg                                       &
      &        ,kext_qh=grid%kext_qh                                       &
      &        ,kext_qa=grid%kext_qa                                       &
      &        ,kext_qic=grid%kext_qic                                       &
      &        ,kext_qip=grid%kext_qip                                       &
      &        ,kext_qid=grid%kext_qid                                       &
      &        ,kext_ft_qic=grid%kext_ft_qic                                       &
      &        ,kext_ft_qip=grid%kext_ft_qip                                       &
      &        ,kext_ft_qid=grid%kext_ft_qid                                       &
      &        ,kext_ft_qs=grid%kext_ft_qs                                       &
      &        ,kext_ft_qg=grid%kext_ft_qg         &
      &        ,height=grid%height                                         &
      &        ,tempc=grid%tempc                                         &
      &        ,ccn_conc=grid%ccn_conc                                   & ! RAS
      &        ,sbmradar=sbmradar,num_sbmradar=num_sbmradar              & ! for SBM
      &        ,sbm_diagnostics=config_flags%sbm_diagnostics             & ! for SBM
      &        ,aerocu=aerocu                                            &
      &        ,aercu_fct=config_flags%aercu_fct                         &
      &        ,aercu_opt=config_flags%aercu_opt                         &
      &        ,no_src_types_cu=grid%no_src_types_cu                     &
      &        ,PBL=grid%bl_pbl_physics,EFCG=grid%EFCG,EFIG=grid%EFIG,EFSG=grid%EFSG &
      &        ,WACT=grid%WACT,CCN1_GS=grid%CCN1_GS,CCN2_GS=grid%CCN2_GS,CCN3_GS=grid%CCN3_GS  &
      &        ,CCN4_GS=grid%CCN4_GS,CCN5_GS=grid%CCN5_GS,CCN6_GS=grid%CCN6_GS &
      &        ,CCN7_GS=grid%CCN7_GS,NR_CU=grid%NR_CU,QR_CU=grid%QR_CU,NS_CU=grid%NS_CU &
      &        ,QS_CU=grid%QS_CU,CU_UAF=grid%CU_UAF,mskf_refl_10cm=grid%mskf_refl_10cm  &
! WRF-Solar EPS
      &        ,multi_perturb=config_flags%multi_perturb                 &
      &        ,pert_thom=config_flags%pert_thom                         &
      &        ,perts_qvapor=grid%pert3d(:,:,:,P_PQVAPOR)                &
      &        ,perts_qcloud=grid%pert3d(:,:,:,P_PQCLOUD)                &
      &        ,perts_qice=grid%pert3d(:,:,:,P_PQICE)                    &
      &        ,perts_qsnow=grid%pert3d(:,:,:,P_PQSNOW)                  &
      &        ,perts_ni=grid%pert3d(:,:,:,P_PNI)                        &
      &        ,pert_thom_qv=config_flags%pert_thom_qv                   &
      &        ,pert_thom_qc=config_flags%pert_thom_qc                   &
      &        ,pert_thom_qi=config_flags%pert_thom_qi                   &
      &        ,pert_thom_qs=config_flags%pert_thom_qs                   &
      &        ,pert_thom_ni=config_flags%pert_thom_ni                   &
      &        ,cloudnc=grid%cloudnc                                     &
! Dynamic Lightning Scheme
      &        ,light_pe_curr=scalar(ims,kms,jms,P_light_pe), F_light_pe=F_light_pe   &
      &        ,light_ne_curr=scalar(ims,kms,jms,P_light_ne), F_light_ne=F_light_ne   &
      &        ,light_neu_curr=scalar(ims,kms,jms,P_light_neu), F_light_neu=F_light_neu   &
      &        ,lpos=grid%lpos,lneg=grid%lneg,lneu=grid%lneu             &
      &        ,lpi2d=grid%lpi2d,lpi3d=grid%lpi3d                        &
	)

                                                                          
BENCH_END(micro_driver_tim)

#if 0
BENCH_START(microswap_2)
! for load balancing; communication to redistribute the points
      IF ( config_flags%mp_physics .EQ. ETAMPNEW .OR. &
     &     config_flags%mp_physics .EQ. FER_MP_HIRES) THEN
#include "SWAP_ETAMP_NEW.inc"
     ELSE IF ( config_flags%mp_physics .EQ. WSM3SCHEME ) THEN
#include "SWAP_WSM3.inc"
     ENDIF
BENCH_END(microswap_2)
#endif

     CALL wrf_debug ( 200 , ' call moist_physics_finish' )
BENCH_START(moist_phys_end_tim)

     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij, its, ite, jts, jte, im, ii, jj, kk )

     DO ij = 1 , grid%num_tiles

       its = max(grid%i_start(ij),ids)
       ite = min(grid%i_end(ij),ide-1)
       jts = max(grid%j_start(ij),jds)
       jte = min(grid%j_end(ij),jde-1)

       IF ( config_flags%mp_zero_out > 0 ) THEN
       CALL microphysics_zero_outb (                                    &
                      moist , num_moist , config_flags ,                &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )

       IF ( config_flags%mp_zero_out_all > 0 ) THEN
       CALL microphysics_zero_outb (                                    &
                      scalar , num_scalar , config_flags ,              &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )

       CALL microphysics_zero_outb (                                    &
                      chem , num_chem , config_flags ,                  &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )
       CALL microphysics_zero_outb (                                    &
                      tracer , num_tracer , config_flags ,              &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )
       ENDIF
       ENDIF

       IF ( config_flags%periodic_x ) THEN
         its = max(grid%i_start(ij),ids)
         ite = min(grid%i_end(ij),ide-1)
       ELSE
         its = max(grid%i_start(ij),ids+sz)
         ite = min(grid%i_end(ij),ide-1-sz)
       ENDIF
       jts = max(grid%j_start(ij),jds+sz)
       jte = min(grid%j_end(ij),jde-1-sz)

       IF ( config_flags%mp_zero_out > 0 ) THEN
       CALL microphysics_zero_outa (                                    &
                      moist , num_moist , config_flags ,                &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )

       IF ( config_flags%mp_zero_out_all > 0 ) THEN
       CALL microphysics_zero_outa (                                    &
                      scalar , num_scalar , config_flags ,              &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )

       CALL microphysics_zero_outa (                                    &
                      chem , num_chem , config_flags ,                  &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )

       CALL microphysics_zero_outa (                                    &
                      tracer , num_tracer , config_flags ,              &
                      ids, ide, jds, jde, kds, kde,                     &
                      ims, ime, jms, jme, kms, kme,                     &
                      its, ite, jts, jte,                               &
                      k_start    , k_end                                )
       ENDIF
       ENDIF

       CALL moist_physics_finish_em( grid%t_2, grid%t_1, t0, grid%muts, th_phy,  &
                                     grid%h_diabatic, dtm,                       &
                                     moist(ims,kms,jms,P_QV),grid%qv_diabatic,   &
                                     moist(ims,kms,jms,P_QC),grid%qc_diabatic,   &
                                     grid%th_phy_m_t0,                           &
                                     config_flags,                               &
#if ( WRF_DFI_RADAR == 1 )
                                     grid%dfi_tten_rad,grid%dfi_stage,           &
#endif
                                     ids, ide, jds, jde, kds, kde,               &
                                     ims, ime, jms, jme, kms, kme,               &
                                     its, ite, jts, jte,                         &
                                     k_start    , k_end                          )

     END DO
     !$OMP END PARALLEL DO

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
#       include "HALO_EM_THETAM.inc"
#       include "PERIOD_EM_THETAM.inc"
#endif
#ifdef WRF_GPU_RESIDENT
#endif
#ifdef WRF_GPU
   IF ( .NOT. gpu_mp_dev ) THEN
        wrf_gpu_on = .TRUE. ; CALL rsl_set_gpu_on( .TRUE. )
       CALL gpu_retile( grid, .FALSE., ids, ide, jds, jde, ips, ipe, jps, jpe )
   ENDIF
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 1 )
#endif
#ifdef WRF_GPU_RESIDENT
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   IF ( gpu_mp_dev ) THEN
     ! host-written in this block: advance_ppt (cumulus rain; cumulus tendencies when an NCA countdown ended)
!$acc update device(grid%rainc) if(associated(grid%rainc))
!$acc update device(grid%rqccuten) if(associated(grid%rqccuten) .and. gpu_push_cu2)
!$acc update device(grid%rqicuten) if(associated(grid%rqicuten) .and. gpu_push_cu2)
!$acc update device(grid%rqvcuten) if(associated(grid%rqvcuten) .and. gpu_push_cu2)
!$acc update device(grid%rthcuten) if(associated(grid%rthcuten) .and. gpu_push_cu2)
!$acc update device(grid%rucuten) if(associated(grid%rucuten) .and. gpu_push_cu2)
!$acc update device(grid%rvcuten) if(associated(grid%rvcuten) .and. gpu_push_cu2)
   ELSE IF ( IAND( wrf_gpu_xfer(), 2 ) /= 0 ) THEN
#  include "gpu_upd_dev_h2.inc"
#       include "gpu_upd_dev_i1_mp.inc"
   ELSE
#  include "gpu_upd_dev_post_mp.inc"
#       include "gpu_upd_dev_i1_mp.inc"
   ENDIF
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'g_postH2', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 3 ) == 3 ) THEN
#    include "gpu_sync_dev_all.inc"
#    include "gpu_upd_dev_i1_all.inc"
   ENDIF
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   IF ( wrf_gpu_prefetch_mode() > 0 ) THEN
#  include "gpu_pf_dev_post_mp.inc"
   ENDIF
#endif
        its=ips ; ite = ipe
        jts=jps ; jte = jpe
        CALL set_physical_bc3d( grid%h_diabatic, 'p', config_flags,      &
                                ids, ide, jds, jde, kds, kde,     &
                                ims, ime, jms, jme, kms, kme,     &
                                ips, ipe, jps, jpe, kps, kpe,     &
                                its, ite, jts, jte,               &
                                k_start    , k_end                )
   ENDIF  ! microphysics test

!-----------------------------------------------------------
!  filter for moist variables post-microphysics and end of timestep
!-----------------------------------------------------------

   IF (config_flags%polar) THEN
     IF ( num_3d_m >= PARAM_FIRST_SCALAR ) THEN
       CALL wrf_debug ( 200 , ' call filter moist' )
       DO im = PARAM_FIRST_SCALAR, num_3d_m
         IF ( config_flags%coupled_filtering ) THEN
           CALL couple_scalars_for_filter ( FIELD=moist(ims,kms,jms,im)        &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF
 
         CALL pxft ( grid=grid                                                 &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 0                                      &
                  ,flag_rurv          = 0                                      &
                  ,flag_wph           = 0                                      &
                  ,flag_ww            = 0                                      &
                  ,flag_t             = 0                                      &
                  ,flag_mu            = 0                                      &
                  ,flag_mut           = 0                                      &
                  ,flag_moist         = im                                     &
                  ,flag_chem          = 0                                      &
                  ,flag_tracer        = 0                                      &
                  ,flag_scalar        = 0                                      &
                  ,actual_distance_average=config_flags%actual_distance_average&
                  ,pos_def            = config_flags%pos_def                   &
                  ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )
 
         IF ( config_flags%coupled_filtering ) THEN
           CALL uncouple_scalars_for_filter ( FIELD=moist(ims,kms,jms,im)      &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF
       ENDDO
     ENDIF
   ENDIF

!-----------------------------------------------------------
!  end filter for moist variables post-microphysics and end of timestep
!-----------------------------------------------------------


   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij, its, ite, jts, jte, im, ii, jj, kk )
   scalar_tile_loop_1ba: DO ij = 1 , grid%num_tiles

     IF ( config_flags%periodic_x ) THEN
       its = max(grid%i_start(ij),ids)
       ite = min(grid%i_end(ij),ide-1)
     ELSE
       its = max(grid%i_start(ij),ids+sz)
       ite = min(grid%i_end(ij),ide-1-sz)
     ENDIF
     jts = max(grid%j_start(ij),jds+sz)
     jte = min(grid%j_end(ij),jde-1-sz)

     CALL calc_p_rho_phi( moist, num_3d_m, config_flags%hypsometric_opt,                    &
                          grid%al, grid%alb, grid%mu_2, grid%muts,                          &
                          grid%c1h, grid%c2h, grid%c3h, grid%c4h, grid%c3f, grid%c4f,       &
                          grid%ph_2, grid%phb, grid%p, grid%pb, grid%t_2,                   &
                          p0, t0, grid%p_top, grid%znu, grid%znw, grid%dnw, grid%rdnw,      &
                          grid%rdn, config_flags%non_hydrostatic,config_flags%use_theta_m,  &
                          ids, ide, jds, jde, kds, kde,                                     &
                          ims, ime, jms, jme, kms, kme,                                     &
                          its, ite, jts, jte,                                               &
                          k_start    , k_end                                                )

   END DO scalar_tile_loop_1ba
   !$OMP END PARALLEL DO
BENCH_END(moist_phys_end_tim)

   IF (.not. config_flags%non_hydrostatic) THEN
#ifdef DM_PARALLEL
#    include "HALO_EM_HYDRO_UV.inc"
#    include "PERIOD_EM_HYDRO_UV.inc"
#endif
     !$OMP PARALLEL DO   &
     !$OMP PRIVATE ( ij )
     DO ij = 1 , grid%num_tiles
       CALL diagnose_w( ph_tend, grid%ph_2, grid%ph_1, grid%w_2, grid%muts, &
                       grid%c1f, grid%c2f, dt_rk,              &
                       grid%u_2, grid%v_2, grid%ht,            &
                       grid%cf1, grid%cf2, grid%cf3, grid%rdx, grid%rdy, grid%msftx, grid%msfty, &
                       ids, ide, jds, jde, kds, kde,           &
                       ims, ime, jms, jme, kms, kme,           &
                       grid%i_start(ij), grid%i_end(ij),       &
                       grid%j_start(ij), grid%j_end(ij),       &
                       k_start    , k_end                     )

     END DO
     !$OMP END PARALLEL DO

   END IF

   CALL wrf_debug ( 200 , ' call chem polar filter ' )

!-----------------------------------------------------------
!  filter for chem and scalar variables at end of timestep
!-----------------------------------------------------------

   IF (config_flags%polar) THEN

     IF ( num_3d_c >= PARAM_FIRST_SCALAR ) then
       chem_filter_loop: DO im = PARAM_FIRST_SCALAR, num_3d_c
         IF ( config_flags%coupled_filtering ) THEN
             CALL couple_scalars_for_filter ( FIELD=chem(ims,kms,jms,im)               &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe           )
         END IF

         CALL pxft ( grid=grid                                                 &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 0                                      &
                  ,flag_rurv          = 0                                      &
                  ,flag_wph           = 0                                      &
                  ,flag_ww            = 0                                      &
                  ,flag_t             = 0                                      &
                  ,flag_mu            = 0                                      &
                  ,flag_mut           = 0                                      &
                  ,flag_moist         = 0                                      &
                  ,flag_chem          = im                                     &
                  ,flag_tracer        = 0                                      &
                  ,flag_scalar        = 0                                      &
                  ,actual_distance_average=config_flags%actual_distance_average&
                  ,pos_def            = config_flags%pos_def                   &
                  ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

         IF ( config_flags%coupled_filtering ) THEN
             CALL uncouple_scalars_for_filter ( FIELD=chem(ims,kms,jms,im)       &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF
       ENDDO chem_filter_loop
     ENDIF
     IF ( num_tracer >= PARAM_FIRST_SCALAR ) then
       tracer_filter_loop: DO im = PARAM_FIRST_SCALAR, num_tracer
         IF ( config_flags%coupled_filtering ) THEN
           CALL couple_scalars_for_filter ( FIELD=tracer(ims,kms,jms,im)         &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe           )
         END IF

         CALL pxft ( grid=grid                                                 &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 0                                      &
                  ,flag_rurv          = 0                                      &
                  ,flag_wph           = 0                                      &
                  ,flag_ww            = 0                                      &
                  ,flag_t             = 0                                      &
                  ,flag_mu            = 0                                      &
                  ,flag_mut           = 0                                      &
                  ,flag_moist         = 0                                      &
                  ,flag_chem          = 0                                      &
                  ,flag_tracer        = im                                     &
                  ,flag_scalar        = 0                                      &
                  ,actual_distance_average=config_flags%actual_distance_average&
                  ,pos_def            = config_flags%pos_def                   &
                  ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

         IF ( config_flags%coupled_filtering ) THEN
           CALL uncouple_scalars_for_filter ( FIELD=tracer(ims,kms,jms,im)       &
                    ,MU=grid%mu_2 , MUB=grid%mub                                 &
                    ,C1=grid%c1h , C2=grid%c2h                                   &
                    ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                    ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                    ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF
       ENDDO tracer_filter_loop
     ENDIF

     IF ( num_3d_s >= PARAM_FIRST_SCALAR ) then
       scalar_filter_loop: DO im = PARAM_FIRST_SCALAR, num_3d_s
         IF ( config_flags%coupled_filtering ) THEN
           CALL couple_scalars_for_filter ( FIELD=scalar(ims,kms,jms,im)       &
                  ,MU=grid%mu_2 , MUB=grid%mub                                 &
                  ,C1=grid%c1h , C2=grid%c2h                                   &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF

         CALL pxft ( grid=grid                                                 &
                  ,lineno=__LINE__                                             &
                  ,flag_uv            = 0                                      &
                  ,flag_rurv          = 0                                      &
                  ,flag_wph           = 0                                      &
                  ,flag_ww            = 0                                      &
                  ,flag_t             = 0                                      &
                  ,flag_mu            = 0                                      &
                  ,flag_mut           = 0                                      &
                  ,flag_moist         = 0                                      &
                  ,flag_chem          = 0                                      &
                  ,flag_tracer        = 0                                      &
                  ,flag_scalar        = im                                     &
                  ,actual_distance_average=config_flags%actual_distance_average&
                  ,pos_def            = config_flags%pos_def                   &
                  ,swap_pole_with_next_j = config_flags%swap_pole_with_next_j  &
                  ,moist=moist,chem=chem,tracer=tracer,scalar=scalar           &
                  ,fft_filter_lat = config_flags%fft_filter_lat                &
                  ,dclat = dclat                                               &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe             &
                  ,imsx=imsx,imex=imex,jmsx=jmsx,jmex=jmex,kmsx=kmsx,kmex=kmex &
                  ,ipsx=ipsx,ipex=ipex,jpsx=jmsx,jpex=jpex,kpsx=kpsx,kpex=kpex )

         IF ( config_flags%coupled_filtering ) THEN
           CALL uncouple_scalars_for_filter ( FIELD=scalar(ims,kms,jms,im)     &
                  ,MU=grid%mu_2 , MUB=grid%mub                                 &
                  ,C1=grid%c1h , C2=grid%c2h                                   &
                  ,ids=ids,ide=ide,jds=jds,jde=jde,kds=kds,kde=kde             &
                  ,ims=ims,ime=ime,jms=jms,jme=jme,kms=kms,kme=kme             &
                  ,ips=ips,ipe=ipe,jps=jps,jpe=jpe,kps=kps,kpe=kpe          )
         END IF
       ENDDO scalar_filter_loop
     ENDIF
   ENDIF

!-----------------------------------------------------------
!  end filter for chem and scalar variables at end of timestep
!-----------------------------------------------------------

   !  We're finished except for boundary condition (and patch) update

   ! Boundary condition time (or communication time).  At this time, we have
   ! implemented periodic and symmetric physical boundary conditions.

   ! b.c. routine for data within patch.

   ! we need to do both time levels of 
   ! data because the time filter only works in the physical solution space.

   ! First, do patch communications for boundary conditions (periodicity)

!-----------------------------------------------------------
!  Stencils for patch communications  (WCS, 29 June 2001)
!
!  here's where we need a wide comm stencil - these are the 
!  uncoupled variables so are used for high order calc in
!  advection and mixong routines.
!
!                              * * * * *
!            *        * * *    * * * * *
!          * + *      * + *    * * + * * 
!            *        * * *    * * * * *
!                              * * * * *
!
!   grid%u_1                            x
!   grid%u_2                            x
!   grid%v_1                            x
!   grid%v_2                            x
!   grid%w_1                            x
!   grid%w_2                            x
!   grid%t_1                            x
!   grid%t_2                            x
!  grid%ph_1                            x
!  grid%ph_2                            x
!  grid%tke_1                           x
!  grid%tke_2                           x
!
!    2D variables
!  grid%mu_1     x
!  grid%mu_2     x
!
!    4D variables
!  moist                         x
!   chem                         x
! scalar                         x
!----------------------------------------------------------


#ifdef DM_PARALLEL
   IF      ( config_flags%h_mom_adv_order <= 4 .and. config_flags%h_sca_adv_order <= 4 ) THEN
#    include "HALO_EM_D3_3.inc"
   ELSE IF ( config_flags%h_mom_adv_order <= 6 .and. config_flags%h_sca_adv_order <= 6 ) THEN
#    include "HALO_EM_D3_5.inc"
   ELSE 
      WRITE(wrf_err_message,*)'solve_em: invalid h_mom_adv_order or h_sca_adv_order = ', &
               config_flags%h_mom_adv_order, config_flags%h_sca_adv_order
      CALL wrf_error_fatal(TRIM(wrf_err_message))
   ENDIF
#  include "PERIOD_BDY_EM_D3.inc"
#  include "PERIOD_BDY_EM_MOIST.inc"
#  include "PERIOD_BDY_EM_CHEM.inc"
#  include "PERIOD_BDY_EM_TRACER.inc"
#  include "PERIOD_BDY_EM_SCALAR.inc"
#endif

!  now set physical b.c on a patch

BENCH_START(bc_2d_tim)
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )
   tile_bc_loop_2: DO ij = 1 , grid%num_tiles

     CALL wrf_debug ( 200 , ' call set_phys_bc_dry_2' )

     CALL set_phys_bc_dry_2( config_flags,                           &
                             grid%u_1, grid%u_2, grid%v_1, grid%v_2, grid%w_1, grid%w_2,           &
                             grid%t_1, grid%t_2, grid%ph_1, grid%ph_2, grid%mu_1, grid%mu_2,       &
                             ids, ide, jds, jde, kds, kde,           &
                             ims, ime, jms, jme, kms, kme,           &
                             ips, ipe, jps, jpe, kps, kpe,           &
                             grid%i_start(ij), grid%i_end(ij),       &
                             grid%j_start(ij), grid%j_end(ij),       &
                             k_start    , k_end                     )

     CALL set_physical_bc3d( grid%tke_1, 'p', config_flags,   &
                             ids, ide, jds, jde, kds, kde,            &
                             ims, ime, jms, jme, kms, kme,            &
                             ips, ipe, jps, jpe, kps, kpe,            &
                             grid%i_start(ij), grid%i_end(ij),        &
                             grid%j_start(ij), grid%j_end(ij),        &
                             k_start    , k_end-1                    )

     CALL set_physical_bc3d( grid%tke_2 , 'p', config_flags,  &
                             ids, ide, jds, jde, kds, kde,            &
                             ims, ime, jms, jme, kms, kme,            &
                             ips, ipe, jps, jpe, kps, kpe,            &
                             grid%i_start(ij), grid%i_end(ij),        &
                             grid%j_start(ij), grid%j_end(ij),        &
                             k_start    , k_end                      )

     moisture_loop_bdy_2 : DO im = PARAM_FIRST_SCALAR , num_3d_m

       CALL set_physical_bc3d( moist(ims,kms,jms,im), 'p',           &
                               config_flags,                           &
                               ids, ide, jds, jde, kds, kde,           &
                               ims, ime, jms, jme, kms, kme,           &
                               ips, ipe, jps, jpe, kps, kpe,           &
                               grid%i_start(ij), grid%i_end(ij),       &
                               grid%j_start(ij), grid%j_end(ij),       &
                               k_start    , k_end                     )

     END DO moisture_loop_bdy_2

     chem_species_bdy_loop_2 : DO ic = PARAM_FIRST_SCALAR , num_3d_c

       CALL set_physical_bc3d( chem(ims,kms,jms,ic) , 'p', config_flags,  &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               ips, ipe, jps, jpe, kps, kpe,            &
                               grid%i_start(ij), grid%i_end(ij),                  &
                               grid%j_start(ij), grid%j_end(ij),                  &
                               k_start    , k_end                      )

     END DO chem_species_bdy_loop_2

     tracer_species_bdy_loop_2 : DO ic = PARAM_FIRST_SCALAR , num_tracer

       CALL set_physical_bc3d( tracer(ims,kms,jms,ic) , 'p', config_flags,  &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               ips, ipe, jps, jpe, kps, kpe,            &
                               grid%i_start(ij), grid%i_end(ij),                  &
                               grid%j_start(ij), grid%j_end(ij),                  &
                               k_start    , k_end                      )

     END DO tracer_species_bdy_loop_2

     scalar_species_bdy_loop_2 : DO is = PARAM_FIRST_SCALAR , num_3d_s

       CALL set_physical_bc3d( scalar(ims,kms,jms,is) , 'p', config_flags,  &
                               ids, ide, jds, jde, kds, kde,            &
                               ims, ime, jms, jme, kms, kme,            &
                               ips, ipe, jps, jpe, kps, kpe,            &
                               grid%i_start(ij), grid%i_end(ij),                  &
                               grid%j_start(ij), grid%j_end(ij),                  &
                               k_start    , k_end                      )

     END DO scalar_species_bdy_loop_2

   END DO tile_bc_loop_2
   !$OMP END PARALLEL DO
BENCH_END(bc_2d_tim)

!  this code forces boundary values to specified values to avoid drift

   IF( config_flags%specified .or. config_flags%nested ) THEN 
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )
   tile_bc_loop_3: DO ij = 1 , grid%num_tiles

     CALL wrf_debug ( 200 , ' call spec_bdy_final' )

     CALL spec_bdy_final   ( grid%u_2, grid%muus, grid%c1h, grid%c2h, grid%msfuy,     &
                                grid%u_bxs, grid%u_bxe, grid%u_bys, grid%u_bye,  &
                                grid%u_btxs,grid%u_btxe,grid%u_btys,grid%u_btye, &
                                'u', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )

     CALL spec_bdy_final   ( grid%v_2, grid%muvs, grid%c1h, grid%c2h, grid%msfvx,     &
                                grid%v_bxs, grid%v_bxe, grid%v_bys, grid%v_bye,  &
                                grid%v_btxs,grid%v_btxe,grid%v_btys,grid%v_btye, &
                                'v', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )

     IF( config_flags%nested) THEN
       CALL spec_bdy_final   ( grid%w_2, grid%muts, grid%c1f, grid%c2f, grid%msfty, &
                                grid%w_bxs, grid%w_bxe, grid%w_bys, grid%w_bye,  &
                                grid%w_btxs,grid%w_btxe,grid%w_btys,grid%w_btye, &
                                'w', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )
     ENDIF

     CALL spec_bdy_final   ( grid%t_2, grid%muts, grid%c1h, grid%c2h, grid%msfty,&
                                grid%t_bxs, grid%t_bxe, grid%t_bys, grid%t_bye,  &
                                grid%t_btxs,grid%t_btxe,grid%t_btys,grid%t_btye, &
                                't', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )

     CALL spec_bdy_final   ( grid%ph_2, grid%muts, grid%c1f, grid%c2f, grid%msfty,   &
                                grid%ph_bxs, grid%ph_bxe, grid%ph_bys, grid%ph_bye,  &
                                grid%ph_btxs,grid%ph_btxe,grid%ph_btys,grid%ph_btye, &
                                'h', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )

     CALL spec_bdy_final   ( grid%mu_2, grid%muts, grid%c1h, grid%c2h, grid%msfty,   &
                                grid%mu_bxs, grid%mu_bxe, grid%mu_bys, grid%mu_bye,  &
                                grid%mu_btxs,grid%mu_btxe,grid%mu_btys,grid%mu_btye, &
                                'm', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, 1,  1,    & ! domain dims
                                ims,ime, jms,jme, 1,  1,    & ! memory dims
                                ips,ipe, jps,jpe, 1,  1,    & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                1  , 1                    )

     moisture_loop_bdy_3 : DO im = PARAM_FIRST_SCALAR , num_3d_m

     IF ( im .EQ. P_QV .OR. config_flags%nested .OR. &
             ( config_flags%specified .AND. config_flags%have_bcs_moist ) ) THEN
        CALL spec_bdy_final   ( moist(ims,kms,jms,im), grid%muts,                &
                                grid%c1h, grid%c2h, grid%msfty,                  &
                                moist_bxs(jms,kms,1,im),moist_bxe(jms,kms,1,im), &
                                moist_bys(ims,kms,1,im),moist_bye(ims,kms,1,im), &
                                moist_btxs(jms,kms,1,im),moist_btxe(jms,kms,1,im), &
                                moist_btys(ims,kms,1,im),moist_btye(ims,kms,1,im), &
                                't', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )
     ENDIF

     END DO moisture_loop_bdy_3

#if (WRF_CHEM == 1)
     IF (num_3d_c >= PARAM_FIRST_SCALAR)  THEN
         chem_species_bdy_loop_3 : DO ic = PARAM_FIRST_SCALAR , num_3d_c

     IF( ( config_flags%nested ) ) THEN
        CALL spec_bdy_final   ( chem(ims,kms,jms,ic), grid%muts,               &
                                grid%c1h, grid%c2h, grid%msfty,                &
                                chem_bxs(jms,kms,1,ic),chem_bxe(jms,kms,1,ic), &
                                chem_bys(ims,kms,1,ic),chem_bye(ims,kms,1,ic), &
                                chem_btxs(jms,kms,1,ic),chem_btxe(jms,kms,1,ic), &
                                chem_btys(ims,kms,1,ic),chem_btye(ims,kms,1,ic), &
                                't', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )
     ENDIF

         END DO chem_species_bdy_loop_3
     ENDIF
#endif

     tracer_species_bdy_loop_3 : DO im = PARAM_FIRST_SCALAR , num_tracer

     IF( ( config_flags%nested ) ) THEN
        CALL spec_bdy_final   ( tracer(ims,kms,jms,im), grid%muts,                 &
                                grid%c1h, grid%c2h, grid%msfty,                    &
                                tracer_bxs(jms,kms,1,im),tracer_bxe(jms,kms,1,im), &
                                tracer_bys(ims,kms,1,im),tracer_bye(ims,kms,1,im), &
                                tracer_btxs(jms,kms,1,im),tracer_btxe(jms,kms,1,im), &
                                tracer_btys(ims,kms,1,im),tracer_btye(ims,kms,1,im), &
                                't', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )
     ENDIF

     END DO tracer_species_bdy_loop_3

     scalar_species_bdy_loop_3 : DO is = PARAM_FIRST_SCALAR , num_3d_s

     IF( ( config_flags%nested ) ) THEN
        CALL spec_bdy_final   ( scalar(ims,kms,jms,is), grid%muts,                 &
                                grid%c1h, grid%c2h, grid%msfty,                    &
                                scalar_bxs(jms,kms,1,is),scalar_bxe(jms,kms,1,is), &
                                scalar_bys(ims,kms,1,is),scalar_bye(ims,kms,1,is), &
                                scalar_btxs(jms,kms,1,is),scalar_btxe(jms,kms,1,is), &
                                scalar_btys(ims,kms,1,is),scalar_btye(ims,kms,1,is), &
                                't', config_flags,                               &
                                config_flags%spec_bdy_width, grid%spec_zone,     &
                                grid%dtbc,                                       &
                                ids,ide, jds,jde, kds,kde,  & ! domain dims
                                ims,ime, jms,jme, kms,kme,  & ! memory dims
                                ips,ipe, jps,jpe, kps,kpe,  & ! patch  dims
                                grid%i_start(ij), grid%i_end(ij),       &
                                grid%j_start(ij), grid%j_end(ij),       &
                                k_start    , k_end                     )
     ENDIF

     END DO scalar_species_bdy_loop_3

   END DO tile_bc_loop_3
   !$OMP END PARALLEL DO

   ENDIF

! reset surface w for consistency

#ifdef DM_PARALLEL
#  include "HALO_EM_C.inc"
#  include "PERIOD_BDY_EM_E.inc"
#endif

   CALL wrf_debug ( 10 , ' call set_w_surface' )
   fill_w_flag = .false.

   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij )
   DO ij = 1 , grid%num_tiles
      CALL set_w_surface( config_flags, grid%znw, fill_w_flag,              &
                           grid%w_2, grid%ht,  grid%u_2, grid%v_2,          &
                           grid%cf1, grid%cf2, grid%cf3, grid%rdx, grid%rdy,&
                           grid%msftx, grid%msfty,                          &
                           ids, ide, jds, jde, kds, kde,                    &
                           ims, ime, jms, jme, kms, kme,                    &
                           grid%i_start(ij), grid%i_end(ij),                &
                           grid%j_start(ij), grid%j_end(ij),                &
                           k_start, k_end                                   )
!                          its, ite, jts, jte, k_start, min(k_end,kde-1),   &

   END DO
   !$OMP END PARALLEL DO

#ifdef CORDEXDIAG
#ifdef CDXWRF
#if CDXWRF>=4
! Getting some variables for the Water budget
   IF (config_flags%output_wb == 1 .AND. curr_secs2 > 0.) THEN
     !!i2 = (ime+ims)/2
     !!j2 = (jme+jms)/2
     ! Avoiding floating point exceptions when compiling in debug mode

     ! Inter-time step tendency (only for the existent species!!)
     grid%qvttend = (moist(:,:,:,P_QV) - moist_old(:,:,:,P_QV))/REAL(model_config_rec%dt(grid%id))
     grid%qcttend = (moist(:,:,:,P_QC) - moist_old(:,:,:,P_QC))/REAL(model_config_rec%dt(grid%id))
     grid%qrttend = (moist(:,:,:,P_QR) - moist_old(:,:,:,P_QR))/REAL(model_config_rec%dt(grid%id))
     IF (P_QS >= PARAM_FIRST_SCALAR) THEN
       grid%qsttend = (moist(:,:,:,P_QS) - moist_old(:,:,:,P_QS))/REAL(model_config_rec%dt(grid%id))
     ENDIF
     IF (P_QI >= PARAM_FIRST_SCALAR) THEN
       grid%qittend = (moist(:,:,:,P_QI) - moist_old(:,:,:,P_QI))/REAL(model_config_rec%dt(grid%id))
     ENDIF
     IF (P_QH >= PARAM_FIRST_SCALAR) THEN
       grid%qhttend = (moist(:,:,:,P_QH) - moist_old(:,:,:,P_QH))/REAL(model_config_rec%dt(grid%id))
     ENDIF
     IF (P_QG >= PARAM_FIRST_SCALAR) THEN
       grid%qgttend = (moist(:,:,:,P_QG) - moist_old(:,:,:,P_QG))/REAL(model_config_rec%dt(grid%id))
     ENDIF
   END IF
#endif
#endif
#endif

!-----------------------------------------------------------
!  After all of the RK steps, after the microphysics, after p-rho-phi,
!  after w, after filtering, we have data ready to use.
!-----------------------------------------------------------

#ifdef WRF_GPU_RESIDENT
  ! host copies current for after_all_rk_steps diagnostics (history/restart output pulls the full list: gpu_pull_for_output)
#ifdef WRF_SEG_TIMERS
   CALL seg_enter( 5 )
#endif
   IF ( IAND( wrf_gpu_xfer(), 8 ) /= 0 ) THEN
   ! lean (bit 524288): no host 3-D state needed after this step when its diagnostics run on the GPU (same test as
   ! diagnostics_driver); the next step pulls the state at H1 if it is not lean
   lean_h3 = IAND( wrf_gpu_xfer(), 524288 ) /= 0 .AND. IAND( wrf_gpu_xfer(), 65536 ) /= 0 .AND.               &
             config_flags%nwp_diagnostics == 1 .AND. config_flags%afwa_diag_opt == 1 .AND.                       &
             config_flags%mp_physics == THOMPSON .AND. .NOT. F_QNG .AND. grid%itimestep /= 1 .AND. gpu_prep_dev
   IF ( lean_h3 ) THEN
      CALL afwa_time_flags( grid, ld_after, ld_out, ld_first )
      lean_h3 = .NOT. ( ld_out .OR. ld_first )
   ENDIF
   IF ( .NOT. lean_h3 ) THEN
   IF ( IAND( wrf_gpu_xfer(), 2048 ) /= 0 ) THEN
#  include "gpu_stage_host_h3.inc"
   ELSE
#  include "gpu_upd_host_h3.inc"
   ENDIF
   gpu_h3_done = .TRUE.
   ELSE
   gpu_h3_done = .FALSE.
   ENDIF
   ! updraft helicity (cal_helicity in part2) is GPU-computed: the host diagnostics read/reset it and H1 pushes it back
!$acc update self(grid%uh) if(associated(grid%uh))
!$acc update self(grid%up_heli_max) if(associated(grid%up_heli_max))
   ! (also with staged pulls, bit 2048: before, those steps never pulled the GPU microphysics outputs - the host
   ! surface physics then saw no grid-scale precipitation)
   IF ( gpu_mp_dev ) THEN   ! microphysics ran on the GPU: outputs the host reads (H3 diagnostics, next H1 physics)
!$acc update self(grid%rainnc) if(associated(grid%rainnc))
!$acc update self(grid%rainncv) if(associated(grid%rainncv))
!$acc update self(grid%snownc) if(associated(grid%snownc))
!$acc update self(grid%snowncv) if(associated(grid%snowncv))
!$acc update self(grid%graupelnc) if(associated(grid%graupelnc))
!$acc update self(grid%graupelncv) if(associated(grid%graupelncv))
!$acc update self(grid%sr) if(associated(grid%sr))
!$acc update self(grid%re_cloud) if(associated(grid%re_cloud) .and. .not.wrf_gpu_ra_pullre)
!$acc update self(grid%re_ice) if(associated(grid%re_ice) .and. .not.wrf_gpu_ra_pullre)
!$acc update self(grid%re_snow) if(associated(grid%re_snow) .and. .not.wrf_gpu_ra_pullre)
   ENDIF
   ELSE
#  include "gpu_upd_host_pre_phys.inc"
   ENDIF
#ifdef WRF_SEG_TIMERS
   CALL seg_leave()
#endif
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 1 ) /= 0 ) THEN
#    include "gpu_sync_host_all.inc"
#    include "gpu_upd_host_i1_all.inc"
   ENDIF
#endif
#if defined(WRF_GPU) && !defined(WRF_GPU_RESIDENT)
   IF ( wrf_gpu_prefetch_mode() > 0 ) THEN
#  include "gpu_pf_host_pre_phys.inc"
   ENDIF
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'h_preH3', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 4 )
#endif
#ifdef WRF_GPU
  IF ( wrf_gpu_hostblocks() ) THEN ; wrf_gpu_on = .FALSE. ; CALL rsl_set_gpu_on( .FALSE. ) ; ENDIF
       CALL gpu_retile( grid, .TRUE., ids, ide, jds, jde, ips, ipe, jps, jpe )
#endif
#ifdef WRF_GPU_RESIDENT
#endif
  CALL after_all_rk_steps ( grid, config_flags,                  &
                            moist, chem, tracer, scalar,         &
                            th_phy, pi_phy, p_phy,               &
                            p8w, t8w, dz8w,                      &
                            REAL(curr_secs,8), curr_secs2,       &
                            diag_flag,                           &
                            ids,  ide,  jds,  jde,  kds,  kde,   &
                            ims,  ime,  jms,  jme,  kms,  kme,   &
                            ips,  ipe,  jps,  jpe,  kps,  kpe,   &
                            imsx, imex, jmsx, jmex, kmsx, kmex,  &
                            ipsx, ipex, jpsx, jpex, kpsx, kpex,  &
                            imsy, imey, jmsy, jmey, kmsy, kmey,  &
                            ipsy, ipey, jpsy, jpey, kpsy, kpey   )
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 3 ) == 3 ) THEN
#    include "gpu_sync_dev_all.inc"
#    include "gpu_upd_dev_i1_all.inc"
   ENDIF
#endif
#ifdef WRF_GPU
  wrf_gpu_on = .TRUE. ; CALL rsl_set_gpu_on( .TRUE. )
       CALL gpu_retile( grid, .FALSE., ids, ide, jds, jde, ips, ipe, jps, jpe )
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 1 )
#endif
#ifdef WRF_GPU_RESIDENT
#endif



#ifdef DM_PARALLEL
!-----------------------------------------------------------------------
! see above
!--------------------------------------------------------------
   CALL wrf_debug ( 200 , ' call HALO_RK_E' )
   IF      ( config_flags%h_mom_adv_order <= 4  .and. config_flags%h_sca_adv_order <= 4 ) THEN
#    include "HALO_EM_E_3.inc"
   ELSE IF ( config_flags%h_mom_adv_order <= 6 .and. config_flags%h_sca_adv_order <= 6 ) THEN
#    include "HALO_EM_E_5.inc"
   ELSE
     WRITE(wrf_err_message,*)'solve_em: invalid h_mom_adv_order or h_sca_adv_order = ', &
               config_flags%h_mom_adv_order, config_flags%h_sca_adv_order
     CALL wrf_error_fatal(TRIM(wrf_err_message))
   ENDIF
#endif

#ifdef DM_PARALLEL
   IF ( num_moist >= PARAM_FIRST_SCALAR  ) THEN
!-----------------------------------------------------------------------
! see above
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_MOIST' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_MOIST_E_3.inc"
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_MOIST_E_5.inc"
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
   IF ( num_chem >= PARAM_FIRST_SCALAR ) THEN
!-----------------------------------------------------------------------
! see above
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_CHEM' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_CHEM_E_3.inc"
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_CHEM_E_5.inc"
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
   IF ( num_tracer >= PARAM_FIRST_SCALAR ) THEN
!-----------------------------------------------------------------------
! see above
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_TRACER' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_TRACER_E_3.inc"
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_TRACER_E_5.inc"
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
   IF ( num_scalar >= PARAM_FIRST_SCALAR ) THEN
!-----------------------------------------------------------------------
! see above
!--------------------------------------------------------------
     CALL wrf_debug ( 200 , ' call HALO_RK_SCALAR' )
     IF      ( config_flags%h_sca_adv_order <= 4 ) THEN
#      include "HALO_EM_SCALAR_E_3.inc"
     ELSE IF ( config_flags%h_sca_adv_order <= 6 ) THEN
#      include "HALO_EM_SCALAR_E_5.inc"
     ELSE
       WRITE(wrf_err_message,*)'solve_em: invalid h_sca_adv_order = ',config_flags%h_sca_adv_order
       CALL wrf_error_fatal(TRIM(wrf_err_message))
     ENDIF
   ENDIF
#endif

   
!-----------------------------------------------------------------------
! firebrand spotting (passive Lagrangian particle transport, 
! tracks firebrand physics properties)
!-----------------------------------------------------------------------

   IF(config_flags%ifire == 2 .AND. &
       ! Check if spotting is on
       config_flags%fs_firebrand_gen_lim > 0 .AND. & 
       ! Check if this is the inner most grid
       config_flags%max_dom == grid%id) THEN 

#ifdef DM_PARALLEL
       CALL wrf_debug ( 200 , ' call HALO_FIREBRAND_SPOTTING' )
#      include "HALO_FIREBRAND_SPOTTING_5.inc"
#endif

       CALL wrf_debug ( 3 , 'solve: calling firebrand_spotting_em_driver...' )
       CALL firebrand_spotting_em_driver (  &
               cf            = config_flags,        &
               grid          = grid,                &
               fs_p_id       = grid%fs_p_id,        &
               fs_p_src      = grid%fs_p_src,      &
               fs_p_dt       = grid%fs_p_dt,        &
               fs_p_x        = grid%fs_p_x,         &
               fs_p_y        = grid%fs_p_y,         &
               fs_p_z        = grid%fs_p_z,         &
               fs_gen_inst   = grid%fs_gen_inst,    &
               fs_p_mass     = grid%fs_p_mass,      &  
               fs_p_diam     = grid%fs_p_diam,      & 
               fs_p_effd     = grid%fs_p_effd,      & 
               fs_p_temp     = grid%fs_p_temp,      & 
               fs_p_tvel     = grid%fs_p_tvel,      & 
               fs_last_gen_dt= grid%fs_last_gen_dt, &
               fs_gen_idmax  = grid%fs_gen_idmax,   &
               fs_fire_ROSdt = grid%fs_fire_ROSdt,  &
               fs_fire_area  = grid%fs_fire_area,   &
               fs_count_landed_all   = grid%fs_count_landed_all,   &
               fs_count_landed_hist  = grid%fs_count_landed_hist,  &
               fs_landing_mask       = grid%fs_landing_mask,       &
               fs_spotting_lkhd      = grid%fs_spotting_lkhd,      &
               fs_frac_landed        = grid%fs_frac_landed,        &
               fs_fuel_spotting_risk = grid%fs_fuel_spotting_risk, &
               fs_count_reset        = grid%fs_count_reset)

   ENDIF
! end of firebrand spotting
!-----------------------------------------------------------------------

!  Max values of CFL for adaptive time step scheme

   DEALLOCATE(max_vert_cfl_tmp)
   DEALLOCATE(max_horiz_cfl_tmp)

   CALL wrf_debug ( 200 , ' call end of solve_em' )

!  Are we about to read SST input from the wrflowinput file?  That data is saved
!  for use in fractional merging of external/coupled SST and input SST. 
   IF ( coupler_on )   grid%just_read_auxinput4 = Is_alarm_tstep(grid%domain_clock, grid%alarms(AUXINPUT4_ALARM))

!  Are we about to read the lateral boundary file?  This is a domain one action only.
   IF ( grid%id .EQ. 1 ) grid%just_read_boundary = Is_alarm_tstep(grid%domain_clock, grid%alarms(BOUNDARY_ALARM))

! Finish timers if compiled with -DBENCH.
#include "bench_solve_em_end.h"

#if (WRF_CMAQ == 1)
   if (firstime) then
      CALL nl_get_wrf_cmaq_option ( 1, wrf_cmaq_option )
      CALL nl_get_wrf_cmaq_freq ( 1, wrf_cmaq_freq )
      CALL nl_get_direct_sw_feedback ( .false., direct_sw_feedback )
      CALL nl_get_met_file_tstep ( 1, met_file_tstep )

      cmaq_wrf_feedback = direct_sw_feedback

      if (wrf_cmaq_option .gt. 0) then
         cmaq_nstep = ((grid%run_days * 24 + grid%run_hours) * 3600 + grid%run_minutes * 60 + grid%run_seconds) / &
                       (grid%time_step * WRF_CMAQ_FREQ)

         wrf_end_step = cmaq_nstep * WRF_CMAQ_FREQ - 1
      end if
   end if

   if (wrf_cmaq_option .gt. 0) then
      COUNTER = COUNTER + 1

      if ( .not. cmaq_wrf_feedback .and. firstime) then
         grid%prev_rainnc = 0.0
         grid%prev_rainc  = 0.0
      end if

      CMAQ_STEP = (mod(COUNTER, WRF_CMAQ_FREQ) .EQ. 0)

      if (CMAQ_STEP) then
         CALL aqprep (grid, config_flags, grid%t_phy, p_phy,       &
                      grid%rho, grid%z_at_w, dz8w, p8w, t8w,       &
                      model_config_rec%num_land_cat, 'V4.1.1',     &
                      wrf_cmaq_option, wrf_cmaq_freq,              &
                      ids, ide, jds, jde, kds, kde,                &
                      ims, ime, jms, jme, kms, kme,                &
                      ips, ipe, jps, jpe, kps, kpe,                &
                      moist(:,:,:,p_qv),                           &  !  optional
                      moist(:,:,:,p_qc),                           &  !  optional
                      moist(:,:,:,p_qr),                           &  !  optional
                      moist(:,:,:,p_qi),                           &  !  optional
                      moist(:,:,:,p_qs),                           &  !  optional
                      moist(:,:,:,p_qg)                            &  !  optional
                     )
         grid%prev_rainnc = grid%rainnc
         grid%prev_rainc  = grid%rainc
      end if

      if ((counter >= 1) .and. (CMAQ_STEP) .and. (wrf_cmaq_option .gt. 1)) then

         CALL CMAQ_DRIVER (cmaq_sdate, cmaq_stime, grid%time_step*WRF_CMAQ_FREQ,  &
                           twoway_jdate, twoway_jtime, .false.)

         if (direct_sw_feedback) then
            CALL FEEDBACK_READ (grid, twoway_jdate, twoway_jtime)
            feedback_is_ready = .true.
         end if

      end if

! call aqprep and cmaq one last time before the entire twoway model ends
      if (wrf_end_step == counter) then
         CALL aqprep (grid, config_flags, grid%t_phy, p_phy,       &
                      grid%rho, grid%z_at_w, dz8w, p8w, t8w,       &
                      model_config_rec%num_land_cat, 'V4.1.1',     &
                      wrf_cmaq_option, wrf_cmaq_freq,              &
                      ids, ide, jds, jde, kds, kde,                &
                      ims, ime, jms, jme, kms, kme,                &
                      ips, ipe, jps, jpe, kps, kpe,                &
                      moist(:,:,:,p_qv),                           &  !  optional
                      moist(:,:,:,p_qc),                           &  !  optional
                      moist(:,:,:,p_qr),                           &  !  optional
                      moist(:,:,:,p_qi),                           &  !  optional
                      moist(:,:,:,p_qs),                           &  !  optional
                      moist(:,:,:,p_qg)                            &  !  optional
                     )

         if (wrf_cmaq_option .gt. 1) then

            CALL CMAQ_DRIVER (cmaq_sdate, cmaq_stime, grid%time_step*WRF_CMAQ_FREQ, &
                              twoway_jdate, twoway_jtime, .true.)
         end if

      end if

   end if
   firstime = .false.
#endif

#ifdef WRF_GPU_FIELDTRACE
       CALL gpu_field_trace( grid, 'd_end_step' )
#endif
#ifdef WRF_GPU
!$acc wait
#endif
#ifdef WRF_GPU
   CALL gpu_ck( grid, 'i_end', rk_step, ids, ide, jds, jde, kds, kde, &
        ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
#endif
#ifdef WRF_GPU_RESIDENT
!$acc exit data delete(h_tendency, z_tendency)
#endif
#ifdef WRF_GPU_RESIDENT
   IF ( IAND( wrf_gpu_fullsync(), 7 ) == 7 ) THEN
#    include "gpu_sync_host_all.inc"
      gpu_fs_have_host = .TRUE.
   ENDIF
#endif
#ifdef WRF_SEG_TIMERS
   CALL seg_mark( 0 )
#endif
   RETURN

END SUBROUTINE solve_em

#ifdef WRF_GPU_FIELDTRACE
! GPU porting aid: report which allocated real state fields changed since the previous trace point.
SUBROUTINE gpu_field_trace( grid, tag )
   USE module_domain, ONLY : domain, fieldlist
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   CHARACTER(*), INTENT(IN) :: tag
   INTEGER, PARAMETER :: MAXF = 6000
   REAL(8), SAVE :: prev(MAXF)
   LOGICAL, SAVE :: have = .FALSE.
   CHARACTER(LEN=20), SAVE :: prevtag = 'start'
   TYPE(fieldlist), POINTER :: p
   INTEGER :: n, nch
   REAL(8) :: h
   CHARACTER(LEN=4000) :: line
   n = 0 ; nch = 0 ; line = ''
   p => grid%head_statevars
   DO WHILE ( ASSOCIATED(p) )
      h = -1.d300
      IF ( p%Type == 'r' ) THEN
         IF ( p%Ndim == 2 ) THEN
            IF ( ASSOCIATED(p%rfield_2d) ) THEN
               IF ( SIZE(p%rfield_2d) > 1 ) h = SUM(DBLE(p%rfield_2d)) + 1.000001d0*SUM(ABS(DBLE(p%rfield_2d)))
            ENDIF
         ELSE IF ( p%Ndim == 3 ) THEN
            IF ( ASSOCIATED(p%rfield_3d) ) THEN
               IF ( SIZE(p%rfield_3d) > 1 ) h = SUM(DBLE(p%rfield_3d)) + 1.000001d0*SUM(ABS(DBLE(p%rfield_3d)))
            ENDIF
         ELSE IF ( p%Ndim == 4 ) THEN
            IF ( ASSOCIATED(p%rfield_4d) ) THEN
               IF ( SIZE(p%rfield_4d) > 1 ) h = SUM(DBLE(p%rfield_4d)) + 1.000001d0*SUM(ABS(DBLE(p%rfield_4d)))
            ENDIF
         ENDIF
      ENDIF
      n = n + 1
      IF ( n <= MAXF .AND. h > -1.d299 ) THEN
         IF ( have .AND. h /= prev(n) ) THEN
            nch = nch + 1
            IF ( LEN_TRIM(line) < 3800 ) line = TRIM(line)//' '//TRIM(p%VarName)
         ENDIF
         prev(n) = h
      ENDIF
      p => p%next
   ENDDO
   IF ( have ) WRITE(0,'(A,A,A,A,A,I5,A,A)') 'GPUTRACE ', TRIM(prevtag), ' -> ', TRIM(tag), ' changed ', nch, ' :', TRIM(line)
   have = .TRUE. ; prevtag = tag
END SUBROUTINE gpu_field_trace
#endif
#ifdef WRF_GPU_RESIDENT
! Called from med_before_solve_io / med_last_solve_io: when any output alarm rings, make the host copies of every
! device-written grid array current (the per-block pulls in solve_em only cover what each host block reads).
SUBROUTINE gpu_pull_for_output( grid )
   USE module_domain, ONLY : domain
   USE module_utility
   USE module_streams, ONLY : MAX_WRF_ALARMS
   USE openacc, ONLY : acc_is_present
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   INTEGER :: ia, rc
   LOGICAL :: any_ring
   INTEGER, EXTERNAL :: wrf_gpu_xfer
   IF ( .NOT. ASSOCIATED(grid%u_2) ) RETURN
   IF ( .NOT. acc_is_present(grid%u_2) ) RETURN      ! before the first solve_em: host copies are the only copies
   any_ring = .FALSE.
   DO ia = 1, MAX_WRF_ALARMS
      IF ( grid%alarms_created(ia) ) THEN
         IF ( WRFU_AlarmIsRinging( grid%alarms(ia), rc=rc ) ) any_ring = .TRUE.
      ENDIF
   ENDDO
   IF ( .NOT. any_ring ) RETURN
#  include "gpu_upd_host_pre_phys.inc"
   IF ( IAND( wrf_gpu_xfer(), 32 ) /= 0 ) THEN    ! GPU Thompson: effective radii (pulled lazily otherwise)
!$acc update self(grid%re_cloud) if(associated(grid%re_cloud))
!$acc update self(grid%re_ice) if(associated(grid%re_ice))
!$acc update self(grid%re_snow) if(associated(grid%re_snow))
   ENDIF
   IF ( IAND( wrf_gpu_xfer(), 1024 ) /= 0 ) THEN  ! GPU MYJ PBL: its 3-D state for history/restart
!$acc update self(grid%tke_pbl) if(associated(grid%tke_pbl))
!$acc update self(grid%el_pbl) if(associated(grid%el_pbl))
!$acc update self(grid%exch_h) if(associated(grid%exch_h))
   ENDIF
   IF ( IAND( wrf_gpu_xfer(), 1024 ) /= 0 .AND. ASSOCIATED( grid%dtaux3d ) ) THEN   ! GPU orographic GWD diagnostics
      IF ( acc_is_present( grid%dtaux3d ) ) THEN
!$acc update self(grid%dtaux3d,grid%dtauy3d)
      ENDIF
   ENDIF
   IF ( IAND( wrf_gpu_xfer(), 22 ) == 22 ) THEN   ! GPU-owned physics tendencies (bit 16)
!$acc update self(grid%rthraten) if(associated(grid%rthraten))
!$acc update self(grid%rqcblten) if(associated(grid%rqcblten))
!$acc update self(grid%rqiblten) if(associated(grid%rqiblten))
!$acc update self(grid%rqvblten) if(associated(grid%rqvblten))
!$acc update self(grid%rthblten) if(associated(grid%rthblten))
!$acc update self(grid%rublten) if(associated(grid%rublten))
!$acc update self(grid%rvblten) if(associated(grid%rvblten))
!$acc update self(grid%rqccuten) if(associated(grid%rqccuten))
!$acc update self(grid%rqicuten) if(associated(grid%rqicuten))
!$acc update self(grid%rqvcuten) if(associated(grid%rqvcuten))
!$acc update self(grid%rthcuten) if(associated(grid%rthcuten))
!$acc update self(grid%rucuten) if(associated(grid%rucuten))
!$acc update self(grid%rvcuten) if(associated(grid%rvcuten))
   ENDIF
!$acc wait
END SUBROUTINE gpu_pull_for_output
#endif
#ifdef WRF_GPU
! WRF_GPU_CK=N (diagnostic): device-side domain sums of the state at fixed points of solve_em for the first N steps.
! Same kernels in managed and residency builds -> the first checkpoint where the two differ locates a missing transfer.
SUBROUTINE gpu_ck( grid, tag, rk, ids, ide, jds, jde, kds, kde, ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe )
   USE module_domain, ONLY : domain
   USE module_state_description, ONLY : P_QV
   USE module_wrf_error, ONLY : wrf_gpu_on
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   CHARACTER(*), INTENT(IN) :: tag
   INTEGER, INTENT(IN) :: rk, ids, ide, jds, jde, kds, kde, ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe, kps, kpe
   INTEGER, SAVE :: nck = -1
   CHARACTER(LEN=8) :: v
   CHARACTER(LEN=400) :: msg
   INTEGER :: st, ie, je, ke
   REAL(8) :: r(10)
   REAL(8), EXTERNAL :: gpu_ck3, gpu_ck2
   LOGICAL :: on
   IF ( nck < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_CK', v, STATUS=st )
      nck = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) nck
      IF ( st /= 0 ) nck = 0
   ENDIF
   IF ( grid%itimestep > nck ) RETURN
   ie = MIN(ipe, ide-1) ; je = MIN(jpe, jde-1) ; ke = MIN(kpe, kde-1)
   on = wrf_gpu_on ; wrf_gpu_on = .TRUE.
   r(1)  = gpu_ck2( grid%mu_2, ims, ime, jms, jme, ips, ie, jps, je )
   r(2)  = gpu_ck2( grid%muts, ims, ime, jms, jme, ips, ie, jps, je )
   r(3)  = gpu_ck3( grid%t_2,  ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   r(4)  = gpu_ck3( grid%ph_2, ims, ime, kms, kme, jms, jme, ips, ie, kps, kpe, jps, je )
   r(5)  = gpu_ck3( grid%u_2,  ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   r(6)  = gpu_ck3( grid%v_2,  ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   r(7)  = gpu_ck3( grid%w_2,  ims, ime, kms, kme, jms, jme, ips, ie, kps, kpe, jps, je )
   r(8)  = gpu_ck3( grid%p,    ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   r(9)  = gpu_ck3( grid%al,   ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   r(10) = gpu_ck3( grid%moist(ims,kms,jms,P_QV), ims, ime, kms, kme, jms, jme, ips, ie, kps, ke, jps, je )
   wrf_gpu_on = on
   WRITE(msg,'(A,I5,I4,1X,A8,10ES24.16)') 'GPUCK ', grid%itimestep, rk, tag, r
   CALL wrf_message( msg )
END SUBROUTINE gpu_ck

SUBROUTINE gpu_ckt( grid, tag, rk, ru, rv, rw, ph, t, mu, ims, ime, jms, jme, kms, kme, is, ie, js, je, ks, ke )
   USE module_domain, ONLY : domain
   USE module_wrf_error, ONLY : wrf_gpu_on
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   CHARACTER(*), INTENT(IN) :: tag
   INTEGER, INTENT(IN) :: rk, ims, ime, jms, jme, kms, kme, is, ie, js, je, ks, ke
   REAL, INTENT(IN) :: ru(ims:ime,kms:kme,jms:jme), rv(ims:ime,kms:kme,jms:jme), rw(ims:ime,kms:kme,jms:jme), &
                       ph(ims:ime,kms:kme,jms:jme), t(ims:ime,kms:kme,jms:jme), mu(ims:ime,jms:jme)
   INTEGER, SAVE :: nck = -1
   CHARACTER(LEN=8) :: v
   CHARACTER(LEN=300) :: msg
   INTEGER :: st
   REAL(8) :: r(6)
   REAL(8), EXTERNAL :: gpu_ck3, gpu_ck2
   LOGICAL :: on
   IF ( nck < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_CK', v, STATUS=st )
      nck = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) nck
      IF ( st /= 0 ) nck = 0
   ENDIF
   IF ( grid%itimestep > nck ) RETURN
   on = wrf_gpu_on ; wrf_gpu_on = .TRUE.
   r(1) = gpu_ck3( ru, ims, ime, kms, kme, jms, jme, is, ie, ks, ke-1, js, je )
   r(2) = gpu_ck3( rv, ims, ime, kms, kme, jms, jme, is, ie, ks, ke-1, js, je )
   r(3) = gpu_ck3( rw, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je )
   r(4) = gpu_ck3( ph, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je )
   r(5) = gpu_ck3( t,  ims, ime, kms, kme, jms, jme, is, ie, ks, ke-1, js, je )
   r(6) = gpu_ck2( mu, ims, ime, jms, jme, is, ie, js, je )
   wrf_gpu_on = on
   WRITE(msg,'(A,I5,I4,1X,A8,6ES24.16)') 'GPUCKT ', grid%itimestep, rk, tag, r
   CALL wrf_message( msg )
END SUBROUTINE gpu_ckt

SUBROUTINE gpu_ckv( grid, name, nd, a, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je )
   USE module_domain, ONLY : domain
   USE module_wrf_error, ONLY : wrf_gpu_on
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   CHARACTER(*), INTENT(IN) :: name
   INTEGER, INTENT(IN) :: nd, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je
   REAL, INTENT(IN) :: a(ims:ime, kms:kme, jms:jme)
   INTEGER, SAVE :: nck = -1
   CHARACTER(LEN=8) :: v
   CHARACTER(LEN=200) :: msg
   INTEGER :: st
   REAL(8) :: r
   REAL(8), EXTERNAL :: gpu_ck3
   LOGICAL :: on
   IF ( nck < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_CK', v, STATUS=st )
      nck = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) nck
      IF ( st /= 0 ) nck = 0
   ENDIF
   IF ( nck <= 0 ) RETURN
   on = wrf_gpu_on ; wrf_gpu_on = .TRUE.
   r = gpu_ck3( a, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je )
   wrf_gpu_on = on
   WRITE(msg,'(A,I2,1X,A,1X,ES24.16)') 'GPUCKV ', nd, TRIM(name), r
   CALL wrf_message( msg )
END SUBROUTINE gpu_ckv

REAL(8) FUNCTION gpu_ck3( a, ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je )
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ims, ime, kms, kme, jms, jme, is, ie, ks, ke, js, je
   REAL, INTENT(IN) :: a(ims:ime, kms:kme, jms:jme)
   REAL(8) :: s
   INTEGER :: i, k, j
   s = 0.d0
!$acc parallel loop collapse(3) reduction(+:s)
   DO j = js, je
   DO k = ks, ke
   DO i = is, ie
      s = s + DBLE(a(i,k,j))
   ENDDO
   ENDDO
   ENDDO
   gpu_ck3 = s
END FUNCTION gpu_ck3

REAL(8) FUNCTION gpu_ck2( a, ims, ime, jms, jme, is, ie, js, je )
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: ims, ime, jms, jme, is, ie, js, je
   REAL, INTENT(IN) :: a(ims:ime, jms:jme)
   REAL(8) :: s
   INTEGER :: i, j
   s = 0.d0
!$acc parallel loop collapse(2) reduction(+:s)
   DO j = js, je
   DO i = is, ie
      s = s + DBLE(a(i,j))
   ENDDO
   ENDDO
   gpu_ck2 = s
END FUNCTION gpu_ck2
#endif
#ifdef WRF_GPU
! ---------------------------------------------------------------------------------------------------------------
! GPU (managed memory) placement advice. WRF_GPU_ADVISE=0 none (default), 1 cuMemAdvise SET_READ_MOSTLY,
! 2 SET_PREFERRED_LOCATION=GPU + SET_ACCESSED_BY=CPU. Applied to every grid state array (once) and to the solve_em
! i1 temporaries (every call: they are re-allocated per step). libcuda is resolved with dlopen at run time.
! ---------------------------------------------------------------------------------------------------------------
INTEGER FUNCTION wrf_gpu_advise_mode()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_ADVISE', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   wrf_gpu_advise_mode = mode
END FUNCTION wrf_gpu_advise_mode

SUBROUTINE wrf_gpu_advise_addr( addr, nbytes )
   USE ISO_C_BINDING
   USE openacc
   IMPLICIT NONE
   INTEGER(8), INTENT(IN) :: addr, nbytes
   INTERFACE
      TYPE(C_PTR) FUNCTION dlopen( name, flags ) BIND(C, NAME='dlopen')
         IMPORT ; CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name ; INTEGER(C_INT), VALUE :: flags
      END FUNCTION
      TYPE(C_FUNPTR) FUNCTION dlsym( h, name ) BIND(C, NAME='dlsym')
         IMPORT ; TYPE(C_PTR), VALUE :: h ; CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
      END FUNCTION
   END INTERFACE
   ABSTRACT INTERFACE
      INTEGER(C_INT) FUNCTION advise_t( dptr, cnt, advice, dev ) BIND(C)
         IMPORT ; INTEGER(C_LONG_LONG), VALUE :: dptr ; INTEGER(C_SIZE_T), VALUE :: cnt
         INTEGER(C_INT), VALUE :: advice, dev
      END FUNCTION
      INTEGER(C_INT) FUNCTION getdev_t( dev ) BIND(C)
         IMPORT ; INTEGER(C_INT) :: dev
      END FUNCTION
   END INTERFACE
   PROCEDURE(advise_t), POINTER, SAVE :: cu_advise => NULL()
   PROCEDURE(getdev_t), POINTER, SAVE :: cu_getdev => NULL()
   LOGICAL, SAVE :: init = .FALSE.
   INTEGER(C_INT), SAVE :: dev = 0
   INTEGER, SAVE :: nok = 0, nbad = 0, nrep = 0
   TYPE(C_PTR) :: h
   INTEGER(C_INT) :: rc
   INTEGER :: mode
   INTEGER, EXTERNAL :: wrf_gpu_advise_mode
   mode = wrf_gpu_advise_mode()
   IF ( mode == 0 .OR. nbytes <= 0 ) RETURN
   IF ( .NOT. init ) THEN
      init = .TRUE.
      CALL acc_init( acc_device_nvidia )
      h = dlopen( 'libcuda.so.1'//C_NULL_CHAR, 2 )   ! RTLD_NOW
      IF ( C_ASSOCIATED(h) ) THEN
         CALL C_F_PROCPOINTER( dlsym( h, 'cuMemAdvise'//C_NULL_CHAR ), cu_advise )
         CALL C_F_PROCPOINTER( dlsym( h, 'cuCtxGetDevice'//C_NULL_CHAR ), cu_getdev )
         IF ( ASSOCIATED(cu_getdev) ) rc = cu_getdev( dev )
      ENDIF
      WRITE(0,'(A,I2,A,L2,A,I3)') 'WRF_GPU_ADVISE mode', mode, ' cuMemAdvise found', ASSOCIATED(cu_advise), ' dev', dev
   ENDIF
   IF ( .NOT. ASSOCIATED(cu_advise) ) RETURN
   IF ( mode == 1 ) THEN
      rc = cu_advise( INT(addr,C_LONG_LONG), INT(nbytes,C_SIZE_T), 1_C_INT, dev )          ! SET_READ_MOSTLY
   ELSE
      rc = cu_advise( INT(addr,C_LONG_LONG), INT(nbytes,C_SIZE_T), 3_C_INT, dev )          ! SET_PREFERRED_LOCATION
      IF ( rc == 0 ) rc = cu_advise( INT(addr,C_LONG_LONG), INT(nbytes,C_SIZE_T), 5_C_INT, -1_C_INT )  ! ACCESSED_BY CPU
   ENDIF
   IF ( rc == 0 ) THEN ; nok = nok + 1 ; ELSE ; nbad = nbad + 1 ; ENDIF
   IF ( nok + nbad == 200 .OR. (nok + nbad > 200 .AND. nrep == 0 .AND. nbad > 0) ) THEN
      nrep = nrep + 1
      WRITE(0,'(A,I8,A,I8,A,I6)') 'WRF_GPU_ADVISE calls ok', nok, ' failed', nbad, ' last rc', rc
   ENDIF
END SUBROUTINE wrf_gpu_advise_addr

! WRF_GPU_PIN=1 (residency): page-lock (cuMemHostRegister) the host copies of the grid state arrays and the
! persistent i1 temporaries once, so the per-block update self/device transfers can DMA directly instead of staging
! through pageable memory. All their page ranges are collected, merged and registered (wrf_gpu_pin_flush).
INTEGER FUNCTION wrf_gpu_pin_mode()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_PIN', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   wrf_gpu_pin_mode = mode
END FUNCTION wrf_gpu_pin_mode

MODULE wrf_gpu_pin_list
   ! page ranges of every host array that crosses PCIe; merged and registered once (wrf_gpu_pin_flush)
   INTEGER, PARAMETER :: MAXR = 4000
   INTEGER(8), SAVE :: r0(MAXR), r1(MAXR)
   INTEGER, SAVE :: nr = 0
END MODULE wrf_gpu_pin_list

SUBROUTINE wrf_gpu_pin_addr( addr, nbytes, nok, nfail, tot )
   ! collect only: whole-page range of [addr, addr+nbytes)
   USE wrf_gpu_pin_list
   IMPLICIT NONE
   INTEGER(8), INTENT(IN) :: addr, nbytes
   INTEGER, INTENT(INOUT) :: nok, nfail
   INTEGER(8), INTENT(INOUT) :: tot
   IF ( nbytes <= 0 ) RETURN
   IF ( nr >= MAXR ) THEN ; nfail = nfail + 1 ; RETURN ; ENDIF
   nr = nr + 1
   r0(nr) = ( addr / 4096_8 ) * 4096_8
   r1(nr) = ( ( addr + nbytes + 4095_8 ) / 4096_8 ) * 4096_8
   nok = nok + 1 ; tot = tot + nbytes
END SUBROUTINE wrf_gpu_pin_addr

SUBROUTINE wrf_gpu_pin_flush()
   ! sort the collected ranges, merge overlapping/adjacent ones (arrays sharing a page end up in one interval, so no
   ! copied array is ever partly registered) and cuMemHostRegister each merged interval
   USE wrf_gpu_pin_list
   USE ISO_C_BINDING
   IMPLICIT NONE
   INTERFACE
      TYPE(C_PTR) FUNCTION dlopen( name, flags ) BIND(C, NAME='dlopen')
         IMPORT :: C_PTR, C_CHAR, C_INT
         CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
         INTEGER(C_INT), VALUE :: flags
      END FUNCTION dlopen
      TYPE(C_FUNPTR) FUNCTION dlsym( h, name ) BIND(C, NAME='dlsym')
         IMPORT :: C_PTR, C_FUNPTR, C_CHAR
         TYPE(C_PTR), VALUE :: h
         CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
      END FUNCTION dlsym
   END INTERFACE
   ABSTRACT INTERFACE
      INTEGER(C_INT) FUNCTION reg_t( p, n, flags ) BIND(C)
         IMPORT :: C_INT, C_SIZE_T, C_LONG_LONG
         INTEGER(C_LONG_LONG), VALUE :: p
         INTEGER(C_SIZE_T), VALUE :: n
         INTEGER(C_INT), VALUE :: flags
      END FUNCTION reg_t
   END INTERFACE
   PROCEDURE(reg_t), POINTER :: cu_reg
   TYPE(C_PTR) :: h
   INTEGER :: i, j, nm, nok, nbad
   INTEGER(8) :: t0, t1, tot
   INTEGER(C_INT) :: rc
   cu_reg => NULL()
   h = dlopen( 'libcuda.so.1'//C_NULL_CHAR, 2 )
   IF ( C_ASSOCIATED(h) ) CALL C_F_PROCPOINTER( dlsym( h, 'cuMemHostRegister_v2'//C_NULL_CHAR ), cu_reg )
   IF ( .NOT. ASSOCIATED(cu_reg) .OR. nr == 0 ) RETURN
   DO i = 2, nr                                   ! insertion sort by start
      t0 = r0(i) ; t1 = r1(i) ; j = i - 1
      DO WHILE ( j >= 1 )
         IF ( r0(j) <= t0 ) EXIT
         r0(j+1) = r0(j) ; r1(j+1) = r1(j) ; j = j - 1
      ENDDO
      r0(j+1) = t0 ; r1(j+1) = t1
   ENDDO
   nm = 1                                         ! merge in place
   DO i = 2, nr
      IF ( r0(i) <= r1(nm) ) THEN
         r1(nm) = MAX( r1(nm), r1(i) )
      ELSE
         nm = nm + 1 ; r0(nm) = r0(i) ; r1(nm) = r1(i)
      ENDIF
   ENDDO
   nok = 0 ; nbad = 0 ; tot = 0
   DO i = 1, nm
      rc = cu_reg( INT(r0(i),C_LONG_LONG), INT(r1(i)-r0(i),C_SIZE_T), 0_C_INT )
      IF ( rc == 0 ) THEN ; nok = nok + 1 ; tot = tot + (r1(i)-r0(i)) ; ELSE ; nbad = nbad + 1 ; ENDIF
   ENDDO
   WRITE(0,'(A,I6,A,I6,A,I6,A,F9.1,A)') 'WRF_GPU_PIN: ', nr, ' arrays -> ', nm, ' merged intervals, ', nbad, &
        ' failed, ', DBLE(tot)/1.d6, ' MB registered'
   nr = 0
END SUBROUTINE wrf_gpu_pin_flush

SUBROUTINE wrf_gpu_pin_grid( grid )
   USE module_domain, ONLY : domain, fieldlist
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   TYPE(fieldlist), POINTER :: p
   INTEGER :: nok, nfail
   INTEGER(8) :: tot
   nok = 0 ; nfail = 0 ; tot = 0
   p => grid%head_statevars
   DO WHILE ( ASSOCIATED(p) )
      IF ( p%Type == 'r' ) THEN
         IF ( p%Ndim == 2 ) THEN
            IF ( ASSOCIATED(p%rfield_2d) ) THEN
               IF ( SIZE(p%rfield_2d) > 1 ) CALL wrf_gpu_pin_addr( LOC(p%rfield_2d(LBOUND(p%rfield_2d,1),LBOUND(p%rfield_2d,2))), &
                                            INT(SIZE(p%rfield_2d),8)*4_8, nok, nfail, tot )
            ENDIF
         ELSE IF ( p%Ndim == 3 ) THEN
            IF ( ASSOCIATED(p%rfield_3d) ) THEN
               IF ( SIZE(p%rfield_3d) > 1 ) CALL wrf_gpu_pin_addr( LOC(p%rfield_3d(LBOUND(p%rfield_3d,1),LBOUND(p%rfield_3d,2), &
                                            LBOUND(p%rfield_3d,3))), INT(SIZE(p%rfield_3d),8)*4_8, nok, nfail, tot )
            ENDIF
         ELSE IF ( p%Ndim == 4 ) THEN
            IF ( ASSOCIATED(p%rfield_4d) ) THEN
               IF ( SIZE(p%rfield_4d) > 1 ) CALL wrf_gpu_pin_addr( LOC(p%rfield_4d(LBOUND(p%rfield_4d,1),LBOUND(p%rfield_4d,2), &
                                            LBOUND(p%rfield_4d,3),LBOUND(p%rfield_4d,4))), INT(SIZE(p%rfield_4d),8)*4_8, nok, nfail, tot )
            ENDIF
         ENDIF
      ENDIF
      p => p%next
   ENDDO
   WRITE(0,'(A,I6,A,I6,A,F9.1,A)') 'WRF_GPU_PIN grid: ', nok, ' arrays registered, ', nfail, ' skipped/failed, ', DBLE(tot)/1.d6, ' MB'
END SUBROUTINE wrf_gpu_pin_grid

SUBROUTINE wrf_gpu_advise_grid( grid )
   USE module_domain, ONLY : domain, fieldlist
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   TYPE(fieldlist), POINTER :: p
   INTEGER, EXTERNAL :: wrf_gpu_advise_mode
   INTEGER :: n
   IF ( wrf_gpu_advise_mode() == 0 ) RETURN
   n = 0
   p => grid%head_statevars
   DO WHILE ( ASSOCIATED(p) )
      IF ( p%Type == 'r' ) THEN
         IF ( p%Ndim == 2 ) THEN
            IF ( ASSOCIATED(p%rfield_2d) ) THEN
               IF ( SIZE(p%rfield_2d) > 1 ) THEN
                  CALL wrf_gpu_advise_addr( LOC(p%rfield_2d(LBOUND(p%rfield_2d,1),LBOUND(p%rfield_2d,2))), &
                                            INT(SIZE(p%rfield_2d),8)*4_8 ) ; n = n + 1
               ENDIF
            ENDIF
         ELSE IF ( p%Ndim == 3 ) THEN
            IF ( ASSOCIATED(p%rfield_3d) ) THEN
               IF ( SIZE(p%rfield_3d) > 1 ) THEN
                  CALL wrf_gpu_advise_addr( LOC(p%rfield_3d(LBOUND(p%rfield_3d,1),LBOUND(p%rfield_3d,2),LBOUND(p%rfield_3d,3))), &
                                            INT(SIZE(p%rfield_3d),8)*4_8 ) ; n = n + 1
               ENDIF
            ENDIF
         ELSE IF ( p%Ndim == 4 ) THEN
            IF ( ASSOCIATED(p%rfield_4d) ) THEN
               IF ( SIZE(p%rfield_4d) > 1 ) THEN
                  CALL wrf_gpu_advise_addr( LOC(p%rfield_4d(LBOUND(p%rfield_4d,1),LBOUND(p%rfield_4d,2), &
                                            LBOUND(p%rfield_4d,3),LBOUND(p%rfield_4d,4))), INT(SIZE(p%rfield_4d),8)*4_8 ) ; n = n + 1
               ENDIF
            ENDIF
         ENDIF
      ENDIF
      p => p%next
   ENDDO
   WRITE(0,'(A,I6,A)') 'WRF_GPU_ADVISE grid: ', n, ' real state arrays advised'
END SUBROUTINE wrf_gpu_advise_grid

! ---------------------------------------------------------------------------------------------------------------
! Managed-memory bulk prefetch around the host blocks (WRF_GPU_PREFETCH=1): turns demand page faults for the
! traced field lists into cuMemPrefetchAsync copies. Unlisted data still migrates on demand (correctness unchanged).
! ---------------------------------------------------------------------------------------------------------------
INTEGER FUNCTION wrf_gpu_prefetch_mode()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_PREFETCH', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   wrf_gpu_prefetch_mode = mode
END FUNCTION wrf_gpu_prefetch_mode

MODULE wrf_gpu_pf_ctl
   USE ISO_C_BINDING
   ABSTRACT INTERFACE
      INTEGER(C_INT) FUNCTION prefetch_t( dptr, cnt, dev, stream ) BIND(C)
         IMPORT ; INTEGER(C_LONG_LONG), VALUE :: dptr ; INTEGER(C_SIZE_T), VALUE :: cnt
         INTEGER(C_INT), VALUE :: dev ; TYPE(C_PTR), VALUE :: stream
      END FUNCTION
      INTEGER(C_INT) FUNCTION sync_t() BIND(C)
         IMPORT
      END FUNCTION
      INTEGER(C_INT) FUNCTION getdev_t( dev ) BIND(C)
         IMPORT ; INTEGER(C_INT) :: dev
      END FUNCTION
   END INTERFACE
   PROCEDURE(prefetch_t), POINTER :: cu_prefetch => NULL()
   PROCEDURE(sync_t), POINTER :: cu_sync => NULL()
   LOGICAL :: pf_init = .FALSE.
   INTEGER(C_INT) :: pf_dev = 0
   INTEGER :: pf_ok = 0, pf_bad = 0, pf_rep = 0
CONTAINS
   SUBROUTINE pf_setup()
      USE openacc
      INTERFACE
         TYPE(C_PTR) FUNCTION dlopen( name, flags ) BIND(C, NAME='dlopen')
            IMPORT ; CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name ; INTEGER(C_INT), VALUE :: flags
         END FUNCTION
         TYPE(C_FUNPTR) FUNCTION dlsym( h, name ) BIND(C, NAME='dlsym')
            IMPORT ; TYPE(C_PTR), VALUE :: h ; CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
         END FUNCTION
      END INTERFACE
      PROCEDURE(getdev_t), POINTER :: cu_getdev
      TYPE(C_PTR) :: h
      INTEGER(C_INT) :: rc
      pf_init = .TRUE. ; cu_getdev => NULL()
      CALL acc_init( acc_device_nvidia )
      h = dlopen( 'libcuda.so.1'//C_NULL_CHAR, 2 )
      IF ( C_ASSOCIATED(h) ) THEN
         CALL C_F_PROCPOINTER( dlsym( h, 'cuMemPrefetchAsync'//C_NULL_CHAR ), cu_prefetch )
         CALL C_F_PROCPOINTER( dlsym( h, 'cuCtxSynchronize'//C_NULL_CHAR ), cu_sync )
         CALL C_F_PROCPOINTER( dlsym( h, 'cuCtxGetDevice'//C_NULL_CHAR ), cu_getdev )
         IF ( ASSOCIATED(cu_getdev) ) rc = cu_getdev( pf_dev )
      ENDIF
      WRITE(0,'(A,L2,A,I3)') 'WRF_GPU_PREFETCH cuMemPrefetchAsync found', ASSOCIATED(cu_prefetch), ' dev', pf_dev
   END SUBROUTINE pf_setup
END MODULE wrf_gpu_pf_ctl

SUBROUTINE wrf_gpu_prefetch_addr( addr, nbytes, todev )
   USE wrf_gpu_pf_ctl
   IMPLICIT NONE
   INTEGER(8), INTENT(IN) :: addr, nbytes
   INTEGER, INTENT(IN) :: todev
   INTEGER(C_INT) :: rc, dst
   IF ( nbytes <= 4 ) RETURN
   IF ( .NOT. pf_init ) CALL pf_setup()
   IF ( .NOT. ASSOCIATED(cu_prefetch) ) RETURN
   dst = -1_C_INT                      ! CU_DEVICE_CPU
   IF ( todev /= 0 ) dst = pf_dev
   rc = cu_prefetch( INT(addr,C_LONG_LONG), INT(nbytes,C_SIZE_T), dst, C_NULL_PTR )
   IF ( rc == 0 ) THEN ; pf_ok = pf_ok + 1 ; ELSE ; pf_bad = pf_bad + 1 ; ENDIF
   IF ( pf_ok + pf_bad == 500 .AND. pf_rep == 0 ) THEN
      pf_rep = 1 ; WRITE(0,'(A,I8,A,I8,A,I6)') 'WRF_GPU_PREFETCH calls ok', pf_ok, ' failed', pf_bad, ' last rc', rc
   ENDIF
END SUBROUTINE wrf_gpu_prefetch_addr

SUBROUTINE wrf_gpu_prefetch_sync()
   USE wrf_gpu_pf_ctl
   IMPLICIT NONE
   INTEGER(C_INT) :: rc
   IF ( ASSOCIATED(cu_sync) ) rc = cu_sync()
END SUBROUTINE wrf_gpu_prefetch_sync

! WRF_GPU_HOSTBLOCKS=0: keep compute regions on the GPU inside the physics / microphysics / diagnostics blocks
! (only meaningful for dynamics-only experiments with all physics schemes off). Default 1 = host blocks.
LOGICAL FUNCTION wrf_gpu_hostblocks()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_HOSTBLOCKS', v, STATUS=st )
      mode = 1
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 1
   ENDIF
   wrf_gpu_hostblocks = ( mode /= 0 )
END FUNCTION wrf_gpu_hostblocks

! WRF_GPU_XFER (residency, default 1048575 = all of the below): reduced lists - bit 1 H1 pull, 4 H2 pull, 8 H3 pull, 2 pushes, 16 GPU-owned physics
! tendencies (needs 2+4), 32 microphysics block on the GPU (Thompson), 64 no pushes of recomputed diffusion fields,
! 128 H1 reuses the H3-pulled state (alt/p/ph_2 still pulled), 256 GPU-side init_zero_tendency + phy_prep,
! 1024 MYJ PBL on the GPU (needs 256), 2048 pinned staging of the H1/H3 pulls, 4096 boundary arrays pushed only
! after boundary reads, 8192 Tiedtke cumulus on the GPU (needs 1024); 16384/32768 RRTMG LW/SW, 65536 NWP+AFWA diagnostics, 131072 MYJ surface layer, 262144 Noah LSM, 524288 lean steps, 1048576 RK dynamics without per-routine exit waits, 4194304 lean steps with host Noah (many-core hosts); default 2097151.
! WRF_GPU_XFER bit 2048 (residency): device->host copy of one array through two pinned staging buffers
! (cuMemAllocHost), double-buffered on async queues 11/12, with an OpenMP host copy out of the staging buffer.
! Pageable update self runs at ~4.4 GB/s on the V100 rentals; pinned DMA ~11-12 GB/s. Falls back to update self.
SUBROUTINE gpu_stage_pull( a, n )
   USE openacc
   USE ISO_C_BINDING
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: n
   REAL, TARGET :: a(n)
   INTEGER, PARAMETER :: NCH = 2*1024*1024          ! reals per chunk (8 MB)
   TYPE(C_PTR), SAVE :: stage(2) = C_NULL_PTR
   LOGICAL, SAVE :: tried = .FALSE., ok = .FALSE.
   INTERFACE
      TYPE(C_PTR) FUNCTION dlopen( name, flags ) BIND(C, NAME='dlopen')
         IMPORT :: C_PTR, C_CHAR, C_INT
         CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
         INTEGER(C_INT), VALUE :: flags
      END FUNCTION dlopen
      TYPE(C_FUNPTR) FUNCTION dlsym( h, name ) BIND(C, NAME='dlsym')
         IMPORT :: C_PTR, C_FUNPTR, C_CHAR
         TYPE(C_PTR), VALUE :: h
         CHARACTER(KIND=C_CHAR), DIMENSION(*) :: name
      END FUNCTION dlsym
   END INTERFACE
   ABSTRACT INTERFACE
      INTEGER(C_INT) FUNCTION alloch_t( pp, nbytes ) BIND(C)
         IMPORT :: C_PTR, C_INT, C_SIZE_T
         TYPE(C_PTR) :: pp
         INTEGER(C_SIZE_T), VALUE :: nbytes
      END FUNCTION alloch_t
      INTEGER(C_INT) FUNCTION d2h_t( dst, src, nbytes, strm ) BIND(C)
         IMPORT :: C_PTR, C_INT, C_SIZE_T, C_INT64_T
         TYPE(C_PTR), VALUE :: dst
         INTEGER(C_INT64_T), VALUE :: src
         INTEGER(C_SIZE_T), VALUE :: nbytes
         INTEGER(C_INT64_T), VALUE :: strm   ! CUstream handle
      END FUNCTION d2h_t
   END INTERFACE
   PROCEDURE(alloch_t), POINTER, SAVE :: cu_alloch => NULL()
   PROCEDURE(d2h_t), POINTER, SAVE :: cu_d2h => NULL()
   TYPE(C_PTR) :: h
   INTEGER(C_INT64_T) :: strm(2)
   REAL, POINTER :: st(:)
   INTEGER :: nc, c, b, off, len, lenn, i
   INTEGER(C_INT) :: rc
   INTEGER(C_INT64_T) :: dpi
   IF ( .NOT. tried ) THEN
      tried = .TRUE.
      h = dlopen( 'libcuda.so.1'//C_NULL_CHAR, 2 )
      IF ( C_ASSOCIATED(h) ) THEN
         CALL C_F_PROCPOINTER( dlsym( h, 'cuMemAllocHost_v2'//C_NULL_CHAR ), cu_alloch )
         CALL C_F_PROCPOINTER( dlsym( h, 'cuMemcpyDtoHAsync_v2'//C_NULL_CHAR ), cu_d2h )
      ENDIF
      IF ( ASSOCIATED(cu_alloch) .AND. ASSOCIATED(cu_d2h) ) THEN
         rc = cu_alloch( stage(1), INT(NCH,C_SIZE_T)*4_C_SIZE_T )
         IF ( rc == 0 ) rc = cu_alloch( stage(2), INT(NCH,C_SIZE_T)*4_C_SIZE_T )
         ok = ( rc == 0 )
      ENDIF
      IF ( .NOT. ok ) CALL wrf_message( 'gpu_stage_pull: no pinned staging buffers - using update self' )
      IF ( ok ) CALL wrf_message( 'gpu_stage_pull: pinned staging buffers 2 x 8 MB' )
   ENDIF
!$acc wait
   IF ( .NOT. ok ) THEN
!$acc update self(a)
      RETURN
   ENDIF
   strm(1) = INT( acc_get_cuda_stream( 11 ), C_INT64_T )
   strm(2) = INT( acc_get_cuda_stream( 12 ), C_INT64_T )
   dpi = TRANSFER( acc_deviceptr( a ), dpi )
   nc = ( n + NCH - 1 ) / NCH
   len = MIN( NCH, n )
   rc = cu_d2h( stage(1), dpi, INT(len,C_SIZE_T)*4_C_SIZE_T, strm(1) )
   b = 1
   DO c = 1, nc
      off = (c-1)*NCH
      len = MIN( NCH, n - off )
      IF ( c < nc ) THEN
         lenn = MIN( NCH, n - off - len )
         rc = cu_d2h( stage(3-b), dpi + INT(off+len,C_INT64_T)*4, INT(lenn,C_SIZE_T)*4_C_SIZE_T, strm(3-b) )
      ENDIF
      CALL acc_wait( 10+b )
      CALL C_F_POINTER( stage(b), st, (/ NCH /) )
!$OMP PARALLEL DO
      DO i = 1, len
         a(off+i) = st(i)
      ENDDO
!$OMP END PARALLEL DO
      b = 3 - b
   ENDDO
END SUBROUTINE gpu_stage_pull

LOGICAL FUNCTION wrf_gpu_async_mode()
   ! WRF_GPU_ASYNC (residency builds): 1 = GPU compute constructs on async queue 1 (default; waits at routine exit and before sync directives), 0 = synchronous
   IMPLICIT NONE
   INTEGER :: mode
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_ASYNC', v, STATUS=st )
   mode = 1
   IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
   IF ( st /= 0 ) mode = 1
   wrf_gpu_async_mode = mode /= 0
END FUNCTION wrf_gpu_async_mode

LOGICAL FUNCTION wrf_gpu_h1chk()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_H1CHK', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   wrf_gpu_h1chk = mode > 0
END FUNCTION wrf_gpu_h1chk

INTEGER FUNCTION wrf_gpu_xfer()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_XFER', v, STATUS=st )
      mode = 2097151
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 2097151
   ENDIF
   wrf_gpu_xfer = mode
END FUNCTION wrf_gpu_xfer

! WRF_GPU_FULLSYNC (diagnostic, residency builds): 1 = at every host-block entry pull every device-resident
! grid array and all i1 temporaries to the host; 3 = also push them all back at every host-block exit.
INTEGER FUNCTION wrf_gpu_fullsync()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_FULLSYNC', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   wrf_gpu_fullsync = mode
END FUNCTION wrf_gpu_fullsync

! WRF_GPU_ADDRMAP=1: print address and byte size of every real grid state array and i1 temporary once (to map
! Nsight unified-memory migration address ranges back to arrays).
LOGICAL FUNCTION wrf_gpu_addrmap()
   IMPLICIT NONE
   LOGICAL, SAVE :: done = .FALSE.
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   wrf_gpu_addrmap = .FALSE.
   IF ( done ) RETURN
   done = .TRUE.
   CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_ADDRMAP', v, STATUS=st )
   wrf_gpu_addrmap = ( st == 0 .AND. v(1:1) == '1' )
END FUNCTION wrf_gpu_addrmap

SUBROUTINE wrf_gpu_addrmap_grid( grid )
   USE module_domain, ONLY : domain, fieldlist
   IMPLICIT NONE
   TYPE(domain), INTENT(IN) :: grid
   TYPE(fieldlist), POINTER :: p
   p => grid%head_statevars
   DO WHILE ( ASSOCIATED(p) )
      IF ( p%Type == 'r' ) THEN
         IF ( p%Ndim == 2 ) THEN
            IF ( ASSOCIATED(p%rfield_2d) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP grid:', TRIM(p%VarName), &
               LOC(p%rfield_2d(LBOUND(p%rfield_2d,1),LBOUND(p%rfield_2d,2))), INT(SIZE(p%rfield_2d),8)*4_8
         ELSE IF ( p%Ndim == 3 ) THEN
            IF ( ASSOCIATED(p%rfield_3d) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP grid:', TRIM(p%VarName), &
               LOC(p%rfield_3d(LBOUND(p%rfield_3d,1),LBOUND(p%rfield_3d,2),LBOUND(p%rfield_3d,3))), INT(SIZE(p%rfield_3d),8)*4_8
         ELSE IF ( p%Ndim == 4 ) THEN
            IF ( ASSOCIATED(p%rfield_4d) ) WRITE(0,'(A,A,1X,Z16,1X,I14)') 'ADDRMAP grid:', TRIM(p%VarName), &
               LOC(p%rfield_4d(LBOUND(p%rfield_4d,1),LBOUND(p%rfield_4d,2),LBOUND(p%rfield_4d,3),LBOUND(p%rfield_4d,4))), &
               INT(SIZE(p%rfield_4d),8)*4_8
         ENDIF
      ENDIF
      p => p%next
   ENDDO
END SUBROUTINE wrf_gpu_addrmap_grid

! WRF_GPU_PHYS_TILES=N (dm+sm GPU builds): the GPU dynamics keeps the solve_em tiling (run with WRF_NUM_TILES=1),
! the host blocks (physics, microphysics, after_all_rk_steps) use N OpenMP tiles (tiling zone 19, cached).
SUBROUTINE gpu_retile( grid, to_phys, ids, ide, jds, jde, ips, ipe, jps, jpe )
   USE module_domain, ONLY : domain
   USE module_tiles, ONLY : set_tiles
   USE module_model_constants, ONLY : ZONE_SOLVE_EM
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   LOGICAL, INTENT(IN) :: to_phys
   INTEGER, INTENT(IN) :: ids, ide, jds, jde, ips, ipe, jps, jpe
   INTEGER, PARAMETER :: ZONE_GPU_PHYS = 19
   INTEGER, SAVE :: ntp = -1, ntx = 0, nty = 0
   INTEGER :: st, nsave, spec_save, nx_save, ny_save, nxs, nys
   CHARACTER(LEN=8) :: v
   IF ( ntp < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_PHYS_TILES', v, STATUS=st )
      ntp = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) ntp
      IF ( st /= 0 ) ntp = 0
      ! optional 2-D physics tiling (WRF_GPU_PHYS_TILES_X x WRF_GPU_PHYS_TILES_Y), e.g. 4x4 instead of 16 j-strips
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_PHYS_TILES_X', v, STATUS=st )
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) ntx
      IF ( st /= 0 ) ntx = 0
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_PHYS_TILES_Y', v, STATUS=st )
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) nty
      IF ( st /= 0 ) nty = 0
   ENDIF
   IF ( ntp <= 1 ) RETURN
   IF ( to_phys ) THEN
      IF ( .NOT. grid%tiling_latch(ZONE_GPU_PHYS) ) THEN
         ! set_tiles2 caches the first computed count in grid%num_tiles_spec (and x/y): clear it so the namelist
         ! value ntp is used for this zone, then restore the cached values for the solve_em (dynamics) zone.
         spec_save = grid%num_tiles_spec ; nx_save = grid%num_tiles_x ; ny_save = grid%num_tiles_y
         grid%num_tiles_spec = 0
         CALL nl_get_numtiles( 1, nsave )
         CALL nl_get_numtiles_x( 1, nxs ) ; CALL nl_get_numtiles_y( 1, nys )
         CALL nl_set_numtiles( 1, ntp )
         IF ( ntx > 0 .AND. nty > 0 ) THEN
            CALL nl_set_numtiles_x( 1, ntx ) ; CALL nl_set_numtiles_y( 1, nty )
         ENDIF
         CALL set_tiles( ZONE_GPU_PHYS, grid, ids, ide, jds, jde, ips, ipe, jps, jpe )
         CALL nl_set_numtiles( 1, nsave )
         CALL nl_set_numtiles_x( 1, nxs ) ; CALL nl_set_numtiles_y( 1, nys )
         grid%num_tiles_spec = spec_save ; grid%num_tiles_x = nx_save ; grid%num_tiles_y = ny_save
         CALL set_tiles( ZONE_GPU_PHYS, grid, ids, ide, jds, jde, ips, ipe, jps, jpe )
      ELSE
         CALL set_tiles( ZONE_GPU_PHYS, grid, ids, ide, jds, jde, ips, ipe, jps, jpe )
      ENDIF
   ELSE
      CALL set_tiles( ZONE_SOLVE_EM, grid, ids, ide, jds, jde, ips, ipe, jps, jpe )
   ENDIF
END SUBROUTINE gpu_retile

! WRF_GPU lean step: levels kms..kms+1 of the GPU phy_prep fields and the moisture species to the host, packed on
! the device (one contiguous transfer instead of ~20 full 3-D pulls)
SUBROUTINE gpu_lean_pull( grid, th_phy, p_phy, pi_phy, p8w, t8w, dz8w, moist, num_moist, ims, ime, jms, jme, kms, kme )
   USE module_domain, ONLY : domain
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   INTEGER, INTENT(IN) :: num_moist, ims, ime, jms, jme, kms, kme
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme), INTENT(INOUT) :: th_phy, p_phy, pi_phy, p8w, t8w, dz8w
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme,num_moist), INTENT(INOUT) :: moist
   REAL, ALLOCATABLE, SAVE :: buf(:,:,:,:)
   INTEGER :: i, j, k, n, nf
   nf = 14 + num_moist
   IF ( ALLOCATED(buf) ) THEN
      IF ( SIZE(buf,4) /= nf .OR. SIZE(buf,1) /= ime-ims+1 .OR. SIZE(buf,3) /= jme-jms+1 ) THEN
!$acc exit data delete(buf)
         DEALLOCATE(buf)
      ENDIF
   ENDIF
   IF ( .NOT. ALLOCATED(buf) ) THEN
      ALLOCATE( buf(ims:ime,2,jms:jme,nf) )
!$acc enter data create(buf)
   ENDIF
   CALL lean_pack( buf, grid%t_phy, th_phy, p_phy, pi_phy, grid%u_phy, grid%v_phy, p8w, t8w, dz8w, grid%rho, &
                   grid%z, grid%z_at_w, grid%p_hyd, grid%p_hyd_w, moist, num_moist, nf, ims, ime, jms, jme, kms, kme )
!$acc update self(buf)
   !$OMP PARALLEL DO PRIVATE(i,j,k,n)
   DO j = jms, jme
   DO k = 1, 2
   DO i = ims, ime
      grid%t_phy(i,kms+k-1,j) = buf(i,k,j,1)
      th_phy(i,kms+k-1,j) = buf(i,k,j,2)
      p_phy(i,kms+k-1,j) = buf(i,k,j,3)
      pi_phy(i,kms+k-1,j) = buf(i,k,j,4)
      grid%u_phy(i,kms+k-1,j) = buf(i,k,j,5)
      grid%v_phy(i,kms+k-1,j) = buf(i,k,j,6)
      p8w(i,kms+k-1,j) = buf(i,k,j,7)
      t8w(i,kms+k-1,j) = buf(i,k,j,8)
      dz8w(i,kms+k-1,j) = buf(i,k,j,9)
      grid%rho(i,kms+k-1,j) = buf(i,k,j,10)
      grid%z(i,kms+k-1,j) = buf(i,k,j,11)
      grid%z_at_w(i,kms+k-1,j) = buf(i,k,j,12)
      grid%p_hyd(i,kms+k-1,j) = buf(i,k,j,13)
      grid%p_hyd_w(i,kms+k-1,j) = buf(i,k,j,14)
      DO n = 1, num_moist
         moist(i,kms+k-1,j,n) = buf(i,k,j,14+n)
      ENDDO
   ENDDO
   ENDDO
   ENDDO
   !$OMP END PARALLEL DO
END SUBROUTINE gpu_lean_pull

LOGICAL FUNCTION gpu_p8wchk()
   IMPLICIT NONE
   INTEGER, SAVE :: mode = -1
   CHARACTER(LEN=8) :: v
   INTEGER :: st
   IF ( mode < 0 ) THEN
      CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_P8WCHK', v, STATUS=st )
      mode = 0
      IF ( st == 0 ) READ( v, *, IOSTAT=st ) mode
      IF ( st /= 0 ) mode = 0
   ENDIF
   gpu_p8wchk = mode > 0
END FUNCTION gpu_p8wchk

! WRF_GPU_P8WCHK: compare the device copy of a (contiguous, present) array with the host copy; the host copy is kept
SUBROUTINE gpu_arrchk( nm, a, n, step )
   IMPLICIT NONE
   CHARACTER(LEN=*), INTENT(IN) :: nm
   INTEGER, INTENT(IN) :: n, step
   REAL, INTENT(INOUT) :: a(n)
   REAL, ALLOCATABLE :: h(:)
   REAL :: d
   INTEGER :: nd
   ALLOCATE( h(n) )
   h = a
!$acc update self(a(1:n))
   d = MAXVAL( ABS( a - h ) )
   nd = COUNT( a /= h )
   IF ( nd > 0 ) WRITE(0,'(A,I6,1X,A12,ES12.4,I9)') 'ARRCHK step', step, nm, d, nd
   a = h
   DEALLOCATE( h )
END SUBROUTINE gpu_arrchk

SUBROUTINE gpu_lean_check( grid, th_phy, p_phy, pi_phy, p8w, t8w, dz8w, moist, num_moist, ims, ime, jms, jme, &
                           kms, kme, ips, ipe, jps, jpe )
   USE module_domain, ONLY : domain
   IMPLICIT NONE
   TYPE(domain), INTENT(INOUT) :: grid
   INTEGER, INTENT(IN) :: num_moist, ims, ime, jms, jme, kms, kme, ips, ipe, jps, jpe
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme), INTENT(IN) :: th_phy, p_phy, pi_phy, p8w, t8w, dz8w
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme,num_moist), INTENT(IN) :: moist
   REAL, ALLOCATABLE :: buf(:,:,:,:)
   CHARACTER(LEN=12), PARAMETER :: nm(14) = (/ 't_phy  ', 'th_phy ', 'p_phy  ', 'pi_phy ', 'u_phy  ', 'v_phy  ', &
                                               'p8w    ', 't8w    ', 'dz8w   ', 'rho    ', 'z      ', 'z_at_w ', &
                                               'p_hyd  ', 'p_hyd_w' /)
   REAL :: h, dmax
   INTEGER :: i, j, k, f, nf, ib, jb
   nf = 14 + num_moist
   ALLOCATE( buf(ims:ime,2,jms:jme,nf) )
!$acc wait
!$acc data create(buf)
   CALL lean_pack( buf, grid%t_phy, th_phy, p_phy, pi_phy, grid%u_phy, grid%v_phy, p8w, t8w, dz8w, grid%rho, &
                   grid%z, grid%z_at_w, grid%p_hyd, grid%p_hyd_w, moist, num_moist, nf, ims, ime, jms, jme, kms, kme )
!$acc update self(buf)
!$acc end data
   DO f = 1, 14
      dmax = 0. ; ib = 0 ; jb = 0
      DO j = jps, MIN(jpe, jme) ; DO k = 1, 2 ; DO i = ips, MIN(ipe, ime)
         SELECT CASE (f)
         CASE (1) ; h = grid%t_phy(i,kms+k-1,j)
         CASE (2) ; h = th_phy(i,kms+k-1,j)
         CASE (3) ; h = p_phy(i,kms+k-1,j)
         CASE (4) ; h = pi_phy(i,kms+k-1,j)
         CASE (5) ; h = grid%u_phy(i,kms+k-1,j)
         CASE (6) ; h = grid%v_phy(i,kms+k-1,j)
         CASE (7) ; h = p8w(i,kms+k-1,j)
         CASE (8) ; h = t8w(i,kms+k-1,j)
         CASE (9) ; h = dz8w(i,kms+k-1,j)
         CASE (10) ; h = grid%rho(i,kms+k-1,j)
         CASE (11) ; h = grid%z(i,kms+k-1,j)
         CASE (12) ; h = grid%z_at_w(i,kms+k-1,j)
         CASE (13) ; h = grid%p_hyd(i,kms+k-1,j)
         CASE DEFAULT ; h = grid%p_hyd_w(i,kms+k-1,j)
         END SELECT
         IF ( ABS(buf(i,k,j,f) - h) > dmax ) THEN
            dmax = ABS(buf(i,k,j,f) - h) ; ib = i ; jb = j
         ENDIF
      ENDDO ; ENDDO ; ENDDO
      WRITE(0,'(A,I6,1X,A,ES12.4,2I5)') 'P8WCHK step', grid%itimestep, nm(f), dmax, ib, jb
   ENDDO
   DEALLOCATE( buf )
END SUBROUTINE gpu_lean_check

SUBROUTINE lean_pack( buf, t_phy, th_phy, p_phy, pi_phy, u_phy, v_phy, p8w, t8w, dz8w, rho, z, z_at_w, p_hyd, p_hyd_w, moist, &
                      num_moist, nf, ims, ime, jms, jme, kms, kme )
   IMPLICIT NONE
   INTEGER, INTENT(IN) :: num_moist, nf, ims, ime, jms, jme, kms, kme
   REAL, DIMENSION(ims:ime,2,jms:jme,nf), INTENT(INOUT) :: buf
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme), INTENT(IN) :: t_phy, th_phy, p_phy, pi_phy, u_phy, v_phy, p8w, t8w, &
                                                          dz8w, rho, z, z_at_w, p_hyd, p_hyd_w
   REAL, DIMENSION(ims:ime,kms:kme,jms:jme,num_moist), INTENT(IN) :: moist
   INTEGER :: i, j, k, n
!$acc parallel loop collapse(3) present(buf,t_phy,th_phy,p_phy,pi_phy,u_phy,v_phy,p8w,t8w,dz8w,rho,z,z_at_w,p_hyd,p_hyd_w,moist)
   DO j = jms, jme
   DO k = 1, 2
   DO i = ims, ime
      buf(i,k,j,1) = t_phy(i,kms+k-1,j)
      buf(i,k,j,2) = th_phy(i,kms+k-1,j)
      buf(i,k,j,3) = p_phy(i,kms+k-1,j)
      buf(i,k,j,4) = pi_phy(i,kms+k-1,j)
      buf(i,k,j,5) = u_phy(i,kms+k-1,j)
      buf(i,k,j,6) = v_phy(i,kms+k-1,j)
      buf(i,k,j,7) = p8w(i,kms+k-1,j)
      buf(i,k,j,8) = t8w(i,kms+k-1,j)
      buf(i,k,j,9) = dz8w(i,kms+k-1,j)
      buf(i,k,j,10) = rho(i,kms+k-1,j)
      buf(i,k,j,11) = z(i,kms+k-1,j)
      buf(i,k,j,12) = z_at_w(i,kms+k-1,j)
      buf(i,k,j,13) = p_hyd(i,kms+k-1,j)
      buf(i,k,j,14) = p_hyd_w(i,kms+k-1,j)
      DO n = 1, num_moist
         buf(i,k,j,14+n) = moist(i,kms+k-1,j,n)
      ENDDO
   ENDDO
   ENDDO
   ENDDO
END SUBROUTINE lean_pack
#endif
