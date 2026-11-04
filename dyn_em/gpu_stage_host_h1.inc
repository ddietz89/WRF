! GENERATED from gpu_upd_host_h1.inc: WRF_GPU_XFER bit 2048 - device->host through pinned staging buffers (gpu_stage_pull);
! the first element is passed (sequence association: no copy-in temporary of the pointer array)
! (bit 128: alt/p/ph_2 always pulled - rk_step_prep / rk_phys_bc_dry_1 / set_physical_bc3d update them on the GPU
!  after the previous H3 pull (WRF_GPU_H1CHK); the other state arrays are unchanged since H3)
! read set of H1 (first_rk_step_part1 physics) (grep of grid% references, 2026-11-04); full GPU-written list: gpu_upd_host_pre_phys.inc
   IF ( associated(grid%alt) ) CALL gpu_stage_pull( &
        grid%alt( LBOUND(grid%alt,1) &
                , LBOUND(grid%alt,2) &
                , LBOUND(grid%alt,3) &
                ), SIZE(grid%alt) )
   IF ( associated(grid%mut) ) CALL gpu_stage_pull( &
        grid%mut( LBOUND(grid%mut,1) &
                , LBOUND(grid%mut,2) &
                ), SIZE(grid%mut) )
   IF ( associated(grid%muu) ) CALL gpu_stage_pull( &
        grid%muu( LBOUND(grid%muu,1) &
                , LBOUND(grid%muu,2) &
                ), SIZE(grid%muu) )
   IF ( associated(grid%muv) ) CALL gpu_stage_pull( &
        grid%muv( LBOUND(grid%muv,1) &
                , LBOUND(grid%muv,2) &
                ), SIZE(grid%muv) )
   IF ( associated(grid%p) ) CALL gpu_stage_pull( &
        grid%p( LBOUND(grid%p,1) &
                , LBOUND(grid%p,2) &
                , LBOUND(grid%p,3) &
                ), SIZE(grid%p) )
   IF ( associated(grid%ph_2) ) CALL gpu_stage_pull( &
        grid%ph_2( LBOUND(grid%ph_2,1) &
                , LBOUND(grid%ph_2,2) &
                , LBOUND(grid%ph_2,3) &
                ), SIZE(grid%ph_2) )
   IF ( associated(grid%rho) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%rho( LBOUND(grid%rho,1) &
                , LBOUND(grid%rho,2) &
                , LBOUND(grid%rho,3) &
                ), SIZE(grid%rho) )
   IF ( associated(grid%rqvften) ) CALL gpu_stage_pull( &
        grid%rqvften( LBOUND(grid%rqvften,1) &
                , LBOUND(grid%rqvften,2) &
                , LBOUND(grid%rqvften,3) &
                ), SIZE(grid%rqvften) )
   IF ( associated(grid%t_2) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%t_2( LBOUND(grid%t_2,1) &
                , LBOUND(grid%t_2,2) &
                , LBOUND(grid%t_2,3) &
                ), SIZE(grid%t_2) )
   IF ( associated(grid%u_2) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%u_2( LBOUND(grid%u_2,1) &
                , LBOUND(grid%u_2,2) &
                , LBOUND(grid%u_2,3) &
                ), SIZE(grid%u_2) )
   IF ( associated(grid%v_2) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%v_2( LBOUND(grid%v_2,1) &
                , LBOUND(grid%v_2,2) &
                , LBOUND(grid%v_2,3) &
                ), SIZE(grid%v_2) )
   IF ( associated(grid%w_2) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%w_2( LBOUND(grid%w_2,1) &
                , LBOUND(grid%w_2,2) &
                , LBOUND(grid%w_2,3) &
                ), SIZE(grid%w_2) )
   IF ( associated(grid%moist) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%moist( LBOUND(grid%moist,1) &
                , LBOUND(grid%moist,2) &
                , LBOUND(grid%moist,3) &
                , LBOUND(grid%moist,4) &
                ), SIZE(grid%moist) )
   IF ( associated(grid%scalar) .and. .not.gpu_h1_reuse ) CALL gpu_stage_pull( &
        grid%scalar( LBOUND(grid%scalar,1) &
                , LBOUND(grid%scalar,2) &
                , LBOUND(grid%scalar,3) &
                , LBOUND(grid%scalar,4) &
                ), SIZE(grid%scalar) )
