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

# Advection ISA working default for the qualified GNU13.3/Zen2 campaign.
# CPU/OS admission is required on every runtime node; compiler identity alone
# does not qualify hardware. Use WRF_ADVECTION_ZEN2=0 for generic ISA.
# Other compiler versions remain generic; rebuild the object/archive/executable
# when changing this option. No link or thread-team flags are added.
WRF_ADVECTION_ZEN2 ?= $(if $(and $(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)),$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null))),1,0)
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

# Enable GNU RK tendency SIMD without creating an OpenMP thread team.
# Use make WRF_RK_TENDENCY_SIMD=0 to preserve the ordinary ModuleEM path.
WRF_RK_TENDENCY_SIMD ?= 1
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_em.o: private override FCFLAGS += -fopenmp-simd
endif
endif

# SmallStep ISA working default for the qualified GNU13.3/Zen2 campaign.
# CPU/OS admission is required on every runtime node; compiler identity alone
# does not qualify hardware. Use WRF_SMALL_STEP_ZEN2=0 for generic ISA.
# Other GNU versions default to generic; explicit opt-in remains experimental.
# Rebuild the object/archive/executable when changing this option.
WRF_SMALL_STEP_ZEN2 ?= $(if $(and $(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)),$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null))),1,0)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override FCFLAGS += -march=znver2 -mno-fma
endif
endif

# Exact RK1 T snapshot/coupling fusion: qualified GNU13.3 pure-MPI SmallStep path.
# Use WRF_SMALL_STEP_T_COPY_FUSION=0 and rebuild for the original copy schedule.
WRF_SMALL_STEP_T_COPY_FUSION ?= 1
ifeq ($(WRF_SMALL_STEP_T_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_T_COPY_FUSION
endif
endif
endif
endif
endif
endif
# Exact RK1 PH snapshot/consumer fusion: qualified GNU13.3 pure-MPI SmallStep path.
# Use WRF_SMALL_STEP_PH_COPY_FUSION=0 and rebuild for the original copy schedule.
WRF_SMALL_STEP_PH_COPY_FUSION ?= 1
ifeq ($(WRF_SMALL_STEP_PH_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_PH_COPY_FUSION
endif
endif
endif
endif
endif
endif
# U nonhydrostatic pressure correction SIMD: qualified GNU13.3 SmallStep path.
# Use WRF_SMALL_STEP_U_NH_CORRECTION_SIMD=0 and rebuild to omit this directive.
WRF_SMALL_STEP_U_NH_CORRECTION_SIMD ?= 1
ifeq ($(WRF_SMALL_STEP_U_NH_CORRECTION_SIMD),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_U_NH_CORRECTION_SIMD
endif
endif
endif
endif
endif
endif

# Exact RK1 U/V snapshots fused into their coupling consumers.
# Qualified GNU13.3 empty-OMPCPP SmallStep SIMD/Zen2 path; serial is not qualified.
# Use WRF_SMALL_STEP_UV_COPY_FUSION=0 and rebuild for the prior U/V copy schedule.
WRF_SMALL_STEP_UV_COPY_FUSION ?= 1
ifeq ($(WRF_SMALL_STEP_UV_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_UV_COPY_FUSION
endif
endif
endif
endif
endif
endif

# Exact RK1 W snapshot fused into the existing guarded W/PH consumer.
# Qualified GNU13.3 empty-OMPCPP SmallStep SIMD/Zen2 + PH fusion path.
# WRF_SMALL_STEP_W_COPY_FUSION=0 restores the prior W schedule after full regeneration/rebuild.
# These guards do not assert DM_PARALLEL; matching serial builds remain unqualified.
WRF_SMALL_STEP_W_COPY_FUSION ?= 1
ifeq ($(WRF_SMALL_STEP_W_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_PH_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_W_COPY_FUSION
endif
endif
endif
endif
endif
endif
endif


# Exact same-I WDTN producer / preceding theta-row consumer schedule.
# Qualified GNU13.3 empty-OMPCPP SmallStep SIMD/Zen2 path only.
# Set WRF_ADVANCE_MU_WDTN_ROW_PIPELINE=0 and regenerate/rebuild for original schedule.
# No DM_PARALLEL assertion; matching serial builds remain unqualified.
WRF_ADVANCE_MU_WDTN_ROW_PIPELINE ?= 1
ifeq ($(WRF_ADVANCE_MU_WDTN_ROW_PIPELINE),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_WDTN_ROW_PIPELINE
endif
endif
endif
endif
endif
endif

# Exact calc_coef_w A(k+1)/B(k) row pipeline; all arithmetic/stores retained.
# Qualified GNU13.3 empty-OMPCPP SmallStep SIMD/Zen2 path; matching serial unqualified.
# Set WRF_CALC_COEF_W_AHEAD_ROW_PIPELINE=0 and fully regenerate/rebuild to restore original schedule.
WRF_CALC_COEF_W_AHEAD_ROW_PIPELINE ?= 1
ifeq ($(WRF_CALC_COEF_W_AHEAD_ROW_PIPELINE),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_CALC_COEF_W_AHEAD_ROW_PIPELINE
endif
endif
endif
endif
endif
endif

cio.o :
	$(CC) -c $(CFLAGS) cio.c

clean:
	@ echo 'use the clean script'

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

include depend.dyn_em

# DO NOT DELETE
