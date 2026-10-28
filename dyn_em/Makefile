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

# Full four-lane U momentum prefix with literal scalar tail; no new arithmetic/ISA flags.
# WRF_COUPLE_MOMENTUM_U_SIMD=0 retains the literal original loop.
WRF_COUPLE_MOMENTUM_U_SIMD ?= 1
ifeq ($(WRF_COUPLE_MOMENTUM_U_SIMD),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_COUPLE_MOMENTUM_U_SIMD_DISABLE
endif
ifeq ($(WRF_COUPLE_MOMENTUM_U_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_COUPLE_MOMENTUM_U_SIMD_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Completed adjacent-I Uflux reuse in calc_ww_cp; no new arithmetic/ISA flags.
# WRF_CALC_WW_UFLUX_REUSE=0 retains the literal original loop.
WRF_CALC_WW_UFLUX_REUSE ?= 1
ifeq ($(WRF_CALC_WW_UFLUX_REUSE),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CALC_WW_UFLUX_REUSE_DISABLE
endif
ifeq ($(WRF_CALC_WW_UFLUX_REUSE),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CALC_WW_UFLUX_REUSE_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Exact Coriolis U coefficient row cache: qualified GNU13.3 pure-MPI BigStep SIMD.
# Opt out: WRF_CORIOLIS_U_COEFFICIENT_CACHE=0; regenerate PP, rebuild BigStep,
# replace its archive member and relink. No additional FC/ISA flags.
WRF_CORIOLIS_U_COEFFICIENT_CACHE ?= 1
ifeq ($(WRF_CORIOLIS_U_COEFFICIENT_CACHE),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CORIOLIS_U_COEFFICIENT_CACHE
endif
endif
endif
endif
endif
endif
endif
endif

# Exact normal-V curvature completed quotient row cache: qualified GNU13.3 pure-MPI BigStep SIMD.
# Opt out: WRF_CURVATURE_V_METRIC_CACHE=0; regenerate PP, rebuild BigStep,
# replace its archive member and relink. No additional FC/ISA flags.
WRF_CURVATURE_V_METRIC_CACHE ?= 1
ifeq ($(WRF_CURVATURE_V_METRIC_CACHE),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CURVATURE_V_METRIC_CACHE
endif
endif
endif
endif
endif
endif
endif
endif

# Exact scalar VXGM horizontal J-difference row cache: qualified GNU13.3 pure-MPI BigStep SIMD.
# Opt out: WRF_CURVATURE_VXGM_J_DIFF_CACHE=0; regenerate PP, rebuild BigStep,
# replace its archive member and relink. No additional FC/ISA flags.
WRF_CURVATURE_VXGM_J_DIFF_CACHE ?= 1
ifeq ($(WRF_CURVATURE_VXGM_J_DIFF_CACHE),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CURVATURE_VXGM_J_DIFF_CACHE
endif
endif
endif
endif
endif
endif
endif
endif
# Exact CQV last-species accumulation/consumer fusion: qualified GNU13.3 pure-MPI BigStep SIMD.
# Opt out: WRF_CQV_LAST_SPECIES_CONSUMER_FUSION=0; regenerate PP, rebuild BigStep,
# replace its archive member and relink. No additional FC/ISA flags.
WRF_CQV_LAST_SPECIES_CONSUMER_FUSION ?= 1
ifeq ($(WRF_CQV_LAST_SPECIES_CONSUMER_FUSION),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CQV_LAST_SPECIES_CONSUMER_FUSION
endif
endif
endif
endif
endif
endif
endif
endif


# Exact CQU_CQW last-species accumulation/consumer fusion: qualified GNU13.3 pure-MPI BigStep SIMD.
# Opt out: WRF_CQU_CQW_LAST_SPECIES_CONSUMER_FUSION=0; regenerate PP, rebuild BigStep,
# replace its archive member and relink. No additional FC/ISA flags.
WRF_CQU_CQW_LAST_SPECIES_CONSUMER_FUSION ?= 1
ifeq ($(WRF_CQU_CQW_LAST_SPECIES_CONSUMER_FUSION),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CQU_CQW_LAST_SPECIES_CONSUMER_FUSION
endif
endif
endif
endif
endif
endif
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

# Exact W ELSE WDWN/RHS correction SIMD; qualified GNU13.3 pure-MPI SmallStep.
# WRF_W_WDWN_ELSE_RHS_SIMD=0: regenerate PP, rebuild SmallStep, archive and relink.
WRF_W_WDWN_ELSE_RHS_SIMD ?= 1
ifeq ($(WRF_W_WDWN_ELSE_RHS_SIMD),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifneq (,$(findstring 13.3.0,$(shell $(SFC) --version 2>/dev/null)))
module_small_step_em.o: private override CPPFLAGS += -DWRF_W_WDWN_ELSE_RHS_SIMD
endif
endif
endif
endif
endif
endif
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

# Retained theta producer relocation into the qualified WDTN row pipeline.
# WRF_ADVANCE_MU_THETA_FIRSTPASS_REUSE=0 restores the original producer pass.
WRF_ADVANCE_MU_THETA_FIRSTPASS_REUSE ?= 1
ifeq ($(WRF_ADVANCE_MU_THETA_FIRSTPASS_REUSE),1)
ifeq ($(WRF_ADVANCE_MU_WDTN_ROW_PIPELINE),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_THETA_FIRSTPASS_REUSE
endif
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

# Final completed-flux PD traversal fusion, strict qualified GNU13.3 path only.
# No additional ISA, fastmath, FMA, threading or helper/library dependency.
# Knob0: regenerate PP, recompile this module, fresh archive and relink.
WRF_PD_FINAL_PASS_FUSION ?= 1
ifeq ($(WRF_PD_FINAL_PASS_FUSION),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_PD_FINAL_PASS_FUSION
endif
endif
endif
endif
endif
endif
endif
endif
endif

# WW recurrence / previous-row WW1 consumption, exact scalar operations retained.
# Qualified GNU13.3.0 emptyOMP/OMPCPP SmallStepSIMD1/Zen21; matchingserial unqualified.
# Explicit0 requires full regeneration/rebuild/rearchive/relink, restoring original schedule.
WRF_ADVANCE_MU_WW_ROW_PIPELINE ?= 1
# Inner-I SIMD only within the selected WW row pipeline; explicit 0 keeps its scalar loop.
WRF_ADVANCE_MU_WW_ROW_SIMD ?= 1
ifeq ($(WRF_ADVANCE_MU_WW_ROW_PIPELINE),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_WW_ROW_PIPELINE
ifeq ($(WRF_ADVANCE_MU_WW_ROW_SIMD),1)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_WW_ROW_SIMD
endif
endif
endif
endif
endif
endif
endif
endif
endif


# Damping3 W / finalPH shared traversal; all original scalar and final stores retained.
# Qualified GNU13.3.0 emptyOMP/OMPCPP SmallStepSIMD1/Zen21; matchingserial unqualified.
# Explicit0 requires full regeneration/rebuild/rearchive/relink, restoring original schedule.
WRF_ADVANCE_W_DAMPING_PHI_FUSION ?= 1
ifeq ($(WRF_ADVANCE_W_DAMPING_PHI_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_W_DAMPING_PHI_FUSION
endif
endif
endif
endif
endif
endif
endif
endif


# Six-moisture-family WW_SPLIT reuse, exact existing WW arithmetic and stores retained.
# Qualified GNU13.3.0 ModuleEM SIMD1, empty OMP/OMPCPP, default REAL/INTEGER4.
# Source additionally requires DM_PARALLEL and !_OPENMP; serial keeps original ABI/calls.
# Knob0: regenerate both PPs, rebuild module_em and ALL callers, rearchive and relink.
WRF_MOISTURE_WW_SPLIT_REUSE ?= 1
ifeq ($(WRF_MOISTURE_WW_SPLIT_REUSE),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_em.o solve_em.o: private override CPPFLAGS += -DWRF_MOISTURE_WW_SPLIT_REUSE
# h/z zero reuse composes only with the qualified moisture WW interface.
WRF_MOISTURE_HZ_ZERO_REUSE ?= 1
ifeq ($(WRF_MOISTURE_HZ_ZERO_REUSE),1)
module_em.o solve_em.o: private override CPPFLAGS += -DWRF_MOISTURE_HZ_ZERO_REUSE
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Independent scalar-family WW_SPLIT reuse, same qualified optional interface.
# Requires moisture WW reuse eligibility; no ModuleEM or ABI change.
# Knob0: regenerate/rebuild solve_em, replace archive member and relink.
WRF_SCALAR_WW_SPLIT_REUSE ?= 1
ifeq ($(WRF_SCALAR_WW_SPLIT_REUSE),1)
ifeq ($(WRF_MOISTURE_WW_SPLIT_REUSE),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
solve_em.o: private override CPPFLAGS += -DWRF_SCALAR_WW_SPLIT_REUSE
endif
endif
endif
endif
endif
endif
endif
endif
endif

# First-Y exact zero-entry seed, current qualified two-module path only.
# Knob0: regenerate/rebuild Advect+Em and ALL publicMOD consumers; rearchive/relink.
WRF_ADVECT_FIRST_Y_ZERO_SEED ?= 1
ifeq ($(WRF_ADVECT_FIRST_Y_ZERO_SEED),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o module_em.o: private override CPPFLAGS += -DWRF_ADVECT_FIRST_Y_ZERO_SEED
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Exact private RK scalar clear elimination; optout regenerates Em, replaces slot560 and relinks.
WRF_RK_SCALAR_EXACT_CLEAR ?= 1
ifeq ($(WRF_RK_SCALAR_EXACT_CLEAR),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_em.o: private override CPPFLAGS += -DWRF_RK_SCALAR_EXACT_CLEAR
endif
endif
endif
endif
endif
endif
endif
endif

# Final ww_save copy shares the existing W/PH K traversal; original copy remains off-path.
# Qualified GNU13.3 pureMPI REAL4/INTEGER4 SmallStepSIMD1/Zen21/PHfusion1 only.
# WRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION=0: regeneratePP, rebuildSmallStep, rearchive+relink.
WRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION ?= 1
ifeq ($(WRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION),1)
ifeq ($(WRF_SMALL_STEP_PH_COPY_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Independent V nonhydrostatic pressure correction SIMD; optout0 rebuilds SmallStep/archive/image.
# Qualified GNU13.3/SmallStepSIMD1/Zen21/defaultREAL4INTEGER4/emptyOMP; source DM&&!_OPENMP.
WRF_SMALL_STEP_V_NH_CORRECTION_SIMD ?= 1
ifeq ($(WRF_SMALL_STEP_V_NH_CORRECTION_SIMD),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_V_NH_CORRECTION_SIMD
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Independent V final velocity update SIMD; optout0 rebuilds SmallStep/archive/image.
# Qualified GNU13.3/SmallStepSIMD1/Zen21/defaultREAL4INTEGER4/emptyOMP; source DM&&!_OPENMP.
WRF_SMALL_STEP_V_FINAL_UPDATE_SIMD ?= 1
ifeq ($(WRF_SMALL_STEP_V_FINAL_UPDATE_SIMD),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_V_FINAL_UPDATE_SIMD
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Qualified GNU13.3.0/default REAL4 INTEGER4/empty OMP and OMPCPP; source DM&&!_OPENMP.
# Opt out: make WRF_SMALL_STEP_FINISH_V_SIMD=0 and rebuild module/archive/executable.
WRF_SMALL_STEP_FINISH_V_SIMD ?= 1
ifeq ($(WRF_SMALL_STEP_FINISH_V_SIMD),0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_FINISH_V_SIMD_DISABLE
endif
ifeq ($(WRF_SMALL_STEP_FINISH_V_SIMD),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SMALL_STEP_FINISH_V_SIMD_ENABLE
endif
endif
endif
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

# RK scalar first-stage row pipeline; qualified native, caller and noon application.
# Uses existing module_em SIMD flags only; unsupported/optout retains original source path.
WRF_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE ?= 1
WRF_DISABLE_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE ?= 0
ifneq ($(WRF_DISABLE_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE),0)
module_em.o: private override CPPFLAGS += -DWRF_DISABLE_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE
endif
ifeq ($(WRF_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE),1)
ifeq ($(WRF_DISABLE_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE),0)
ifeq ($(WRF_RK_SCALAR_EXACT_CLEAR),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_em.o: private override CPPFLAGS += -DWRF_RK_SCALAR_FIRSTSTAGE_ROW_PIPELINE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# First non-final SUMFLUX initialization/accumulation fusion; no new arithmetic/ISA flags.
# WRF_SUMFLUX_FIRST_INIT_FUSION=0 retains the literal original procedure path.
WRF_SUMFLUX_FIRST_INIT_FUSION ?= 1
ifeq ($(WRF_SUMFLUX_FIRST_INIT_FUSION),0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SUMFLUX_FIRST_INIT_FUSION_DISABLE
endif
ifeq ($(WRF_SUMFLUX_FIRST_INIT_FUSION),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_SUMFLUX_FIRST_INIT_FUSION_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# RK dry theta later-stage SIMD; first-stage literal scalar priority is preserved.
# Explicit0 selects the original path; no new arithmetic or ISA flags.
WRF_RK_DRY_THETA_LATER_STAGE_SIMD ?= 1
ifeq ($(WRF_RK_DRY_THETA_LATER_STAGE_SIMD),0)
module_em.o: private override CPPFLAGS += -DWRF_RK_DRY_THETA_LATER_STAGE_SIMD_DISABLE
endif
ifeq ($(WRF_RK_DRY_THETA_LATER_STAGE_SIMD),1)
ifeq ($(WRF_RK_TENDENCY_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_em.o: private override CPPFLAGS += -DWRF_RK_DRY_THETA_LATER_STAGE_SIMD_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Independent calc_alt inner-I addition SIMD; no new arithmetic/ISA flags.
# WRF_CALC_ALT_SIMD=0 retains the literal original scalar loop.
WRF_CALC_ALT_SIMD ?= 1
ifeq ($(WRF_CALC_ALT_SIMD),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CALC_ALT_SIMD_DISABLE
endif
ifeq ($(WRF_CALC_ALT_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CALC_ALT_SIMD_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif


# Interior p8w/t8w interpolation SIMD with read-only hardware-mask eligibility.
# WRF_PHY_INTERPOLATION_SIMD=0 preserves the literal original interpolation loop.
# Rebuild this member and helper when changing the knob.
WRF_PHY_INTERPOLATION_SIMD ?= 1
module_big_step_utilities_em.o: private override CPPFLAGS += -UWRF_PHY_INTERPOLATION_SIMD_ENABLE
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_PHY_INTERPOLATION_SIMD_DISABLE
endif
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_PHY_INTERPOLATION_SIMD_ENABLE
OBJS += wrf_phy_interp_mask.o
$(LIBTARGET): wrf_phy_interp_mask.o
wrf_phy_interp_mask.o: wrf_phy_interp_mask.c
	$(CC) $(CFLAGS) -O2 -std=c11 -fno-fast-math -ffp-contract=off -fno-lto -fno-stack-protector -c $< -o $@
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif


# Conditional mass_weight full4-prefix SIMD; original scalar remainder/fallback.
# Default1 proposal only: installation requires own application science/root decision.
# Reuses qualified PHY-owned wrf_phy_interp_mask.o; no second helper/archive member.
WRF_MASS_WEIGHT_SIMD ?= 1
module_bc_em.o: private override CPPFLAGS += -UWRF_MASS_WEIGHT_SIMD_ENABLE
ifeq ($(WRF_MASS_WEIGHT_SIMD),0)
module_bc_em.o: private override CPPFLAGS += -DWRF_MASS_WEIGHT_SIMD_DISABLE
endif
ifeq ($(WRF_MASS_WEIGHT_SIMD),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_bc_em.o: private override CPPFLAGS += -DWRF_MASS_WEIGHT_SIMD_ENABLE
module_bc_em.o: private override FCFLAGS += -fopenmp-simd
module_bc_em.o: wrf_phy_interp_mask.o

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif

# AdvectW X5 full8-prefix SIMD; original scalar remainder and hardware-mask fallback.
# Strict qualified build scope is guarded below; explicit0 preserves the original path.
# Reuses qualified PHY-owned wrf_phy_interp_mask.o; no second helper/archive member.
WRF_ADVECT_W_X5_SIMD ?= 1
module_advect_em.o: private override CPPFLAGS += -UWRF_ADVECT_W_X5_SIMD_ENABLE
ifeq ($(WRF_ADVECT_W_X5_SIMD),0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_W_X5_SIMD_DISABLE
endif
ifeq ($(WRF_ADVECT_W_X5_SIMD),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_W_X5_SIMD_ENABLE
module_advect_em.o: wrf_phy_interp_mask.o

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif
endif
endif

# AdvectW Y5 full8-prefix SIMD; original scalar remainder and hardware-mask fallback.
# Strict qualified build scope is guarded below; explicit0 preserves the original path.
# Reuses qualified PHY-owned wrf_phy_interp_mask.o; no second helper/archive member.
WRF_ADVECT_W_Y5_SIMD ?= 1
module_advect_em.o: private override CPPFLAGS += -UWRF_ADVECT_W_Y5_SIMD_ENABLE
ifeq ($(WRF_ADVECT_W_Y5_SIMD),0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_W_Y5_SIMD_DISABLE
endif
ifeq ($(WRF_ADVECT_W_Y5_SIMD),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_W_Y5_SIMD_ENABLE
module_advect_em.o: wrf_phy_interp_mask.o

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif
endif
endif

# SW stochastic-cloud final consumer guard; literal original scalar fallback.
# Qualified GNU13.3 strict-O2 REAL4/INT4 pureMPI scope; no SIMD gain claim.
WRF_SW_CLOUD_CONSUMER ?= 1
_SW_CLOUD_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_SW_CLOUD_CONSUMER),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_SW_CLOUD_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_SW_CLOUD_FLAGS))),)
ifneq (,$(filter -O2,$(_SW_CLOUD_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_SW_CLOUD_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(_SW_CLOUD_FLAGS)))
ifneq (,$(filter -ffp-contract=off,$(_SW_CLOUD_FLAGS)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
# Reuse the one existing helper owner when PHY already selected it.
ifeq (,$(filter wrf_phy_interp_mask.o,$(OBJS)))
OBJS += wrf_phy_interp_mask.o
$(LIBTARGET): wrf_phy_interp_mask.o
wrf_phy_interp_mask.o: wrf_phy_interp_mask.c
	$(CC) $(CFLAGS) -O2 -std=c11 -fno-fast-math -ffp-contract=off -fno-lto -fno-stack-protector -c $< -o $@
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# Ordered whole-CQU consumer; opt out with WRF_CQU_ORDERED_AVX2=0.
# Rebuild BigStep and both C objects, replace/add their archive members and relink.
# Requires current species fusions; unsupported/O0/unmasked/CPU cases retain original CQU.
WRF_CQU_ORDERED_AVX2 ?= 1
module_big_step_utilities_em.o: private override CPPFLAGS += -UWRF_CQU_ORDERED_AVX2_ENABLE
ifeq ($(WRF_CQU_ORDERED_AVX2),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CQU_ORDERED_AVX2_DISABLE=1
endif
ifeq ($(WRF_CQU_CQW_LAST_SPECIES_CONSUMER_FUSION),1)
ifeq ($(WRF_CQV_LAST_SPECIES_CONSUMER_FUSION),1)
ifeq ($(filter -UDM_PARALLEL -UDM_PARALLEL=% -U -D,$(CPPFLAGS)),)
ifneq (,$(findstring gcc,$(shell $(CC) --version 2>/dev/null)))
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -fno-signed-zeros -fassociative-math -fno-trapping-math -ffp-contract=fast -fdefault-% -fopenmp -fopenmp=%,$(CFLAGS) $(CC)),)
ifeq ($(WRF_CQU_ORDERED_AVX2),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_CQU_ORDERED_AVX2_ENABLE=1
OBJS += wrf_cqu_ordered.o wrf_cqu_ordered_sub_bridge.o
$(LIBTARGET): wrf_cqu_ordered.o wrf_cqu_ordered_sub_bridge.o
wrf_cqu_ordered.o: wrf_cqu_ordered.c
	$(CC) $(CFLAGS) -O2 -std=c11 -mno-avx -mno-avx2 -mno-fma -fno-fast-math -ffp-contract=off -frounding-math -c $< -o $@
wrf_cqu_ordered_sub_bridge.o: wrf_cqu_ordered_sub_bridge.c
	$(CC) $(CFLAGS) -O2 -std=c11 -mno-avx -mno-avx2 -mno-fma -fno-fast-math -ffp-contract=off -frounding-math -c $< -o $@
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif


endif
endif
endif
endif
endif

# Requires the existing single d376 mask-helper owner.
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
# Post-VSPow row final-consumer full4 prefix; original scalar tails/fallback.
# WRF_POSTPOW_FINAL_CONSUMER=0 preserves the literal original post-VSPow pressure consumer.
# Rebuild this member and helper when changing the knob.
WRF_POSTPOW_FINAL_CONSUMER ?= 1
module_big_step_utilities_em.o: private override CPPFLAGS += -UWRF_POSTPOW_FINAL_CONSUMER_ENABLE
ifeq ($(WRF_POSTPOW_FINAL_CONSUMER),0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_POSTPOW_FINAL_CONSUMER_DISABLE
endif
ifeq ($(WRF_POSTPOW_FINAL_CONSUMER),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_big_step_utilities_em.o: private override CPPFLAGS += -DWRF_POSTPOW_FINAL_CONSUMER_ENABLE
OBJS += postpow4.o
$(LIBTARGET): postpow4.o
postpow4.o: postpow4.c
	$(CC) $(CFLAGS) -O2 -std=c11 -fno-fast-math -ffp-contract=off -msse2 -mno-avx -mno-fma -c $< -o $@
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif


endif

# Reuse the disjoint DVDXI/WDTN private lifetimes; no new arithmetic/ISA flags.
# WRF_ADVANCE_MU_DISJOINT_SCRATCH=0 retains separate private scratch arrays; regenerate PP, rebuild SmallStep, rearchive/relink.
WRF_ADVANCE_MU_DISJOINT_SCRATCH ?= 1
ifeq ($(WRF_ADVANCE_MU_DISJOINT_SCRATCH),0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_DISJOINT_SCRATCH_DISABLE
endif
ifeq ($(WRF_ADVANCE_MU_DISJOINT_SCRATCH),1)
ifeq ($(WRF_SMALL_STEP_SIMD),1)
ifeq ($(WRF_SMALL_STEP_ZEN2),1)
ifeq ($(WRF_ADVANCE_MU_WW_ROW_PIPELINE),1)
ifeq ($(WRF_ADVANCE_MU_WW_ROW_SIMD),1)
ifeq ($(WRF_ADVANCE_MU_WDTN_ROW_PIPELINE),1)
ifeq ($(WRF_ADVANCE_MU_THETA_FIRSTPASS_REUSE),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_small_step_em.o: private override CPPFLAGS += -DWRF_ADVANCE_MU_DISJOINT_SCRATCH_ENABLE
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

# AdvectV X5 full8-prefix SIMD; original scalar remainder and hardware-mask fallback.
# Strict qualified build scope is guarded below; explicit0 preserves the original path.
# Reuses qualified PHY-owned wrf_phy_interp_mask.o; no second helper/archive member.
WRF_ADVECT_V_X5_SIMD ?= 1
module_advect_em.o: private override CPPFLAGS += -UWRF_ADVECT_V_X5_SIMD_ENABLE -UWRF_ADVECT_V_X5_O2_OPERAND_ORDER
ifeq ($(WRF_ADVECT_V_X5_SIMD),0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_V_X5_SIMD_DISABLE
endif
ifeq ($(WRF_ADVECT_V_X5_SIMD),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ADVECT_V_X5_SIMD_ENABLE -DWRF_ADVECT_V_X5_O2_OPERAND_ORDER
module_advect_em.o: wrf_phy_interp_mask.o

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif
endif
endif

# Skip the PD consumer only when the unchanged decision found no active cells.
# Strict qualified GNU13.3/O2/REAL4 INTEGER4/pureMPI scope; explicit0 rolls back.
WRF_PD_NOACTIVE_SKIP ?= 1
module_advect_em.o: private override CPPFLAGS += -UWRF_PD_NOACTIVE_SKIP_ENABLE
ifeq ($(WRF_PD_NOACTIVE_SKIP),0)
module_advect_em.o: private override CPPFLAGS += -DWRF_PD_NOACTIVE_SKIP_DISABLE
endif
ifeq ($(WRF_PD_NOACTIVE_SKIP),1)
ifeq ($(WRF_PD_FINAL_PASS_FUSION),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_PD_NOACTIVE_SKIP_ENABLE

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif
endif
endif
endif

# Reuse the completed ordinary horizontal flux plane for vertical scratch.
# Strict qualified GNU13.3/O2/REAL4 INTEGER4/pureMPI scope; explicit0 rolls back.
WRF_ORDINARY_VFLUX_REUSE ?= 1
module_advect_em.o: private override CPPFLAGS += -UWRF_ORDINARY_VFLUX_REUSE_ENABLE
ifeq ($(WRF_ORDINARY_VFLUX_REUSE),0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ORDINARY_VFLUX_REUSE_DISABLE
endif
ifeq ($(WRF_ORDINARY_VFLUX_REUSE),1)
ifeq ($(WRF_PD_NOACTIVE_SKIP),1)
ifeq ($(WRF_PD_FINAL_PASS_FUSION),1)
ifeq ($(WRF_ADVECTION_SIMD),1)
ifeq ($(WRF_ADVECTION_ZEN2),1)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(filter -UDM_PARALLEL -U,$(CPPFLAGS)),)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -fopenmp -fopenmp=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifeq ($(sort $(filter -O%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),-O2)
ifeq ($(filter -ffast-math -Ofast -ffinite-math-only -funsafe-math-optimizations -freciprocal-math -ffp-contract=fast -fno-signed-zeros -fassociative-math -fno-trapping-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC))),)
ifeq ($(filter -D_OPENMP -D_OPENMP=%,$(CPPFLAGS)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_advect_em.o: private override CPPFLAGS += -DWRF_ORDINARY_VFLUX_REUSE_ENABLE

endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif
endif

endif
endif
endif
endif
endif
endif
