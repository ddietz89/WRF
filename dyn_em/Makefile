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

# Enable only GNU SIMD directives in this translation unit; no OpenMP threads.
# Use make WRF_ADVECTION_SIMD=0 to preserve the ordinary compiler path.
WRF_ADVECTION_SIMD ?= 1
ifeq ($(WRF_ADVECTION_SIMD),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_advect_em.o: private override FCFLAGS += -fopenmp-simd
endif
endif

# Experimental architecture opt-in for advection ONLY; default stays generic.
# GNU13.3/native CPU+OS and exact caller/application qualification required.
# WRF_ADVECTION_ZEN2=0 keeps the qualified generic ISA; no link/thread flags.
WRF_ADVECTION_ZEN2 ?= 0
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_advect_em.o: private override FCFLAGS += -march=znver2 -mno-fma
endif
endif

# Enable GNU diffusion SIMD without creating an OpenMP thread team.
# Use make WRF_DIFFUSION_SIMD=0 to preserve the ordinary compiler path.
WRF_DIFFUSION_SIMD ?= 1
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_big_step_utilities_em.o: private override FCFLAGS += -fopenmp-simd
endif
endif

# Enable GNU small-step SIMD without creating an OpenMP thread team.
# Use make WRF_SMALL_STEP_SIMD=0 to preserve the ordinary compiler path.
WRF_SMALL_STEP_SIMD ?= 1
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override FCFLAGS += -fopenmp-simd
endif
endif

cio.o :
	$(CC) -c $(CFLAGS) cio.c

clean:
	@ echo 'use the clean script'

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

include depend.dyn_em

# DO NOT DELETE
