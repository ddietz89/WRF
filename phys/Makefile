

LN      =       ln -sf
MAKE    =       make -i -r
RM      =       rm -f


MODULES = \
	ccpp_kind_types.o \
	module_bep_bem_helper.o \
	complex_number_module.o \
	module_cam_shr_kind_mod.o \
	module_cam_support.o \
	module_cam_shr_const_mod.o \
	module_cam_physconst.o \
	module_cam_cldwat.o \
	module_cam_wv_saturation.o \
	module_cam_esinti.o \
	module_cam_gffgch.o \
	module_cam_error_function.o \
	module_cam_constituents.o \
	module_cam_trb_mtn_stress.o \
	module_cam_molec_diff.o \
	module_cam_upper_bc.o \
	module_cam_bl_diffusion_solver.o \
	module_cam_bl_eddy_diff.o \
	module_cam_mp_microp_aero.o \
	module_cam_mp_cldwat2m_micro.o \
	module_cam_mp_ndrop.o \
	module_cam_mp_modal_aero_initialize_data_phys.o \
	module_cam_mp_radconstants.o \
	module_cam_mp_conv_water.o \
	module_cam_mp_qneg3.o \
	module_data_cam_mam_aero.o \
	module_data_cam_mam_asect.o \
	module_cam_infnan.o \
	$(PHYS_PLUS) \
	module_bl_ysu.o \
	module_bl_shinhong.o \
	module_bl_mrf.o \
	module_bl_gfs.o \
        module_bl_gfsedmf.o \
	module_bl_myjpbl.o \
	module_bl_qnsepbl.o \
	module_bl_acm.o \
        module_bl_mynnedmf_common.o \
        module_bl_mynnedmf.o \
        module_bl_mynnedmf_driver.o \
	module_bl_fogdes.o \
	module_bl_gwdo.o \
	module_bl_gwdo_gsl.o \
	module_bl_myjurb.o \
	module_bl_boulac.o \
	module_checkerror.o \
	module_bl_camuwpbl_driver.o \
	module_bl_mfshconvpbl.o \
	module_bl_eepsilon.o \
	module_bl_keps.o \
        module_shcu_camuwshcu_driver.o \
	module_shcu_camuwshcu.o \
	module_shcu_deng.o          \
	module_shcu_grims.o \
	module_shcu_nscv.o \
	module_cu_camzm_driver.o \
	module_cu_camzm.o \
	module_bl_temf.o \
	module_bl_gbmpbl.o \
	module_cu_g3.o \
	module_cu_kf.o  \
	module_cu_bmj.o \
	module_cu_kfeta.o \
	module_cu_mskf.o \
	module_cu_tiedtke.o\
	module_cu_ntiedtke.o\
	module_cu_gd.o \
	module_cu_gfl_common.o \
	module_cu_gfl_deep.o \
	module_cu_gfl_sh.o \
	module_cu_gfl_wrf.o \
	module_cu_ksas.o \
	module_cu_nsas.o \
	module_cu_sas.o \
	module_gocart_coupling.o \
	module_cu_scalesas.o \
	module_cu_osas.o \
	module_cu_kfcup.o \
	module_madwrf.o \
	module_mp_radar.o \
	module_mp_kessler.o \
	module_mp_lin.o  \
	module_mp_sbu_ylin.o  \
	module_mp_wsm3.o \
	module_mp_wsm5.o \
	module_mp_wsm6.o \
	module_mp_wsm6r.o \
	module_mp_wsm7.o \
	module_mp_etanew.o \
	module_mp_fer_hires.o \
	module_mp_thompson.o \
	module_mp_tempo_cfgs.o \
	module_mp_tempo_params.o \
	module_mp_tempo_utils.o \
	module_mp_tempo_diags.o \
	module_mp_tempo_ml.o \
	module_mp_tempo_aerosols.o \
	module_mp_tempo_main.o \
	module_mp_tempo_driver.o \
	module_mp_rcon.o \
        module_fire_emis.o \
	module_mp_SBM_polar_radar.o \
	module_mp_full_sbm.o \
	module_mp_fast_sbm.o \
	module_ltng_lpi.o \
	module_mp_gsfcgce.o \
	module_mp_gsfcgce_4ice_nuwrf.o \
	module_mp_morr_two_moment.o \
        module_mp_p3.o \
        module_mp_jensen_ishmael.o \
        module_mp_morr_two_moment_aero.o \
	module_mp_milbrandt2mom.o \
	module_mp_nssl_2mom.o \
	module_mp_wdm5.o \
	module_mp_wdm6.o \
	module_mp_wdm7.o \
	module_mp_udm.o \
	module_mp_ntu.o \
	module_mp_cammgmp_driver.o \
	module_ra_sw.o  \
	module_ra_clWRF_support.o  \
	module_ra_gsfcsw.o \
	module_ra_goddard.o \
        module_ra_effective_radius.o \
	module_ra_rrtm.o  \
	module_ra_rrtmg_lw.o  \
	module_ra_rrtmg_sw.o  \
	module_ra_rrtmg_aero_optical_util_cmaq.o \
	module_ra_rrtmg_lwf.o  \
	module_ra_rrtmg_swf.o  \
	module_ra_rrtmg_lwk.o  \
	module_ra_rrtmg_swk.o  \
	module_ra_cam_support.o \
	module_ra_cam.o \
	module_ra_gfdleta.o \
	module_ra_flg.o \
	module_ra_hs.o  \
	module_ra_eclipse.o \
	module_ra_aerosol.o  \
	module_ra_farms.o  \
	module_sf_sfclay.o \
	module_sf_sfclayrev.o \
	module_sf_gfs.o \
	module_sf_exchcoef.o \
	module_sf_gfdl.o \
	module_sf_slab.o  \
	module_sf_noahdrv.o  \
	module_sf_noahlsm.o  \
	module_sf_clm.o  \
	module_sf_ctsm.o \
        module_sf_ssib.o  \
	module_sf_noah_seaice.o \
	module_sf_noah_seaice_drv.o \
	module_sf_noahlsm_glacial_only.o \
        module_sf_gecros.o \
        module_sf_urban.o  \
        module_sf_bep.o  \
        module_sf_bep_bem.o \
        module_sf_bem.o \
	module_sf_pxlsm.o \
	module_sf_pxlsm_data.o \
	module_sf_ruclsm.o \
	module_sf_sfcdiags.o \
	module_sf_sfcdiags_ruclsm.o \
	module_sf_sstskin.o \
	module_sf_tmnupdate.o \
	module_sf_ocean_driver.o \
	module_sf_oml.o \
	module_sf_3dpwp.o \
	module_sf_myjsfc.o \
	module_sf_qnsesfc.o \
	module_sf_mynnsfc_common.o \
	module_sf_mynnsfc_driver.o \
	module_sf_mynnsfc_land.o \
	module_sf_mynnsfc_water.o \
	module_sf_mynnsfc_ice.o \
	module_sf_fogdes.o \
	module_sf_pxsfclay.o \
	module_sf_temfsfclay.o \
	module_sf_idealscmsfclay.o \
	module_sf_scmflux.o \
	module_sf_scmskintemp.o \
	module_physics_addtendc.o \
	module_physics_init.o \
	module_gfs_machine.o \
	module_gfs_funcphys.o \
	module_gfs_physcons.o \
	module_progtm.o \
	module_pbl_driver.o \
	module_data_gocart_dust.o \
        module_dust_emis.o \
	module_cumulus_driver.o \
	module_shallowcu_driver.o \
	module_microphysics_driver.o \
	module_microphysics_zero_out.o \
	module_mixactivate.o \
	module_radiation_driver.o \
	module_surface_driver.o \
	module_lightning_driver.o \
	module_ltng_cpmpr92z.o \
	module_ltng_crmpr92.o \
	module_ltng_iccg.o \
	module_calc_lpi_new.o \
	module_ltng_pe.o \
	module_ltng_strokes.o \
	module_fdda_psufddagd.o \
	module_fdda_spnudging.o \
	module_fddagd_driver.o  \
        module_fddaobs_rtfdda.o \
	module_fddaobs_driver.o \
	module_wind_fitch.o \
	module_wind_mav.o \
	module_sf_lake.o \
	module_diagnostics_driver.o \
	module_diagvar_cordex.o \
	module_irrigation.o

FIRE_MODULES = \
        module_fr_fire_driver.o \
        module_fr_fire_driver_wrf.o \
        module_fr_fire_atm.o \
        module_fr_fire_model.o \
        module_fr_fire_core.o \
        module_fr_fire_phys.o \
        module_fr_fire_util.o \
        module_firebrand_spotting_mpi.o \
        module_firebrand_spotting.o

DIAGNOSTIC_MODULES_EM = \
	module_diag_afwa.o \
	module_diag_cl.o \
	module_diag_functions.o \
	module_diag_cordex.o \
        module_diag_hailcast.o \
	module_diag_misc.o \
	module_diag_nwp.o \
        module_diag_rasm.o \
	module_diag_pld.o \
	module_diag_zld.o \
	module_diag_trad_fields.o \
        module_diag_solar.o

PHYSMMM_MODULES = \
	physics_mmm/sf_sfclayrev.o \
	physics_mmm/cu_ntiedtke.o \
	physics_mmm/module_libmassv.o \
	physics_mmm/mp_wsm6.o \
	physics_mmm/mp_wsm6_effectRad.o \
	physics_mmm/mp_radar.o \
    physics_mmm/bl_gwdo.o \
    physics_mmm/bl_shinhong.o \
    physics_mmm/bl_ysu.o

NOAHMP_MODULES = \
	noahmp/drivers/wrf/NoahmpWRFinitMod.o \
        noahmp/drivers/wrf/NoahmpWRFmainMod.o \
	noahmp/drivers/wrf/NoahmpUrbanDriverMainMod.o \
        noahmp/drivers/wrf/NoahmpGroundwaterInitMod.o \
        noahmp/drivers/wrf/NoahmpSnowInitMod.o \
        noahmp/drivers/wrf/NoahmpInitMainMod.o \
        noahmp/drivers/wrf/NoahmpDriverMainMod.o \
        noahmp/drivers/wrf/NoahmpIOVarType.o \
        noahmp/drivers/wrf/NoahmpIOVarInitMod.o \
        noahmp/drivers/wrf/NoahmpReadTableMod.o \
        noahmp/drivers/wrf/ConfigVarOutTransferMod.o \
        noahmp/drivers/wrf/ForcingVarOutTransferMod.o \
        noahmp/drivers/wrf/EnergyVarOutTransferMod.o \
        noahmp/drivers/wrf/WaterVarOutTransferMod.o \
        noahmp/drivers/wrf/BiochemVarOutTransferMod.o \
        noahmp/drivers/wrf/ConfigVarInTransferMod.o \
        noahmp/drivers/wrf/ForcingVarInTransferMod.o \
        noahmp/drivers/wrf/EnergyVarInTransferMod.o \
        noahmp/drivers/wrf/WaterVarInTransferMod.o \
        noahmp/drivers/wrf/BiochemVarInTransferMod.o \
        noahmp/drivers/wrf/GroundWaterMmfMod.o \
        noahmp/drivers/wrf/PedoTransferSR2006Mod.o \
        noahmp/utility/Machine.o \
        noahmp/utility/CheckNanMod.o \
        noahmp/utility/PiecewiseLinearInterp1dMod.o \
        noahmp/src/ConstantDefineMod.o \
        noahmp/src/ConfigVarType.o \
        noahmp/src/ForcingVarType.o \
        noahmp/src/EnergyVarType.o \
        noahmp/src/WaterVarType.o \
        noahmp/src/BiochemVarType.o \
        noahmp/src/NoahmpVarType.o \
        noahmp/src/ConfigVarInitMod.o \
        noahmp/src/ForcingVarInitMod.o \
        noahmp/src/EnergyVarInitMod.o \
        noahmp/src/WaterVarInitMod.o \
        noahmp/src/BiochemVarInitMod.o \
        noahmp/src/CanopyHydrologyMod.o \
        noahmp/src/GroundWaterTopModelMod.o \
        noahmp/src/IrrigationFloodMod.o \
        noahmp/src/IrrigationInfilPhilipMod.o \
        noahmp/src/IrrigationMicroMod.o \
        noahmp/src/MatrixSolverTriDiagonalMod.o \
        noahmp/src/RunoffSubSurfaceDrainageMod.o \
        noahmp/src/RunoffSubSurfaceEquiWaterTableMod.o \
        noahmp/src/RunoffSubSurfaceGroundWaterMod.o \
        noahmp/src/RunoffSubSurfaceShallowMmfMod.o \
        noahmp/src/RunoffSurfaceBatsMod.o \
        noahmp/src/RunoffSurfaceDynamicVicMod.o \
        noahmp/src/RunoffSurfaceExcessDynamicVicMod.o \
        noahmp/src/RunoffSurfaceFreeDrainMod.o \
        noahmp/src/RunoffSurfaceTopModelEquiMod.o \
        noahmp/src/RunoffSurfaceTopModelGrdMod.o \
        noahmp/src/RunoffSurfaceTopModelMmfMod.o \
        noahmp/src/RunoffSurfaceVicMod.o \
        noahmp/src/RunoffSurfaceXinAnJiangMod.o \
        noahmp/src/RunoffSurfaceWetlandMod.o \
        noahmp/src/WetlandWaterZhang22Mod.o \
        noahmp/src/ShallowWaterTableMmfMod.o \
        noahmp/src/SnowfallBelowCanopyMod.o \
        noahmp/src/SnowLayerCombineMod.o \
        noahmp/src/SnowLayerDivideMod.o \
        noahmp/src/SnowLayerWaterComboMod.o \
        noahmp/src/SnowpackCompactionMod.o \
        noahmp/src/SnowpackCompactionAR24Mod.o \
        noahmp/src/SnowpackHydrologyMod.o \
        noahmp/src/SnowWaterMainMod.o \
        noahmp/src/SoilHydraulicPropertyMod.o \
        noahmp/src/SoilMoistureSolverMod.o \
        noahmp/src/SoilWaterDiffusionRichardsMod.o \
        noahmp/src/SoilWaterInfilGreenAmptMod.o \
        noahmp/src/SoilWaterInfilPhilipMod.o \
        noahmp/src/SoilWaterInfilSmithParlangeMod.o \
        noahmp/src/SoilWaterMainMod.o \
        noahmp/src/TileDrainageEquiDepthMod.o \
        noahmp/src/TileDrainageHooghoudtMod.o \
        noahmp/src/TileDrainageSimpleMod.o \
        noahmp/src/WaterMainMod.o \
        noahmp/src/WaterTableDepthSearchMod.o \
        noahmp/src/WaterTableEquilibriumMod.o \
        noahmp/src/IrrigationTriggerMod.o \
        noahmp/src/IrrigationSprinklerMod.o \
        noahmp/src/CanopyWaterInterceptMod.o \
        noahmp/src/PrecipitationHeatAdvectMod.o \
        noahmp/src/SnowThermalPropertyMod.o \
        noahmp/src/SoilThermalPropertyMod.o \
        noahmp/src/GroundThermalPropertyMod.o \
        noahmp/src/EnergyMainMod.o \
        noahmp/src/NoahmpMainMod.o \
        noahmp/src/SnowAerosolSnicarMod.o \
        noahmp/src/SnowAgingBatsMod.o \
        noahmp/src/SnowAgingSnicarMod.o \
        noahmp/src/SnowAlbedoBatsMod.o \
        noahmp/src/SnowAlbedoClassMod.o \
        noahmp/src/SnowAlbedoSnicarMod.o \
        noahmp/src/SnowFreshRadiusMod.o \
        noahmp/src/SnowInputSnicarMod.o \
        noahmp/src/SnowRadiationSnicarMod.o \
        noahmp/src/GroundAlbedoMod.o \
        noahmp/src/CanopyRadiationTwoStreamMod.o \
        noahmp/src/SurfaceAlbedoMod.o \
        noahmp/src/SurfaceRadiationMod.o \
        noahmp/src/HumiditySaturationMod.o \
        noahmp/src/ResistanceAboveCanopyChen97Mod.o \
        noahmp/src/ResistanceAboveCanopyMostMod.o \
        noahmp/src/ResistanceCanopyStomataBallBerryMod.o \
        noahmp/src/ResistanceCanopyStomataJarvisMod.o \
        noahmp/src/ResistanceLeafToGroundMod.o \
        noahmp/src/VaporPressureSaturationMod.o \
        noahmp/src/SurfaceEnergyFluxVegetatedMod.o \
        noahmp/src/ResistanceBareGroundChen97Mod.o \
        noahmp/src/ResistanceBareGroundMostMod.o \
        noahmp/src/SurfaceEnergyFluxBareGroundMod.o \
        noahmp/src/SoilSnowTemperatureMainMod.o \
        noahmp/src/SoilSnowTemperatureSolverMod.o \
        noahmp/src/SoilSnowThermalDiffusionMod.o \
        noahmp/src/SoilSnowWaterPhaseChangeMod.o \
        noahmp/src/SoilWaterSupercoolKoren99Mod.o \
        noahmp/src/SoilWaterSupercoolNiu06Mod.o \
        noahmp/src/SnowCoverGroundNiu07Mod.o \
        noahmp/src/SnowCoverGroundAR25Mod.o \
        noahmp/src/GroundRoughnessPropertyMod.o \
        noahmp/src/SurfaceEmissivityMod.o \
        noahmp/src/PsychrometricVariableMod.o \
        noahmp/src/ResistanceGroundEvaporationMod.o \
        noahmp/src/SoilWaterTranspirationMod.o \
        noahmp/src/AtmosForcingMod.o \
        noahmp/src/PhenologyMainMod.o \
        noahmp/src/BiochemCropMainMod.o \
        noahmp/src/BiochemNatureVegMainMod.o \
        noahmp/src/CarbonFluxCropMod.o \
        noahmp/src/CarbonFluxNatureVegMod.o \
        noahmp/src/CropGrowDegreeDayMod.o \
        noahmp/src/CropPhotosynthesisMod.o \
        noahmp/src/IrrigationPrepareMod.o \
        noahmp/src/BalanceErrorCheckMod.o \
        noahmp/src/GeneralInitMod.o \
        noahmp/src/BalanceErrorCheckGlacierMod.o \
        noahmp/src/EnergyMainGlacierMod.o \
        noahmp/src/GeneralInitGlacierMod.o \
        noahmp/src/GlacierIceThermalPropertyMod.o \
        noahmp/src/GlacierPhaseChangeMod.o \
        noahmp/src/GlacierTemperatureMainMod.o \
        noahmp/src/GlacierTemperatureSolverMod.o \
        noahmp/src/GlacierThermalDiffusionMod.o \
        noahmp/src/GroundAlbedoGlacierMod.o \
        noahmp/src/GroundRoughnessPropertyGlacierMod.o \
        noahmp/src/GroundThermalPropertyGlacierMod.o \
        noahmp/src/NoahmpMainGlacierMod.o \
        noahmp/src/PrecipitationHeatAdvectGlacierMod.o \
        noahmp/src/PsychrometricVariableGlacierMod.o \
        noahmp/src/ResistanceGroundEvaporationGlacierMod.o \
        noahmp/src/SnowCoverGlacierMod.o \
        noahmp/src/SnowWaterMainGlacierMod.o \
        noahmp/src/SnowpackHydrologyGlacierMod.o \
        noahmp/src/SurfaceAlbedoGlacierMod.o \
        noahmp/src/SurfaceEmissivityGlacierMod.o \
        noahmp/src/SurfaceEnergyFluxGlacierMod.o \
        noahmp/src/SurfaceRadiationGlacierMod.o \
        noahmp/src/WaterMainGlacierMod.o

OBJS    =

LIBTARGET    =  physics
TARGETDIR    =  ./

$(LIBTARGET) :
	(cd .. && ./tools/manage_externals/checkout_externals --externals ./arch/Externals.cfg)
	$(MAKE) $(J) non_nmm ; \
	$(AR) $(ARFLAGS) ../main/$(LIBWRFLIB) $(MODULES) $(OBJS)  \
		$(FIRE_MODULES) $(DIAGNOSTIC_MODULES_EM) $(PHYSMMM_MODULES) $(NOAHMP_MODULES)

include ../configure.wrf

# GWDO exact qualified PP replay; unsupported configurations retain the original suffix rule.
# Qualified O2 owner hook; explicit 0 and unsupported configurations use the original rule.
WRF_GWDO_FIRSTHIT_O2 ?= 1
_GWDO_OWNER := $(WRF_SRC_ROOT_DIR)/tools/cpu-compute/gwdo-first-hit-o2
_GWDO_ELIGIBLE := $(shell python3 $(_GWDO_OWNER)/select_pp.py probe --knob="$(WRF_GWDO_FIRSTHIT_O2)" --rword="$(RWORDSIZE)" --iword="$(IWORDSIZE)" --omp="$(OMP)" --ompcpp="$(OMPCPP)" --promotion="$(PROMOTION)" --double="$(DOUBLE_PRECISION)" --suffix="$(FCSUFFIX)" --cpp="$(CPPFLAGS)" --flags="$(FCFLAGS)" --modules="$(MODULE_DIRS)" --fc="$(FC)")
ifeq ($(_GWDO_ELIGIBLE),1)
physics_mmm/bl_gwdo.o: physics_mmm/bl_gwdo.F90 ccpp_kind_types.o $(_GWDO_OWNER)/qualified_bl_gwdo.f90 $(_GWDO_OWNER)/select_pp.py Makefile ../configure.wrf
	$(RM) $@
	sed -e "s/^\!.*'.*//" -e "s/^ *\!.*'.*//" physics_mmm/bl_gwdo.F90 > physics_mmm/bl_gwdo.G
	$(CPP) -I$(WRF_SRC_ROOT_DIR)/inc $(CPPFLAGS) $(OMPCPP) physics_mmm/bl_gwdo.G > physics_mmm/bl_gwdo.bb
	$(SED_FTN) physics_mmm/bl_gwdo.bb | $(CPP) $(TRADFLAG) > physics_mmm/bl_gwdo.tmp.f90
	$(RM) physics_mmm/bl_gwdo.G physics_mmm/bl_gwdo.bb
	@mode=$$(python3 $(_GWDO_OWNER)/select_pp.py select --dest=physics_mmm/bl_gwdo.tmp.f90 --modules="$(MODULE_DIRS)") && case "$$mode" in ON|ORIGINAL) $(FC) -o $@ -c $(FCFLAGS) $(OMP) $(MODULE_DIRS) $(PROMOTION) $(FCSUFFIX) physics_mmm/bl_gwdo.tmp.f90 ;; *) exit 1 ;; esac
endif

# Qualified GNU13.3.0, empty OMP/OMPCPP, default REAL/INTEGER4 only.
# Source also requires DM_PARALLEL and !_OPENMP; every other default keeps original code.
# Knob0 disables this mechanism even if ENABLE was explicitly supplied externally.
# Non-GNU stacks may explicitly test ENABLE under the same source guard; that is experimental,
# and does not acquire this campaign's native/application qualification.
WRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY ?= 1
ifeq ($(WRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY_DISABLE
endif
ifeq ($(WRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY_ENABLE
endif
endif
endif
endif
endif
endif
endif


# Qualified GNU13.3.0/default REAL4 INTEGER4/empty OMP and OMPCPP; source DM&&!_OPENMP.
# Opt out: make WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY=0 and rebuild module/archive/executable.
WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY ?= 1
ifeq ($(WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY_DISABLE
endif
ifeq ($(WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY_ENABLE
ifneq (,$(filter -DDM_PARALLEL,$(CPPFLAGS)))
module_ra_rrtmg_sw.o: private override FCFLAGS += -fopenmp-simd
endif
endif
endif
endif
endif
endif
endif
endif

# Existing qualified MYJ module recipe: SIMD directives only, no thread team.
# Opt out with WRF_MYJ_SIMD=0 and rebuild this module/archive/executable.
WRF_MYJ_SIMD ?= 1
ifeq ($(WRF_MYJ_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(filter -DDM_PARALLEL,$(CPPFLAGS)))
module_bl_myjpbl.o: private override FCFLAGS += -fopenmp-simd
endif
endif
endif
endif
endif
endif
endif
endif

# Enable GNU add_a2a SIMD in the qualified pure-MPI configuration; no thread team.
# Use make WRF_ADDTENDC_SIMD=0 and rebuild this object/archive/executable to opt out.
WRF_ADDTENDC_SIMD ?= 1
ifeq ($(WRF_ADDTENDC_SIMD),1)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(strip $(OMP)),)
module_physics_addtendc.o: private override FCFLAGS += -fopenmp-simd
endif
endif
endif

non_nmm : $(MODULES) $(FIRE_MODULES) $(OBJS) $(DIAGNOSTIC_MODULES_EM) $(NOAHMP_MODULES)

submodules :
	@if [ \( ! -f ../run/NoahmpTable.TBL \) -o \
	      \( ! -f noahmp/drivers/wrf/NoahmpWRFmainMod.F90 \) -o \( ! -f noahmp/drivers/wrf/NoahmpWRFinitMod.F90 \) -o \
              \( ! -f noahmp/drivers/wrf/NoahmpIOVarInitMod.F90 \) -o \( ! -f noahmp/drivers/wrf/NoahmpIOVarType.F90 \) -o \
	      \( ! -f noahmp/drivers/wrf/GroundWaterMmfMod.F90 \) -o \( ! -f noahmp/drivers/wrf/NoahmpUrbanDriverMainMod.F90 \) -o \
	      \( ! -f noahmp/src/NoahmpMainMod.F90 \) -o \( ! -f noahmp/src/NoahmpVarType.F90 \) ] ; then \
		echo Pulling in NoahMP submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
		( cd ../run ; ln -sf ../phys/noahmp/parameters/NoahmpTable.TBL . ) ; \
		( cd ../run ; ln -sf ../phys/noahmp/parameters/snicar_drdt_bst_fit_60_c070416.nc . ) ; \
		( cd ../run ; ln -sf ../phys/noahmp/parameters/snicar_optics_480bnd_c012422.nc . ) ; \
		( cd ../run ; ln -sf ../phys/noahmp/parameters/snicar_optics_5bnd_c013122.nc . ) ; \
	else \
		echo No action required for NoahMP submodule ; \
	fi
	@if [ \( ! -f physics_mmm/README.md \) ] ; then \
		echo Pulling in MMM-physics submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
	else \
		echo No action required for MMM-physics submodule ; \
	fi
	@if [ \( ! -f module_bl_mynnedmf.F \) -o \( ! -f module_bl_mynnedmf_common.F \) -o \
	      \( ! -f module_bl_mynnedmf_driver.F \) ] ; then \
	      	echo Pulling in MYNN-EDMF submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
		ln -sf MYNN-EDMF/module_bl_mynnedmf.F90 module_bl_mynnedmf.F ; \
		ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_common.F90 module_bl_mynnedmf_common.F ; \
		ln -sf MYNN-EDMF/WRF/module_bl_mynnedmf_driver.F90 module_bl_mynnedmf_driver.F ; \
	else \
		echo No action required for MYNN-EDMF submodule ; \
	fi
	@if [ \( ! -f module_sf_mynnsfc_driver.F \) -o \( ! -f module_sf_mynnsfc_common.F \) -o \
	      \( ! -f module_sf_mynnsfc_land.F \) -o \( ! -f module_sf_mynnsfc_water.F \) -o \
	      \( ! -f module_sf_mynnsfc_ice.F \) ] ; then \
		echo Pulling in MYNN-SFC submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
		ln -sf MYNN-SFC/WRF/module_sf_mynnsfc_driver.F90 module_sf_mynnsfc_driver.F ; \
		ln -sf MYNN-SFC/WRF/module_sf_mynnsfc_common.F90 module_sf_mynnsfc_common.F ; \
		ln -sf MYNN-SFC/module_sf_mynnsfc_land.F90 module_sf_mynnsfc_land.F ; \
		ln -sf MYNN-SFC/module_sf_mynnsfc_water.F90 module_sf_mynnsfc_water.F ; \
		ln -sf MYNN-SFC/module_sf_mynnsfc_ice.F90 module_sf_mynnsfc_ice.F ; \
	else \
		echo No action required for MYNN-SFC submodule ; \
	fi
	@if [ \( ! -f module_cu_gfl_wrf.F \) -o \( ! -f module_cu_gfl_common.F \) -o \
	      \( ! -f module_cu_gfl_deep.F \) -o \( ! -f module_cu_gfl_sh.F \) ] ; then \
	      	echo Pulling in GFL submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
		ln -sf GFL/module_cu_gfl_sh.F90  module_cu_gfl_sh.F; \
		ln -sf GFL/module_cu_gfl_deep.F90  module_cu_gfl_deep.F; \
		ln -sf GFL/WRF/module_cu_gfl_common.F90 module_cu_gfl_common.F ; \
		ln -sf GFL/WRF/module_cu_gfl_wrf.F90 module_cu_gfl_wrf.F ; \
	else \
		echo No action required for GFL submodule ; \
    fi
	@if [ \( ! -f module_mp_tempo_driver.F90 \) -o \( ! -f module_mp_tempo_main.F90 \) -o \
	      \( ! -f module_mp_tempo_cfgs.F90 \) -o \( ! -f module_mp_tempo_aerosols.F90 \) -o \
	      \( ! -f module_mp_tempo_ml.F90 \) -o \( ! -f module_mp_tempo_diags.F90 \) -o \
              \( ! -f module_mp_tempo_utils.F90 \) -o \( ! -f module_mp_tempo_params.F90 \) ] ; then \
                echo Pulling in TEMPO submodule ; \
		( cd .. ; git submodule update --init --recursive ) ; \
		ln -sf TEMPO/src/module_mp_tempo_cfgs.F90 module_mp_tempo_cfgs.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_params.F90 module_mp_tempo_params.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_utils.F90 module_mp_tempo_utils.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_diags.F90 module_mp_tempo_diags.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_ml.F90 module_mp_tempo_ml.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_aerosols.F90 module_mp_tempo_aerosols.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_main.F90 module_mp_tempo_main.F90 ; \
		ln -sf TEMPO/src/module_mp_tempo_driver.F90 module_mp_tempo_driver.F90 ; \
	else \
		echo No action required for TEMPO submodule ; \
	fi

clean:
	@ echo 'use the clean script'

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)
# DO NOT DELETE

include ../main/depend.common

# SW INATM cloud-copy branch unswitch; qualified build scope is guarded below.: SW INATM copy branch unswitch.
# Qualified recipe GNU13.3/default REAL4 INTEGER4/empty OMP/OMPCPP, source DM&&!_OPENMP.
# Opt out with WRF_SW_INATM_COPY_UNSWITCH=0; DISABLE wins over ENABLE.
WRF_SW_INATM_COPY_UNSWITCH ?= 1
ifeq ($(WRF_SW_INATM_COPY_UNSWITCH),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_INATM_COPY_UNSWITCH_DISABLE
endif
ifeq ($(WRF_SW_INATM_COPY_UNSWITCH),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
# Explicit CPP macro injection must also preserve the original source path.
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)),)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_INATM_COPY_UNSWITCH_ENABLE
ifneq (,$(filter -DDM_PARALLEL,$(CPPFLAGS)))
module_ra_rrtmg_sw.o: private override FCFLAGS += -fopenmp-simd
endif
endif
endif
endif
endif
endif
endif
endif
endif

# LW RTRNMC same-kind one-use flux temporaries; source retains literal original fallback.
# Qualified selected GNU13.3 strict-O2 scope; original fallback remains available.
# No compiler/ISA/FP flags are added. DISABLE wins over explicit ENABLE.
WRF_LW_RTRNMC_FLUX_SCALARS ?= 1
_LW_FLUX_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_LW_RTRNMC_FLUX_SCALARS),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_RTRNMC_FLUX_SCALARS_DISABLE
endif
ifeq ($(WRF_LW_RTRNMC_FLUX_SCALARS),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_LW_FLUX_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_LW_FLUX_FLAGS))),)
ifneq (,$(filter -O2,$(_LW_FLUX_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_LW_FLUX_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(_LW_FLUX_FLAGS)))
ifneq (,$(filter -ffp-contract=off,$(_LW_FLUX_FLAGS)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_RTRNMC_FLUX_SCALARS_ENABLE
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


# SW paired VRTQDR fixed stack for 1..33 layers; original allocation fallback retained.
# Qualified selected GNU13.3 strict-O2 scope; original fallback remains available.
# No compiler/ISA/FP flags are added. DISABLE wins over explicit ENABLE.
WRF_SW_VRTQDR_PAIR_FIXED_STACK ?= 1
_SW_PAIR_STACK_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_SW_VRTQDR_PAIR_FIXED_STACK),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_VRTQDR_PAIR_FIXED_STACK_DISABLE
endif
ifeq ($(WRF_SW_VRTQDR_PAIR_FIXED_STACK),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_SW_PAIR_STACK_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_SW_PAIR_STACK_FLAGS))),)
ifneq (,$(filter -O2,$(_SW_PAIR_STACK_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_SW_PAIR_STACK_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(_SW_PAIR_STACK_FLAGS)))
ifneq (,$(filter -ffp-contract=off,$(_SW_PAIR_STACK_FLAGS)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_VRTQDR_PAIR_FIXED_STACK_ENABLE
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


# SPC four private current-gpoint scratch columns; original matrix storage available.
# Qualified selected GNU13.3 strict-O2 scope; original fallback remains available.
# No compiler/ISA/FP flags are added. DISABLE wins over explicit ENABLE.
WRF_SW_SPC_SINGLE_COLUMN ?= 1
_SW_SPC_COLUMN_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_SW_SPC_SINGLE_COLUMN),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_SINGLE_COLUMN_DISABLE
endif
ifeq ($(WRF_SW_SPC_SINGLE_COLUMN),1)
ifeq ($(WRF_SW_VRTQDR_PAIR_FIXED_STACK),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_SW_SPC_COLUMN_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_SW_SPC_COLUMN_FLAGS))),)
ifneq (,$(filter -O2,$(_SW_SPC_COLUMN_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_SW_SPC_COLUMN_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(_SW_SPC_COLUMN_FLAGS)))
ifneq (,$(filter -ffp-contract=off,$(_SW_SPC_COLUMN_FLAGS)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_SINGLE_COLUMN_ENABLE
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

# SPC pre-delta clear/total private beam scalars; original arrays remain available.
# Qualified selected GNU13.3 strict-O2 scope; original fallback remains available.
# No compiler/ISA/FP flags are added. DISABLE wins over explicit ENABLE.
WRF_SW_SPC_NODEL_SCALARS ?= 1
_SW_SPC_NODEL_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_SW_SPC_NODEL_SCALARS),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_NODEL_SCALARS_DISABLE
endif
ifeq ($(WRF_SW_SPC_NODEL_SCALARS),1)
ifeq ($(WRF_SW_VRTQDR_PAIR_FIXED_STACK),1)
ifeq ($(WRF_SW_SPC_SINGLE_COLUMN),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_SW_SPC_NODEL_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_SW_SPC_NODEL_FLAGS))),)
ifneq (,$(filter -O2,$(_SW_SPC_NODEL_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_SW_SPC_NODEL_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(_SW_SPC_NODEL_FLAGS)))
ifneq (,$(filter -ffp-contract=off,$(_SW_SPC_NODEL_FLAGS)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_NODEL_SCALARS_ENABLE
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
module_ra_rrtmg_sw.o: private override CPPFLAGS += -UWRF_SW_CLOUD_CONSUMER_ENABLE
ifeq ($(WRF_SW_CLOUD_CONSUMER),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_CLOUD_CONSUMER_DISABLE
endif
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
ifeq ($(WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY),1)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_CLOUD_CONSUMER_ENABLE
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

WRF_PHY_INTERPOLATION_SIMD ?= 1
WRF_DIFFUSION_SIMD ?= 1
# Ordered four-lane SPC cloud mixing; original scalar tail and unmasked fallback.
# GNU13.3 strict-O2 REAL4/INT4 pureMPI; one existing PHY mask-helper owner.
WRF_SW_SPC_ORDERED_MIX4 ?= 1
_SW_SPC_ORDERED_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -UWRF_SW_SPC_ORDERED_MIX4_ENABLE
ifeq ($(WRF_SW_SPC_ORDERED_MIX4),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_ORDERED_MIX4_DISABLE
endif
ifeq ($(WRF_SW_SPC_ORDERED_MIX4),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_SW_SPC_ORDERED_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_SW_SPC_ORDERED_FLAGS))),)
ifneq (,$(filter -O2,$(_SW_SPC_ORDERED_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_SW_SPC_ORDERED_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifneq (,$(filter x86_64%,$(shell $(CC) -dumpmachine 2>/dev/null)))
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_SPC_ORDERED_MIX4_ENABLE
OBJS += wrf_spc_mix_ordered4.o
$(LIBTARGET): wrf_spc_mix_ordered4.o
wrf_spc_mix_ordered4.o: wrf_spc_mix_ordered4.c
	$(CC) -O2 -fno-fast-math -ffp-contract=off -msse2 -mno-avx -mno-fma -std=c11 -c $< -o $@
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

# Ordered adjacent-column PWAT pass; full original unmasked/stride fallback.
# GNU13.3 strict-O2 REAL4/INT4 pureMPI; one existing PHY mask-helper owner.
WRF_AFWA_PWAT_ORDERED_COLUMN4 ?= 1
_AFWA_PWAT_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
module_diag_afwa.o: private override CPPFLAGS += -UWRF_AFWA_PWAT_ORDERED_COLUMN4_ENABLE
ifeq ($(WRF_AFWA_PWAT_ORDERED_COLUMN4),0)
module_diag_afwa.o: private override CPPFLAGS += -DWRF_AFWA_PWAT_ORDERED_COLUMN4_DISABLE
endif
ifeq ($(WRF_AFWA_PWAT_ORDERED_COLUMN4),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_AFWA_PWAT_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_AFWA_PWAT_FLAGS))),)
ifneq (,$(filter -O2,$(_AFWA_PWAT_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_AFWA_PWAT_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifneq (,$(filter x86_64%,$(shell $(CC) -dumpmachine 2>/dev/null)))
module_diag_afwa.o: private override CPPFLAGS += -DWRF_AFWA_PWAT_ORDERED_COLUMN4_ENABLE
OBJS += wrf_pwat_column4.o
$(LIBTARGET): wrf_pwat_column4.o
wrf_pwat_column4.o: wrf_pwat_column4.c
	$(CC) -O2 -fno-fast-math -ffp-contract=off -msse2 -mno-avx -mno-fma -std=c11 -c $< -o $@
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

# Ordered four-subcolumn LW MCICA overlap; literal original unmasked/nonfinite fallback.
# GNU13.3 strict-O2 REAL4/INT4 pureMPI; one existing PHY mask-helper owner.
WRF_LW_MCICA_OVERLAP_ORDERED4 ?= 1
_LW_OVERLAP_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -UWRF_LW_MCICA_OVERLAP_ORDERED4_ENABLE
ifeq ($(WRF_LW_MCICA_OVERLAP_ORDERED4),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_MCICA_OVERLAP_ORDERED4_DISABLE
endif
ifeq ($(WRF_LW_MCICA_OVERLAP_ORDERED4),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math,$(_LW_OVERLAP_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_LW_OVERLAP_FLAGS))),)
ifneq (,$(filter -O2,$(_LW_OVERLAP_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_LW_OVERLAP_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifeq ($(WRF_DIFFUSION_SIMD),1)
ifeq ($(WRF_LW_MCICA_WHOLE_DRAW_SEED_CARRY),1)
ifneq (,$(filter x86_64%,$(shell $(CC) -dumpmachine 2>/dev/null)))
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_MCICA_OVERLAP_ORDERED4_ENABLE
OBJS += wrf_lw_overlap_ordered4.o
$(LIBTARGET): wrf_lw_overlap_ordered4.o
wrf_lw_overlap_ordered4.o: wrf_lw_overlap_ordered4.c
	$(CC) -O2 -fno-fast-math -ffp-contract=off -msse2 -mno-avx -mno-fma -std=c11 -c $< -o $@
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


# Thompson main pressure read-only view; original private-copy storage is the fallback.
# Strict qualified GNU13.3 scope below; explicit0 restores the original copy.
WRF_THOMPSON_MAIN_PRESSURE_VIEW ?= 1
_THOMPSON_PRESSURE_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
module_mp_thompson.o: private override CPPFLAGS += -UWRF_THOMPSON_MAIN_PRESSURE_VIEW_ENABLE
ifeq ($(WRF_THOMPSON_MAIN_PRESSURE_VIEW),0)
module_mp_thompson.o: private override CPPFLAGS += -DWRF_THOMPSON_MAIN_PRESSURE_VIEW_DISABLE
endif
ifeq ($(WRF_THOMPSON_MAIN_PRESSURE_VIEW),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -DSTUBMPI -DSTUBMPI=% -DWRF_CHEM -DWRF_CHEM=1,$(CPPFLAGS)),)
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math -march=% -mtune=% -mavx% -mfma%,$(_THOMPSON_PRESSURE_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_THOMPSON_PRESSURE_FLAGS))),)
ifneq (,$(filter -O2,$(_THOMPSON_PRESSURE_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_THOMPSON_PRESSURE_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_mp_thompson.o: private override CPPFLAGS += -DWRF_THOMPSON_MAIN_PRESSURE_VIEW_ENABLE
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

# Thompson automatic arrays: module-only GNU13.3 strictO2 recipe.
# Exact native/table/noon checks qualified this recipe; explicit0 restores ordinary allocation.
# Runtime requires unlimited process stack; no other member/compiler receives this flag.
WRF_THOMPSON_STACK_ARRAYS ?= 1
_THOMPSON_STACK_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_THOMPSON_STACK_ARRAYS),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -DSTUBMPI -DSTUBMPI=% -DWRF_CHEM -DWRF_CHEM=1,$(CPPFLAGS)),)
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -fno-stack-arrays -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math -march=% -mtune=% -mavx% -mfma%,$(_THOMPSON_STACK_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_THOMPSON_STACK_FLAGS))),)
ifneq (,$(filter -O2,$(_THOMPSON_STACK_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_THOMPSON_STACK_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_mp_thompson.o: private override FCFLAGS += -fstack-arrays
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

# MYJ automatic arrays: module-only GNU13.3 strictO2 recipe.
# Exact native/captured-caller and own noon application checks passed.
# Existing WRF_MYJ_SIMD=1 recipe is required; explicit0 restores ordinary allocation.
# Runtime requires unlimited stack; no other member/compiler receives this flag.
WRF_MYJ_STACK_ARRAYS ?= 1
_MYJ_STACK_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_MYJ_STACK_ARRAYS),1)
ifeq ($(WRF_MYJ_SIMD),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL,$(CPPFLAGS)))
ifeq ($(filter -DSTUBMPI -DSTUBMPI=% -DWRF_CHEM -DWRF_CHEM=1,$(CPPFLAGS)),)
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -fno-stack-arrays -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math -march=% -mtune=% -mavx% -mfma%,$(_MYJ_STACK_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_MYJ_STACK_FLAGS))),)
ifneq (,$(filter -O2,$(_MYJ_STACK_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_MYJ_STACK_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
module_bl_myjpbl.o: private override FCFLAGS += -fstack-arrays
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

# Qualified GNU Fortran/C13.3 strict-O2 x86_64 pure-MPI path.
# Requires WRF_PHY_INTERPOLATION_SIMD=1: dyn_em owns the existing integer-only mask getter.
# PHY0/unsupported/compiler/architecture or explicit0 retains original schedule; no new helper owner.
# Contiguous LW cloud-row copies on the qualified compiler path.
# Opt out with WRF_LW_INATM_CONTIGUOUS_COPY=0; the original complete loop remains literal.
WRF_LW_INATM_CONTIGUOUS_COPY ?= 1
ifeq ($(WRF_LW_INATM_CONTIGUOUS_COPY),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_INATM_CONTIGUOUS_COPY_DISABLE
endif
module_ra_rrtmg_lw.o: private override CPPFLAGS += -UWRF_LW_RTRNMC_TWO_G_CHANNEL_ENABLE
WRF_LW_RTRNMC_TWO_G_CHANNEL ?= 1
_LW_RTRNMC_TWO_G_FLAGS = $(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG) $(FC) $(SFC)
ifeq ($(WRF_LW_RTRNMC_TWO_G_CHANNEL),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_RTRNMC_TWO_G_CHANNEL_DISABLE
endif
ifeq ($(WRF_LW_RTRNMC_TWO_G_CHANNEL),1)
ifeq ($(strip $(OMPCPP) $(OMP) $(PROMOTION) $(DOUBLE_PRECISION)),)
ifeq ($(filter -D_OPENMP% _OPENMP%,$(CPPFLAGS)),)
ifneq (,$(filter -DDM_PARALLEL -DDM_PARALLEL=%,$(CPPFLAGS)))
ifeq ($(filter -DSTUBMPI -DSTUBMPI=% -DWRF_CHEM -DWRF_CHEM=1 -DWRFPLUS -DWRFPLUS=1,$(CPPFLAGS)),)
ifeq ($(filter -U%,$(CPPFLAGS)),)
ifeq ($(strip $(RWORDSIZE)),4)
ifeq ($(strip $(IWORDSIZE)),4)
ifeq ($(filter -fdefault-% -freal-% -finteger-% -r8 -i8 -fopenmp -fopenmp=% -fno-stack-arrays -Ofast -ffast-math -fassociative-math -funsafe-math-optimizations -freciprocal-math -ffinite-math-only -fno-signed-zeros -fno-trapping-math -march=% -mtune=% -mavx% -mfma%,$(_LW_RTRNMC_TWO_G_FLAGS)),)
ifeq ($(filter-out -O2,$(filter -O%,$(_LW_RTRNMC_TWO_G_FLAGS))),)
ifneq (,$(filter -O2,$(_LW_RTRNMC_TWO_G_FLAGS)))
ifeq ($(filter-out -ffp-contract=off,$(filter -ffp-contract=%,$(_LW_RTRNMC_TWO_G_FLAGS))),)
ifneq (,$(filter -fno-fast-math,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(filter -ffp-contract=off,$(FCFLAGS) $(FCBASEOPTS) $(FCOPTIM) $(FCDEBUG)))
ifneq (,$(findstring GNU Fortran,$(shell $(FC) --version 2>/dev/null)))
ifeq ($(shell $(FC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifneq (,$(findstring GNU Fortran,$(shell $(SFC) --version 2>/dev/null)))
ifeq ($(shell $(SFC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(shell $(CC) -dumpfullversion -dumpversion 2>/dev/null),13.3.0)
ifeq ($(WRF_PHY_INTERPOLATION_SIMD),1)
ifneq (,$(filter x86_64%,$(shell $(CC) -dumpmachine 2>/dev/null)))
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_RTRNMC_TWO_G_CHANNEL_ENABLE
ifeq ($(WRF_LW_INATM_CONTIGUOUS_COPY),1)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_INATM_CONTIGUOUS_COPY_ENABLE
module_ra_rrtmg_lw.o: private override FCFLAGS += -fopenmp-simd
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

# Two sampled TAUMOL fs1 sites: enabled only under the existing qualified LW build.
# Fortran also checks binary32 REAL and 32-bit INTEGER; unsupported precision uses literal MOD.
WRF_LW_TAUMOL_FS1_REUSE ?= 1
ifeq ($(WRF_LW_TAUMOL_FS1_REUSE),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_TAUMOL_FS1_REUSE_DISABLE
endif

# Two sampled lower-atmosphere band-4 fractions; same qualified LW build and precision checks.
WRF_LW_TAUMOL_BAND4_FRACTION_REUSE ?= 1
ifeq ($(WRF_LW_TAUMOL_BAND4_FRACTION_REUSE),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_TAUMOL_BAND4_FRACTION_REUSE_DISABLE
endif

# One sampled lower band12 fraction; same qualified LW build and precision admission.
WRF_LW_TAUMOL_BAND12_FRACTION_REUSE ?= 1
ifeq ($(WRF_LW_TAUMOL_BAND12_FRACTION_REUSE),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_TAUMOL_BAND12_FRACTION_REUSE_DISABLE
endif

# Final five retained sampled LW fraction sites; same qualified build and precision admission.
WRF_LW_TAUMOL_FIVE_SAMPLED_FRACTIONS_REUSE ?= 1
ifeq ($(WRF_LW_TAUMOL_FIVE_SAMPLED_FRACTIONS_REUSE),0)
module_ra_rrtmg_lw.o: private override CPPFLAGS += -DWRF_LW_TAUMOL_FIVE_SAMPLED_FRACTIONS_REUSE_DISABLE
endif

# CSW snow initialization: skip only the overwritten active iceflag5 rectangle.
# Inherits existing GNU13.3 strict-O2 REAL4/INT4 pureMPI SW ordered support.
# WRF_SW_INATM_CSW_INIT_SKIP=0 restores the original full initialization.
WRF_SW_INATM_CSW_INIT_SKIP ?= 1
ifeq ($(WRF_SW_INATM_CSW_INIT_SKIP),0)
module_ra_rrtmg_sw.o: private override CPPFLAGS += -DWRF_SW_INATM_CSW_INIT_SKIP_DISABLE
endif
