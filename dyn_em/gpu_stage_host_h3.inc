! GENERATED from gpu_upd_host_h3.inc: WRF_GPU_XFER bit 2048 - device->host through pinned staging buffers (gpu_stage_pull);
! the first element is passed (sequence association: no copy-in temporary of the pointer array)
! WRF_GPU_H3MASK bits (solve_em h3mask): 0 alt 1 moist 2 mu_2 3 p 4 ph_2 5 rho 6 t_2 7 u_2 8 v_2 9 w_2 10 scalar,
! 11 also the slot-1 dummy of moist/scalar; h3got records what was pulled (H1 reuse)
! read set of H3 (after_all_rk_steps diagnostics) (grep of grid% references, 2026-11-04); full GPU-written list: gpu_upd_host_pre_phys.inc
   IF ( associated(grid%alt) .and. BTEST(h3mask,0) ) CALL gpu_stage_pull( &
        grid%alt( LBOUND(grid%alt,1) &
                , LBOUND(grid%alt,2) &
                , LBOUND(grid%alt,3) &
                ), SIZE(grid%alt) )
   IF ( associated(grid%moist) .and. BTEST(h3mask,1) ) THEN
     IF ( BTEST(h3mask,11) .or. SIZE(grid%moist,4) < 2 ) THEN
       CALL gpu_stage_pull( grid%moist( LBOUND(grid%moist,1), LBOUND(grid%moist,2), LBOUND(grid%moist,3), &
                                  LBOUND(grid%moist,4) ), &
                            SIZE(grid%moist) )
     ELSE
       CALL gpu_stage_pull( grid%moist( LBOUND(grid%moist,1), LBOUND(grid%moist,2), LBOUND(grid%moist,3), &
                                  LBOUND(grid%moist,4)+1 ), &
                            SIZE(grid%moist) - SIZE(grid%moist,1)*SIZE(grid%moist,2)*SIZE(grid%moist,3) )
     ENDIF
   ENDIF
   IF ( associated(grid%mu_2) .and. BTEST(h3mask,2) ) CALL gpu_stage_pull( &
        grid%mu_2( LBOUND(grid%mu_2,1) &
                , LBOUND(grid%mu_2,2) &
                ), SIZE(grid%mu_2) )
   IF ( associated(grid%p) .and. BTEST(h3mask,3) ) CALL gpu_stage_pull( &
        grid%p( LBOUND(grid%p,1) &
                , LBOUND(grid%p,2) &
                , LBOUND(grid%p,3) &
                ), SIZE(grid%p) )
   IF ( associated(grid%ph_2) .and. BTEST(h3mask,4) ) CALL gpu_stage_pull( &
        grid%ph_2( LBOUND(grid%ph_2,1) &
                , LBOUND(grid%ph_2,2) &
                , LBOUND(grid%ph_2,3) &
                ), SIZE(grid%ph_2) )
   IF ( associated(grid%rho) .and. BTEST(h3mask,5) ) CALL gpu_stage_pull( &
        grid%rho( LBOUND(grid%rho,1) &
                , LBOUND(grid%rho,2) &
                , LBOUND(grid%rho,3) &
                ), SIZE(grid%rho) )
   IF ( associated(grid%t_2) .and. BTEST(h3mask,6) ) CALL gpu_stage_pull( &
        grid%t_2( LBOUND(grid%t_2,1) &
                , LBOUND(grid%t_2,2) &
                , LBOUND(grid%t_2,3) &
                ), SIZE(grid%t_2) )
   IF ( associated(grid%u_2) .and. BTEST(h3mask,7) ) CALL gpu_stage_pull( &
        grid%u_2( LBOUND(grid%u_2,1) &
                , LBOUND(grid%u_2,2) &
                , LBOUND(grid%u_2,3) &
                ), SIZE(grid%u_2) )
   IF ( associated(grid%v_2) .and. BTEST(h3mask,8) ) CALL gpu_stage_pull( &
        grid%v_2( LBOUND(grid%v_2,1) &
                , LBOUND(grid%v_2,2) &
                , LBOUND(grid%v_2,3) &
                ), SIZE(grid%v_2) )
   IF ( associated(grid%w_2) .and. BTEST(h3mask,9) ) CALL gpu_stage_pull( &
        grid%w_2( LBOUND(grid%w_2,1) &
                , LBOUND(grid%w_2,2) &
                , LBOUND(grid%w_2,3) &
                ), SIZE(grid%w_2) )
   IF ( associated(grid%scalar) .and. BTEST(h3mask,10) ) THEN
     IF ( BTEST(h3mask,11) .or. SIZE(grid%scalar,4) < 2 ) THEN
       CALL gpu_stage_pull( grid%scalar( LBOUND(grid%scalar,1), LBOUND(grid%scalar,2), LBOUND(grid%scalar,3), &
                                  LBOUND(grid%scalar,4) ), &
                            SIZE(grid%scalar) )
     ELSE
       CALL gpu_stage_pull( grid%scalar( LBOUND(grid%scalar,1), LBOUND(grid%scalar,2), LBOUND(grid%scalar,3), &
                                  LBOUND(grid%scalar,4)+1 ), &
                            SIZE(grid%scalar) - SIZE(grid%scalar,1)*SIZE(grid%scalar,2)*SIZE(grid%scalar,3) )
     ENDIF
   ENDIF
