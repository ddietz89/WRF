#

LN      =       ln -sf
MAKE    =       make -i -r
RM      =       rm -f


MODULES =                 		\
        module_advect_em.o   		\
        module_ieva_em.o            \
	  module_diffusion_em.o  		\
	  module_small_step_em.o 		\
        module_big_step_utilities_em.o  \
        module_em.o         		\
        module_solvedebug_em.o    	\
        module_bc_em.o                  \
        module_init_utilities.o         \
        module_wps_io_arw.o             \
	  module_damping_em.o		\
	  module_polarfft.o		\
        module_force_scm.o              \
        module_first_rk_step_part1.o    \
        module_first_rk_step_part2.o    \
        module_avgflx_em.o              \
	  module_sfs_nba.o		\
        module_convtrans_prep.o         \
	  module_sfs_driver.o		\
	  module_stoch.o			\
	  module_after_all_rk_steps.o	\
	  $(CASE_MODULE)

# possible CASE_MODULE settings
#	module_initialize_b_wave.o      \
#	module_initialize_grav2d_x.o    \
#	module_initialize_heldsuarez.o  \
#	module_initialize_hill2d_x.o    \
#	module_initialize_quarter_ss.o  \
#	module_initialize_real.o        \
#	module_initialize_lsm_x.o       \
#	module_initialize_les.o         \
#	module_initialize_squall2d_x.o  \
#	module_initialize_squall2d_y.o 

OBJS    = 		        \
	init_modules_em.o       \
	solve_em.o              \
        start_em.o              \
        shift_domain_em.o       \
        couple_or_uncouple_em.o \
        nest_init_utils.o	\
        adapt_timestep_em.o     \
        interp_domain_em.o
 

LIBTARGET    =  dyn_em
TARGETDIR    =  ./
$(LIBTARGET) :  $(MODULES) $(OBJS)
		$(AR) $(ARFLAGS) ../main/$(LIBWRFLIB) $(MODULES) $(OBJS)

include ../configure.wrf

# BSU_REGCAP: register cap for the big-step utilities kernels (ncu 2026-11-07: horizontal_pressure_gradient 138-158
# registers, horizontal_diffusion 156-168, calc_ww_cp 136, rhs_ph 102-139, all at ~16% occupancy). 0 = none.
BSU_REGCAP ?= 0
ifneq ($(BSU_REGCAP),0)
ifneq (,$(findstring -DWRF_GPU_RESIDENT,$(ARCH_LOCAL)))
module_big_step_utilities_em.o: FCFLAGS += -gpu=maxregcount:$(BSU_REGCAP)
endif
endif
# SMALLSTEP_REGCAP: register cap for the small-step solver kernels (ncu 2026-11-08 big1000: advance_w 96 regs / 30%
# occupancy at 60% DRAM, advance_mu_t 88-107, advance_uv 64-90); 0 = no cap. A cap only changes register allocation.
# Tried 80 (2026-11-08): bit-identical, 0.4121/0.4128 vs 0.4090/0.4116 s/step - no gain, default stays 0.
SMALLSTEP_REGCAP ?= 80
ifneq ($(SMALLSTEP_REGCAP),0)
ifneq (,$(findstring -DWRF_GPU_RESIDENT,$(ARCH_LOCAL)))
module_small_step_em.o: FCFLAGS += -gpu=maxregcount:$(SMALLSTEP_REGCAP)
endif
endif

cio.o :
	$(CC) -c $(CFLAGS) cio.c

clean:
	@ echo 'use the clean script'

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

include depend.dyn_em

# DO NOT DELETE
