!+---+-----------------------------------------------------------------+
!.. This subroutine computes the moisture tendencies of water vapor,
!.. cloud droplets, rain, cloud ice (pristine), snow, and graupel.
!.. Prior to WRFv2.2 this code was based on Reisner et al (1998), but
!.. few of those pieces remain.  A complete description is now found in
!.. Thompson, G., P. R. Field, R. M. Rasmussen, and W. D. Hall, 2008:
!.. Explicit Forecasts of winter precipitation using an improved bulk
!.. microphysics scheme. Part II: Implementation of a new snow
!.. parameterization.  Mon. Wea. Rev., 136, 5095-5115.
!.. Prior to WRFv3.1, this code was single-moment rain prediction as
!.. described in the reference above, but in v3.1 and higher, the
!.. scheme is two-moment rain (predicted rain number concentration).
!..
!.. Beginning with WRFv3.6, this is also the "aerosol-aware" scheme as
!.. described in Thompson, G. and T. Eidhammer, 2014:  A study of
!.. aerosol impacts on clouds and precipitation development in a large
!.. winter cyclone.  J. Atmos. Sci., 71, 3636-3658.  Setting WRF
!.. namelist option mp_physics=8 utilizes the older one-moment cloud
!.. water with constant droplet concentration set as Nt_c (found below)
!.. while mp_physics=28 uses double-moment cloud droplet number
!.. concentration, which is not permitted to exceed Nt_c_max below.
!..
!.. Most importantly, users may wish to modify the prescribed number of
!.. cloud droplets (Nt_c; see guidelines mentioned below).  Otherwise,
!.. users may alter the rain and graupel size distribution parameters
!.. to use exponential (Marshal-Palmer) or generalized gamma shape.
!.. The snow field assumes a combination of two gamma functions (from
!.. Field et al. 2005) and would require significant modifications
!.. throughout the entire code to alter its shape as well as accretion
!.. rates.  Users may also alter the constants used for density of rain,
!.. graupel, ice, and snow, but the latter is not constant when using
!.. Paul Field's snow distribution and moments methods.  Other values
!.. users can modify include the constants for mass and/or velocity
!.. power law relations and assumed capacitances used in deposition/
!.. sublimation/evaporation/melting.
!.. Remaining values should probably be left alone.
!..
!..Author: Greg Thompson, NCAR-RAL, gthompsn@ucar.edu, 303-497-2805
!..Last modified: 24 Jan 2018   Aerosol additions to v3.5.1 code 9/2013
!..                 Cloud fraction additions 11/2014 part of pre-v3.7
!..                 3-moment graupel/hail additions Aug. 2018 (released in v4.4)
!+---+-----------------------------------------------------------------+
!wrft:model_layer:physics
!+---+-----------------------------------------------------------------+
!


      MODULE module_mp_thompson

      USE module_wrf_error
      USE module_mp_radar
#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
      USE module_dm, ONLY : wrf_dm_max_real
#endif
      USE module_model_constants, only : RE_QC_BG, RE_QI_BG, RE_QS_BG

      IMPLICIT NONE

      LOGICAL, PARAMETER, PRIVATE:: iiwarm = .false.
      LOGICAL, PRIVATE:: is_aerosol_aware = .false.
      LOGICAL, PARAMETER, PRIVATE:: dustyIce = .true.
      LOGICAL, PARAMETER, PRIVATE:: homogIce = .true.
      LOGICAL, PRIVATE:: is_hail_aware = .false.

      INTEGER, PARAMETER, PRIVATE:: IFDRY = 0
      REAL, PARAMETER, PRIVATE:: T_0 = 273.15
      REAL, PARAMETER, PRIVATE:: PI = 3.1415926536

!..Densities of rain, snow, graupel, and cloud ice.
      REAL, PARAMETER, PRIVATE:: rho_w = 1000.0
      REAL, PRIVATE:: rho_s = 100.0
      REAL, PARAMETER, PRIVATE:: rho_i = 890.0
      INTEGER, PARAMETER, PRIVATE:: NRHG = 9
      INTEGER, PARAMETER, PRIVATE:: NRHG1 = 1
      INTEGER :: dimNRHG

      REAL, DIMENSION(NRHG), PARAMETER, PRIVATE:: &
           rho_g = (/50., 100., 200., 300., 400., 500., 600., 700., 800./)
      INTEGER, PARAMETER :: idx_bg1 = 5 ! index for rhog when mp=8 or 28

!..Prescribed number of cloud droplets.  Set according to known data or
!.. roughly 100 per cc (100.E6 m^-3) for Maritime cases and
!.. 300 per cc (300.E6 m^-3) for Continental.  Gamma shape parameter,
!.. mu_c, calculated based on Nt_c is important in autoconversion
!.. scheme.  In 2-moment cloud water, Nt_c represents a maximum of
!.. droplet concentration and nu_c is also variable depending on local
!.. droplet number concentration.
      REAL, PARAMETER, PRIVATE:: Nt_c = 100.E6
      REAL, PARAMETER, PRIVATE:: Nt_c_max = 1999.E6

!..Declaration of constants for assumed CCN/IN aerosols when none in
!.. the input data.  Look inside the init routine for modifications
!.. due to surface land-sea points or vegetation characteristics.
      REAL, PARAMETER, PRIVATE:: naIN0 = 1.5E6
      REAL, PARAMETER, PRIVATE:: naIN1 = 0.5E6
      REAL, PARAMETER, PRIVATE:: naCCN0 = 300.0E6
      REAL, PARAMETER, PRIVATE:: naCCN1 = 50.0E6
      REAL, PARAMETER, PRIVATE:: naBC0 = 150.0E6
      REAL, PARAMETER, PRIVATE:: naBC1 = 25.0E6

!..Generalized gamma distributions for rain, graupel and cloud ice.
!.. N(D) = N_0 * D**mu * exp(-lamda*D);  mu=0 is exponential.
      REAL, PARAMETER, PRIVATE:: mu_r = 0.0
      REAL, PARAMETER, PRIVATE:: mu_g = 0.0
      REAL, PARAMETER, PRIVATE:: mu_i = 0.0
      REAL, PRIVATE:: mu_c

!..Sum of two gamma distrib for snow (Field et al. 2005).
!.. N(D) = M2**4/M3**3 * [Kap0*exp(-M2*Lam0*D/M3)
!..    + Kap1*(M2/M3)**mu_s * D**mu_s * exp(-M2*Lam1*D/M3)]
!.. M2 and M3 are the (bm_s)th and (bm_s+1)th moments respectively
!.. calculated as function of ice water content and temperature.
      REAL, PARAMETER, PRIVATE:: mu_s = 0.6357
      REAL, PARAMETER, PRIVATE:: Kap0 = 490.6
      REAL, PARAMETER, PRIVATE:: Kap1 = 17.46
      REAL, PARAMETER, PRIVATE:: Lam0 = 20.78
      REAL, PARAMETER, PRIVATE:: Lam1 = 3.29

!..Y-intercept parameter for graupel is not constant and depends on
!.. mixing ratio.  Also, when mu_g is non-zero, these become equiv
!.. y-intercept for an exponential distrib and proper values are
!.. computed based on same mixing ratio and total number concentration.
      REAL, PARAMETER, PRIVATE:: gonv_min = 1.E2
      REAL, PARAMETER, PRIVATE:: gonv_max = 1.E6

!..Mass power law relations:  mass = am*D**bm
!.. Snow from Field et al. (2005), others assume spherical form.
      REAL, PARAMETER, PRIVATE:: am_r = PI*rho_w/6.0
      REAL, PARAMETER, PRIVATE:: bm_r = 3.0
      REAL, PARAMETER, PRIVATE:: am_s = 0.069
      REAL, PARAMETER, PRIVATE:: bm_s = 2.0
      REAL, DIMENSION(NRHG), PARAMETER,PRIVATE:: am_g = (/              &
     &            PI*rho_g(1)/6.0, PI*rho_g(2)/6.0, PI*rho_g(3)/6.0,    &
     &            PI*rho_g(4)/6.0, PI*rho_g(5)/6.0, PI*rho_g(6)/6.0,    &
     &            PI*rho_g(7)/6.0, PI*rho_g(8)/6.0, PI*rho_g(9)/6.0 /)
      REAL, PARAMETER, PRIVATE:: bm_g = 3.0
      REAL, PARAMETER, PRIVATE:: am_i = PI*rho_i/6.0
      REAL, PARAMETER, PRIVATE:: bm_i = 3.0

!..Fallspeed power laws relations:  v = (av*D**bv)*exp(-fv*D)
!.. Rain from Ferrier (1994), ice, snow, and graupel from
!.. Thompson et al (2008). Coefficient fv is zero for graupel/ice.
      REAL, PARAMETER, PRIVATE:: av_r = 4854.0
      REAL, PARAMETER, PRIVATE:: bv_r = 1.0
      REAL, PARAMETER, PRIVATE:: fv_r = 195.0
      REAL, PARAMETER, PRIVATE:: av_s = 40.0
      REAL, PARAMETER, PRIVATE:: bv_s = 0.55
      REAL, PARAMETER, PRIVATE:: fv_s = 100.0
      REAL, PARAMETER, PRIVATE:: av_g_old = 442.0
      REAL, PARAMETER, PRIVATE:: bv_g_old = 0.89
      REAL, DIMENSION(NRHG), PRIVATE:: & ! Computed from A. Heymsfield: Best - Reynolds relation
     &    av_g = (/ 45.9173813, 67.0867386, 98.0158463, 122.353378,     &
     &              143.204224, 161.794724, 178.762115, 194.488785,     &
     &              209.225876/)
      REAL, DIMENSION(NRHG), PRIVATE:: & ! Computed from A. Heymsfield: Best - Reynolds relation
     &    bv_g = (/0.640961647, 0.640961647, 0.640961647, 0.640961647,  &
     &             0.640961647, 0.640961647, 0.640961647, 0.640961647,  &
     &             0.640961647/)
      REAL, PARAMETER, PRIVATE:: a_coeff = 0.47244157
      REAL, PARAMETER, PRIVATE:: b_coeff = 0.54698726
      REAL, PARAMETER, PRIVATE:: av_i = 1493.9
      REAL, PARAMETER, PRIVATE:: bv_i = 1.0
      REAL, PARAMETER, PRIVATE:: av_c = 0.316946E8
      REAL, PARAMETER, PRIVATE:: bv_c = 2.0

!..Capacitance of sphere and plates/aggregates: D**3, D**2
      REAL, PARAMETER, PRIVATE:: C_cube = 0.5
      REAL, PARAMETER, PRIVATE:: C_sqrd = 0.15

!..Collection efficiencies.  Rain/snow/graupel collection of cloud
!.. droplets use variables (Ef_rw, Ef_sw, Ef_gw respectively) and
!.. get computed elsewhere because they are dependent on stokes
!.. number.
      REAL, PARAMETER, PRIVATE:: Ef_si = 0.05
      REAL, PARAMETER, PRIVATE:: Ef_rs = 0.95
      REAL, PARAMETER, PRIVATE:: Ef_rg = 0.75
      REAL, PARAMETER, PRIVATE:: Ef_ri = 0.95

!..Minimum microphys values
!.. R1 value, 1.E-12, cannot be set lower because of numerical
!.. problems with Paul Field's moments and should not be set larger
!.. because of truncation problems in snow/ice growth.
      REAL, PARAMETER, PRIVATE:: R1 = 1.E-12
      REAL, PARAMETER, PRIVATE:: R2 = 1.E-6
      REAL, PARAMETER, PRIVATE:: eps = 1.E-15

!..Constants in Cooper curve relation for cloud ice number.
      REAL, PARAMETER, PRIVATE:: TNO = 5.0
      REAL, PARAMETER, PRIVATE:: ATO = 0.304

!..Rho_not used in fallspeed relations (rho_not/rho)**.5 adjustment.
      REAL, PARAMETER, PRIVATE:: rho_not = 101325.0/(287.05*298.0)

!..Schmidt number
      REAL, PARAMETER, PRIVATE:: Sc = 0.632
      REAL, PRIVATE:: Sc3

!..Homogeneous freezing temperature
      REAL, PARAMETER, PRIVATE:: HGFR = 235.16

!..Water vapor and air gas constants at constant pressure
      REAL, PARAMETER, PRIVATE:: Rv = 461.5
      REAL, PARAMETER, PRIVATE:: oRv = 1./Rv
      REAL, PARAMETER, PRIVATE:: R = 287.04
      REAL, PARAMETER, PRIVATE:: Cp = 1004.0
      REAL, PARAMETER, PRIVATE:: R_uni = 8.314                           ! J (mol K)-1

      DOUBLE PRECISION, PARAMETER, PRIVATE:: k_b = 1.38065E-23           ! Boltzmann constant [J/K]
      DOUBLE PRECISION, PARAMETER, PRIVATE:: M_w = 18.01528E-3           ! molecular mass of water [kg/mol]
      DOUBLE PRECISION, PARAMETER, PRIVATE:: M_a = 28.96E-3              ! molecular mass of air [kg/mol]
      DOUBLE PRECISION, PARAMETER, PRIVATE:: N_avo = 6.022E23            ! Avogadro number [1/mol]
      DOUBLE PRECISION, PARAMETER, PRIVATE:: ma_w = M_w / N_avo          ! mass of water molecule [kg]
      REAL, PARAMETER, PRIVATE:: ar_volume = 4./3.*PI*(2.5e-6)**3        ! assume radius of 0.025 micrometer, 2.5e-6 cm

!..Enthalpy of sublimation, vaporization, and fusion at 0C.
      REAL, PARAMETER, PRIVATE:: lsub = 2.834E6
      REAL, PARAMETER, PRIVATE:: lvap0 = 2.5E6
      REAL, PARAMETER, PRIVATE:: lfus = lsub - lvap0
      REAL, PARAMETER, PRIVATE:: olfus = 1./lfus

!..Ice initiates with this mass (kg), corresponding diameter calc.
!..Min diameters and mass of cloud, rain, snow, and graupel (m, kg).
      REAL, PARAMETER, PRIVATE:: xm0i = 1.E-12
      REAL, PARAMETER, PRIVATE:: D0c = 1.E-6
      REAL, PARAMETER, PRIVATE:: D0r = 50.E-6
      REAL, PARAMETER, PRIVATE:: D0s = 300.E-6
      REAL, PARAMETER, PRIVATE:: D0g = 350.E-6
      REAL, PRIVATE:: D0i, xm0s, xm0g

!..Lookup table dimensions
      INTEGER, PARAMETER, PRIVATE:: nbins = 100
      INTEGER, PARAMETER, PRIVATE:: nbc = nbins
      INTEGER, PARAMETER, PRIVATE:: nbi = nbins
      INTEGER, PARAMETER, PRIVATE:: nbr = nbins
      INTEGER, PARAMETER, PRIVATE:: nbs = nbins
      INTEGER, PARAMETER, PRIVATE:: nbg = nbins
      INTEGER, PARAMETER, PRIVATE:: ntb_c = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_i = 64
      INTEGER, PARAMETER, PRIVATE:: ntb_r = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_s = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_g = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_g1 = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_r1 = 37
      INTEGER, PARAMETER, PRIVATE:: ntb_i1 = 55
      INTEGER, PARAMETER, PRIVATE:: ntb_t = 9
      INTEGER, PRIVATE:: nic1, nic2, nii2, nii3, nir2, nir3, nis2, nig2, nig3
      INTEGER, PARAMETER, PRIVATE:: ntb_arc = 7
      INTEGER, PARAMETER, PRIVATE:: ntb_arw = 9
      INTEGER, PARAMETER, PRIVATE:: ntb_art = 7
      INTEGER, PARAMETER, PRIVATE:: ntb_arr = 5
      INTEGER, PARAMETER, PRIVATE:: ntb_ark = 4
      INTEGER, PARAMETER, PRIVATE:: ntb_IN = 55
      INTEGER, PRIVATE:: niIN2

      DOUBLE PRECISION, DIMENSION(nbins+1):: xDx
      DOUBLE PRECISION, DIMENSION(nbc):: Dc, dtc
      DOUBLE PRECISION, DIMENSION(nbi):: Di, dti
      DOUBLE PRECISION, DIMENSION(nbr):: Dr, dtr
      DOUBLE PRECISION, DIMENSION(nbs):: Ds, dts
      DOUBLE PRECISION, DIMENSION(nbg):: Dg, dtg
      DOUBLE PRECISION, DIMENSION(nbc):: t_Nc

!..Lookup tables for cloud water content (kg/m**3).
      REAL, DIMENSION(ntb_c), PARAMETER, PRIVATE:: &
      r_c = (/1.e-6,2.e-6,3.e-6,4.e-6,5.e-6,6.e-6,7.e-6,8.e-6,9.e-6, &
              1.e-5,2.e-5,3.e-5,4.e-5,5.e-5,6.e-5,7.e-5,8.e-5,9.e-5, &
              1.e-4,2.e-4,3.e-4,4.e-4,5.e-4,6.e-4,7.e-4,8.e-4,9.e-4, &
              1.e-3,2.e-3,3.e-3,4.e-3,5.e-3,6.e-3,7.e-3,8.e-3,9.e-3, &
              1.e-2/)

!..Lookup tables for cloud ice content (kg/m**3).
      REAL, DIMENSION(ntb_i), PARAMETER, PRIVATE:: &
      r_i = (/1.e-10,2.e-10,3.e-10,4.e-10, &
              5.e-10,6.e-10,7.e-10,8.e-10,9.e-10, &
              1.e-9,2.e-9,3.e-9,4.e-9,5.e-9,6.e-9,7.e-9,8.e-9,9.e-9, &
              1.e-8,2.e-8,3.e-8,4.e-8,5.e-8,6.e-8,7.e-8,8.e-8,9.e-8, &
              1.e-7,2.e-7,3.e-7,4.e-7,5.e-7,6.e-7,7.e-7,8.e-7,9.e-7, &
              1.e-6,2.e-6,3.e-6,4.e-6,5.e-6,6.e-6,7.e-6,8.e-6,9.e-6, &
              1.e-5,2.e-5,3.e-5,4.e-5,5.e-5,6.e-5,7.e-5,8.e-5,9.e-5, &
              1.e-4,2.e-4,3.e-4,4.e-4,5.e-4,6.e-4,7.e-4,8.e-4,9.e-4, &
              1.e-3/)

!..Lookup tables for rain content (kg/m**3).
      REAL, DIMENSION(ntb_r), PARAMETER, PRIVATE:: &
      r_r = (/1.e-6,2.e-6,3.e-6,4.e-6,5.e-6,6.e-6,7.e-6,8.e-6,9.e-6, &
              1.e-5,2.e-5,3.e-5,4.e-5,5.e-5,6.e-5,7.e-5,8.e-5,9.e-5, &
              1.e-4,2.e-4,3.e-4,4.e-4,5.e-4,6.e-4,7.e-4,8.e-4,9.e-4, &
              1.e-3,2.e-3,3.e-3,4.e-3,5.e-3,6.e-3,7.e-3,8.e-3,9.e-3, &
              1.e-2/)

!..Lookup tables for graupel content (kg/m**3).
      REAL, DIMENSION(ntb_g), PARAMETER, PRIVATE:: &
      r_g = (/1.e-6,2.e-6,3.e-6,4.e-6,5.e-6,6.e-6,7.e-6,8.e-6,9.e-6, &
              1.e-5,2.e-5,3.e-5,4.e-5,5.e-5,6.e-5,7.e-5,8.e-5,9.e-5, &
              1.e-4,2.e-4,3.e-4,4.e-4,5.e-4,6.e-4,7.e-4,8.e-4,9.e-4, &
              1.e-3,2.e-3,3.e-3,4.e-3,5.e-3,6.e-3,7.e-3,8.e-3,9.e-3, &
              1.e-2/)

!..Lookup tables for snow content (kg/m**3).
      REAL, DIMENSION(ntb_s), PARAMETER, PRIVATE:: &
      r_s = (/1.e-6,2.e-6,3.e-6,4.e-6,5.e-6,6.e-6,7.e-6,8.e-6,9.e-6, &
              1.e-5,2.e-5,3.e-5,4.e-5,5.e-5,6.e-5,7.e-5,8.e-5,9.e-5, &
              1.e-4,2.e-4,3.e-4,4.e-4,5.e-4,6.e-4,7.e-4,8.e-4,9.e-4, &
              1.e-3,2.e-3,3.e-3,4.e-3,5.e-3,6.e-3,7.e-3,8.e-3,9.e-3, &
              1.e-2/)

!..Lookup tables for rain y-intercept parameter (/m**4).
      REAL, DIMENSION(ntb_r1), PARAMETER, PRIVATE:: &
      N0r_exp = (/1.e6,2.e6,3.e6,4.e6,5.e6,6.e6,7.e6,8.e6,9.e6, &
                  1.e7,2.e7,3.e7,4.e7,5.e7,6.e7,7.e7,8.e7,9.e7, &
                  1.e8,2.e8,3.e8,4.e8,5.e8,6.e8,7.e8,8.e8,9.e8, &
                  1.e9,2.e9,3.e9,4.e9,5.e9,6.e9,7.e9,8.e9,9.e9, &
                  1.e10/)

!..Lookup tables for graupel y-intercept parameter (/m**4).
      REAL, DIMENSION(ntb_g1), PARAMETER, PRIVATE:: &
      N0g_exp = (/1.e2,2.e2,3.e2,4.e2,5.e2,6.e2,7.e2,8.e2,9.e2, &
                  1.e3,2.e3,3.e3,4.e3,5.e3,6.e3,7.e3,8.e3,9.e3, &
                  1.e4,2.e4,3.e4,4.e4,5.e4,6.e4,7.e4,8.e4,9.e4, &
                  1.e5,2.e5,3.e5,4.e5,5.e5,6.e5,7.e5,8.e5,9.e5, &
                  1.e6/)

!..Lookup tables for ice number concentration (/m**3).
      REAL, DIMENSION(ntb_i1), PARAMETER, PRIVATE:: &
      Nt_i = (/1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0, &
               1.e1,2.e1,3.e1,4.e1,5.e1,6.e1,7.e1,8.e1,9.e1, &
               1.e2,2.e2,3.e2,4.e2,5.e2,6.e2,7.e2,8.e2,9.e2, &
               1.e3,2.e3,3.e3,4.e3,5.e3,6.e3,7.e3,8.e3,9.e3, &
               1.e4,2.e4,3.e4,4.e4,5.e4,6.e4,7.e4,8.e4,9.e4, &
               1.e5,2.e5,3.e5,4.e5,5.e5,6.e5,7.e5,8.e5,9.e5, &
               1.e6/)

!..Aerosol table parameter: Number of available aerosols, vertical
!.. velocity, temperature, aerosol mean radius, and hygroscopicity.
      REAL, DIMENSION(ntb_arc), PARAMETER, PRIVATE:: &
      ta_Na = (/10.0, 31.6, 100.0, 316.0, 1000.0, 3160.0, 10000.0/)
      REAL, DIMENSION(ntb_arw), PARAMETER, PRIVATE:: &
      ta_Ww = (/0.01, 0.0316, 0.1, 0.316, 1.0, 3.16, 10.0, 31.6, 100.0/)
      REAL, DIMENSION(ntb_art), PARAMETER, PRIVATE:: &
      ta_Tk = (/243.15, 253.15, 263.15, 273.15, 283.15, 293.15, 303.15/)
      REAL, DIMENSION(ntb_arr), PARAMETER, PRIVATE:: &
      ta_Ra = (/0.01, 0.02, 0.04, 0.08, 0.16/)
      REAL, DIMENSION(ntb_ark), PARAMETER, PRIVATE:: &
      ta_Ka = (/0.2, 0.4, 0.6, 0.8/)

!..Lookup tables for IN concentration (/m**3) from 0.001 to 1000/Liter.
      REAL, DIMENSION(ntb_IN), PARAMETER, PRIVATE:: &
      Nt_IN = (/1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0, &
               1.e1,2.e1,3.e1,4.e1,5.e1,6.e1,7.e1,8.e1,9.e1, &
               1.e2,2.e2,3.e2,4.e2,5.e2,6.e2,7.e2,8.e2,9.e2, &
               1.e3,2.e3,3.e3,4.e3,5.e3,6.e3,7.e3,8.e3,9.e3, &
               1.e4,2.e4,3.e4,4.e4,5.e4,6.e4,7.e4,8.e4,9.e4, &
               1.e5,2.e5,3.e5,4.e5,5.e5,6.e5,7.e5,8.e5,9.e5, &
               1.e6/)

!..For snow moments conversions (from Field et al. 2005)
      REAL, DIMENSION(10), PARAMETER, PRIVATE:: &
      sa = (/ 5.065339, -0.062659, -3.032362, 0.029469, -0.000285, &
              0.31255,   0.000204,  0.003199, 0.0,      -0.015952/)
      REAL, DIMENSION(10), PARAMETER, PRIVATE:: &
      sb = (/ 0.476221, -0.015896,  0.165977, 0.007468, -0.000141, &
              0.060366,  0.000079,  0.000594, 0.0,      -0.003577/)

!..Temperatures (5 C interval 0 to -40) used in lookup tables.
      REAL, DIMENSION(ntb_t), PARAMETER, PRIVATE:: &
      Tc = (/-0.01, -5., -10., -15., -20., -25., -30., -35., -40./)

!..Lookup tables for various accretion/collection terms.
!.. ntb_x refers to the number of elements for rain, snow, graupel,
!.. and temperature array indices.  Variables beginning with t-p/c/m/n
!.. represent lookup tables.  Save compile-time memory by making
!.. allocatable (2009Jun12, J. Michalakes).
      INTEGER, PARAMETER, PRIVATE:: R8SIZE = 8
      INTEGER, PARAMETER, PRIVATE:: R4SIZE = 4
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:,:,:)::           &
                tcg_racg, tmr_racg, tcr_gacr,                           & ! tmg_gacr
                tnr_racg, tnr_gacr
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:,:)::             &
                tcs_racs1, tmr_racs1, tcs_racs2, tmr_racs2,             &
                tcr_sacr1, tms_sacr1, tcr_sacr2, tms_sacr2,             &
                tnr_racs1, tnr_racs2, tnr_sacr1, tnr_sacr2
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:,:)::             &
                tpi_qcfz, tni_qcfz
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:,:)::             &
                tpi_qrfz, tpg_qrfz, tni_qrfz, tnr_qrfz
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:)::                 &
                tps_iaus, tni_iaus, tpi_ide
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:):: t_Efrw
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:):: t_Efsw
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:):: tnr_rev
      REAL (KIND=R8SIZE), ALLOCATABLE, DIMENSION(:,:,:)::               &
                tpc_wev, tnc_wev
      REAL (KIND=R4SIZE), ALLOCATABLE, DIMENSION(:,:,:,:,:):: tnccn_act

!..Variables holding a bunch of exponents and gamma values (cloud water,
!.. cloud ice, rain, snow, then graupel).
      REAL, DIMENSION(5,15), PRIVATE:: cce, ccg
      REAL, DIMENSION(15), PRIVATE::  ocg1, ocg2
      REAL, DIMENSION(7), PRIVATE:: cie, cig
      REAL, PRIVATE:: oig1, oig2, obmi
      REAL, DIMENSION(13), PRIVATE:: cre, crg
      REAL, PRIVATE:: ore1, org1, org2, org3, obmr
      REAL, DIMENSION(17), PRIVATE:: cse, csg
      REAL, PRIVATE:: oams, obms, ocms
      REAL, DIMENSION(12,NRHG), PRIVATE:: cge, cgg
      REAL, PRIVATE:: oge1, ogg1, ogg2, ogg3, obmg
      REAL, DIMENSION(NRHG), PRIVATE:: oamg, ocmg

!..Declaration of precomputed constants in various rate eqns.
      REAL:: t1_qr_qc, t1_qr_qi, t2_qr_qi, t1_qg_qc, t1_qs_qc, t1_qs_qi
      REAL:: t1_qr_ev, t2_qr_ev
      REAL:: t1_qs_sd, t2_qs_sd, t1_qg_sd, t2_qg_sd
      REAL:: t1_qs_me, t2_qs_me, t1_qg_me, t2_qg_me

!+---+
!+---+-----------------------------------------------------------------+
!..END DECLARATIONS
!+---+-----------------------------------------------------------------+
!+---+
!ctrlL

#ifdef WRF_GPU
!.. GPU port: device copies of all module variables (filled at the end of thompson_init)
      INTEGER, PARAMETER:: KTGPU = 34   ! max vertical levels (kte) of the device column routine (local memory ~ KTGPU)
      INTEGER:: th_probe = 0   ! WRF_GPU_THPROBE=N (timing only, results invalid): return after phase N of mp_thompson
!$acc declare create(th_probe)
      ! set by solve_em before each microphysics call (WRF_GPU_RELAZY, default on): the effective radii are not needed
      ! from this call - no radiation within the next two step starts, no restart write, no solar diagnostics
      LOGICAL:: mp_re_skip = .FALSE.
!$acc declare create(is_aerosol_aware,is_hail_aware,rho_s,dimNRHG,mu_c,av_g,bv_g,Sc3)
!$acc declare create(D0i,xm0s,xm0g,nic1,nic2,nii2,nii3,nir2)
!$acc declare create(nir3,nis2,nig2,nig3,niIN2,xDx,Dc,dtc)
!$acc declare create(Di,dti,Dr,dtr,Ds,dts,Dg,dtg)
!$acc declare create(t_Nc,tcg_racg,tmr_racg,tcr_gacr,tnr_racg,tnr_gacr,tcs_racs1,tmr_racs1)
!$acc declare create(tcs_racs2,tmr_racs2,tcr_sacr1,tms_sacr1,tcr_sacr2,tms_sacr2,tnr_racs1,tnr_racs2)
!$acc declare create(tnr_sacr1,tnr_sacr2,tpi_qcfz,tni_qcfz,tpi_qrfz,tpg_qrfz,tni_qrfz,tnr_qrfz)
!$acc declare create(tps_iaus,tni_iaus,tpi_ide,t_Efrw,t_Efsw,tnr_rev,tpc_wev,tnc_wev)
!$acc declare create(tnccn_act,cce,ccg,ocg1,ocg2,cie,cig,oig1)
!$acc declare create(oig2,obmi,cre,crg,ore1,org1,org2,org3)
!$acc declare create(obmr,cse,csg,oams,obms,ocms,cge,cgg)
!$acc declare create(oge1,ogg1,ogg2,ogg3,obmg,oamg,ocmg,t1_qr_qc)
!$acc declare create(t1_qr_qi,t2_qr_qi,t1_qg_qc,t1_qs_qc,t1_qs_qi,t1_qr_ev,t2_qr_ev,t1_qs_sd)
!$acc declare create(t2_qs_sd,t1_qg_sd,t2_qg_sd,t1_qs_me,t2_qs_me,t1_qg_me,t2_qg_me)
#endif
#ifdef WRF_GPU
!.. WRF_GPU_THLEV band scratch (module, device-resident; allocated by thlev_alloc)
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_tten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qvten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qcten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qiten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qrten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qsten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qgten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qbten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_niten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nrten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ncten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ngten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nwfaten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nifaten
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nbcaten
      DOUBLE PRECISION, DIMENSION(:,:,:), ALLOCATABLE:: thb_prr_sml
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_temp
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rc
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ri
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rr
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rs
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rg
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rb
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ni
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nr
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nc
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ng
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rho
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_rhof
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_visco
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_lvap
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ocp
      DOUBLE PRECISION, DIMENSION(:,:,:), ALLOCATABLE:: thb_ilamg
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_mvd_r
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_mvd_g
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_smob
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_smoc
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_vts_boost
      INTEGER, DIMENSION(:,:,:), ALLOCATABLE:: thb_idx_bg
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_l_qc
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_l_qi
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_l_qr
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_l_qs
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_l_qg
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qv1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qc1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qi1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qr1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qs1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qg1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_qb1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ni1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nr1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nc1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_ng1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nwfa1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nifa1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nbca1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_t1d
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_w1d
      LOGICAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_nm
      INTEGER, DIMENSION(:,:,:), ALLOCATABLE:: thb_km
      LOGICAL, DIMENSION(:,:), ALLOCATABLE:: thb_nmc
      INTEGER, DIMENSION(:,:), ALLOCATABLE:: thb_kmc
      REAL, DIMENSION(:,:,:), ALLOCATABLE:: thb_vtq, thb_vtn
      INTEGER, DIMENSION(:,:), ALLOCATABLE:: thb_ksed
      REAL, DIMENSION(:,:), ALLOCATABLE:: thb_onst, thb_ppt
!$acc declare create(thb_vtq, thb_vtn, thb_ksed, thb_onst, thb_ppt)
!$acc declare create(thb_tten,thb_qvten,thb_qcten,thb_qiten,thb_qrten,thb_qsten,thb_qgten,thb_qbten,thb_niten,thb_nrten,thb_ncten,thb_ngten,thb_nwfaten,thb_nifaten,thb_nbcaten,thb_prr_sml,thb_temp,thb_rc,thb_ri,thb_rr,thb_rs,thb_rg,thb_rb,thb_ni,thb_nr,thb_nc,thb_ng,thb_rho,thb_rhof,thb_visco,thb_lvap,thb_ocp,thb_ilamg,thb_mvd_r,thb_mvd_g,thb_smob,thb_smoc,thb_vts_boost,thb_idx_bg,thb_l_qc,thb_l_qi,thb_l_qr,thb_l_qs,thb_l_qg,thb_qv1d,thb_qc1d,thb_qi1d,thb_qr1d,thb_qs1d,thb_qg1d,thb_qb1d,thb_ni1d,thb_nr1d,thb_nc1d,thb_ng1d,thb_nwfa1d,thb_nifa1d,thb_nbca1d,thb_t1d,thb_w1d,thb_nm,thb_km,thb_nmc,thb_kmc)
      INTEGER, SAVE:: thlev_on = -1, thbsz_ni = 0, thbsz_nk = 0, thbsz_nj = 0
      INTEGER, SAVE:: thband_max = -1
      INTEGER, SAVE:: thsplit_on = -1
#endif
#ifdef WRF_GPU
!.. GPU: Thompson's column tail kernel (thom_tail/thom_fin and the write-back) lives in the submodule
!.. module_mp_thompson_tail (phys/module_mp_thompson_tail.F) so it gets its own register cap (THOMPSON_TAIL_REGCAP):
!.. it runs best at 128 registers while the level kernels want 255 (2026-11-10 nsys: tail 20.7 vs 26.0 ms, level
!.. kernel 12.0 vs 18.4 ms on the cloudy 1000x380 rank)
      INTERFACE
      MODULE SUBROUTINE thom_tail_band( gpu_aer, gpu_wif, gpu_do_refl, gpu_do_re, kediagloc, thb0, thb1, dt,      &
                           qv, qc, qr, qi, qs, qg, ni, nr, th, pii, p, dz,                       &
                           RAINNC, RAINNCV, SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV, SR,            &
                           refl_10cm, re_cloud, re_ice, re_snow, mp_li, mp_lj, nmp,               &
                           ims, ime, jms, jme, kms, kme, kts, kte )
      INTEGER, INTENT(IN):: gpu_aer, gpu_wif, kediagloc, thb0, thb1, nmp
      LOGICAL, INTENT(IN):: gpu_do_refl, gpu_do_re
      REAL, INTENT(IN):: dt
      INTEGER, INTENT(IN):: ims, ime, jms, jme, kms, kme, kts, kte
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: qv, qc, qr, qi, qs, qg, ni, nr, th
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN):: pii, p, dz
      REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT):: RAINNC, RAINNCV, SR
      REAL, DIMENSION(ims:ime, jms:jme), OPTIONAL, INTENT(INOUT):: SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: refl_10cm, re_cloud, re_ice, re_snow
      INTEGER, DIMENSION(nmp), INTENT(IN):: mp_li, mp_lj
      END SUBROUTINE thom_tail_band
      END INTERFACE
#endif
      CONTAINS

      SUBROUTINE thompson_init(hgt, orho, nwfa2d, nbca2d, ng,           &
                          nwfa, nifa, nbca, wif_input_opt, frc_urb2d,   &
                          dx, dy, is_start,                             &
                          ids, ide, jds, jde, kds, kde,                 &
                          ims, ime, jms, jme, kms, kme,                 &
                          its, ite, jts, jte, kts, kte)

      IMPLICIT NONE

      INTEGER, INTENT(IN):: ids,ide, jds,jde, kds,kde, &
                            ims,ime, jms,jme, kms,kme, &
                            its,ite, jts,jte, kts,kte
      REAL, DIMENSION(ims:ime,kms:kme,jms:jme), INTENT(IN):: hgt

!..OPTIONAL variables that control application of hail-aware scheme
      REAL, DIMENSION(ims:ime,kms:kme,jms:jme), OPTIONAL, INTENT(INOUT) :: ng

!..OPTIONAL variables that control application of aerosol-aware scheme

      REAL, DIMENSION(ims:ime,kms:kme,jms:jme), OPTIONAL, INTENT(INOUT) :: nwfa, nifa, nbca
      REAL, DIMENSION(ims:ime,jms:jme), OPTIONAL, INTENT(INOUT) :: nwfa2d, nbca2d
      REAL, DIMENSION(ims:ime,kms:kme,jms:jme), OPTIONAL, INTENT(IN) :: orho
      REAL, DIMENSION(ims:ime,jms:jme), OPTIONAL, INTENT(IN) :: frc_urb2d
      REAL, OPTIONAL, INTENT(IN) :: DX, DY
      LOGICAL, OPTIONAL, INTENT(IN) :: is_start
      INTEGER, OPTIONAL, INTENT(IN) :: wif_input_opt
      CHARACTER*256:: mp_debug


      INTEGER:: i, j, k, l, m, n
      REAL:: h_01, niIN3, niCCN3, niBC3, max_test, z1
      LOGICAL:: micro_init, has_CCN, has_IN

!+---+

      if (PRESENT(ng)) then
         is_hail_aware = .TRUE.
         dimNRHG = NRHG
      else
         av_g(idx_bg1) = av_g_old
         bv_g(idx_bg1) = bv_g_old
         dimNRHG = NRHG1
      endif

      is_aerosol_aware = .FALSE.
      micro_init = .FALSE.
      has_CCN    = .FALSE.
      has_IN     = .FALSE.

      write(mp_debug,*) ' DEBUG  checking column of hgt ', its+1,jts+1
      CALL wrf_debug(250, mp_debug)
      do k = kts, kte
         write(mp_debug,*) ' DEBUGT  k, hgt = ', k, hgt(its+1,k,jts+1)
         CALL wrf_debug(250, mp_debug)
      enddo

      if (PRESENT(nwfa2d) .AND. PRESENT(nwfa) .AND. PRESENT(nifa)) is_aerosol_aware = .TRUE.

      if (is_aerosol_aware) then

!..Check for existing aerosol data, both CCN and IN aerosols.  If missing
!.. fill in just a basic vertical profile, somewhat boundary-layer following.

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
      max_test = wrf_dm_max_real ( MAXVAL(nwfa(its:ite-1,:,jts:jte-1)) )
#else
      max_test = MAXVAL ( nwfa(its:ite-1,:,jts:jte-1) )
#endif

      if (max_test .lt. eps) then
         write(mp_debug,*) ' Apparently there are no initial CCN aerosols.'
         CALL wrf_debug(100, mp_debug)
         write(mp_debug,*) '   checked column at point (i,j) = ', its,jts
         CALL wrf_debug(100, mp_debug)
         do j = jts, min(jde-1,jte)
         do i = its, min(ide-1,ite)
            if (hgt(i,1,j).le.1000.0) then
               h_01 = 0.8
            elseif (hgt(i,1,j).ge.2500.0) then
               h_01 = 0.01
            else
               h_01 = 0.8*cos(hgt(i,1,j)*0.001 - 1.0)
            endif
            niCCN3 = -1.0*ALOG(naCCN1/naCCN0)/h_01
            nwfa(i,1,j) = naCCN1+naCCN0*exp(-((hgt(i,2,j)-hgt(i,1,j))/1000.)*niCCN3)
            z1=hgt(i,2,j)-hgt(i,1,j)
            nwfa2d(i,j) = nwfa(i,1,j) * 0.000196 * (50./z1)
            do k = 2, kte
               nwfa(i,k,j) = naCCN1+naCCN0*exp(-((hgt(i,k,j)-hgt(i,1,j))/1000.)*niCCN3)
            enddo
         enddo
         enddo
      else
         has_CCN    = .TRUE.
         write(mp_debug,*) ' Apparently initial CCN aerosols are present.'
         CALL wrf_debug(100, mp_debug)
         write(mp_debug,*) '   column sum at point (i,j) = ', its,jts, SUM(nwfa(its,:,jts))
         CALL wrf_debug(100, mp_debug)
      endif


#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
      max_test = wrf_dm_max_real ( MAXVAL(nifa(its:ite-1,:,jts:jte-1)) )
#else
      max_test = MAXVAL ( nifa(its:ite-1,:,jts:jte-1) )
#endif

      if (max_test .lt. eps) then
         write(mp_debug,*) ' Apparently there are no initial IN aerosols.'
         CALL wrf_debug(100, mp_debug)
         write(mp_debug,*) '   checked column at point (i,j) = ', its,jts
         CALL wrf_debug(100, mp_debug)
         do j = jts, min(jde-1,jte)
         do i = its, min(ide-1,ite)
            if (hgt(i,1,j).le.1000.0) then
               h_01 = 0.8
            elseif (hgt(i,1,j).ge.2500.0) then
               h_01 = 0.01
            else
               h_01 = 0.8*cos(hgt(i,1,j)*0.001 - 1.0)
            endif
            niIN3 = -1.0*ALOG(naIN1/naIN0)/h_01
            nifa(i,1,j) = naIN1+naIN0*exp(-((hgt(i,2,j)-hgt(i,1,j))/1000.)*niIN3)
            do k = 2, kte
               nifa(i,k,j) = naIN1+naIN0*exp(-((hgt(i,k,j)-hgt(i,1,j))/1000.)*niIN3)
            enddo
         enddo
         enddo
      else
         has_IN     = .TRUE.
         write(mp_debug,*) ' Apparently initial IN aerosols are present.'
         CALL wrf_debug(100, mp_debug)
         write(mp_debug,*) '   column sum at point (i,j) = ', its,jts, SUM(nifa(its,:,jts))
         CALL wrf_debug(100, mp_debug)
      endif


      if ( wif_input_opt .eq. 2 ) then

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
         max_test = wrf_dm_max_real ( MAXVAL(nbca(its:ite-1,:,jts:jte-1)) )
#else
         max_test = MAXVAL ( nbca(its:ite-1,:,jts:jte-1) )
#endif

         if (max_test .lt. eps) then
            write(mp_debug,*) ' Apparently there are no initial BC aerosols.'
            CALL wrf_debug(100, mp_debug)
            write(mp_debug,*) '   checked column at point (i,j) = ', its,jts
            CALL wrf_debug(100, mp_debug)
            do j = jts, min(jde-1,jte)
            do i = its, min(ide-1,ite)
               if (hgt(i,1,j).le.1000.0) then
                  h_01 = 0.8
               elseif (hgt(i,1,j).ge.2500.0) then
                  h_01 = 0.01
               else
                  h_01 = 0.8*cos(hgt(i,1,j)*0.001 - 1.0)
               endif
               niBC3 = -1.0*ALOG(naBC1/naBC0)/h_01
               nbca(i,1,j) = naBC1+naBC0*exp(-((hgt(i,2,j)-hgt(i,1,j))/1000.)*niBC3)
               z1=hgt(i,2,j)-hgt(i,1,j)
               nbca2d(i,j) = nbca(i,1,j) * 0.000098 * (50./z1) * (1. + frc_urb2d(i,j))
               do k = 2, kte
                  nbca(i,k,j) = naBC1+naBC0*exp(-((hgt(i,k,j)-hgt(i,1,j))/1000.)*niBC3)
               enddo
            enddo
            enddo
         else
            write(mp_debug,*) ' Apparently initial BC aerosols are present.'
            CALL wrf_debug(100, mp_debug)
            write(mp_debug,*) '   column sum at point (i,j) = ', its,jts, SUM(nbca(its,:,jts))
            CALL wrf_debug(100, mp_debug)
         endif

      endif

      endif


!..Allocate space for lookup tables (J. Michalakes 2009Jun08).

      if (.NOT. ALLOCATED(tcg_racg) ) then
         ALLOCATE(tcg_racg(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))
         micro_init = .TRUE.
      endif

      if (.NOT. ALLOCATED(tmr_racg)) ALLOCATE(tmr_racg(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tcr_gacr)) ALLOCATE(tcr_gacr(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))
      ! if (.NOT. ALLOCATED(tmg_gacr)) ALLOCATE(tmg_gacr(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_racg)) ALLOCATE(tnr_racg(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_gacr)) ALLOCATE(tnr_gacr(ntb_g1,ntb_g,dimNRHG,ntb_r1,ntb_r))

      if (.NOT. ALLOCATED(tcs_racs1)) ALLOCATE(tcs_racs1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tmr_racs1)) ALLOCATE(tmr_racs1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tcs_racs2)) ALLOCATE(tcs_racs2(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tmr_racs2)) ALLOCATE(tmr_racs2(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tcr_sacr1)) ALLOCATE(tcr_sacr1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tms_sacr1)) ALLOCATE(tms_sacr1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tcr_sacr2)) ALLOCATE(tcr_sacr2(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tms_sacr2)) ALLOCATE(tms_sacr2(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_racs1)) ALLOCATE(tnr_racs1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_racs2)) ALLOCATE(tnr_racs2(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_sacr1)) ALLOCATE(tnr_sacr1(ntb_s,ntb_t,ntb_r1,ntb_r))
      if (.NOT. ALLOCATED(tnr_sacr2)) ALLOCATE(tnr_sacr2(ntb_s,ntb_t,ntb_r1,ntb_r))

      if (.NOT. ALLOCATED(tpi_qcfz)) ALLOCATE(tpi_qcfz(ntb_c,nbc,45,ntb_IN))
      if (.NOT. ALLOCATED(tni_qcfz)) ALLOCATE(tni_qcfz(ntb_c,nbc,45,ntb_IN))

      if (.NOT. ALLOCATED(tpi_qrfz)) ALLOCATE(tpi_qrfz(ntb_r,ntb_r1,45,ntb_IN))
      if (.NOT. ALLOCATED(tpg_qrfz)) ALLOCATE(tpg_qrfz(ntb_r,ntb_r1,45,ntb_IN))
      if (.NOT. ALLOCATED(tni_qrfz)) ALLOCATE(tni_qrfz(ntb_r,ntb_r1,45,ntb_IN))
      if (.NOT. ALLOCATED(tnr_qrfz)) ALLOCATE(tnr_qrfz(ntb_r,ntb_r1,45,ntb_IN))

      if (.NOT. ALLOCATED(tps_iaus)) ALLOCATE(tps_iaus(ntb_i,ntb_i1))
      if (.NOT. ALLOCATED(tni_iaus)) ALLOCATE(tni_iaus(ntb_i,ntb_i1))
      if (.NOT. ALLOCATED(tpi_ide)) ALLOCATE(tpi_ide(ntb_i,ntb_i1))

      if (.NOT. ALLOCATED(t_Efrw)) ALLOCATE(t_Efrw(nbr,nbc))
      if (.NOT. ALLOCATED(t_Efsw)) ALLOCATE(t_Efsw(nbs,nbc))

      if (.NOT. ALLOCATED(tnr_rev)) ALLOCATE(tnr_rev(nbr, ntb_r1, ntb_r))
      if (.NOT. ALLOCATED(tpc_wev)) ALLOCATE(tpc_wev(nbc,ntb_c,nbc))
      if (.NOT. ALLOCATED(tnc_wev)) ALLOCATE(tnc_wev(nbc,ntb_c,nbc))

      if (.NOT. ALLOCATED(tnccn_act))                                   &
            ALLOCATE(tnccn_act(ntb_arc,ntb_arw,ntb_art,ntb_arr,ntb_ark))

      if (micro_init) then

!..From Martin et al. (1994), assign gamma shape parameter mu for cloud
!.. drops according to general dispersion characteristics (disp=~0.25
!.. for Maritime and 0.45 for Continental).
!.. disp=SQRT((mu+2)/(mu+1) - 1) so mu varies from 15 for Maritime
!.. to 2 for really dirty air.  This not used in 2-moment cloud water
!.. scheme and nu_c used instead and varies from 2 to 15 (integer-only).
      mu_c = MIN(15., (1000.E6/Nt_c + 2.))

!..Schmidt number to one-third used numerous times.
      Sc3 = Sc**(1./3.)

!..Compute min ice diam from mass, min snow/graupel mass from diam.
      D0i = (xm0i/am_i)**(1./bm_i)
      xm0s = am_s * D0s**bm_s
      xm0g = am_g(NRHG) * D0g**bm_g

!..These constants various exponents and gamma() assoc with cloud,
!.. rain, snow, and graupel.
      do n = 1, 15
         cce(1,n) = n + 1.
         cce(2,n) = bm_r + n + 1.
         cce(3,n) = bm_r + n + 4.
         cce(4,n) = n + bv_c + 1.
         cce(5,n) = bm_r + n + bv_c + 1.
         ccg(1,n) = WGAMMA(cce(1,n))
         ccg(2,n) = WGAMMA(cce(2,n))
         ccg(3,n) = WGAMMA(cce(3,n))
         ccg(4,n) = WGAMMA(cce(4,n))
         ccg(5,n) = WGAMMA(cce(5,n))
         ocg1(n) = 1./ccg(1,n)
         ocg2(n) = 1./ccg(2,n)
      enddo

      cie(1) = mu_i + 1.
      cie(2) = bm_i + mu_i + 1.
      cie(3) = bm_i + mu_i + bv_i + 1.
      cie(4) = mu_i + bv_i + 1.
      cie(5) = mu_i + 2.
      cie(6) = bm_i*0.5 + mu_i + bv_i + 1.
      cie(7) = bm_i*0.5 + mu_i + 1.
      cig(1) = WGAMMA(cie(1))
      cig(2) = WGAMMA(cie(2))
      cig(3) = WGAMMA(cie(3))
      cig(4) = WGAMMA(cie(4))
      cig(5) = WGAMMA(cie(5))
      cig(6) = WGAMMA(cie(6))
      cig(7) = WGAMMA(cie(7))
      oig1 = 1./cig(1)
      oig2 = 1./cig(2)
      obmi = 1./bm_i

      cre(1) = bm_r + 1.
      cre(2) = mu_r + 1.
      cre(3) = bm_r + mu_r + 1.
      cre(4) = bm_r*2. + mu_r + 1.
      cre(5) = mu_r + bv_r + 1.
      cre(6) = bm_r + mu_r + bv_r + 1.
      cre(7) = bm_r*0.5 + mu_r + bv_r + 1.
      cre(8) = bm_r + mu_r + bv_r + 3.
      cre(9) = mu_r + bv_r + 3.
      cre(10) = mu_r + 2.
      cre(11) = 0.5*(bv_r + 5. + 2.*mu_r)
      cre(12) = bm_r*0.5 + mu_r + 1.
      cre(13) = bm_r*2. + mu_r + bv_r + 1.
      do n = 1, 13
         crg(n) = WGAMMA(cre(n))
      enddo
      obmr = 1./bm_r
      ore1 = 1./cre(1)
      org1 = 1./crg(1)
      org2 = 1./crg(2)
      org3 = 1./crg(3)

      cse(1) = bm_s + 1.
      cse(2) = bm_s + 2.
      cse(3) = bm_s*2.
      cse(4) = bm_s + bv_s + 1.
      cse(5) = bm_s*2. + bv_s + 1.
      cse(6) = bm_s*2. + 1.
      cse(7) = bm_s + mu_s + 1.
      cse(8) = bm_s + mu_s + 2.
      cse(9) = bm_s + mu_s + 3.
      cse(10) = bm_s + mu_s + bv_s + 1.
      cse(11) = bm_s*2. + mu_s + bv_s + 1.
      cse(12) = bm_s*2. + mu_s + 1.
      cse(13) = bv_s + 2.
      cse(14) = bm_s + bv_s
      cse(15) = mu_s + 1.
      cse(16) = 1.0 + (1.0 + bv_s)/2.
      cse(17) = bm_s + bv_s + 2.
      do n = 1, 17
         csg(n) = WGAMMA(cse(n))
      enddo
      oams = 1./am_s
      obms = 1./bm_s
      ocms = oams**obms

      cge(1,:) = bm_g + 1.
      cge(2,:) = mu_g + 1.
      cge(3,:) = bm_g + mu_g + 1.
      cge(4,:) = bm_g*2. + mu_g + 1.
      cge(10,:) = mu_g + 2.
      cge(12,:) = bm_g*0.5 + mu_g + 1.
      do m = 1, NRHG
         cge(5,m) = bm_g*2. + mu_g + bv_g(m) + 1.
         cge(6,m) = bm_g + mu_g + bv_g(m) + 1.
         cge(7,m) = bm_g*0.5 + mu_g + bv_g(m) + 1.
         cge(8,m) = mu_g + bv_g(m) + 1.                                  ! not used
         cge(9,m) = mu_g + bv_g(m) + 3.
         cge(11,m) = 0.5*(bv_g(m) + 5. + 2.*mu_g)
      enddo
      do m = 1, NRHG
      do n = 1, 12
         cgg(n,m) = WGAMMA(cge(n,m))
      enddo
      enddo
      oamg = 1./am_g
      obmg = 1./bm_g
      do m = 1, NRHG
         oamg(m) = 1./am_g(m)
         ocmg(m) = oamg(m)**obmg
      enddo
      oge1 = 1./cge(1,1)
      ogg1 = 1./cgg(1,1)
      ogg2 = 1./cgg(2,1)
      ogg3 = 1./cgg(3,1)

!+---+-----------------------------------------------------------------+
!..Simplify various rate eqns the best we can now.
!+---+-----------------------------------------------------------------+

!..Rain collecting cloud water and cloud ice
      t1_qr_qc = PI*.25*av_r * crg(9)
      t1_qr_qi = PI*.25*av_r * crg(9)
      t2_qr_qi = PI*.25*am_r*av_r * crg(8)

!..Graupel collecting cloud water
!     t1_qg_qc = PI*.25*av_g * cgg(9)

!..Snow collecting cloud water
      t1_qs_qc = PI*.25*av_s

!..Snow collecting cloud ice
      t1_qs_qi = PI*.25*av_s

!..Evaporation of rain; ignore depositional growth of rain.
      t1_qr_ev = 0.78 * crg(10)
      t2_qr_ev = 0.308*Sc3*SQRT(av_r) * crg(11)

!..Sublimation/depositional growth of snow
      t1_qs_sd = 0.86
      t2_qs_sd = 0.28*Sc3*SQRT(av_s)

!..Melting of snow
      t1_qs_me = PI*4.*C_sqrd*olfus * 0.86
      t2_qs_me = PI*4.*C_sqrd*olfus * 0.28*Sc3*SQRT(av_s)

!..Sublimation/depositional growth of graupel
      t1_qg_sd = 0.86 * cgg(10,1)
!     t2_qg_sd = 0.28*Sc3*SQRT(av_g) * cgg(11)

!..Melting of graupel
      t1_qg_me = PI*4.*C_cube*olfus * 0.86 * cgg(10,1)
!     t2_qg_me = PI*4.*C_cube*olfus * 0.28*Sc3*SQRT(av_g) * cgg(11)

!..Constants for helping find lookup table indexes.
      nic2 = NINT(ALOG10(r_c(1)))
      nii2 = NINT(ALOG10(r_i(1)))
      nii3 = NINT(ALOG10(Nt_i(1)))
      nir2 = NINT(ALOG10(r_r(1)))
      nir3 = NINT(ALOG10(N0r_exp(1)))
      nis2 = NINT(ALOG10(r_s(1)))
      nig2 = NINT(ALOG10(r_g(1)))
      nig3 = NINT(ALOG10(N0g_exp(1)))
      niIN2 = NINT(ALOG10(Nt_IN(1)))

!..Create bins of cloud water (from min diameter up to 100 microns).
      Dc(1) = D0c*1.0d0
      dtc(1) = D0c*1.0d0
      do n = 2, nbc
         Dc(n) = Dc(n-1) + 1.0D-6
         dtc(n) = (Dc(n) - Dc(n-1))
      enddo

!..Create bins of cloud ice (from min diameter up to 5x min snow size).
      xDx(1) = D0i*1.0d0
      xDx(nbi+1) = 2.0d0*D0s
      do n = 2, nbi
         xDx(n) = DEXP(DFLOAT(n-1)/DFLOAT(nbi) &
                  *DLOG(xDx(nbi+1)/xDx(1)) +DLOG(xDx(1)))
      enddo
      do n = 1, nbi
         Di(n) = DSQRT(xDx(n)*xDx(n+1))
         dti(n) = xDx(n+1) - xDx(n)
      enddo

!..Create bins of rain (from min diameter up to 5 mm).
      xDx(1) = D0r*1.0d0
      xDx(nbr+1) = 0.005d0
      do n = 2, nbr
         xDx(n) = DEXP(DFLOAT(n-1)/DFLOAT(nbr) &
                  *DLOG(xDx(nbr+1)/xDx(1)) +DLOG(xDx(1)))
      enddo
      do n = 1, nbr
         Dr(n) = DSQRT(xDx(n)*xDx(n+1))
         dtr(n) = xDx(n+1) - xDx(n)
      enddo

!..Create bins of snow (from min diameter up to 2 cm).
      xDx(1) = D0s*1.0d0
      xDx(nbs+1) = 0.02d0
      do n = 2, nbs
         xDx(n) = DEXP(DFLOAT(n-1)/DFLOAT(nbs) &
                  *DLOG(xDx(nbs+1)/xDx(1)) +DLOG(xDx(1)))
      enddo
      do n = 1, nbs
         Ds(n) = DSQRT(xDx(n)*xDx(n+1))
         dts(n) = xDx(n+1) - xDx(n)
      enddo

!..Create bins of graupel (from min diameter up to 5 cm).
      xDx(1) = D0g*1.0d0
      xDx(nbg+1) = 0.05d0
      do n = 2, nbg
         xDx(n) = DEXP(DFLOAT(n-1)/DFLOAT(nbg) &
                  *DLOG(xDx(nbg+1)/xDx(1)) +DLOG(xDx(1)))
      enddo
      do n = 1, nbg
         Dg(n) = DSQRT(xDx(n)*xDx(n+1))
         dtg(n) = xDx(n+1) - xDx(n)
      enddo

!..Create bins of cloud droplet number concentration (1 to 3000 per cc).
      xDx(1) = 1.0d0
      xDx(nbc+1) = 3000.0d0
      do n = 2, nbc
         xDx(n) = DEXP(DFLOAT(n-1)/DFLOAT(nbc)                          &
                  *DLOG(xDx(nbc+1)/xDx(1)) +DLOG(xDx(1)))
      enddo
      do n = 1, nbc
         t_Nc(n) = DSQRT(xDx(n)*xDx(n+1)) * 1.D6
      enddo
      nic1 = DLOG(t_Nc(nbc)/t_Nc(1))

!+---+-----------------------------------------------------------------+
!..Create lookup tables for most costly calculations.
!+---+-----------------------------------------------------------------+

      do m = 1, ntb_r
         do k = 1, ntb_r1
            do n = 1, dimNRHG
            do j = 1, ntb_g
               do i = 1, ntb_g1
                     tcg_racg(i,j,n,k,m) = 0.0d0
                     tmr_racg(i,j,n,k,m) = 0.0d0
                     tcr_gacr(i,j,n,k,m) = 0.0d0
                     !tmg_gacr(i,j,n,k,m) = 0.0d0
                     tnr_racg(i,j,n,k,m) = 0.0d0
                     tnr_gacr(i,j,n,k,m) = 0.0d0
                  enddo
               enddo
            enddo
         enddo
      enddo

      do m = 1, ntb_r
         do k = 1, ntb_r1
            do j = 1, ntb_t
               do i = 1, ntb_s
                  tcs_racs1(i,j,k,m) = 0.0d0
                  tmr_racs1(i,j,k,m) = 0.0d0
                  tcs_racs2(i,j,k,m) = 0.0d0
                  tmr_racs2(i,j,k,m) = 0.0d0
                  tcr_sacr1(i,j,k,m) = 0.0d0
                  tms_sacr1(i,j,k,m) = 0.0d0
                  tcr_sacr2(i,j,k,m) = 0.0d0
                  tms_sacr2(i,j,k,m) = 0.0d0
                  tnr_racs1(i,j,k,m) = 0.0d0
                  tnr_racs2(i,j,k,m) = 0.0d0
                  tnr_sacr1(i,j,k,m) = 0.0d0
                  tnr_sacr2(i,j,k,m) = 0.0d0
               enddo
            enddo
         enddo
      enddo

      do m = 1, ntb_IN
         do k = 1, 45
            do j = 1, ntb_r1
               do i = 1, ntb_r
                  tpi_qrfz(i,j,k,m) = 0.0d0
                  tni_qrfz(i,j,k,m) = 0.0d0
                  tpg_qrfz(i,j,k,m) = 0.0d0
                  tnr_qrfz(i,j,k,m) = 0.0d0
               enddo
            enddo
            do j = 1, nbc
               do i = 1, ntb_c
                  tpi_qcfz(i,j,k,m) = 0.0d0
                  tni_qcfz(i,j,k,m) = 0.0d0
               enddo
            enddo
         enddo
      enddo

      do j = 1, ntb_i1
         do i = 1, ntb_i
            tps_iaus(i,j) = 0.0d0
            tni_iaus(i,j) = 0.0d0
            tpi_ide(i,j) = 0.0d0
         enddo
      enddo

      do j = 1, nbc
         do i = 1, nbr
            t_Efrw(i,j) = 0.0
         enddo
         do i = 1, nbs
            t_Efsw(i,j) = 0.0
         enddo
      enddo

      do k = 1, ntb_r
         do j = 1, ntb_r1
            do i = 1, nbr
               tnr_rev(i,j,k) = 0.0d0
            enddo
         enddo
      enddo

      do k = 1, nbc
         do j = 1, ntb_c
            do i = 1, nbc
               tpc_wev(i,j,k) = 0.0d0
               tnc_wev(i,j,k) = 0.0d0
            enddo
         enddo
      enddo

      do m = 1, ntb_ark
         do l = 1, ntb_arr
            do k = 1, ntb_art
               do j = 1, ntb_arw
                  do i = 1, ntb_arc
                     tnccn_act(i,j,k,l,m) = 1.0
                  enddo
               enddo
            enddo
         enddo
      enddo

      CALL wrf_debug(150, 'CREATING MICROPHYSICS LOOKUP TABLES ... ')
      WRITE (wrf_err_message, '(a, f5.2, a, f5.2, a, f5.2, a, f5.2)') &
          ' using: mu_c=',mu_c,' mu_i=',mu_i,' mu_r=',mu_r,' mu_g=',mu_g
      CALL wrf_debug(150, wrf_err_message)

!..Read a static file containing CCN activation of aerosols. The
!.. data were created from a parcel model by Feingold & Heymsfield with
!.. further changes by Eidhammer and Kriedenweis.
      if (is_aerosol_aware) then
         CALL wrf_debug(200, '  calling table_ccnAct routine')
         call table_ccnAct
      endif

!..Collision efficiency between rain/snow and cloud water.
      CALL wrf_debug(200, '  creating qc collision eff tables')
      call table_Efrw
      call table_Efsw

!..Drop evaporation.
      CALL wrf_debug(200, '  creating rain evap table')
      call table_dropEvap

!..Initialize various constants for computing radar reflectivity.
      xam_r = am_r
      xbm_r = bm_r
      xmu_r = mu_r
      xam_s = am_s
      xbm_s = bm_s
      xmu_s = mu_s
      xam_g = am_g(idx_bg1)
      xbm_g = bm_g
      xmu_g = mu_g
      call radar_init

      if (.not. iiwarm) then

!..Rain collecting graupel & graupel collecting rain.
      CALL wrf_debug(200, '  creating rain collecting graupel table')

         call qr_acr_qg(dimNRHG)

!..Rain collecting snow & snow collecting rain.
      CALL wrf_debug(200, '  creating rain collecting snow table')
      call qr_acr_qs

!..Cloud water and rain freezing (Bigg, 1953).
      CALL wrf_debug(200, '  creating freezing of water drops table')
      call freezeH2O

!..Conversion of some ice mass into snow category.
      CALL wrf_debug(200, '  creating ice converting to snow table')
      call qi_aut_qs

      endif

      CALL wrf_debug(150, ' ... DONE microphysical lookup tables')

      endif

#ifdef WRF_GPU
!$acc update device(is_aerosol_aware,is_hail_aware,rho_s,dimNRHG,mu_c,av_g,bv_g,Sc3)
!$acc update device(D0i,xm0s,xm0g,nic1,nic2,nii2,nii3,nir2)
!$acc update device(nir3,nis2,nig2,nig3,niIN2,xDx,Dc,dtc)
!$acc update device(Di,dti,Dr,dtr,Ds,dts,Dg,dtg)
!$acc update device(t_Nc,cce,ccg,ocg1,ocg2,cie,cig,oig1)
!$acc update device(oig2,obmi,cre,crg,ore1,org1,org2,org3)
!$acc update device(obmr,cse,csg,oams,obms,ocms,cge,cgg)
!$acc update device(oge1,ogg1,ogg2,ogg3,obmg,oamg,ocmg,t1_qr_qc)
!$acc update device(t1_qr_qi,t2_qr_qi,t1_qg_qc,t1_qs_qc,t1_qs_qi,t1_qr_ev,t2_qr_ev,t1_qs_sd)
!$acc update device(t2_qs_sd,t1_qg_sd,t2_qg_sd,t1_qs_me,t2_qs_me,t1_qg_me,t2_qg_me)
!$acc update device(tcg_racg) if(allocated(tcg_racg))
!$acc update device(tmr_racg) if(allocated(tmr_racg))
!$acc update device(tcr_gacr) if(allocated(tcr_gacr))
!$acc update device(tnr_racg) if(allocated(tnr_racg))
!$acc update device(tnr_gacr) if(allocated(tnr_gacr))
!$acc update device(tcs_racs1) if(allocated(tcs_racs1))
!$acc update device(tmr_racs1) if(allocated(tmr_racs1))
!$acc update device(tcs_racs2) if(allocated(tcs_racs2))
!$acc update device(tmr_racs2) if(allocated(tmr_racs2))
!$acc update device(tcr_sacr1) if(allocated(tcr_sacr1))
!$acc update device(tms_sacr1) if(allocated(tms_sacr1))
!$acc update device(tcr_sacr2) if(allocated(tcr_sacr2))
!$acc update device(tms_sacr2) if(allocated(tms_sacr2))
!$acc update device(tnr_racs1) if(allocated(tnr_racs1))
!$acc update device(tnr_racs2) if(allocated(tnr_racs2))
!$acc update device(tnr_sacr1) if(allocated(tnr_sacr1))
!$acc update device(tnr_sacr2) if(allocated(tnr_sacr2))
!$acc update device(tpi_qcfz) if(allocated(tpi_qcfz))
!$acc update device(tni_qcfz) if(allocated(tni_qcfz))
!$acc update device(tpi_qrfz) if(allocated(tpi_qrfz))
!$acc update device(tpg_qrfz) if(allocated(tpg_qrfz))
!$acc update device(tni_qrfz) if(allocated(tni_qrfz))
!$acc update device(tnr_qrfz) if(allocated(tnr_qrfz))
!$acc update device(tps_iaus) if(allocated(tps_iaus))
!$acc update device(tni_iaus) if(allocated(tni_iaus))
!$acc update device(tpi_ide) if(allocated(tpi_ide))
!$acc update device(t_Efrw) if(allocated(t_Efrw))
!$acc update device(t_Efsw) if(allocated(t_Efsw))
!$acc update device(tnr_rev) if(allocated(tnr_rev))
!$acc update device(tpc_wev) if(allocated(tpc_wev))
!$acc update device(tnc_wev) if(allocated(tnc_wev))
!$acc update device(tnccn_act) if(allocated(tnccn_act))
#endif
      END SUBROUTINE thompson_init
!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!..This is a wrapper routine designed to transfer values from 3D to 1D.
!+---+-----------------------------------------------------------------+
      SUBROUTINE mp_gt_driver(qv, qc, qr, qi, qs, qg, qb, ni, nr, nc, ng,&
                              nwfa, nifa, nbca, nwfa2d, nifa2d, nbca2d,  &
                              aer_init_opt, wif_input_opt,               &
                              th, pii, p, w, dz,                         &
                              dt_in, itimestep,                          &
                              RAINNC, RAINNCV, &
                              SNOWNC, SNOWNCV, &
                              GRAUPELNC, GRAUPELNCV, SR, &
#if ( WRF_CHEM == 1 )
                              wetscav_on, rainprod, evapprod, &
#endif
                              refl_10cm, diagflag, ke_diag, do_radar_ref,      &
                              re_cloud, re_ice, re_snow,              &
                              has_reqc, has_reqi, has_reqs,           &
                              ids,ide, jds,jde, kds,kde, &             ! domain dims
                              ims,ime, jms,jme, kms,kme, &             ! memory dims
                              its,ite, jts,jte, kts,kte)               ! tile dims

      implicit none

!..Subroutine arguments
      INTEGER, INTENT(IN):: ids,ide, jds,jde, kds,kde, &
                            ims,ime, jms,jme, kms,kme, &
                            its,ite, jts,jte, kts,kte
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: &
                          qv, qc, qr, qi, qs, qg, ni, nr, th
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), OPTIONAL, INTENT(INOUT):: &
                          nc, nwfa, nifa, nbca, qb, ng
      REAL, DIMENSION(ims:ime, jms:jme), OPTIONAL, INTENT(IN):: nwfa2d, nifa2d, &
                                                                nbca2d
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: &
                          re_cloud, re_ice, re_snow
      INTEGER, INTENT(IN):: has_reqc, has_reqi, has_reqs
#if ( WRF_CHEM == 1 )
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT):: &
                          rainprod, evapprod
#endif
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN):: &
                          pii, p, w, dz
      REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT):: &
                          RAINNC, RAINNCV, SR
      REAL, DIMENSION(ims:ime, jms:jme), OPTIONAL, INTENT(INOUT)::      &
                          SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV
      REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT)::       &
                          refl_10cm
      REAL, INTENT(IN):: dt_in
      INTEGER, INTENT(IN):: itimestep
      INTEGER, OPTIONAL, INTENT(IN):: aer_init_opt, wif_input_opt
#if ( WRF_CHEM == 1 )
      LOGICAL, INTENT(in) :: wetscav_on
#endif

!..Local variables
#ifdef WRF_GPU
!.. fixed size: private arrays of the GPU column loop must not be heap-allocated per device thread
      REAL, DIMENSION(1:KTGPU):: &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d,     &
                          ni1d, nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d,&
                          t1d, p1d, w1d, dz1d, rho, dBZ
      REAL, DIMENSION(1:KTGPU):: re_qc1d, re_qi1d, re_qs1d
#else
      REAL, DIMENSION(kts:kte):: &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d,     &
                          ni1d, nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d,&
                          t1d, p1d, w1d, dz1d, rho, dBZ
      REAL, DIMENSION(kts:kte):: re_qc1d, re_qi1d, re_qs1d
#endif
#if ( WRF_CHEM == 1 )
      REAL, DIMENSION(kts:kte):: &
                          rainprod1d, evapprod1d
#endif
      REAL, DIMENSION(its:ite, jts:jte):: pcp_ra, pcp_sn, pcp_gr, pcp_ic
      REAL:: dt, pptrain, pptsnow, pptgraul, pptice
      REAL:: qc_max, qr_max, qs_max, qi_max, qg_max, ni_max, nr_max
      REAL:: nwfa1
      REAL:: ygra1, zans1
      DOUBLE PRECISION:: lamg, lam_exp, lamr, N0_min, N0_exp
      INTEGER:: i, j, k, k_0, k_inj
      INTEGER:: imax_qc,imax_qr,imax_qi,imax_qs,imax_qg,imax_ni,imax_nr
      INTEGER:: jmax_qc,jmax_qr,jmax_qi,jmax_qs,jmax_qg,jmax_ni,jmax_nr
      INTEGER:: kmax_qc,kmax_qr,kmax_qi,kmax_qs,kmax_qg,kmax_ni,kmax_nr
      INTEGER:: i_start, j_start, i_end, j_end
      LOGICAL, OPTIONAL, INTENT(IN) :: diagflag
      INTEGER, OPTIONAL, INTENT(IN) :: do_radar_ref, ke_diag
      CHARACTER*256:: mp_debug
      
      integer :: kediagloc
#ifdef WRF_GPU
      LOGICAL:: gpu_do_re, gpu_do_refl
      INTEGER:: gpu_aer, gpu_wif
      REAL:: sv_dzq
      INTEGER:: sv_idx_bg
      DOUBLE PRECISION:: sv_ilamg
      LOGICAL:: sv_l_qc
      LOGICAL:: sv_l_qg
      LOGICAL:: sv_l_qi
      LOGICAL:: sv_l_qr
      LOGICAL:: sv_l_qs
      REAL:: sv_lvap
      REAL:: sv_mvd_g
      REAL:: sv_mvd_r
      REAL:: sv_nbca1d
      REAL:: sv_nbcaten
      REAL:: sv_nc
      REAL:: sv_nc1d
      REAL:: sv_ncten
      REAL:: sv_ng
      REAL:: sv_ng1d
      REAL:: sv_ngten
      REAL:: sv_ni
      REAL:: sv_ni1d
      REAL:: sv_nifa1d
      REAL:: sv_nifaten
      REAL:: sv_niten
      REAL:: sv_nr
      REAL:: sv_nr1d
      REAL:: sv_nrten
      REAL:: sv_nwfa1d
      REAL:: sv_nwfaten
      REAL:: sv_ocp
      REAL:: sv_p1d
      DOUBLE PRECISION:: sv_prr_sml
      REAL:: sv_qb1d
      REAL:: sv_qbten
      REAL:: sv_qc1d
      REAL:: sv_qcten
      REAL:: sv_qg1d
      REAL:: sv_qgten
      REAL:: sv_qi1d
      REAL:: sv_qiten
      REAL:: sv_qr1d
      REAL:: sv_qrten
      REAL:: sv_qs1d
      REAL:: sv_qsten
      REAL:: sv_qv1d
      REAL:: sv_qvten
      REAL:: sv_rb
      REAL:: sv_rc
      REAL:: sv_rg
      REAL:: sv_rho
      REAL:: sv_rhof
      REAL:: sv_ri
      REAL:: sv_rr
      REAL:: sv_rs
      REAL:: sv_smob
      REAL:: sv_smoc
      REAL:: sv_t1d
      REAL:: sv_temp
      REAL:: sv_tten
      REAL:: sv_visco
      REAL:: sv_vts_boost
      REAL:: sv_w1d
      REAL:: sv_rhod, sv_ygra1, sv_zans1, sv_N0_exp, sv_lam_exp, sv_lamg
      LOGICAL:: sv_nm
      INTEGER:: sv_km
      INTEGER:: thjb, thje, thjj, thnb, thb0, thb1, thbsz, sp_
      REAL:: lv_tten
      REAL:: lv_qvten
      REAL:: lv_qcten
      REAL:: lv_qiten
      REAL:: lv_qrten
      REAL:: lv_qsten
      REAL:: lv_qgten
      REAL:: lv_qbten
      REAL:: lv_niten
      REAL:: lv_nrten
      REAL:: lv_ncten
      REAL:: lv_ngten
      REAL:: lv_nwfaten
      REAL:: lv_nifaten
      REAL:: lv_nbcaten
      DOUBLE PRECISION:: lv_prw_vcd
      DOUBLE PRECISION:: lv_pnc_wcd
      DOUBLE PRECISION:: lv_prr_wau
      DOUBLE PRECISION:: lv_prr_rcw
      DOUBLE PRECISION:: lv_prr_sml
      DOUBLE PRECISION:: lv_prr_gml
      DOUBLE PRECISION:: lv_prv_rev
      DOUBLE PRECISION:: lv_pnr_rev
      DOUBLE PRECISION:: lv_pri_rci
      DOUBLE PRECISION:: lv_prs_iau
      DOUBLE PRECISION:: lv_prs_sci
      DOUBLE PRECISION:: lv_prs_scw
      DOUBLE PRECISION:: lv_prs_sde
      DOUBLE PRECISION:: lv_prg_scw
      DOUBLE PRECISION:: lv_prg_gde
      DOUBLE PRECISION:: lv_prg_gcw
      DOUBLE PRECISION:: lv_pnc_wau_s
      DOUBLE PRECISION:: lv_pnc_rcw_s
      DOUBLE PRECISION:: lv_pnc_scw_s
      DOUBLE PRECISION:: lv_pnc_gcw_s
      DOUBLE PRECISION:: lv_prr_rcs_s
      DOUBLE PRECISION:: lv_prr_rcg_s
      DOUBLE PRECISION:: lv_prr_rci_s
      DOUBLE PRECISION:: lv_pnr_wau_s
      DOUBLE PRECISION:: lv_pnr_rcs_s
      DOUBLE PRECISION:: lv_pnr_rcg_s
      DOUBLE PRECISION:: lv_pnr_rci_s
      DOUBLE PRECISION:: lv_pnr_sml_s
      DOUBLE PRECISION:: lv_pnr_gml_s
      DOUBLE PRECISION:: lv_pnr_rcr_s
      DOUBLE PRECISION:: lv_pnr_rfz_s
      DOUBLE PRECISION:: lv_pri_inu_s
      DOUBLE PRECISION:: lv_pni_inu_s
      DOUBLE PRECISION:: lv_pri_ihm_s
      DOUBLE PRECISION:: lv_pni_ihm_s
      DOUBLE PRECISION:: lv_pri_wfz_s
      DOUBLE PRECISION:: lv_pni_wfz_s
      DOUBLE PRECISION:: lv_pri_rfz_s
      DOUBLE PRECISION:: lv_pni_rfz_s
      DOUBLE PRECISION:: lv_pri_ide_s
      DOUBLE PRECISION:: lv_pni_ide_s
      DOUBLE PRECISION:: lv_pni_rci_s
      DOUBLE PRECISION:: lv_pni_sci_s
      DOUBLE PRECISION:: lv_pni_iau_s
      DOUBLE PRECISION:: lv_pri_iha_s
      DOUBLE PRECISION:: lv_pni_iha_s
      DOUBLE PRECISION:: lv_prs_rcs_s
      DOUBLE PRECISION:: lv_prs_ihm_s
      DOUBLE PRECISION:: lv_prs_ide_s
      DOUBLE PRECISION:: lv_prg_rfz_s
      DOUBLE PRECISION:: lv_prg_rci_s
      DOUBLE PRECISION:: lv_prg_rcs_s
      DOUBLE PRECISION:: lv_prg_rcg_s
      DOUBLE PRECISION:: lv_prg_ihm_s
      DOUBLE PRECISION:: lv_png_scw_s
      DOUBLE PRECISION:: lv_png_rcs_s
      DOUBLE PRECISION:: lv_png_rcg_s
      DOUBLE PRECISION:: lv_png_gde_s
      DOUBLE PRECISION:: lv_pbg_scw_s
      DOUBLE PRECISION:: lv_pbg_rfz_s
      DOUBLE PRECISION:: lv_pbg_gcw_s
      DOUBLE PRECISION:: lv_pbg_rci_s
      DOUBLE PRECISION:: lv_pbg_rcs_s
      DOUBLE PRECISION:: lv_pbg_rcg_s
      DOUBLE PRECISION:: lv_pbg_sml_s
      DOUBLE PRECISION:: lv_pbg_gml_s
      DOUBLE PRECISION:: lv_pna_rca_s
      DOUBLE PRECISION:: lv_pna_sca_s
      DOUBLE PRECISION:: lv_pna_gca_s
      DOUBLE PRECISION:: lv_pnd_rcd_s
      DOUBLE PRECISION:: lv_pnd_scd_s
      DOUBLE PRECISION:: lv_pnd_gcd_s
      DOUBLE PRECISION:: lv_pnb_rcb_s
      DOUBLE PRECISION:: lv_pnb_scb_s
      DOUBLE PRECISION:: lv_pnb_gcb_s
      REAL:: lv_temp
      REAL:: lv_pres
      REAL:: lv_qv
      REAL:: lv_rc
      REAL:: lv_ri
      REAL:: lv_rr
      REAL:: lv_rs
      REAL:: lv_rg
      REAL:: lv_rb
      REAL:: lv_ni
      REAL:: lv_nr
      REAL:: lv_nc
      REAL:: lv_ns
      REAL:: lv_ng
      REAL:: lv_nwfa
      REAL:: lv_nifa
      REAL:: lv_nbca
      REAL:: lv_rho
      REAL:: lv_rhof
      REAL:: lv_rhof2
      REAL:: lv_qvs
      REAL:: lv_ssatw
      REAL:: lv_diffu
      REAL:: lv_visco
      REAL:: lv_vsc2
      REAL:: lv_tcond
      REAL:: lv_lvap
      REAL:: lv_ocp
      REAL:: lv_lvt2
      DOUBLE PRECISION:: lv_ilamr
      DOUBLE PRECISION:: lv_ilamg
      DOUBLE PRECISION:: lv_n0_r
      DOUBLE PRECISION:: lv_n0_g
      DOUBLE PRECISION:: lv_n0_melt
      REAL:: lv_mvd_r
      REAL:: lv_mvd_c
      REAL:: lv_mvd_g
      REAL:: lv_smob
      REAL:: lv_smo2
      REAL:: lv_smo1
      REAL:: lv_smo0
      REAL:: lv_smoc
      REAL:: lv_smod
      REAL:: lv_smoe
      REAL:: lv_smof
      REAL:: lv_smog
      REAL:: lv_orho
      REAL:: lv_lfus2
      DOUBLE PRECISION:: lv_n0_exp
      DOUBLE PRECISION:: lv_lam_exp
      DOUBLE PRECISION:: lv_lamc
      DOUBLE PRECISION:: lv_lamr
      DOUBLE PRECISION:: lv_lamg
      DOUBLE PRECISION:: lv_lami
      DOUBLE PRECISION:: lv_ilami
      REAL:: lv_xdc
      REAL:: lv_dc_b
      REAL:: lv_dc_g
      REAL:: lv_xdi
      REAL:: lv_xds
      REAL:: lv_xdg
      DOUBLE PRECISION:: lv_dc_star
      REAL:: lv_zeta1
      REAL:: lv_zeta
      REAL:: lv_taud
      REAL:: lv_tau
      REAL:: lv_stoke_g
      REAL:: lv_vts
      REAL:: lv_vtg
      REAL:: lv_xrho_g
      REAL:: lv_afall
      REAL:: lv_vtg1
      REAL:: lv_vtg2
      REAL:: lv_bfall
      REAL:: lv_vts_boost
      REAL:: lv_m0
      REAL:: lv_slam1
      REAL:: lv_slam2
      REAL:: lv_mrat
      REAL:: lv_c_snow
      REAL:: lv_a_
      REAL:: lv_b_
      REAL:: lv_loga_
      REAL:: lv_tf
      REAL:: lv_tempc
      REAL:: lv_tc0
      REAL:: lv_dew_t
      REAL:: lv_tlcl
      REAL:: lv_the
      REAL:: lv_twet_k
      REAL:: lv_tempc_s
      REAL:: lv_rhof_s
      REAL:: lv_rhof2_s
      REAL:: lv_qvs_s
      REAL:: lv_delqvs_s
      REAL:: lv_qvsi_s
      REAL:: lv_satw_s
      REAL:: lv_sati_s
      REAL:: lv_ssatw_s
      REAL:: lv_ssati_s
      REAL:: lv_diffu_s
      REAL:: lv_visco_s
      REAL:: lv_ocp_s
      REAL:: lv_vsc2_s
      REAL:: lv_lvap_s
      REAL:: lv_tcond_s
      REAL:: lv_xnc
      REAL:: lv_xri
      REAL:: lv_xni
      REAL:: lv_xmi
      REAL:: lv_oxmi
      REAL:: lv_xrc
      REAL:: lv_xrr
      REAL:: lv_xnr
      REAL:: lv_xrg
      REAL:: lv_xng
      REAL:: lv_xrb
      REAL:: lv_xsat
      REAL:: lv_rate_max
      REAL:: lv_sump
      REAL:: lv_ratio
      REAL:: lv_clap
      REAL:: lv_fcd
      REAL:: lv_dfcd
      REAL:: lv_otemp
      REAL:: lv_rvs
      REAL:: lv_rvs_p
      REAL:: lv_rvs_pp
      REAL:: lv_gamsc
      REAL:: lv_alphsc
      REAL:: lv_t1_evap
      REAL:: lv_t1_subl
      REAL:: lv_r_frac
      REAL:: lv_g_frac
      REAL:: lv_const_ri
      REAL:: lv_rime_dens
      REAL:: lv_ef_rw
      REAL:: lv_ef_sw
      REAL:: lv_ef_gw
      REAL:: lv_ef_rr
      REAL:: lv_ef_ra
      REAL:: lv_ef_sa
      REAL:: lv_ef_ga
      REAL:: lv_dtsave
      REAL:: lv_odts
      REAL:: lv_odt
      REAL:: lv_ygra1
      REAL:: lv_zans1
      REAL:: lv_eva_factor
      REAL:: lv_melt_f
      INTEGER:: lv_n
      INTEGER:: lv_nn
      INTEGER:: lv_it
      INTEGER:: lv_iexfrq
      INTEGER:: lv_k_melting
      INTEGER:: lv_nir
      INTEGER:: lv_nis
      INTEGER:: lv_nig
      INTEGER:: lv_nii
      INTEGER:: lv_nic
      INTEGER:: lv_niin
      INTEGER:: lv_idx_tc
      INTEGER:: lv_idx_t
      INTEGER:: lv_idx_s
      INTEGER:: lv_idx_g1
      INTEGER:: lv_idx_g
      INTEGER:: lv_idx_r1
      INTEGER:: lv_idx_r
      INTEGER:: lv_idx_i1
      INTEGER:: lv_idx_i
      INTEGER:: lv_idx_c
      INTEGER:: lv_idx
      INTEGER:: lv_idx_d
      INTEGER:: lv_idx_n
      INTEGER:: lv_idx_in
      INTEGER:: lv_idx_bg
      LOGICAL:: lv_no_micro
      LOGICAL:: lv_l_qc
      LOGICAL:: lv_l_qi
      LOGICAL:: lv_l_qr
      LOGICAL:: lv_l_qs
      LOGICAL:: lv_l_qg
      LOGICAL:: lv_debug_flag
      INTEGER:: lv_nu_c
      INTEGER:: lvonce, thonce
      CHARACTER(LEN=8):: thlev_env
      INTEGER:: thlev_st
      ! WRF_GPU_MPCOMPACT=1 (default): the column kernel runs over a list of columns with the hydrometeor-bearing
      ! ones first (stable (j,i) order within each group), so warps are not dragged through the full scheme by a
      ! few active lanes (only ~20% of columns carry condensate on big1000). Per-column arithmetic is unchanged.
      INTEGER, SAVE :: mp_compact = -1
      INTEGER, ALLOCATABLE, SAVE :: mp_li(:), mp_lj(:), mp_flag(:,:), mp_nact(:), mp_offa(:), mp_offi(:)
      INTEGER :: nx_, ny_, ncol_, n_, jj_, cnt_, act_, pa_, pi_, tot_, st_
      CHARACTER(LEN=8) :: cv_
      REAL :: tf_, qf_, sf_
      INTEGER, SAVE :: mp_ncall = 0
#endif

!+---+

      i_start = its
      j_start = jts
      i_end   = MIN(ite, ide-1)
      j_end   = MIN(jte, jde-1)

!..For idealized testing by developer.
!     if ( (ide-ids+1).gt.4 .and. (jde-jds+1).lt.4 .and.                &
!          ids.eq.its.and.ide.eq.ite.and.jds.eq.jts.and.jde.eq.jte) then
!        i_start = its + 2
!        i_end   = ite
!        j_start = jts
!        j_end   = jte
!     endif

      dt = dt_in
   
      qc_max = 0.
      qr_max = 0.
      qs_max = 0.
      qi_max = 0.
      qg_max = 0
      ni_max = 0.
      nr_max = 0.
      imax_qc = 0
      imax_qr = 0
      imax_qi = 0
      imax_qs = 0
      imax_qg = 0
      imax_ni = 0
      imax_nr = 0
      jmax_qc = 0
      jmax_qr = 0
      jmax_qi = 0
      jmax_qs = 0
      jmax_qg = 0
      jmax_ni = 0
      jmax_nr = 0
      kmax_qc = 0
      kmax_qr = 0
      kmax_qi = 0
      kmax_qs = 0
      kmax_qg = 0
      kmax_ni = 0
      kmax_nr = 0
      do i = 1, 256
         mp_debug(i:i) = char(0)
      enddo

      if (.NOT. is_aerosol_aware .AND. PRESENT(nc) .AND. PRESENT(nwfa)  &
                .AND. PRESENT(nifa) .AND. PRESENT(nwfa2d)) then
         write(mp_debug,*) 'WARNING, nc-nwfa-nifa-nwfa2d present but is_aerosol_aware is FALSE'
         CALL wrf_debug(0, mp_debug)
      endif

#ifdef WRF_GPU
!.. GPU path (residency builds, wrf_gpu_on): one device thread per column; plain Thompson only (not aerosol/hail
!.. aware); no max/negative-value debug tracking.
      IF ( wrf_gpu_on ) THEN
      IF ( is_aerosol_aware .OR. is_hail_aware .OR. kts /= 1 .OR. kte > KTGPU .OR.          &
           .NOT. ( PRESENT(snowncv) .AND. PRESENT(snownc) .AND.                         &
                   PRESENT(graupelncv) .AND. PRESENT(graupelnc) ) )                     &
         CALL wrf_error_fatal('mp_gt_driver: GPU path supports plain Thompson (mp_physics=8, kte<=KTGPU) only')
      gpu_do_refl = .FALSE.
      IF ( PRESENT(diagflag) .AND. PRESENT(do_radar_ref) ) gpu_do_refl = diagflag .AND. do_radar_ref == 1
      kediagloc = kte
      IF ( PRESENT(ke_diag) ) kediagloc = ke_diag
      gpu_do_re = has_reqc.ne.0 .and. has_reqi.ne.0 .and. has_reqs.ne.0 .and. .not. mp_re_skip
      gpu_aer = 0 ; IF ( PRESENT(aer_init_opt) ) gpu_aer = aer_init_opt
      gpu_wif = 0 ; IF ( PRESENT(wif_input_opt) ) gpu_wif = wif_input_opt
      IF ( mp_compact < 0 ) THEN
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_THPROBE', cv_, STATUS=st_ )
         th_probe = 0
         IF ( st_ == 0 ) READ( cv_, *, IOSTAT=st_ ) th_probe
         IF ( st_ /= 0 ) th_probe = 0
!$acc update device(th_probe)
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_MPCOMPACT', cv_, STATUS=st_ )
         mp_compact = 1
         IF ( st_ == 0 ) READ( cv_, *, IOSTAT=st_ ) mp_compact
         IF ( st_ /= 0 ) mp_compact = 1
      ENDIF
      nx_ = i_end - i_start + 1 ; ny_ = j_end - j_start + 1 ; ncol_ = nx_*ny_
      IF ( ALLOCATED(mp_li) ) THEN
         IF ( SIZE(mp_li) /= ncol_ .OR. SIZE(mp_nact) /= ny_ .OR. SIZE(mp_flag,1) /= nx_ ) THEN
!$acc exit data delete(mp_li, mp_lj, mp_flag, mp_nact, mp_offa, mp_offi)
            DEALLOCATE( mp_li, mp_lj, mp_flag, mp_nact, mp_offa, mp_offi )
         ENDIF
      ENDIF
      IF ( .NOT. ALLOCATED(mp_li) ) THEN
         ALLOCATE( mp_li(ncol_), mp_lj(ncol_), mp_flag(nx_,ny_), mp_nact(ny_), mp_offa(ny_), mp_offi(ny_) )
!$acc enter data create(mp_li, mp_lj, mp_flag, mp_nact, mp_offa, mp_offi)
      ENDIF
      IF ( mp_compact >= 1 ) THEN
         ! flag and per-row count of columns with any hydrometeor above R1 (the scheme's own no_micro test)
!$acc parallel loop gang present(mp_flag, mp_nact)
         do j = j_start, j_end
            cnt_ = 0
!$acc loop vector reduction(+:cnt_) private(act_)
            do i = i_start, i_end
               act_ = 0
               do k = kts, kte
                  if ( qc(i,k,j) .gt. R1 .or. qi(i,k,j) .gt. R1 .or. qr(i,k,j) .gt. R1 .or.     &
                       qs(i,k,j) .gt. R1 .or. qg(i,k,j) .gt. R1 ) act_ = 1
                  ! the scheme also leaves no_micro for ice supersaturation anywhere in the column (same formulas)
                  tf_ = th(i,k,j)*pii(i,k,j)
                  if ( tf_ - 273.15 .le. 0.0 ) then
                     qf_ = rsif(p(i,k,j), tf_)
                  else
                     qf_ = rslf(p(i,k,j), tf_)
                  endif
                  sf_ = qv(i,k,j)/qf_ - 1.
                  if ( abs(sf_) .lt. eps ) sf_ = 0.0
                  if ( sf_ .gt. 0.0 ) act_ = 1
               enddo
               mp_flag(i-i_start+1, j-j_start+1) = act_
               cnt_ = cnt_ + act_
            enddo
            mp_nact(j-j_start+1) = cnt_
         enddo
         mp_ncall = mp_ncall + 1
         IF ( mp_compact == 2 .AND. MOD(mp_ncall,20) == 1 ) THEN
!$acc update self(mp_nact)
            WRITE(0,'(A,I6,A,F6.1,A)') 'MPCOMPACT call', mp_ncall, ': active columns ', 100.*REAL(SUM(mp_nact))/REAL(ncol_), ' %'
         ENDIF
         ! row offsets of the two groups (serial scan over the rows)
!$acc parallel num_gangs(1) num_workers(1) vector_length(1) present(mp_nact, mp_offa, mp_offi)
         tot_ = 0
!$acc loop seq
         do jj_ = 1, ny_
            mp_offa(jj_) = tot_ ; tot_ = tot_ + mp_nact(jj_)
         enddo
!$acc loop seq
         do jj_ = 1, ny_
            mp_offi(jj_) = tot_ ; tot_ = tot_ + nx_ - mp_nact(jj_)
         enddo
!$acc end parallel
         ! fill the lists, one gang per row, in i order
!$acc parallel loop gang vector_length(1) present(mp_flag, mp_offa, mp_offi, mp_li, mp_lj) private(pa_, pi_)
         do j = j_start, j_end
            pa_ = mp_offa(j-j_start+1) ; pi_ = mp_offi(j-j_start+1)
!$acc loop seq
            do i = i_start, i_end
               if ( mp_flag(i-i_start+1, j-j_start+1) == 1 ) then
                  pa_ = pa_ + 1 ; mp_li(pa_) = i ; mp_lj(pa_) = j
               else
                  pi_ = pi_ + 1 ; mp_li(pi_) = i ; mp_lj(pi_) = j
               endif
            enddo
         enddo
      ELSE
!$acc parallel loop gang present(mp_li, mp_lj)
         do j = j_start, j_end
!$acc loop vector
         do i = i_start, i_end
            mp_li((j-j_start)*nx_ + i-i_start+1) = i ; mp_lj((j-j_start)*nx_ + i-i_start+1) = j
         enddo
         enddo
      ENDIF
      IF ( thlev_on < 0 ) THEN
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_THLEV', thlev_env )
         thlev_on = 0
         IF ( TRIM(thlev_env) == '1' ) thlev_on = 1
      ENDIF
      IF ( thlev_on == 1 ) THEN
!.. WRF_GPU_THLEV=1: level-parallel Thompson (see thom_lev / thom_tail); j bands bound the scratch
      ! the column list (mp_li/mp_lj, every patch column) in balanced bands of at most WRF_GPU_THBAND columns
      ! (default 0 = one band): the hand-off scratch is (band, nk, 1). 2-node MPS layout (190k columns per rank):
      ! one band 0.4179 s/step 21.0 GB/GPU, 100000 0.4195 19.6 GB, 65536 0.4221 19.1 GB (2026-11-08, bit-identical)
      IF ( thband_max < 0 ) THEN
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_THBAND', cv_, STATUS=st_ )
         thband_max = 0
         IF ( st_ == 0 ) READ( cv_, *, IOSTAT=st_ ) thband_max
         IF ( st_ /= 0 ) thband_max = 0
         IF ( thband_max <= 0 ) thband_max = HUGE(thband_max)/2
      ENDIF
      thnb = (ncol_ + thband_max - 1) / thband_max
      thbsz = (ncol_ + thnb - 1) / thnb
      CALL thlev_alloc( thbsz, kte - kts + 1, 1 )
      ! WRF_GPU_THSPLIT=1: the column tail's fall speeds and sedimentation run per (species, column) (thom_vt, thom_sed)
      IF ( thsplit_on < 0 ) THEN
         CALL GET_ENVIRONMENT_VARIABLE( 'WRF_GPU_THSPLIT', cv_, STATUS=st_ )
         thsplit_on = 0
         IF ( st_ == 0 ) READ( cv_, *, IOSTAT=st_ ) thsplit_on
         IF ( st_ /= 0 ) thsplit_on = 0
      ENDIF
      IF ( thsplit_on == 1 ) THEN
         IF ( ALLOCATED(thb_vtq) ) THEN
            IF ( SIZE(thb_vtq,1) /= thbsz .OR. SIZE(thb_vtq,2) /= kte+1 ) &
               DEALLOCATE( thb_vtq, thb_vtn, thb_ksed, thb_onst, thb_ppt )
         ENDIF
         IF ( .NOT. ALLOCATED(thb_vtq) ) ALLOCATE( thb_vtq(thbsz,kte+1,5), thb_vtn(thbsz,kte+1,5), &
              thb_ksed(thbsz,5), thb_onst(thbsz,5), thb_ppt(thbsz,5) )
      ENDIF
      thjb = j_start ; thje = j_end
      DO thb0 = 1, ncol_, thbsz
      thb1 = MIN( thb0 + thbsz - 1, ncol_ )
!$acc parallel loop gang vector collapse(2) present(mp_li, mp_lj) &
!$acc private(sv_dzq,sv_idx_bg,sv_ilamg,sv_l_qc,sv_l_qg,sv_l_qi,sv_l_qr,sv_l_qs,sv_lvap,sv_mvd_g) &
!$acc private(sv_mvd_r,sv_nbca1d,sv_nbcaten,sv_nc,sv_nc1d,sv_ncten,sv_ng,sv_ng1d,sv_ngten,sv_ni) &
!$acc private(sv_ni1d,sv_nifa1d,sv_nifaten,sv_niten,sv_nr,sv_nr1d,sv_nrten,sv_nwfa1d,sv_nwfaten,sv_ocp) &
!$acc private(sv_p1d,sv_prr_sml,sv_qb1d,sv_qbten,sv_qc1d,sv_qcten,sv_qg1d,sv_qgten,sv_qi1d,sv_qiten) &
!$acc private(sv_qr1d,sv_qrten,sv_qs1d,sv_qsten,sv_qv1d,sv_qvten,sv_rb,sv_rc,sv_rg,sv_rho) &
!$acc private(sv_rhof,sv_ri,sv_rr,sv_rs,sv_smob,sv_smoc,sv_t1d,sv_temp,sv_tten,sv_visco) &
!$acc private(sv_vts_boost,sv_w1d,sv_rhod,sv_ygra1,sv_zans1,sv_N0_exp,sv_lam_exp,sv_lamg,sv_nm,sv_km) &
!$acc private(i, j)
      do k = kts, kte
      do n_ = thb0, thb1
            i = mp_li(n_) ; j = mp_lj(n_)
            sv_t1d = th(i,k,j)*pii(i,k,j)
            sv_p1d = p(i,k,j)
            sv_w1d = w(i,k,j)
            sv_dzq = dz(i,k,j)
            sv_qv1d = qv(i,k,j)
            sv_qc1d = qc(i,k,j)
            sv_qi1d = qi(i,k,j)
            sv_qr1d = qr(i,k,j)
            sv_qs1d = qs(i,k,j)
            sv_qg1d = qg(i,k,j)
            sv_ni1d = ni(i,k,j)
            sv_nr1d = nr(i,k,j)
            sv_rhod = 0.622*sv_p1d/(R*sv_t1d*(sv_qv1d+0.622))
            sv_nc1d = Nt_c/sv_rhod
            sv_nwfa1d = 11.1E6/sv_rhod
            sv_nifa1d = naIN1*0.01/sv_rhod
            sv_nbca1d = 5.55E6/sv_rhod
            if (sv_qg1d.gt.R1) then
               sv_ygra1 = alog10(max(1.E-9, sv_qg1d*sv_rhod))
               sv_zans1 = 3.0 + 2./7.*(sv_ygra1+8.)
               sv_zans1 = MAX(2., MIN(sv_zans1, 6.))
               sv_N0_exp = 10.**(sv_zans1)
               sv_lam_exp = (sv_N0_exp*am_g(idx_bg1)*cgg(1,1)/(sv_rhod*sv_qg1d))**oge1
               sv_lamg = sv_lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
               sv_ng1d = cgg(2,1)*ogg3*sv_rhod*sv_qg1d*sv_lamg**bm_g / am_g(idx_bg1)
               sv_ng1d = MAX(R2, sv_ng1d/sv_rhod)
               sv_qb1d = sv_qg1d/rho_g(idx_bg1)
            else
               sv_ng1d = 0
               sv_qb1d = 0
            endif
            CALL thom_lev(1, k, .true., 0, sv_nm, sv_km, gpu_aer, gpu_wif, sv_qv1d, sv_qc1d, sv_qi1d, sv_qr1d, sv_qs1d, sv_qg1d, sv_qb1d, sv_ni1d, sv_nr1d, sv_nc1d, sv_ng1d, sv_nwfa1d, sv_nifa1d, sv_nbca1d, sv_t1d, sv_p1d, sv_w1d, dt, sv_tten, sv_qvten, sv_qcten, sv_qiten, sv_qrten, sv_qsten, sv_qgten, sv_qbten, sv_niten, sv_nrten, sv_ncten, sv_ngten, sv_nwfaten, sv_nifaten, sv_nbcaten, sv_prr_sml, sv_temp, sv_rc, sv_ri, sv_rr, sv_rs, sv_rg, sv_rb, sv_ni, sv_nr, sv_nc, sv_ng, sv_rho, sv_rhof, sv_visco, sv_lvap, sv_ocp, sv_ilamg, sv_mvd_r, sv_mvd_g, sv_smob, sv_smoc, sv_vts_boost, sv_idx_bg, sv_l_qc, sv_l_qi, sv_l_qr, sv_l_qs, sv_l_qg)
            thb_nm(n_-thb0+1,k-kts+1,1) = sv_nm
            thb_km(n_-thb0+1,k-kts+1,1) = sv_km
      enddo
      enddo
!$acc parallel loop gang vector
      do n_ = thb0, thb1
         thb_nmc(n_-thb0+1,1) = .true.
         thb_kmc(n_-thb0+1,1) = 0
         do k = kts, kte
            IF ( .NOT. thb_nm(n_-thb0+1,k-kts+1,1) ) thb_nmc(n_-thb0+1,1) = .false.
            thb_kmc(n_-thb0+1,1) = MAX( thb_kmc(n_-thb0+1,1), thb_km(n_-thb0+1,k-kts+1,1) )
         enddo
      enddo
!$acc parallel loop gang vector collapse(2) present(mp_li, mp_lj) &
!$acc private(sv_dzq,sv_idx_bg,sv_ilamg,sv_l_qc,sv_l_qg,sv_l_qi,sv_l_qr,sv_l_qs,sv_lvap,sv_mvd_g) &
!$acc private(sv_mvd_r,sv_nbca1d,sv_nbcaten,sv_nc,sv_nc1d,sv_ncten,sv_ng,sv_ng1d,sv_ngten,sv_ni) &
!$acc private(sv_ni1d,sv_nifa1d,sv_nifaten,sv_niten,sv_nr,sv_nr1d,sv_nrten,sv_nwfa1d,sv_nwfaten,sv_ocp) &
!$acc private(sv_p1d,sv_prr_sml,sv_qb1d,sv_qbten,sv_qc1d,sv_qcten,sv_qg1d,sv_qgten,sv_qi1d,sv_qiten) &
!$acc private(sv_qr1d,sv_qrten,sv_qs1d,sv_qsten,sv_qv1d,sv_qvten,sv_rb,sv_rc,sv_rg,sv_rho) &
!$acc private(sv_rhof,sv_ri,sv_rr,sv_rs,sv_smob,sv_smoc,sv_t1d,sv_temp,sv_tten,sv_visco) &
!$acc private(sv_vts_boost,sv_w1d,sv_rhod,sv_ygra1,sv_zans1,sv_N0_exp,sv_lam_exp,sv_lamg,sv_nm,sv_km) &
!$acc private(lv_tten,lv_qvten,lv_qcten,lv_qiten,lv_qrten,lv_qsten,lv_qgten,lv_qbten,lv_niten,lv_nrten) &
!$acc private(lv_ncten,lv_ngten,lv_nwfaten,lv_nifaten,lv_nbcaten,lv_prw_vcd,lv_pnc_wcd,lv_prr_wau,lv_prr_rcw,lv_prr_sml) &
!$acc private(lv_prr_gml,lv_prv_rev,lv_pnr_rev,lv_pri_rci,lv_prs_iau,lv_prs_sci,lv_prs_scw,lv_prs_sde,lv_prg_scw,lv_prg_gde) &
!$acc private(lv_prg_gcw,lv_pnc_wau_s,lv_pnc_rcw_s,lv_pnc_scw_s,lv_pnc_gcw_s,lv_prr_rcs_s,lv_prr_rcg_s,lv_prr_rci_s,lv_pnr_wau_s,lv_pnr_rcs_s) &
!$acc private(lv_pnr_rcg_s,lv_pnr_rci_s,lv_pnr_sml_s,lv_pnr_gml_s,lv_pnr_rcr_s,lv_pnr_rfz_s,lv_pri_inu_s,lv_pni_inu_s,lv_pri_ihm_s,lv_pni_ihm_s) &
!$acc private(lv_pri_wfz_s,lv_pni_wfz_s,lv_pri_rfz_s,lv_pni_rfz_s,lv_pri_ide_s,lv_pni_ide_s,lv_pni_rci_s,lv_pni_sci_s,lv_pni_iau_s,lv_pri_iha_s) &
!$acc private(lv_pni_iha_s,lv_prs_rcs_s,lv_prs_ihm_s,lv_prs_ide_s,lv_prg_rfz_s,lv_prg_rci_s,lv_prg_rcs_s,lv_prg_rcg_s,lv_prg_ihm_s,lv_png_scw_s) &
!$acc private(lv_png_rcs_s,lv_png_rcg_s,lv_png_gde_s,lv_pbg_scw_s,lv_pbg_rfz_s,lv_pbg_gcw_s,lv_pbg_rci_s,lv_pbg_rcs_s,lv_pbg_rcg_s,lv_pbg_sml_s) &
!$acc private(lv_pbg_gml_s,lv_pna_rca_s,lv_pna_sca_s,lv_pna_gca_s,lv_pnd_rcd_s,lv_pnd_scd_s,lv_pnd_gcd_s,lv_pnb_rcb_s,lv_pnb_scb_s,lv_pnb_gcb_s) &
!$acc private(lv_temp,lv_pres,lv_qv,lv_rc,lv_ri,lv_rr,lv_rs,lv_rg,lv_rb,lv_ni) &
!$acc private(lv_nr,lv_nc,lv_ns,lv_ng,lv_nwfa,lv_nifa,lv_nbca,lv_rho,lv_rhof,lv_rhof2) &
!$acc private(lv_qvs,lv_ssatw,lv_diffu,lv_visco,lv_vsc2,lv_tcond,lv_lvap,lv_ocp,lv_lvt2,lv_ilamr) &
!$acc private(lv_ilamg,lv_n0_r,lv_n0_g,lv_n0_melt,lv_mvd_r,lv_mvd_c,lv_mvd_g,lv_smob,lv_smo2,lv_smo1) &
!$acc private(lv_smo0,lv_smoc,lv_smod,lv_smoe,lv_smof,lv_smog,lv_orho,lv_lfus2,lv_n0_exp,lv_lam_exp) &
!$acc private(lv_lamc,lv_lamr,lv_lamg,lv_lami,lv_ilami,lv_xdc,lv_dc_b,lv_dc_g,lv_xdi,lv_xds) &
!$acc private(lv_xdg,lv_dc_star,lv_zeta1,lv_zeta,lv_taud,lv_tau,lv_stoke_g,lv_vts,lv_vtg,lv_xrho_g) &
!$acc private(lv_afall,lv_vtg1,lv_vtg2,lv_bfall,lv_vts_boost,lv_m0,lv_slam1,lv_slam2,lv_mrat,lv_c_snow) &
!$acc private(lv_a_,lv_b_,lv_loga_,lv_tf,lv_tempc,lv_tc0,lv_dew_t,lv_tlcl,lv_the,lv_twet_k) &
!$acc private(lv_tempc_s,lv_rhof_s,lv_rhof2_s,lv_qvs_s,lv_delqvs_s,lv_qvsi_s,lv_satw_s,lv_sati_s,lv_ssatw_s,lv_ssati_s) &
!$acc private(lv_diffu_s,lv_visco_s,lv_ocp_s,lv_vsc2_s,lv_lvap_s,lv_tcond_s,lv_xnc,lv_xri,lv_xni,lv_xmi) &
!$acc private(lv_oxmi,lv_xrc,lv_xrr,lv_xnr,lv_xrg,lv_xng,lv_xrb,lv_xsat,lv_rate_max,lv_sump) &
!$acc private(lv_ratio,lv_clap,lv_fcd,lv_dfcd,lv_otemp,lv_rvs,lv_rvs_p,lv_rvs_pp,lv_gamsc,lv_alphsc) &
!$acc private(lv_t1_evap,lv_t1_subl,lv_r_frac,lv_g_frac,lv_const_ri,lv_rime_dens,lv_ef_rw,lv_ef_sw,lv_ef_gw,lv_ef_rr) &
!$acc private(lv_ef_ra,lv_ef_sa,lv_ef_ga,lv_dtsave,lv_odts,lv_odt,lv_ygra1,lv_zans1,lv_eva_factor,lv_melt_f) &
!$acc private(lv_n,lv_nn,lv_it,lv_iexfrq,lv_k_melting,lv_nir,lv_nis,lv_nig,lv_nii,lv_nic) &
!$acc private(lv_niin,lv_idx_tc,lv_idx_t,lv_idx_s,lv_idx_g1,lv_idx_g,lv_idx_r1,lv_idx_r,lv_idx_i1,lv_idx_i) &
!$acc private(lv_idx_c,lv_idx,lv_idx_d,lv_idx_n,lv_idx_in,lv_idx_bg,lv_no_micro,lv_l_qc,lv_l_qi,lv_l_qr) &
!$acc private(lv_l_qs,lv_l_qg,lv_debug_flag,lv_nu_c,lvonce,thonce) &
!$acc private(i, j)
      do k = kts, kte
      do n_ = thb0, thb1
            i = mp_li(n_) ; j = mp_lj(n_)
            sv_t1d = th(i,k,j)*pii(i,k,j)
            sv_p1d = p(i,k,j)
            sv_w1d = w(i,k,j)
            sv_dzq = dz(i,k,j)
            sv_qv1d = qv(i,k,j)
            sv_qc1d = qc(i,k,j)
            sv_qi1d = qi(i,k,j)
            sv_qr1d = qr(i,k,j)
            sv_qs1d = qs(i,k,j)
            sv_qg1d = qg(i,k,j)
            sv_ni1d = ni(i,k,j)
            sv_nr1d = nr(i,k,j)
            sv_rhod = 0.622*sv_p1d/(R*sv_t1d*(sv_qv1d+0.622))
            sv_nc1d = Nt_c/sv_rhod
            sv_nwfa1d = 11.1E6/sv_rhod
            sv_nifa1d = naIN1*0.01/sv_rhod
            sv_nbca1d = 5.55E6/sv_rhod
            if (sv_qg1d.gt.R1) then
               sv_ygra1 = alog10(max(1.E-9, sv_qg1d*sv_rhod))
               sv_zans1 = 3.0 + 2./7.*(sv_ygra1+8.)
               sv_zans1 = MAX(2., MIN(sv_zans1, 6.))
               sv_N0_exp = 10.**(sv_zans1)
               sv_lam_exp = (sv_N0_exp*am_g(idx_bg1)*cgg(1,1)/(sv_rhod*sv_qg1d))**oge1
               sv_lamg = sv_lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
               sv_ng1d = cgg(2,1)*ogg3*sv_rhod*sv_qg1d*sv_lamg**bm_g / am_g(idx_bg1)
               sv_ng1d = MAX(R2, sv_ng1d/sv_rhod)
               sv_qb1d = sv_qg1d/rho_g(idx_bg1)
            else
               sv_ng1d = 0
               sv_qb1d = 0
            endif
            lvblk: do lvonce = 1, 1
            lv_debug_flag = .false.
            if(lv_debug_flag) then
            endif
            if (th_probe == 6) exit lvblk
            lv_no_micro = .true.
            lv_dtsave = dt
            lv_odt = 1./dt
            lv_odts = 1./lv_dtsave
            lv_iexfrq = 1
            lv_smo0 = 0.
            lv_smo1 = 0.
            lv_smo2 = 0.
            lv_smob = 0.
            lv_smoc = 0.
            lv_smod = 0.
            lv_smoe = 0.
            lv_smof = 0.
            lv_smog = 0.
            lv_ns   = 0.
            lv_mvd_r = 0.
            lv_mvd_c = 0.
            lv_temp = sv_t1d
            lv_qv = MAX(1.E-10, sv_qv1d)
            lv_pres = sv_p1d
            lv_rho = 0.622*lv_pres/(R*lv_temp*(lv_qv+0.622))
            if (is_aerosol_aware) then
            if (gpu_aer .lt. 2) then
            lv_nwfa = MAX(11.1E6, MIN(9999.E6, sv_nwfa1d*lv_rho))
            lv_nifa = MAX(naIN1*0.01, MIN(9999.E6, sv_nifa1d*lv_rho))
            if (gpu_wif .eq. 2) then
            lv_nbca = MAX(5.55E6, MIN(9999.E6, sv_nbca1d*lv_rho))
            else
            lv_nbca = 0.0
            endif
            else
            lv_nwfa = MAX(0.0, sv_nwfa1d*lv_rho)
            lv_nifa = MAX(0.0, sv_nifa1d*lv_rho)
            if (gpu_wif .eq. 2) then
            lv_nbca = MAX(0.0, sv_nbca1d*lv_rho)
            else
            lv_nbca = 0.0
            endif
            endif
            else
            lv_nwfa = MAX(11.1E6, MIN(9999.E6, sv_nwfa1d*lv_rho))
            lv_nifa = MAX(naIN1*0.01, MIN(9999.E6, sv_nifa1d*lv_rho))
            lv_nbca = MAX(5.55E6, MIN(9999.E6, sv_nbca1d*lv_rho))
            endif
            if (sv_qc1d .gt. R1) then
            lv_no_micro = .false.
            lv_rc = sv_qc1d*lv_rho
            lv_nc = MAX(2., MIN(sv_nc1d*lv_rho, Nt_c_max))
            lv_l_qc = .true.
            lv_nu_c = MIN(15, NINT(1000.E6/lv_nc) + 2)
            lv_lamc = (lv_nc*am_r*ccg(2,lv_nu_c)*ocg1(lv_nu_c)/lv_rc)**obmr
            lv_xdc = (bm_r + lv_nu_c + 1.) / lv_lamc
            if (lv_xdc.lt. D0c) then
            lv_lamc = cce(2,lv_nu_c)/D0c
            elseif (lv_xdc.gt. D0r*2.) then
            lv_lamc = cce(2,lv_nu_c)/(D0r*2.)
            endif
            lv_nc = MIN( DBLE(Nt_c_max), ccg(1,lv_nu_c)*ocg2(lv_nu_c)*lv_rc    / am_r*lv_lamc**bm_r)
            if (.NOT. is_aerosol_aware) lv_nc = Nt_c
            else
            sv_qc1d = 0.0
            sv_nc1d = 0.0
            lv_rc = R1
            lv_nc = 2.
            lv_l_qc = .false.
            endif
            if (sv_qi1d .gt. R1) then
            lv_no_micro = .false.
            lv_ri = sv_qi1d*lv_rho
            lv_ni = MAX(R2, sv_ni1d*lv_rho)
            if (lv_ni.le. R2) then
            lv_lami = cie(2)/5.E-6
            lv_ni = MIN(999.D3, cig(1)*oig2*lv_ri/am_i*lv_lami**bm_i)
            endif
            lv_l_qi = .true.
            lv_lami = (am_i*cig(2)*oig1*lv_ni/lv_ri)**obmi
            lv_ilami = 1./lv_lami
            lv_xdi = (bm_i + mu_i + 1.) * lv_ilami
            if (lv_xdi.lt. 5.E-6) then
            lv_lami = cie(2)/5.E-6
            lv_ni = MIN(999.D3, cig(1)*oig2*lv_ri/am_i*lv_lami**bm_i)
            elseif (lv_xdi.gt. 300.E-6) then
            lv_lami = cie(2)/300.E-6
            lv_ni = cig(1)*oig2*lv_ri/am_i*lv_lami**bm_i
            endif
            else
            sv_qi1d = 0.0
            sv_ni1d = 0.0
            lv_ri = R1
            lv_ni = R2
            lv_l_qi = .false.
            endif
            if (sv_qr1d .gt. R1) then
            lv_no_micro = .false.
            lv_rr = sv_qr1d*lv_rho
            lv_nr = MAX(R2, sv_nr1d*lv_rho)
            if (lv_nr.le. R2) then
            lv_mvd_r = 1.0E-3
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_nr = crg(2)*org3*lv_rr*lv_lamr**bm_r / am_r
            endif
            lv_l_qr = .true.
            lv_lamr = (am_r*crg(3)*org2*lv_nr/lv_rr)**obmr
            lv_mvd_r = (3.0 + mu_r + 0.672) / lv_lamr
            if (lv_mvd_r .gt. 2.5E-3) then
            lv_mvd_r = 2.5E-3
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_nr = crg(2)*org3*lv_rr*lv_lamr**bm_r / am_r
            elseif (lv_mvd_r .lt. D0r*0.75) then
            lv_mvd_r = D0r*0.75
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_nr = crg(2)*org3*lv_rr*lv_lamr**bm_r / am_r
            endif
            else
            sv_qr1d = 0.0
            sv_nr1d = 0.0
            lv_rr = R1
            lv_nr = R2
            lv_l_qr = .false.
            endif
            if (sv_qs1d .gt. R1) then
            lv_no_micro = .false.
            lv_rs = sv_qs1d*lv_rho
            lv_l_qs = .true.
            else
            sv_qs1d = 0.0
            lv_rs = R1
            lv_l_qs = .false.
            endif
            if (sv_qg1d .gt. R1) then
            lv_no_micro = .false.
            lv_l_qg = .true.
            lv_rg = sv_qg1d*lv_rho
            lv_ng = MAX(R2, sv_ng1d*lv_rho)
            lv_rb = MAX(sv_qg1d/rho_g(NRHG), sv_qb1d)
            lv_rb = MIN(sv_qg1d/rho_g(1), lv_rb)
            sv_qb1d = lv_rb
            lv_idx_bg = MAX(1,MIN(NINT(sv_qg1d/lv_rb *0.01)+1,NRHG))
            if (lv_ng.le. R2) then
            lv_mvd_g = 1.5E-3
            lv_lamg = (3.0 + mu_g + 0.672) / lv_mvd_g
            lv_ng = cgg(2,1)*ogg3*lv_rg*lv_lamg**bm_g / am_g(lv_idx_bg)
            endif
            lv_lamg = (am_g(lv_idx_bg)*cgg(3,1)*ogg2*lv_ng/lv_rg)**obmg
            lv_mvd_g = (3.0 + mu_g + 0.672) / lv_lamg
            if (lv_mvd_g .gt. 25.4E-3) then
            lv_mvd_g = 25.4E-3
            lv_lamg = (3.0 + mu_g + 0.672) / lv_mvd_g
            lv_ng = cgg(2,1)*ogg3*lv_rg*lv_lamg**bm_g / am_g(lv_idx_bg)
            elseif (lv_mvd_g .lt. D0r) then
            lv_mvd_g = D0r
            lv_lamg = (3.0 + mu_g + 0.672) / lv_mvd_g
            lv_ng = cgg(2,1)*ogg3*lv_rg*lv_lamg**bm_g / am_g(lv_idx_bg)
            endif
            else
            sv_qg1d = 0.0
            sv_ng1d = 0.0
            sv_qb1d = 0.0
            lv_idx_bg = idx_bg1
            lv_rg = R1
            lv_ng = R2
            lv_rb = R1/lv_rho/rho_g(NRHG)
            lv_l_qg = .false.
            endif
            if (.not. is_hail_aware) lv_idx_bg = idx_bg1
            lv_k_melting = 0
            lv_tempc = lv_temp - 273.15
            if (lv_tempc .le. 0.0) then
            lv_qvsi_s = rsif(lv_pres, lv_temp)
            else
            lv_qvsi_s = rslf(lv_pres, lv_temp)
            lv_k_melting = MAX(k, lv_k_melting)
            endif
            lv_sati_s = lv_qv/lv_qvsi_s
            lv_ssati_s = lv_sati_s - 1.
            if (abs(lv_ssati_s).lt. eps) lv_ssati_s = 0.0
            if (lv_no_micro .and. lv_ssati_s.gt. 0.0) lv_no_micro = .false.
            lv_no_micro = thb_nmc(n_-thb0+1,1)
            lv_k_melting = thb_kmc(n_-thb0+1,1)
            if (lv_no_micro) exit lvblk
            if (th_probe == 1) exit lvblk
            lv_tten = 0.
            lv_qvten = 0.
            lv_qcten = 0.
            lv_qiten = 0.
            lv_qrten = 0.
            lv_qsten = 0.
            lv_qgten = 0.
            lv_ngten = 0.
            lv_qbten = 0.
            lv_niten = 0.
            lv_nrten = 0.
            lv_ncten = 0.
            lv_nwfaten = 0.
            lv_nifaten = 0.
            lv_nbcaten = 0.
            lv_prw_vcd = 0.
            lv_pnc_wcd = 0.
            lv_prv_rev = 0.
            lv_prr_wau = 0.
            lv_prr_rcw = 0.
            lv_prr_sml = 0.
            lv_prr_gml = 0.
            lv_pnr_rev = 0.
            lv_pri_rci = 0.
            lv_prs_iau = 0.
            lv_prs_sci = 0.
            lv_prs_scw = 0.
            lv_prs_sde = 0.
            lv_prg_scw = 0.
            lv_prg_gde = 0.
            lv_prg_gcw = 0.
            if (.not. iiwarm) then
            do thonce = 1, 1
            if (.not. lv_l_qs) CYCLE
            lv_tc0 = MIN(-0.1, lv_temp-273.15)
            lv_smob = lv_rs*oams
            if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            lv_smo2 = lv_smob
            else
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*bm_s  + sa(4)*lv_tc0*bm_s + sa(5)*lv_tc0*lv_tc0  + sa(6)*bm_s*bm_s + sa(7)*lv_tc0*lv_tc0*bm_s  + sa(8)*lv_tc0*bm_s*bm_s + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*bm_s*bm_s*bm_s
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1) + sb(2)*lv_tc0 + sb(3)*bm_s  + sb(4)*lv_tc0*bm_s + sb(5)*lv_tc0*lv_tc0  + sb(6)*bm_s*bm_s + sb(7)*lv_tc0*lv_tc0*bm_s  + sb(8)*lv_tc0*bm_s*bm_s + sb(9)*lv_tc0*lv_tc0*lv_tc0  + sb(10)*bm_s*bm_s*bm_s
            lv_smo2 = (lv_smob/lv_a_)**(1./lv_b_)
            endif
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(5)*lv_tc0*lv_tc0 + sa(9)*lv_tc0*lv_tc0*lv_tc0
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1) + sb(2)*lv_tc0 + sb(5)*lv_tc0*lv_tc0 + sb(9)*lv_tc0*lv_tc0*lv_tc0
            lv_smo0 = lv_a_ * lv_smo2**lv_b_
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)  + sa(4)*lv_tc0 + sa(5)*lv_tc0*lv_tc0  + sa(6) + sa(7)*lv_tc0*lv_tc0  + sa(8)*lv_tc0 + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3) + sb(4)*lv_tc0  + sb(5)*lv_tc0*lv_tc0 + sb(6)  + sb(7)*lv_tc0*lv_tc0 + sb(8)*lv_tc0  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)
            lv_smo1 = lv_a_ * lv_smo2**lv_b_
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(1)  + sa(4)*lv_tc0*cse(1) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(1)*cse(1) + sa(7)*lv_tc0*lv_tc0*cse(1)  + sa(8)*lv_tc0*cse(1)*cse(1) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(1)*cse(1)*cse(1)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(1) + sb(4)*lv_tc0*cse(1)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(1)*cse(1)  + sb(7)*lv_tc0*lv_tc0*cse(1) + sb(8)*lv_tc0*cse(1)*cse(1)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(1)*cse(1)*cse(1)
            lv_smoc = lv_a_ * lv_smo2**lv_b_
            lv_m0 = lv_smob/lv_smoc
            lv_mrat = lv_smob*lv_m0*lv_m0*lv_m0
            lv_slam1 = lv_m0 * Lam0
            lv_slam2 = lv_m0 * Lam1
            lv_ns = lv_mrat*Kap0/lv_slam1                                         + lv_mrat*Kap1*lv_m0**mu_s*csg(15)/lv_slam2**cse(15)
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(13)  + sa(4)*lv_tc0*cse(13) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(13)*cse(13) + sa(7)*lv_tc0*lv_tc0*cse(13)  + sa(8)*lv_tc0*cse(13)*cse(13) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(13)*cse(13)*cse(13)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(13) + sb(4)*lv_tc0*cse(13)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(13)*cse(13)  + sb(7)*lv_tc0*lv_tc0*cse(13) + sb(8)*lv_tc0*cse(13)*cse(13)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(13)*cse(13)*cse(13)
            lv_smoe = lv_a_ * lv_smo2**lv_b_
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(16)  + sa(4)*lv_tc0*cse(16) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(16)*cse(16) + sa(7)*lv_tc0*lv_tc0*cse(16)  + sa(8)*lv_tc0*cse(16)*cse(16) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(16)*cse(16)*cse(16)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(16) + sb(4)*lv_tc0*cse(16)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(16)*cse(16)  + sb(7)*lv_tc0*lv_tc0*cse(16) + sb(8)*lv_tc0*cse(16)*cse(16)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(16)*cse(16)*cse(16)
            lv_smof = lv_a_ * lv_smo2**lv_b_
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(17)  + sa(4)*lv_tc0*cse(17) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(17)*cse(17) + sa(7)*lv_tc0*lv_tc0*cse(17)  + sa(8)*lv_tc0*cse(17)*cse(17) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(17)*cse(17)*cse(17)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(17) + sb(4)*lv_tc0*cse(17)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(17)*cse(17)  + sb(7)*lv_tc0*lv_tc0*cse(17) + sb(8)*lv_tc0*cse(17)*cse(17)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(17)*cse(17)*cse(17)
            lv_smog = lv_a_ * lv_smo2**lv_b_
            enddo
            lv_lamg = (am_g(lv_idx_bg)*cgg(3,1)*ogg2*lv_ng/lv_rg)**obmg
            lv_ilamg = 1./lv_lamg
            lv_n0_g = lv_ng*ogg2*lv_lamg**cge(2,1)
            endif
            lv_lamr = (am_r*crg(3)*org2*lv_nr/lv_rr)**obmr
            lv_ilamr = 1./lv_lamr
            lv_mvd_r = (3.0 + mu_r + 0.672) / lv_lamr
            lv_n0_r = lv_nr*org2*lv_lamr**cre(2)
            lv_tempc_s = lv_temp - 273.15
            lv_rhof_s = SQRT(RHO_NOT/lv_rho)
            lv_rhof2_s = SQRT(lv_rhof_s)
            lv_qvs_s = rslf(lv_pres, lv_temp)
            lv_delqvs_s = MAX(0.0, rslf(lv_pres, 273.15)-lv_qv)
            if (lv_tempc_s .le. 0.0) then
            lv_qvsi_s = rsif(lv_pres, lv_temp)
            else
            lv_qvsi_s = lv_qvs_s
            endif
            lv_satw_s = lv_qv/lv_qvs_s
            lv_sati_s = lv_qv/lv_qvsi_s
            lv_ssatw_s = lv_satw_s - 1.
            lv_ssati_s = lv_sati_s - 1.
            if (abs(lv_ssatw_s).lt. eps) lv_ssatw_s = 0.0
            if (abs(lv_ssati_s).lt. eps) lv_ssati_s = 0.0
            lv_diffu_s = 2.11E-5*(lv_temp/273.15)**1.94 * (101325./lv_pres)
            if (lv_tempc_s .ge. 0.0) then
            lv_visco_s = (1.718+0.0049*lv_tempc_s)*1.0E-5
            else
            lv_visco_s = (1.718+0.0049*lv_tempc_s-1.2E-5*lv_tempc_s*lv_tempc_s)*1.0E-5
            endif
            lv_ocp_s = 1./(Cp*(1.+0.887*lv_qv))
            lv_vsc2_s = SQRT(lv_rho/lv_visco_s)
            lv_lvap_s = lvap0 + (2106.0 - 4218.0)*lv_tempc_s
            lv_tcond_s = (5.69 + 0.0168*lv_tempc_s)*1.0E-5 * 418.936
            lv_twet_k = lv_temp
            if (k .le. lv_k_melting) then
            if (lv_satw_s .lt. 0.999 .and. (lv_l_qs .or. lv_l_qg)) then
            lv_dew_t = MIN(lv_temp-0.001, t_dew(lv_pres, lv_qv))
            lv_tlcl = t_lcl(lv_temp, lv_dew_t)
            lv_the = theta_e(lv_pres, lv_temp, lv_qv, lv_tlcl)
            lv_twet_k = MIN(lv_temp, compT_fr_The(lv_the, lv_pres))
            endif
            endif
            lv_pnc_wau_s = 0.
            lv_pnc_rcw_s = 0.
            lv_pnc_scw_s = 0.
            lv_pnc_gcw_s = 0.
            lv_prr_rcs_s = 0.
            lv_prr_rcg_s = 0.
            lv_prr_rci_s = 0.
            lv_pnr_wau_s = 0.
            lv_pnr_rcs_s = 0.
            lv_pnr_rcg_s = 0.
            lv_pnr_rci_s = 0.
            lv_pnr_sml_s = 0.
            lv_pnr_gml_s = 0.
            lv_pnr_rcr_s = 0.
            lv_pnr_rfz_s = 0.
            lv_pri_inu_s = 0.
            lv_pni_inu_s = 0.
            lv_pri_ihm_s = 0.
            lv_pni_ihm_s = 0.
            lv_pri_wfz_s = 0.
            lv_pni_wfz_s = 0.
            lv_pri_rfz_s = 0.
            lv_pni_rfz_s = 0.
            lv_pri_ide_s = 0.
            lv_pni_ide_s = 0.
            lv_pni_rci_s = 0.
            lv_pni_sci_s = 0.
            lv_pni_iau_s = 0.
            lv_pri_iha_s = 0.
            lv_pni_iha_s = 0.
            lv_prs_rcs_s = 0.
            lv_prs_ihm_s = 0.
            lv_prs_ide_s = 0.
            lv_prg_rfz_s = 0.
            lv_prg_rci_s = 0.
            lv_prg_rcs_s = 0.
            lv_prg_rcg_s = 0.
            lv_prg_ihm_s = 0.
            lv_png_scw_s = 0.
            lv_png_rcs_s = 0.
            lv_png_rcg_s = 0.
            lv_png_gde_s = 0.
            lv_pbg_scw_s = 0.
            lv_pbg_rfz_s = 0.
            lv_pbg_gcw_s = 0.
            lv_pbg_rci_s = 0.
            lv_pbg_rcs_s = 0.
            lv_pbg_rcg_s = 0.
            lv_pbg_sml_s = 0.
            lv_pbg_gml_s = 0.
            lv_pna_rca_s = 0.
            lv_pna_sca_s = 0.
            lv_pna_gca_s = 0.
            lv_pnd_rcd_s = 0.
            lv_pnd_scd_s = 0.
            lv_pnd_gcd_s = 0.
            lv_pnb_rcb_s = 0.
            lv_pnb_scb_s = 0.
            lv_pnb_gcb_s = 0.
            if (lv_l_qr .and. lv_mvd_r.gt. D0r) then
            lv_ef_rr = 1.0 - EXP(2300.0*(lv_mvd_r-1950.0E-6))
            lv_pnr_rcr_s = lv_ef_rr * 2.0*lv_nr*lv_rr
            endif
            lv_mvd_c = D0c
            if (lv_l_qc) then
            lv_nu_c = MIN(15, NINT(1000.E6/lv_nc) + 2)
            lv_xdc = MAX(D0c*1.E6, ((lv_rc/(am_r*lv_nc))**obmr) * 1.E6)
            lv_lamc = (lv_nc*am_r* ccg(2,lv_nu_c) * ocg1(lv_nu_c) / lv_rc)**obmr
            lv_mvd_c = (3.0+lv_nu_c+0.672) / lv_lamc
            lv_mvd_c = MAX(D0c, MIN(lv_mvd_c, D0r))
            endif
            if (lv_rc.gt. 0.01e-3) then
            lv_dc_g = ((ccg(3,lv_nu_c)*ocg2(lv_nu_c))**obmr / lv_lamc) * 1.E6
            lv_dc_b = (lv_xdc*lv_xdc*lv_xdc*lv_dc_g*lv_dc_g*lv_dc_g - lv_xdc*lv_xdc*lv_xdc*lv_xdc*lv_xdc*lv_xdc)  **(1./6.)
            lv_zeta1 = 0.5*((6.25E-6*lv_xdc*lv_dc_b*lv_dc_b*lv_dc_b - 0.4)  + abs(6.25E-6*lv_xdc*lv_dc_b*lv_dc_b*lv_dc_b - 0.4))
            lv_zeta = 0.027*lv_rc*lv_zeta1
            lv_taud = 0.5*((0.5*lv_dc_b - 7.5) + abs(0.5*lv_dc_b - 7.5)) + R1
            lv_tau  = 3.72/(lv_rc*lv_taud)
            lv_prr_wau = lv_zeta/lv_tau
            lv_prr_wau = MIN(DBLE(lv_rc*lv_odts), lv_prr_wau)
            lv_pnr_wau_s = lv_prr_wau / (am_r*lv_nu_c*10.*D0r*D0r*D0r)
            lv_pnc_wau_s = MIN(DBLE(lv_nc*lv_odts), lv_prr_wau                  / (am_r*lv_mvd_c*lv_mvd_c*lv_mvd_c))
            endif
            if (lv_l_qr .and. lv_mvd_r.gt. D0r .and. lv_mvd_c.gt. D0c) then
            lv_lamr = 1./lv_ilamr
            lv_idx = 1 + INT(nbr*DLOG(lv_mvd_r/Dr(1))/DLOG(Dr(nbr)/Dr(1)))
            lv_idx = MIN(lv_idx, nbr)
            lv_ef_rw = t_Efrw(lv_idx, INT(lv_mvd_c*1.E6))
            lv_prr_rcw = lv_rhof_s*t1_qr_qc*lv_ef_rw*lv_rc*lv_n0_r  *((lv_lamr+fv_r)**(-cre(9)))
            lv_prr_rcw = MIN(DBLE(lv_rc*lv_odts), lv_prr_rcw)
            lv_pnc_rcw_s = lv_rhof_s*t1_qr_qc*lv_ef_rw*lv_nc*lv_n0_r              *((lv_lamr+fv_r)**(-cre(9)))
            lv_pnc_rcw_s = MIN(DBLE(lv_nc*lv_odts), lv_pnc_rcw_s)
            endif
            if (lv_l_qr .and. lv_mvd_r.gt. D0r) then
            lv_ef_ra = Eff_aero(lv_mvd_r,0.04E-6,lv_visco_s,lv_rho,lv_temp,'r')
            lv_lamr = 1./lv_ilamr
            lv_pna_rca_s = lv_rhof_s*t1_qr_qc*lv_ef_ra*lv_nwfa*lv_n0_r            *((lv_lamr+fv_r)**(-cre(9)))
            lv_pna_rca_s = MIN(DBLE(lv_nwfa*lv_odts), lv_pna_rca_s)
            lv_ef_ra = Eff_aero(lv_mvd_r,0.8E-6,lv_visco_s,lv_rho,lv_temp,'r')
            lv_pnd_rcd_s = lv_rhof_s*t1_qr_qc*lv_ef_ra*lv_nifa*lv_n0_r            *((lv_lamr+fv_r)**(-cre(9)))
            lv_pnd_rcd_s = MIN(DBLE(lv_nifa*lv_odts), lv_pnd_rcd_s)
            if (.true.) then
            if (gpu_wif .eq. 2) then
            lv_ef_ra = Eff_aero(lv_mvd_r,0.0236E-6,  lv_visco_s,lv_rho,lv_temp,'r')
            lv_pnb_rcb_s = lv_rhof_s*t1_qr_qc*lv_ef_ra*lv_nbca*lv_n0_r        *((lv_lamr+fv_r)**(-cre(9)))
            lv_pnb_rcb_s = MIN(DBLE(lv_nbca*lv_odts), lv_pnb_rcb_s)
            endif
            endif
            endif
            if (.not. iiwarm) then
            lv_vts_boost = 1.0
            lv_orho = 1./lv_rho
            if (lv_l_qs) then
            lv_xds = lv_smoc / lv_smob
            rho_s = MAX(rho_g(1), MIN(0.13/lv_xds, rho_i-100.))
            else
            lv_xds = 0.
            rho_s = 100.
            endif
            lv_tempc = lv_temp - 273.15
            lv_idx_tc = MAX(1, MIN(NINT(-lv_tempc), 45) )
            lv_idx_t = INT( (lv_tempc-2.5)/5. ) - 1
            lv_idx_t = MAX(1, -lv_idx_t)
            lv_idx_t = MIN(lv_idx_t, ntb_t)
            lv_it = MAX(1, MIN(NINT(-lv_tempc), 31) )
            if (lv_rc.gt. r_c(1)) then
            lv_nic = NINT(ALOG10(lv_rc))
            do lv_nn = lv_nic-1, lv_nic+1
            lv_n = lv_nn
            if ( (lv_rc/10.**lv_nn).ge.1.0 .and.  (lv_rc/10.**lv_nn).lt.10.0) goto 141
            enddo
            141      continue
            lv_idx_c = INT(lv_rc/10.**lv_n) + 10*(lv_n-nic2) - (lv_n-nic2)
            lv_idx_c = MAX(1, MIN(lv_idx_c, ntb_c))
            else
            lv_idx_c = 1
            endif
            lv_idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(lv_nc/t_Nc(1)) / nic1)
            lv_idx_n = MAX(1, MIN(lv_idx_n, nbc))
            if (lv_ri.gt. r_i(1)) then
            lv_nii = NINT(ALOG10(lv_ri))
            do lv_nn = lv_nii-1, lv_nii+1
            lv_n = lv_nn
            if ( (lv_ri/10.**lv_nn).ge.1.0 .and.  (lv_ri/10.**lv_nn).lt.10.0) goto 142
            enddo
            142      continue
            lv_idx_i = INT(lv_ri/10.**lv_n) + 10*(lv_n-nii2) - (lv_n-nii2)
            lv_idx_i = MAX(1, MIN(lv_idx_i, ntb_i))
            else
            lv_idx_i = 1
            endif
            if (lv_ni.gt. Nt_i(1)) then
            lv_nii = NINT(ALOG10(lv_ni))
            do lv_nn = lv_nii-1, lv_nii+1
            lv_n = lv_nn
            if ( (lv_ni/10.**lv_nn).ge.1.0 .and.  (lv_ni/10.**lv_nn).lt.10.0) goto 143
            enddo
            143      continue
            lv_idx_i1 = INT(lv_ni/10.**lv_n) + 10*(lv_n-nii3) - (lv_n-nii3)
            lv_idx_i1 = MAX(1, MIN(lv_idx_i1, ntb_i1))
            else
            lv_idx_i1 = 1
            endif
            if (lv_rr.gt. r_r(1)) then
            lv_nir = NINT(ALOG10(lv_rr))
            do lv_nn = lv_nir-1, lv_nir+1
            lv_n = lv_nn
            if ( (lv_rr/10.**lv_nn).ge.1.0 .and.  (lv_rr/10.**lv_nn).lt.10.0) goto 144
            enddo
            144      continue
            lv_idx_r = INT(lv_rr/10.**lv_n) + 10*(lv_n-nir2) - (lv_n-nir2)
            lv_idx_r = MAX(1, MIN(lv_idx_r, ntb_r))
            lv_lamr = 1./lv_ilamr
            lv_lam_exp = lv_lamr * (crg(3)*org2*org1)**bm_r
            lv_n0_exp = org1*lv_rr/am_r * lv_lam_exp**cre(1)
            lv_nir = NINT(DLOG10(lv_n0_exp))
            do lv_nn = lv_nir-1, lv_nir+1
            lv_n = lv_nn
            if ( (lv_n0_exp/10.**lv_nn).ge.1.0 .and.  (lv_n0_exp/10.**lv_nn).lt.10.0) goto 145
            enddo
            145      continue
            lv_idx_r1 = INT(lv_n0_exp/10.**lv_n) + 10*(lv_n-nir3) - (lv_n-nir3)
            lv_idx_r1 = MAX(1, MIN(lv_idx_r1, ntb_r1))
            else
            lv_idx_r = 1
            lv_idx_r1 = ntb_r1
            endif
            if (lv_rs.gt. r_s(1)) then
            lv_nis = NINT(ALOG10(lv_rs))
            do lv_nn = lv_nis-1, lv_nis+1
            lv_n = lv_nn
            if ( (lv_rs/10.**lv_nn).ge.1.0 .and.  (lv_rs/10.**lv_nn).lt.10.0) goto 146
            enddo
            146      continue
            lv_idx_s = INT(lv_rs/10.**lv_n) + 10*(lv_n-nis2) - (lv_n-nis2)
            lv_idx_s = MAX(1, MIN(lv_idx_s, ntb_s))
            else
            lv_idx_s = 1
            endif
            if (lv_rg.gt. r_g(1)) then
            lv_nig = NINT(ALOG10(lv_rg))
            do lv_nn = lv_nig-1, lv_nig+1
            lv_n = lv_nn
            if ( (lv_rg/10.**lv_nn).ge.1.0 .and.  (lv_rg/10.**lv_nn).lt.10.0) goto 147
            enddo
            147      continue
            lv_idx_g = INT(lv_rg/10.**lv_n) + 10*(lv_n-nig2) - (lv_n-nig2)
            lv_idx_g = MAX(1, MIN(lv_idx_g, ntb_g))
            lv_lamg = 1./lv_ilamg
            lv_lam_exp = lv_lamg * (cgg(3,1)*ogg2*ogg1)**bm_g
            lv_n0_exp = ogg1*lv_rg/am_g(lv_idx_bg) * lv_lam_exp**cge(1,1)
            lv_nig = NINT(DLOG10(lv_n0_exp))
            do lv_nn = lv_nig-1, lv_nig+1
            lv_n = lv_nn
            if ( (lv_n0_exp/10.**lv_nn).ge.1.0 .and.  (lv_n0_exp/10.**lv_nn).lt.10.0) goto 148
            enddo
            148      continue
            lv_idx_g1 = INT(lv_n0_exp/10.**lv_n) + 10*(lv_n-nig3) - (lv_n-nig3)
            lv_idx_g1 = MAX(1, MIN(lv_idx_g1, ntb_g1))
            else
            lv_idx_g = 1
            lv_idx_g1 = ntb_g1
            endif
            lv_otemp = 1./lv_temp
            lv_rvs = lv_rho*lv_qvsi_s
            lv_rvs_p = lv_rvs*lv_otemp*(lsub*lv_otemp*oRv - 1.)
            lv_rvs_pp = lv_rvs * ( lv_otemp*(lsub*lv_otemp*oRv - 1.)  *lv_otemp*(lsub*lv_otemp*oRv - 1.)  + (-2.*lsub*lv_otemp*lv_otemp*lv_otemp*oRv)  + lv_otemp*lv_otemp)
            lv_gamsc = lsub*lv_diffu_s/lv_tcond_s * lv_rvs_p
            lv_alphsc = 0.5*(lv_gamsc/(1.+lv_gamsc))*(lv_gamsc/(1.+lv_gamsc))  * lv_rvs_pp/lv_rvs_p * lv_rvs/lv_rvs_p
            lv_alphsc = MAX(1.E-9, lv_alphsc)
            lv_xsat = lv_ssati_s
            if (abs(lv_xsat).lt. 1.E-9) lv_xsat=0.
            lv_t1_subl = 4.*PI*( 1.0 - lv_alphsc*lv_xsat  + 2.*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat  - 5.*lv_alphsc*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat*lv_xsat )  / (1.+lv_gamsc)
            if (lv_l_qc .and. lv_mvd_c.gt. D0c) then
            if (lv_xds .gt. D0s) then
            lv_idx = 1 + INT(nbs*DLOG(lv_xds/Ds(1))/DLOG(Ds(nbs)/Ds(1)))
            lv_idx = MIN(lv_idx, nbs)
            lv_ef_sw = t_Efsw(lv_idx, INT(lv_mvd_c*1.E6))
            lv_prs_scw = lv_rhof_s*t1_qs_qc*lv_ef_sw*lv_rc*lv_smoe
            lv_prs_scw = MIN(DBLE(lv_rc*lv_odts), lv_prs_scw)
            lv_pnc_scw_s = lv_rhof_s*t1_qs_qc*lv_ef_sw*lv_nc*lv_smoe
            lv_pnc_scw_s = MIN(DBLE(lv_nc*lv_odts), lv_pnc_scw_s)
            endif
            if (lv_rg.ge. r_g(1) .and. lv_mvd_c.gt. D0c) then
            lv_xdg = (bm_g + mu_g + 1.) * lv_ilamg
            lv_vtg = lv_rhof_s*av_g(lv_idx_bg)*cgg(6,lv_idx_bg)*ogg3 * lv_ilamg**bv_g(lv_idx_bg)
            lv_stoke_g = lv_mvd_c*lv_mvd_c*lv_vtg*rho_w/(9.*lv_visco_s*lv_xdg)
            lv_const_ri = -1.*(lv_mvd_c*0.5E6)*lv_vtg/MIN(-0.1,lv_tempc)
            lv_const_ri = MAX(0.1, MIN(lv_const_ri, 10.))
            lv_rime_dens = (0.051 + 0.114*lv_const_ri - 0.0055*lv_const_ri*lv_const_ri)*1000.
            if (lv_stoke_g.ge.0.4 .and. lv_stoke_g.le.10.) then
            lv_ef_gw = 0.55*ALOG10(2.51*lv_stoke_g)
            elseif (lv_stoke_g.lt.0.4) then
            lv_ef_gw = 0.0
            elseif (lv_stoke_g.gt.10) then
            lv_ef_gw = 0.77
            endif
            if (lv_twet_k.gt.T_0) lv_ef_gw = lv_ef_gw*0.1
            t1_qg_qc = PI*.25*av_g(lv_idx_bg) * cgg(9,lv_idx_bg)
            lv_prg_gcw = lv_rhof_s*t1_qg_qc*lv_ef_gw*lv_rc*lv_n0_g  *lv_ilamg**cge(9,lv_idx_bg)
            lv_pnc_gcw_s = lv_rhof_s*t1_qg_qc*lv_ef_gw*lv_nc*lv_n0_g            *lv_ilamg**cge(9,lv_idx_bg)
            lv_pnc_gcw_s = MIN(DBLE(lv_nc*lv_odts), lv_pnc_gcw_s)
            if (lv_twet_k.lt.T_0) lv_pbg_gcw_s = lv_prg_gcw/lv_rime_dens
            endif
            endif
            if (lv_rs .gt. r_s(1)) then
            lv_ef_sa = Eff_aero(lv_xds,0.04E-6,lv_visco_s,lv_rho,lv_temp,'s')
            lv_pna_sca_s = lv_rhof_s*t1_qs_qc*lv_ef_sa*lv_nwfa*lv_smoe
            lv_pna_sca_s = MIN(DBLE(lv_nwfa*lv_odts), lv_pna_sca_s)
            lv_ef_sa = Eff_aero(lv_xds,0.8E-6,lv_visco_s,lv_rho,lv_temp,'s')
            lv_pnd_scd_s = lv_rhof_s*t1_qs_qc*lv_ef_sa*lv_nifa*lv_smoe
            lv_pnd_scd_s = MIN(DBLE(lv_nifa*lv_odts), lv_pnd_scd_s)
            if (.true.) then
            if (gpu_wif .eq. 2) then
            lv_ef_sa = Eff_aero(lv_xds,0.0236E-6,lv_visco_s,lv_rho,lv_temp,'s')
            lv_pnb_scb_s = lv_rhof_s*t1_qs_qc*lv_ef_sa*lv_nbca*lv_smoe
            lv_pnb_scb_s = MIN(DBLE(lv_nbca*lv_odts), lv_pnb_scb_s)
            endif
            endif
            endif
            if (lv_rg .gt. r_g(1)) then
            lv_xdg = (bm_g + mu_g + 1.) * lv_ilamg
            lv_ef_ga = Eff_aero(lv_xdg,0.04E-6,lv_visco_s,lv_rho,lv_temp,'g')
            t1_qg_qc = PI*.25*av_g(lv_idx_bg) * cgg(9,lv_idx_bg)
            lv_pna_gca_s = lv_rhof_s*t1_qg_qc*lv_ef_ga*lv_nwfa*lv_n0_g            *lv_ilamg**cge(9,lv_idx_bg)
            lv_pna_gca_s = MIN(DBLE(lv_nwfa*lv_odts), lv_pna_gca_s)
            lv_ef_ga = Eff_aero(lv_xdg,0.8E-6,lv_visco_s,lv_rho,lv_temp,'g')
            lv_pnd_gcd_s = lv_rhof_s*t1_qg_qc*lv_ef_ga*lv_nifa*lv_n0_g            *lv_ilamg**cge(9,lv_idx_bg)
            lv_pnd_gcd_s = MIN(DBLE(lv_nifa*lv_odts), lv_pnd_gcd_s)
            if (.true.) then
            if (gpu_wif .eq. 2) then
            lv_ef_ga = Eff_aero(lv_xdg,0.0236E-6,lv_visco_s,lv_rho,lv_temp,'g')
            lv_pnb_gcb_s = lv_rhof_s*t1_qg_qc*lv_ef_ga*lv_nbca*lv_n0_g        *lv_ilamg**cge(9,lv_idx_bg)
            lv_pnb_gcb_s = MIN(DBLE(lv_nbca*lv_odts), lv_pnb_gcb_s)
            endif
            endif
            endif
            if (lv_rr.ge. r_r(1)) then
            if (lv_rs.ge. r_s(1)) then
            if (lv_twet_k.lt.T_0) then
            lv_prr_rcs_s = -(tmr_racs2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tcr_sacr2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tmr_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tcr_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r))
            lv_prs_rcs_s = tmr_racs2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tcr_sacr2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  - tcs_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  - tms_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)
            lv_prg_rcs_s = tmr_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tcr_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tcs_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)  + tms_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)
            lv_prr_rcs_s = MAX(DBLE(-lv_rr*lv_odts), lv_prr_rcs_s)
            lv_prs_rcs_s = MAX(DBLE(-lv_rs*lv_odts), lv_prs_rcs_s)
            lv_prg_rcs_s = MIN(DBLE((lv_rr+lv_rs)*lv_odts), lv_prg_rcs_s)
            lv_pnr_rcs_s = tnr_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)             + tnr_racs2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)           + tnr_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)           + tnr_sacr2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)
            lv_pnr_rcs_s = MIN(DBLE(lv_nr*lv_odts), lv_pnr_rcs_s)
            lv_png_rcs_s = lv_pnr_rcs_s
            lv_pbg_rcs_s = lv_prg_rcs_s/rho_i
            else
            lv_prs_rcs_s = -tcs_racs1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)            - tms_sacr1(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)           + tmr_racs2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)           + tcr_sacr2(lv_idx_s,lv_idx_t,lv_idx_r1,lv_idx_r)
            lv_prs_rcs_s = MAX(DBLE(-lv_rs*lv_odts), lv_prs_rcs_s)
            lv_prr_rcs_s = -lv_prs_rcs_s
            endif
            endif
            if (lv_rg.ge. r_g(1)) then
            if (lv_twet_k.lt.T_0) then
            lv_prg_rcg_s = tmr_racg(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)   + tcr_gacr(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)
            lv_prg_rcg_s = MIN(DBLE(lv_rr*lv_odts), lv_prg_rcg_s)
            lv_prr_rcg_s = -lv_prg_rcg_s
            lv_pnr_rcg_s = tnr_racg(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)   + tnr_gacr(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)
            lv_pnr_rcg_s = MIN(DBLE(lv_nr*lv_odts), lv_pnr_rcg_s)
            lv_pbg_rcg_s = lv_prg_rcg_s/rho_i
            else
            lv_prr_rcg_s = tcg_racg(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)
            lv_prr_rcg_s = MIN(DBLE(lv_rg*lv_odts), lv_prr_rcg_s)
            lv_prg_rcg_s = -lv_prr_rcg_s
            lv_png_rcg_s = tnr_racg(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)
            lv_png_rcg_s = MIN(DBLE(lv_ng*lv_odts), lv_png_rcg_s)
            lv_pbg_rcg_s = lv_prg_rcg_s/rho_g(lv_idx_bg)
            lv_pnr_rcg_s = -1.5*tnr_gacr(lv_idx_g1,lv_idx_g,lv_idx_bg,lv_idx_r1,lv_idx_r)
            endif
            endif
            endif
            if (lv_temp.lt.T_0) then
            lv_vts_boost = 1.0
            lv_rate_max = (lv_qv-lv_qvsi_s)*lv_rho*lv_odts*0.999
            if (dustyIce .AND. is_aerosol_aware) then
            lv_xni = iceDeMott(lv_tempc,lv_qvs_s,lv_qvs_s,lv_qvsi_s,lv_rho,lv_nifa)
            else
            lv_xni = 1.0 *1000.
            endif
            if (lv_xni.gt. Nt_IN(1)) then
            lv_niin = NINT(ALOG10(lv_xni))
            do lv_nn = lv_niin-1, lv_niin+1
            lv_n = lv_nn
            if ( (lv_xni/10.**lv_nn).ge.1.0 .and.  (lv_xni/10.**lv_nn).lt.10.0) goto 149
            enddo
            149       continue
            lv_idx_in = INT(lv_xni/10.**lv_n) + 10*(lv_n-niin2) - (lv_n-niin2)
            lv_idx_in = MAX(1, MIN(lv_idx_in, ntb_IN))
            else
            lv_idx_in = 1
            endif
            if (lv_rr.gt. r_r(1)) then
            lv_prg_rfz_s = tpg_qrfz(lv_idx_r,lv_idx_r1,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pri_rfz_s = tpi_qrfz(lv_idx_r,lv_idx_r1,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pni_rfz_s = tni_qrfz(lv_idx_r,lv_idx_r1,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pnr_rfz_s = tnr_qrfz(lv_idx_r,lv_idx_r1,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pnr_rfz_s = MIN(DBLE(lv_nr*lv_odts), lv_pnr_rfz_s)
            elseif (lv_rr.gt. R1 .and. lv_temp.lt.HGFR) then
            lv_pri_rfz_s = lv_rr*lv_odts
            lv_pni_rfz_s = lv_nr*lv_odts
            endif
            lv_pbg_rfz_s = lv_prg_rfz_s/rho_i
            if (lv_rc.gt. r_c(1)) then
            lv_pri_wfz_s = tpi_qcfz(lv_idx_c,lv_idx_n,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pri_wfz_s = MIN(DBLE(lv_rc*lv_odts), lv_pri_wfz_s)
            lv_pni_wfz_s = tni_qcfz(lv_idx_c,lv_idx_n,lv_idx_tc,lv_idx_in)*lv_odts
            lv_pni_wfz_s = MIN(DBLE(lv_nc*lv_odts), lv_pri_wfz_s/(2.*xm0i),      lv_pni_wfz_s)
            elseif (lv_rc.gt. R1 .and. lv_temp.lt.HGFR) then
            lv_pri_wfz_s = lv_rc*lv_odts
            lv_pni_wfz_s = lv_nc*lv_odts
            endif
            if ( (lv_ssati_s.ge. 0.25) .or. (lv_ssatw_s.gt. eps  .and. lv_temp.lt.253.15) ) then
            if (dustyIce .AND. is_aerosol_aware) then
            lv_xnc = iceDeMott(lv_tempc,lv_qv,lv_qvs_s,lv_qvsi_s,lv_rho,lv_nifa)
            else
            lv_xnc = MIN(250.E3, TNO*EXP(ATO*(T_0-lv_temp)))
            endif
            lv_xni = lv_ni + (lv_pni_rfz_s+lv_pni_wfz_s)*lv_dtsave
            lv_pni_inu_s = 0.5*(lv_xnc-lv_xni + abs(lv_xnc-lv_xni))*lv_odts
            lv_pri_inu_s = MIN(DBLE(lv_rate_max), xm0i*lv_pni_inu_s)
            lv_pni_inu_s = lv_pri_inu_s/xm0i
            endif
            lv_xni = lv_ns+lv_ni + (lv_pni_rfz_s+lv_pni_wfz_s+lv_pni_inu_s)*lv_dtsave
            if (is_aerosol_aware .AND. homogIce .AND. (lv_xni.le.999.E3)      .AND.(lv_temp.lt.238).AND.(lv_ssati_s.ge.0.4) ) then
            lv_xnc = iceKoop(lv_temp,lv_qv,lv_qvs_s,lv_nwfa, lv_dtsave)
            lv_pni_iha_s = lv_xnc*lv_odts
            lv_pri_iha_s = MIN(DBLE(lv_rate_max), xm0i*0.1*lv_pni_iha_s)
            lv_pni_iha_s = lv_pri_iha_s/(xm0i*0.1)
            endif
            if (lv_l_qi) then
            lv_lami = (am_i*cig(2)*oig1*lv_ni/lv_ri)**obmi
            lv_ilami = 1./lv_lami
            lv_xdi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * lv_ilami)
            lv_xmi = am_i*lv_xdi**bm_i
            lv_oxmi = 1./lv_xmi
            lv_pri_ide_s = C_cube*lv_t1_subl*lv_diffu_s*lv_ssati_s*lv_rvs  *oig1*cig(5)*lv_ni*lv_ilami
            if (lv_pri_ide_s .lt. 0.0) then
            lv_pri_ide_s = MAX(DBLE(-lv_ri*lv_odts), lv_pri_ide_s, DBLE(lv_rate_max))
            lv_pni_ide_s = lv_pri_ide_s*lv_oxmi
            lv_pni_ide_s = MAX(DBLE(-lv_ni*lv_odts), lv_pni_ide_s)
            else
            lv_pri_ide_s = MIN(lv_pri_ide_s, DBLE(lv_rate_max))
            lv_prs_ide_s = (1.0D0-tpi_ide(lv_idx_i,lv_idx_i1))*lv_pri_ide_s
            lv_pri_ide_s = tpi_ide(lv_idx_i,lv_idx_i1)*lv_pri_ide_s
            endif
            if ( (lv_idx_i.eq. ntb_i) .or. (lv_xdi.gt. 5.0*D0s) ) then
            lv_prs_iau = lv_ri*.99*lv_odts
            lv_pni_iau_s = lv_ni*.95*lv_odts
            elseif (lv_xdi.lt. 0.1*D0s) then
            lv_prs_iau = 0.
            lv_pni_iau_s = 0.
            else
            lv_prs_iau = tps_iaus(lv_idx_i,lv_idx_i1)*lv_odts
            lv_prs_iau = MIN(DBLE(lv_ri*.99*lv_odts), lv_prs_iau)
            lv_pni_iau_s = tni_iaus(lv_idx_i,lv_idx_i1)*lv_odts
            lv_pni_iau_s = MIN(DBLE(lv_ni*.95*lv_odts), lv_pni_iau_s)
            endif
            endif
            if (lv_l_qs) then
            lv_c_snow = C_sqrd + (lv_tempc+1.5)*(C_cube-C_sqrd)/(-30.+1.5)
            lv_c_snow = MAX(C_sqrd, MIN(lv_c_snow, C_cube))
            lv_prs_sde = lv_c_snow*lv_t1_subl*lv_diffu_s*lv_ssati_s*lv_rvs  * (t1_qs_sd*lv_smo1  + t2_qs_sd*lv_rhof2_s*lv_vsc2_s*lv_smof)
            if (lv_prs_sde.lt. 0.) then
            lv_prs_sde = MAX(DBLE(-lv_rs*lv_odts), lv_prs_sde, DBLE(lv_rate_max))
            else
            lv_prs_sde = MIN(lv_prs_sde, DBLE(lv_rate_max))
            endif
            endif
            if (lv_l_qg .and. lv_ssati_s.lt. -eps) then
            t2_qg_sd = 0.28*Sc3*SQRT(av_g(lv_idx_bg)) * cgg(11,lv_idx_bg)
            lv_prg_gde = C_cube*lv_t1_subl*lv_diffu_s*lv_ssati_s*lv_rvs  * lv_n0_g * (t1_qg_sd*lv_ilamg**cge(10,1)  + t2_qg_sd*lv_vsc2_s*lv_rhof2_s*lv_ilamg**cge(11,lv_idx_bg))
            if (lv_prg_gde.lt. 0.) then
            lv_prg_gde = MAX(DBLE(-lv_rg*lv_odts), lv_prg_gde, DBLE(lv_rate_max))
            lv_png_gde_s = lv_prg_gde * lv_ng/lv_rg
            else
            lv_prg_gde = MIN(lv_prg_gde, DBLE(lv_rate_max))
            endif
            endif
            if (lv_l_qi) then
            lv_lami = (am_i*cig(2)*oig1*lv_ni/lv_ri)**obmi
            lv_ilami = 1./lv_lami
            lv_xdi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * lv_ilami)
            lv_xmi = am_i*lv_xdi**bm_i
            lv_oxmi = 1./lv_xmi
            if (lv_rs.ge. r_s(1)) then
            lv_prs_sci = t1_qs_qi*lv_rhof_s*Ef_si*lv_ri*lv_smoe
            lv_pni_sci_s = lv_prs_sci * lv_oxmi
            endif
            if (lv_rr.ge. r_r(1) .and. lv_mvd_r.gt. 4.*lv_xdi) then
            lv_lamr = 1./lv_ilamr
            lv_pri_rci = lv_rhof_s*t1_qr_qi*Ef_ri*lv_ri*lv_n0_r  *((lv_lamr+fv_r)**(-cre(9)))
            lv_pnr_rci_s = lv_rhof_s*t1_qr_qi*Ef_ri*lv_ni*lv_n0_r            *((lv_lamr+fv_r)**(-cre(9)))
            lv_pnr_rci_s = MIN(DBLE(lv_nr*lv_odts), lv_pnr_rci_s)
            lv_pni_rci_s = lv_pri_rci * lv_oxmi
            lv_prr_rci_s = lv_rhof_s*t2_qr_qi*Ef_ri*lv_ni*lv_n0_r  *((lv_lamr+fv_r)**(-cre(8)))
            lv_prr_rci_s = MIN(DBLE(lv_rr*lv_odts), lv_prr_rci_s)
            lv_prg_rci_s = lv_pri_rci + lv_prr_rci_s
            lv_pbg_rci_s = lv_prg_rci_s/rho_i
            endif
            endif
            if (lv_prg_gcw.gt. eps .and. lv_tempc.gt.-8.0) then
            lv_tf = 0.
            if (lv_tempc.ge.-5.0 .and. lv_tempc.lt.-3.0) then
            lv_tf = 0.5*(-3.0 - lv_tempc)
            elseif (lv_tempc.gt.-8.0 .and. lv_tempc.lt.-5.0) then
            lv_tf = 0.33333333*(8.0 + lv_tempc)
            endif
            lv_pni_ihm_s = 3.5E8*lv_tf*lv_prg_gcw
            lv_pri_ihm_s = xm0i*lv_pni_ihm_s
            lv_prs_ihm_s = lv_prs_scw/(lv_prs_scw+lv_prg_gcw)  * lv_pri_ihm_s
            lv_prg_ihm_s = lv_prg_gcw/(lv_prs_scw+lv_prg_gcw)  * lv_pri_ihm_s
            endif
            if (lv_prs_scw.gt.2.0*lv_prs_sde .and.  lv_prs_sde.gt.eps) then
            lv_r_frac = MIN(30.0D0, lv_prs_scw/lv_prs_sde)
            lv_g_frac = MIN(0.95, 0.15 + (lv_r_frac-2.)*.028)
            lv_vts_boost = MIN(1.5, 1.1 + (lv_r_frac-2.)*.014)
            lv_prg_scw = lv_g_frac*lv_prs_scw
            lv_png_scw_s = lv_prg_scw*lv_smo0/lv_rs
            lv_vts = av_s*lv_xds**bv_s * EXP(-fv_s*lv_xds)
            lv_const_ri = -1.*(lv_mvd_c*0.5E6)*lv_vts/MIN(-0.1,lv_tempc)
            lv_const_ri = MAX(0.1, MIN(lv_const_ri, 10.))
            lv_rime_dens = (0.051 + 0.114*lv_const_ri - 0.0055*lv_const_ri*lv_const_ri)*1000.
            if(lv_rime_dens .lt. 150.) then
            lv_g_frac = 0.
            lv_prg_scw=0.
            lv_png_scw_s=0.
            endif
            lv_pbg_scw_s = lv_prg_scw/(0.5*(lv_rime_dens+rho_s))
            lv_prs_scw = (1. - lv_g_frac)*lv_prs_scw
            endif
            else
            if (lv_l_qs) then
            lv_prr_sml = (lv_tempc*lv_tcond_s-lvap0*lv_diffu_s*lv_delqvs_s)        * (t1_qs_me*lv_smo1 + t2_qs_me*lv_rhof2_s*lv_vsc2_s*lv_smof)
            if (lv_prr_sml .gt. 0.) then
            lv_prr_sml = lv_prr_sml + 4218.*olfus*(lv_twet_k-T_0)        * (lv_prr_rcs_s+lv_prs_scw)
            endif
            lv_prr_sml = MIN(DBLE(lv_rs*lv_odts), MAX(0.D0, lv_prr_sml))
            if (lv_prr_sml.gt.0.0) then
            lv_pnr_sml_s = lv_smo0/lv_rs*lv_prr_sml * 10.0**(-0.25*(lv_twet_k-T_0))
            elseif (lv_ssati_s.lt. 0.) then
            lv_prs_sde = C_sqrd*lv_t1_subl*lv_diffu_s*lv_ssati_s*lv_rvs  * (t1_qs_sd*lv_smo1  + t2_qs_sd*lv_rhof2_s*lv_vsc2_s*lv_smof)
            lv_prs_sde = MAX(DBLE(-lv_rs*lv_odts), lv_prs_sde)
            endif
            endif
            if (lv_l_qg) then
            lv_n0_melt = lv_n0_g
            if ((lv_rg*lv_ng) .lt. 1.E-4) then
            lv_lamg = 1./lv_ilamg
            lv_n0_melt = (1.E-4/lv_rg)*ogg2*lv_lamg**cge(2,1)
            endif
            t2_qg_me = PI*4.*C_cube*olfus * 0.28*Sc3*SQRT(av_g(lv_idx_bg)) * cgg(11,lv_idx_bg)
            lv_prr_gml = (lv_tempc*lv_tcond_s-lvap0*lv_diffu_s*lv_delqvs_s)        * lv_n0_melt*(t1_qg_me*lv_ilamg**cge(10,1)            + t2_qg_me*lv_rhof2_s*lv_vsc2_s*lv_ilamg**cge(11,lv_idx_bg))
            lv_prr_gml = MIN(DBLE(lv_rg*lv_odts), MAX(0.D0, lv_prr_gml))
            if (lv_prr_gml .gt. 0.0) then
            lv_melt_f = MAX(0.05, MIN(lv_prr_gml*dt/lv_rg,1.0))
            lv_pbg_gml_s = lv_prr_gml / MAX(MIN(lv_melt_f*rho_g(lv_idx_bg),1000.),50.)
            lv_pnr_gml_s = lv_prr_gml*lv_ng/lv_rg * 10.0**(-0.33*(lv_twet_k-T_0))
            elseif (lv_ssati_s.lt. 0.) then
            t2_qg_sd = 0.28*Sc3*SQRT(av_g(lv_idx_bg)) * cgg(11,lv_idx_bg)
            lv_prg_gde = C_cube*lv_t1_subl*lv_diffu_s*lv_ssati_s*lv_rvs  * lv_n0_g * (t1_qg_sd*lv_ilamg**cge(10,1)  + t2_qg_sd*lv_vsc2_s*lv_rhof2_s*lv_ilamg**cge(11,lv_idx_bg))
            lv_prg_gde = MAX(DBLE(-lv_rg*lv_odts), lv_prg_gde)
            lv_png_gde_s = lv_prg_gde * lv_ng/lv_rg
            endif
            endif
            if (dt .gt. 120.) then
            lv_prr_rcw=lv_prr_rcw+lv_prs_scw+lv_prg_gcw
            lv_prs_scw=0.
            lv_prg_gcw=0.
            endif
            endif
            if (.not. is_hail_aware) lv_idx_bg = idx_bg1
            endif
            lv_sump = lv_pri_inu_s + lv_pri_ide_s + lv_prs_ide_s  + lv_prs_sde + lv_prg_gde + lv_pri_iha_s
            lv_rate_max = (lv_qv-lv_qvsi_s)*lv_rho*lv_odts*0.999
            if ( (lv_sump.gt. eps .and. lv_sump.gt. lv_rate_max) .or.  (lv_sump.lt. -eps .and. lv_sump.lt. lv_rate_max) ) then
            lv_ratio = lv_rate_max/lv_sump
            lv_pri_inu_s = lv_pri_inu_s * lv_ratio
            lv_pri_ide_s = lv_pri_ide_s * lv_ratio
            lv_pni_ide_s = lv_pni_ide_s * lv_ratio
            lv_prs_ide_s = lv_prs_ide_s * lv_ratio
            lv_prs_sde = lv_prs_sde * lv_ratio
            lv_prg_gde = lv_prg_gde * lv_ratio
            lv_pri_iha_s = lv_pri_iha_s * lv_ratio
            endif
            lv_sump = -lv_prr_wau - lv_pri_wfz_s - lv_prr_rcw  - lv_prs_scw - lv_prg_scw - lv_prg_gcw
            lv_rate_max = -lv_rc*lv_odts
            if (lv_sump.lt. lv_rate_max .and. lv_l_qc) then
            lv_ratio = lv_rate_max/lv_sump
            lv_prr_wau = lv_prr_wau * lv_ratio
            lv_pri_wfz_s = lv_pri_wfz_s * lv_ratio
            lv_prr_rcw = lv_prr_rcw * lv_ratio
            lv_prs_scw = lv_prs_scw * lv_ratio
            lv_prg_scw = lv_prg_scw * lv_ratio
            lv_prg_gcw = lv_prg_gcw * lv_ratio
            endif
            lv_sump = lv_pri_ide_s - lv_prs_iau - lv_prs_sci  - lv_pri_rci
            lv_rate_max = -lv_ri*lv_odts
            if (lv_sump.lt. lv_rate_max .and. lv_l_qi) then
            lv_ratio = lv_rate_max/lv_sump
            lv_pri_ide_s = lv_pri_ide_s * lv_ratio
            lv_prs_iau = lv_prs_iau * lv_ratio
            lv_prs_sci = lv_prs_sci * lv_ratio
            lv_pri_rci = lv_pri_rci * lv_ratio
            endif
            lv_sump = -lv_prg_rfz_s - lv_pri_rfz_s - lv_prr_rci_s  + lv_prr_rcs_s + lv_prr_rcg_s
            lv_rate_max = -lv_rr*lv_odts
            if (lv_sump.lt. lv_rate_max .and. lv_l_qr) then
            lv_ratio = lv_rate_max/lv_sump
            lv_prg_rfz_s = lv_prg_rfz_s * lv_ratio
            lv_pri_rfz_s = lv_pri_rfz_s * lv_ratio
            lv_prr_rci_s = lv_prr_rci_s * lv_ratio
            lv_prr_rcs_s = lv_prr_rcs_s * lv_ratio
            lv_prr_rcg_s = lv_prr_rcg_s * lv_ratio
            endif
            lv_sump = lv_prs_sde - lv_prs_ihm_s - lv_prr_sml  + lv_prs_rcs_s
            lv_rate_max = -lv_rs*lv_odts
            if (lv_sump.lt. lv_rate_max .and. lv_l_qs) then
            lv_ratio = lv_rate_max/lv_sump
            lv_prs_sde = lv_prs_sde * lv_ratio
            lv_prs_ihm_s = lv_prs_ihm_s * lv_ratio
            lv_prr_sml = lv_prr_sml * lv_ratio
            lv_prs_rcs_s = lv_prs_rcs_s * lv_ratio
            endif
            lv_sump = lv_prg_gde - lv_prg_ihm_s - lv_prr_gml  + lv_prg_rcg_s
            lv_rate_max = -lv_rg*lv_odts
            if (lv_sump.lt. lv_rate_max .and. lv_l_qg) then
            lv_ratio = lv_rate_max/lv_sump
            lv_prg_gde = lv_prg_gde * lv_ratio
            lv_prg_ihm_s = lv_prg_ihm_s * lv_ratio
            lv_prr_gml = lv_prr_gml * lv_ratio
            lv_prg_rcg_s = lv_prg_rcg_s * lv_ratio
            endif
            lv_pri_ihm_s = lv_prs_ihm_s + lv_prg_ihm_s
            lv_ratio = MIN( ABS(lv_prr_rcg_s), ABS(lv_prg_rcg_s) )
            lv_prr_rcg_s = lv_ratio * SIGN(1.0, SNGL(lv_prr_rcg_s))
            lv_prg_rcg_s = -lv_prr_rcg_s
            if (lv_twet_k.gt.T_0) then
            lv_ratio = MIN( ABS(lv_prr_rcs_s), ABS(lv_prs_rcs_s) )
            lv_prr_rcs_s = lv_ratio * SIGN(1.0, SNGL(lv_prr_rcs_s))
            lv_prs_rcs_s = -lv_prr_rcs_s
            endif
            lv_orho = 1./lv_rho
            lv_lfus2 = lsub - lv_lvap_s
            if (is_aerosol_aware) then
            lv_nwfaten = lv_nwfaten - (lv_pna_rca_s + lv_pna_sca_s           + lv_pna_gca_s + lv_pni_iha_s) * lv_orho
            lv_nifaten = lv_nifaten - (lv_pnd_rcd_s + lv_pnd_scd_s           + lv_pnd_gcd_s) * lv_orho
            if (gpu_wif .eq. 2) then
            lv_nbcaten = lv_nbcaten - (lv_pnb_rcb_s + lv_pnb_scb_s        + lv_pnb_gcb_s) * lv_orho
            else
            lv_nbcaten = 0.0
            endif
            if (dustyIce) then
            lv_nifaten = lv_nifaten - lv_pni_inu_s*lv_orho
            else
            lv_nifaten = 0.
            endif
            endif
            lv_qvten = lv_qvten + (-lv_pri_inu_s - lv_pri_iha_s - lv_pri_ide_s    - lv_prs_ide_s - lv_prs_sde - lv_prg_gde)  * lv_orho
            lv_qcten = lv_qcten + (-lv_prr_wau - lv_pri_wfz_s  - lv_prr_rcw - lv_prs_scw - lv_prg_scw  - lv_prg_gcw)  * lv_orho
            lv_ncten = lv_ncten + (-lv_pnc_wau_s - lv_pnc_rcw_s  - lv_pni_wfz_s - lv_pnc_scw_s - lv_pnc_gcw_s)  * lv_orho
            lv_xrc=MAX(R1, (sv_qc1d + lv_qcten*lv_dtsave)*lv_rho)
            lv_xnc=MAX(2., (sv_nc1d + lv_ncten*lv_dtsave)*lv_rho)
            if (lv_xrc .gt. R1) then
            lv_nu_c = MIN(15, NINT(1000.E6/lv_xnc) + 2)
            lv_lamc = (lv_xnc*am_r*ccg(2,lv_nu_c)*ocg1(lv_nu_c)/lv_rc)**obmr
            lv_xdc = (bm_r + lv_nu_c + 1.) / lv_lamc
            if (lv_xdc.lt. D0c) then
            lv_lamc = cce(2,lv_nu_c)/D0c
            lv_xnc = ccg(1,lv_nu_c)*ocg2(lv_nu_c)*lv_xrc/am_r*lv_lamc**bm_r
            lv_ncten = (lv_xnc-sv_nc1d*lv_rho)*lv_odts*lv_orho
            elseif (lv_xdc.gt. D0r*2.) then
            lv_lamc = cce(2,lv_nu_c)/(D0r*2.)
            lv_xnc = ccg(1,lv_nu_c)*ocg2(lv_nu_c)*lv_xrc/am_r*lv_lamc**bm_r
            lv_ncten = (lv_xnc-sv_nc1d*lv_rho)*lv_odts*lv_orho
            endif
            else
            lv_ncten = -sv_nc1d*lv_odts
            endif
            lv_xnc=MAX(0.,(sv_nc1d + lv_ncten*lv_dtsave)*lv_rho)
            if (lv_xnc.gt.Nt_c_max)  lv_ncten = (Nt_c_max-sv_nc1d*lv_rho)*lv_odts*lv_orho
            lv_qiten = lv_qiten + (lv_pri_inu_s + lv_pri_iha_s + lv_pri_ihm_s     + lv_pri_wfz_s + lv_pri_rfz_s + lv_pri_ide_s  - lv_prs_iau - lv_prs_sci - lv_pri_rci)  * lv_orho
            lv_niten = lv_niten + (lv_pni_inu_s + lv_pni_iha_s + lv_pni_ihm_s     + lv_pni_wfz_s + lv_pni_rfz_s + lv_pni_ide_s  - lv_pni_iau_s - lv_pni_sci_s - lv_pni_rci_s)  * lv_orho
            lv_xri=MAX(R1,(sv_qi1d + lv_qiten*lv_dtsave)*lv_rho)
            lv_xni=MAX(R2,(sv_ni1d + lv_niten*lv_dtsave)*lv_rho)
            if (lv_xri.gt. R1) then
            lv_lami = (am_i*cig(2)*oig1*lv_xni/lv_xri)**obmi
            lv_ilami = 1./lv_lami
            lv_xdi = (bm_i + mu_i + 1.) * lv_ilami
            if (lv_xdi.lt. 5.E-6) then
            lv_lami = cie(2)/5.E-6
            lv_xni = MIN(999.D3, cig(1)*oig2*lv_xri/am_i*lv_lami**bm_i)
            lv_niten = (lv_xni-sv_ni1d*lv_rho)*lv_odts*lv_orho
            elseif (lv_xdi.gt. 300.E-6) then
            lv_lami = cie(2)/300.E-6
            lv_xni = cig(1)*oig2*lv_xri/am_i*lv_lami**bm_i
            lv_niten = (lv_xni-sv_ni1d*lv_rho)*lv_odts*lv_orho
            endif
            else
            lv_niten = -sv_ni1d*lv_odts
            endif
            lv_xni=MAX(0.,(sv_ni1d + lv_niten*lv_dtsave)*lv_rho)
            if (lv_xni.gt.999.E3)  lv_niten = (999.E3-sv_ni1d*lv_rho)*lv_odts*lv_orho
            lv_qrten = lv_qrten + (lv_prr_wau + lv_prr_rcw  + lv_prr_sml + lv_prr_gml + lv_prr_rcs_s  + lv_prr_rcg_s - lv_prg_rfz_s  - lv_pri_rfz_s - lv_prr_rci_s)  * lv_orho
            lv_nrten = lv_nrten + (lv_pnr_wau_s + lv_pnr_sml_s + lv_pnr_gml_s     - (lv_pnr_rfz_s + lv_pnr_rcr_s + lv_pnr_rcg_s            + lv_pnr_rcs_s + lv_pnr_rci_s + lv_pni_rfz_s) )          * lv_orho
            lv_xrr=MAX(R1,(sv_qr1d + lv_qrten*lv_dtsave)*lv_rho)
            lv_xnr=MAX(R2,(sv_nr1d + lv_nrten*lv_dtsave)*lv_rho)
            if (lv_xrr.gt. R1) then
            lv_lamr = (am_r*crg(3)*org2*lv_xnr/lv_xrr)**obmr
            lv_mvd_r = (3.0 + mu_r + 0.672) / lv_lamr
            if (lv_mvd_r .gt. 2.5E-3) then
            lv_mvd_r = 2.5E-3
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_xnr = crg(2)*org3*lv_xrr*lv_lamr**bm_r / am_r
            lv_nrten = (lv_xnr-sv_nr1d*lv_rho)*lv_odts*lv_orho
            elseif (lv_mvd_r .lt. D0r*0.75) then
            lv_mvd_r = D0r*0.75
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_xnr = crg(2)*org3*lv_xrr*lv_lamr**bm_r / am_r
            lv_nrten = (lv_xnr-sv_nr1d*lv_rho)*lv_odts*lv_orho
            endif
            else
            lv_qrten = -sv_qr1d*lv_odts
            lv_nrten = -sv_nr1d*lv_odts
            endif
            lv_qsten = lv_qsten + (lv_prs_iau + lv_prs_sde + lv_prs_sci     + lv_prs_scw + lv_prs_rcs_s + lv_prs_ide_s             - lv_prs_ihm_s - lv_prr_sml)                         * lv_orho
            lv_qgten = lv_qgten + (lv_prg_scw + lv_prg_rfz_s  + lv_prg_gde + lv_prg_rcg_s + lv_prg_gcw  + lv_prg_rci_s + lv_prg_rcs_s - lv_prg_ihm_s  - lv_prr_gml)                           * lv_orho
            lv_ngten = lv_ngten + (lv_png_scw_s + lv_pnr_rfz_s - lv_png_rcg_s     + lv_pnr_rci_s + lv_png_rcs_s + lv_png_gde_s             - lv_pnr_gml_s) * lv_orho
            lv_qbten = lv_qbten + (lv_pbg_scw_s + lv_pbg_rfz_s                  + lv_pbg_gcw_s + lv_pbg_rci_s + lv_pbg_rcs_s             + lv_pbg_rcg_s + lv_pbg_sml_s - lv_pbg_gml_s             + (lv_prg_gde - lv_prg_ihm_s) /rho_g(lv_idx_bg) )    * lv_orho
            lv_xrg=MAX(R1,(sv_qg1d + lv_qgten*lv_dtsave)*lv_rho)
            lv_xng=MAX(R2,(sv_ng1d + lv_ngten*lv_dtsave)*lv_rho)
            lv_xrb=MAX(lv_xrg/lv_rho/rho_g(NRHG),(sv_qb1d + lv_qbten*lv_dtsave))
            lv_xrb=MIN(lv_xrg/lv_rho/rho_g(1), lv_xrb)
            if (lv_xrg .gt. R1) then
            lv_lamg = (am_g(lv_idx_bg)*cgg(3,1)*ogg2*lv_xng/lv_xrg)**obmg
            lv_mvd_g = (3.0 + mu_g + 0.672) / lv_lamg
            if(lv_debug_flag) then
            lv_xrho_g = MAX(rho_g(1),MIN(lv_rg/lv_rho/lv_rb,rho_g(NRHG)))
            lv_afall = a_coeff*((4.0*lv_xrho_g*9.8)/(3.0*lv_rho))**b_coeff
            lv_afall = lv_afall * lv_visco_s**(1.0-2.0*b_coeff)
            lv_vtg1 = lv_rhof_s*lv_afall*cgg(6,lv_idx_bg)*ogg3 / lv_lamg**lv_bfall
            lv_vtg2 = lv_rhof_s*lv_afall*cgg(7,lv_idx_bg)/cgg(12,lv_idx_bg) / lv_lamg**lv_bfall
            endif
            if (lv_mvd_g .gt. 25.4E-3) then
            lv_mvd_g = 25.4E-3
            lv_lamg = (3.0 + mu_g + 0.672) / lv_mvd_g
            lv_xng = cgg(2,1)*ogg3*lv_xrg*lv_lamg**bm_g / am_g(lv_idx_bg)
            lv_ngten = (lv_xng-sv_ng1d*lv_rho)*lv_odts*lv_orho
            elseif (lv_mvd_g .lt. D0r) then
            lv_mvd_g = D0r
            lv_lamg = (3.0 + mu_g + 0.672) / lv_mvd_g
            lv_xng = cgg(2,1)*ogg3*lv_xrg*lv_lamg**bm_g / am_g(lv_idx_bg)
            lv_ngten = (lv_xng-sv_ng1d*lv_rho)*lv_odts*lv_orho
            endif
            else
            lv_qgten = -sv_qg1d*lv_odts
            lv_ngten = -sv_ng1d*lv_odts
            lv_qbten = -sv_qb1d*lv_odts
            endif
            if (lv_temp.lt.T_0) then
            lv_tten = lv_tten  + ( lsub*lv_ocp_s*(lv_pri_inu_s + lv_pri_ide_s  + lv_prs_ide_s + lv_prs_sde  + lv_prg_gde + lv_pri_iha_s)  + lv_lfus2*lv_ocp_s*(lv_pri_wfz_s + lv_pri_rfz_s  + lv_prg_rfz_s + lv_prs_scw  + lv_prg_scw + lv_prg_gcw  + lv_prg_rcs_s + lv_prs_rcs_s  + lv_prr_rci_s + lv_prg_rcg_s)  )*lv_orho * (1-IFDRY)
            else
            lv_tten = lv_tten  + ( lfus*lv_ocp_s*(-lv_prr_sml - lv_prr_gml  - lv_prr_rcg_s - lv_prr_rcs_s)  + lsub*lv_ocp_s*(lv_prs_sde + lv_prg_gde)  )*lv_orho * (1-IFDRY)
            endif
            if (th_probe == 2) exit lvblk
            lv_temp = sv_t1d + dt*lv_tten
            lv_otemp = 1./lv_temp
            lv_tempc = lv_temp - 273.15
            lv_qv = MAX(1.E-10, sv_qv1d + dt*lv_qvten)
            lv_rho = 0.622*lv_pres/(R*lv_temp*(lv_qv+0.622))
            lv_rhof = SQRT(RHO_NOT/lv_rho)
            lv_rhof2 = SQRT(lv_rhof)
            lv_qvs = rslf(lv_pres, lv_temp)
            lv_ssatw = lv_qv/lv_qvs - 1.
            if (abs(lv_ssatw).lt. eps) lv_ssatw = 0.0
            lv_diffu = 2.11E-5*(lv_temp/273.15)**1.94 * (101325./lv_pres)
            if (lv_tempc .ge. 0.0) then
            lv_visco = (1.718+0.0049*lv_tempc)*1.0E-5
            else
            lv_visco = (1.718+0.0049*lv_tempc-1.2E-5*lv_tempc*lv_tempc)*1.0E-5
            endif
            lv_vsc2 = SQRT(lv_rho/lv_visco)
            lv_lvap = lvap0 + (2106.0 - 4218.0)*lv_tempc
            lv_tcond = (5.69 + 0.0168*lv_tempc)*1.0E-5 * 418.936
            lv_ocp = 1./(Cp*(1.+0.887*lv_qv))
            lv_lvt2=lv_lvap*lv_lvap*lv_ocp*oRv*lv_otemp*lv_otemp
            lv_nwfa = MAX(11.1E6, (sv_nwfa1d + lv_nwfaten*dt)*lv_rho)
            if ((sv_qc1d + lv_qcten*dt) .gt. R1) then
            lv_rc = (sv_qc1d + lv_qcten*dt)*lv_rho
            lv_nc = MAX(2., MIN((sv_nc1d+lv_ncten*dt)*lv_rho, Nt_c_max))
            if (.NOT. is_aerosol_aware) lv_nc = Nt_c
            lv_l_qc = .true.
            else
            lv_rc = R1
            lv_nc = 2.
            lv_l_qc = .false.
            endif
            if ((sv_qi1d + lv_qiten*dt) .gt. R1) then
            lv_ri = (sv_qi1d + lv_qiten*dt)*lv_rho
            lv_ni = MAX(R2, (sv_ni1d + lv_niten*dt)*lv_rho)
            lv_l_qi = .true.
            else
            lv_ri = R1
            lv_ni = R2
            lv_l_qi = .false.
            endif
            if ((sv_qr1d + lv_qrten*dt) .gt. R1) then
            lv_rr = (sv_qr1d + lv_qrten*dt)*lv_rho
            lv_nr = MAX(R2, (sv_nr1d + lv_nrten*dt)*lv_rho)
            lv_l_qr = .true.
            lv_lamr = (am_r*crg(3)*org2*lv_nr/lv_rr)**obmr
            lv_mvd_r = (3.0 + mu_r + 0.672) / lv_lamr
            if (lv_mvd_r .gt. 2.5E-3) then
            lv_mvd_r = 2.5E-3
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_nr = crg(2)*org3*lv_rr*lv_lamr**bm_r / am_r
            elseif (lv_mvd_r .lt. D0r*0.75) then
            lv_mvd_r = D0r*0.75
            lv_lamr = (3.0 + mu_r + 0.672) / lv_mvd_r
            lv_nr = crg(2)*org3*lv_rr*lv_lamr**bm_r / am_r
            endif
            else
            lv_rr = R1
            lv_nr = R2
            lv_l_qr = .false.
            endif
            if ((sv_qs1d + lv_qsten*dt) .gt. R1) then
            lv_rs = (sv_qs1d + lv_qsten*dt)*lv_rho
            lv_l_qs = .true.
            else
            lv_rs = R1
            lv_l_qs = .false.
            endif
            if (is_hail_aware) then
            if ((sv_qg1d + lv_qgten*dt) .gt. R1) then
            lv_l_qg = .true.
            lv_rg = (sv_qg1d + lv_qgten*dt)*lv_rho
            lv_ng = MAX(R2, (sv_ng1d + lv_ngten*dt)*lv_rho)
            lv_rb = MAX(lv_rg/lv_rho/rho_g(NRHG), sv_qb1d + lv_qbten*dt)
            lv_rb = MIN(lv_rg/lv_rho/rho_g(1), lv_rb)
            lv_idx_bg = MAX(1,MIN(NINT(lv_rg/lv_rho/lv_rb *0.01)+1,NRHG))
            else
            lv_rg = R1
            lv_ng = R2
            lv_rb = R1/lv_rho/rho_g(NRHG)
            lv_idx_bg = idx_bg1
            lv_l_qg = .false.
            endif
            else
            lv_idx_bg = idx_bg1
            if ((sv_qg1d + lv_qgten*dt) .gt. R1) then
            lv_rg = (sv_qg1d + lv_qgten*dt)*lv_rho
            lv_ygra1 = alog10(max(1.E-9, lv_rg))
            lv_zans1 = 3.0 + 2./7.*(lv_ygra1+8.)
            lv_zans1 = MAX(2., MIN(lv_zans1, 6.))
            lv_n0_exp = 10.**(lv_zans1)
            lv_lam_exp = (lv_n0_exp*am_g(lv_idx_bg)*cgg(1,1)/lv_rg)**oge1
            lv_lamg = lv_lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
            lv_ng = cgg(2,1)*ogg3*lv_rg*lv_lamg**bm_g / am_g(lv_idx_bg)
            lv_rb = lv_rg/lv_rho/rho_g(lv_idx_bg)
            else
            lv_rg = R1
            lv_ng = R2
            lv_rb = R1/lv_rho/rho_g(NRHG)
            lv_l_qg = .false.
            endif
            endif
            if (.not. iiwarm) then
            lv_smo2 = 0.
            lv_smob = 0.
            lv_smoc = 0.
            lv_smod = 0.
            do thonce = 1, 1
            if (.not. lv_l_qs) CYCLE
            lv_tc0 = MIN(-0.1, lv_temp-273.15)
            lv_smob = lv_rs*oams
            if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            lv_smo2 = lv_smob
            else
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*bm_s  + sa(4)*lv_tc0*bm_s + sa(5)*lv_tc0*lv_tc0  + sa(6)*bm_s*bm_s + sa(7)*lv_tc0*lv_tc0*bm_s  + sa(8)*lv_tc0*bm_s*bm_s + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*bm_s*bm_s*bm_s
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1) + sb(2)*lv_tc0 + sb(3)*bm_s  + sb(4)*lv_tc0*bm_s + sb(5)*lv_tc0*lv_tc0  + sb(6)*bm_s*bm_s + sb(7)*lv_tc0*lv_tc0*bm_s  + sb(8)*lv_tc0*bm_s*bm_s + sb(9)*lv_tc0*lv_tc0*lv_tc0  + sb(10)*bm_s*bm_s*bm_s
            lv_smo2 = (lv_smob/lv_a_)**(1./lv_b_)
            endif
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(1)  + sa(4)*lv_tc0*cse(1) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(1)*cse(1) + sa(7)*lv_tc0*lv_tc0*cse(1)  + sa(8)*lv_tc0*cse(1)*cse(1) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(1)*cse(1)*cse(1)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(1) + sb(4)*lv_tc0*cse(1)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(1)*cse(1)  + sb(7)*lv_tc0*lv_tc0*cse(1) + sb(8)*lv_tc0*cse(1)*cse(1)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(1)*cse(1)*cse(1)
            lv_smoc = lv_a_ * lv_smo2**lv_b_
            lv_loga_ = sa(1) + sa(2)*lv_tc0 + sa(3)*cse(14)  + sa(4)*lv_tc0*cse(14) + sa(5)*lv_tc0*lv_tc0  + sa(6)*cse(14)*cse(14) + sa(7)*lv_tc0*lv_tc0*cse(14)  + sa(8)*lv_tc0*cse(14)*cse(14) + sa(9)*lv_tc0*lv_tc0*lv_tc0  + sa(10)*cse(14)*cse(14)*cse(14)
            lv_a_ = 10.0**lv_loga_
            lv_b_ = sb(1)+ sb(2)*lv_tc0 + sb(3)*cse(14) + sb(4)*lv_tc0*cse(14)  + sb(5)*lv_tc0*lv_tc0 + sb(6)*cse(14)*cse(14)  + sb(7)*lv_tc0*lv_tc0*cse(14) + sb(8)*lv_tc0*cse(14)*cse(14)  + sb(9)*lv_tc0*lv_tc0*lv_tc0 + sb(10)*cse(14)*cse(14)*cse(14)
            lv_smod = lv_a_ * lv_smo2**lv_b_
            enddo
            if (th_probe == 3) exit lvblk
            lv_lamg = (am_g(lv_idx_bg)*cgg(3,1)*ogg2*lv_ng/lv_rg)**obmg
            lv_ilamg = 1./lv_lamg
            lv_n0_g = lv_ng*ogg2*lv_lamg**cge(2,1)
            endif
            lv_lamr = (am_r*crg(3)*org2*lv_nr/lv_rr)**obmr
            lv_ilamr = 1./lv_lamr
            lv_mvd_r = (3.0 + mu_r + 0.672) / lv_lamr
            lv_n0_r = lv_nr*org2*lv_lamr**cre(2)
            lv_orho = 1./lv_rho
            if ( (lv_ssatw.gt. eps) .or. (lv_ssatw.lt. -eps .and.  lv_l_qc) ) then
            lv_clap = (lv_qv-lv_qvs)/(1. + lv_lvt2*lv_qvs)
            do lv_n = 1, 3
            lv_fcd = lv_qvs* EXP(lv_lvt2*lv_clap) - lv_qv + lv_clap
            lv_dfcd = lv_qvs*lv_lvt2* EXP(lv_lvt2*lv_clap) + 1.
            lv_clap = lv_clap - lv_fcd/lv_dfcd
            enddo
            lv_xrc = lv_rc + lv_clap*lv_rho
            lv_xnc = 0.
            if (lv_xrc.gt. R1) then
            lv_prw_vcd = lv_clap*lv_odt
            if (lv_clap .gt. eps) then
            if (is_aerosol_aware) then
            lv_xnc = MAX(2., activ_ncloud(lv_temp, sv_w1d, lv_nwfa))
            else
            lv_xnc = Nt_c
            endif
            lv_pnc_wcd = 0.5*(lv_xnc-lv_nc + abs(lv_xnc-lv_nc))*lv_odts*lv_orho
            elseif (lv_clap .lt. -eps .AND. lv_ssatw.lt.-1.E-6 .AND. is_aerosol_aware) then
            lv_tempc = lv_temp - 273.15
            lv_otemp = 1./lv_temp
            lv_rvs = lv_rho*lv_qvs
            lv_rvs_p = lv_rvs*lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)
            lv_rvs_pp = lv_rvs * ( lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)  *lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)  + (-2.*lv_lvap*lv_otemp*lv_otemp*lv_otemp*oRv)  + lv_otemp*lv_otemp)
            lv_gamsc = lv_lvap*lv_diffu/lv_tcond * lv_rvs_p
            lv_alphsc = 0.5*(lv_gamsc/(1.+lv_gamsc))*(lv_gamsc/(1.+lv_gamsc))  * lv_rvs_pp/lv_rvs_p * lv_rvs/lv_rvs_p
            lv_alphsc = MAX(1.E-9, lv_alphsc)
            lv_xsat = lv_ssatw
            if (abs(lv_xsat).lt. 1.E-9) lv_xsat=0.
            lv_t1_evap = 2.*PI*( 1.0 - lv_alphsc*lv_xsat   + 2.*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat   - 5.*lv_alphsc*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat*lv_xsat )  / (1.+lv_gamsc)
            lv_dc_star = DSQRT(-2.D0*dt * lv_t1_evap/(2.*PI)  * 4.*lv_diffu*lv_ssatw*lv_rvs/rho_w)
            lv_idx_d = MAX(1, MIN(INT(1.E6*lv_dc_star), nbc))
            lv_idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(lv_nc/t_Nc(1)) / nic1)
            lv_idx_n = MAX(1, MIN(lv_idx_n, nbc))
            if (lv_rc.gt. r_c(1)) then
            lv_nic = NINT(ALOG10(lv_rc))
            do lv_nn = lv_nic-1, lv_nic+1
            lv_n = lv_nn
            if ( (lv_rc/10.**lv_nn).ge.1.0 .and.  (lv_rc/10.**lv_nn).lt.10.0) goto 159
            enddo
            159         continue
            lv_idx_c = INT(lv_rc/10.**lv_n) + 10*(lv_n-nic2) - (lv_n-nic2)
            lv_idx_c = MAX(1, MIN(lv_idx_c, ntb_c))
            else
            lv_idx_c = 1
            endif
            lv_prw_vcd = MAX(DBLE(-lv_rc*0.99*lv_orho*lv_odt), lv_prw_vcd)
            lv_pnc_wcd = MAX(DBLE(-lv_nc*0.99*lv_orho*lv_odt),                 DBLE(-tnc_wev(lv_idx_d, lv_idx_c, lv_idx_n)*lv_orho*lv_odt))
            endif
            else
            lv_prw_vcd = -lv_rc*lv_orho*lv_odt
            lv_pnc_wcd = -lv_nc*lv_orho*lv_odt
            endif
            lv_qvten = lv_qvten - lv_prw_vcd
            lv_qcten = lv_qcten + lv_prw_vcd
            lv_ncten = lv_ncten + lv_pnc_wcd
            lv_nwfaten = lv_nwfaten - lv_pnc_wcd
            lv_tten = lv_tten + lv_lvap*lv_ocp*lv_prw_vcd*(1-IFDRY)
            lv_rc = MAX(R1, (sv_qc1d + dt*lv_qcten)*lv_rho)
            if (lv_rc.eq.R1) lv_l_qc = .false.
            lv_nc = MAX(2., MIN((sv_nc1d+lv_ncten*dt)*lv_rho, Nt_c_max))
            if (.NOT. is_aerosol_aware) lv_nc = Nt_c
            lv_qv = MAX(1.E-10, sv_qv1d + dt*lv_qvten)
            lv_temp = sv_t1d + dt*lv_tten
            lv_rho = 0.622*lv_pres/(R*lv_temp*(lv_qv+0.622))
            lv_qvs = rslf(lv_pres, lv_temp)
            lv_ssatw = lv_qv/lv_qvs - 1.
            endif
            if ( (lv_ssatw.lt. -eps) .and. lv_l_qr  .and. (.not.(lv_prw_vcd.gt. 0.)) ) then
            lv_tempc = lv_temp - 273.15
            lv_otemp = 1./lv_temp
            lv_orho = 1./lv_rho
            lv_rhof = SQRT(RHO_NOT*lv_orho)
            lv_rhof2 = SQRT(lv_rhof)
            lv_diffu = 2.11E-5*(lv_temp/273.15)**1.94 * (101325./lv_pres)
            if (lv_tempc .ge. 0.0) then
            lv_visco = (1.718+0.0049*lv_tempc)*1.0E-5
            else
            lv_visco = (1.718+0.0049*lv_tempc-1.2E-5*lv_tempc*lv_tempc)*1.0E-5
            endif
            lv_vsc2 = SQRT(lv_rho/lv_visco)
            lv_lvap = lvap0 + (2106.0 - 4218.0)*lv_tempc
            lv_tcond = (5.69 + 0.0168*lv_tempc)*1.0E-5 * 418.936
            lv_ocp = 1./(Cp*(1.+0.887*lv_qv))
            lv_rvs = lv_rho*lv_qvs
            lv_rvs_p = lv_rvs*lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)
            lv_rvs_pp = lv_rvs * ( lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)  *lv_otemp*(lv_lvap*lv_otemp*oRv - 1.)  + (-2.*lv_lvap*lv_otemp*lv_otemp*lv_otemp*oRv)  + lv_otemp*lv_otemp)
            lv_gamsc = lv_lvap*lv_diffu/lv_tcond * lv_rvs_p
            lv_alphsc = 0.5*(lv_gamsc/(1.+lv_gamsc))*(lv_gamsc/(1.+lv_gamsc))  * lv_rvs_pp/lv_rvs_p * lv_rvs/lv_rvs_p
            lv_alphsc = MAX(1.E-9, lv_alphsc)
            lv_xsat   = MIN(-1.E-9, lv_ssatw)
            lv_t1_evap = 2.*PI*( 1.0 - lv_alphsc*lv_xsat   + 2.*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat   - 5.*lv_alphsc*lv_alphsc*lv_alphsc*lv_xsat*lv_xsat*lv_xsat )  / (1.+lv_gamsc)
            lv_lamr = 1./lv_ilamr
            if (lv_qv/lv_qvs .lt. 0.95 .AND. lv_rr*lv_orho.le.1.E-8) then
            lv_prv_rev = lv_rr*lv_orho*lv_odts
            else
            lv_prv_rev = lv_t1_evap*lv_diffu*(-lv_ssatw)*lv_n0_r*lv_rvs  * (t1_qr_ev*lv_ilamr**cre(10)  + t2_qr_ev*lv_vsc2*lv_rhof2*((lv_lamr+0.5*fv_r)**(-cre(11))))
            lv_rate_max = MIN((lv_rr*lv_orho*lv_odts), (lv_qvs-lv_qv)*lv_odts)
            lv_prv_rev = MIN(DBLE(lv_rate_max), lv_prv_rev*lv_orho)
            IF (lv_prr_gml.gt.0.0) THEN
            lv_eva_factor = MIN(1.0, 0.01+(0.99-0.01)*(lv_tempc/20.0))
            lv_prv_rev = lv_prv_rev*lv_eva_factor
            ENDIF
            endif
            lv_pnr_rev = MIN(DBLE(lv_nr*0.99*lv_orho*lv_odts),                   lv_prv_rev * lv_nr/lv_rr)
            lv_qrten = lv_qrten - lv_prv_rev
            lv_qvten = lv_qvten + lv_prv_rev
            lv_nrten = lv_nrten - lv_pnr_rev
            lv_nwfaten = lv_nwfaten + lv_pnr_rev
            lv_tten = lv_tten - lv_lvap*lv_ocp*lv_prv_rev*(1-IFDRY)
            lv_rr = MAX(R1, (sv_qr1d + dt*lv_qrten)*lv_rho)
            lv_qv = MAX(1.E-10, sv_qv1d + dt*lv_qvten)
            lv_nr = MAX(R2, (sv_nr1d + dt*lv_nrten)*lv_rho)
            lv_temp = sv_t1d + dt*lv_tten
            lv_rho = 0.622*lv_pres/(R*lv_temp*(lv_qv+0.622))
            endif
            if (th_probe == 4) exit lvblk
            enddo lvblk
            ! columns without microphysics (thb_nmc) skip the tail, which is the only reader of these
            IF ( .NOT. thb_nmc(n_-thb0+1,1) ) THEN
            thb_tten(n_-thb0+1,k-kts+1,1) = lv_tten
            thb_qvten(n_-thb0+1,k-kts+1,1) = lv_qvten
            thb_qcten(n_-thb0+1,k-kts+1,1) = lv_qcten
            thb_qiten(n_-thb0+1,k-kts+1,1) = lv_qiten
            thb_qrten(n_-thb0+1,k-kts+1,1) = lv_qrten
            thb_qsten(n_-thb0+1,k-kts+1,1) = lv_qsten
            thb_qgten(n_-thb0+1,k-kts+1,1) = lv_qgten
            thb_qbten(n_-thb0+1,k-kts+1,1) = lv_qbten
            thb_niten(n_-thb0+1,k-kts+1,1) = lv_niten
            thb_nrten(n_-thb0+1,k-kts+1,1) = lv_nrten
            thb_ncten(n_-thb0+1,k-kts+1,1) = lv_ncten
            thb_ngten(n_-thb0+1,k-kts+1,1) = lv_ngten
            thb_nwfaten(n_-thb0+1,k-kts+1,1) = lv_nwfaten
            thb_nifaten(n_-thb0+1,k-kts+1,1) = lv_nifaten
            thb_nbcaten(n_-thb0+1,k-kts+1,1) = lv_nbcaten
            thb_prr_sml(n_-thb0+1,k-kts+1,1) = lv_prr_sml
            thb_temp(n_-thb0+1,k-kts+1,1) = lv_temp
            thb_rc(n_-thb0+1,k-kts+1,1) = lv_rc
            thb_ri(n_-thb0+1,k-kts+1,1) = lv_ri
            thb_rr(n_-thb0+1,k-kts+1,1) = lv_rr
            thb_rs(n_-thb0+1,k-kts+1,1) = lv_rs
            thb_rg(n_-thb0+1,k-kts+1,1) = lv_rg
            thb_rb(n_-thb0+1,k-kts+1,1) = lv_rb
            thb_ni(n_-thb0+1,k-kts+1,1) = lv_ni
            thb_nr(n_-thb0+1,k-kts+1,1) = lv_nr
            thb_nc(n_-thb0+1,k-kts+1,1) = lv_nc
            thb_ng(n_-thb0+1,k-kts+1,1) = lv_ng
            thb_rho(n_-thb0+1,k-kts+1,1) = lv_rho
            thb_rhof(n_-thb0+1,k-kts+1,1) = lv_rhof
            thb_visco(n_-thb0+1,k-kts+1,1) = lv_visco
            thb_lvap(n_-thb0+1,k-kts+1,1) = lv_lvap
            thb_ocp(n_-thb0+1,k-kts+1,1) = lv_ocp
            thb_ilamg(n_-thb0+1,k-kts+1,1) = lv_ilamg
            thb_mvd_r(n_-thb0+1,k-kts+1,1) = lv_mvd_r
            thb_mvd_g(n_-thb0+1,k-kts+1,1) = lv_mvd_g
            thb_smob(n_-thb0+1,k-kts+1,1) = lv_smob
            thb_smoc(n_-thb0+1,k-kts+1,1) = lv_smoc
            thb_vts_boost(n_-thb0+1,k-kts+1,1) = lv_vts_boost
            thb_idx_bg(n_-thb0+1,k-kts+1,1) = lv_idx_bg
            thb_l_qc(n_-thb0+1,k-kts+1,1) = lv_l_qc
            thb_l_qi(n_-thb0+1,k-kts+1,1) = lv_l_qi
            thb_l_qr(n_-thb0+1,k-kts+1,1) = lv_l_qr
            thb_l_qs(n_-thb0+1,k-kts+1,1) = lv_l_qs
            thb_l_qg(n_-thb0+1,k-kts+1,1) = lv_l_qg
            ENDIF
            thb_qv1d(n_-thb0+1,k-kts+1,1) = sv_qv1d
            thb_qc1d(n_-thb0+1,k-kts+1,1) = sv_qc1d
            thb_qi1d(n_-thb0+1,k-kts+1,1) = sv_qi1d
            thb_qr1d(n_-thb0+1,k-kts+1,1) = sv_qr1d
            thb_qs1d(n_-thb0+1,k-kts+1,1) = sv_qs1d
            thb_qg1d(n_-thb0+1,k-kts+1,1) = sv_qg1d
            thb_qb1d(n_-thb0+1,k-kts+1,1) = sv_qb1d
            thb_ni1d(n_-thb0+1,k-kts+1,1) = sv_ni1d
            thb_nr1d(n_-thb0+1,k-kts+1,1) = sv_nr1d
            thb_nc1d(n_-thb0+1,k-kts+1,1) = sv_nc1d
            thb_ng1d(n_-thb0+1,k-kts+1,1) = sv_ng1d
            thb_nwfa1d(n_-thb0+1,k-kts+1,1) = sv_nwfa1d
            thb_nifa1d(n_-thb0+1,k-kts+1,1) = sv_nifa1d
            thb_nbca1d(n_-thb0+1,k-kts+1,1) = sv_nbca1d
            thb_t1d(n_-thb0+1,k-kts+1,1) = sv_t1d
            thb_w1d(n_-thb0+1,k-kts+1,1) = sv_w1d
      enddo
      enddo
      IF ( thsplit_on == 1 ) THEN
!$acc parallel loop gang vector collapse(2) present(mp_li, mp_lj) private(i, j, w1d, dz1d)
      do sp_ = 1, 5
      do n_ = thb0, thb1
         i = mp_li(n_) ; j = mp_lj(n_)
         thb_ppt(n_-thb0+1,sp_) = 0.
         IF ( .NOT. thb_nmc(n_-thb0+1,1) ) THEN
            do k = kts, kte
               dz1d(k) = dz(i,k,j)
               w1d(k) = thb_w1d(n_-thb0+1,k-kts+1,1)
            enddo
            CALL thom_vt(sp_, w1d, dz1d, kts, kte, dt, n_-thb0+1, 1)
         ENDIF
      enddo
      enddo
!$acc parallel loop gang vector collapse(2) present(mp_li, mp_lj) private(i, j, dz1d)
      do sp_ = 1, 5
      do n_ = thb0, thb1
         i = mp_li(n_) ; j = mp_lj(n_)
         IF ( .NOT. thb_nmc(n_-thb0+1,1) ) THEN
            do k = kts, kte
               dz1d(k) = dz(i,k,j)
            enddo
            CALL thom_sed(sp_, dz1d, kts, kte, dt, n_-thb0+1, 1)
         ENDIF
      enddo
      enddo
      ENDIF
      CALL thom_tail_band( gpu_aer, gpu_wif, gpu_do_refl, gpu_do_re, kediagloc, thb0, thb1, dt,      &
                           qv, qc, qr, qi, qs, qg, ni, nr, th, pii, p, dz,                       &
                           RAINNC, RAINNCV, SNOWNC, SNOWNCV, GRAUPELNC, GRAUPELNCV, SR,            &
                           refl_10cm, re_cloud, re_ice, re_snow, mp_li, mp_lj, SIZE(mp_li),       &
                           ims, ime, jms, jme, kms, kme, kts, kte )
      ENDDO   ! THLEV list bands
      ELSE
!$acc parallel loop gang vector present(mp_li, mp_lj) &
!$acc private(qv1d,qc1d,qi1d,qr1d,qs1d,qg1d,qb1d,ni1d,nr1d,nc1d,ng1d,nwfa1d,nifa1d,nbca1d) &
!$acc private(t1d,p1d,w1d,dz1d,rho,re_qc1d,re_qi1d,re_qs1d,dBZ)
      do n_ = 1, ncol_
         i = mp_li(n_) ; j = mp_lj(n_)
         pptrain = 0.
         pptsnow = 0.
         pptgraul = 0.
         pptice = 0.
         do k = kts, kte
            t1d(k) = th(i,k,j)*pii(i,k,j)
            p1d(k) = p(i,k,j)
            w1d(k) = w(i,k,j)
            dz1d(k) = dz(i,k,j)
            qv1d(k) = qv(i,k,j)
            qc1d(k) = qc(i,k,j)
            qi1d(k) = qi(i,k,j)
            qr1d(k) = qr(i,k,j)
            qs1d(k) = qs(i,k,j)
            qg1d(k) = qg(i,k,j)
            ni1d(k) = ni(i,k,j)
            nr1d(k) = nr(i,k,j)
            rho(k) = 0.622*p1d(k)/(R*t1d(k)*(qv1d(k)+0.622))
            nc1d(k) = Nt_c/rho(k)
            nwfa1d(k) = 11.1E6/rho(k)
            nifa1d(k) = naIN1*0.01/rho(k)
            nbca1d(k) = 5.55E6/rho(k)
         enddo
         do k = kte, kts, -1
            if (qg1d(k).gt.R1) then
               ygra1 = alog10(max(1.E-9, qg1d(k)*rho(k)))
               zans1 = 3.0 + 2./7.*(ygra1+8.)
               zans1 = MAX(2., MIN(zans1, 6.))
               N0_exp = 10.**(zans1)
               lam_exp = (N0_exp*am_g(idx_bg1)*cgg(1,1)/(rho(k)*qg1d(k)))**oge1
               lamg = lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
               ng1d(k) = cgg(2,1)*ogg3*rho(k)*qg1d(k)*lamg**bm_g / am_g(idx_bg1)
               ng1d(k) = MAX(R2, ng1d(k)/rho(k))
               qb1d(k) = qg1d(k)/rho_g(idx_bg1)
            else
               ng1d(k) = 0
               qb1d(k) = 0
            endif
         enddo
         call mp_thompson(gpu_aer, gpu_wif, &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d, ni1d,     &
                          nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, w1d, dz1d,  &
                      pptrain, pptsnow, pptgraul, pptice, &
                      kts, kte, dt, i, j)
         RAINNCV(i,j) = pptrain + pptsnow + pptgraul + pptice
         RAINNC(i,j) = RAINNC(i,j) + pptrain + pptsnow + pptgraul + pptice
         SNOWNCV(i,j) = pptsnow + pptice
         SNOWNC(i,j) = SNOWNC(i,j) + pptsnow + pptice
         GRAUPELNCV(i,j) = pptgraul
         GRAUPELNC(i,j) = GRAUPELNC(i,j) + pptgraul
         SR(i,j) = (pptsnow + pptgraul + pptice)/(RAINNCV(i,j)+1.e-12)
         do k = kts, kte
            qv(i,k,j) = qv1d(k)
            qc(i,k,j) = qc1d(k)
            qi(i,k,j) = qi1d(k)
            qr(i,k,j) = qr1d(k)
            qs(i,k,j) = qs1d(k)
            qg(i,k,j) = qg1d(k)
            ni(i,k,j) = ni1d(k)
            nr(i,k,j) = nr1d(k)
            th(i,k,j) = t1d(k)/pii(i,k,j)
            if (qv1d(k) .lt. 0.0) then
             if (k.lt.kte-2 .and. k.gt.kts+1) then
                qv(i,k,j) = MAX(1.E-7, 0.5*(qv(i,k-1,j) + qv(i,k+1,j)))
             else
                qv(i,k,j) = 1.E-7
             endif
            endif
         enddo
         IF ( gpu_do_refl ) THEN
          call calc_refl10cm (qv1d, qc1d, qr1d, nr1d, qs1d, qg1d,       &
                      ng1d, qb1d, t1d, p1d, dBZ, kts, kte, i, j, kediagloc)
          do k = kts, kte
             refl_10cm(i,k,j) = MAX(-35., dBZ(k))
          enddo
         ENDIF
         IF ( gpu_do_re .AND. th_probe /= 5 ) THEN
          do k = kts, kte
             re_qc1d(k) = RE_QC_BG
             re_qi1d(k) = RE_QI_BG
             re_qs1d(k) = RE_QS_BG
          enddo
          call calc_effectRad (t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d,  &
                      re_qc1d, re_qi1d, re_qs1d, kts, kte)
          do k = kts, kte
             re_cloud(i,k,j) = MAX(RE_QC_BG, MIN(re_qc1d(k), 50.E-6))
             re_ice(i,k,j)   = MAX(RE_QI_BG, MIN(re_qi1d(k), 125.E-6))
             re_snow(i,k,j)  = MAX(RE_QS_BG, MIN(re_qs1d(k), 999.E-6))
          enddo
         ENDIF
      enddo
      ENDIF
      RETURN
      ENDIF
#endif
      j_loop:  do j = j_start, j_end
      i_loop:  do i = i_start, i_end

         pptrain = 0.
         pptsnow = 0.
         pptgraul = 0.
         pptice = 0.
         RAINNCV(i,j) = 0.
         IF ( PRESENT (snowncv) ) THEN
            SNOWNCV(i,j) = 0.
         ENDIF
         IF ( PRESENT (graupelncv) ) THEN
            GRAUPELNCV(i,j) = 0.
         ENDIF
         SR(i,j) = 0.

         do k = kts, kte
            t1d(k) = th(i,k,j)*pii(i,k,j)
            p1d(k) = p(i,k,j)
            w1d(k) = w(i,k,j)
            dz1d(k) = dz(i,k,j)
            qv1d(k) = qv(i,k,j)
            qc1d(k) = qc(i,k,j)
            qi1d(k) = qi(i,k,j)
            qr1d(k) = qr(i,k,j)
            qs1d(k) = qs(i,k,j)
            qg1d(k) = qg(i,k,j)
            ni1d(k) = ni(i,k,j)
            nr1d(k) = nr(i,k,j)
            rho(k) = 0.622*p1d(k)/(R*t1d(k)*(qv1d(k)+0.622))
         enddo
         if (is_aerosol_aware) then
            do k = kts, kte
               nc1d(k) = nc(i,k,j)
               nwfa1d(k) = nwfa(i,k,j)
               nifa1d(k) = nifa(i,k,j)
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = nbca(i,k,j)
               else
                  nbca1d(k) = 0.0
               endif
            enddo
            nwfa1 = nwfa2d(i,j)
         else
            do k = kts, kte
               nc1d(k) = Nt_c/rho(k)
               nwfa1d(k) = 11.1E6/rho(k)
               nifa1d(k) = naIN1*0.01/rho(k)
               nbca1d(k) = 5.55E6/rho(k)
            enddo
         endif

!..If not the variable-density graupel-hail hybrid, then set the vol mixing
!.. ratio to mass mixing ratio divided by constant density (500kg/m3) value.

         if (is_hail_aware) then
            do k = kts, kte
               ng1d(k) = ng(i,k,j)
               qb1d(k) = qb(i,k,j)
            enddo
         else

            do k = kte, kts, -1
               if (qg1d(k).gt.R1) then
                  ygra1 = alog10(max(1.E-9, qg1d(k)*rho(k)))
                  zans1 = 3.0 + 2./7.*(ygra1+8.)
                  zans1 = MAX(2., MIN(zans1, 6.))
                  N0_exp = 10.**(zans1)
                  lam_exp = (N0_exp*am_g(idx_bg1)*cgg(1,1)/(rho(k)*qg1d(k)))**oge1
                  lamg = lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
                  ng1d(k) = cgg(2,1)*ogg3*rho(k)*qg1d(k)*lamg**bm_g / am_g(idx_bg1)
                  ng1d(k) = MAX(R2, ng1d(k)/rho(k))
                  qb1d(k) = qg1d(k)/rho_g(idx_bg1)
               else
                  ng1d(k) = 0
                  qb1d(k) = 0
               endif
            enddo
         endif

         call mp_thompson(aer_init_opt, wif_input_opt, &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d, ni1d,     &
                          nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, w1d, dz1d,  &
                      pptrain, pptsnow, pptgraul, pptice, &
#if ( WRF_CHEM == 1 )
                      wetscav_on, rainprod1d, evapprod1d, &
#endif
                      kts, kte, dt, i, j)

         pcp_ra(i,j) = pptrain
         pcp_sn(i,j) = pptsnow
         pcp_gr(i,j) = pptgraul
         pcp_ic(i,j) = pptice
         RAINNCV(i,j) = pptrain + pptsnow + pptgraul + pptice
         RAINNC(i,j) = RAINNC(i,j) + pptrain + pptsnow + pptgraul + pptice
         IF ( PRESENT(snowncv) .AND. PRESENT(snownc) ) THEN
            SNOWNCV(i,j) = pptsnow + pptice
            SNOWNC(i,j) = SNOWNC(i,j) + pptsnow + pptice
         ENDIF
         IF ( PRESENT(graupelncv) .AND. PRESENT(graupelnc) ) THEN
            GRAUPELNCV(i,j) = pptgraul
            GRAUPELNC(i,j) = GRAUPELNC(i,j) + pptgraul
         ENDIF
         SR(i,j) = (pptsnow + pptgraul + pptice)/(RAINNCV(i,j)+1.e-12)


!..
!..BEGIN AEROSOL EMISSIONS
!..
!..Reset lowest model level to initial state aerosols (fake sfc source).
!.. Changed 13 May 2013 to fake emissions in which nwfa2d is aerosol
!.. number tendency (number per kg per second).
         if (is_aerosol_aware) then
!..Add anthropogenic emissions
!-GT        nwfa1d(kts) = nwfa1
            nwfa1d(kts) = nwfa1d(kts) + nwfa2d(i,j)*dt_in
            nifa1d(kts) = nifa1d(kts) + nifa2d(i,j)*dt_in
            if (wif_input_opt .eq. 2) then
               nbca1d(kts) = nbca1d(kts) + nbca2d(i,j)*dt_in
            else
               nbca1d(kts) = 0.0
            endif
!..
!..END AEROSOL EMISSIONS
!..

            do k = kts, kte
               nc(i,k,j) = nc1d(k)
               nwfa(i,k,j) = nwfa1d(k)
               nifa(i,k,j) = nifa1d(k)
               if (wif_input_opt .eq. 2) then
                  nbca(i,k,j) = nbca1d(k)
               else
                  nbca(i,k,j) = 0.0
               endif
            enddo
         endif
         if (is_hail_aware) then
            do k = kts, kte
               ng(i,k,j) = ng1d(k)
               qb(i,k,j) = qb1d(k)
            enddo
         endif

         do k = kts, kte
            qv(i,k,j) = qv1d(k)
            qc(i,k,j) = qc1d(k)
            qi(i,k,j) = qi1d(k)
            qr(i,k,j) = qr1d(k)
            qs(i,k,j) = qs1d(k)
            qg(i,k,j) = qg1d(k)
            ni(i,k,j) = ni1d(k)
            nr(i,k,j) = nr1d(k)
            th(i,k,j) = t1d(k)/pii(i,k,j)
#if ( WRF_CHEM == 1 )
          IF ( wetscav_on ) THEN
            rainprod(i,k,j) = rainprod1d(k)
            evapprod(i,k,j) = evapprod1d(k)
          ENDIF
#endif
            if (qc1d(k) .gt. qc_max) then
             imax_qc = i
             jmax_qc = j
             kmax_qc = k
             qc_max = qc1d(k)
            elseif (qc1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qc ', qc1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (qr1d(k) .gt. qr_max) then
             imax_qr = i
             jmax_qr = j
             kmax_qr = k
             qr_max = qr1d(k)
            elseif (qr1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qr ', qr1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (nr1d(k) .gt. nr_max) then
             imax_nr = i
             jmax_nr = j
             kmax_nr = k
             nr_max = nr1d(k)
            elseif (nr1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative nr ', nr1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (qs1d(k) .gt. qs_max) then
             imax_qs = i
             jmax_qs = j
             kmax_qs = k
             qs_max = qs1d(k)
            elseif (qs1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qs ', qs1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (qi1d(k) .gt. qi_max) then
             imax_qi = i
             jmax_qi = j
             kmax_qi = k
             qi_max = qi1d(k)
            elseif (qi1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qi ', qi1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (qg1d(k) .gt. qg_max) then
             imax_qg = i
             jmax_qg = j
             kmax_qg = k
             qg_max = qg1d(k)
            elseif (qg1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qg ', qg1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (ni1d(k) .gt. ni_max) then
             imax_ni = i
             jmax_ni = j
             kmax_ni = k
             ni_max = ni1d(k)
            elseif (ni1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative ni ', ni1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
            endif
            if (qv1d(k) .lt. 0.0) then
             write(mp_debug,*) 'WARNING, negative qv ', qv1d(k),        &
                        ' at i,j,k=', i,j,k
             CALL wrf_debug(150, mp_debug)
             if (k.lt.kte-2 .and. k.gt.kts+1) then
                write(mp_debug,*) '   below and above are: ', qv(i,k-1,j), qv(i,k+1,j)
                CALL wrf_debug(150, mp_debug)
                qv(i,k,j) = MAX(1.E-7, 0.5*(qv(i,k-1,j) + qv(i,k+1,j)))
             else
                qv(i,k,j) = 1.E-7
             endif
            endif
         enddo

         IF ( PRESENT (diagflag) ) THEN
         if (diagflag .and. do_radar_ref == 1) then
          
          IF ( present(ke_diag) ) THEN
            kediagloc = ke_diag
          ELSE
            kediagloc = kte
          ENDIF
          
          call calc_refl10cm (qv1d, qc1d, qr1d, nr1d, qs1d, qg1d,       &
                      ng1d, qb1d, t1d, p1d, dBZ, kts, kte, i, j, kediagloc)
          do k = kts, kte
             refl_10cm(i,k,j) = MAX(-35., dBZ(k))
          enddo
         endif
         ENDIF

         IF (has_reqc.ne.0 .and. has_reqi.ne.0 .and. has_reqs.ne.0) THEN
          do k = kts, kte
             re_qc1d(k) = RE_QC_BG
             re_qi1d(k) = RE_QI_BG
             re_qs1d(k) = RE_QS_BG
          enddo
          call calc_effectRad (t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d,  &
                      re_qc1d, re_qi1d, re_qs1d, kts, kte)
          do k = kts, kte
             re_cloud(i,k,j) = MAX(RE_QC_BG, MIN(re_qc1d(k), 50.E-6))
             re_ice(i,k,j)   = MAX(RE_QI_BG, MIN(re_qi1d(k), 125.E-6))
             re_snow(i,k,j)  = MAX(RE_QS_BG, MIN(re_qs1d(k), 999.E-6))
          enddo
         ENDIF

      enddo i_loop
      enddo j_loop

! DEBUG - GT
      write(mp_debug,'(a,7(a,e13.6,1x,a,i3,a,i3,a,i3,a,1x))') 'MP-GT:', &
         'qc: ', qc_max, '(', imax_qc, ',', jmax_qc, ',', kmax_qc, ')', &
         'qr: ', qr_max, '(', imax_qr, ',', jmax_qr, ',', kmax_qr, ')', &
         'qi: ', qi_max, '(', imax_qi, ',', jmax_qi, ',', kmax_qi, ')', &
         'qs: ', qs_max, '(', imax_qs, ',', jmax_qs, ',', kmax_qs, ')', &
         'qg: ', qg_max, '(', imax_qg, ',', jmax_qg, ',', kmax_qg, ')', &
         'ni: ', ni_max, '(', imax_ni, ',', jmax_ni, ',', kmax_ni, ')', &
         'nr: ', nr_max, '(', imax_nr, ',', jmax_nr, ',', kmax_nr, ')'
      CALL wrf_debug(150, mp_debug)
! END DEBUG - GT

      do i = 1, 256
         mp_debug(i:i) = char(0)
      enddo

      END SUBROUTINE mp_gt_driver

!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!+---+-----------------------------------------------------------------+
!.. This subroutine computes the moisture tendencies of water vapor,
!.. cloud droplets, rain, cloud ice (pristine), snow, and graupel.
!.. Previously this code was based on Reisner et al (1998), but few of
!.. those pieces remain.  A complete description is now found in
!.. Thompson et al. (2004, 2008).
!+---+-----------------------------------------------------------------+
!
      subroutine mp_thompson (aer_init_opt, wif_input_opt, &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d,       &
                          ni1d, nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, &
                          t1d, p1d, w1d, dzq,                             &
                          pptrain, pptsnow, pptgraul, pptice, &
#if ( WRF_CHEM == 1 )
                          wetscav_on, rainprod, evapprod, &
#endif
                          kts, kte, dt, ii, jj)
#ifdef WRF_GPU
!$acc routine seq
#endif

      implicit none

!..Sub arguments
      INTEGER, OPTIONAL, INTENT(IN):: aer_init_opt, wif_input_opt
      INTEGER, INTENT(IN):: kts, kte, ii, jj
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: &
                          qv1d, qc1d, qi1d, qr1d, qs1d, qg1d, qb1d,     &
                          ni1d, nr1d, nc1d, ng1d, nwfa1d, nifa1d, nbca1d, t1d
      REAL, DIMENSION(kts:kte), INTENT(IN):: p1d, w1d, dzq
      REAL, INTENT(INOUT):: pptrain, pptsnow, pptgraul, pptice
      REAL, INTENT(IN):: dt
#if ( WRF_CHEM == 1 )
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: &
                          rainprod, evapprod
      LOGICAL, INTENT(IN) :: wetscav_on
#endif

!..Local variables
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: tten, qvten, qcten, qiten, qrten,            &
           qsten, qgten, qbten, niten, nrten, ncten, ngten, nwfaten, nifaten, &
                                                              nbcaten
#else
      REAL, DIMENSION(kts:kte):: tten, qvten, qcten, qiten, qrten,            &
           qsten, qgten, qbten, niten, nrten, ncten, ngten, nwfaten, nifaten, &
                                                              nbcaten
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prw_vcd
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: prw_vcd
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pnc_wcd, pnc_wau, pnc_rcw, &
           pnc_scw, pnc_gcw
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: pnc_wcd, pnc_wau, pnc_rcw, &
           pnc_scw, pnc_gcw
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pna_rca, pna_sca, pna_gca, &
           pnd_rcd, pnd_scd, pnd_gcd, pnb_rcb, pnb_scb, pnb_gcb
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: pna_rca, pna_sca, pna_gca, &
           pnd_rcd, pnd_scd, pnd_gcd, pnb_rcb, pnb_scb, pnb_gcb
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prr_wau, prr_rcw, prr_rcs, &
           prr_rcg, prr_sml, prr_gml, &
           prr_rci, prv_rev,          &
           pnr_wau, pnr_rcs, pnr_rcg, &
           pnr_rci, pnr_sml, pnr_gml, &
           pnr_rev, pnr_rcr, pnr_rfz
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: prr_wau, prr_rcw, prr_rcs, &
           prr_rcg, prr_sml, prr_gml, &
           prr_rci, prv_rev,          &
           pnr_wau, pnr_rcs, pnr_rcg, &
           pnr_rci, pnr_sml, pnr_gml, &
           pnr_rev, pnr_rcr, pnr_rfz
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: pri_inu, pni_inu, pri_ihm, &
           pni_ihm, pri_wfz, pni_wfz, &
           pri_rfz, pni_rfz, pri_ide, &
           pni_ide, pri_rci, pni_rci, &
           pni_sci, pni_iau, pri_iha, pni_iha
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: pri_inu, pni_inu, pri_ihm, &
           pni_ihm, pri_wfz, pni_wfz, &
           pri_rfz, pni_rfz, pri_ide, &
           pni_ide, pri_rci, pni_rci, &
           pni_sci, pni_iau, pri_iha, pni_iha
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prs_iau, prs_sci, prs_rcs, &
           prs_scw, prs_sde, prs_ihm, &
           prs_ide
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: prs_iau, prs_sci, prs_rcs, &
           prs_scw, prs_sde, prs_ihm, &
           prs_ide
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: prg_scw, prg_rfz, prg_gde, &
           prg_gcw, prg_rci, prg_rcs, prg_rcg, prg_ihm,                 &
           png_rcs, png_rcg, png_scw, png_gde,                          &
           pbg_scw, pbg_rfz, pbg_gcw, pbg_rci, pbg_rcs, pbg_rcg,        &
           pbg_sml, pbg_gml
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: prg_scw, prg_rfz, prg_gde, &
           prg_gcw, prg_rci, prg_rcs, prg_rcg, prg_ihm,                 &
           png_rcs, png_rcg, png_scw, png_gde,                          &
           pbg_scw, pbg_rfz, pbg_gcw, pbg_rci, pbg_rcs, pbg_rcg,        &
           pbg_sml, pbg_gml
#endif

      DOUBLE PRECISION, PARAMETER:: zeroD0 = 0.0d0
#ifdef WRF_GPU
      DOUBLE PRECISION:: pnc_wau_s, pnc_rcw_s, pnc_scw_s, pnc_gcw_s, prr_rcs_s, prr_rcg_s, prr_rci_s, pnr_wau_s, pnr_rcs_s, pnr_rcg_s, pnr_rci_s, pnr_sml_s
      DOUBLE PRECISION:: pnr_gml_s, pnr_rcr_s, pnr_rfz_s, pri_inu_s, pni_inu_s, pri_ihm_s, pni_ihm_s, pri_wfz_s, pni_wfz_s, pri_rfz_s, pni_rfz_s, pri_ide_s
      DOUBLE PRECISION:: pni_ide_s, pni_rci_s, pni_sci_s, pni_iau_s, pri_iha_s, pni_iha_s, prs_rcs_s, prs_ihm_s, prs_ide_s, prg_rfz_s, prg_rci_s, prg_rcs_s
      DOUBLE PRECISION:: prg_rcg_s, prg_ihm_s, png_scw_s, png_rcs_s, png_rcg_s, png_gde_s, pbg_scw_s, pbg_rfz_s, pbg_gcw_s, pbg_rci_s, pbg_rcs_s, pbg_rcg_s
      DOUBLE PRECISION:: pbg_sml_s, pbg_gml_s, pna_rca_s, pna_sca_s, pna_gca_s, pnd_rcd_s, pnd_scd_s, pnd_gcd_s, pnb_rcb_s, pnb_scb_s, pnb_gcb_s
#endif

#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: temp, twet, pres, qv
#else
      REAL, DIMENSION(kts:kte):: temp, twet, pres, qv
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rc, ri, rr, rs, rg, rb
#else
      REAL, DIMENSION(kts:kte):: rc, ri, rr, rs, rg, rb
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: ni, nr, nc, ns, ng, nwfa, nifa, nbca
#else
      REAL, DIMENSION(kts:kte):: ni, nr, nc, ns, ng, nwfa, nifa, nbca
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rho, rhof, rhof2
#else
      REAL, DIMENSION(kts:kte):: rho, rhof, rhof2
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: qvs, qvsi, delQvs
#else
      REAL, DIMENSION(kts:kte):: qvs, qvsi, delQvs
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: satw, sati, ssatw, ssati
#else
      REAL, DIMENSION(kts:kte):: satw, sati, ssatw, ssati
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: diffu, visco, vsc2, &
           tcond, lvap, ocp, lvt2
#else
      REAL, DIMENSION(kts:kte):: diffu, visco, vsc2, &
           tcond, lvap, ocp, lvt2
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: ilamr, ilamg, N0_r, N0_g
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: ilamr, ilamg, N0_r, N0_g
#endif
      DOUBLE PRECISION:: N0_melt
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: mvd_r, mvd_c, mvd_g
#else
      REAL, DIMENSION(kts:kte):: mvd_r, mvd_c, mvd_g
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: smob, smo2, smo1, smo0, &
           smoc, smod, smoe, smof, smog
#else
      REAL, DIMENSION(kts:kte):: smob, smo2, smo1, smo0, &
           smoc, smod, smoe, smof, smog
#endif

#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: sed_r,sed_s,sed_g,sed_i,sed_n,sed_c,sed_b
#else
      REAL, DIMENSION(kts:kte):: sed_r,sed_s,sed_g,sed_i,sed_n,sed_c,sed_b
#endif

      REAL:: rgvm, delta_tp, orho, lfus2
      REAL, DIMENSION(5):: onstep
      DOUBLE PRECISION:: N0_exp, N0_min, lam_exp, lamc, lamr, lamg
      DOUBLE PRECISION:: lami, ilami, ilamc
      REAL:: xDc, Dc_b, Dc_g, xDi, xDr, xDs, xDg, Ds_m, Dg_m
      DOUBLE PRECISION:: Dr_star, Dc_star
      REAL:: zeta1, zeta, taud, tau
      REAL:: stoke_r, stoke_s, stoke_g, stoke_i
      REAL:: vti, vtr, vts, vtg, vtc
      REAL:: xrho_g, afall, vtg1, vtg2
      REAL:: bfall = 3*b_coeff - 1
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU+1):: vtik, vtnik, vtrk, vtnrk, vtsk, vtgk,  &
                  vtngk, vtck, vtnck
#else
      REAL, DIMENSION(kts:kte+1):: vtik, vtnik, vtrk, vtnrk, vtsk, vtgk,  &
                  vtngk, vtck, vtnck
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: vts_boost
#else
      REAL, DIMENSION(kts:kte):: vts_boost
#endif
      REAL:: M0, slam1, slam2
      REAL:: Mrat, ils1, ils2, t1_vts, t2_vts, t3_vts, t4_vts, C_snow
      REAL:: a_, b_, loga_, A1, A2, tf
      REAL:: tempc, tc0, r_mvd1, r_mvd2, xkrat
      REAL:: dew_t, Tlcl, The
#ifdef WRF_GPU
      REAL:: twet_k
      REAL:: tempc_s, rhof_s, rhof2_s, qvs_s, delQvs_s, qvsi_s, satw_s, sati_s, ssatw_s, ssati_s, &
             diffu_s, visco_s, ocp_s, vsc2_s, lvap_s, tcond_s
#endif
      REAL:: xnc, xri, xni, xmi, oxmi, xrc, xrr, xnr, xrg, xng, xrb
      REAL:: xsat, rate_max, sump, ratio
      REAL:: clap, fcd, dfcd
      REAL:: otemp, rvs, rvs_p, rvs_pp, gamsc, alphsc, t1_evap, t1_subl
      REAL:: r_frac, g_frac, const_Ri, rime_dens
      REAL:: Ef_rw, Ef_sw, Ef_gw, Ef_rr
      REAL:: Ef_ra, Ef_sa, Ef_ga
      REAL:: dtsave, odts, odt, odzq, hgt_agl
      REAL:: xslw1, ygra1, zans1, eva_factor
      REAL:: SR, melt_f
      INTEGER:: i, k, k2, n, nn, nstep, k_0, kbot, IT, iexfrq, k_melting
      INTEGER, DIMENSION(5):: ksed1
      INTEGER:: nir, nis, nig, nii, nic, niin
      INTEGER:: idx_tc, idx_t, idx_s, idx_g1, idx_g, idx_r1, idx_r,     &
                idx_i1, idx_i, idx_c, idx, idx_d, idx_n, idx_in
#ifdef WRF_GPU
      INTEGER, DIMENSION(1:KTGPU):: idx_bg
#else
      INTEGER, DIMENSION(kts:kte):: idx_bg
#endif

      LOGICAL:: melti, no_micro
#ifdef WRF_GPU
      LOGICAL, DIMENSION(1:KTGPU):: L_qc, L_qi, L_qr, L_qs, L_qg
#else
      LOGICAL, DIMENSION(kts:kte):: L_qc, L_qi, L_qr, L_qs, L_qg
#endif
      LOGICAL:: debug_flag
      CHARACTER*256:: mp_debug
      INTEGER:: nu_c

!+---+

      debug_flag = .false.
!     if (ii.eq.901 .and. jj.eq.379) debug_flag = .true.
      if(debug_flag) then
#ifndef WRF_GPU
        write(mp_debug, *) 'DEBUG INFO, mp_thompson at (i,j) ', ii, ', ', jj
#endif
#ifndef WRF_GPU
        CALL wrf_debug(550, mp_debug)
#endif
      endif

#ifdef WRF_GPU
      if (th_probe == 6) return
#endif
      no_micro = .true.
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1

!+---+-----------------------------------------------------------------+
!.. Source/sink terms.  First 2 chars: "pr" represents source/sink of
!.. mass while "pn" represents source/sink of number.  Next char is one
!.. of "v" for water vapor, "r" for rain, "i" for cloud ice, "w" for
!.. cloud water, "s" for snow, and "g" for graupel.  Next chars
!.. represent processes: "de" for sublimation/deposition, "ev" for
!.. evaporation, "fz" for freezing, "ml" for melting, "au" for
!.. autoconversion, "nu" for ice nucleation, "hm" for Hallet/Mossop
!.. secondary ice production, and "c" for collection followed by the
!.. character for the species being collected.  ALL of these terms are
!.. positive (except for deposition/sublimation terms which can switch
!.. signs based on super/subsaturation) and are treated as negatives
!.. where necessary in the tendency equations.
!+---+-----------------------------------------------------------------+

#ifndef WRF_GPU
      do k = kts, kte
         tten(k) = 0.
         qvten(k) = 0.
         qcten(k) = 0.
         qiten(k) = 0.
         qrten(k) = 0.
         qsten(k) = 0.
         qgten(k) = 0.
         ngten(k) = 0.
         qbten(k) = 0.
         niten(k) = 0.
         nrten(k) = 0.
         ncten(k) = 0.
         nwfaten(k) = 0.
         nifaten(k) = 0.
         nbcaten(k) = 0.

         prw_vcd(k) = 0.

         pnc_wcd(k) = 0.
         pnc_wau(k) = 0.
         pnc_rcw(k) = 0.
         pnc_scw(k) = 0.
         pnc_gcw(k) = 0.

         prv_rev(k) = 0.
         prr_wau(k) = 0.
         prr_rcw(k) = 0.
         prr_rcs(k) = 0.
         prr_rcg(k) = 0.
         prr_sml(k) = 0.
         prr_gml(k) = 0.
         prr_rci(k) = 0.
         pnr_wau(k) = 0.
         pnr_rcs(k) = 0.
         pnr_rcg(k) = 0.
         pnr_rci(k) = 0.
         pnr_sml(k) = 0.
         pnr_gml(k) = 0.
         pnr_rev(k) = 0.
         pnr_rcr(k) = 0.
         pnr_rfz(k) = 0.

         pri_inu(k) = 0.
         pni_inu(k) = 0.
         pri_ihm(k) = 0.
         pni_ihm(k) = 0.
         pri_wfz(k) = 0.
         pni_wfz(k) = 0.
         pri_rfz(k) = 0.
         pni_rfz(k) = 0.
         pri_ide(k) = 0.
         pni_ide(k) = 0.
         pri_rci(k) = 0.
         pni_rci(k) = 0.
         pni_sci(k) = 0.
         pni_iau(k) = 0.
         pri_iha(k) = 0.
         pni_iha(k) = 0.

         prs_iau(k) = 0.
         prs_sci(k) = 0.
         prs_rcs(k) = 0.
         prs_scw(k) = 0.
         prs_sde(k) = 0.
         prs_ihm(k) = 0.
         prs_ide(k) = 0.

         prg_scw(k) = 0.
         prg_rfz(k) = 0.
         prg_gde(k) = 0.
         prg_gcw(k) = 0.
         prg_rci(k) = 0.
         prg_rcs(k) = 0.
         prg_rcg(k) = 0.
         prg_ihm(k) = 0.
         !   new source/sink terms for 3-moment graupel
         png_scw(k) = 0.
         png_rcs(k) = 0.
         png_rcg(k) = 0.
         png_gde(k) = 0.

         pbg_scw(k) = 0.
         pbg_rfz(k) = 0.
         pbg_gcw(k) = 0.
         pbg_rci(k) = 0.
         pbg_rcs(k) = 0.
         pbg_rcg(k) = 0.
         pbg_sml(k) = 0.
         pbg_gml(k) = 0.

         pna_rca(k) = 0.
         pna_sca(k) = 0.
         pna_gca(k) = 0.

         pnd_rcd(k) = 0.
         pnd_scd(k) = 0.
         pnd_gcd(k) = 0.

         pnb_rcb(k) = 0.
         pnb_scb(k) = 0.
         pnb_gcb(k) = 0.
      enddo
#endif
#if ( WRF_CHEM == 1 )
    if ( wetscav_on ) then
      do k = kts, kte
         rainprod(k) = 0.
         evapprod(k) = 0.
      enddo
    endif
#endif

!..Bug fix (2016Jun15), prevent use of uninitialized value(s) of snow moments.
      do k = kts, kte
         smo0(k) = 0.
         smo1(k) = 0.
         smo2(k) = 0.
         smob(k) = 0.
         smoc(k) = 0.
         smod(k) = 0.
         smoe(k) = 0.
         smof(k) = 0.
         smog(k) = 0.
         ns(k)   = 0.
         mvd_r(k) = 0.
         mvd_c(k) = 0.
      enddo

!+---+-----------------------------------------------------------------+
!..Put column of data into local arrays.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         temp(k) = t1d(k)
         qv(k) = MAX(1.E-10, qv1d(k))
         pres(k) = p1d(k)
         rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
         if (is_aerosol_aware) then
            if (aer_init_opt .lt. 2) then  ! Constant or climatology (e.g., GOCART)
               nwfa(k) = MAX(11.1E6, MIN(9999.E6, nwfa1d(k)*rho(k)))
               nifa(k) = MAX(naIN1*0.01, MIN(9999.E6, nifa1d(k)*rho(k)))
               if (wif_input_opt .eq. 2) then  ! Considering BC aerosol
                  nbca(k) = MAX(5.55E6, MIN(9999.E6, nbca1d(k)*rho(k)))
               else
                  nbca(k) = 0.0
               endif
            else   ! First guess (e.g., GEOS-5)
               nwfa(k) = MAX(0.0, nwfa1d(k)*rho(k))
               nifa(k) = MAX(0.0, nifa1d(k)*rho(k))
               if (wif_input_opt .eq. 2) then  ! Considering BC aerosol
                  nbca(k) = MAX(0.0, nbca1d(k)*rho(k))
               else
                  nbca(k) = 0.0
               endif
            endif
         else
            nwfa(k) = MAX(11.1E6, MIN(9999.E6, nwfa1d(k)*rho(k)))
            nifa(k) = MAX(naIN1*0.01, MIN(9999.E6, nifa1d(k)*rho(k)))
            nbca(k) = MAX(5.55E6, MIN(9999.E6, nbca1d(k)*rho(k)))
         endif

         if (qc1d(k) .gt. R1) then
            no_micro = .false.
            rc(k) = qc1d(k)*rho(k)
            nc(k) = MAX(2., MIN(nc1d(k)*rho(k), Nt_c_max))
            L_qc(k) = .true.
            nu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
            lamc = (nc(k)*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc(k))**obmr
            xDc = (bm_r + nu_c + 1.) / lamc
            if (xDc.lt. D0c) then
             lamc = cce(2,nu_c)/D0c
            elseif (xDc.gt. D0r*2.) then
             lamc = cce(2,nu_c)/(D0r*2.)
            endif
            nc(k) = MIN( DBLE(Nt_c_max), ccg(1,nu_c)*ocg2(nu_c)*rc(k)   &
                  / am_r*lamc**bm_r)
            if (.NOT. is_aerosol_aware) nc(k) = Nt_c
         else
            qc1d(k) = 0.0
            nc1d(k) = 0.0
            rc(k) = R1
            nc(k) = 2.
            L_qc(k) = .false.
         endif

         if (qi1d(k) .gt. R1) then
            no_micro = .false.
            ri(k) = qi1d(k)*rho(k)
            ni(k) = MAX(R2, ni1d(k)*rho(k))
            if (ni(k).le. R2) then
               lami = cie(2)/5.E-6
               ni(k) = MIN(999.D3, cig(1)*oig2*ri(k)/am_i*lami**bm_i)
            endif
            L_qi(k) = .true.
            lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
            ilami = 1./lami
            xDi = (bm_i + mu_i + 1.) * ilami
            if (xDi.lt. 5.E-6) then
             lami = cie(2)/5.E-6
             ni(k) = MIN(999.D3, cig(1)*oig2*ri(k)/am_i*lami**bm_i)
            elseif (xDi.gt. 300.E-6) then
             lami = cie(2)/300.E-6
             ni(k) = cig(1)*oig2*ri(k)/am_i*lami**bm_i
            endif
         else
            qi1d(k) = 0.0
            ni1d(k) = 0.0
            ri(k) = R1
            ni(k) = R2
            L_qi(k) = .false.
         endif

         if (qr1d(k) .gt. R1) then
            no_micro = .false.
            rr(k) = qr1d(k)*rho(k)
            nr(k) = MAX(R2, nr1d(k)*rho(k))
            if (nr(k).le. R2) then
               mvd_r(k) = 1.0E-3
               lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
               nr(k) = crg(2)*org3*rr(k)*lamr**bm_r / am_r
            endif
            L_qr(k) = .true.
            lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
            mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
            if (mvd_r(k) .gt. 2.5E-3) then
               mvd_r(k) = 2.5E-3
               lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
               nr(k) = crg(2)*org3*rr(k)*lamr**bm_r / am_r
            elseif (mvd_r(k) .lt. D0r*0.75) then
               mvd_r(k) = D0r*0.75
               lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
               nr(k) = crg(2)*org3*rr(k)*lamr**bm_r / am_r
            endif
         else
            qr1d(k) = 0.0
            nr1d(k) = 0.0
            rr(k) = R1
            nr(k) = R2
            L_qr(k) = .false.
         endif
         if (qs1d(k) .gt. R1) then
            no_micro = .false.
            rs(k) = qs1d(k)*rho(k)
            L_qs(k) = .true.
         else
            qs1d(k) = 0.0
            rs(k) = R1
            L_qs(k) = .false.
         endif
         if (qg1d(k) .gt. R1) then
            no_micro = .false.
            L_qg(k) = .true.
            rg(k) = qg1d(k)*rho(k)
            ng(k) = MAX(R2, ng1d(k)*rho(k))
            rb(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k))
            rb(k) = MIN(qg1d(k)/rho_g(1), rb(k))
            qb1d(k) = rb(k)
            idx_bg(k) = MAX(1,MIN(NINT(qg1d(k)/rb(k) *0.01)+1,NRHG))
            if (ng(k).le. R2) then
               mvd_g(k) = 1.5E-3
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               ng(k) = cgg(2,1)*ogg3*rg(k)*lamg**bm_g / am_g(idx_bg(k))
            endif
            lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng(k)/rg(k))**obmg
            mvd_g(k) = (3.0 + mu_g + 0.672) / lamg
            if (mvd_g(k) .gt. 25.4E-3) then
               mvd_g(k) = 25.4E-3
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               ng(k) = cgg(2,1)*ogg3*rg(k)*lamg**bm_g / am_g(idx_bg(k))
            elseif (mvd_g(k) .lt. D0r) then
               mvd_g(k) = D0r
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               ng(k) = cgg(2,1)*ogg3*rg(k)*lamg**bm_g / am_g(idx_bg(k))
            endif
         else
            qg1d(k) = 0.0
            ng1d(k) = 0.0
            qb1d(k) = 0.0
            idx_bg(k) = idx_bg1
            rg(k) = R1
            ng(k) = R2
            rb(k) = R1/rho(k)/rho_g(NRHG)
            L_qg(k) = .false.
         endif
         if (.not. is_hail_aware) idx_bg(k) = idx_bg1
      enddo

!+---+-----------------------------------------------------------------+
!     if (debug_flag) then
!      write(mp_debug,*) 'DEBUG-VERBOSE at (i,j) ', ii, ', ', jj
!      CALL wrf_debug(550, mp_debug)
!      do k = kts, kte
!         write(mp_debug, '(a,i3,f8.2,1x,f7.2,1x, 13(1x,e13.6))')        &
!     &              'VERBOSE: ', k, pres(k)*0.01, temp(k)-273.15, qv(k), rc(k), rr(k), ri(k), rs(k), rg(k), nc(k), nr(k), ni(k), ng(k), rb(k), nwfa(k), nifa(k)
!        CALL wrf_debug(550, mp_debug)
!      enddo
!     endif
!+---+-----------------------------------------------------------------+

!+---+-----------------------------------------------------------------+
!..Derive various thermodynamic variables frequently used.
!.. Saturation vapor pressure (mixing ratio) over liquid/ice comes from
!.. Flatau et al. 1992; enthalpy (latent heat) of vaporization from
!.. Bohren & Albrecht 1998; others from Pruppacher & Klett 1978.
!+---+-----------------------------------------------------------------+
#ifdef WRF_GPU
      ! GPU: only what the no_micro test needs; the other per-level properties are evaluated as scalars inside
      ! the fused rate loop (same expressions) - no per-level arrays written for clear columns
      k_melting = 0
      do k = kts, kte
         tempc = temp(k) - 273.15
         if (tempc .le. 0.0) then
          qvsi_s = rsif(pres(k), temp(k))
         else
          qvsi_s = rslf(pres(k), temp(k))
          k_melting = MAX(k, k_melting)
         endif
         sati_s = qv(k)/qvsi_s
         ssati_s = sati_s - 1.
         if (abs(ssati_s).lt. eps) ssati_s = 0.0
         if (no_micro .and. ssati_s.gt. 0.0) no_micro = .false.
      enddo
#else
      k_melting = 0
      do k = kts, kte
         tempc = temp(k) - 273.15
         rhof(k) = SQRT(RHO_NOT/rho(k))
         rhof2(k) = SQRT(rhof(k))
         qvs(k) = rslf(pres(k), temp(k))
         delQvs(k) = MAX(0.0, rslf(pres(k), 273.15)-qv(k))
         if (tempc .le. 0.0) then
          qvsi(k) = rsif(pres(k), temp(k))
         else
          qvsi(k) = qvs(k)
          k_melting = MAX(k, k_melting)
         endif
         satw(k) = qv(k)/qvs(k)
         sati(k) = qv(k)/qvsi(k)
         ssatw(k) = satw(k) - 1.
         ssati(k) = sati(k) - 1.
         if (abs(ssatw(k)).lt. eps) ssatw(k) = 0.0
         if (abs(ssati(k)).lt. eps) ssati(k) = 0.0
         if (no_micro .and. ssati(k).gt. 0.0) no_micro = .false.
         diffu(k) = 2.11E-5*(temp(k)/273.15)**1.94 * (101325./pres(k))
         if (tempc .ge. 0.0) then
            visco(k) = (1.718+0.0049*tempc)*1.0E-5
         else
            visco(k) = (1.718+0.0049*tempc-1.2E-5*tempc*tempc)*1.0E-5
         endif
         ocp(k) = 1./(Cp*(1.+0.887*qv(k)))
         vsc2(k) = SQRT(rho(k)/visco(k))
         lvap(k) = lvap0 + (2106.0 - 4218.0)*tempc
         tcond(k) = (5.69 + 0.0168*tempc)*1.0E-5 * 418.936
         twet(k) = temp(k)
      enddo
#endif

#ifndef WRF_GPU
      if (k_melting .gt. 0) then
         do k = kts, k_melting
            if (satw(k) .lt. 0.999) then
               dew_t = MIN(temp(k)-0.001, t_dew(pres(k), qv(k))) 
               Tlcl = t_lcl(temp(k), dew_t)
               The = theta_e(pres(k), temp(k), qv(k), Tlcl)
               twet(k) = MIN(temp(k), compT_fr_The(The, pres(k)))
            endif
      enddo
      endif
#endif

!+---+-----------------------------------------------------------------+
!..If no existing hydrometeor species and no chance to initiate ice or
!.. condense cloud water, just exit quickly!
!+---+-----------------------------------------------------------------+

      if (no_micro) return
#ifdef WRF_GPU
      if (th_probe == 1) return
#endif
#ifdef WRF_GPU
!.. GPU: zero the tendency/process-rate arrays only for columns that do microphysics (none of them is
!.. read or written before the no_micro return) - clear columns skip ~90 local-memory array stores
      do k = kts, kte
         tten(k) = 0.
         qvten(k) = 0.
         qcten(k) = 0.
         qiten(k) = 0.
         qrten(k) = 0.
         qsten(k) = 0.
         qgten(k) = 0.
         ngten(k) = 0.
         qbten(k) = 0.
         niten(k) = 0.
         nrten(k) = 0.
         ncten(k) = 0.
         nwfaten(k) = 0.
         nifaten(k) = 0.
         nbcaten(k) = 0.

         prw_vcd(k) = 0.

         pnc_wcd(k) = 0.
         prv_rev(k) = 0.
         prr_wau(k) = 0.
         prr_rcw(k) = 0.
         prr_sml(k) = 0.
         prr_gml(k) = 0.
         pnr_rev(k) = 0.
         pri_rci(k) = 0.
         prs_iau(k) = 0.
         prs_sci(k) = 0.
         prs_scw(k) = 0.
         prs_sde(k) = 0.
         prg_scw(k) = 0.
         prg_gde(k) = 0.
         prg_gcw(k) = 0.
         !   new source/sink terms for 3-moment graupel
      enddo
#endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope, and useful moments for snow.
!+---+-----------------------------------------------------------------+
      if (.not. iiwarm) then
      do k = kts, kte
         if (.not. L_qs(k)) CYCLE
         tc0 = MIN(-0.1, temp(k)-273.15)
         smob(k) = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2(k) = smob(k)
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
               + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
               + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
               + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
               + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
               + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
               + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
               + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
               + sb(10)*bm_s*bm_s*bm_s
            smo2(k) = (smob(k)/a_)**(1./b_)
         endif

!..Calculate 0th moment.  Represents snow number concentration.
         loga_ = sa(1) + sa(2)*tc0 + sa(5)*tc0*tc0 + sa(9)*tc0*tc0*tc0
         a_ = 10.0**loga_
         b_ = sb(1) + sb(2)*tc0 + sb(5)*tc0*tc0 + sb(9)*tc0*tc0*tc0
         smo0(k) = a_ * smo2(k)**b_

!..Calculate 1st moment.  Useful for depositional growth and melting.
         loga_ = sa(1) + sa(2)*tc0 + sa(3) &
               + sa(4)*tc0 + sa(5)*tc0*tc0 &
               + sa(6) + sa(7)*tc0*tc0 &
               + sa(8)*tc0 + sa(9)*tc0*tc0*tc0 &
               + sa(10)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3) + sb(4)*tc0 &
              + sb(5)*tc0*tc0 + sb(6) &
              + sb(7)*tc0*tc0 + sb(8)*tc0 &
              + sb(9)*tc0*tc0*tc0 + sb(10)
         smo1(k) = a_ * smo2(k)**b_

!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
               + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
               + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
               + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
              + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
              + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc(k) = a_ * smo2(k)**b_

!..Calculate snow number concentration (explicit integral, not smo0)
         M0 = smob(k)/smoc(k)
         Mrat = smob(k)*M0*M0*M0
         slam1 = M0 * Lam0
         slam2 = M0 * Lam1
         ns(k) = Mrat*Kap0/slam1                                        &
                 + Mrat*Kap1*M0**mu_s*csg(15)/slam2**cse(15)

!..Calculate bv_s+2 (th) moment.  Useful for riming.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(13) &
               + sa(4)*tc0*cse(13) + sa(5)*tc0*tc0 &
               + sa(6)*cse(13)*cse(13) + sa(7)*tc0*tc0*cse(13) &
               + sa(8)*tc0*cse(13)*cse(13) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(13)*cse(13)*cse(13)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(13) + sb(4)*tc0*cse(13) &
              + sb(5)*tc0*tc0 + sb(6)*cse(13)*cse(13) &
              + sb(7)*tc0*tc0*cse(13) + sb(8)*tc0*cse(13)*cse(13) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(13)*cse(13)*cse(13)
         smoe(k) = a_ * smo2(k)**b_

!..Calculate 1+(bv_s+1)/2 (th) moment.  Useful for depositional growth.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(16) &
               + sa(4)*tc0*cse(16) + sa(5)*tc0*tc0 &
               + sa(6)*cse(16)*cse(16) + sa(7)*tc0*tc0*cse(16) &
               + sa(8)*tc0*cse(16)*cse(16) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(16)*cse(16)*cse(16)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(16) + sb(4)*tc0*cse(16) &
              + sb(5)*tc0*tc0 + sb(6)*cse(16)*cse(16) &
              + sb(7)*tc0*tc0*cse(16) + sb(8)*tc0*cse(16)*cse(16) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(16)*cse(16)*cse(16)
         smof(k) = a_ * smo2(k)**b_

!..Calculate bm_s + bv_s+2 (th) moment.  Useful for riming into graupel.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(17) &
               + sa(4)*tc0*cse(17) + sa(5)*tc0*tc0 &
               + sa(6)*cse(17)*cse(17) + sa(7)*tc0*tc0*cse(17) &
               + sa(8)*tc0*cse(17)*cse(17) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(17)*cse(17)*cse(17)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(17) + sb(4)*tc0*cse(17) &
              + sb(5)*tc0*tc0 + sb(6)*cse(17)*cse(17) &
              + sb(7)*tc0*tc0*cse(17) + sb(8)*tc0*cse(17)*cse(17) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(17)*cse(17)*cse(17)
         smog(k) = a_ * smo2(k)**b_

      enddo

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for graupel.
!+---+-----------------------------------------------------------------+

      do k = kte, kts, -1
         lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng(k)/rg(k))**obmg
         ilamg(k) = 1./lamg
         N0_g(k) = ng(k)*ogg2*lamg**cge(2,1)
      enddo

      endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for rain.
!+---+-----------------------------------------------------------------+
      do k = kte, kts, -1
         lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
         ilamr(k) = 1./lamr
         mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
         N0_r(k) = nr(k)*org2*lamr**cre(2)
      enddo

!+---+-----------------------------------------------------------------+
!..Compute warm-rain process terms (except evap done later).
!+---+-----------------------------------------------------------------+

#ifdef WRF_GPU
!.. GPU: warm-rain rates, ice rates, depletion limits and tendencies fused into one level loop (every one of
!.. them is per level). The 59 process rates used only here are scalars (zeroed per level, as the zero loop
!.. did) instead of KTGPU-long local arrays - same per-level arithmetic, far less local-memory traffic.
      do k = kts, kte
         ! GPU: per-level thermodynamic properties as scalars (the setup loop's expressions)
         tempc_s = temp(k) - 273.15
         rhof_s = SQRT(RHO_NOT/rho(k))
         rhof2_s = SQRT(rhof_s)
         qvs_s = rslf(pres(k), temp(k))
         delQvs_s = MAX(0.0, rslf(pres(k), 273.15)-qv(k))
         if (tempc_s .le. 0.0) then
          qvsi_s = rsif(pres(k), temp(k))
         else
          qvsi_s = qvs_s
         endif
         satw_s = qv(k)/qvs_s
         sati_s = qv(k)/qvsi_s
         ssatw_s = satw_s - 1.
         ssati_s = sati_s - 1.
         if (abs(ssatw_s).lt. eps) ssatw_s = 0.0
         if (abs(ssati_s).lt. eps) ssati_s = 0.0
         diffu_s = 2.11E-5*(temp(k)/273.15)**1.94 * (101325./pres(k))
         if (tempc_s .ge. 0.0) then
            visco_s = (1.718+0.0049*tempc_s)*1.0E-5
         else
            visco_s = (1.718+0.0049*tempc_s-1.2E-5*tempc_s*tempc_s)*1.0E-5
         endif
         ocp_s = 1./(Cp*(1.+0.887*qv(k)))
         vsc2_s = SQRT(rho(k)/visco_s)
         lvap_s = lvap0 + (2106.0 - 4218.0)*tempc_s
         tcond_s = (5.69 + 0.0168*tempc_s)*1.0E-5 * 418.936
         ! GPU: wet-bulb temperature (iterative moist-adiabat solver) only where it is used - all its uses are
         ! in snow/graupel processes; the host computes it for every level up to k_melting before the no_micro exit
         twet_k = temp(k)
         if (k .le. k_melting) then
          if (satw_s .lt. 0.999 .and. (L_qs(k) .or. L_qg(k))) then
             dew_t = MIN(temp(k)-0.001, t_dew(pres(k), qv(k)))
             Tlcl = t_lcl(temp(k), dew_t)
             The = theta_e(pres(k), temp(k), qv(k), Tlcl)
             twet_k = MIN(temp(k), compT_fr_The(The, pres(k)))
          endif
         endif
         pnc_wau_s = 0.
         pnc_rcw_s = 0.
         pnc_scw_s = 0.
         pnc_gcw_s = 0.
         prr_rcs_s = 0.
         prr_rcg_s = 0.
         prr_rci_s = 0.
         pnr_wau_s = 0.
         pnr_rcs_s = 0.
         pnr_rcg_s = 0.
         pnr_rci_s = 0.
         pnr_sml_s = 0.
         pnr_gml_s = 0.
         pnr_rcr_s = 0.
         pnr_rfz_s = 0.
         pri_inu_s = 0.
         pni_inu_s = 0.
         pri_ihm_s = 0.
         pni_ihm_s = 0.
         pri_wfz_s = 0.
         pni_wfz_s = 0.
         pri_rfz_s = 0.
         pni_rfz_s = 0.
         pri_ide_s = 0.
         pni_ide_s = 0.
         pni_rci_s = 0.
         pni_sci_s = 0.
         pni_iau_s = 0.
         pri_iha_s = 0.
         pni_iha_s = 0.
         prs_rcs_s = 0.
         prs_ihm_s = 0.
         prs_ide_s = 0.
         prg_rfz_s = 0.
         prg_rci_s = 0.
         prg_rcs_s = 0.
         prg_rcg_s = 0.
         prg_ihm_s = 0.
         png_scw_s = 0.
         png_rcs_s = 0.
         png_rcg_s = 0.
         png_gde_s = 0.
         pbg_scw_s = 0.
         pbg_rfz_s = 0.
         pbg_gcw_s = 0.
         pbg_rci_s = 0.
         pbg_rcs_s = 0.
         pbg_rcg_s = 0.
         pbg_sml_s = 0.
         pbg_gml_s = 0.
         pna_rca_s = 0.
         pna_sca_s = 0.
         pna_gca_s = 0.
         pnd_rcd_s = 0.
         pnd_scd_s = 0.
         pnd_gcd_s = 0.
         pnb_rcb_s = 0.
         pnb_scb_s = 0.
         pnb_gcb_s = 0.

!..Rain self-collection follows Seifert, 1994 and drop break-up
!.. follows Verlinde and Cotton, 1993.                                        RAIN2M
         if (L_qr(k) .and. mvd_r(k).gt. D0r) then
!-GT      Ef_rr = 1.0
!-GT      if (mvd_r(k) .gt. 1500.0E-6) then
             Ef_rr = 1.0 - EXP(2300.0*(mvd_r(k)-1950.0E-6))
!-GT      endif
          pnr_rcr_s = Ef_rr * 2.0*nr(k)*rr(k)
         endif

         mvd_c(k) = D0c
         if (L_qc(k)) then
          nu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
          xDc = MAX(D0c*1.E6, ((rc(k)/(am_r*nc(k)))**obmr) * 1.E6)
          lamc = (nc(k)*am_r* ccg(2,nu_c) * ocg1(nu_c) / rc(k))**obmr
          mvd_c(k) = (3.0+nu_c+0.672) / lamc
          mvd_c(k) = MAX(D0c, MIN(mvd_c(k), D0r))
         endif

!..Autoconversion follows Berry & Reinhardt (1974) with characteristic
!.. diameters correctly computed from gamma distrib of cloud droplets.
         if (rc(k).gt. 0.01e-3) then
          Dc_g = ((ccg(3,nu_c)*ocg2(nu_c))**obmr / lamc) * 1.E6
          Dc_b = (xDc*xDc*xDc*Dc_g*Dc_g*Dc_g - xDc*xDc*xDc*xDc*xDc*xDc) &
                 **(1./6.)
          zeta1 = 0.5*((6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4) &
                     + abs(6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4))
          zeta = 0.027*rc(k)*zeta1
          taud = 0.5*((0.5*Dc_b - 7.5) + abs(0.5*Dc_b - 7.5)) + R1
          tau  = 3.72/(rc(k)*taud)
          prr_wau(k) = zeta/tau
          prr_wau(k) = MIN(DBLE(rc(k)*odts), prr_wau(k))
          pnr_wau_s = prr_wau(k) / (am_r*nu_c*10.*D0r*D0r*D0r)             ! RAIN2M
          pnc_wau_s = MIN(DBLE(nc(k)*odts), prr_wau(k)                 &
                     / (am_r*mvd_c(k)*mvd_c(k)*mvd_c(k)))                   ! Qc2M
         endif

!..Rain collecting cloud water.  In CE, assume Dc<<Dr and vtc=~0.
         if (L_qr(k) .and. mvd_r(k).gt. D0r .and. mvd_c(k).gt. D0c) then
          lamr = 1./ilamr(k)
          idx = 1 + INT(nbr*DLOG(mvd_r(k)/Dr(1))/DLOG(Dr(nbr)/Dr(1)))
          idx = MIN(idx, nbr)
          Ef_rw = t_Efrw(idx, INT(mvd_c(k)*1.E6))
          prr_rcw(k) = rhof_s*t1_qr_qc*Ef_rw*rc(k)*N0_r(k) &
                         *((lamr+fv_r)**(-cre(9)))
          prr_rcw(k) = MIN(DBLE(rc(k)*odts), prr_rcw(k))
          pnc_rcw_s = rhof_s*t1_qr_qc*Ef_rw*nc(k)*N0_r(k)             &
                         *((lamr+fv_r)**(-cre(9)))                          ! Qc2M
          pnc_rcw_s = MIN(DBLE(nc(k)*odts), pnc_rcw_s)
         endif

!..Rain collecting aerosols, wet scavenging.
         if (L_qr(k) .and. mvd_r(k).gt. D0r) then
          Ef_ra = Eff_aero(mvd_r(k),0.04E-6,visco_s,rho(k),temp(k),'r')
          lamr = 1./ilamr(k)
          pna_rca_s = rhof_s*t1_qr_qc*Ef_ra*nwfa(k)*N0_r(k)           &
                         *((lamr+fv_r)**(-cre(9)))
          pna_rca_s = MIN(DBLE(nwfa(k)*odts), pna_rca_s)

          Ef_ra = Eff_aero(mvd_r(k),0.8E-6,visco_s,rho(k),temp(k),'r')
          pnd_rcd_s = rhof_s*t1_qr_qc*Ef_ra*nifa(k)*N0_r(k)           &
                         *((lamr+fv_r)**(-cre(9)))
          pnd_rcd_s = MIN(DBLE(nifa(k)*odts), pnd_rcd_s)

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_ra = Eff_aero(mvd_r(k),0.0236E-6, &
                                 visco_s,rho(k),temp(k),'r')
              pnb_rcb_s = rhof_s*t1_qr_qc*Ef_ra*nbca(k)*N0_r(k)       &
                             *((lamr+fv_r)**(-cre(9)))
              pnb_rcb_s = MIN(DBLE(nbca(k)*odts), pnb_rcb_s)
            endif
          endif
         endif

      if (.not. iiwarm) then
         vts_boost(k) = 1.0
         orho = 1./rho(k)

         if (L_qs(k)) then
            xDs = smoc(k) / smob(k)
            rho_s = MAX(rho_g(1), MIN(0.13/xDs, rho_i-100.))
         else
            xDs = 0.
            rho_s = 100.
         endif

!..Temperature lookup table indexes.
         tempc = temp(k) - 273.15
         idx_tc = MAX(1, MIN(NINT(-tempc), 45) )
         idx_t = INT( (tempc-2.5)/5. ) - 1
         idx_t = MAX(1, -idx_t)
         idx_t = MIN(idx_t, ntb_t)
         IT = MAX(1, MIN(NINT(-tempc), 31) )

!..Cloud water lookup table index.
         if (rc(k).gt. r_c(1)) then
          nic = NINT(ALOG10(rc(k)))
          do nn = nic-1, nic+1
             n = nn
             if ( (rc(k)/10.**nn).ge.1.0 .and. &
                  (rc(k)/10.**nn).lt.10.0) goto 141
          enddo
 141      continue
          idx_c = INT(rc(k)/10.**n) + 10*(n-nic2) - (n-nic2)
          idx_c = MAX(1, MIN(idx_c, ntb_c))
         else
          idx_c = 1
         endif

!..Cloud droplet number lookup table index.
         idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(nc(k)/t_Nc(1)) / nic1)
         idx_n = MAX(1, MIN(idx_n, nbc))

!..Cloud ice lookup table indexes.
         if (ri(k).gt. r_i(1)) then
          nii = NINT(ALOG10(ri(k)))
          do nn = nii-1, nii+1
             n = nn
             if ( (ri(k)/10.**nn).ge.1.0 .and. &
                  (ri(k)/10.**nn).lt.10.0) goto 142
          enddo
 142      continue
          idx_i = INT(ri(k)/10.**n) + 10*(n-nii2) - (n-nii2)
          idx_i = MAX(1, MIN(idx_i, ntb_i))
         else
          idx_i = 1
         endif

         if (ni(k).gt. Nt_i(1)) then
          nii = NINT(ALOG10(ni(k)))
          do nn = nii-1, nii+1
             n = nn
             if ( (ni(k)/10.**nn).ge.1.0 .and. &
                  (ni(k)/10.**nn).lt.10.0) goto 143
          enddo
 143      continue
          idx_i1 = INT(ni(k)/10.**n) + 10*(n-nii3) - (n-nii3)
          idx_i1 = MAX(1, MIN(idx_i1, ntb_i1))
         else
          idx_i1 = 1
         endif

!..Rain lookup table indexes.
         if (rr(k).gt. r_r(1)) then
          nir = NINT(ALOG10(rr(k)))
          do nn = nir-1, nir+1
             n = nn
             if ( (rr(k)/10.**nn).ge.1.0 .and. &
                  (rr(k)/10.**nn).lt.10.0) goto 144
          enddo
 144      continue
          idx_r = INT(rr(k)/10.**n) + 10*(n-nir2) - (n-nir2)
          idx_r = MAX(1, MIN(idx_r, ntb_r))

          lamr = 1./ilamr(k)
          lam_exp = lamr * (crg(3)*org2*org1)**bm_r
          N0_exp = org1*rr(k)/am_r * lam_exp**cre(1)
          nir = NINT(DLOG10(N0_exp))
          do nn = nir-1, nir+1
             n = nn
             if ( (N0_exp/10.**nn).ge.1.0 .and. &
                  (N0_exp/10.**nn).lt.10.0) goto 145
          enddo
 145      continue
          idx_r1 = INT(N0_exp/10.**n) + 10*(n-nir3) - (n-nir3)
          idx_r1 = MAX(1, MIN(idx_r1, ntb_r1))
         else
          idx_r = 1
          idx_r1 = ntb_r1
         endif

!..Snow lookup table index.
         if (rs(k).gt. r_s(1)) then
          nis = NINT(ALOG10(rs(k)))
          do nn = nis-1, nis+1
             n = nn
             if ( (rs(k)/10.**nn).ge.1.0 .and. &
                  (rs(k)/10.**nn).lt.10.0) goto 146
          enddo
 146      continue
          idx_s = INT(rs(k)/10.**n) + 10*(n-nis2) - (n-nis2)
          idx_s = MAX(1, MIN(idx_s, ntb_s))
         else
          idx_s = 1
         endif

!..Graupel lookup table index.
         if (rg(k).gt. r_g(1)) then
          nig = NINT(ALOG10(rg(k)))
          do nn = nig-1, nig+1
             n = nn
             if ( (rg(k)/10.**nn).ge.1.0 .and. &
                  (rg(k)/10.**nn).lt.10.0) goto 147
          enddo
 147      continue
          idx_g = INT(rg(k)/10.**n) + 10*(n-nig2) - (n-nig2)
          idx_g = MAX(1, MIN(idx_g, ntb_g))

          lamg = 1./ilamg(k)
          lam_exp = lamg * (cgg(3,1)*ogg2*ogg1)**bm_g
          N0_exp = ogg1*rg(k)/am_g(idx_bg(k)) * lam_exp**cge(1,1)
          nig = NINT(DLOG10(N0_exp))
          do nn = nig-1, nig+1
             n = nn
             if ( (N0_exp/10.**nn).ge.1.0 .and. &
                  (N0_exp/10.**nn).lt.10.0) goto 148
          enddo
 148      continue
          idx_g1 = INT(N0_exp/10.**n) + 10*(n-nig3) - (n-nig3)
          idx_g1 = MAX(1, MIN(idx_g1, ntb_g1))
         else
          idx_g = 1
          idx_g1 = ntb_g1
         endif

!..Deposition/sublimation prefactor (from Srivastava & Coen 1992).
         otemp = 1./temp(k)
         rvs = rho(k)*qvsi_s
         rvs_p = rvs*otemp*(lsub*otemp*oRv - 1.)
         rvs_pp = rvs * ( otemp*(lsub*otemp*oRv - 1.) &
                         *otemp*(lsub*otemp*oRv - 1.) &
                         + (-2.*lsub*otemp*otemp*otemp*oRv) &
                         + otemp*otemp)
         gamsc = lsub*diffu_s/tcond_s * rvs_p
         alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc)) &
                    * rvs_pp/rvs_p * rvs/rvs_p
         alphsc = MAX(1.E-9, alphsc)
         xsat = ssati_s
         if (abs(xsat).lt. 1.E-9) xsat=0.
         t1_subl = 4.*PI*( 1.0 - alphsc*xsat &
                + 2.*alphsc*alphsc*xsat*xsat &
                - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat ) &
                / (1.+gamsc)

!..Snow collecting cloud water.  In CE, assume Dc<<Ds and vtc=~0.
         if (L_qc(k) .and. mvd_c(k).gt. D0c) then
          if (xDs .gt. D0s) then
           idx = 1 + INT(nbs*DLOG(xDs/Ds(1))/DLOG(Ds(nbs)/Ds(1)))
           idx = MIN(idx, nbs)
           Ef_sw = t_Efsw(idx, INT(mvd_c(k)*1.E6))
           prs_scw(k) = rhof_s*t1_qs_qc*Ef_sw*rc(k)*smoe(k)
           prs_scw(k) = MIN(DBLE(rc(k)*odts), prs_scw(k))
           pnc_scw_s = rhof_s*t1_qs_qc*Ef_sw*nc(k)*smoe(k)                ! Qc2M
           pnc_scw_s = MIN(DBLE(nc(k)*odts), pnc_scw_s)
          endif

!..Graupel collecting cloud water.  In CE, assume Dc<<Dg and vtc=~0.
          if (rg(k).ge. r_g(1) .and. mvd_c(k).gt. D0c) then
           xDg = (bm_g + mu_g + 1.) * ilamg(k)
           vtg = rhof_s*av_g(idx_bg(k))*cgg(6,idx_bg(k))*ogg3 * ilamg(k)**bv_g(idx_bg(k))
           stoke_g = mvd_c(k)*mvd_c(k)*vtg*rho_w/(9.*visco_s*xDg)
!..Rime density formula of Cober and List (1993) also used by Milbrandt and Morrison (2014).
           const_Ri = -1.*(mvd_c(k)*0.5E6)*vtg/MIN(-0.1,tempc)
           const_Ri = MAX(0.1, MIN(const_Ri, 10.))
           rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
            if (stoke_g.ge.0.4 .and. stoke_g.le.10.) then
             Ef_gw = 0.55*ALOG10(2.51*stoke_g)
            elseif (stoke_g.lt.0.4) then
             Ef_gw = 0.0
            elseif (stoke_g.gt.10) then
             Ef_gw = 0.77
            endif
!!! Not sure what to do here - hail increases size rapidly here below melting level.
            if (twet_k.gt.T_0) Ef_gw = Ef_gw*0.1
            t1_qg_qc = PI*.25*av_g(idx_bg(k)) * cgg(9,idx_bg(k))
            prg_gcw(k) = rhof_s*t1_qg_qc*Ef_gw*rc(k)*N0_g(k) &
                          *ilamg(k)**cge(9,idx_bg(k))
            pnc_gcw_s = rhof_s*t1_qg_qc*Ef_gw*nc(k)*N0_g(k)           &
                          *ilamg(k)**cge(9,idx_bg(k))                    ! Qc2M
            pnc_gcw_s = MIN(DBLE(nc(k)*odts), pnc_gcw_s)
            if (twet_k.lt.T_0) pbg_gcw_s = prg_gcw(k)/rime_dens
          endif
         endif

!..Snow and graupel collecting aerosols, wet scavenging.
         if (rs(k) .gt. r_s(1)) then
          Ef_sa = Eff_aero(xDs,0.04E-6,visco_s,rho(k),temp(k),'s')
          pna_sca_s = rhof_s*t1_qs_qc*Ef_sa*nwfa(k)*smoe(k)
          pna_sca_s = MIN(DBLE(nwfa(k)*odts), pna_sca_s)

          Ef_sa = Eff_aero(xDs,0.8E-6,visco_s,rho(k),temp(k),'s')
          pnd_scd_s = rhof_s*t1_qs_qc*Ef_sa*nifa(k)*smoe(k)
          pnd_scd_s = MIN(DBLE(nifa(k)*odts), pnd_scd_s)

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_sa = Eff_aero(xDs,0.0236E-6,visco_s,rho(k),temp(k),'s')
              pnb_scb_s = rhof_s*t1_qs_qc*Ef_sa*nbca(k)*smoe(k)
              pnb_scb_s = MIN(DBLE(nbca(k)*odts), pnb_scb_s)
            endif
          endif
         endif
         if (rg(k) .gt. r_g(1)) then
          xDg = (bm_g + mu_g + 1.) * ilamg(k)
          Ef_ga = Eff_aero(xDg,0.04E-6,visco_s,rho(k),temp(k),'g')
          t1_qg_qc = PI*.25*av_g(idx_bg(k)) * cgg(9,idx_bg(k))
          pna_gca_s = rhof_s*t1_qg_qc*Ef_ga*nwfa(k)*N0_g(k)           &
                        *ilamg(k)**cge(9,idx_bg(k))
          pna_gca_s = MIN(DBLE(nwfa(k)*odts), pna_gca_s)

          Ef_ga = Eff_aero(xDg,0.8E-6,visco_s,rho(k),temp(k),'g')
          pnd_gcd_s = rhof_s*t1_qg_qc*Ef_ga*nifa(k)*N0_g(k)           &
                        *ilamg(k)**cge(9,idx_bg(k))
          pnd_gcd_s = MIN(DBLE(nifa(k)*odts), pnd_gcd_s)

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_ga = Eff_aero(xDg,0.0236E-6,visco_s,rho(k),temp(k),'g')
              pnb_gcb_s = rhof_s*t1_qg_qc*Ef_ga*nbca(k)*N0_g(k)       &
                            *ilamg(k)**cge(9,idx_bg(k))
              pnb_gcb_s = MIN(DBLE(nbca(k)*odts), pnb_gcb_s)
            endif
          endif
         endif

!..Rain collecting snow.  Cannot assume Wisner (1972) approximation
!.. or Mizuno (1990) approach so we solve the CE explicitly and store
!.. results in lookup table.
         if (rr(k).ge. r_r(1)) then
          if (rs(k).ge. r_s(1)) then
           if (twet_k.lt.T_0) then
            prr_rcs_s = -(tmr_racs2(idx_s,idx_t,idx_r1,idx_r) &
                           + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r) &
                           + tmr_racs1(idx_s,idx_t,idx_r1,idx_r) &
                           + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r))
            prs_rcs_s = tmr_racs2(idx_s,idx_t,idx_r1,idx_r) &
                         + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r) &
                         - tcs_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
            prg_rcs_s = tmr_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r) &
                         + tcs_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         + tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
            prr_rcs_s = MAX(DBLE(-rr(k)*odts), prr_rcs_s)
            prs_rcs_s = MAX(DBLE(-rs(k)*odts), prs_rcs_s)
            prg_rcs_s = MIN(DBLE((rr(k)+rs(k))*odts), prg_rcs_s)
            pnr_rcs_s = tnr_racs1(idx_s,idx_t,idx_r1,idx_r)            &   ! RAIN2M
                         + tnr_racs2(idx_s,idx_t,idx_r1,idx_r)          &
                         + tnr_sacr1(idx_s,idx_t,idx_r1,idx_r)          &
                         + tnr_sacr2(idx_s,idx_t,idx_r1,idx_r)
            pnr_rcs_s = MIN(DBLE(nr(k)*odts), pnr_rcs_s)
            png_rcs_s = pnr_rcs_s
!-GT        pbg_rcs_s = prg_rcs_s/(0.5*(rho_i+rho_s))
            pbg_rcs_s = prg_rcs_s/rho_i
           else
            prs_rcs_s = -tcs_racs1(idx_s,idx_t,idx_r1,idx_r)           &
                         - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)          &
                         + tmr_racs2(idx_s,idx_t,idx_r1,idx_r)          &
                         + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r)
            prs_rcs_s = MAX(DBLE(-rs(k)*odts), prs_rcs_s)
            prr_rcs_s = -prs_rcs_s
           endif
          endif

!..Rain collecting graupel.  Cannot assume Wisner (1972) approximation
!.. or Mizuno (1990) approach so we solve the CE explicitly and store
!.. results in lookup table.
          if (rg(k).ge. r_g(1)) then
           if (twet_k.lt.T_0) then
            prg_rcg_s = tmr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  &
                         + tcr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            prg_rcg_s = MIN(DBLE(rr(k)*odts), prg_rcg_s)
            prr_rcg_s = -prg_rcg_s
            pnr_rcg_s = tnr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  &   ! RAIN2M
                         + tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            pnr_rcg_s = MIN(DBLE(nr(k)*odts), pnr_rcg_s)
!-GT        pbg_rcg_s = prg_rcg_s/(0.5*(rho_i+rho_g(idx_bg(k))))
            pbg_rcg_s = prg_rcg_s/rho_i
           else
            prr_rcg_s = tcg_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            prr_rcg_s = MIN(DBLE(rg(k)*odts), prr_rcg_s)
            prg_rcg_s = -prr_rcg_s
            png_rcg_s = tnr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
!!!                    + tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            png_rcg_s = MIN(DBLE(ng(k)*odts), png_rcg_s)
            pbg_rcg_s = prg_rcg_s/rho_g(idx_bg(k))
!..Put in explicit drop break-up due to collisions.
            pnr_rcg_s = -1.5*tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  ! RAIN2M
           endif
          endif
         endif

!+---+-----------------------------------------------------------------+
!..Next IF block handles only those processes below 0C.
!+---+-----------------------------------------------------------------+

         if (temp(k).lt.T_0) then

          vts_boost(k) = 1.0
          rate_max = (qv(k)-qvsi_s)*rho(k)*odts*0.999

!+---+---------------- BEGIN NEW ICE NUCLEATION -----------------------+
!..Freezing of supercooled water (rain or cloud) is influenced by dust
!.. but still using Bigg 1953 with a temperature adjustment of a few
!.. degrees depending on dust concentration.  A default value by way
!.. of idx_IN is 1.0 per Liter of air is used when dustyIce flag is
!.. false.  Next, a combination of deposition/condensation freezing
!.. using DeMott et al (2010) dust nucleation when water saturated or
!.. Phillips et al (2008) when below water saturation; else, without
!.. dustyIce flag, use the previous Cooper (1986) temperature-dependent
!.. value.  Lastly, allow homogeneous freezing of deliquesced aerosols
!.. following Koop et al. (2001, Nature).
!.. Implemented by T. Eidhammer and G. Thompson 2012Dec18
!+---+-----------------------------------------------------------------+

          if (dustyIce .AND. is_aerosol_aware) then
           xni = iceDeMott(tempc,qvs_s,qvs_s,qvsi_s,rho(k),nifa(k))
          else
           xni = 1.0 *1000.                                               ! Default is 1.0 per Liter
          endif

!..Ice nuclei lookup table index.
          if (xni.gt. Nt_IN(1)) then
           niin = NINT(ALOG10(xni))
           do nn = niin-1, niin+1
              n = nn
              if ( (xni/10.**nn).ge.1.0 .and. &
                   (xni/10.**nn).lt.10.0) goto 149
           enddo
 149       continue
           idx_IN = INT(xni/10.**n) + 10*(n-niin2) - (n-niin2)
           idx_IN = MAX(1, MIN(idx_IN, ntb_IN))
          else
           idx_IN = 1
          endif

!..Freezing of water drops into graupel/cloud ice (Bigg 1953).
          if (rr(k).gt. r_r(1)) then
           prg_rfz_s = tpg_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pri_rfz_s = tpi_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pni_rfz_s = tni_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pnr_rfz_s = tnr_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts          ! RAIN2M
           pnr_rfz_s = MIN(DBLE(nr(k)*odts), pnr_rfz_s)
          elseif (rr(k).gt. R1 .and. temp(k).lt.HGFR) then
           pri_rfz_s = rr(k)*odts
           pni_rfz_s = nr(k)*odts                                         ! RAIN2M
          endif
          pbg_rfz_s = prg_rfz_s/rho_i

          if (rc(k).gt. r_c(1)) then
           pri_wfz_s = tpi_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
           pri_wfz_s = MIN(DBLE(rc(k)*odts), pri_wfz_s)
           pni_wfz_s = tni_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
           pni_wfz_s = MIN(DBLE(nc(k)*odts), pri_wfz_s/(2.*xm0i),     &
                                pni_wfz_s)
          elseif (rc(k).gt. R1 .and. temp(k).lt.HGFR) then
           pri_wfz_s = rc(k)*odts
           pni_wfz_s = nc(k)*odts
          endif

!..Deposition nucleation of dust/mineral from DeMott et al (2010)
!.. we may need to relax the temperature and ssati constraints.
          if ( (ssati_s.ge. 0.25) .or. (ssatw_s.gt. eps &
                                .and. temp(k).lt.253.15) ) then
           if (dustyIce .AND. is_aerosol_aware) then
            xnc = iceDeMott(tempc,qv(k),qvs_s,qvsi_s,rho(k),nifa(k))
           else
            xnc = MIN(250.E3, TNO*EXP(ATO*(T_0-temp(k))))
           endif
           xni = ni(k) + (pni_rfz_s+pni_wfz_s)*dtsave
           pni_inu_s = 0.5*(xnc-xni + abs(xnc-xni))*odts
           pri_inu_s = MIN(DBLE(rate_max), xm0i*pni_inu_s)
           pni_inu_s = pri_inu_s/xm0i
          endif

!..Freezing of aqueous aerosols based on Koop et al (2001, Nature)
          xni = ns(k)+ni(k) + (pni_rfz_s+pni_wfz_s+pni_inu_s)*dtsave
          if (is_aerosol_aware .AND. homogIce .AND. (xni.le.999.E3)     &
     &                .AND.(temp(k).lt.238).AND.(ssati_s.ge.0.4) ) then
            xnc = iceKoop(temp(k),qv(k),qvs_s,nwfa(k), dtsave)
            pni_iha_s = xnc*odts
            pri_iha_s = MIN(DBLE(rate_max), xm0i*0.1*pni_iha_s)
            pni_iha_s = pri_iha_s/(xm0i*0.1)
          endif
!+---+------------------ END NEW ICE NUCLEATION -----------------------+


!..Deposition/sublimation of cloud ice (Srivastava & Coen 1992).
          if (L_qi(k)) then
           lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
           ilami = 1./lami
           xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
           xmi = am_i*xDi**bm_i
           oxmi = 1./xmi
           pri_ide_s = C_cube*t1_subl*diffu_s*ssati_s*rvs &
                  *oig1*cig(5)*ni(k)*ilami

           if (pri_ide_s .lt. 0.0) then
            pri_ide_s = MAX(DBLE(-ri(k)*odts), pri_ide_s, DBLE(rate_max))
            pni_ide_s = pri_ide_s*oxmi
            pni_ide_s = MAX(DBLE(-ni(k)*odts), pni_ide_s)
           else
            pri_ide_s = MIN(pri_ide_s, DBLE(rate_max))
            prs_ide_s = (1.0D0-tpi_ide(idx_i,idx_i1))*pri_ide_s
            pri_ide_s = tpi_ide(idx_i,idx_i1)*pri_ide_s
           endif

!..Some cloud ice needs to move into the snow category.  Use lookup
!.. table that resulted from explicit bin representation of distrib.
           if ( (idx_i.eq. ntb_i) .or. (xDi.gt. 5.0*D0s) ) then
            prs_iau(k) = ri(k)*.99*odts
            pni_iau_s = ni(k)*.95*odts
           elseif (xDi.lt. 0.1*D0s) then
            prs_iau(k) = 0.
            pni_iau_s = 0.
           else
            prs_iau(k) = tps_iaus(idx_i,idx_i1)*odts
            prs_iau(k) = MIN(DBLE(ri(k)*.99*odts), prs_iau(k))
            pni_iau_s = tni_iaus(idx_i,idx_i1)*odts
            pni_iau_s = MIN(DBLE(ni(k)*.95*odts), pni_iau_s)
           endif
          endif

!..Deposition/sublimation of snow/graupel follows Srivastava & Coen
!.. (1992).
          if (L_qs(k)) then
           C_snow = C_sqrd + (tempc+1.5)*(C_cube-C_sqrd)/(-30.+1.5)
           C_snow = MAX(C_sqrd, MIN(C_snow, C_cube))
           prs_sde(k) = C_snow*t1_subl*diffu_s*ssati_s*rvs &
                        * (t1_qs_sd*smo1(k) &
                         + t2_qs_sd*rhof2_s*vsc2_s*smof(k))
           if (prs_sde(k).lt. 0.) then
            prs_sde(k) = MAX(DBLE(-rs(k)*odts), prs_sde(k), DBLE(rate_max))
           else
            prs_sde(k) = MIN(prs_sde(k), DBLE(rate_max))
           endif
          endif

          if (L_qg(k) .and. ssati_s.lt. -eps) then
           t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
           prg_gde(k) = C_cube*t1_subl*diffu_s*ssati_s*rvs &
               * N0_g(k) * (t1_qg_sd*ilamg(k)**cge(10,1) &
               + t2_qg_sd*vsc2_s*rhof2_s*ilamg(k)**cge(11,idx_bg(k)))
           if (prg_gde(k).lt. 0.) then
            prg_gde(k) = MAX(DBLE(-rg(k)*odts), prg_gde(k), DBLE(rate_max))
            png_gde_s = prg_gde(k) * ng(k)/rg(k)
           else
            prg_gde(k) = MIN(prg_gde(k), DBLE(rate_max))
           endif
          endif

!..Snow collecting cloud ice.  In CE, assume Di<<Ds and vti=~0.
          if (L_qi(k)) then
           lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
           ilami = 1./lami
           xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
           xmi = am_i*xDi**bm_i
           oxmi = 1./xmi
           if (rs(k).ge. r_s(1)) then
            prs_sci(k) = t1_qs_qi*rhof_s*Ef_si*ri(k)*smoe(k)
            pni_sci_s = prs_sci(k) * oxmi
           endif

!..Rain collecting cloud ice.  In CE, assume Di<<Dr and vti=~0.
           if (rr(k).ge. r_r(1) .and. mvd_r(k).gt. 4.*xDi) then
            lamr = 1./ilamr(k)
            pri_rci(k) = rhof_s*t1_qr_qi*Ef_ri*ri(k)*N0_r(k) &
                           *((lamr+fv_r)**(-cre(9)))
            pnr_rci_s = rhof_s*t1_qr_qi*Ef_ri*ni(k)*N0_r(k)           &   ! RAIN2M
                           *((lamr+fv_r)**(-cre(9)))
            pnr_rci_s = MIN(DBLE(nr(k)*odts), pnr_rci_s)
            pni_rci_s = pri_rci(k) * oxmi
            prr_rci_s = rhof_s*t2_qr_qi*Ef_ri*ni(k)*N0_r(k) &
                           *((lamr+fv_r)**(-cre(8)))
            prr_rci_s = MIN(DBLE(rr(k)*odts), prr_rci_s)
            prg_rci_s = pri_rci(k) + prr_rci_s
            pbg_rci_s = prg_rci_s/rho_i
           endif
          endif

!..Ice multiplication from rime-splinters (Hallet & Mossop 1974).
          if (prg_gcw(k).gt. eps .and. tempc.gt.-8.0) then
           tf = 0.
           if (tempc.ge.-5.0 .and. tempc.lt.-3.0) then
            tf = 0.5*(-3.0 - tempc)
           elseif (tempc.gt.-8.0 .and. tempc.lt.-5.0) then
            tf = 0.33333333*(8.0 + tempc)
           endif
           pni_ihm_s = 3.5E8*tf*prg_gcw(k)
           pri_ihm_s = xm0i*pni_ihm_s
           prs_ihm_s = prs_scw(k)/(prs_scw(k)+prg_gcw(k)) &
                          * pri_ihm_s
           prg_ihm_s = prg_gcw(k)/(prs_scw(k)+prg_gcw(k)) &
                          * pri_ihm_s
          endif

!..A portion of rimed snow converts to graupel but some remains snow.
!.. Interp from 15 to 95% as riming factor increases from 2.0 to 30.0
!.. 0.028 came from (.95-.15)/(30.-2.).  This remains ad-hoc and should
!.. be revisited.
          if (prs_scw(k).gt.2.0*prs_sde(k) .and. &
                         prs_sde(k).gt.eps) then
           r_frac = MIN(30.0D0, prs_scw(k)/prs_sde(k))
           g_frac = MIN(0.95, 0.15 + (r_frac-2.)*.028)
           vts_boost(k) = MIN(1.5, 1.1 + (r_frac-2.)*.014)
           prg_scw(k) = g_frac*prs_scw(k)
           png_scw_s = prg_scw(k)*smo0(k)/rs(k)
!..GT      png_scw_s = prg_scw(k)*ns(k)/rs(k)
           vts = av_s*xDs**bv_s * EXP(-fv_s*xDs)
           const_Ri = -1.*(mvd_c(k)*0.5E6)*vts/MIN(-0.1,tempc)
           const_Ri = MAX(0.1, MIN(const_Ri, 10.))
           rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
           if(rime_dens .lt. 150.) then                                  ! Idea of A. Jensen
              g_frac = 0.
              prg_scw(k)=0.
              png_scw_s=0.
           endif
           pbg_scw_s = prg_scw(k)/(0.5*(rime_dens+rho_s))
           prs_scw(k) = (1. - g_frac)*prs_scw(k)
          endif

         else

!..Melt snow and graupel and enhance from collisions with liquid.
!.. We also need to sublimate snow and graupel if subsaturated.
          if (L_qs(k)) then
           prr_sml(k) = (tempc*tcond_s-lvap0*diffu_s*delQvs_s)       &
                      * (t1_qs_me*smo1(k) + t2_qs_me*rhof2_s*vsc2_s*smof(k))
           if (prr_sml(k) .gt. 0.) then
              prr_sml(k) = prr_sml(k) + 4218.*olfus*(twet_k-T_0)       &
                                      * (prr_rcs_s+prs_scw(k))
           endif
           prr_sml(k) = MIN(DBLE(rs(k)*odts), MAX(0.D0, prr_sml(k)))

           if (prr_sml(k).gt.0.0) then
              pnr_sml_s = smo0(k)/rs(k)*prr_sml(k) * 10.0**(-0.25*(twet_k-T_0))
           elseif (ssati_s.lt. 0.) then
              prs_sde(k) = C_sqrd*t1_subl*diffu_s*ssati_s*rvs &
                         * (t1_qs_sd*smo1(k) &
                          + t2_qs_sd*rhof2_s*vsc2_s*smof(k))
            prs_sde(k) = MAX(DBLE(-rs(k)*odts), prs_sde(k))
           endif
          endif

          if (L_qg(k)) then
           N0_melt = N0_g(k)
           if ((rg(k)*ng(k)) .lt. 1.E-4) then
              lamg = 1./ilamg(k)
              N0_melt = (1.E-4/rg(k))*ogg2*lamg**cge(2,1)
           endif
           t2_qg_me = PI*4.*C_cube*olfus * 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
           prr_gml(k) = (tempc*tcond_s-lvap0*diffu_s*delQvs_s)       &
                      * N0_melt*(t1_qg_me*ilamg(k)**cge(10,1)           &
                      + t2_qg_me*rhof2_s*vsc2_s*ilamg(k)**cge(11,idx_bg(k)))
!          if (prr_gml(k) .gt. 0.) then
!             prr_gml(k) = prr_gml(k) + 4218.*olfus*(twet_k-T_0)       &
!                                     * (prr_rcg_s+prg_gcw(k))
!          endif
           prr_gml(k) = MIN(DBLE(rg(k)*odts), MAX(0.D0, prr_gml(k)))
!           pnr_gml_s = N0_g(k)*cgg(2)*ilamg(k)**cge(2) / rg(k)         &   ! RAIN2M
!                      * prr_gml(k) * 10.0**(-0.5*tempc)

           if (prr_gml(k) .gt. 0.0) then
            melt_f = MAX(0.05, MIN(prr_gml(k)*dt/rg(k),1.0))
            !..1000 is density water, 50 is lower limit (max ice density is 800)
            pbg_gml_s = prr_gml(k) / MAX(MIN(melt_f*rho_g(idx_bg(k)),1000.),50.)
!-GT        pnr_gml_s = prr_gml(k)*ng(k)/rg(k)
            pnr_gml_s = prr_gml(k)*ng(k)/rg(k) * 10.0**(-0.33*(twet_k-T_0))
           elseif (ssati_s.lt. 0.) then
            t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
            prg_gde(k) = C_cube*t1_subl*diffu_s*ssati_s*rvs &
                * N0_g(k) * (t1_qg_sd*ilamg(k)**cge(10,1) &
                + t2_qg_sd*vsc2_s*rhof2_s*ilamg(k)**cge(11,idx_bg(k)))
            prg_gde(k) = MAX(DBLE(-rg(k)*odts), prg_gde(k))
            png_gde_s = prg_gde(k) * ng(k)/rg(k)
           endif
          endif

!.. This change will be required if users run adaptive time step that
!.. results in delta-t that is generally too long to allow cloud water
!.. collection by snow/graupel above melting temperature.
!.. Credit to Bjorn-Egil Nygaard for discovering.
          if (dt .gt. 120.) then
             prr_rcw(k)=prr_rcw(k)+prs_scw(k)+prg_gcw(k)
             prs_scw(k)=0.
             prg_gcw(k)=0.
          endif

         endif

         if (.not. is_hail_aware) idx_bg(k) = idx_bg1

      endif

!..If ice supersaturated, ensure sum of depos growth terms does not
!.. deplete more vapor than possibly exists.  If subsaturated, limit
!.. sum of sublimation terms such that vapor does not reproduce ice
!.. supersat again.
         sump = pri_inu_s + pri_ide_s + prs_ide_s &
              + prs_sde(k) + prg_gde(k) + pri_iha_s
         rate_max = (qv(k)-qvsi_s)*rho(k)*odts*0.999
         if ( (sump.gt. eps .and. sump.gt. rate_max) .or. &
              (sump.lt. -eps .and. sump.lt. rate_max) ) then
          ratio = rate_max/sump
          pri_inu_s = pri_inu_s * ratio
          pri_ide_s = pri_ide_s * ratio
          pni_ide_s = pni_ide_s * ratio
          prs_ide_s = prs_ide_s * ratio
          prs_sde(k) = prs_sde(k) * ratio
          prg_gde(k) = prg_gde(k) * ratio
          pri_iha_s = pri_iha_s * ratio
         endif

!..Cloud water conservation.
         sump = -prr_wau(k) - pri_wfz_s - prr_rcw(k) &
                - prs_scw(k) - prg_scw(k) - prg_gcw(k)
         rate_max = -rc(k)*odts
         if (sump.lt. rate_max .and. L_qc(k)) then
          ratio = rate_max/sump
          prr_wau(k) = prr_wau(k) * ratio
          pri_wfz_s = pri_wfz_s * ratio
          prr_rcw(k) = prr_rcw(k) * ratio
          prs_scw(k) = prs_scw(k) * ratio
          prg_scw(k) = prg_scw(k) * ratio
          prg_gcw(k) = prg_gcw(k) * ratio
         endif

!..Cloud ice conservation.
         sump = pri_ide_s - prs_iau(k) - prs_sci(k) &
                - pri_rci(k)
         rate_max = -ri(k)*odts
         if (sump.lt. rate_max .and. L_qi(k)) then
          ratio = rate_max/sump
          pri_ide_s = pri_ide_s * ratio
          prs_iau(k) = prs_iau(k) * ratio
          prs_sci(k) = prs_sci(k) * ratio
          pri_rci(k) = pri_rci(k) * ratio
         endif

!..Rain conservation.
         sump = -prg_rfz_s - pri_rfz_s - prr_rci_s &
                + prr_rcs_s + prr_rcg_s
         rate_max = -rr(k)*odts
         if (sump.lt. rate_max .and. L_qr(k)) then
          ratio = rate_max/sump
          prg_rfz_s = prg_rfz_s * ratio
          pri_rfz_s = pri_rfz_s * ratio
          prr_rci_s = prr_rci_s * ratio
          prr_rcs_s = prr_rcs_s * ratio
          prr_rcg_s = prr_rcg_s * ratio
         endif

!..Snow conservation.
         sump = prs_sde(k) - prs_ihm_s - prr_sml(k) &
                + prs_rcs_s
         rate_max = -rs(k)*odts
         if (sump.lt. rate_max .and. L_qs(k)) then
          ratio = rate_max/sump
          prs_sde(k) = prs_sde(k) * ratio
          prs_ihm_s = prs_ihm_s * ratio
          prr_sml(k) = prr_sml(k) * ratio
          prs_rcs_s = prs_rcs_s * ratio
         endif

!..Graupel conservation.
         sump = prg_gde(k) - prg_ihm_s - prr_gml(k) &
              + prg_rcg_s
         rate_max = -rg(k)*odts
         if (sump.lt. rate_max .and. L_qg(k)) then
          ratio = rate_max/sump
          prg_gde(k) = prg_gde(k) * ratio
          prg_ihm_s = prg_ihm_s * ratio
          prr_gml(k) = prr_gml(k) * ratio
          prg_rcg_s = prg_rcg_s * ratio
         endif

!..Re-enforce proper mass conservation for subsequent elements in case
!.. any of the above terms were altered.  Thanks P. Blossey. 2009Sep28
         pri_ihm_s = prs_ihm_s + prg_ihm_s
         ratio = MIN( ABS(prr_rcg_s), ABS(prg_rcg_s) )
         prr_rcg_s = ratio * SIGN(1.0, SNGL(prr_rcg_s))
         prg_rcg_s = -prr_rcg_s
         if (twet_k.gt.T_0) then
            ratio = MIN( ABS(prr_rcs_s), ABS(prs_rcs_s) )
            prr_rcs_s = ratio * SIGN(1.0, SNGL(prr_rcs_s))
            prs_rcs_s = -prr_rcs_s
         endif

         orho = 1./rho(k)
         lfus2 = lsub - lvap_s

!..Aerosol number tendency
         if (is_aerosol_aware) then
            nwfaten(k) = nwfaten(k) - (pna_rca_s + pna_sca_s          &
                       + pna_gca_s + pni_iha_s) * orho
            nifaten(k) = nifaten(k) - (pnd_rcd_s + pnd_scd_s          &
                       + pnd_gcd_s) * orho
            if (wif_input_opt .eq. 2) then
               nbcaten(k) = nbcaten(k) - (pnb_rcb_s + pnb_scb_s       &
                          + pnb_gcb_s) * orho
            else
               nbcaten(k) = 0.0
            endif
            if (dustyIce) then
               nifaten(k) = nifaten(k) - pni_inu_s*orho
            else
               nifaten(k) = 0.
            endif
         endif

!..Water vapor tendency
         qvten(k) = qvten(k) + (-pri_inu_s - pri_iha_s - pri_ide_s   &
                      - prs_ide_s - prs_sde(k) - prg_gde(k)) &
                      * orho

!..Cloud water tendency
         qcten(k) = qcten(k) + (-prr_wau(k) - pri_wfz_s &
                      - prr_rcw(k) - prs_scw(k) - prg_scw(k) &
                      - prg_gcw(k)) &
                      * orho

!..Cloud water number tendency
         ncten(k) = ncten(k) + (-pnc_wau_s - pnc_rcw_s &
                      - pni_wfz_s - pnc_scw_s - pnc_gcw_s) &
                      * orho

!..Cloud water mass/number balance; keep mass-wt mean size between
!.. 1 and 50 microns.  Also no more than Nt_c_max drops total.
         xrc=MAX(R1, (qc1d(k) + qcten(k)*dtsave)*rho(k))
         xnc=MAX(2., (nc1d(k) + ncten(k)*dtsave)*rho(k))
         if (xrc .gt. R1) then
          nu_c = MIN(15, NINT(1000.E6/xnc) + 2)
          lamc = (xnc*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc(k))**obmr
          xDc = (bm_r + nu_c + 1.) / lamc
          if (xDc.lt. D0c) then
           lamc = cce(2,nu_c)/D0c
           xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
           ncten(k) = (xnc-nc1d(k)*rho(k))*odts*orho
          elseif (xDc.gt. D0r*2.) then
           lamc = cce(2,nu_c)/(D0r*2.)
           xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
           ncten(k) = (xnc-nc1d(k)*rho(k))*odts*orho
          endif
         else
          ncten(k) = -nc1d(k)*odts
         endif
         xnc=MAX(0.,(nc1d(k) + ncten(k)*dtsave)*rho(k))
         if (xnc.gt.Nt_c_max) &
                ncten(k) = (Nt_c_max-nc1d(k)*rho(k))*odts*orho

!..Cloud ice mixing ratio tendency
         qiten(k) = qiten(k) + (pri_inu_s + pri_iha_s + pri_ihm_s    &
                      + pri_wfz_s + pri_rfz_s + pri_ide_s &
                      - prs_iau(k) - prs_sci(k) - pri_rci(k)) &
                      * orho

!..Cloud ice number tendency.
         niten(k) = niten(k) + (pni_inu_s + pni_iha_s + pni_ihm_s    &
                      + pni_wfz_s + pni_rfz_s + pni_ide_s &
                      - pni_iau_s - pni_sci_s - pni_rci_s) &
                      * orho

!..Cloud ice mass/number balance; keep mass-wt mean size between
!.. 5 and 300 microns.  Also no more than 500 xtals per liter.
         xri=MAX(R1,(qi1d(k) + qiten(k)*dtsave)*rho(k))
         xni=MAX(R2,(ni1d(k) + niten(k)*dtsave)*rho(k))
         if (xri.gt. R1) then
           lami = (am_i*cig(2)*oig1*xni/xri)**obmi
           ilami = 1./lami
           xDi = (bm_i + mu_i + 1.) * ilami
           if (xDi.lt. 5.E-6) then
            lami = cie(2)/5.E-6
            xni = MIN(999.D3, cig(1)*oig2*xri/am_i*lami**bm_i)
            niten(k) = (xni-ni1d(k)*rho(k))*odts*orho
           elseif (xDi.gt. 300.E-6) then
            lami = cie(2)/300.E-6
            xni = cig(1)*oig2*xri/am_i*lami**bm_i
            niten(k) = (xni-ni1d(k)*rho(k))*odts*orho
           endif
         else
          niten(k) = -ni1d(k)*odts
         endif
         xni=MAX(0.,(ni1d(k) + niten(k)*dtsave)*rho(k))
         if (xni.gt.999.E3) &
                niten(k) = (999.E3-ni1d(k)*rho(k))*odts*orho

!..Rain tendency
         qrten(k) = qrten(k) + (prr_wau(k) + prr_rcw(k) &
                      + prr_sml(k) + prr_gml(k) + prr_rcs_s &
                      + prr_rcg_s - prg_rfz_s &
                      - pri_rfz_s - prr_rci_s) &
                      * orho

!..Rain number tendency
         nrten(k) = nrten(k) + (pnr_wau_s + pnr_sml_s + pnr_gml_s    &
                      - (pnr_rfz_s + pnr_rcr_s + pnr_rcg_s           &
                      + pnr_rcs_s + pnr_rci_s + pni_rfz_s) )         &
                      * orho

!..Rain mass/number balance; keep median volume diameter between
!.. 37 microns (D0r*0.75) and 2.5 mm.
         xrr=MAX(R1,(qr1d(k) + qrten(k)*dtsave)*rho(k))
         xnr=MAX(R2,(nr1d(k) + nrten(k)*dtsave)*rho(k))
         if (xrr.gt. R1) then
           lamr = (am_r*crg(3)*org2*xnr/xrr)**obmr
           mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
           if (mvd_r(k) .gt. 2.5E-3) then
              mvd_r(k) = 2.5E-3
              lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
              xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
              nrten(k) = (xnr-nr1d(k)*rho(k))*odts*orho
           elseif (mvd_r(k) .lt. D0r*0.75) then
              mvd_r(k) = D0r*0.75
              lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
              xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
              nrten(k) = (xnr-nr1d(k)*rho(k))*odts*orho
           endif
         else
           qrten(k) = -qr1d(k)*odts
           nrten(k) = -nr1d(k)*odts
         endif

!..Snow tendency
         qsten(k) = qsten(k) + (prs_iau(k) + prs_sde(k) + prs_sci(k)    &
                      + prs_scw(k) + prs_rcs_s + prs_ide_s            &
                      - prs_ihm_s - prr_sml(k))                        &
                      * orho

!..Graupel tendency
         qgten(k) = qgten(k) + (prg_scw(k) + prg_rfz_s &
                      + prg_gde(k) + prg_rcg_s + prg_gcw(k) &
                      + prg_rci_s + prg_rcs_s - prg_ihm_s &
                      - prr_gml(k))                          &
                      * orho

!..Graupel number tendency
         ngten(k) = ngten(k) + (png_scw_s + pnr_rfz_s - png_rcg_s    &
                      + pnr_rci_s + png_rcs_s + png_gde_s            &
                      - pnr_gml_s) * orho

!..Graupel volume mixing ratio tendency
         qbten(k) = qbten(k) + (pbg_scw_s + pbg_rfz_s                 &
                      + pbg_gcw_s + pbg_rci_s + pbg_rcs_s            &
                      + pbg_rcg_s + pbg_sml_s - pbg_gml_s            &
                      + (prg_gde(k) - prg_ihm_s) /rho_g(idx_bg(k)) )   &
                      * orho

!..Graupel mass/number balance; keep its median volume diameter between
!.. 3.0 times minimum size (D0g) and 25 mm.
         xrg=MAX(R1,(qg1d(k) + qgten(k)*dtsave)*rho(k))
         xng=MAX(R2,(ng1d(k) + ngten(k)*dtsave)*rho(k))
         xrb=MAX(xrg/rho(k)/rho_g(NRHG),(qb1d(k) + qbten(k)*dtsave))
         xrb=MIN(xrg/rho(k)/rho_g(1), xrb)

         if (xrg .gt. R1) then
            lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*xng/xrg)**obmg
            mvd_g(k) = (3.0 + mu_g + 0.672) / lamg

      if(debug_flag) then
           xrho_g = MAX(rho_g(1),MIN(rg(k)/rho(k)/rb(k),rho_g(NRHG)))
           afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*rho(k)))**b_coeff
           afall = afall * visco_s**(1.0-2.0*b_coeff)
           vtg1 = rhof_s*afall*cgg(6,idx_bg(k))*ogg3 / lamg**bfall
           vtg2 = rhof_s*afall*cgg(7,idx_bg(k))/cgg(12,idx_bg(k)) / lamg**bfall
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: xrg, xng, xrb, ns, idx_bg, rho_g, mvd, vtg: ', k, xrg, xng, xrb, ns(k), idx_bg(k), xrg/rho(k)/xrb, mvd_g(k)*1000., vtg1, vtg2
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: qgten: ', qgten(k), prg_scw(k), prg_rfz_s, prg_gde(k), prg_rcg_s, prg_gcw(k), prg_rci_s, prg_rcs_s, prg_ihm_s, prr_gml(k)
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: ngten: ', ngten(k), png_scw_s, pnr_rfz_s, png_rcg_s, pnr_rci_s, png_rcs_s, pnr_gml_s
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: qbten: ', qbten(k), pbg_scw_s, pbg_rfz_s, pbg_gcw_s, pbg_rci_s, pbg_rcs_s, pbg_rcg_s, pbg_sml_s, pbg_gml_s
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
      endif

            if (mvd_g(k) .gt. 25.4E-3) then
               mvd_g(k) = 25.4E-3
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg(k))
               ngten(k) = (xng-ng1d(k)*rho(k))*odts*orho
            elseif (mvd_g(k) .lt. D0r) then
               mvd_g(k) = D0r
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg(k))
               ngten(k) = (xng-ng1d(k)*rho(k))*odts*orho
            endif

         else
           qgten(k) = -qg1d(k)*odts
           ngten(k) = -ng1d(k)*odts
           qbten(k) = -qb1d(k)*odts
         endif

!..Temperature tendency
         if (temp(k).lt.T_0) then
          tten(k) = tten(k) &
                    + ( lsub*ocp_s*(pri_inu_s + pri_ide_s &
                                     + prs_ide_s + prs_sde(k) &
                                     + prg_gde(k) + pri_iha_s) &
                     + lfus2*ocp_s*(pri_wfz_s + pri_rfz_s &
                                     + prg_rfz_s + prs_scw(k) &
                                     + prg_scw(k) + prg_gcw(k) &
                                     + prg_rcs_s + prs_rcs_s &
                                     + prr_rci_s + prg_rcg_s) &
                       )*orho * (1-IFDRY)
         else
          tten(k) = tten(k) &
                    + ( lfus*ocp_s*(-prr_sml(k) - prr_gml(k) &
                                     - prr_rcg_s - prr_rcs_s) &
                      + lsub*ocp_s*(prs_sde(k) + prg_gde(k)) &
                       )*orho * (1-IFDRY)
         endif

      enddo
      if (th_probe == 2) return
#else
      do k = kts, kte

!..Rain self-collection follows Seifert, 1994 and drop break-up
!.. follows Verlinde and Cotton, 1993.                                        RAIN2M
         if (L_qr(k) .and. mvd_r(k).gt. D0r) then
!-GT      Ef_rr = 1.0
!-GT      if (mvd_r(k) .gt. 1500.0E-6) then
             Ef_rr = 1.0 - EXP(2300.0*(mvd_r(k)-1950.0E-6))
!-GT      endif
          pnr_rcr(k) = Ef_rr * 2.0*nr(k)*rr(k)
         endif

         mvd_c(k) = D0c
         if (L_qc(k)) then
          nu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
          xDc = MAX(D0c*1.E6, ((rc(k)/(am_r*nc(k)))**obmr) * 1.E6)
          lamc = (nc(k)*am_r* ccg(2,nu_c) * ocg1(nu_c) / rc(k))**obmr
          mvd_c(k) = (3.0+nu_c+0.672) / lamc
          mvd_c(k) = MAX(D0c, MIN(mvd_c(k), D0r))
         endif

!..Autoconversion follows Berry & Reinhardt (1974) with characteristic
!.. diameters correctly computed from gamma distrib of cloud droplets.
         if (rc(k).gt. 0.01e-3) then
          Dc_g = ((ccg(3,nu_c)*ocg2(nu_c))**obmr / lamc) * 1.E6
          Dc_b = (xDc*xDc*xDc*Dc_g*Dc_g*Dc_g - xDc*xDc*xDc*xDc*xDc*xDc) &
                 **(1./6.)
          zeta1 = 0.5*((6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4) &
                     + abs(6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4))
          zeta = 0.027*rc(k)*zeta1
          taud = 0.5*((0.5*Dc_b - 7.5) + abs(0.5*Dc_b - 7.5)) + R1
          tau  = 3.72/(rc(k)*taud)
          prr_wau(k) = zeta/tau
          prr_wau(k) = MIN(DBLE(rc(k)*odts), prr_wau(k))
          pnr_wau(k) = prr_wau(k) / (am_r*nu_c*10.*D0r*D0r*D0r)             ! RAIN2M
          pnc_wau(k) = MIN(DBLE(nc(k)*odts), prr_wau(k)                 &
                     / (am_r*mvd_c(k)*mvd_c(k)*mvd_c(k)))                   ! Qc2M
         endif

!..Rain collecting cloud water.  In CE, assume Dc<<Dr and vtc=~0.
         if (L_qr(k) .and. mvd_r(k).gt. D0r .and. mvd_c(k).gt. D0c) then
          lamr = 1./ilamr(k)
          idx = 1 + INT(nbr*DLOG(mvd_r(k)/Dr(1))/DLOG(Dr(nbr)/Dr(1)))
          idx = MIN(idx, nbr)
          Ef_rw = t_Efrw(idx, INT(mvd_c(k)*1.E6))
          prr_rcw(k) = rhof(k)*t1_qr_qc*Ef_rw*rc(k)*N0_r(k) &
                         *((lamr+fv_r)**(-cre(9)))
          prr_rcw(k) = MIN(DBLE(rc(k)*odts), prr_rcw(k))
          pnc_rcw(k) = rhof(k)*t1_qr_qc*Ef_rw*nc(k)*N0_r(k)             &
                         *((lamr+fv_r)**(-cre(9)))                          ! Qc2M
          pnc_rcw(k) = MIN(DBLE(nc(k)*odts), pnc_rcw(k))
         endif

!..Rain collecting aerosols, wet scavenging.
         if (L_qr(k) .and. mvd_r(k).gt. D0r) then
          Ef_ra = Eff_aero(mvd_r(k),0.04E-6,visco(k),rho(k),temp(k),'r')
          lamr = 1./ilamr(k)
          pna_rca(k) = rhof(k)*t1_qr_qc*Ef_ra*nwfa(k)*N0_r(k)           &
                         *((lamr+fv_r)**(-cre(9)))
          pna_rca(k) = MIN(DBLE(nwfa(k)*odts), pna_rca(k))

          Ef_ra = Eff_aero(mvd_r(k),0.8E-6,visco(k),rho(k),temp(k),'r')
          pnd_rcd(k) = rhof(k)*t1_qr_qc*Ef_ra*nifa(k)*N0_r(k)           &
                         *((lamr+fv_r)**(-cre(9)))
          pnd_rcd(k) = MIN(DBLE(nifa(k)*odts), pnd_rcd(k))

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_ra = Eff_aero(mvd_r(k),0.0236E-6, &
                                 visco(k),rho(k),temp(k),'r')
              pnb_rcb(k) = rhof(k)*t1_qr_qc*Ef_ra*nbca(k)*N0_r(k)       &
                             *((lamr+fv_r)**(-cre(9)))
              pnb_rcb(k) = MIN(DBLE(nbca(k)*odts), pnb_rcb(k))
            endif
          endif
         endif

      enddo

!+---+-----------------------------------------------------------------+
!..Compute all frozen hydrometeor species' process terms.
!+---+-----------------------------------------------------------------+
      if (.not. iiwarm) then
      !..vts_boost is the factor applied to snow terminal
      !..fallspeed due to riming of snow
      do k = kts, kte
         vts_boost(k) = 1.0
         orho = 1./rho(k)

         if (L_qs(k)) then
            xDs = smoc(k) / smob(k)
            rho_s = MAX(rho_g(1), MIN(0.13/xDs, rho_i-100.))
         else
            xDs = 0.
            rho_s = 100.
         endif

!..Temperature lookup table indexes.
         tempc = temp(k) - 273.15
         idx_tc = MAX(1, MIN(NINT(-tempc), 45) )
         idx_t = INT( (tempc-2.5)/5. ) - 1
         idx_t = MAX(1, -idx_t)
         idx_t = MIN(idx_t, ntb_t)
         IT = MAX(1, MIN(NINT(-tempc), 31) )

!..Cloud water lookup table index.
         if (rc(k).gt. r_c(1)) then
          nic = NINT(ALOG10(rc(k)))
          do nn = nic-1, nic+1
             n = nn
             if ( (rc(k)/10.**nn).ge.1.0 .and. &
                  (rc(k)/10.**nn).lt.10.0) goto 141
          enddo
 141      continue
          idx_c = INT(rc(k)/10.**n) + 10*(n-nic2) - (n-nic2)
          idx_c = MAX(1, MIN(idx_c, ntb_c))
         else
          idx_c = 1
         endif

!..Cloud droplet number lookup table index.
         idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(nc(k)/t_Nc(1)) / nic1)
         idx_n = MAX(1, MIN(idx_n, nbc))

!..Cloud ice lookup table indexes.
         if (ri(k).gt. r_i(1)) then
          nii = NINT(ALOG10(ri(k)))
          do nn = nii-1, nii+1
             n = nn
             if ( (ri(k)/10.**nn).ge.1.0 .and. &
                  (ri(k)/10.**nn).lt.10.0) goto 142
          enddo
 142      continue
          idx_i = INT(ri(k)/10.**n) + 10*(n-nii2) - (n-nii2)
          idx_i = MAX(1, MIN(idx_i, ntb_i))
         else
          idx_i = 1
         endif

         if (ni(k).gt. Nt_i(1)) then
          nii = NINT(ALOG10(ni(k)))
          do nn = nii-1, nii+1
             n = nn
             if ( (ni(k)/10.**nn).ge.1.0 .and. &
                  (ni(k)/10.**nn).lt.10.0) goto 143
          enddo
 143      continue
          idx_i1 = INT(ni(k)/10.**n) + 10*(n-nii3) - (n-nii3)
          idx_i1 = MAX(1, MIN(idx_i1, ntb_i1))
         else
          idx_i1 = 1
         endif

!..Rain lookup table indexes.
         if (rr(k).gt. r_r(1)) then
          nir = NINT(ALOG10(rr(k)))
          do nn = nir-1, nir+1
             n = nn
             if ( (rr(k)/10.**nn).ge.1.0 .and. &
                  (rr(k)/10.**nn).lt.10.0) goto 144
          enddo
 144      continue
          idx_r = INT(rr(k)/10.**n) + 10*(n-nir2) - (n-nir2)
          idx_r = MAX(1, MIN(idx_r, ntb_r))

          lamr = 1./ilamr(k)
          lam_exp = lamr * (crg(3)*org2*org1)**bm_r
          N0_exp = org1*rr(k)/am_r * lam_exp**cre(1)
          nir = NINT(DLOG10(N0_exp))
          do nn = nir-1, nir+1
             n = nn
             if ( (N0_exp/10.**nn).ge.1.0 .and. &
                  (N0_exp/10.**nn).lt.10.0) goto 145
          enddo
 145      continue
          idx_r1 = INT(N0_exp/10.**n) + 10*(n-nir3) - (n-nir3)
          idx_r1 = MAX(1, MIN(idx_r1, ntb_r1))
         else
          idx_r = 1
          idx_r1 = ntb_r1
         endif

!..Snow lookup table index.
         if (rs(k).gt. r_s(1)) then
          nis = NINT(ALOG10(rs(k)))
          do nn = nis-1, nis+1
             n = nn
             if ( (rs(k)/10.**nn).ge.1.0 .and. &
                  (rs(k)/10.**nn).lt.10.0) goto 146
          enddo
 146      continue
          idx_s = INT(rs(k)/10.**n) + 10*(n-nis2) - (n-nis2)
          idx_s = MAX(1, MIN(idx_s, ntb_s))
         else
          idx_s = 1
         endif

!..Graupel lookup table index.
         if (rg(k).gt. r_g(1)) then
          nig = NINT(ALOG10(rg(k)))
          do nn = nig-1, nig+1
             n = nn
             if ( (rg(k)/10.**nn).ge.1.0 .and. &
                  (rg(k)/10.**nn).lt.10.0) goto 147
          enddo
 147      continue
          idx_g = INT(rg(k)/10.**n) + 10*(n-nig2) - (n-nig2)
          idx_g = MAX(1, MIN(idx_g, ntb_g))

          lamg = 1./ilamg(k)
          lam_exp = lamg * (cgg(3,1)*ogg2*ogg1)**bm_g
          N0_exp = ogg1*rg(k)/am_g(idx_bg(k)) * lam_exp**cge(1,1)
          nig = NINT(DLOG10(N0_exp))
          do nn = nig-1, nig+1
             n = nn
             if ( (N0_exp/10.**nn).ge.1.0 .and. &
                  (N0_exp/10.**nn).lt.10.0) goto 148
          enddo
 148      continue
          idx_g1 = INT(N0_exp/10.**n) + 10*(n-nig3) - (n-nig3)
          idx_g1 = MAX(1, MIN(idx_g1, ntb_g1))
         else
          idx_g = 1
          idx_g1 = ntb_g1
         endif

!..Deposition/sublimation prefactor (from Srivastava & Coen 1992).
         otemp = 1./temp(k)
         rvs = rho(k)*qvsi(k)
         rvs_p = rvs*otemp*(lsub*otemp*oRv - 1.)
         rvs_pp = rvs * ( otemp*(lsub*otemp*oRv - 1.) &
                         *otemp*(lsub*otemp*oRv - 1.) &
                         + (-2.*lsub*otemp*otemp*otemp*oRv) &
                         + otemp*otemp)
         gamsc = lsub*diffu(k)/tcond(k) * rvs_p
         alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc)) &
                    * rvs_pp/rvs_p * rvs/rvs_p
         alphsc = MAX(1.E-9, alphsc)
         xsat = ssati(k)
         if (abs(xsat).lt. 1.E-9) xsat=0.
         t1_subl = 4.*PI*( 1.0 - alphsc*xsat &
                + 2.*alphsc*alphsc*xsat*xsat &
                - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat ) &
                / (1.+gamsc)

!..Snow collecting cloud water.  In CE, assume Dc<<Ds and vtc=~0.
         if (L_qc(k) .and. mvd_c(k).gt. D0c) then
          if (xDs .gt. D0s) then
           idx = 1 + INT(nbs*DLOG(xDs/Ds(1))/DLOG(Ds(nbs)/Ds(1)))
           idx = MIN(idx, nbs)
           Ef_sw = t_Efsw(idx, INT(mvd_c(k)*1.E6))
           prs_scw(k) = rhof(k)*t1_qs_qc*Ef_sw*rc(k)*smoe(k)
           prs_scw(k) = MIN(DBLE(rc(k)*odts), prs_scw(k))
           pnc_scw(k) = rhof(k)*t1_qs_qc*Ef_sw*nc(k)*smoe(k)                ! Qc2M
           pnc_scw(k) = MIN(DBLE(nc(k)*odts), pnc_scw(k))
          endif

!..Graupel collecting cloud water.  In CE, assume Dc<<Dg and vtc=~0.
          if (rg(k).ge. r_g(1) .and. mvd_c(k).gt. D0c) then
           xDg = (bm_g + mu_g + 1.) * ilamg(k)
           vtg = rhof(k)*av_g(idx_bg(k))*cgg(6,idx_bg(k))*ogg3 * ilamg(k)**bv_g(idx_bg(k))
           stoke_g = mvd_c(k)*mvd_c(k)*vtg*rho_w/(9.*visco(k)*xDg)
!..Rime density formula of Cober and List (1993) also used by Milbrandt and Morrison (2014).
           const_Ri = -1.*(mvd_c(k)*0.5E6)*vtg/MIN(-0.1,tempc)
           const_Ri = MAX(0.1, MIN(const_Ri, 10.))
           rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
            if (stoke_g.ge.0.4 .and. stoke_g.le.10.) then
             Ef_gw = 0.55*ALOG10(2.51*stoke_g)
            elseif (stoke_g.lt.0.4) then
             Ef_gw = 0.0
            elseif (stoke_g.gt.10) then
             Ef_gw = 0.77
            endif
!!! Not sure what to do here - hail increases size rapidly here below melting level.
            if (twet(k).gt.T_0) Ef_gw = Ef_gw*0.1
            t1_qg_qc = PI*.25*av_g(idx_bg(k)) * cgg(9,idx_bg(k))
            prg_gcw(k) = rhof(k)*t1_qg_qc*Ef_gw*rc(k)*N0_g(k) &
                          *ilamg(k)**cge(9,idx_bg(k))
            pnc_gcw(k) = rhof(k)*t1_qg_qc*Ef_gw*nc(k)*N0_g(k)           &
                          *ilamg(k)**cge(9,idx_bg(k))                    ! Qc2M
            pnc_gcw(k) = MIN(DBLE(nc(k)*odts), pnc_gcw(k))
            if (twet(k).lt.T_0) pbg_gcw(k) = prg_gcw(k)/rime_dens
          endif
         endif

!..Snow and graupel collecting aerosols, wet scavenging.
         if (rs(k) .gt. r_s(1)) then
          Ef_sa = Eff_aero(xDs,0.04E-6,visco(k),rho(k),temp(k),'s')
          pna_sca(k) = rhof(k)*t1_qs_qc*Ef_sa*nwfa(k)*smoe(k)
          pna_sca(k) = MIN(DBLE(nwfa(k)*odts), pna_sca(k))

          Ef_sa = Eff_aero(xDs,0.8E-6,visco(k),rho(k),temp(k),'s')
          pnd_scd(k) = rhof(k)*t1_qs_qc*Ef_sa*nifa(k)*smoe(k)
          pnd_scd(k) = MIN(DBLE(nifa(k)*odts), pnd_scd(k))

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_sa = Eff_aero(xDs,0.0236E-6,visco(k),rho(k),temp(k),'s')
              pnb_scb(k) = rhof(k)*t1_qs_qc*Ef_sa*nbca(k)*smoe(k)
              pnb_scb(k) = MIN(DBLE(nbca(k)*odts), pnb_scb(k))
            endif
          endif
         endif
         if (rg(k) .gt. r_g(1)) then
          xDg = (bm_g + mu_g + 1.) * ilamg(k)
          Ef_ga = Eff_aero(xDg,0.04E-6,visco(k),rho(k),temp(k),'g')
          t1_qg_qc = PI*.25*av_g(idx_bg(k)) * cgg(9,idx_bg(k))
          pna_gca(k) = rhof(k)*t1_qg_qc*Ef_ga*nwfa(k)*N0_g(k)           &
                        *ilamg(k)**cge(9,idx_bg(k))
          pna_gca(k) = MIN(DBLE(nwfa(k)*odts), pna_gca(k))

          Ef_ga = Eff_aero(xDg,0.8E-6,visco(k),rho(k),temp(k),'g')
          pnd_gcd(k) = rhof(k)*t1_qg_qc*Ef_ga*nifa(k)*N0_g(k)           &
                        *ilamg(k)**cge(9,idx_bg(k))
          pnd_gcd(k) = MIN(DBLE(nifa(k)*odts), pnd_gcd(k))

          if (present(wif_input_opt)) then
            if (wif_input_opt .eq. 2) then
              Ef_ga = Eff_aero(xDg,0.0236E-6,visco(k),rho(k),temp(k),'g')
              pnb_gcb(k) = rhof(k)*t1_qg_qc*Ef_ga*nbca(k)*N0_g(k)       &
                            *ilamg(k)**cge(9,idx_bg(k))
              pnb_gcb(k) = MIN(DBLE(nbca(k)*odts), pnb_gcb(k))
            endif
          endif
         endif

!..Rain collecting snow.  Cannot assume Wisner (1972) approximation
!.. or Mizuno (1990) approach so we solve the CE explicitly and store
!.. results in lookup table.
         if (rr(k).ge. r_r(1)) then
          if (rs(k).ge. r_s(1)) then
           if (twet(k).lt.T_0) then
            prr_rcs(k) = -(tmr_racs2(idx_s,idx_t,idx_r1,idx_r) &
                           + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r) &
                           + tmr_racs1(idx_s,idx_t,idx_r1,idx_r) &
                           + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r))
            prs_rcs(k) = tmr_racs2(idx_s,idx_t,idx_r1,idx_r) &
                         + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r) &
                         - tcs_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
            prg_rcs(k) = tmr_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r) &
                         + tcs_racs1(idx_s,idx_t,idx_r1,idx_r) &
                         + tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
            prr_rcs(k) = MAX(DBLE(-rr(k)*odts), prr_rcs(k))
            prs_rcs(k) = MAX(DBLE(-rs(k)*odts), prs_rcs(k))
            prg_rcs(k) = MIN(DBLE((rr(k)+rs(k))*odts), prg_rcs(k))
            pnr_rcs(k) = tnr_racs1(idx_s,idx_t,idx_r1,idx_r)            &   ! RAIN2M
                         + tnr_racs2(idx_s,idx_t,idx_r1,idx_r)          &
                         + tnr_sacr1(idx_s,idx_t,idx_r1,idx_r)          &
                         + tnr_sacr2(idx_s,idx_t,idx_r1,idx_r)
            pnr_rcs(k) = MIN(DBLE(nr(k)*odts), pnr_rcs(k))
            png_rcs(k) = pnr_rcs(k)
!-GT        pbg_rcs(k) = prg_rcs(k)/(0.5*(rho_i+rho_s))
            pbg_rcs(k) = prg_rcs(k)/rho_i
           else
            prs_rcs(k) = -tcs_racs1(idx_s,idx_t,idx_r1,idx_r)           &
                         - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)          &
                         + tmr_racs2(idx_s,idx_t,idx_r1,idx_r)          &
                         + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r)
            prs_rcs(k) = MAX(DBLE(-rs(k)*odts), prs_rcs(k))
            prr_rcs(k) = -prs_rcs(k)
           endif
          endif

!..Rain collecting graupel.  Cannot assume Wisner (1972) approximation
!.. or Mizuno (1990) approach so we solve the CE explicitly and store
!.. results in lookup table.
          if (rg(k).ge. r_g(1)) then
           if (twet(k).lt.T_0) then
            prg_rcg(k) = tmr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  &
                         + tcr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            prg_rcg(k) = MIN(DBLE(rr(k)*odts), prg_rcg(k))
            prr_rcg(k) = -prg_rcg(k)
            pnr_rcg(k) = tnr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  &   ! RAIN2M
                         + tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            pnr_rcg(k) = MIN(DBLE(nr(k)*odts), pnr_rcg(k))
!-GT        pbg_rcg(k) = prg_rcg(k)/(0.5*(rho_i+rho_g(idx_bg(k))))
            pbg_rcg(k) = prg_rcg(k)/rho_i
           else
            prr_rcg(k) = tcg_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            prr_rcg(k) = MIN(DBLE(rg(k)*odts), prr_rcg(k))
            prg_rcg(k) = -prr_rcg(k)
            png_rcg(k) = tnr_racg(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
!!!                    + tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)
            png_rcg(k) = MIN(DBLE(ng(k)*odts), png_rcg(k))
            pbg_rcg(k) = prg_rcg(k)/rho_g(idx_bg(k))
!..Put in explicit drop break-up due to collisions.
            pnr_rcg(k) = -1.5*tnr_gacr(idx_g1,idx_g,idx_bg(k),idx_r1,idx_r)  ! RAIN2M
           endif
          endif
         endif

!+---+-----------------------------------------------------------------+
!..Next IF block handles only those processes below 0C.
!+---+-----------------------------------------------------------------+

         if (temp(k).lt.T_0) then

          vts_boost(k) = 1.0
          rate_max = (qv(k)-qvsi(k))*rho(k)*odts*0.999

!+---+---------------- BEGIN NEW ICE NUCLEATION -----------------------+
!..Freezing of supercooled water (rain or cloud) is influenced by dust
!.. but still using Bigg 1953 with a temperature adjustment of a few
!.. degrees depending on dust concentration.  A default value by way
!.. of idx_IN is 1.0 per Liter of air is used when dustyIce flag is
!.. false.  Next, a combination of deposition/condensation freezing
!.. using DeMott et al (2010) dust nucleation when water saturated or
!.. Phillips et al (2008) when below water saturation; else, without
!.. dustyIce flag, use the previous Cooper (1986) temperature-dependent
!.. value.  Lastly, allow homogeneous freezing of deliquesced aerosols
!.. following Koop et al. (2001, Nature).
!.. Implemented by T. Eidhammer and G. Thompson 2012Dec18
!+---+-----------------------------------------------------------------+

          if (dustyIce .AND. is_aerosol_aware) then
           xni = iceDeMott(tempc,qvs(k),qvs(k),qvsi(k),rho(k),nifa(k))
          else
           xni = 1.0 *1000.                                               ! Default is 1.0 per Liter
          endif

!..Ice nuclei lookup table index.
          if (xni.gt. Nt_IN(1)) then
           niin = NINT(ALOG10(xni))
           do nn = niin-1, niin+1
              n = nn
              if ( (xni/10.**nn).ge.1.0 .and. &
                   (xni/10.**nn).lt.10.0) goto 149
           enddo
 149       continue
           idx_IN = INT(xni/10.**n) + 10*(n-niin2) - (n-niin2)
           idx_IN = MAX(1, MIN(idx_IN, ntb_IN))
          else
           idx_IN = 1
          endif

!..Freezing of water drops into graupel/cloud ice (Bigg 1953).
          if (rr(k).gt. r_r(1)) then
           prg_rfz(k) = tpg_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pri_rfz(k) = tpi_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pni_rfz(k) = tni_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
           pnr_rfz(k) = tnr_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts          ! RAIN2M
           pnr_rfz(k) = MIN(DBLE(nr(k)*odts), pnr_rfz(k))
          elseif (rr(k).gt. R1 .and. temp(k).lt.HGFR) then
           pri_rfz(k) = rr(k)*odts
           pni_rfz(k) = nr(k)*odts                                         ! RAIN2M
          endif
          pbg_rfz(k) = prg_rfz(k)/rho_i

          if (rc(k).gt. r_c(1)) then
           pri_wfz(k) = tpi_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
           pri_wfz(k) = MIN(DBLE(rc(k)*odts), pri_wfz(k))
           pni_wfz(k) = tni_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
           pni_wfz(k) = MIN(DBLE(nc(k)*odts), pri_wfz(k)/(2.*xm0i),     &
                                pni_wfz(k))
          elseif (rc(k).gt. R1 .and. temp(k).lt.HGFR) then
           pri_wfz(k) = rc(k)*odts
           pni_wfz(k) = nc(k)*odts
          endif

!..Deposition nucleation of dust/mineral from DeMott et al (2010)
!.. we may need to relax the temperature and ssati constraints.
          if ( (ssati(k).ge. 0.25) .or. (ssatw(k).gt. eps &
                                .and. temp(k).lt.253.15) ) then
           if (dustyIce .AND. is_aerosol_aware) then
            xnc = iceDeMott(tempc,qv(k),qvs(k),qvsi(k),rho(k),nifa(k))
           else
            xnc = MIN(250.E3, TNO*EXP(ATO*(T_0-temp(k))))
           endif
           xni = ni(k) + (pni_rfz(k)+pni_wfz(k))*dtsave
           pni_inu(k) = 0.5*(xnc-xni + abs(xnc-xni))*odts
           pri_inu(k) = MIN(DBLE(rate_max), xm0i*pni_inu(k))
           pni_inu(k) = pri_inu(k)/xm0i
          endif

!..Freezing of aqueous aerosols based on Koop et al (2001, Nature)
          xni = ns(k)+ni(k) + (pni_rfz(k)+pni_wfz(k)+pni_inu(k))*dtsave
          if (is_aerosol_aware .AND. homogIce .AND. (xni.le.999.E3)     &
     &                .AND.(temp(k).lt.238).AND.(ssati(k).ge.0.4) ) then
            xnc = iceKoop(temp(k),qv(k),qvs(k),nwfa(k), dtsave)
            pni_iha(k) = xnc*odts
            pri_iha(k) = MIN(DBLE(rate_max), xm0i*0.1*pni_iha(k))
            pni_iha(k) = pri_iha(k)/(xm0i*0.1)
          endif
!+---+------------------ END NEW ICE NUCLEATION -----------------------+


!..Deposition/sublimation of cloud ice (Srivastava & Coen 1992).
          if (L_qi(k)) then
           lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
           ilami = 1./lami
           xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
           xmi = am_i*xDi**bm_i
           oxmi = 1./xmi
           pri_ide(k) = C_cube*t1_subl*diffu(k)*ssati(k)*rvs &
                  *oig1*cig(5)*ni(k)*ilami

           if (pri_ide(k) .lt. 0.0) then
            pri_ide(k) = MAX(DBLE(-ri(k)*odts), pri_ide(k), DBLE(rate_max))
            pni_ide(k) = pri_ide(k)*oxmi
            pni_ide(k) = MAX(DBLE(-ni(k)*odts), pni_ide(k))
           else
            pri_ide(k) = MIN(pri_ide(k), DBLE(rate_max))
            prs_ide(k) = (1.0D0-tpi_ide(idx_i,idx_i1))*pri_ide(k)
            pri_ide(k) = tpi_ide(idx_i,idx_i1)*pri_ide(k)
           endif

!..Some cloud ice needs to move into the snow category.  Use lookup
!.. table that resulted from explicit bin representation of distrib.
           if ( (idx_i.eq. ntb_i) .or. (xDi.gt. 5.0*D0s) ) then
            prs_iau(k) = ri(k)*.99*odts
            pni_iau(k) = ni(k)*.95*odts
           elseif (xDi.lt. 0.1*D0s) then
            prs_iau(k) = 0.
            pni_iau(k) = 0.
           else
            prs_iau(k) = tps_iaus(idx_i,idx_i1)*odts
            prs_iau(k) = MIN(DBLE(ri(k)*.99*odts), prs_iau(k))
            pni_iau(k) = tni_iaus(idx_i,idx_i1)*odts
            pni_iau(k) = MIN(DBLE(ni(k)*.95*odts), pni_iau(k))
           endif
          endif

!..Deposition/sublimation of snow/graupel follows Srivastava & Coen
!.. (1992).
          if (L_qs(k)) then
           C_snow = C_sqrd + (tempc+1.5)*(C_cube-C_sqrd)/(-30.+1.5)
           C_snow = MAX(C_sqrd, MIN(C_snow, C_cube))
           prs_sde(k) = C_snow*t1_subl*diffu(k)*ssati(k)*rvs &
                        * (t1_qs_sd*smo1(k) &
                         + t2_qs_sd*rhof2(k)*vsc2(k)*smof(k))
           if (prs_sde(k).lt. 0.) then
            prs_sde(k) = MAX(DBLE(-rs(k)*odts), prs_sde(k), DBLE(rate_max))
           else
            prs_sde(k) = MIN(prs_sde(k), DBLE(rate_max))
           endif
          endif

          if (L_qg(k) .and. ssati(k).lt. -eps) then
           t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
           prg_gde(k) = C_cube*t1_subl*diffu(k)*ssati(k)*rvs &
               * N0_g(k) * (t1_qg_sd*ilamg(k)**cge(10,1) &
               + t2_qg_sd*vsc2(k)*rhof2(k)*ilamg(k)**cge(11,idx_bg(k)))
           if (prg_gde(k).lt. 0.) then
            prg_gde(k) = MAX(DBLE(-rg(k)*odts), prg_gde(k), DBLE(rate_max))
            png_gde(k) = prg_gde(k) * ng(k)/rg(k)
           else
            prg_gde(k) = MIN(prg_gde(k), DBLE(rate_max))
           endif
          endif

!..Snow collecting cloud ice.  In CE, assume Di<<Ds and vti=~0.
          if (L_qi(k)) then
           lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
           ilami = 1./lami
           xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
           xmi = am_i*xDi**bm_i
           oxmi = 1./xmi
           if (rs(k).ge. r_s(1)) then
            prs_sci(k) = t1_qs_qi*rhof(k)*Ef_si*ri(k)*smoe(k)
            pni_sci(k) = prs_sci(k) * oxmi
           endif

!..Rain collecting cloud ice.  In CE, assume Di<<Dr and vti=~0.
           if (rr(k).ge. r_r(1) .and. mvd_r(k).gt. 4.*xDi) then
            lamr = 1./ilamr(k)
            pri_rci(k) = rhof(k)*t1_qr_qi*Ef_ri*ri(k)*N0_r(k) &
                           *((lamr+fv_r)**(-cre(9)))
            pnr_rci(k) = rhof(k)*t1_qr_qi*Ef_ri*ni(k)*N0_r(k)           &   ! RAIN2M
                           *((lamr+fv_r)**(-cre(9)))
            pnr_rci(k) = MIN(DBLE(nr(k)*odts), pnr_rci(k))
            pni_rci(k) = pri_rci(k) * oxmi
            prr_rci(k) = rhof(k)*t2_qr_qi*Ef_ri*ni(k)*N0_r(k) &
                           *((lamr+fv_r)**(-cre(8)))
            prr_rci(k) = MIN(DBLE(rr(k)*odts), prr_rci(k))
            prg_rci(k) = pri_rci(k) + prr_rci(k)
            pbg_rci(k) = prg_rci(k)/rho_i
           endif
          endif

!..Ice multiplication from rime-splinters (Hallet & Mossop 1974).
          if (prg_gcw(k).gt. eps .and. tempc.gt.-8.0) then
           tf = 0.
           if (tempc.ge.-5.0 .and. tempc.lt.-3.0) then
            tf = 0.5*(-3.0 - tempc)
           elseif (tempc.gt.-8.0 .and. tempc.lt.-5.0) then
            tf = 0.33333333*(8.0 + tempc)
           endif
           pni_ihm(k) = 3.5E8*tf*prg_gcw(k)
           pri_ihm(k) = xm0i*pni_ihm(k)
           prs_ihm(k) = prs_scw(k)/(prs_scw(k)+prg_gcw(k)) &
                          * pri_ihm(k)
           prg_ihm(k) = prg_gcw(k)/(prs_scw(k)+prg_gcw(k)) &
                          * pri_ihm(k)
          endif

!..A portion of rimed snow converts to graupel but some remains snow.
!.. Interp from 15 to 95% as riming factor increases from 2.0 to 30.0
!.. 0.028 came from (.95-.15)/(30.-2.).  This remains ad-hoc and should
!.. be revisited.
          if (prs_scw(k).gt.2.0*prs_sde(k) .and. &
                         prs_sde(k).gt.eps) then
           r_frac = MIN(30.0D0, prs_scw(k)/prs_sde(k))
           g_frac = MIN(0.95, 0.15 + (r_frac-2.)*.028)
           vts_boost(k) = MIN(1.5, 1.1 + (r_frac-2.)*.014)
           prg_scw(k) = g_frac*prs_scw(k)
           png_scw(k) = prg_scw(k)*smo0(k)/rs(k)
!..GT      png_scw(k) = prg_scw(k)*ns(k)/rs(k)
           vts = av_s*xDs**bv_s * EXP(-fv_s*xDs)
           const_Ri = -1.*(mvd_c(k)*0.5E6)*vts/MIN(-0.1,tempc)
           const_Ri = MAX(0.1, MIN(const_Ri, 10.))
           rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
           if(rime_dens .lt. 150.) then                                  ! Idea of A. Jensen
              g_frac = 0.
              prg_scw(k)=0.
              png_scw(k)=0.
           endif
           pbg_scw(k) = prg_scw(k)/(0.5*(rime_dens+rho_s))
           prs_scw(k) = (1. - g_frac)*prs_scw(k)
          endif

         else

!..Melt snow and graupel and enhance from collisions with liquid.
!.. We also need to sublimate snow and graupel if subsaturated.
          if (L_qs(k)) then
           prr_sml(k) = (tempc*tcond(k)-lvap0*diffu(k)*delQvs(k))       &
                      * (t1_qs_me*smo1(k) + t2_qs_me*rhof2(k)*vsc2(k)*smof(k))
           if (prr_sml(k) .gt. 0.) then
              prr_sml(k) = prr_sml(k) + 4218.*olfus*(twet(k)-T_0)       &
                                      * (prr_rcs(k)+prs_scw(k))
           endif
           prr_sml(k) = MIN(DBLE(rs(k)*odts), MAX(0.D0, prr_sml(k)))

           if (prr_sml(k).gt.0.0) then
              pnr_sml(k) = smo0(k)/rs(k)*prr_sml(k) * 10.0**(-0.25*(twet(k)-T_0))
           elseif (ssati(k).lt. 0.) then
              prs_sde(k) = C_sqrd*t1_subl*diffu(k)*ssati(k)*rvs &
                         * (t1_qs_sd*smo1(k) &
                          + t2_qs_sd*rhof2(k)*vsc2(k)*smof(k))
            prs_sde(k) = MAX(DBLE(-rs(k)*odts), prs_sde(k))
           endif
          endif

          if (L_qg(k)) then
           N0_melt = N0_g(k)
           if ((rg(k)*ng(k)) .lt. 1.E-4) then
              lamg = 1./ilamg(k)
              N0_melt = (1.E-4/rg(k))*ogg2*lamg**cge(2,1)
           endif
           t2_qg_me = PI*4.*C_cube*olfus * 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
           prr_gml(k) = (tempc*tcond(k)-lvap0*diffu(k)*delQvs(k))       &
                      * N0_melt*(t1_qg_me*ilamg(k)**cge(10,1)           &
                      + t2_qg_me*rhof2(k)*vsc2(k)*ilamg(k)**cge(11,idx_bg(k)))
!          if (prr_gml(k) .gt. 0.) then
!             prr_gml(k) = prr_gml(k) + 4218.*olfus*(twet(k)-T_0)       &
!                                     * (prr_rcg(k)+prg_gcw(k))
!          endif
           prr_gml(k) = MIN(DBLE(rg(k)*odts), MAX(0.D0, prr_gml(k)))
!           pnr_gml(k) = N0_g(k)*cgg(2)*ilamg(k)**cge(2) / rg(k)         &   ! RAIN2M
!                      * prr_gml(k) * 10.0**(-0.5*tempc)

           if (prr_gml(k) .gt. 0.0) then
            melt_f = MAX(0.05, MIN(prr_gml(k)*dt/rg(k),1.0))
            !..1000 is density water, 50 is lower limit (max ice density is 800)
            pbg_gml(k) = prr_gml(k) / MAX(MIN(melt_f*rho_g(idx_bg(k)),1000.),50.)
!-GT        pnr_gml(k) = prr_gml(k)*ng(k)/rg(k)
            pnr_gml(k) = prr_gml(k)*ng(k)/rg(k) * 10.0**(-0.33*(twet(k)-T_0))
           elseif (ssati(k).lt. 0.) then
            t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg(k))) * cgg(11,idx_bg(k))
            prg_gde(k) = C_cube*t1_subl*diffu(k)*ssati(k)*rvs &
                * N0_g(k) * (t1_qg_sd*ilamg(k)**cge(10,1) &
                + t2_qg_sd*vsc2(k)*rhof2(k)*ilamg(k)**cge(11,idx_bg(k)))
            prg_gde(k) = MAX(DBLE(-rg(k)*odts), prg_gde(k))
            png_gde(k) = prg_gde(k) * ng(k)/rg(k)
           endif
          endif

!.. This change will be required if users run adaptive time step that
!.. results in delta-t that is generally too long to allow cloud water
!.. collection by snow/graupel above melting temperature.
!.. Credit to Bjorn-Egil Nygaard for discovering.
          if (dt .gt. 120.) then
             prr_rcw(k)=prr_rcw(k)+prs_scw(k)+prg_gcw(k)
             prs_scw(k)=0.
             prg_gcw(k)=0.
          endif

         endif

         if (.not. is_hail_aware) idx_bg(k) = idx_bg1

      enddo
      endif

!+---+-----------------------------------------------------------------+
!..Ensure we do not deplete more hydrometeor species than exists.
!+---+-----------------------------------------------------------------+
      do k = kts, kte

!..If ice supersaturated, ensure sum of depos growth terms does not
!.. deplete more vapor than possibly exists.  If subsaturated, limit
!.. sum of sublimation terms such that vapor does not reproduce ice
!.. supersat again.
         sump = pri_inu(k) + pri_ide(k) + prs_ide(k) &
              + prs_sde(k) + prg_gde(k) + pri_iha(k)
         rate_max = (qv(k)-qvsi(k))*rho(k)*odts*0.999
         if ( (sump.gt. eps .and. sump.gt. rate_max) .or. &
              (sump.lt. -eps .and. sump.lt. rate_max) ) then
          ratio = rate_max/sump
          pri_inu(k) = pri_inu(k) * ratio
          pri_ide(k) = pri_ide(k) * ratio
          pni_ide(k) = pni_ide(k) * ratio
          prs_ide(k) = prs_ide(k) * ratio
          prs_sde(k) = prs_sde(k) * ratio
          prg_gde(k) = prg_gde(k) * ratio
          pri_iha(k) = pri_iha(k) * ratio
         endif

!..Cloud water conservation.
         sump = -prr_wau(k) - pri_wfz(k) - prr_rcw(k) &
                - prs_scw(k) - prg_scw(k) - prg_gcw(k)
         rate_max = -rc(k)*odts
         if (sump.lt. rate_max .and. L_qc(k)) then
          ratio = rate_max/sump
          prr_wau(k) = prr_wau(k) * ratio
          pri_wfz(k) = pri_wfz(k) * ratio
          prr_rcw(k) = prr_rcw(k) * ratio
          prs_scw(k) = prs_scw(k) * ratio
          prg_scw(k) = prg_scw(k) * ratio
          prg_gcw(k) = prg_gcw(k) * ratio
         endif

!..Cloud ice conservation.
         sump = pri_ide(k) - prs_iau(k) - prs_sci(k) &
                - pri_rci(k)
         rate_max = -ri(k)*odts
         if (sump.lt. rate_max .and. L_qi(k)) then
          ratio = rate_max/sump
          pri_ide(k) = pri_ide(k) * ratio
          prs_iau(k) = prs_iau(k) * ratio
          prs_sci(k) = prs_sci(k) * ratio
          pri_rci(k) = pri_rci(k) * ratio
         endif

!..Rain conservation.
         sump = -prg_rfz(k) - pri_rfz(k) - prr_rci(k) &
                + prr_rcs(k) + prr_rcg(k)
         rate_max = -rr(k)*odts
         if (sump.lt. rate_max .and. L_qr(k)) then
          ratio = rate_max/sump
          prg_rfz(k) = prg_rfz(k) * ratio
          pri_rfz(k) = pri_rfz(k) * ratio
          prr_rci(k) = prr_rci(k) * ratio
          prr_rcs(k) = prr_rcs(k) * ratio
          prr_rcg(k) = prr_rcg(k) * ratio
         endif

!..Snow conservation.
         sump = prs_sde(k) - prs_ihm(k) - prr_sml(k) &
                + prs_rcs(k)
         rate_max = -rs(k)*odts
         if (sump.lt. rate_max .and. L_qs(k)) then
          ratio = rate_max/sump
          prs_sde(k) = prs_sde(k) * ratio
          prs_ihm(k) = prs_ihm(k) * ratio
          prr_sml(k) = prr_sml(k) * ratio
          prs_rcs(k) = prs_rcs(k) * ratio
         endif

!..Graupel conservation.
         sump = prg_gde(k) - prg_ihm(k) - prr_gml(k) &
              + prg_rcg(k)
         rate_max = -rg(k)*odts
         if (sump.lt. rate_max .and. L_qg(k)) then
          ratio = rate_max/sump
          prg_gde(k) = prg_gde(k) * ratio
          prg_ihm(k) = prg_ihm(k) * ratio
          prr_gml(k) = prr_gml(k) * ratio
          prg_rcg(k) = prg_rcg(k) * ratio
         endif

!..Re-enforce proper mass conservation for subsequent elements in case
!.. any of the above terms were altered.  Thanks P. Blossey. 2009Sep28
         pri_ihm(k) = prs_ihm(k) + prg_ihm(k)
         ratio = MIN( ABS(prr_rcg(k)), ABS(prg_rcg(k)) )
         prr_rcg(k) = ratio * SIGN(1.0, SNGL(prr_rcg(k)))
         prg_rcg(k) = -prr_rcg(k)
         if (twet(k).gt.T_0) then
            ratio = MIN( ABS(prr_rcs(k)), ABS(prs_rcs(k)) )
            prr_rcs(k) = ratio * SIGN(1.0, SNGL(prr_rcs(k)))
            prs_rcs(k) = -prr_rcs(k)
         endif

      enddo

!+---+-----------------------------------------------------------------+
!..Calculate tendencies of all species but constrain the number of ice
!.. to reasonable values.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         orho = 1./rho(k)
         lfus2 = lsub - lvap(k)

!..Aerosol number tendency
         if (is_aerosol_aware) then
            nwfaten(k) = nwfaten(k) - (pna_rca(k) + pna_sca(k)          &
                       + pna_gca(k) + pni_iha(k)) * orho
            nifaten(k) = nifaten(k) - (pnd_rcd(k) + pnd_scd(k)          &
                       + pnd_gcd(k)) * orho
            if (wif_input_opt .eq. 2) then
               nbcaten(k) = nbcaten(k) - (pnb_rcb(k) + pnb_scb(k)       &
                          + pnb_gcb(k)) * orho
            else
               nbcaten(k) = 0.0
            endif
            if (dustyIce) then
               nifaten(k) = nifaten(k) - pni_inu(k)*orho
            else
               nifaten(k) = 0.
            endif
         endif

!..Water vapor tendency
         qvten(k) = qvten(k) + (-pri_inu(k) - pri_iha(k) - pri_ide(k)   &
                      - prs_ide(k) - prs_sde(k) - prg_gde(k)) &
                      * orho

!..Cloud water tendency
         qcten(k) = qcten(k) + (-prr_wau(k) - pri_wfz(k) &
                      - prr_rcw(k) - prs_scw(k) - prg_scw(k) &
                      - prg_gcw(k)) &
                      * orho

!..Cloud water number tendency
         ncten(k) = ncten(k) + (-pnc_wau(k) - pnc_rcw(k) &
                      - pni_wfz(k) - pnc_scw(k) - pnc_gcw(k)) &
                      * orho

!..Cloud water mass/number balance; keep mass-wt mean size between
!.. 1 and 50 microns.  Also no more than Nt_c_max drops total.
         xrc=MAX(R1, (qc1d(k) + qcten(k)*dtsave)*rho(k))
         xnc=MAX(2., (nc1d(k) + ncten(k)*dtsave)*rho(k))
         if (xrc .gt. R1) then
          nu_c = MIN(15, NINT(1000.E6/xnc) + 2)
          lamc = (xnc*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc(k))**obmr
          xDc = (bm_r + nu_c + 1.) / lamc
          if (xDc.lt. D0c) then
           lamc = cce(2,nu_c)/D0c
           xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
           ncten(k) = (xnc-nc1d(k)*rho(k))*odts*orho
          elseif (xDc.gt. D0r*2.) then
           lamc = cce(2,nu_c)/(D0r*2.)
           xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
           ncten(k) = (xnc-nc1d(k)*rho(k))*odts*orho
          endif
         else
          ncten(k) = -nc1d(k)*odts
         endif
         xnc=MAX(0.,(nc1d(k) + ncten(k)*dtsave)*rho(k))
         if (xnc.gt.Nt_c_max) &
                ncten(k) = (Nt_c_max-nc1d(k)*rho(k))*odts*orho

!..Cloud ice mixing ratio tendency
         qiten(k) = qiten(k) + (pri_inu(k) + pri_iha(k) + pri_ihm(k)    &
                      + pri_wfz(k) + pri_rfz(k) + pri_ide(k) &
                      - prs_iau(k) - prs_sci(k) - pri_rci(k)) &
                      * orho

!..Cloud ice number tendency.
         niten(k) = niten(k) + (pni_inu(k) + pni_iha(k) + pni_ihm(k)    &
                      + pni_wfz(k) + pni_rfz(k) + pni_ide(k) &
                      - pni_iau(k) - pni_sci(k) - pni_rci(k)) &
                      * orho

!..Cloud ice mass/number balance; keep mass-wt mean size between
!.. 5 and 300 microns.  Also no more than 500 xtals per liter.
         xri=MAX(R1,(qi1d(k) + qiten(k)*dtsave)*rho(k))
         xni=MAX(R2,(ni1d(k) + niten(k)*dtsave)*rho(k))
         if (xri.gt. R1) then
           lami = (am_i*cig(2)*oig1*xni/xri)**obmi
           ilami = 1./lami
           xDi = (bm_i + mu_i + 1.) * ilami
           if (xDi.lt. 5.E-6) then
            lami = cie(2)/5.E-6
            xni = MIN(999.D3, cig(1)*oig2*xri/am_i*lami**bm_i)
            niten(k) = (xni-ni1d(k)*rho(k))*odts*orho
           elseif (xDi.gt. 300.E-6) then
            lami = cie(2)/300.E-6
            xni = cig(1)*oig2*xri/am_i*lami**bm_i
            niten(k) = (xni-ni1d(k)*rho(k))*odts*orho
           endif
         else
          niten(k) = -ni1d(k)*odts
         endif
         xni=MAX(0.,(ni1d(k) + niten(k)*dtsave)*rho(k))
         if (xni.gt.999.E3) &
                niten(k) = (999.E3-ni1d(k)*rho(k))*odts*orho

!..Rain tendency
         qrten(k) = qrten(k) + (prr_wau(k) + prr_rcw(k) &
                      + prr_sml(k) + prr_gml(k) + prr_rcs(k) &
                      + prr_rcg(k) - prg_rfz(k) &
                      - pri_rfz(k) - prr_rci(k)) &
                      * orho

!..Rain number tendency
         nrten(k) = nrten(k) + (pnr_wau(k) + pnr_sml(k) + pnr_gml(k)    &
                      - (pnr_rfz(k) + pnr_rcr(k) + pnr_rcg(k)           &
                      + pnr_rcs(k) + pnr_rci(k) + pni_rfz(k)) )         &
                      * orho

!..Rain mass/number balance; keep median volume diameter between
!.. 37 microns (D0r*0.75) and 2.5 mm.
         xrr=MAX(R1,(qr1d(k) + qrten(k)*dtsave)*rho(k))
         xnr=MAX(R2,(nr1d(k) + nrten(k)*dtsave)*rho(k))
         if (xrr.gt. R1) then
           lamr = (am_r*crg(3)*org2*xnr/xrr)**obmr
           mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
           if (mvd_r(k) .gt. 2.5E-3) then
              mvd_r(k) = 2.5E-3
              lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
              xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
              nrten(k) = (xnr-nr1d(k)*rho(k))*odts*orho
           elseif (mvd_r(k) .lt. D0r*0.75) then
              mvd_r(k) = D0r*0.75
              lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
              xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
              nrten(k) = (xnr-nr1d(k)*rho(k))*odts*orho
           endif
         else
           qrten(k) = -qr1d(k)*odts
           nrten(k) = -nr1d(k)*odts
         endif

!..Snow tendency
         qsten(k) = qsten(k) + (prs_iau(k) + prs_sde(k) + prs_sci(k)    &
                      + prs_scw(k) + prs_rcs(k) + prs_ide(k)            &
                      - prs_ihm(k) - prr_sml(k))                        &
                      * orho

!..Graupel tendency
         qgten(k) = qgten(k) + (prg_scw(k) + prg_rfz(k) &
                      + prg_gde(k) + prg_rcg(k) + prg_gcw(k) &
                      + prg_rci(k) + prg_rcs(k) - prg_ihm(k) &
                      - prr_gml(k))                          &
                      * orho

!..Graupel number tendency
         ngten(k) = ngten(k) + (png_scw(k) + pnr_rfz(k) - png_rcg(k)    &
                      + pnr_rci(k) + png_rcs(k) + png_gde(k)            &
                      - pnr_gml(k)) * orho

!..Graupel volume mixing ratio tendency
         qbten(k) = qbten(k) + (pbg_scw(k) + pbg_rfz(k)                 &
                      + pbg_gcw(k) + pbg_rci(k) + pbg_rcs(k)            &
                      + pbg_rcg(k) + pbg_sml(k) - pbg_gml(k)            &
                      + (prg_gde(k) - prg_ihm(k)) /rho_g(idx_bg(k)) )   &
                      * orho

!..Graupel mass/number balance; keep its median volume diameter between
!.. 3.0 times minimum size (D0g) and 25 mm.
         xrg=MAX(R1,(qg1d(k) + qgten(k)*dtsave)*rho(k))
         xng=MAX(R2,(ng1d(k) + ngten(k)*dtsave)*rho(k))
         xrb=MAX(xrg/rho(k)/rho_g(NRHG),(qb1d(k) + qbten(k)*dtsave))
         xrb=MIN(xrg/rho(k)/rho_g(1), xrb)

         if (xrg .gt. R1) then
            lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*xng/xrg)**obmg
            mvd_g(k) = (3.0 + mu_g + 0.672) / lamg

      if(debug_flag) then
           xrho_g = MAX(rho_g(1),MIN(rg(k)/rho(k)/rb(k),rho_g(NRHG)))
           afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*rho(k)))**b_coeff
           afall = afall * visco(k)**(1.0-2.0*b_coeff)
           vtg1 = rhof(k)*afall*cgg(6,idx_bg(k))*ogg3 / lamg**bfall
           vtg2 = rhof(k)*afall*cgg(7,idx_bg(k))/cgg(12,idx_bg(k)) / lamg**bfall
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: xrg, xng, xrb, ns, idx_bg, rho_g, mvd, vtg: ', k, xrg, xng, xrb, ns(k), idx_bg(k), xrg/rho(k)/xrb, mvd_g(k)*1000., vtg1, vtg2
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: qgten: ', qgten(k), prg_scw(k), prg_rfz(k), prg_gde(k), prg_rcg(k), prg_gcw(k), prg_rci(k), prg_rcs(k), prg_ihm(k), prr_gml(k)
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: ngten: ', ngten(k), png_scw(k), pnr_rfz(k), png_rcg(k), pnr_rci(k), png_rcs(k), pnr_gml(k)
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
#ifndef WRF_GPU
         write(mp_debug, *) 'DEBUG: qbten: ', qbten(k), pbg_scw(k), pbg_rfz(k), pbg_gcw(k), pbg_rci(k), pbg_rcs(k), pbg_rcg(k), pbg_sml(k), pbg_gml(k)
#endif
#ifndef WRF_GPU
         CALL wrf_debug(0, mp_debug)
#endif
      endif

            if (mvd_g(k) .gt. 25.4E-3) then
               mvd_g(k) = 25.4E-3
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg(k))
               ngten(k) = (xng-ng1d(k)*rho(k))*odts*orho
            elseif (mvd_g(k) .lt. D0r) then
               mvd_g(k) = D0r
               lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
               xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg(k))
               ngten(k) = (xng-ng1d(k)*rho(k))*odts*orho
            endif

         else
           qgten(k) = -qg1d(k)*odts
           ngten(k) = -ng1d(k)*odts
           qbten(k) = -qb1d(k)*odts
         endif

!..Temperature tendency
         if (temp(k).lt.T_0) then
          tten(k) = tten(k) &
                    + ( lsub*ocp(k)*(pri_inu(k) + pri_ide(k) &
                                     + prs_ide(k) + prs_sde(k) &
                                     + prg_gde(k) + pri_iha(k)) &
                     + lfus2*ocp(k)*(pri_wfz(k) + pri_rfz(k) &
                                     + prg_rfz(k) + prs_scw(k) &
                                     + prg_scw(k) + prg_gcw(k) &
                                     + prg_rcs(k) + prs_rcs(k) &
                                     + prr_rci(k) + prg_rcg(k)) &
                       )*orho * (1-IFDRY)
         else
          tten(k) = tten(k) &
                    + ( lfus*ocp(k)*(-prr_sml(k) - prr_gml(k) &
                                     - prr_rcg(k) - prr_rcs(k)) &
                      + lsub*ocp(k)*(prs_sde(k) + prg_gde(k)) &
                       )*orho * (1-IFDRY)
         endif

      enddo
#endif

!+---+-----------------------------------------------------------------+
!..Update variables for TAU+1 before condensation & sedimention.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         temp(k) = t1d(k) + DT*tten(k)
         otemp = 1./temp(k)
         tempc = temp(k) - 273.15
         qv(k) = MAX(1.E-10, qv1d(k) + DT*qvten(k))
         rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
         rhof(k) = SQRT(RHO_NOT/rho(k))
         rhof2(k) = SQRT(rhof(k))
         qvs(k) = rslf(pres(k), temp(k))
         ssatw(k) = qv(k)/qvs(k) - 1.
         if (abs(ssatw(k)).lt. eps) ssatw(k) = 0.0
         diffu(k) = 2.11E-5*(temp(k)/273.15)**1.94 * (101325./pres(k))
         if (tempc .ge. 0.0) then
            visco(k) = (1.718+0.0049*tempc)*1.0E-5
         else
            visco(k) = (1.718+0.0049*tempc-1.2E-5*tempc*tempc)*1.0E-5
         endif
         vsc2(k) = SQRT(rho(k)/visco(k))
         lvap(k) = lvap0 + (2106.0 - 4218.0)*tempc
         tcond(k) = (5.69 + 0.0168*tempc)*1.0E-5 * 418.936
         ocp(k) = 1./(Cp*(1.+0.887*qv(k)))
         lvt2(k)=lvap(k)*lvap(k)*ocp(k)*oRv*otemp*otemp

         nwfa(k) = MAX(11.1E6, (nwfa1d(k) + nwfaten(k)*DT)*rho(k))
      enddo

      do k = kts, kte
         if ((qc1d(k) + qcten(k)*DT) .gt. R1) then
            rc(k) = (qc1d(k) + qcten(k)*DT)*rho(k)
            nc(k) = MAX(2., MIN((nc1d(k)+ncten(k)*DT)*rho(k), Nt_c_max))
            if (.NOT. is_aerosol_aware) nc(k) = Nt_c
            L_qc(k) = .true.
         else
            rc(k) = R1
            nc(k) = 2.
            L_qc(k) = .false.
         endif

         if ((qi1d(k) + qiten(k)*DT) .gt. R1) then
            ri(k) = (qi1d(k) + qiten(k)*DT)*rho(k)
            ni(k) = MAX(R2, (ni1d(k) + niten(k)*DT)*rho(k))
            L_qi(k) = .true. 
         else
            ri(k) = R1
            ni(k) = R2
            L_qi(k) = .false.
         endif

         if ((qr1d(k) + qrten(k)*DT) .gt. R1) then
            rr(k) = (qr1d(k) + qrten(k)*DT)*rho(k)
            nr(k) = MAX(R2, (nr1d(k) + nrten(k)*DT)*rho(k))
            L_qr(k) = .true.
            lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
            mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
            if (mvd_r(k) .gt. 2.5E-3) then
               mvd_r(k) = 2.5E-3
               lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
               nr(k) = crg(2)*org3*rr(k)*lamr**bm_r / am_r
            elseif (mvd_r(k) .lt. D0r*0.75) then
               mvd_r(k) = D0r*0.75
               lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
               nr(k) = crg(2)*org3*rr(k)*lamr**bm_r / am_r
            endif
         else
            rr(k) = R1
            nr(k) = R2
            L_qr(k) = .false.
         endif
               
         if ((qs1d(k) + qsten(k)*DT) .gt. R1) then
            rs(k) = (qs1d(k) + qsten(k)*DT)*rho(k)
            L_qs(k) = .true.
         else
            rs(k) = R1
            L_qs(k) = .false.
         endif
      enddo

      if (is_hail_aware) then
         do k = kts, kte
            if ((qg1d(k) + qgten(k)*DT) .gt. R1) then
               L_qg(k) = .true.
               rg(k) = (qg1d(k) + qgten(k)*DT)*rho(k)
               ng(k) = MAX(R2, (ng1d(k) + ngten(k)*DT)*rho(k))
               rb(k) = MAX(rg(k)/rho(k)/rho_g(NRHG), qb1d(k) + qbten(k)*DT)
               rb(k) = MIN(rg(k)/rho(k)/rho_g(1), rb(k))
               idx_bg(k) = MAX(1,MIN(NINT(rg(k)/rho(k)/rb(k) *0.01)+1,NRHG))
            else
               rg(k) = R1
               ng(k) = R2
               rb(k) = R1/rho(k)/rho_g(NRHG)
               idx_bg(k) = idx_bg1
               L_qg(k) = .false.
            endif
         enddo
      else
         do k = kte, kts, -1
            idx_bg(k) = idx_bg1
         enddo
         do k = kte, kts, -1
         if ((qg1d(k) + qgten(k)*DT) .gt. R1) then
            rg(k) = (qg1d(k) + qgten(k)*DT)*rho(k)
               ygra1 = alog10(max(1.E-9, rg(k)))
               zans1 = 3.0 + 2./7.*(ygra1+8.)
               zans1 = MAX(2., MIN(zans1, 6.))
               N0_exp = 10.**(zans1)
               lam_exp = (N0_exp*am_g(idx_bg(k))*cgg(1,1)/rg(k))**oge1
               lamg = lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
               ng(k) = cgg(2,1)*ogg3*rg(k)*lamg**bm_g / am_g(idx_bg(k))
               rb(k) = rg(k)/rho(k)/rho_g(idx_bg(k))
         else
            rg(k) = R1
               ng(k) = R2
               rb(k) = R1/rho(k)/rho_g(NRHG)
            L_qg(k) = .false.
         endif
      enddo
      endif

!+---+-----------------------------------------------------------------+
!..With tendency-updated mixing ratios, recalculate snow moments and
!.. intercepts/slopes of graupel and rain.
!+---+-----------------------------------------------------------------+
      if (.not. iiwarm) then
      do k = kts, kte
         smo2(k) = 0.
         smob(k) = 0.
         smoc(k) = 0.
         smod(k) = 0.
      enddo
      do k = kts, kte
         if (.not. L_qs(k)) CYCLE
         tc0 = MIN(-0.1, temp(k)-273.15)
         smob(k) = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2(k) = smob(k)
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
               + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
               + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
               + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
               + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
               + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
               + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
               + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
               + sb(10)*bm_s*bm_s*bm_s
            smo2(k) = (smob(k)/a_)**(1./b_)
         endif

!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
               + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
               + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
               + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
              + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
              + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc(k) = a_ * smo2(k)**b_

!..Calculate bm_s+bv_s (th) moment.  Useful for sedimentation.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(14) &
               + sa(4)*tc0*cse(14) + sa(5)*tc0*tc0 &
               + sa(6)*cse(14)*cse(14) + sa(7)*tc0*tc0*cse(14) &
               + sa(8)*tc0*cse(14)*cse(14) + sa(9)*tc0*tc0*tc0 &
               + sa(10)*cse(14)*cse(14)*cse(14)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(14) + sb(4)*tc0*cse(14) &
              + sb(5)*tc0*tc0 + sb(6)*cse(14)*cse(14) &
              + sb(7)*tc0*tc0*cse(14) + sb(8)*tc0*cse(14)*cse(14) &
              + sb(9)*tc0*tc0*tc0 + sb(10)*cse(14)*cse(14)*cse(14)
         smod(k) = a_ * smo2(k)**b_
      enddo
#ifdef WRF_GPU
      if (th_probe == 3) return
#endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for graupel.
!+---+-----------------------------------------------------------------+

      do k = kte, kts, -1
         lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng(k)/rg(k))**obmg
         ilamg(k) = 1./lamg
         N0_g(k) = ng(k)*ogg2*lamg**cge(2,1)
      enddo

      endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for rain.
!+---+-----------------------------------------------------------------+
      do k = kte, kts, -1
         lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
         ilamr(k) = 1./lamr
         mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
         N0_r(k) = nr(k)*org2*lamr**cre(2)
      enddo

!+---+-----------------------------------------------------------------+
!..Cloud water condensation and evaporation.  Nucleate cloud droplets
!.. using explicit CCN aerosols with hygroscopicity like sulfates using
!.. parcel model lookup table results provided by T. Eidhammer.  Evap
!.. drops using calculation of max drop size capable of evaporating in
!.. single timestep and explicit number of drops smaller than Dc_star
!.. from lookup table.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         orho = 1./rho(k)
         if ( (ssatw(k).gt. eps) .or. (ssatw(k).lt. -eps .and. &
                   L_qc(k)) ) then
          clap = (qv(k)-qvs(k))/(1. + lvt2(k)*qvs(k))
          do n = 1, 3
             fcd = qvs(k)* EXP(lvt2(k)*clap) - qv(k) + clap
             dfcd = qvs(k)*lvt2(k)* EXP(lvt2(k)*clap) + 1.
             clap = clap - fcd/dfcd
          enddo
          xrc = rc(k) + clap*rho(k)
          xnc = 0.
          if (xrc.gt. R1) then
           prw_vcd(k) = clap*odt
!+---+-----------------------------------------------------------------+ !  DROPLET NUCLEATION
           if (clap .gt. eps) then
            if (is_aerosol_aware) then
               xnc = MAX(2., activ_ncloud(temp(k), w1d(k), nwfa(k)))
            else
               xnc = Nt_c
            endif
            pnc_wcd(k) = 0.5*(xnc-nc(k) + abs(xnc-nc(k)))*odts*orho

!+---+-----------------------------------------------------------------+ !  EVAPORATION
           elseif (clap .lt. -eps .AND. ssatw(k).lt.-1.E-6 .AND. is_aerosol_aware) then
            tempc = temp(k) - 273.15
            otemp = 1./temp(k)
            rvs = rho(k)*qvs(k)
            rvs_p = rvs*otemp*(lvap(k)*otemp*oRv - 1.)
            rvs_pp = rvs * ( otemp*(lvap(k)*otemp*oRv - 1.) &
                            *otemp*(lvap(k)*otemp*oRv - 1.) &
                            + (-2.*lvap(k)*otemp*otemp*otemp*oRv) &
                            + otemp*otemp)
            gamsc = lvap(k)*diffu(k)/tcond(k) * rvs_p
            alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc)) &
                       * rvs_pp/rvs_p * rvs/rvs_p
            alphsc = MAX(1.E-9, alphsc)
            xsat = ssatw(k)
            if (abs(xsat).lt. 1.E-9) xsat=0.
            t1_evap = 2.*PI*( 1.0 - alphsc*xsat  &
                   + 2.*alphsc*alphsc*xsat*xsat  &
                   - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat ) &
                   / (1.+gamsc)

            Dc_star = DSQRT(-2.D0*DT * t1_evap/(2.*PI) &
                    * 4.*diffu(k)*ssatw(k)*rvs/rho_w)
            idx_d = MAX(1, MIN(INT(1.E6*Dc_star), nbc))

            idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(nc(k)/t_Nc(1)) / nic1)
            idx_n = MAX(1, MIN(idx_n, nbc))

!..Cloud water lookup table index.
            if (rc(k).gt. r_c(1)) then
             nic = NINT(ALOG10(rc(k)))
             do nn = nic-1, nic+1
                n = nn
                if ( (rc(k)/10.**nn).ge.1.0 .and. &
                     (rc(k)/10.**nn).lt.10.0) goto 159
             enddo
 159         continue
             idx_c = INT(rc(k)/10.**n) + 10*(n-nic2) - (n-nic2)
             idx_c = MAX(1, MIN(idx_c, ntb_c))
            else
             idx_c = 1
            endif

           !prw_vcd(k) = MAX(DBLE(-rc(k)*orho*odt),                     &
           !           -tpc_wev(idx_d, idx_c, idx_n)*orho*odt)
            prw_vcd(k) = MAX(DBLE(-rc(k)*0.99*orho*odt), prw_vcd(k))
            pnc_wcd(k) = MAX(DBLE(-nc(k)*0.99*orho*odt),                &
                         DBLE(-tnc_wev(idx_d, idx_c, idx_n)*orho*odt))

           endif
          else
           prw_vcd(k) = -rc(k)*orho*odt
           pnc_wcd(k) = -nc(k)*orho*odt
          endif

!+---+-----------------------------------------------------------------+

          qvten(k) = qvten(k) - prw_vcd(k)
          qcten(k) = qcten(k) + prw_vcd(k)
          ncten(k) = ncten(k) + pnc_wcd(k)
          nwfaten(k) = nwfaten(k) - pnc_wcd(k)
          tten(k) = tten(k) + lvap(k)*ocp(k)*prw_vcd(k)*(1-IFDRY)
          rc(k) = MAX(R1, (qc1d(k) + DT*qcten(k))*rho(k))
          if (rc(k).eq.R1) L_qc(k) = .false.
          nc(k) = MAX(2., MIN((nc1d(k)+ncten(k)*DT)*rho(k), Nt_c_max))
          if (.NOT. is_aerosol_aware) nc(k) = Nt_c
          qv(k) = MAX(1.E-10, qv1d(k) + DT*qvten(k))
          temp(k) = t1d(k) + DT*tten(k)
          rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
          qvs(k) = rslf(pres(k), temp(k))
          ssatw(k) = qv(k)/qvs(k) - 1.
         endif
      enddo

!+---+-----------------------------------------------------------------+
!.. If still subsaturated, allow rain to evaporate, following
!.. Srivastava & Coen (1992).
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         if ( (ssatw(k).lt. -eps) .and. L_qr(k) &
                     .and. (.not.(prw_vcd(k).gt. 0.)) ) then
          tempc = temp(k) - 273.15
          otemp = 1./temp(k)
          orho = 1./rho(k)
          rhof(k) = SQRT(RHO_NOT*orho)
          rhof2(k) = SQRT(rhof(k))
          diffu(k) = 2.11E-5*(temp(k)/273.15)**1.94 * (101325./pres(k))
          if (tempc .ge. 0.0) then
             visco(k) = (1.718+0.0049*tempc)*1.0E-5
          else
             visco(k) = (1.718+0.0049*tempc-1.2E-5*tempc*tempc)*1.0E-5
          endif
          vsc2(k) = SQRT(rho(k)/visco(k))
          lvap(k) = lvap0 + (2106.0 - 4218.0)*tempc
          tcond(k) = (5.69 + 0.0168*tempc)*1.0E-5 * 418.936
          ocp(k) = 1./(Cp*(1.+0.887*qv(k)))

          rvs = rho(k)*qvs(k)
          rvs_p = rvs*otemp*(lvap(k)*otemp*oRv - 1.)
          rvs_pp = rvs * ( otemp*(lvap(k)*otemp*oRv - 1.) &
                          *otemp*(lvap(k)*otemp*oRv - 1.) &
                          + (-2.*lvap(k)*otemp*otemp*otemp*oRv) &
                          + otemp*otemp)
          gamsc = lvap(k)*diffu(k)/tcond(k) * rvs_p
          alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc)) &
                     * rvs_pp/rvs_p * rvs/rvs_p
          alphsc = MAX(1.E-9, alphsc)
          xsat   = MIN(-1.E-9, ssatw(k))
          t1_evap = 2.*PI*( 1.0 - alphsc*xsat  &
                 + 2.*alphsc*alphsc*xsat*xsat  &
                 - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat ) &
                 / (1.+gamsc)

          lamr = 1./ilamr(k)
!..Rapidly eliminate near zero values when low humidity (<95%)
          if (qv(k)/qvs(k) .lt. 0.95 .AND. rr(k)*orho.le.1.E-8) then
          prv_rev(k) = rr(k)*orho*odts
          else
          prv_rev(k) = t1_evap*diffu(k)*(-ssatw(k))*N0_r(k)*rvs &
              * (t1_qr_ev*ilamr(k)**cre(10) &
              + t2_qr_ev*vsc2(k)*rhof2(k)*((lamr+0.5*fv_r)**(-cre(11))))
          rate_max = MIN((rr(k)*orho*odts), (qvs(k)-qv(k))*odts)
          prv_rev(k) = MIN(DBLE(rate_max), prv_rev(k)*orho)

!..TEST: G. Thompson  10 May 2013
!..Reduce the rain evaporation in same places as melting graupel occurs.
!..Rationale: falling and simultaneous melting graupel in subsaturated
!..regions will not melt as fast because particle temperature stays
!..at 0C.  Also not much shedding of the water from the graupel so
!..likely that the water-coated graupel evaporating much slower than
!..if the water was immediately shed off.
          IF (prr_gml(k).gt.0.0) THEN
             eva_factor = MIN(1.0, 0.01+(0.99-0.01)*(tempc/20.0))
             prv_rev(k) = prv_rev(k)*eva_factor
          ENDIF
          endif

          pnr_rev(k) = MIN(DBLE(nr(k)*0.99*orho*odts),                  &   ! RAIN2M
                       prv_rev(k) * nr(k)/rr(k))

          qrten(k) = qrten(k) - prv_rev(k)
          qvten(k) = qvten(k) + prv_rev(k)
          nrten(k) = nrten(k) - pnr_rev(k)
          nwfaten(k) = nwfaten(k) + pnr_rev(k)
          tten(k) = tten(k) - lvap(k)*ocp(k)*prv_rev(k)*(1-IFDRY)

          rr(k) = MAX(R1, (qr1d(k) + DT*qrten(k))*rho(k))
          qv(k) = MAX(1.E-10, qv1d(k) + DT*qvten(k))
          nr(k) = MAX(R2, (nr1d(k) + DT*nrten(k))*rho(k))
          temp(k) = t1d(k) + DT*tten(k)
          rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
         endif
      enddo
#if ( WRF_CHEM == 1 )
      if( wetscav_on ) then
        do k = kts, kte
          evapprod(k) = prv_rev(k) - (min(zeroD0,prs_sde(k)) + &
                                      min(zeroD0,prg_gde(k)))
          rainprod(k) = prr_wau(k) + prr_rcw(k) + prs_scw(k) + &
                                     prg_scw(k) + prs_iau(k) + &
                                     prg_gcw(k) + prs_sci(k) + &
                                     pri_rci(k)
        enddo
      endif
#endif
#ifdef WRF_GPU
      if (th_probe == 4) return
#endif

!+---+-----------------------------------------------------------------+
!..Find max terminal fallspeed (distribution mass-weighted mean
!.. velocity) and use it to determine if we need to split the timestep
!.. (var nstep>1).  Either way, only bother to do sedimentation below
!.. 1st level that contains any sedimenting particles (k=ksed1 on down).
!.. New in v3.0+ is computing separate for rain, ice, snow, and
!.. graupel species thus making code faster with credit to J. Schmidt.
!+---+-----------------------------------------------------------------+
      nstep = 0
      onstep(:) = 1.0
      ksed1(:) = 1
      do k = kte+1, kts, -1
         vtrk(k) = 0.
         vtnrk(k) = 0.
         vtik(k) = 0.
         vtnik(k) = 0.
         vtsk(k) = 0.
         vtgk(k) = 0.
         vtngk(k) = 0.
         vtck(k) = 0.
         vtnck(k) = 0.
      enddo

      if (ANY(L_qr(kts:kte))) then
      do k = kte, kts, -1
         vtr = 0.
         rhof(k) = SQRT(RHO_NOT/rho(k))

         if (rr(k).gt. R1) then
          lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
          vtr = rhof(k)*av_r*crg(6)*org3 * lamr**cre(3)                 &
                      *((lamr+fv_r)**(-cre(6)))
          vtrk(k) = vtr
! First below is technically correct:
!         vtr = rhof(k)*av_r*crg(5)*org2 * lamr**cre(2)                 &
!                     *((lamr+fv_r)**(-cre(5)))
! Test: make number fall faster (but still slower than mass)
! Goal: less prominent size sorting
          vtr = rhof(k)*av_r*crg(7)/crg(12) * lamr**cre(12)             &
                      *((lamr+fv_r)**(-cre(7)))
          vtnrk(k) = vtr
         else
          vtrk(k) = vtrk(k+1)
          vtnrk(k) = vtnrk(k+1)
         endif

         if (MAX(vtrk(k),vtnrk(k)) .gt. 1.E-3) then
            ksed1(1) = MAX(ksed1(1), k)
            delta_tp = dzq(k)/(MAX(vtrk(k),vtnrk(k)))
            nstep = MAX(nstep, INT(DT/delta_tp + 1.))
         endif
      enddo
      if (ksed1(1) .eq. kte) ksed1(1) = kte-1
      if (nstep .gt. 0) onstep(1) = 1./REAL(nstep)
      endif

!+---+-----------------------------------------------------------------+

      if (ANY(L_qc(kts:kte))) then
      hgt_agl = 0.
      do k = kts, kte-1
         if (rc(k) .gt. R2) ksed1(5) = k
         hgt_agl = hgt_agl + dzq(k)
         if (hgt_agl .gt. 500.0) goto 151
      enddo
 151  continue

      do k = ksed1(5), kts, -1
         vtc = 0.
         if (rc(k) .gt. R1 .and. w1d(k) .lt. 1.E-1) then
          nu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
          lamc = (nc(k)*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc(k))**obmr
          ilamc = 1./lamc
          vtc = rhof(k)*av_c*ccg(5,nu_c)*ocg2(nu_c) * ilamc**bv_c
          vtck(k) = vtc
          vtc = rhof(k)*av_c*ccg(4,nu_c)*ocg1(nu_c) * ilamc**bv_c
          vtnck(k) = vtc
         endif
      enddo
      endif

!+---+-----------------------------------------------------------------+

      if (.not. iiwarm) then

       if (ANY(L_qi(kts:kte))) then
       nstep = 0
       do k = kte, kts, -1
          vti = 0.

          if (ri(k).gt. R1) then
           lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
           ilami = 1./lami
           vti = rhof(k)*av_i*cig(3)*oig2 * ilami**bv_i
           vtik(k) = vti
! First below is technically correct:
!          vti = rhof(k)*av_i*cig(4)*oig1 * ilami**bv_i
! Goal: less prominent size sorting
           vti = rhof(k)*av_i*cig(6)/cig(7) * ilami**bv_i
           vtnik(k) = vti
          else
           vtik(k) = vtik(k+1)
           vtnik(k) = vtnik(k+1)
          endif

          if (vtik(k) .gt. 1.E-3) then
             ksed1(2) = MAX(ksed1(2), k)
             delta_tp = dzq(k)/vtik(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(2) .eq. kte) ksed1(2) = kte-1
       if (nstep .gt. 0) onstep(2) = 1./REAL(nstep)
       endif

!+---+-----------------------------------------------------------------+

       if (ANY(L_qs(kts:kte))) then
       nstep = 0
       do k = kte, kts, -1
          vts = 0.

          if (rs(k).gt. R1) then
           xDs = smoc(k) / smob(k)
           Mrat = 1./xDs
           ils1 = 1./(Mrat*Lam0 + fv_s)
           ils2 = 1./(Mrat*Lam1 + fv_s)
           t1_vts = Kap0*csg(4)*ils1**cse(4)
           t2_vts = Kap1*Mrat**mu_s*csg(10)*ils2**cse(10)
           ils1 = 1./(Mrat*Lam0)
           ils2 = 1./(Mrat*Lam1)
           t3_vts = Kap0*csg(1)*ils1**cse(1)
           t4_vts = Kap1*Mrat**mu_s*csg(7)*ils2**cse(7)
           vts = rhof(k)*av_s * (t1_vts+t2_vts)/(t3_vts+t4_vts)
           if (prr_sml(k) .gt. 0.0) then 
            SR = rs(k)/(rs(k)+rr(k))
            vtsk(k) = vts*SR + (1.-SR)*vtrk(k)
           else
            vtsk(k) = vts*vts_boost(k)
           endif
          else
            vtsk(k) = vtsk(k+1)
          endif

          if (vtsk(k) .gt. 1.E-3) then
             ksed1(3) = MAX(ksed1(3), k)
             delta_tp = dzq(k)/vtsk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(3) .eq. kte) ksed1(3) = kte-1
       if (nstep .gt. 0) onstep(3) = 1./REAL(nstep)
       endif

!+---+-----------------------------------------------------------------+

       if (ANY(L_qg(kts:kte))) then
       nstep = 0
       do k = kte, kts, -1
          vtg = 0.

          if (rg(k).gt. R1) then
           if (is_hail_aware) then
              xrho_g = MAX(rho_g(1),MIN(rg(k)/rho(k)/rb(k),rho_g(NRHG)))
              afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*rho(k)))**b_coeff
              afall = afall * visco(k)**(1.0-2.0*b_coeff)
           else
              afall = av_g_old
              bfall = bv_g_old
           endif
           vtg = rhof(k)*afall*cgg(6,idx_bg(k))*ogg3 * ilamg(k)**bfall
            vtgk(k) = vtg
! Goal: less prominent size sorting
!    the ELSE section below is technically (mathematically) correct:
           if (mu_g .eq. 0) then
              vtg = rhof(k)*afall*cgg(7,idx_bg(k))/cgg(12,idx_bg(k)) * ilamg(k)**bfall
           else
              vtg = rhof(k)*afall*cgg(8,idx_bg(k))*ogg2 * ilamg(k)**bfall
           endif
           vtngk(k) = vtg
          else
            vtgk(k) = vtgk(k+1)
           vtngk(k) = vtngk(k+1)
          endif

          if (vtgk(k) .gt. 1.E-3) then
             ksed1(4) = MAX(ksed1(4), k)
             delta_tp = dzq(k)/vtgk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(4) .eq. kte) ksed1(4) = kte-1
       if (nstep .gt. 0) onstep(4) = 1./REAL(nstep)
       endif
      endif

!+---+-----------------------------------------------------------------+
!..Sedimentation of mixing ratio is the integral of v(D)*m(D)*N(D)*dD,
!.. whereas neglect m(D) term for number concentration.  Therefore,
!.. cloud ice has proper differential sedimentation.
!+---+-----------------------------------------------------------------+

      if (ANY(L_qr(kts:kte))) then
      nstep = NINT(1./onstep(1))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_r(k) = vtrk(k)*rr(k)
            sed_n(k) = vtnrk(k)*nr(k)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./rho(k)
         qrten(k) = qrten(k) - sed_r(k)*odzq*onstep(1)*orho
         nrten(k) = nrten(k) - sed_n(k)*odzq*onstep(1)*orho
         rr(k) = MAX(R1, rr(k) - sed_r(k)*odzq*DT*onstep(1))
         nr(k) = MAX(R2, nr(k) - sed_n(k)*odzq*DT*onstep(1))
         do k = ksed1(1), kts, -1
            odzq = 1./dzq(k)
            orho = 1./rho(k)
            qrten(k) = qrten(k) + (sed_r(k+1)-sed_r(k))                 &
                                               *odzq*onstep(1)*orho
            nrten(k) = nrten(k) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(1)*orho
            rr(k) = MAX(R1, rr(k) + (sed_r(k+1)-sed_r(k)) &
                                           *odzq*DT*onstep(1))
            nr(k) = MAX(R2, nr(k) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(1))
         enddo

         if (rr(kts).gt.R1*1000.) &
         pptrain = pptrain + sed_r(kts)*DT*onstep(1)
      enddo
      endif

!+---+-----------------------------------------------------------------+

      if (ANY(L_qc(kts:kte))) then
      do k = kte, kts, -1
         sed_c(k) = vtck(k)*rc(k)
         sed_n(k) = vtnck(k)*nc(k)
      enddo
      do k = ksed1(5), kts, -1
         odzq = 1./dzq(k)
         orho = 1./rho(k)
         qcten(k) = qcten(k) + (sed_c(k+1)-sed_c(k)) *odzq*orho
         ncten(k) = ncten(k) + (sed_n(k+1)-sed_n(k)) *odzq*orho
         rc(k) = MAX(R1, rc(k) + (sed_c(k+1)-sed_c(k)) *odzq*DT)
         nc(k) = MAX(10., nc(k) + (sed_n(k+1)-sed_n(k)) *odzq*DT)
      enddo
      endif

!+---+-----------------------------------------------------------------+

      if (ANY(L_qi(kts:kte))) then
      nstep = NINT(1./onstep(2))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_i(k) = vtik(k)*ri(k)
            sed_n(k) = vtnik(k)*ni(k)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./rho(k)
         qiten(k) = qiten(k) - sed_i(k)*odzq*onstep(2)*orho
         niten(k) = niten(k) - sed_n(k)*odzq*onstep(2)*orho
         ri(k) = MAX(R1, ri(k) - sed_i(k)*odzq*DT*onstep(2))
         ni(k) = MAX(R2, ni(k) - sed_n(k)*odzq*DT*onstep(2))
         do k = ksed1(2), kts, -1
            odzq = 1./dzq(k)
            orho = 1./rho(k)
            qiten(k) = qiten(k) + (sed_i(k+1)-sed_i(k))                 &
                                               *odzq*onstep(2)*orho
            niten(k) = niten(k) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(2)*orho
            ri(k) = MAX(R1, ri(k) + (sed_i(k+1)-sed_i(k)) &
                                           *odzq*DT*onstep(2))
            ni(k) = MAX(R2, ni(k) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(2))
         enddo

         if (ri(kts).gt.R1*1000.) &
         pptice = pptice + sed_i(kts)*DT*onstep(2)
      enddo
      endif

!+---+-----------------------------------------------------------------+

      if (ANY(L_qs(kts:kte))) then
      nstep = NINT(1./onstep(3))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_s(k) = vtsk(k)*rs(k)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./rho(k)
         qsten(k) = qsten(k) - sed_s(k)*odzq*onstep(3)*orho
         rs(k) = MAX(R1, rs(k) - sed_s(k)*odzq*DT*onstep(3))
         do k = ksed1(3), kts, -1
            odzq = 1./dzq(k)
            orho = 1./rho(k)
            qsten(k) = qsten(k) + (sed_s(k+1)-sed_s(k))                 &
                                               *odzq*onstep(3)*orho
            rs(k) = MAX(R1, rs(k) + (sed_s(k+1)-sed_s(k)) &
                                           *odzq*DT*onstep(3))
         enddo

         if (rs(kts).gt.R1*1000.) &
         pptsnow = pptsnow + sed_s(kts)*DT*onstep(3)
      enddo
      endif

!+---+-----------------------------------------------------------------+

      if (ANY(L_qg(kts:kte))) then
      nstep = NINT(1./onstep(4))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_g(k) = vtgk(k)*rg(k)
            sed_n(k) = vtngk(k)*ng(k)
            sed_b(k) = vtgk(k)*rb(k)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./rho(k)
         qgten(k) = qgten(k) - sed_g(k)*odzq*onstep(4)*orho
         ngten(k) = ngten(k) - sed_n(k)*odzq*onstep(4)*orho
         qbten(k) = qbten(k) - sed_b(k)*odzq*onstep(4)
         rg(k) = MAX(R1, rg(k) - sed_g(k)*odzq*DT*onstep(4))
         ng(k) = MAX(R2, ng(k) - sed_n(k)*odzq*DT*onstep(4))
         rb(k) = MAX(R1/rho(k)/rho_g(NRHG), rb(k) - sed_b(k)*odzq*DT*onstep(4))
         do k = ksed1(4), kts, -1
            odzq = 1./dzq(k)
            orho = 1./rho(k)
            qgten(k) = qgten(k) + (sed_g(k+1)-sed_g(k))                 &
                                               *odzq*onstep(4)*orho
            ngten(k) = ngten(k) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(4)*orho
            qbten(k) = qbten(k) + (sed_b(k+1)-sed_b(k))                 &
                                               *odzq*onstep(4)
            rg(k) = MAX(R1, rg(k) + (sed_g(k+1)-sed_g(k)) &
                                           *odzq*DT*onstep(4))
            ng(k) = MAX(R2, ng(k) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(4))
            rb(k) = MAX(rg(k)/rho(k)/rho_g(NRHG), rb(k) + (sed_b(k+1)-sed_b(k))  &
                                           *odzq*DT*onstep(4))
         enddo

         if (rg(kts).gt.R1*1000.) &
         pptgraul = pptgraul + sed_g(kts)*DT*onstep(4)
      enddo
      endif

!+---+-----------------------------------------------------------------+
!.. Instantly melt any cloud ice into cloud water if above 0C and
!.. instantly freeze any cloud water found below HGFR.
!+---+-----------------------------------------------------------------+
      if (.not. iiwarm) then
      do k = kts, kte
         xri = MAX(0.0, qi1d(k) + qiten(k)*DT)
         if ( (temp(k).gt. T_0) .and. (xri.gt. 0.0) ) then
          qcten(k) = qcten(k) + xri*odt
          ncten(k) = ncten(k) + ni1d(k)*odt
          qiten(k) = qiten(k) - xri*odt
          niten(k) = -ni1d(k)*odt
          tten(k) = tten(k) - lfus*ocp(k)*xri*odt*(1-IFDRY)
         endif

         xrc = MAX(0.0, qc1d(k) + qcten(k)*DT)
         if ( (temp(k).lt. HGFR) .and. (xrc.gt. 0.0) ) then
          lfus2 = lsub - lvap(k)
          xnc = nc1d(k) + ncten(k)*DT
          qiten(k) = qiten(k) + xrc*odt
          niten(k) = niten(k) + xnc*odt
          qcten(k) = qcten(k) - xrc*odt
          ncten(k) = ncten(k) - xnc*odt
          tten(k) = tten(k) + lfus2*ocp(k)*xrc*odt*(1-IFDRY)
         endif
      enddo
      endif

!+---+-----------------------------------------------------------------+
!.. All tendencies computed, apply and pass back final values to parent.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         t1d(k)  = t1d(k) + tten(k)*DT
         qv1d(k) = MAX(1.E-10, qv1d(k) + qvten(k)*DT)
         qc1d(k) = qc1d(k) + qcten(k)*DT
         nc1d(k) = MAX(2./rho(k), MIN(nc1d(k) + ncten(k)*DT, Nt_c_max))
         if (is_aerosol_aware) then
            if (aer_init_opt .lt. 2) then
               nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                             (nwfa1d(k)+nwfaten(k)*DT)))
               nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                             (nifa1d(k)+nifaten(k)*DT)))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                        &
                                (nbca1d(k)+nbcaten(k)*DT)))
               else
                  nbca1d(k) = 0.0
               endif
            else
               nwfa1d(k) = MAX(0.0, (nwfa1d(k)+nwfaten(k)*DT))
               nifa1d(k) = MAX(0.0, (nifa1d(k)+nifaten(k)*DT))
               if (wif_input_opt .eq. 2) then
                  nbca1d(k) = MAX(0.0, (nbca1d(k)+nbcaten(k)*DT))
               else
                  nbca1d(k) = 0.0
               endif
            endif
         else
            nwfa1d(k) = MAX(11.1E6, MIN(9999.E6,                           &
                          (nwfa1d(k)+nwfaten(k)*DT)))
            nifa1d(k) = MAX(naIN1*0.01, MIN(9999.E6,                       &
                          (nifa1d(k)+nifaten(k)*DT)))
            nbca1d(k) = MAX(5.55E6, MIN(9999.E6,                           &
                          (nbca1d(k)+nbcaten(k)*DT)))
         endif

         if (qc1d(k) .le. R1) then
           qc1d(k) = 0.0
           nc1d(k) = 0.0
         else
           nu_c = MIN(15, NINT(1000.E6/(nc1d(k)*rho(k))) + 2)
           lamc = (am_r*ccg(2,nu_c)*ocg1(nu_c)*nc1d(k)/qc1d(k))**obmr
           xDc = (bm_r + nu_c + 1.) / lamc
           if (xDc.lt. D0c) then
            lamc = cce(2,nu_c)/D0c
           elseif (xDc.gt. D0r*2.) then
            lamc = cce(2,nu_c)/(D0r*2.)
           endif
           nc1d(k) = MIN(ccg(1,nu_c)*ocg2(nu_c)*qc1d(k)/am_r*lamc**bm_r,&
                         DBLE(Nt_c_max)/rho(k))
         endif

         qi1d(k) = qi1d(k) + qiten(k)*DT
         ni1d(k) = MAX(R2/rho(k), ni1d(k) + niten(k)*DT)
         if (qi1d(k) .le. R1) then
           qi1d(k) = 0.0
           ni1d(k) = 0.0
         else
           lami = (am_i*cig(2)*oig1*ni1d(k)/qi1d(k))**obmi
           ilami = 1./lami
           xDi = (bm_i + mu_i + 1.) * ilami
           if (xDi.lt. 5.E-6) then
            lami = cie(2)/5.E-6
           elseif (xDi.gt. 300.E-6) then
            lami = cie(2)/300.E-6
           endif
           ni1d(k) = MIN(cig(1)*oig2*qi1d(k)/am_i*lami**bm_i,           &
                         999.D3/rho(k))
         endif
         qr1d(k) = qr1d(k) + qrten(k)*DT
         nr1d(k) = MAX(R2/rho(k), nr1d(k) + nrten(k)*DT)
         if (qr1d(k) .le. R1) then
           qr1d(k) = 0.0
           nr1d(k) = 0.0
         else
           lamr = (am_r*crg(3)*org2*nr1d(k)/qr1d(k))**obmr
           mvd_r(k) = (3.0 + mu_r + 0.672) / lamr
           if (mvd_r(k) .gt. 2.5E-3) then
              mvd_r(k) = 2.5E-3
           elseif (mvd_r(k) .lt. D0r*0.75) then
              mvd_r(k) = D0r*0.75
           endif
           lamr = (3.0 + mu_r + 0.672) / mvd_r(k)
           nr1d(k) = crg(2)*org3*qr1d(k)*lamr**bm_r / am_r
         endif
         qs1d(k) = qs1d(k) + qsten(k)*DT
         if (qs1d(k) .le. R1) qs1d(k) = 0.0
         qg1d(k) = qg1d(k) + qgten(k)*DT
         ng1d(k) = MAX(R2/rho(k), ng1d(k) + ngten(k)*DT)
         if (qg1d(k) .le. R1) then
           qg1d(k) = 0.0
           ng1d(k) = 0.0
           qb1d(k) = 0.0
         else
           qb1d(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k) + qbten(k)*DT)
           qb1d(k) = MIN(qg1d(k)/rho_g(1), qb1d(k))
           idx_bg(k) = MAX(1,MIN(NINT(qg1d(k)/qb1d(k) *0.01)+1,NRHG))
           if (.not. is_hail_aware) idx_bg(k) = idx_bg1
           lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng1d(k)/qg1d(k))**obmg
           mvd_g(k) = (3.0 + mu_g + 0.672) / lamg
           if (mvd_g(k) .gt. 25.4E-3) then
              mvd_g(k) = 25.4E-3
           elseif (mvd_g(k) .lt. D0r) then
              mvd_g(k) = D0r
           endif
           lamg = (3.0 + mu_g + 0.672) / mvd_g(k)
           ng1d(k) = cgg(2,1)*ogg3*qg1d(k)*lamg**bm_g / am_g(idx_bg(k))
         endif

      enddo

      end subroutine mp_thompson
#ifdef WRF_GPU
      subroutine thlev_alloc(ni, nk, nj)
      implicit none
      INTEGER, INTENT(IN):: ni, nk, nj
      IF ( ni == thbsz_ni .AND. nk == thbsz_nk .AND. nj == thbsz_nj ) RETURN
!$acc wait
      IF ( ALLOCATED(thb_tten) ) DEALLOCATE(thb_tten)
      IF ( ALLOCATED(thb_qvten) ) DEALLOCATE(thb_qvten)
      IF ( ALLOCATED(thb_qcten) ) DEALLOCATE(thb_qcten)
      IF ( ALLOCATED(thb_qiten) ) DEALLOCATE(thb_qiten)
      IF ( ALLOCATED(thb_qrten) ) DEALLOCATE(thb_qrten)
      IF ( ALLOCATED(thb_qsten) ) DEALLOCATE(thb_qsten)
      IF ( ALLOCATED(thb_qgten) ) DEALLOCATE(thb_qgten)
      IF ( ALLOCATED(thb_qbten) ) DEALLOCATE(thb_qbten)
      IF ( ALLOCATED(thb_niten) ) DEALLOCATE(thb_niten)
      IF ( ALLOCATED(thb_nrten) ) DEALLOCATE(thb_nrten)
      IF ( ALLOCATED(thb_ncten) ) DEALLOCATE(thb_ncten)
      IF ( ALLOCATED(thb_ngten) ) DEALLOCATE(thb_ngten)
      IF ( ALLOCATED(thb_nwfaten) ) DEALLOCATE(thb_nwfaten)
      IF ( ALLOCATED(thb_nifaten) ) DEALLOCATE(thb_nifaten)
      IF ( ALLOCATED(thb_nbcaten) ) DEALLOCATE(thb_nbcaten)
      IF ( ALLOCATED(thb_prr_sml) ) DEALLOCATE(thb_prr_sml)
      IF ( ALLOCATED(thb_temp) ) DEALLOCATE(thb_temp)
      IF ( ALLOCATED(thb_rc) ) DEALLOCATE(thb_rc)
      IF ( ALLOCATED(thb_ri) ) DEALLOCATE(thb_ri)
      IF ( ALLOCATED(thb_rr) ) DEALLOCATE(thb_rr)
      IF ( ALLOCATED(thb_rs) ) DEALLOCATE(thb_rs)
      IF ( ALLOCATED(thb_rg) ) DEALLOCATE(thb_rg)
      IF ( ALLOCATED(thb_rb) ) DEALLOCATE(thb_rb)
      IF ( ALLOCATED(thb_ni) ) DEALLOCATE(thb_ni)
      IF ( ALLOCATED(thb_nr) ) DEALLOCATE(thb_nr)
      IF ( ALLOCATED(thb_nc) ) DEALLOCATE(thb_nc)
      IF ( ALLOCATED(thb_ng) ) DEALLOCATE(thb_ng)
      IF ( ALLOCATED(thb_rho) ) DEALLOCATE(thb_rho)
      IF ( ALLOCATED(thb_rhof) ) DEALLOCATE(thb_rhof)
      IF ( ALLOCATED(thb_visco) ) DEALLOCATE(thb_visco)
      IF ( ALLOCATED(thb_lvap) ) DEALLOCATE(thb_lvap)
      IF ( ALLOCATED(thb_ocp) ) DEALLOCATE(thb_ocp)
      IF ( ALLOCATED(thb_ilamg) ) DEALLOCATE(thb_ilamg)
      IF ( ALLOCATED(thb_mvd_r) ) DEALLOCATE(thb_mvd_r)
      IF ( ALLOCATED(thb_mvd_g) ) DEALLOCATE(thb_mvd_g)
      IF ( ALLOCATED(thb_smob) ) DEALLOCATE(thb_smob)
      IF ( ALLOCATED(thb_smoc) ) DEALLOCATE(thb_smoc)
      IF ( ALLOCATED(thb_vts_boost) ) DEALLOCATE(thb_vts_boost)
      IF ( ALLOCATED(thb_idx_bg) ) DEALLOCATE(thb_idx_bg)
      IF ( ALLOCATED(thb_l_qc) ) DEALLOCATE(thb_l_qc)
      IF ( ALLOCATED(thb_l_qi) ) DEALLOCATE(thb_l_qi)
      IF ( ALLOCATED(thb_l_qr) ) DEALLOCATE(thb_l_qr)
      IF ( ALLOCATED(thb_l_qs) ) DEALLOCATE(thb_l_qs)
      IF ( ALLOCATED(thb_l_qg) ) DEALLOCATE(thb_l_qg)
      IF ( ALLOCATED(thb_qv1d) ) DEALLOCATE(thb_qv1d)
      IF ( ALLOCATED(thb_qc1d) ) DEALLOCATE(thb_qc1d)
      IF ( ALLOCATED(thb_qi1d) ) DEALLOCATE(thb_qi1d)
      IF ( ALLOCATED(thb_qr1d) ) DEALLOCATE(thb_qr1d)
      IF ( ALLOCATED(thb_qs1d) ) DEALLOCATE(thb_qs1d)
      IF ( ALLOCATED(thb_qg1d) ) DEALLOCATE(thb_qg1d)
      IF ( ALLOCATED(thb_qb1d) ) DEALLOCATE(thb_qb1d)
      IF ( ALLOCATED(thb_ni1d) ) DEALLOCATE(thb_ni1d)
      IF ( ALLOCATED(thb_nr1d) ) DEALLOCATE(thb_nr1d)
      IF ( ALLOCATED(thb_nc1d) ) DEALLOCATE(thb_nc1d)
      IF ( ALLOCATED(thb_ng1d) ) DEALLOCATE(thb_ng1d)
      IF ( ALLOCATED(thb_nwfa1d) ) DEALLOCATE(thb_nwfa1d)
      IF ( ALLOCATED(thb_nifa1d) ) DEALLOCATE(thb_nifa1d)
      IF ( ALLOCATED(thb_nbca1d) ) DEALLOCATE(thb_nbca1d)
      IF ( ALLOCATED(thb_t1d) ) DEALLOCATE(thb_t1d)
      IF ( ALLOCATED(thb_w1d) ) DEALLOCATE(thb_w1d)
      IF ( ALLOCATED(thb_nm) ) DEALLOCATE(thb_nm)
      IF ( ALLOCATED(thb_km) ) DEALLOCATE(thb_km)
      IF ( ALLOCATED(thb_nmc) ) DEALLOCATE(thb_nmc)
      IF ( ALLOCATED(thb_kmc) ) DEALLOCATE(thb_kmc)
      ALLOCATE( thb_tten(ni,nk,nj) )
      ALLOCATE( thb_qvten(ni,nk,nj) )
      ALLOCATE( thb_qcten(ni,nk,nj) )
      ALLOCATE( thb_qiten(ni,nk,nj) )
      ALLOCATE( thb_qrten(ni,nk,nj) )
      ALLOCATE( thb_qsten(ni,nk,nj) )
      ALLOCATE( thb_qgten(ni,nk,nj) )
      ALLOCATE( thb_qbten(ni,nk,nj) )
      ALLOCATE( thb_niten(ni,nk,nj) )
      ALLOCATE( thb_nrten(ni,nk,nj) )
      ALLOCATE( thb_ncten(ni,nk,nj) )
      ALLOCATE( thb_ngten(ni,nk,nj) )
      ALLOCATE( thb_nwfaten(ni,nk,nj) )
      ALLOCATE( thb_nifaten(ni,nk,nj) )
      ALLOCATE( thb_nbcaten(ni,nk,nj) )
      ALLOCATE( thb_prr_sml(ni,nk,nj) )
      ALLOCATE( thb_temp(ni,nk,nj) )
      ALLOCATE( thb_rc(ni,nk,nj) )
      ALLOCATE( thb_ri(ni,nk,nj) )
      ALLOCATE( thb_rr(ni,nk,nj) )
      ALLOCATE( thb_rs(ni,nk,nj) )
      ALLOCATE( thb_rg(ni,nk,nj) )
      ALLOCATE( thb_rb(ni,nk,nj) )
      ALLOCATE( thb_ni(ni,nk,nj) )
      ALLOCATE( thb_nr(ni,nk,nj) )
      ALLOCATE( thb_nc(ni,nk,nj) )
      ALLOCATE( thb_ng(ni,nk,nj) )
      ALLOCATE( thb_rho(ni,nk,nj) )
      ALLOCATE( thb_rhof(ni,nk,nj) )
      ALLOCATE( thb_visco(ni,nk,nj) )
      ALLOCATE( thb_lvap(ni,nk,nj) )
      ALLOCATE( thb_ocp(ni,nk,nj) )
      ALLOCATE( thb_ilamg(ni,nk,nj) )
      ALLOCATE( thb_mvd_r(ni,nk,nj) )
      ALLOCATE( thb_mvd_g(ni,nk,nj) )
      ALLOCATE( thb_smob(ni,nk,nj) )
      ALLOCATE( thb_smoc(ni,nk,nj) )
      ALLOCATE( thb_vts_boost(ni,nk,nj) )
      ALLOCATE( thb_idx_bg(ni,nk,nj) )
      ALLOCATE( thb_l_qc(ni,nk,nj) )
      ALLOCATE( thb_l_qi(ni,nk,nj) )
      ALLOCATE( thb_l_qr(ni,nk,nj) )
      ALLOCATE( thb_l_qs(ni,nk,nj) )
      ALLOCATE( thb_l_qg(ni,nk,nj) )
      ALLOCATE( thb_qv1d(ni,nk,nj) )
      ALLOCATE( thb_qc1d(ni,nk,nj) )
      ALLOCATE( thb_qi1d(ni,nk,nj) )
      ALLOCATE( thb_qr1d(ni,nk,nj) )
      ALLOCATE( thb_qs1d(ni,nk,nj) )
      ALLOCATE( thb_qg1d(ni,nk,nj) )
      ALLOCATE( thb_qb1d(ni,nk,nj) )
      ALLOCATE( thb_ni1d(ni,nk,nj) )
      ALLOCATE( thb_nr1d(ni,nk,nj) )
      ALLOCATE( thb_nc1d(ni,nk,nj) )
      ALLOCATE( thb_ng1d(ni,nk,nj) )
      ALLOCATE( thb_nwfa1d(ni,nk,nj) )
      ALLOCATE( thb_nifa1d(ni,nk,nj) )
      ALLOCATE( thb_nbca1d(ni,nk,nj) )
      ALLOCATE( thb_t1d(ni,nk,nj) )
      ALLOCATE( thb_w1d(ni,nk,nj) )
      ALLOCATE( thb_nm(ni,nk,nj) )
      ALLOCATE( thb_km(ni,nk,nj) )
      ALLOCATE( thb_nmc(ni,nj), thb_kmc(ni,nj) )
      thbsz_ni = ni ; thbsz_nk = nk ; thbsz_nj = nj
      end subroutine thlev_alloc

!.. GPU (WRF_GPU_THLEV): one level of mp_thompson's per-level phase (generated by thgen.py from the
!.. loop bodies above; arrays indexed by k are scalars here). mode 1: prologue only -> no_micro and
!.. k_melting contributions; mode 2: whole phase with the column values no_micro_col / kmelt_col.
      subroutine thom_lev(mode, k, no_micro_col, kmelt_col, nm_out, km_out, &
                          aer_init_opt, wif_input_opt, qv1d, qc1d, qi1d, qr1d, &
                          qs1d, qg1d, qb1d, ni1d, nr1d, nc1d, &
                          ng1d, nwfa1d, nifa1d, nbca1d, t1d, p1d, &
                          w1d, dt, tten, qvten, qcten, qiten, &
                          qrten, qsten, qgten, qbten, niten, nrten, &
                          ncten, ngten, nwfaten, nifaten, nbcaten, prr_sml, &
                          temp, rc, ri, rr, rs, rg, &
                          rb, ni, nr, nc, ng, rho, &
                          rhof, visco, lvap, ocp, ilamg, mvd_r, &
                          mvd_g, smob, smoc, vts_boost, idx_bg, l_qc, &
                          l_qi, l_qr, l_qs, l_qg)
!$acc routine seq
      implicit none
      INTEGER, INTENT(IN):: mode, k, kmelt_col
      LOGICAL, INTENT(IN):: no_micro_col
      LOGICAL, INTENT(OUT):: nm_out
      INTEGER, INTENT(OUT):: km_out
      INTEGER:: thonce
      INTEGER, INTENT(IN):: aer_init_opt
      INTEGER, INTENT(IN):: wif_input_opt
      REAL, INTENT(INOUT):: qv1d
      REAL, INTENT(INOUT):: qc1d
      REAL, INTENT(INOUT):: qi1d
      REAL, INTENT(INOUT):: qr1d
      REAL, INTENT(INOUT):: qs1d
      REAL, INTENT(INOUT):: qg1d
      REAL, INTENT(INOUT):: qb1d
      REAL, INTENT(INOUT):: ni1d
      REAL, INTENT(INOUT):: nr1d
      REAL, INTENT(INOUT):: nc1d
      REAL, INTENT(INOUT):: ng1d
      REAL, INTENT(INOUT):: nwfa1d
      REAL, INTENT(INOUT):: nifa1d
      REAL, INTENT(INOUT):: nbca1d
      REAL, INTENT(INOUT):: t1d
      REAL, INTENT(INOUT):: p1d
      REAL, INTENT(INOUT):: w1d
      REAL, INTENT(IN):: dt
      REAL, INTENT(INOUT):: tten
      REAL, INTENT(INOUT):: qvten
      REAL, INTENT(INOUT):: qcten
      REAL, INTENT(INOUT):: qiten
      REAL, INTENT(INOUT):: qrten
      REAL, INTENT(INOUT):: qsten
      REAL, INTENT(INOUT):: qgten
      REAL, INTENT(INOUT):: qbten
      REAL, INTENT(INOUT):: niten
      REAL, INTENT(INOUT):: nrten
      REAL, INTENT(INOUT):: ncten
      REAL, INTENT(INOUT):: ngten
      REAL, INTENT(INOUT):: nwfaten
      REAL, INTENT(INOUT):: nifaten
      REAL, INTENT(INOUT):: nbcaten
      DOUBLE PRECISION, INTENT(INOUT):: prr_sml
      REAL, INTENT(INOUT):: temp
      REAL, INTENT(INOUT):: rc
      REAL, INTENT(INOUT):: ri
      REAL, INTENT(INOUT):: rr
      REAL, INTENT(INOUT):: rs
      REAL, INTENT(INOUT):: rg
      REAL, INTENT(INOUT):: rb
      REAL, INTENT(INOUT):: ni
      REAL, INTENT(INOUT):: nr
      REAL, INTENT(INOUT):: nc
      REAL, INTENT(INOUT):: ng
      REAL, INTENT(INOUT):: rho
      REAL, INTENT(INOUT):: rhof
      REAL, INTENT(INOUT):: visco
      REAL, INTENT(INOUT):: lvap
      REAL, INTENT(INOUT):: ocp
      DOUBLE PRECISION, INTENT(INOUT):: ilamg
      REAL, INTENT(INOUT):: mvd_r
      REAL, INTENT(INOUT):: mvd_g
      REAL, INTENT(INOUT):: smob
      REAL, INTENT(INOUT):: smoc
      REAL, INTENT(INOUT):: vts_boost
      INTEGER, INTENT(INOUT):: idx_bg
      LOGICAL, INTENT(INOUT):: l_qc
      LOGICAL, INTENT(INOUT):: l_qi
      LOGICAL, INTENT(INOUT):: l_qr
      LOGICAL, INTENT(INOUT):: l_qs
      LOGICAL, INTENT(INOUT):: l_qg
      DOUBLE PRECISION:: prw_vcd
      DOUBLE PRECISION:: pnc_wcd
      DOUBLE PRECISION:: prr_wau
      DOUBLE PRECISION:: prr_rcw
      DOUBLE PRECISION:: prr_gml
      DOUBLE PRECISION:: prv_rev
      DOUBLE PRECISION:: pnr_rev
      DOUBLE PRECISION:: pri_rci
      DOUBLE PRECISION:: prs_iau
      DOUBLE PRECISION:: prs_sci
      DOUBLE PRECISION:: prs_scw
      DOUBLE PRECISION:: prs_sde
      DOUBLE PRECISION:: prg_scw
      DOUBLE PRECISION:: prg_gde
      DOUBLE PRECISION:: prg_gcw
      DOUBLE PRECISION:: pnc_wau_s
      DOUBLE PRECISION:: pnc_rcw_s
      DOUBLE PRECISION:: pnc_scw_s
      DOUBLE PRECISION:: pnc_gcw_s
      DOUBLE PRECISION:: prr_rcs_s
      DOUBLE PRECISION:: prr_rcg_s
      DOUBLE PRECISION:: prr_rci_s
      DOUBLE PRECISION:: pnr_wau_s
      DOUBLE PRECISION:: pnr_rcs_s
      DOUBLE PRECISION:: pnr_rcg_s
      DOUBLE PRECISION:: pnr_rci_s
      DOUBLE PRECISION:: pnr_sml_s
      DOUBLE PRECISION:: pnr_gml_s
      DOUBLE PRECISION:: pnr_rcr_s
      DOUBLE PRECISION:: pnr_rfz_s
      DOUBLE PRECISION:: pri_inu_s
      DOUBLE PRECISION:: pni_inu_s
      DOUBLE PRECISION:: pri_ihm_s
      DOUBLE PRECISION:: pni_ihm_s
      DOUBLE PRECISION:: pri_wfz_s
      DOUBLE PRECISION:: pni_wfz_s
      DOUBLE PRECISION:: pri_rfz_s
      DOUBLE PRECISION:: pni_rfz_s
      DOUBLE PRECISION:: pri_ide_s
      DOUBLE PRECISION:: pni_ide_s
      DOUBLE PRECISION:: pni_rci_s
      DOUBLE PRECISION:: pni_sci_s
      DOUBLE PRECISION:: pni_iau_s
      DOUBLE PRECISION:: pri_iha_s
      DOUBLE PRECISION:: pni_iha_s
      DOUBLE PRECISION:: prs_rcs_s
      DOUBLE PRECISION:: prs_ihm_s
      DOUBLE PRECISION:: prs_ide_s
      DOUBLE PRECISION:: prg_rfz_s
      DOUBLE PRECISION:: prg_rci_s
      DOUBLE PRECISION:: prg_rcs_s
      DOUBLE PRECISION:: prg_rcg_s
      DOUBLE PRECISION:: prg_ihm_s
      DOUBLE PRECISION:: png_scw_s
      DOUBLE PRECISION:: png_rcs_s
      DOUBLE PRECISION:: png_rcg_s
      DOUBLE PRECISION:: png_gde_s
      DOUBLE PRECISION:: pbg_scw_s
      DOUBLE PRECISION:: pbg_rfz_s
      DOUBLE PRECISION:: pbg_gcw_s
      DOUBLE PRECISION:: pbg_rci_s
      DOUBLE PRECISION:: pbg_rcs_s
      DOUBLE PRECISION:: pbg_rcg_s
      DOUBLE PRECISION:: pbg_sml_s
      DOUBLE PRECISION:: pbg_gml_s
      DOUBLE PRECISION:: pna_rca_s
      DOUBLE PRECISION:: pna_sca_s
      DOUBLE PRECISION:: pna_gca_s
      DOUBLE PRECISION:: pnd_rcd_s
      DOUBLE PRECISION:: pnd_scd_s
      DOUBLE PRECISION:: pnd_gcd_s
      DOUBLE PRECISION:: pnb_rcb_s
      DOUBLE PRECISION:: pnb_scb_s
      DOUBLE PRECISION:: pnb_gcb_s
      REAL:: pres
      REAL:: qv
      REAL:: ns
      REAL:: nwfa
      REAL:: nifa
      REAL:: nbca
      REAL:: rhof2
      REAL:: qvs
      REAL:: ssatw
      REAL:: diffu
      REAL:: vsc2
      REAL:: tcond
      REAL:: lvt2
      DOUBLE PRECISION:: ilamr
      DOUBLE PRECISION:: n0_r
      DOUBLE PRECISION:: n0_g
      DOUBLE PRECISION:: n0_melt
      REAL:: mvd_c
      REAL:: smo2
      REAL:: smo1
      REAL:: smo0
      REAL:: smod
      REAL:: smoe
      REAL:: smof
      REAL:: smog
      REAL:: orho
      REAL:: lfus2
      DOUBLE PRECISION:: n0_exp
      DOUBLE PRECISION:: lam_exp
      DOUBLE PRECISION:: lamc
      DOUBLE PRECISION:: lamr
      DOUBLE PRECISION:: lamg
      DOUBLE PRECISION:: lami
      DOUBLE PRECISION:: ilami
      REAL:: xdc
      REAL:: dc_b
      REAL:: dc_g
      REAL:: xdi
      REAL:: xds
      REAL:: xdg
      DOUBLE PRECISION:: dc_star
      REAL:: zeta1
      REAL:: zeta
      REAL:: taud
      REAL:: tau
      REAL:: stoke_g
      REAL:: vts
      REAL:: vtg
      REAL:: xrho_g
      REAL:: afall
      REAL:: vtg1
      REAL:: vtg2
      REAL:: bfall
      REAL:: m0
      REAL:: slam1
      REAL:: slam2
      REAL:: mrat
      REAL:: c_snow
      REAL:: a_
      REAL:: b_
      REAL:: loga_
      REAL:: tf
      REAL:: tempc
      REAL:: tc0
      REAL:: dew_t
      REAL:: tlcl
      REAL:: the
      REAL:: twet_k
      REAL:: tempc_s
      REAL:: rhof_s
      REAL:: rhof2_s
      REAL:: qvs_s
      REAL:: delqvs_s
      REAL:: qvsi_s
      REAL:: satw_s
      REAL:: sati_s
      REAL:: ssatw_s
      REAL:: ssati_s
      REAL:: diffu_s
      REAL:: visco_s
      REAL:: ocp_s
      REAL:: vsc2_s
      REAL:: lvap_s
      REAL:: tcond_s
      REAL:: xnc
      REAL:: xri
      REAL:: xni
      REAL:: xmi
      REAL:: oxmi
      REAL:: xrc
      REAL:: xrr
      REAL:: xnr
      REAL:: xrg
      REAL:: xng
      REAL:: xrb
      REAL:: xsat
      REAL:: rate_max
      REAL:: sump
      REAL:: ratio
      REAL:: clap
      REAL:: fcd
      REAL:: dfcd
      REAL:: otemp
      REAL:: rvs
      REAL:: rvs_p
      REAL:: rvs_pp
      REAL:: gamsc
      REAL:: alphsc
      REAL:: t1_evap
      REAL:: t1_subl
      REAL:: r_frac
      REAL:: g_frac
      REAL:: const_ri
      REAL:: rime_dens
      REAL:: ef_rw
      REAL:: ef_sw
      REAL:: ef_gw
      REAL:: ef_rr
      REAL:: ef_ra
      REAL:: ef_sa
      REAL:: ef_ga
      REAL:: dtsave
      REAL:: odts
      REAL:: odt
      REAL:: ygra1
      REAL:: zans1
      REAL:: eva_factor
      REAL:: melt_f
      INTEGER:: n
      INTEGER:: nn
      INTEGER:: it
      INTEGER:: iexfrq
      INTEGER:: k_melting
      INTEGER:: nir
      INTEGER:: nis
      INTEGER:: nig
      INTEGER:: nii
      INTEGER:: nic
      INTEGER:: niin
      INTEGER:: idx_tc
      INTEGER:: idx_t
      INTEGER:: idx_s
      INTEGER:: idx_g1
      INTEGER:: idx_g
      INTEGER:: idx_r1
      INTEGER:: idx_r
      INTEGER:: idx_i1
      INTEGER:: idx_i
      INTEGER:: idx_c
      INTEGER:: idx
      INTEGER:: idx_d
      INTEGER:: idx_n
      INTEGER:: idx_in
      LOGICAL:: no_micro
      LOGICAL:: debug_flag
      INTEGER:: nu_c
      nm_out = .true.
      km_out = 0
      debug_flag = .false.
      if(debug_flag) then
      endif
      if (th_probe == 6) return
      no_micro = .true.
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1
      smo0 = 0.
      smo1 = 0.
      smo2 = 0.
      smob = 0.
      smoc = 0.
      smod = 0.
      smoe = 0.
      smof = 0.
      smog = 0.
      ns   = 0.
      mvd_r = 0.
      mvd_c = 0.
      temp = t1d
      qv = MAX(1.E-10, qv1d)
      pres = p1d
      rho = 0.622*pres/(R*temp*(qv+0.622))
      if (is_aerosol_aware) then
      if (aer_init_opt .lt. 2) then
      nwfa = MAX(11.1E6, MIN(9999.E6, nwfa1d*rho))
      nifa = MAX(naIN1*0.01, MIN(9999.E6, nifa1d*rho))
      if (wif_input_opt .eq. 2) then
      nbca = MAX(5.55E6, MIN(9999.E6, nbca1d*rho))
      else
      nbca = 0.0
      endif
      else
      nwfa = MAX(0.0, nwfa1d*rho)
      nifa = MAX(0.0, nifa1d*rho)
      if (wif_input_opt .eq. 2) then
      nbca = MAX(0.0, nbca1d*rho)
      else
      nbca = 0.0
      endif
      endif
      else
      nwfa = MAX(11.1E6, MIN(9999.E6, nwfa1d*rho))
      nifa = MAX(naIN1*0.01, MIN(9999.E6, nifa1d*rho))
      nbca = MAX(5.55E6, MIN(9999.E6, nbca1d*rho))
      endif
      if (qc1d .gt. R1) then
      no_micro = .false.
      rc = qc1d*rho
      nc = MAX(2., MIN(nc1d*rho, Nt_c_max))
      L_qc = .true.
      nu_c = MIN(15, NINT(1000.E6/nc) + 2)
      lamc = (nc*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc)**obmr
      xDc = (bm_r + nu_c + 1.) / lamc
      if (xDc.lt. D0c) then
      lamc = cce(2,nu_c)/D0c
      elseif (xDc.gt. D0r*2.) then
      lamc = cce(2,nu_c)/(D0r*2.)
      endif
      nc = MIN( DBLE(Nt_c_max), ccg(1,nu_c)*ocg2(nu_c)*rc    / am_r*lamc**bm_r)
      if (.NOT. is_aerosol_aware) nc = Nt_c
      else
      qc1d = 0.0
      nc1d = 0.0
      rc = R1
      nc = 2.
      L_qc = .false.
      endif
      if (qi1d .gt. R1) then
      no_micro = .false.
      ri = qi1d*rho
      ni = MAX(R2, ni1d*rho)
      if (ni.le. R2) then
      lami = cie(2)/5.E-6
      ni = MIN(999.D3, cig(1)*oig2*ri/am_i*lami**bm_i)
      endif
      L_qi = .true.
      lami = (am_i*cig(2)*oig1*ni/ri)**obmi
      ilami = 1./lami
      xDi = (bm_i + mu_i + 1.) * ilami
      if (xDi.lt. 5.E-6) then
      lami = cie(2)/5.E-6
      ni = MIN(999.D3, cig(1)*oig2*ri/am_i*lami**bm_i)
      elseif (xDi.gt. 300.E-6) then
      lami = cie(2)/300.E-6
      ni = cig(1)*oig2*ri/am_i*lami**bm_i
      endif
      else
      qi1d = 0.0
      ni1d = 0.0
      ri = R1
      ni = R2
      L_qi = .false.
      endif
      if (qr1d .gt. R1) then
      no_micro = .false.
      rr = qr1d*rho
      nr = MAX(R2, nr1d*rho)
      if (nr.le. R2) then
      mvd_r = 1.0E-3
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      nr = crg(2)*org3*rr*lamr**bm_r / am_r
      endif
      L_qr = .true.
      lamr = (am_r*crg(3)*org2*nr/rr)**obmr
      mvd_r = (3.0 + mu_r + 0.672) / lamr
      if (mvd_r .gt. 2.5E-3) then
      mvd_r = 2.5E-3
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      nr = crg(2)*org3*rr*lamr**bm_r / am_r
      elseif (mvd_r .lt. D0r*0.75) then
      mvd_r = D0r*0.75
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      nr = crg(2)*org3*rr*lamr**bm_r / am_r
      endif
      else
      qr1d = 0.0
      nr1d = 0.0
      rr = R1
      nr = R2
      L_qr = .false.
      endif
      if (qs1d .gt. R1) then
      no_micro = .false.
      rs = qs1d*rho
      L_qs = .true.
      else
      qs1d = 0.0
      rs = R1
      L_qs = .false.
      endif
      if (qg1d .gt. R1) then
      no_micro = .false.
      L_qg = .true.
      rg = qg1d*rho
      ng = MAX(R2, ng1d*rho)
      rb = MAX(qg1d/rho_g(NRHG), qb1d)
      rb = MIN(qg1d/rho_g(1), rb)
      qb1d = rb
      idx_bg = MAX(1,MIN(NINT(qg1d/rb *0.01)+1,NRHG))
      if (ng.le. R2) then
      mvd_g = 1.5E-3
      lamg = (3.0 + mu_g + 0.672) / mvd_g
      ng = cgg(2,1)*ogg3*rg*lamg**bm_g / am_g(idx_bg)
      endif
      lamg = (am_g(idx_bg)*cgg(3,1)*ogg2*ng/rg)**obmg
      mvd_g = (3.0 + mu_g + 0.672) / lamg
      if (mvd_g .gt. 25.4E-3) then
      mvd_g = 25.4E-3
      lamg = (3.0 + mu_g + 0.672) / mvd_g
      ng = cgg(2,1)*ogg3*rg*lamg**bm_g / am_g(idx_bg)
      elseif (mvd_g .lt. D0r) then
      mvd_g = D0r
      lamg = (3.0 + mu_g + 0.672) / mvd_g
      ng = cgg(2,1)*ogg3*rg*lamg**bm_g / am_g(idx_bg)
      endif
      else
      qg1d = 0.0
      ng1d = 0.0
      qb1d = 0.0
      idx_bg = idx_bg1
      rg = R1
      ng = R2
      rb = R1/rho/rho_g(NRHG)
      L_qg = .false.
      endif
      if (.not. is_hail_aware) idx_bg = idx_bg1
      k_melting = 0
      tempc = temp - 273.15
      if (tempc .le. 0.0) then
      qvsi_s = rsif(pres, temp)
      else
      qvsi_s = rslf(pres, temp)
      k_melting = MAX(k, k_melting)
      endif
      sati_s = qv/qvsi_s
      ssati_s = sati_s - 1.
      if (abs(ssati_s).lt. eps) ssati_s = 0.0
      if (no_micro .and. ssati_s.gt. 0.0) no_micro = .false.
      if (mode == 1) then
      nm_out = no_micro
      km_out = k_melting
      return
      endif
      no_micro = no_micro_col
      k_melting = kmelt_col
      if (no_micro) return
      if (th_probe == 1) return
      tten = 0.
      qvten = 0.
      qcten = 0.
      qiten = 0.
      qrten = 0.
      qsten = 0.
      qgten = 0.
      ngten = 0.
      qbten = 0.
      niten = 0.
      nrten = 0.
      ncten = 0.
      nwfaten = 0.
      nifaten = 0.
      nbcaten = 0.
      prw_vcd = 0.
      pnc_wcd = 0.
      prv_rev = 0.
      prr_wau = 0.
      prr_rcw = 0.
      prr_sml = 0.
      prr_gml = 0.
      pnr_rev = 0.
      pri_rci = 0.
      prs_iau = 0.
      prs_sci = 0.
      prs_scw = 0.
      prs_sde = 0.
      prg_scw = 0.
      prg_gde = 0.
      prg_gcw = 0.
      if (.not. iiwarm) then
      do thonce = 1, 1
      if (.not. L_qs) CYCLE
      tc0 = MIN(-0.1, temp-273.15)
      smob = rs*oams
      if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
      smo2 = smob
      else
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s  + sa(4)*tc0*bm_s + sa(5)*tc0*tc0  + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s  + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0  + sa(10)*bm_s*bm_s*bm_s
      a_ = 10.0**loga_
      b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s  + sb(4)*tc0*bm_s + sb(5)*tc0*tc0  + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s  + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0  + sb(10)*bm_s*bm_s*bm_s
      smo2 = (smob/a_)**(1./b_)
      endif
      loga_ = sa(1) + sa(2)*tc0 + sa(5)*tc0*tc0 + sa(9)*tc0*tc0*tc0
      a_ = 10.0**loga_
      b_ = sb(1) + sb(2)*tc0 + sb(5)*tc0*tc0 + sb(9)*tc0*tc0*tc0
      smo0 = a_ * smo2**b_
      loga_ = sa(1) + sa(2)*tc0 + sa(3)  + sa(4)*tc0 + sa(5)*tc0*tc0  + sa(6) + sa(7)*tc0*tc0  + sa(8)*tc0 + sa(9)*tc0*tc0*tc0  + sa(10)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3) + sb(4)*tc0  + sb(5)*tc0*tc0 + sb(6)  + sb(7)*tc0*tc0 + sb(8)*tc0  + sb(9)*tc0*tc0*tc0 + sb(10)
      smo1 = a_ * smo2**b_
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1)  + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0  + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1)  + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(1)*cse(1)*cse(1)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1)  + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1)  + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
      smoc = a_ * smo2**b_
      M0 = smob/smoc
      Mrat = smob*M0*M0*M0
      slam1 = M0 * Lam0
      slam2 = M0 * Lam1
      ns = Mrat*Kap0/slam1                                         + Mrat*Kap1*M0**mu_s*csg(15)/slam2**cse(15)
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(13)  + sa(4)*tc0*cse(13) + sa(5)*tc0*tc0  + sa(6)*cse(13)*cse(13) + sa(7)*tc0*tc0*cse(13)  + sa(8)*tc0*cse(13)*cse(13) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(13)*cse(13)*cse(13)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(13) + sb(4)*tc0*cse(13)  + sb(5)*tc0*tc0 + sb(6)*cse(13)*cse(13)  + sb(7)*tc0*tc0*cse(13) + sb(8)*tc0*cse(13)*cse(13)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(13)*cse(13)*cse(13)
      smoe = a_ * smo2**b_
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(16)  + sa(4)*tc0*cse(16) + sa(5)*tc0*tc0  + sa(6)*cse(16)*cse(16) + sa(7)*tc0*tc0*cse(16)  + sa(8)*tc0*cse(16)*cse(16) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(16)*cse(16)*cse(16)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(16) + sb(4)*tc0*cse(16)  + sb(5)*tc0*tc0 + sb(6)*cse(16)*cse(16)  + sb(7)*tc0*tc0*cse(16) + sb(8)*tc0*cse(16)*cse(16)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(16)*cse(16)*cse(16)
      smof = a_ * smo2**b_
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(17)  + sa(4)*tc0*cse(17) + sa(5)*tc0*tc0  + sa(6)*cse(17)*cse(17) + sa(7)*tc0*tc0*cse(17)  + sa(8)*tc0*cse(17)*cse(17) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(17)*cse(17)*cse(17)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(17) + sb(4)*tc0*cse(17)  + sb(5)*tc0*tc0 + sb(6)*cse(17)*cse(17)  + sb(7)*tc0*tc0*cse(17) + sb(8)*tc0*cse(17)*cse(17)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(17)*cse(17)*cse(17)
      smog = a_ * smo2**b_
      enddo
      lamg = (am_g(idx_bg)*cgg(3,1)*ogg2*ng/rg)**obmg
      ilamg = 1./lamg
      N0_g = ng*ogg2*lamg**cge(2,1)
      endif
      lamr = (am_r*crg(3)*org2*nr/rr)**obmr
      ilamr = 1./lamr
      mvd_r = (3.0 + mu_r + 0.672) / lamr
      N0_r = nr*org2*lamr**cre(2)
      tempc_s = temp - 273.15
      rhof_s = SQRT(RHO_NOT/rho)
      rhof2_s = SQRT(rhof_s)
      qvs_s = rslf(pres, temp)
      delQvs_s = MAX(0.0, rslf(pres, 273.15)-qv)
      if (tempc_s .le. 0.0) then
      qvsi_s = rsif(pres, temp)
      else
      qvsi_s = qvs_s
      endif
      satw_s = qv/qvs_s
      sati_s = qv/qvsi_s
      ssatw_s = satw_s - 1.
      ssati_s = sati_s - 1.
      if (abs(ssatw_s).lt. eps) ssatw_s = 0.0
      if (abs(ssati_s).lt. eps) ssati_s = 0.0
      diffu_s = 2.11E-5*(temp/273.15)**1.94 * (101325./pres)
      if (tempc_s .ge. 0.0) then
      visco_s = (1.718+0.0049*tempc_s)*1.0E-5
      else
      visco_s = (1.718+0.0049*tempc_s-1.2E-5*tempc_s*tempc_s)*1.0E-5
      endif
      ocp_s = 1./(Cp*(1.+0.887*qv))
      vsc2_s = SQRT(rho/visco_s)
      lvap_s = lvap0 + (2106.0 - 4218.0)*tempc_s
      tcond_s = (5.69 + 0.0168*tempc_s)*1.0E-5 * 418.936
      twet_k = temp
      if (k .le. k_melting) then
      if (satw_s .lt. 0.999 .and. (L_qs .or. L_qg)) then
      dew_t = MIN(temp-0.001, t_dew(pres, qv))
      Tlcl = t_lcl(temp, dew_t)
      The = theta_e(pres, temp, qv, Tlcl)
      twet_k = MIN(temp, compT_fr_The(The, pres))
      endif
      endif
      pnc_wau_s = 0.
      pnc_rcw_s = 0.
      pnc_scw_s = 0.
      pnc_gcw_s = 0.
      prr_rcs_s = 0.
      prr_rcg_s = 0.
      prr_rci_s = 0.
      pnr_wau_s = 0.
      pnr_rcs_s = 0.
      pnr_rcg_s = 0.
      pnr_rci_s = 0.
      pnr_sml_s = 0.
      pnr_gml_s = 0.
      pnr_rcr_s = 0.
      pnr_rfz_s = 0.
      pri_inu_s = 0.
      pni_inu_s = 0.
      pri_ihm_s = 0.
      pni_ihm_s = 0.
      pri_wfz_s = 0.
      pni_wfz_s = 0.
      pri_rfz_s = 0.
      pni_rfz_s = 0.
      pri_ide_s = 0.
      pni_ide_s = 0.
      pni_rci_s = 0.
      pni_sci_s = 0.
      pni_iau_s = 0.
      pri_iha_s = 0.
      pni_iha_s = 0.
      prs_rcs_s = 0.
      prs_ihm_s = 0.
      prs_ide_s = 0.
      prg_rfz_s = 0.
      prg_rci_s = 0.
      prg_rcs_s = 0.
      prg_rcg_s = 0.
      prg_ihm_s = 0.
      png_scw_s = 0.
      png_rcs_s = 0.
      png_rcg_s = 0.
      png_gde_s = 0.
      pbg_scw_s = 0.
      pbg_rfz_s = 0.
      pbg_gcw_s = 0.
      pbg_rci_s = 0.
      pbg_rcs_s = 0.
      pbg_rcg_s = 0.
      pbg_sml_s = 0.
      pbg_gml_s = 0.
      pna_rca_s = 0.
      pna_sca_s = 0.
      pna_gca_s = 0.
      pnd_rcd_s = 0.
      pnd_scd_s = 0.
      pnd_gcd_s = 0.
      pnb_rcb_s = 0.
      pnb_scb_s = 0.
      pnb_gcb_s = 0.
      if (L_qr .and. mvd_r.gt. D0r) then
      Ef_rr = 1.0 - EXP(2300.0*(mvd_r-1950.0E-6))
      pnr_rcr_s = Ef_rr * 2.0*nr*rr
      endif
      mvd_c = D0c
      if (L_qc) then
      nu_c = MIN(15, NINT(1000.E6/nc) + 2)
      xDc = MAX(D0c*1.E6, ((rc/(am_r*nc))**obmr) * 1.E6)
      lamc = (nc*am_r* ccg(2,nu_c) * ocg1(nu_c) / rc)**obmr
      mvd_c = (3.0+nu_c+0.672) / lamc
      mvd_c = MAX(D0c, MIN(mvd_c, D0r))
      endif
      if (rc.gt. 0.01e-3) then
      Dc_g = ((ccg(3,nu_c)*ocg2(nu_c))**obmr / lamc) * 1.E6
      Dc_b = (xDc*xDc*xDc*Dc_g*Dc_g*Dc_g - xDc*xDc*xDc*xDc*xDc*xDc)  **(1./6.)
      zeta1 = 0.5*((6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4)  + abs(6.25E-6*xDc*Dc_b*Dc_b*Dc_b - 0.4))
      zeta = 0.027*rc*zeta1
      taud = 0.5*((0.5*Dc_b - 7.5) + abs(0.5*Dc_b - 7.5)) + R1
      tau  = 3.72/(rc*taud)
      prr_wau = zeta/tau
      prr_wau = MIN(DBLE(rc*odts), prr_wau)
      pnr_wau_s = prr_wau / (am_r*nu_c*10.*D0r*D0r*D0r)
      pnc_wau_s = MIN(DBLE(nc*odts), prr_wau                  / (am_r*mvd_c*mvd_c*mvd_c))
      endif
      if (L_qr .and. mvd_r.gt. D0r .and. mvd_c.gt. D0c) then
      lamr = 1./ilamr
      idx = 1 + INT(nbr*DLOG(mvd_r/Dr(1))/DLOG(Dr(nbr)/Dr(1)))
      idx = MIN(idx, nbr)
      Ef_rw = t_Efrw(idx, INT(mvd_c*1.E6))
      prr_rcw = rhof_s*t1_qr_qc*Ef_rw*rc*N0_r  *((lamr+fv_r)**(-cre(9)))
      prr_rcw = MIN(DBLE(rc*odts), prr_rcw)
      pnc_rcw_s = rhof_s*t1_qr_qc*Ef_rw*nc*N0_r              *((lamr+fv_r)**(-cre(9)))
      pnc_rcw_s = MIN(DBLE(nc*odts), pnc_rcw_s)
      endif
      if (L_qr .and. mvd_r.gt. D0r) then
      Ef_ra = Eff_aero(mvd_r,0.04E-6,visco_s,rho,temp,'r')
      lamr = 1./ilamr
      pna_rca_s = rhof_s*t1_qr_qc*Ef_ra*nwfa*N0_r            *((lamr+fv_r)**(-cre(9)))
      pna_rca_s = MIN(DBLE(nwfa*odts), pna_rca_s)
      Ef_ra = Eff_aero(mvd_r,0.8E-6,visco_s,rho,temp,'r')
      pnd_rcd_s = rhof_s*t1_qr_qc*Ef_ra*nifa*N0_r            *((lamr+fv_r)**(-cre(9)))
      pnd_rcd_s = MIN(DBLE(nifa*odts), pnd_rcd_s)
      if (.true.) then
      if (wif_input_opt .eq. 2) then
      Ef_ra = Eff_aero(mvd_r,0.0236E-6,  visco_s,rho,temp,'r')
      pnb_rcb_s = rhof_s*t1_qr_qc*Ef_ra*nbca*N0_r        *((lamr+fv_r)**(-cre(9)))
      pnb_rcb_s = MIN(DBLE(nbca*odts), pnb_rcb_s)
      endif
      endif
      endif
      if (.not. iiwarm) then
      vts_boost = 1.0
      orho = 1./rho
      if (L_qs) then
      xDs = smoc / smob
      rho_s = MAX(rho_g(1), MIN(0.13/xDs, rho_i-100.))
      else
      xDs = 0.
      rho_s = 100.
      endif
      tempc = temp - 273.15
      idx_tc = MAX(1, MIN(NINT(-tempc), 45) )
      idx_t = INT( (tempc-2.5)/5. ) - 1
      idx_t = MAX(1, -idx_t)
      idx_t = MIN(idx_t, ntb_t)
      IT = MAX(1, MIN(NINT(-tempc), 31) )
      if (rc.gt. r_c(1)) then
      nic = NINT(ALOG10(rc))
      do nn = nic-1, nic+1
      n = nn
      if ( (rc/10.**nn).ge.1.0 .and.  (rc/10.**nn).lt.10.0) goto 141
      enddo
      141      continue
      idx_c = INT(rc/10.**n) + 10*(n-nic2) - (n-nic2)
      idx_c = MAX(1, MIN(idx_c, ntb_c))
      else
      idx_c = 1
      endif
      idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(nc/t_Nc(1)) / nic1)
      idx_n = MAX(1, MIN(idx_n, nbc))
      if (ri.gt. r_i(1)) then
      nii = NINT(ALOG10(ri))
      do nn = nii-1, nii+1
      n = nn
      if ( (ri/10.**nn).ge.1.0 .and.  (ri/10.**nn).lt.10.0) goto 142
      enddo
      142      continue
      idx_i = INT(ri/10.**n) + 10*(n-nii2) - (n-nii2)
      idx_i = MAX(1, MIN(idx_i, ntb_i))
      else
      idx_i = 1
      endif
      if (ni.gt. Nt_i(1)) then
      nii = NINT(ALOG10(ni))
      do nn = nii-1, nii+1
      n = nn
      if ( (ni/10.**nn).ge.1.0 .and.  (ni/10.**nn).lt.10.0) goto 143
      enddo
      143      continue
      idx_i1 = INT(ni/10.**n) + 10*(n-nii3) - (n-nii3)
      idx_i1 = MAX(1, MIN(idx_i1, ntb_i1))
      else
      idx_i1 = 1
      endif
      if (rr.gt. r_r(1)) then
      nir = NINT(ALOG10(rr))
      do nn = nir-1, nir+1
      n = nn
      if ( (rr/10.**nn).ge.1.0 .and.  (rr/10.**nn).lt.10.0) goto 144
      enddo
      144      continue
      idx_r = INT(rr/10.**n) + 10*(n-nir2) - (n-nir2)
      idx_r = MAX(1, MIN(idx_r, ntb_r))
      lamr = 1./ilamr
      lam_exp = lamr * (crg(3)*org2*org1)**bm_r
      N0_exp = org1*rr/am_r * lam_exp**cre(1)
      nir = NINT(DLOG10(N0_exp))
      do nn = nir-1, nir+1
      n = nn
      if ( (N0_exp/10.**nn).ge.1.0 .and.  (N0_exp/10.**nn).lt.10.0) goto 145
      enddo
      145      continue
      idx_r1 = INT(N0_exp/10.**n) + 10*(n-nir3) - (n-nir3)
      idx_r1 = MAX(1, MIN(idx_r1, ntb_r1))
      else
      idx_r = 1
      idx_r1 = ntb_r1
      endif
      if (rs.gt. r_s(1)) then
      nis = NINT(ALOG10(rs))
      do nn = nis-1, nis+1
      n = nn
      if ( (rs/10.**nn).ge.1.0 .and.  (rs/10.**nn).lt.10.0) goto 146
      enddo
      146      continue
      idx_s = INT(rs/10.**n) + 10*(n-nis2) - (n-nis2)
      idx_s = MAX(1, MIN(idx_s, ntb_s))
      else
      idx_s = 1
      endif
      if (rg.gt. r_g(1)) then
      nig = NINT(ALOG10(rg))
      do nn = nig-1, nig+1
      n = nn
      if ( (rg/10.**nn).ge.1.0 .and.  (rg/10.**nn).lt.10.0) goto 147
      enddo
      147      continue
      idx_g = INT(rg/10.**n) + 10*(n-nig2) - (n-nig2)
      idx_g = MAX(1, MIN(idx_g, ntb_g))
      lamg = 1./ilamg
      lam_exp = lamg * (cgg(3,1)*ogg2*ogg1)**bm_g
      N0_exp = ogg1*rg/am_g(idx_bg) * lam_exp**cge(1,1)
      nig = NINT(DLOG10(N0_exp))
      do nn = nig-1, nig+1
      n = nn
      if ( (N0_exp/10.**nn).ge.1.0 .and.  (N0_exp/10.**nn).lt.10.0) goto 148
      enddo
      148      continue
      idx_g1 = INT(N0_exp/10.**n) + 10*(n-nig3) - (n-nig3)
      idx_g1 = MAX(1, MIN(idx_g1, ntb_g1))
      else
      idx_g = 1
      idx_g1 = ntb_g1
      endif
      otemp = 1./temp
      rvs = rho*qvsi_s
      rvs_p = rvs*otemp*(lsub*otemp*oRv - 1.)
      rvs_pp = rvs * ( otemp*(lsub*otemp*oRv - 1.)  *otemp*(lsub*otemp*oRv - 1.)  + (-2.*lsub*otemp*otemp*otemp*oRv)  + otemp*otemp)
      gamsc = lsub*diffu_s/tcond_s * rvs_p
      alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc))  * rvs_pp/rvs_p * rvs/rvs_p
      alphsc = MAX(1.E-9, alphsc)
      xsat = ssati_s
      if (abs(xsat).lt. 1.E-9) xsat=0.
      t1_subl = 4.*PI*( 1.0 - alphsc*xsat  + 2.*alphsc*alphsc*xsat*xsat  - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat )  / (1.+gamsc)
      if (L_qc .and. mvd_c.gt. D0c) then
      if (xDs .gt. D0s) then
      idx = 1 + INT(nbs*DLOG(xDs/Ds(1))/DLOG(Ds(nbs)/Ds(1)))
      idx = MIN(idx, nbs)
      Ef_sw = t_Efsw(idx, INT(mvd_c*1.E6))
      prs_scw = rhof_s*t1_qs_qc*Ef_sw*rc*smoe
      prs_scw = MIN(DBLE(rc*odts), prs_scw)
      pnc_scw_s = rhof_s*t1_qs_qc*Ef_sw*nc*smoe
      pnc_scw_s = MIN(DBLE(nc*odts), pnc_scw_s)
      endif
      if (rg.ge. r_g(1) .and. mvd_c.gt. D0c) then
      xDg = (bm_g + mu_g + 1.) * ilamg
      vtg = rhof_s*av_g(idx_bg)*cgg(6,idx_bg)*ogg3 * ilamg**bv_g(idx_bg)
      stoke_g = mvd_c*mvd_c*vtg*rho_w/(9.*visco_s*xDg)
      const_Ri = -1.*(mvd_c*0.5E6)*vtg/MIN(-0.1,tempc)
      const_Ri = MAX(0.1, MIN(const_Ri, 10.))
      rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
      if (stoke_g.ge.0.4 .and. stoke_g.le.10.) then
      Ef_gw = 0.55*ALOG10(2.51*stoke_g)
      elseif (stoke_g.lt.0.4) then
      Ef_gw = 0.0
      elseif (stoke_g.gt.10) then
      Ef_gw = 0.77
      endif
      if (twet_k.gt.T_0) Ef_gw = Ef_gw*0.1
      t1_qg_qc = PI*.25*av_g(idx_bg) * cgg(9,idx_bg)
      prg_gcw = rhof_s*t1_qg_qc*Ef_gw*rc*N0_g  *ilamg**cge(9,idx_bg)
      pnc_gcw_s = rhof_s*t1_qg_qc*Ef_gw*nc*N0_g            *ilamg**cge(9,idx_bg)
      pnc_gcw_s = MIN(DBLE(nc*odts), pnc_gcw_s)
      if (twet_k.lt.T_0) pbg_gcw_s = prg_gcw/rime_dens
      endif
      endif
      if (rs .gt. r_s(1)) then
      Ef_sa = Eff_aero(xDs,0.04E-6,visco_s,rho,temp,'s')
      pna_sca_s = rhof_s*t1_qs_qc*Ef_sa*nwfa*smoe
      pna_sca_s = MIN(DBLE(nwfa*odts), pna_sca_s)
      Ef_sa = Eff_aero(xDs,0.8E-6,visco_s,rho,temp,'s')
      pnd_scd_s = rhof_s*t1_qs_qc*Ef_sa*nifa*smoe
      pnd_scd_s = MIN(DBLE(nifa*odts), pnd_scd_s)
      if (.true.) then
      if (wif_input_opt .eq. 2) then
      Ef_sa = Eff_aero(xDs,0.0236E-6,visco_s,rho,temp,'s')
      pnb_scb_s = rhof_s*t1_qs_qc*Ef_sa*nbca*smoe
      pnb_scb_s = MIN(DBLE(nbca*odts), pnb_scb_s)
      endif
      endif
      endif
      if (rg .gt. r_g(1)) then
      xDg = (bm_g + mu_g + 1.) * ilamg
      Ef_ga = Eff_aero(xDg,0.04E-6,visco_s,rho,temp,'g')
      t1_qg_qc = PI*.25*av_g(idx_bg) * cgg(9,idx_bg)
      pna_gca_s = rhof_s*t1_qg_qc*Ef_ga*nwfa*N0_g            *ilamg**cge(9,idx_bg)
      pna_gca_s = MIN(DBLE(nwfa*odts), pna_gca_s)
      Ef_ga = Eff_aero(xDg,0.8E-6,visco_s,rho,temp,'g')
      pnd_gcd_s = rhof_s*t1_qg_qc*Ef_ga*nifa*N0_g            *ilamg**cge(9,idx_bg)
      pnd_gcd_s = MIN(DBLE(nifa*odts), pnd_gcd_s)
      if (.true.) then
      if (wif_input_opt .eq. 2) then
      Ef_ga = Eff_aero(xDg,0.0236E-6,visco_s,rho,temp,'g')
      pnb_gcb_s = rhof_s*t1_qg_qc*Ef_ga*nbca*N0_g        *ilamg**cge(9,idx_bg)
      pnb_gcb_s = MIN(DBLE(nbca*odts), pnb_gcb_s)
      endif
      endif
      endif
      if (rr.ge. r_r(1)) then
      if (rs.ge. r_s(1)) then
      if (twet_k.lt.T_0) then
      prr_rcs_s = -(tmr_racs2(idx_s,idx_t,idx_r1,idx_r)  + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r)  + tmr_racs1(idx_s,idx_t,idx_r1,idx_r)  + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r))
      prs_rcs_s = tmr_racs2(idx_s,idx_t,idx_r1,idx_r)  + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r)  - tcs_racs1(idx_s,idx_t,idx_r1,idx_r)  - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
      prg_rcs_s = tmr_racs1(idx_s,idx_t,idx_r1,idx_r)  + tcr_sacr1(idx_s,idx_t,idx_r1,idx_r)  + tcs_racs1(idx_s,idx_t,idx_r1,idx_r)  + tms_sacr1(idx_s,idx_t,idx_r1,idx_r)
      prr_rcs_s = MAX(DBLE(-rr*odts), prr_rcs_s)
      prs_rcs_s = MAX(DBLE(-rs*odts), prs_rcs_s)
      prg_rcs_s = MIN(DBLE((rr+rs)*odts), prg_rcs_s)
      pnr_rcs_s = tnr_racs1(idx_s,idx_t,idx_r1,idx_r)             + tnr_racs2(idx_s,idx_t,idx_r1,idx_r)           + tnr_sacr1(idx_s,idx_t,idx_r1,idx_r)           + tnr_sacr2(idx_s,idx_t,idx_r1,idx_r)
      pnr_rcs_s = MIN(DBLE(nr*odts), pnr_rcs_s)
      png_rcs_s = pnr_rcs_s
      pbg_rcs_s = prg_rcs_s/rho_i
      else
      prs_rcs_s = -tcs_racs1(idx_s,idx_t,idx_r1,idx_r)            - tms_sacr1(idx_s,idx_t,idx_r1,idx_r)           + tmr_racs2(idx_s,idx_t,idx_r1,idx_r)           + tcr_sacr2(idx_s,idx_t,idx_r1,idx_r)
      prs_rcs_s = MAX(DBLE(-rs*odts), prs_rcs_s)
      prr_rcs_s = -prs_rcs_s
      endif
      endif
      if (rg.ge. r_g(1)) then
      if (twet_k.lt.T_0) then
      prg_rcg_s = tmr_racg(idx_g1,idx_g,idx_bg,idx_r1,idx_r)   + tcr_gacr(idx_g1,idx_g,idx_bg,idx_r1,idx_r)
      prg_rcg_s = MIN(DBLE(rr*odts), prg_rcg_s)
      prr_rcg_s = -prg_rcg_s
      pnr_rcg_s = tnr_racg(idx_g1,idx_g,idx_bg,idx_r1,idx_r)   + tnr_gacr(idx_g1,idx_g,idx_bg,idx_r1,idx_r)
      pnr_rcg_s = MIN(DBLE(nr*odts), pnr_rcg_s)
      pbg_rcg_s = prg_rcg_s/rho_i
      else
      prr_rcg_s = tcg_racg(idx_g1,idx_g,idx_bg,idx_r1,idx_r)
      prr_rcg_s = MIN(DBLE(rg*odts), prr_rcg_s)
      prg_rcg_s = -prr_rcg_s
      png_rcg_s = tnr_racg(idx_g1,idx_g,idx_bg,idx_r1,idx_r)
      png_rcg_s = MIN(DBLE(ng*odts), png_rcg_s)
      pbg_rcg_s = prg_rcg_s/rho_g(idx_bg)
      pnr_rcg_s = -1.5*tnr_gacr(idx_g1,idx_g,idx_bg,idx_r1,idx_r)
      endif
      endif
      endif
      if (temp.lt.T_0) then
      vts_boost = 1.0
      rate_max = (qv-qvsi_s)*rho*odts*0.999
      if (dustyIce .AND. is_aerosol_aware) then
      xni = iceDeMott(tempc,qvs_s,qvs_s,qvsi_s,rho,nifa)
      else
      xni = 1.0 *1000.
      endif
      if (xni.gt. Nt_IN(1)) then
      niin = NINT(ALOG10(xni))
      do nn = niin-1, niin+1
      n = nn
      if ( (xni/10.**nn).ge.1.0 .and.  (xni/10.**nn).lt.10.0) goto 149
      enddo
      149       continue
      idx_IN = INT(xni/10.**n) + 10*(n-niin2) - (n-niin2)
      idx_IN = MAX(1, MIN(idx_IN, ntb_IN))
      else
      idx_IN = 1
      endif
      if (rr.gt. r_r(1)) then
      prg_rfz_s = tpg_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
      pri_rfz_s = tpi_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
      pni_rfz_s = tni_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
      pnr_rfz_s = tnr_qrfz(idx_r,idx_r1,idx_tc,idx_IN)*odts
      pnr_rfz_s = MIN(DBLE(nr*odts), pnr_rfz_s)
      elseif (rr.gt. R1 .and. temp.lt.HGFR) then
      pri_rfz_s = rr*odts
      pni_rfz_s = nr*odts
      endif
      pbg_rfz_s = prg_rfz_s/rho_i
      if (rc.gt. r_c(1)) then
      pri_wfz_s = tpi_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
      pri_wfz_s = MIN(DBLE(rc*odts), pri_wfz_s)
      pni_wfz_s = tni_qcfz(idx_c,idx_n,idx_tc,idx_IN)*odts
      pni_wfz_s = MIN(DBLE(nc*odts), pri_wfz_s/(2.*xm0i),      pni_wfz_s)
      elseif (rc.gt. R1 .and. temp.lt.HGFR) then
      pri_wfz_s = rc*odts
      pni_wfz_s = nc*odts
      endif
      if ( (ssati_s.ge. 0.25) .or. (ssatw_s.gt. eps  .and. temp.lt.253.15) ) then
      if (dustyIce .AND. is_aerosol_aware) then
      xnc = iceDeMott(tempc,qv,qvs_s,qvsi_s,rho,nifa)
      else
      xnc = MIN(250.E3, TNO*EXP(ATO*(T_0-temp)))
      endif
      xni = ni + (pni_rfz_s+pni_wfz_s)*dtsave
      pni_inu_s = 0.5*(xnc-xni + abs(xnc-xni))*odts
      pri_inu_s = MIN(DBLE(rate_max), xm0i*pni_inu_s)
      pni_inu_s = pri_inu_s/xm0i
      endif
      xni = ns+ni + (pni_rfz_s+pni_wfz_s+pni_inu_s)*dtsave
      if (is_aerosol_aware .AND. homogIce .AND. (xni.le.999.E3)      .AND.(temp.lt.238).AND.(ssati_s.ge.0.4) ) then
      xnc = iceKoop(temp,qv,qvs_s,nwfa, dtsave)
      pni_iha_s = xnc*odts
      pri_iha_s = MIN(DBLE(rate_max), xm0i*0.1*pni_iha_s)
      pni_iha_s = pri_iha_s/(xm0i*0.1)
      endif
      if (L_qi) then
      lami = (am_i*cig(2)*oig1*ni/ri)**obmi
      ilami = 1./lami
      xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
      xmi = am_i*xDi**bm_i
      oxmi = 1./xmi
      pri_ide_s = C_cube*t1_subl*diffu_s*ssati_s*rvs  *oig1*cig(5)*ni*ilami
      if (pri_ide_s .lt. 0.0) then
      pri_ide_s = MAX(DBLE(-ri*odts), pri_ide_s, DBLE(rate_max))
      pni_ide_s = pri_ide_s*oxmi
      pni_ide_s = MAX(DBLE(-ni*odts), pni_ide_s)
      else
      pri_ide_s = MIN(pri_ide_s, DBLE(rate_max))
      prs_ide_s = (1.0D0-tpi_ide(idx_i,idx_i1))*pri_ide_s
      pri_ide_s = tpi_ide(idx_i,idx_i1)*pri_ide_s
      endif
      if ( (idx_i.eq. ntb_i) .or. (xDi.gt. 5.0*D0s) ) then
      prs_iau = ri*.99*odts
      pni_iau_s = ni*.95*odts
      elseif (xDi.lt. 0.1*D0s) then
      prs_iau = 0.
      pni_iau_s = 0.
      else
      prs_iau = tps_iaus(idx_i,idx_i1)*odts
      prs_iau = MIN(DBLE(ri*.99*odts), prs_iau)
      pni_iau_s = tni_iaus(idx_i,idx_i1)*odts
      pni_iau_s = MIN(DBLE(ni*.95*odts), pni_iau_s)
      endif
      endif
      if (L_qs) then
      C_snow = C_sqrd + (tempc+1.5)*(C_cube-C_sqrd)/(-30.+1.5)
      C_snow = MAX(C_sqrd, MIN(C_snow, C_cube))
      prs_sde = C_snow*t1_subl*diffu_s*ssati_s*rvs  * (t1_qs_sd*smo1  + t2_qs_sd*rhof2_s*vsc2_s*smof)
      if (prs_sde.lt. 0.) then
      prs_sde = MAX(DBLE(-rs*odts), prs_sde, DBLE(rate_max))
      else
      prs_sde = MIN(prs_sde, DBLE(rate_max))
      endif
      endif
      if (L_qg .and. ssati_s.lt. -eps) then
      t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg)) * cgg(11,idx_bg)
      prg_gde = C_cube*t1_subl*diffu_s*ssati_s*rvs  * N0_g * (t1_qg_sd*ilamg**cge(10,1)  + t2_qg_sd*vsc2_s*rhof2_s*ilamg**cge(11,idx_bg))
      if (prg_gde.lt. 0.) then
      prg_gde = MAX(DBLE(-rg*odts), prg_gde, DBLE(rate_max))
      png_gde_s = prg_gde * ng/rg
      else
      prg_gde = MIN(prg_gde, DBLE(rate_max))
      endif
      endif
      if (L_qi) then
      lami = (am_i*cig(2)*oig1*ni/ri)**obmi
      ilami = 1./lami
      xDi = MAX(DBLE(D0i), (bm_i + mu_i + 1.) * ilami)
      xmi = am_i*xDi**bm_i
      oxmi = 1./xmi
      if (rs.ge. r_s(1)) then
      prs_sci = t1_qs_qi*rhof_s*Ef_si*ri*smoe
      pni_sci_s = prs_sci * oxmi
      endif
      if (rr.ge. r_r(1) .and. mvd_r.gt. 4.*xDi) then
      lamr = 1./ilamr
      pri_rci = rhof_s*t1_qr_qi*Ef_ri*ri*N0_r  *((lamr+fv_r)**(-cre(9)))
      pnr_rci_s = rhof_s*t1_qr_qi*Ef_ri*ni*N0_r            *((lamr+fv_r)**(-cre(9)))
      pnr_rci_s = MIN(DBLE(nr*odts), pnr_rci_s)
      pni_rci_s = pri_rci * oxmi
      prr_rci_s = rhof_s*t2_qr_qi*Ef_ri*ni*N0_r  *((lamr+fv_r)**(-cre(8)))
      prr_rci_s = MIN(DBLE(rr*odts), prr_rci_s)
      prg_rci_s = pri_rci + prr_rci_s
      pbg_rci_s = prg_rci_s/rho_i
      endif
      endif
      if (prg_gcw.gt. eps .and. tempc.gt.-8.0) then
      tf = 0.
      if (tempc.ge.-5.0 .and. tempc.lt.-3.0) then
      tf = 0.5*(-3.0 - tempc)
      elseif (tempc.gt.-8.0 .and. tempc.lt.-5.0) then
      tf = 0.33333333*(8.0 + tempc)
      endif
      pni_ihm_s = 3.5E8*tf*prg_gcw
      pri_ihm_s = xm0i*pni_ihm_s
      prs_ihm_s = prs_scw/(prs_scw+prg_gcw)  * pri_ihm_s
      prg_ihm_s = prg_gcw/(prs_scw+prg_gcw)  * pri_ihm_s
      endif
      if (prs_scw.gt.2.0*prs_sde .and.  prs_sde.gt.eps) then
      r_frac = MIN(30.0D0, prs_scw/prs_sde)
      g_frac = MIN(0.95, 0.15 + (r_frac-2.)*.028)
      vts_boost = MIN(1.5, 1.1 + (r_frac-2.)*.014)
      prg_scw = g_frac*prs_scw
      png_scw_s = prg_scw*smo0/rs
      vts = av_s*xDs**bv_s * EXP(-fv_s*xDs)
      const_Ri = -1.*(mvd_c*0.5E6)*vts/MIN(-0.1,tempc)
      const_Ri = MAX(0.1, MIN(const_Ri, 10.))
      rime_dens = (0.051 + 0.114*const_Ri - 0.0055*const_Ri*const_Ri)*1000.
      if(rime_dens .lt. 150.) then
      g_frac = 0.
      prg_scw=0.
      png_scw_s=0.
      endif
      pbg_scw_s = prg_scw/(0.5*(rime_dens+rho_s))
      prs_scw = (1. - g_frac)*prs_scw
      endif
      else
      if (L_qs) then
      prr_sml = (tempc*tcond_s-lvap0*diffu_s*delQvs_s)        * (t1_qs_me*smo1 + t2_qs_me*rhof2_s*vsc2_s*smof)
      if (prr_sml .gt. 0.) then
      prr_sml = prr_sml + 4218.*olfus*(twet_k-T_0)        * (prr_rcs_s+prs_scw)
      endif
      prr_sml = MIN(DBLE(rs*odts), MAX(0.D0, prr_sml))
      if (prr_sml.gt.0.0) then
      pnr_sml_s = smo0/rs*prr_sml * 10.0**(-0.25*(twet_k-T_0))
      elseif (ssati_s.lt. 0.) then
      prs_sde = C_sqrd*t1_subl*diffu_s*ssati_s*rvs  * (t1_qs_sd*smo1  + t2_qs_sd*rhof2_s*vsc2_s*smof)
      prs_sde = MAX(DBLE(-rs*odts), prs_sde)
      endif
      endif
      if (L_qg) then
      N0_melt = N0_g
      if ((rg*ng) .lt. 1.E-4) then
      lamg = 1./ilamg
      N0_melt = (1.E-4/rg)*ogg2*lamg**cge(2,1)
      endif
      t2_qg_me = PI*4.*C_cube*olfus * 0.28*Sc3*SQRT(av_g(idx_bg)) * cgg(11,idx_bg)
      prr_gml = (tempc*tcond_s-lvap0*diffu_s*delQvs_s)        * N0_melt*(t1_qg_me*ilamg**cge(10,1)            + t2_qg_me*rhof2_s*vsc2_s*ilamg**cge(11,idx_bg))
      prr_gml = MIN(DBLE(rg*odts), MAX(0.D0, prr_gml))
      if (prr_gml .gt. 0.0) then
      melt_f = MAX(0.05, MIN(prr_gml*dt/rg,1.0))
      pbg_gml_s = prr_gml / MAX(MIN(melt_f*rho_g(idx_bg),1000.),50.)
      pnr_gml_s = prr_gml*ng/rg * 10.0**(-0.33*(twet_k-T_0))
      elseif (ssati_s.lt. 0.) then
      t2_qg_sd = 0.28*Sc3*SQRT(av_g(idx_bg)) * cgg(11,idx_bg)
      prg_gde = C_cube*t1_subl*diffu_s*ssati_s*rvs  * N0_g * (t1_qg_sd*ilamg**cge(10,1)  + t2_qg_sd*vsc2_s*rhof2_s*ilamg**cge(11,idx_bg))
      prg_gde = MAX(DBLE(-rg*odts), prg_gde)
      png_gde_s = prg_gde * ng/rg
      endif
      endif
      if (dt .gt. 120.) then
      prr_rcw=prr_rcw+prs_scw+prg_gcw
      prs_scw=0.
      prg_gcw=0.
      endif
      endif
      if (.not. is_hail_aware) idx_bg = idx_bg1
      endif
      sump = pri_inu_s + pri_ide_s + prs_ide_s  + prs_sde + prg_gde + pri_iha_s
      rate_max = (qv-qvsi_s)*rho*odts*0.999
      if ( (sump.gt. eps .and. sump.gt. rate_max) .or.  (sump.lt. -eps .and. sump.lt. rate_max) ) then
      ratio = rate_max/sump
      pri_inu_s = pri_inu_s * ratio
      pri_ide_s = pri_ide_s * ratio
      pni_ide_s = pni_ide_s * ratio
      prs_ide_s = prs_ide_s * ratio
      prs_sde = prs_sde * ratio
      prg_gde = prg_gde * ratio
      pri_iha_s = pri_iha_s * ratio
      endif
      sump = -prr_wau - pri_wfz_s - prr_rcw  - prs_scw - prg_scw - prg_gcw
      rate_max = -rc*odts
      if (sump.lt. rate_max .and. L_qc) then
      ratio = rate_max/sump
      prr_wau = prr_wau * ratio
      pri_wfz_s = pri_wfz_s * ratio
      prr_rcw = prr_rcw * ratio
      prs_scw = prs_scw * ratio
      prg_scw = prg_scw * ratio
      prg_gcw = prg_gcw * ratio
      endif
      sump = pri_ide_s - prs_iau - prs_sci  - pri_rci
      rate_max = -ri*odts
      if (sump.lt. rate_max .and. L_qi) then
      ratio = rate_max/sump
      pri_ide_s = pri_ide_s * ratio
      prs_iau = prs_iau * ratio
      prs_sci = prs_sci * ratio
      pri_rci = pri_rci * ratio
      endif
      sump = -prg_rfz_s - pri_rfz_s - prr_rci_s  + prr_rcs_s + prr_rcg_s
      rate_max = -rr*odts
      if (sump.lt. rate_max .and. L_qr) then
      ratio = rate_max/sump
      prg_rfz_s = prg_rfz_s * ratio
      pri_rfz_s = pri_rfz_s * ratio
      prr_rci_s = prr_rci_s * ratio
      prr_rcs_s = prr_rcs_s * ratio
      prr_rcg_s = prr_rcg_s * ratio
      endif
      sump = prs_sde - prs_ihm_s - prr_sml  + prs_rcs_s
      rate_max = -rs*odts
      if (sump.lt. rate_max .and. L_qs) then
      ratio = rate_max/sump
      prs_sde = prs_sde * ratio
      prs_ihm_s = prs_ihm_s * ratio
      prr_sml = prr_sml * ratio
      prs_rcs_s = prs_rcs_s * ratio
      endif
      sump = prg_gde - prg_ihm_s - prr_gml  + prg_rcg_s
      rate_max = -rg*odts
      if (sump.lt. rate_max .and. L_qg) then
      ratio = rate_max/sump
      prg_gde = prg_gde * ratio
      prg_ihm_s = prg_ihm_s * ratio
      prr_gml = prr_gml * ratio
      prg_rcg_s = prg_rcg_s * ratio
      endif
      pri_ihm_s = prs_ihm_s + prg_ihm_s
      ratio = MIN( ABS(prr_rcg_s), ABS(prg_rcg_s) )
      prr_rcg_s = ratio * SIGN(1.0, SNGL(prr_rcg_s))
      prg_rcg_s = -prr_rcg_s
      if (twet_k.gt.T_0) then
      ratio = MIN( ABS(prr_rcs_s), ABS(prs_rcs_s) )
      prr_rcs_s = ratio * SIGN(1.0, SNGL(prr_rcs_s))
      prs_rcs_s = -prr_rcs_s
      endif
      orho = 1./rho
      lfus2 = lsub - lvap_s
      if (is_aerosol_aware) then
      nwfaten = nwfaten - (pna_rca_s + pna_sca_s           + pna_gca_s + pni_iha_s) * orho
      nifaten = nifaten - (pnd_rcd_s + pnd_scd_s           + pnd_gcd_s) * orho
      if (wif_input_opt .eq. 2) then
      nbcaten = nbcaten - (pnb_rcb_s + pnb_scb_s        + pnb_gcb_s) * orho
      else
      nbcaten = 0.0
      endif
      if (dustyIce) then
      nifaten = nifaten - pni_inu_s*orho
      else
      nifaten = 0.
      endif
      endif
      qvten = qvten + (-pri_inu_s - pri_iha_s - pri_ide_s    - prs_ide_s - prs_sde - prg_gde)  * orho
      qcten = qcten + (-prr_wau - pri_wfz_s  - prr_rcw - prs_scw - prg_scw  - prg_gcw)  * orho
      ncten = ncten + (-pnc_wau_s - pnc_rcw_s  - pni_wfz_s - pnc_scw_s - pnc_gcw_s)  * orho
      xrc=MAX(R1, (qc1d + qcten*dtsave)*rho)
      xnc=MAX(2., (nc1d + ncten*dtsave)*rho)
      if (xrc .gt. R1) then
      nu_c = MIN(15, NINT(1000.E6/xnc) + 2)
      lamc = (xnc*am_r*ccg(2,nu_c)*ocg1(nu_c)/rc)**obmr
      xDc = (bm_r + nu_c + 1.) / lamc
      if (xDc.lt. D0c) then
      lamc = cce(2,nu_c)/D0c
      xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
      ncten = (xnc-nc1d*rho)*odts*orho
      elseif (xDc.gt. D0r*2.) then
      lamc = cce(2,nu_c)/(D0r*2.)
      xnc = ccg(1,nu_c)*ocg2(nu_c)*xrc/am_r*lamc**bm_r
      ncten = (xnc-nc1d*rho)*odts*orho
      endif
      else
      ncten = -nc1d*odts
      endif
      xnc=MAX(0.,(nc1d + ncten*dtsave)*rho)
      if (xnc.gt.Nt_c_max)  ncten = (Nt_c_max-nc1d*rho)*odts*orho
      qiten = qiten + (pri_inu_s + pri_iha_s + pri_ihm_s     + pri_wfz_s + pri_rfz_s + pri_ide_s  - prs_iau - prs_sci - pri_rci)  * orho
      niten = niten + (pni_inu_s + pni_iha_s + pni_ihm_s     + pni_wfz_s + pni_rfz_s + pni_ide_s  - pni_iau_s - pni_sci_s - pni_rci_s)  * orho
      xri=MAX(R1,(qi1d + qiten*dtsave)*rho)
      xni=MAX(R2,(ni1d + niten*dtsave)*rho)
      if (xri.gt. R1) then
      lami = (am_i*cig(2)*oig1*xni/xri)**obmi
      ilami = 1./lami
      xDi = (bm_i + mu_i + 1.) * ilami
      if (xDi.lt. 5.E-6) then
      lami = cie(2)/5.E-6
      xni = MIN(999.D3, cig(1)*oig2*xri/am_i*lami**bm_i)
      niten = (xni-ni1d*rho)*odts*orho
      elseif (xDi.gt. 300.E-6) then
      lami = cie(2)/300.E-6
      xni = cig(1)*oig2*xri/am_i*lami**bm_i
      niten = (xni-ni1d*rho)*odts*orho
      endif
      else
      niten = -ni1d*odts
      endif
      xni=MAX(0.,(ni1d + niten*dtsave)*rho)
      if (xni.gt.999.E3)  niten = (999.E3-ni1d*rho)*odts*orho
      qrten = qrten + (prr_wau + prr_rcw  + prr_sml + prr_gml + prr_rcs_s  + prr_rcg_s - prg_rfz_s  - pri_rfz_s - prr_rci_s)  * orho
      nrten = nrten + (pnr_wau_s + pnr_sml_s + pnr_gml_s     - (pnr_rfz_s + pnr_rcr_s + pnr_rcg_s            + pnr_rcs_s + pnr_rci_s + pni_rfz_s) )          * orho
      xrr=MAX(R1,(qr1d + qrten*dtsave)*rho)
      xnr=MAX(R2,(nr1d + nrten*dtsave)*rho)
      if (xrr.gt. R1) then
      lamr = (am_r*crg(3)*org2*xnr/xrr)**obmr
      mvd_r = (3.0 + mu_r + 0.672) / lamr
      if (mvd_r .gt. 2.5E-3) then
      mvd_r = 2.5E-3
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
      nrten = (xnr-nr1d*rho)*odts*orho
      elseif (mvd_r .lt. D0r*0.75) then
      mvd_r = D0r*0.75
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      xnr = crg(2)*org3*xrr*lamr**bm_r / am_r
      nrten = (xnr-nr1d*rho)*odts*orho
      endif
      else
      qrten = -qr1d*odts
      nrten = -nr1d*odts
      endif
      qsten = qsten + (prs_iau + prs_sde + prs_sci     + prs_scw + prs_rcs_s + prs_ide_s             - prs_ihm_s - prr_sml)                         * orho
      qgten = qgten + (prg_scw + prg_rfz_s  + prg_gde + prg_rcg_s + prg_gcw  + prg_rci_s + prg_rcs_s - prg_ihm_s  - prr_gml)                           * orho
      ngten = ngten + (png_scw_s + pnr_rfz_s - png_rcg_s     + pnr_rci_s + png_rcs_s + png_gde_s             - pnr_gml_s) * orho
      qbten = qbten + (pbg_scw_s + pbg_rfz_s                  + pbg_gcw_s + pbg_rci_s + pbg_rcs_s             + pbg_rcg_s + pbg_sml_s - pbg_gml_s             + (prg_gde - prg_ihm_s) /rho_g(idx_bg) )    * orho
      xrg=MAX(R1,(qg1d + qgten*dtsave)*rho)
      xng=MAX(R2,(ng1d + ngten*dtsave)*rho)
      xrb=MAX(xrg/rho/rho_g(NRHG),(qb1d + qbten*dtsave))
      xrb=MIN(xrg/rho/rho_g(1), xrb)
      if (xrg .gt. R1) then
      lamg = (am_g(idx_bg)*cgg(3,1)*ogg2*xng/xrg)**obmg
      mvd_g = (3.0 + mu_g + 0.672) / lamg
      if(debug_flag) then
      xrho_g = MAX(rho_g(1),MIN(rg/rho/rb,rho_g(NRHG)))
      afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*rho))**b_coeff
      afall = afall * visco_s**(1.0-2.0*b_coeff)
      vtg1 = rhof_s*afall*cgg(6,idx_bg)*ogg3 / lamg**bfall
      vtg2 = rhof_s*afall*cgg(7,idx_bg)/cgg(12,idx_bg) / lamg**bfall
      endif
      if (mvd_g .gt. 25.4E-3) then
      mvd_g = 25.4E-3
      lamg = (3.0 + mu_g + 0.672) / mvd_g
      xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg)
      ngten = (xng-ng1d*rho)*odts*orho
      elseif (mvd_g .lt. D0r) then
      mvd_g = D0r
      lamg = (3.0 + mu_g + 0.672) / mvd_g
      xng = cgg(2,1)*ogg3*xrg*lamg**bm_g / am_g(idx_bg)
      ngten = (xng-ng1d*rho)*odts*orho
      endif
      else
      qgten = -qg1d*odts
      ngten = -ng1d*odts
      qbten = -qb1d*odts
      endif
      if (temp.lt.T_0) then
      tten = tten  + ( lsub*ocp_s*(pri_inu_s + pri_ide_s  + prs_ide_s + prs_sde  + prg_gde + pri_iha_s)  + lfus2*ocp_s*(pri_wfz_s + pri_rfz_s  + prg_rfz_s + prs_scw  + prg_scw + prg_gcw  + prg_rcs_s + prs_rcs_s  + prr_rci_s + prg_rcg_s)  )*orho * (1-IFDRY)
      else
      tten = tten  + ( lfus*ocp_s*(-prr_sml - prr_gml  - prr_rcg_s - prr_rcs_s)  + lsub*ocp_s*(prs_sde + prg_gde)  )*orho * (1-IFDRY)
      endif
      if (th_probe == 2) return
      temp = t1d + DT*tten
      otemp = 1./temp
      tempc = temp - 273.15
      qv = MAX(1.E-10, qv1d + DT*qvten)
      rho = 0.622*pres/(R*temp*(qv+0.622))
      rhof = SQRT(RHO_NOT/rho)
      rhof2 = SQRT(rhof)
      qvs = rslf(pres, temp)
      ssatw = qv/qvs - 1.
      if (abs(ssatw).lt. eps) ssatw = 0.0
      diffu = 2.11E-5*(temp/273.15)**1.94 * (101325./pres)
      if (tempc .ge. 0.0) then
      visco = (1.718+0.0049*tempc)*1.0E-5
      else
      visco = (1.718+0.0049*tempc-1.2E-5*tempc*tempc)*1.0E-5
      endif
      vsc2 = SQRT(rho/visco)
      lvap = lvap0 + (2106.0 - 4218.0)*tempc
      tcond = (5.69 + 0.0168*tempc)*1.0E-5 * 418.936
      ocp = 1./(Cp*(1.+0.887*qv))
      lvt2=lvap*lvap*ocp*oRv*otemp*otemp
      nwfa = MAX(11.1E6, (nwfa1d + nwfaten*DT)*rho)
      if ((qc1d + qcten*DT) .gt. R1) then
      rc = (qc1d + qcten*DT)*rho
      nc = MAX(2., MIN((nc1d+ncten*DT)*rho, Nt_c_max))
      if (.NOT. is_aerosol_aware) nc = Nt_c
      L_qc = .true.
      else
      rc = R1
      nc = 2.
      L_qc = .false.
      endif
      if ((qi1d + qiten*DT) .gt. R1) then
      ri = (qi1d + qiten*DT)*rho
      ni = MAX(R2, (ni1d + niten*DT)*rho)
      L_qi = .true.
      else
      ri = R1
      ni = R2
      L_qi = .false.
      endif
      if ((qr1d + qrten*DT) .gt. R1) then
      rr = (qr1d + qrten*DT)*rho
      nr = MAX(R2, (nr1d + nrten*DT)*rho)
      L_qr = .true.
      lamr = (am_r*crg(3)*org2*nr/rr)**obmr
      mvd_r = (3.0 + mu_r + 0.672) / lamr
      if (mvd_r .gt. 2.5E-3) then
      mvd_r = 2.5E-3
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      nr = crg(2)*org3*rr*lamr**bm_r / am_r
      elseif (mvd_r .lt. D0r*0.75) then
      mvd_r = D0r*0.75
      lamr = (3.0 + mu_r + 0.672) / mvd_r
      nr = crg(2)*org3*rr*lamr**bm_r / am_r
      endif
      else
      rr = R1
      nr = R2
      L_qr = .false.
      endif
      if ((qs1d + qsten*DT) .gt. R1) then
      rs = (qs1d + qsten*DT)*rho
      L_qs = .true.
      else
      rs = R1
      L_qs = .false.
      endif
      if (is_hail_aware) then
      if ((qg1d + qgten*DT) .gt. R1) then
      L_qg = .true.
      rg = (qg1d + qgten*DT)*rho
      ng = MAX(R2, (ng1d + ngten*DT)*rho)
      rb = MAX(rg/rho/rho_g(NRHG), qb1d + qbten*DT)
      rb = MIN(rg/rho/rho_g(1), rb)
      idx_bg = MAX(1,MIN(NINT(rg/rho/rb *0.01)+1,NRHG))
      else
      rg = R1
      ng = R2
      rb = R1/rho/rho_g(NRHG)
      idx_bg = idx_bg1
      L_qg = .false.
      endif
      else
      idx_bg = idx_bg1
      if ((qg1d + qgten*DT) .gt. R1) then
      rg = (qg1d + qgten*DT)*rho
      ygra1 = alog10(max(1.E-9, rg))
      zans1 = 3.0 + 2./7.*(ygra1+8.)
      zans1 = MAX(2., MIN(zans1, 6.))
      N0_exp = 10.**(zans1)
      lam_exp = (N0_exp*am_g(idx_bg)*cgg(1,1)/rg)**oge1
      lamg = lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
      ng = cgg(2,1)*ogg3*rg*lamg**bm_g / am_g(idx_bg)
      rb = rg/rho/rho_g(idx_bg)
      else
      rg = R1
      ng = R2
      rb = R1/rho/rho_g(NRHG)
      L_qg = .false.
      endif
      endif
      if (.not. iiwarm) then
      smo2 = 0.
      smob = 0.
      smoc = 0.
      smod = 0.
      do thonce = 1, 1
      if (.not. L_qs) CYCLE
      tc0 = MIN(-0.1, temp-273.15)
      smob = rs*oams
      if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
      smo2 = smob
      else
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s  + sa(4)*tc0*bm_s + sa(5)*tc0*tc0  + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s  + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0  + sa(10)*bm_s*bm_s*bm_s
      a_ = 10.0**loga_
      b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s  + sb(4)*tc0*bm_s + sb(5)*tc0*tc0  + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s  + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0  + sb(10)*bm_s*bm_s*bm_s
      smo2 = (smob/a_)**(1./b_)
      endif
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1)  + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0  + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1)  + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(1)*cse(1)*cse(1)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1)  + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1)  + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
      smoc = a_ * smo2**b_
      loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(14)  + sa(4)*tc0*cse(14) + sa(5)*tc0*tc0  + sa(6)*cse(14)*cse(14) + sa(7)*tc0*tc0*cse(14)  + sa(8)*tc0*cse(14)*cse(14) + sa(9)*tc0*tc0*tc0  + sa(10)*cse(14)*cse(14)*cse(14)
      a_ = 10.0**loga_
      b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(14) + sb(4)*tc0*cse(14)  + sb(5)*tc0*tc0 + sb(6)*cse(14)*cse(14)  + sb(7)*tc0*tc0*cse(14) + sb(8)*tc0*cse(14)*cse(14)  + sb(9)*tc0*tc0*tc0 + sb(10)*cse(14)*cse(14)*cse(14)
      smod = a_ * smo2**b_
      enddo
      if (th_probe == 3) return
      lamg = (am_g(idx_bg)*cgg(3,1)*ogg2*ng/rg)**obmg
      ilamg = 1./lamg
      N0_g = ng*ogg2*lamg**cge(2,1)
      endif
      lamr = (am_r*crg(3)*org2*nr/rr)**obmr
      ilamr = 1./lamr
      mvd_r = (3.0 + mu_r + 0.672) / lamr
      N0_r = nr*org2*lamr**cre(2)
      orho = 1./rho
      if ( (ssatw.gt. eps) .or. (ssatw.lt. -eps .and.  L_qc) ) then
      clap = (qv-qvs)/(1. + lvt2*qvs)
      do n = 1, 3
      fcd = qvs* EXP(lvt2*clap) - qv + clap
      dfcd = qvs*lvt2* EXP(lvt2*clap) + 1.
      clap = clap - fcd/dfcd
      enddo
      xrc = rc + clap*rho
      xnc = 0.
      if (xrc.gt. R1) then
      prw_vcd = clap*odt
      if (clap .gt. eps) then
      if (is_aerosol_aware) then
      xnc = MAX(2., activ_ncloud(temp, w1d, nwfa))
      else
      xnc = Nt_c
      endif
      pnc_wcd = 0.5*(xnc-nc + abs(xnc-nc))*odts*orho
      elseif (clap .lt. -eps .AND. ssatw.lt.-1.E-6 .AND. is_aerosol_aware) then
      tempc = temp - 273.15
      otemp = 1./temp
      rvs = rho*qvs
      rvs_p = rvs*otemp*(lvap*otemp*oRv - 1.)
      rvs_pp = rvs * ( otemp*(lvap*otemp*oRv - 1.)  *otemp*(lvap*otemp*oRv - 1.)  + (-2.*lvap*otemp*otemp*otemp*oRv)  + otemp*otemp)
      gamsc = lvap*diffu/tcond * rvs_p
      alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc))  * rvs_pp/rvs_p * rvs/rvs_p
      alphsc = MAX(1.E-9, alphsc)
      xsat = ssatw
      if (abs(xsat).lt. 1.E-9) xsat=0.
      t1_evap = 2.*PI*( 1.0 - alphsc*xsat   + 2.*alphsc*alphsc*xsat*xsat   - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat )  / (1.+gamsc)
      Dc_star = DSQRT(-2.D0*DT * t1_evap/(2.*PI)  * 4.*diffu*ssatw*rvs/rho_w)
      idx_d = MAX(1, MIN(INT(1.E6*Dc_star), nbc))
      idx_n = NINT(1.0 + FLOAT(nbc) * DLOG(nc/t_Nc(1)) / nic1)
      idx_n = MAX(1, MIN(idx_n, nbc))
      if (rc.gt. r_c(1)) then
      nic = NINT(ALOG10(rc))
      do nn = nic-1, nic+1
      n = nn
      if ( (rc/10.**nn).ge.1.0 .and.  (rc/10.**nn).lt.10.0) goto 159
      enddo
      159         continue
      idx_c = INT(rc/10.**n) + 10*(n-nic2) - (n-nic2)
      idx_c = MAX(1, MIN(idx_c, ntb_c))
      else
      idx_c = 1
      endif
      prw_vcd = MAX(DBLE(-rc*0.99*orho*odt), prw_vcd)
      pnc_wcd = MAX(DBLE(-nc*0.99*orho*odt),                 DBLE(-tnc_wev(idx_d, idx_c, idx_n)*orho*odt))
      endif
      else
      prw_vcd = -rc*orho*odt
      pnc_wcd = -nc*orho*odt
      endif
      qvten = qvten - prw_vcd
      qcten = qcten + prw_vcd
      ncten = ncten + pnc_wcd
      nwfaten = nwfaten - pnc_wcd
      tten = tten + lvap*ocp*prw_vcd*(1-IFDRY)
      rc = MAX(R1, (qc1d + DT*qcten)*rho)
      if (rc.eq.R1) L_qc = .false.
      nc = MAX(2., MIN((nc1d+ncten*DT)*rho, Nt_c_max))
      if (.NOT. is_aerosol_aware) nc = Nt_c
      qv = MAX(1.E-10, qv1d + DT*qvten)
      temp = t1d + DT*tten
      rho = 0.622*pres/(R*temp*(qv+0.622))
      qvs = rslf(pres, temp)
      ssatw = qv/qvs - 1.
      endif
      if ( (ssatw.lt. -eps) .and. L_qr  .and. (.not.(prw_vcd.gt. 0.)) ) then
      tempc = temp - 273.15
      otemp = 1./temp
      orho = 1./rho
      rhof = SQRT(RHO_NOT*orho)
      rhof2 = SQRT(rhof)
      diffu = 2.11E-5*(temp/273.15)**1.94 * (101325./pres)
      if (tempc .ge. 0.0) then
      visco = (1.718+0.0049*tempc)*1.0E-5
      else
      visco = (1.718+0.0049*tempc-1.2E-5*tempc*tempc)*1.0E-5
      endif
      vsc2 = SQRT(rho/visco)
      lvap = lvap0 + (2106.0 - 4218.0)*tempc
      tcond = (5.69 + 0.0168*tempc)*1.0E-5 * 418.936
      ocp = 1./(Cp*(1.+0.887*qv))
      rvs = rho*qvs
      rvs_p = rvs*otemp*(lvap*otemp*oRv - 1.)
      rvs_pp = rvs * ( otemp*(lvap*otemp*oRv - 1.)  *otemp*(lvap*otemp*oRv - 1.)  + (-2.*lvap*otemp*otemp*otemp*oRv)  + otemp*otemp)
      gamsc = lvap*diffu/tcond * rvs_p
      alphsc = 0.5*(gamsc/(1.+gamsc))*(gamsc/(1.+gamsc))  * rvs_pp/rvs_p * rvs/rvs_p
      alphsc = MAX(1.E-9, alphsc)
      xsat   = MIN(-1.E-9, ssatw)
      t1_evap = 2.*PI*( 1.0 - alphsc*xsat   + 2.*alphsc*alphsc*xsat*xsat   - 5.*alphsc*alphsc*alphsc*xsat*xsat*xsat )  / (1.+gamsc)
      lamr = 1./ilamr
      if (qv/qvs .lt. 0.95 .AND. rr*orho.le.1.E-8) then
      prv_rev = rr*orho*odts
      else
      prv_rev = t1_evap*diffu*(-ssatw)*N0_r*rvs  * (t1_qr_ev*ilamr**cre(10)  + t2_qr_ev*vsc2*rhof2*((lamr+0.5*fv_r)**(-cre(11))))
      rate_max = MIN((rr*orho*odts), (qvs-qv)*odts)
      prv_rev = MIN(DBLE(rate_max), prv_rev*orho)
      IF (prr_gml.gt.0.0) THEN
      eva_factor = MIN(1.0, 0.01+(0.99-0.01)*(tempc/20.0))
      prv_rev = prv_rev*eva_factor
      ENDIF
      endif
      pnr_rev = MIN(DBLE(nr*0.99*orho*odts),                   prv_rev * nr/rr)
      qrten = qrten - prv_rev
      qvten = qvten + prv_rev
      nrten = nrten - pnr_rev
      nwfaten = nwfaten + pnr_rev
      tten = tten - lvap*ocp*prv_rev*(1-IFDRY)
      rr = MAX(R1, (qr1d + DT*qrten)*rho)
      qv = MAX(1.E-10, qv1d + DT*qvten)
      nr = MAX(R2, (nr1d + DT*nrten)*rho)
      temp = t1d + DT*tten
      rho = 0.622*pres/(R*temp*(qv+0.622))
      endif
      if (th_probe == 4) return
      end subroutine thom_lev

!.. GPU (WRF_GPU_THLEV): mp_thompson from the sedimentation on (generated by thgen.py); the per-level
!.. phase's arrays arrive as arguments (filled by thom_lev in the band scratch).

!.. GPU (WRF_GPU_THSPLIT): fall speeds of one species (sp 1 rain, 2 ice, 3 snow, 4 graupel, 5 cloud) as
!.. thom_tail computes them before any sedimentation; stored for thom_sed (generated by thsplit.py)
      subroutine thom_vt(sp, w1d, dzq, kts, kte, dt, thic, thjjb)
!$acc routine seq
      implicit none
      INTEGER, INTENT(IN):: sp, kts, kte, thic, thjjb
      REAL, DIMENSION(kts:kte), INTENT(IN):: w1d, dzq
      REAL, INTENT(IN):: dt
      REAL, DIMENSION(1:KTGPU):: rhofl
      LOGICAL:: lqr_
      REAL:: delta_tp
      REAL, DIMENSION(5):: onstep
      DOUBLE PRECISION:: lamc
      DOUBLE PRECISION:: lamr
      DOUBLE PRECISION:: lami
      DOUBLE PRECISION:: ilami
      DOUBLE PRECISION:: ilamc
      REAL:: xds
      REAL:: vti
      REAL:: vtr
      REAL:: vts
      REAL:: vtg
      REAL:: vtc
      REAL:: xrho_g
      REAL:: afall
      REAL:: bfall
      REAL, DIMENSION(1:KTGPU+1):: vtik
      REAL, DIMENSION(1:KTGPU+1):: vtnik
      REAL, DIMENSION(1:KTGPU+1):: vtrk
      REAL, DIMENSION(1:KTGPU+1):: vtnrk
      REAL, DIMENSION(1:KTGPU+1):: vtsk
      REAL, DIMENSION(1:KTGPU+1):: vtgk
      REAL, DIMENSION(1:KTGPU+1):: vtngk
      REAL, DIMENSION(1:KTGPU+1):: vtck
      REAL, DIMENSION(1:KTGPU+1):: vtnck
      REAL:: mrat
      REAL:: ils1
      REAL:: ils2
      REAL:: t1_vts
      REAL:: t2_vts
      REAL:: t3_vts
      REAL:: t4_vts
      REAL:: dtsave
      REAL:: odts
      REAL:: odt
      REAL:: hgt_agl
      REAL:: sr
      INTEGER:: k
      INTEGER:: nstep
      INTEGER:: iexfrq
      INTEGER, DIMENSION(5):: ksed1
      INTEGER:: nu_c
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1
      nstep = 0
      onstep(:) = 1.0
      ksed1(:) = 1
      do k = kte+1, kts, -1
         vtrk(k) = 0.
         vtnrk(k) = 0.
         vtik(k) = 0.
         vtnik(k) = 0.
         vtsk(k) = 0.
         vtgk(k) = 0.
         vtngk(k) = 0.
         vtck(k) = 0.
         vtnck(k) = 0.
      enddo
      lqr_ = ANY(thb_l_qr(thic,kts:kte,thjjb))
      do k = kts, kte
         if (lqr_) then
            rhofl(k) = SQRT(RHO_NOT/thb_rho(thic,k,thjjb))
         else
            rhofl(k) = thb_rhof(thic,k,thjjb)
         endif
      enddo
      if (sp .eq. 1 .or. sp .eq. 3) then
      if (ANY(thb_l_qr(thic,kts:kte,thjjb))) then
      do k = kte, kts, -1
         vtr = 0.

         if (thb_rr(thic,k,thjjb).gt. R1) then
          lamr = (am_r*crg(3)*org2*thb_nr(thic,k,thjjb)/thb_rr(thic,k,thjjb))**obmr
          vtr = rhofl(k)*av_r*crg(6)*org3 * lamr**cre(3)                 &
                      *((lamr+fv_r)**(-cre(6)))
          vtrk(k) = vtr





          vtr = rhofl(k)*av_r*crg(7)/crg(12) * lamr**cre(12)             &
                      *((lamr+fv_r)**(-cre(7)))
          vtnrk(k) = vtr
         else
          vtrk(k) = vtrk(k+1)
          vtnrk(k) = vtnrk(k+1)
         endif

         if (MAX(vtrk(k),vtnrk(k)) .gt. 1.E-3) then
            ksed1(1) = MAX(ksed1(1), k)
            delta_tp = dzq(k)/(MAX(vtrk(k),vtnrk(k)))
            nstep = MAX(nstep, INT(DT/delta_tp + 1.))
         endif
      enddo
      if (ksed1(1) .eq. kte) ksed1(1) = kte-1
      if (nstep .gt. 0) onstep(1) = 1./REAL(nstep)
      endif



      endif
      if (sp .eq. 5) then
      if (ANY(thb_l_qc(thic,kts:kte,thjjb))) then
      hgt_agl = 0.
      do k = kts, kte-1
         if (thb_rc(thic,k,thjjb) .gt. R2) ksed1(5) = k
         hgt_agl = hgt_agl + dzq(k)
         if (hgt_agl .gt. 500.0) goto 151
      enddo
 151  continue

      do k = ksed1(5), kts, -1
         vtc = 0.
         if (thb_rc(thic,k,thjjb) .gt. R1 .and. w1d(k) .lt. 1.E-1) then
          nu_c = MIN(15, NINT(1000.E6/thb_nc(thic,k,thjjb)) + 2)
          lamc = (thb_nc(thic,k,thjjb)*am_r*ccg(2,nu_c)*ocg1(nu_c)/thb_rc(thic,k,thjjb))**obmr
          ilamc = 1./lamc
          vtc = rhofl(k)*av_c*ccg(5,nu_c)*ocg2(nu_c) * ilamc**bv_c
          vtck(k) = vtc
          vtc = rhofl(k)*av_c*ccg(4,nu_c)*ocg1(nu_c) * ilamc**bv_c
          vtnck(k) = vtc
         endif
      enddo
      endif



      endif
      if (.not. iiwarm) then
      if (sp .eq. 2) then
       if (ANY(thb_l_qi(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vti = 0.

          if (thb_ri(thic,k,thjjb).gt. R1) then
           lami = (am_i*cig(2)*oig1*thb_ni(thic,k,thjjb)/thb_ri(thic,k,thjjb))**obmi
           ilami = 1./lami
           vti = rhofl(k)*av_i*cig(3)*oig2 * ilami**bv_i
           vtik(k) = vti



           vti = rhofl(k)*av_i*cig(6)/cig(7) * ilami**bv_i
           vtnik(k) = vti
          else
           vtik(k) = vtik(k+1)
           vtnik(k) = vtnik(k+1)
          endif

          if (vtik(k) .gt. 1.E-3) then
             ksed1(2) = MAX(ksed1(2), k)
             delta_tp = dzq(k)/vtik(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(2) .eq. kte) ksed1(2) = kte-1
       if (nstep .gt. 0) onstep(2) = 1./REAL(nstep)
       endif



      endif
      if (sp .eq. 3) then
       if (ANY(thb_l_qs(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vts = 0.

          if (thb_rs(thic,k,thjjb).gt. R1) then
           xDs = thb_smoc(thic,k,thjjb) / thb_smob(thic,k,thjjb)
           Mrat = 1./xDs
           ils1 = 1./(Mrat*Lam0 + fv_s)
           ils2 = 1./(Mrat*Lam1 + fv_s)
           t1_vts = Kap0*csg(4)*ils1**cse(4)
           t2_vts = Kap1*Mrat**mu_s*csg(10)*ils2**cse(10)
           ils1 = 1./(Mrat*Lam0)
           ils2 = 1./(Mrat*Lam1)
           t3_vts = Kap0*csg(1)*ils1**cse(1)
           t4_vts = Kap1*Mrat**mu_s*csg(7)*ils2**cse(7)
           vts = rhofl(k)*av_s * (t1_vts+t2_vts)/(t3_vts+t4_vts)
           if (thb_prr_sml(thic,k,thjjb) .gt. 0.0) then 
            SR = thb_rs(thic,k,thjjb)/(thb_rs(thic,k,thjjb)+thb_rr(thic,k,thjjb))
            vtsk(k) = vts*SR + (1.-SR)*vtrk(k)
           else
            vtsk(k) = vts*thb_vts_boost(thic,k,thjjb)
           endif
          else
            vtsk(k) = vtsk(k+1)
          endif

          if (vtsk(k) .gt. 1.E-3) then
             ksed1(3) = MAX(ksed1(3), k)
             delta_tp = dzq(k)/vtsk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(3) .eq. kte) ksed1(3) = kte-1
       if (nstep .gt. 0) onstep(3) = 1./REAL(nstep)
       endif



      endif
      if (sp .eq. 4) then
       if (ANY(thb_l_qg(thic,kts:kte,thjjb))) then
       nstep = 0
       do k = kte, kts, -1
          vtg = 0.

          if (thb_rg(thic,k,thjjb).gt. R1) then
           if (is_hail_aware) then
              xrho_g = MAX(rho_g(1),MIN(thb_rg(thic,k,thjjb)/thb_rho(thic,k,thjjb)/thb_rb(thic,k,thjjb),rho_g(NRHG)))
              afall = a_coeff*((4.0*xrho_g*9.8)/(3.0*thb_rho(thic,k,thjjb)))**b_coeff
              afall = afall * thb_visco(thic,k,thjjb)**(1.0-2.0*b_coeff)
           else
              afall = av_g_old
              bfall = bv_g_old
           endif
           vtg = rhofl(k)*afall*cgg(6,thb_idx_bg(thic,k,thjjb))*ogg3 * thb_ilamg(thic,k,thjjb)**bfall
            vtgk(k) = vtg


           if (mu_g .eq. 0) then
              vtg = rhofl(k)*afall*cgg(7,thb_idx_bg(thic,k,thjjb))/cgg(12,thb_idx_bg(thic,k,thjjb)) * thb_ilamg(thic,k,thjjb)**bfall
           else
              vtg = rhofl(k)*afall*cgg(8,thb_idx_bg(thic,k,thjjb))*ogg2 * thb_ilamg(thic,k,thjjb)**bfall
           endif
           vtngk(k) = vtg
          else
            vtgk(k) = vtgk(k+1)
           vtngk(k) = vtngk(k+1)
          endif

          if (vtgk(k) .gt. 1.E-3) then
             ksed1(4) = MAX(ksed1(4), k)
             delta_tp = dzq(k)/vtgk(k)
             nstep = MAX(nstep, INT(DT/delta_tp + 1.))
          endif
       enddo
       if (ksed1(4) .eq. kte) ksed1(4) = kte-1
       if (nstep .gt. 0) onstep(4) = 1./REAL(nstep)
       endif
      endif
      endif
      if (sp .eq. 1) then
      do k = kts, kte+1
         thb_vtq(thic,k,1) = vtrk(k)
         thb_vtn(thic,k,1) = vtnrk(k)
      enddo
      thb_ksed(thic,1) = ksed1(1)
      thb_onst(thic,1) = onstep(1)
      endif
      if (sp .eq. 2) then
      do k = kts, kte+1
         thb_vtq(thic,k,2) = vtik(k)
         thb_vtn(thic,k,2) = vtnik(k)
      enddo
      thb_ksed(thic,2) = ksed1(2)
      thb_onst(thic,2) = onstep(2)
      endif
      if (sp .eq. 3) then
      do k = kts, kte+1
         thb_vtq(thic,k,3) = vtsk(k)
      enddo
      thb_ksed(thic,3) = ksed1(3)
      thb_onst(thic,3) = onstep(3)
      endif
      if (sp .eq. 4) then
      do k = kts, kte+1
         thb_vtq(thic,k,4) = vtgk(k)
         thb_vtn(thic,k,4) = vtngk(k)
      enddo
      thb_ksed(thic,4) = ksed1(4)
      thb_onst(thic,4) = onstep(4)
      endif
      if (sp .eq. 5) then
      do k = kts, kte+1
         thb_vtq(thic,k,5) = vtck(k)
         thb_vtn(thic,k,5) = vtnck(k)
      enddo
      thb_ksed(thic,5) = ksed1(5)
      thb_onst(thic,5) = onstep(1)
      endif
      end subroutine thom_vt

!.. GPU (WRF_GPU_THSPLIT): sedimentation of one species from the fall speeds thom_vt stored; its surface
!.. precipitation goes to thb_ppt(thic,sp) (generated by thsplit.py)
      subroutine thom_sed(sp, dzq, kts, kte, dt, thic, thjjb)
!$acc routine seq
      implicit none
      INTEGER, INTENT(IN):: sp, kts, kte, thic, thjjb
      REAL, DIMENSION(kts:kte), INTENT(IN):: dzq
      REAL, INTENT(IN):: dt
      REAL:: pptrain, pptsnow, pptgraul, pptice
      REAL, DIMENSION(1:KTGPU):: sed_r
      REAL, DIMENSION(1:KTGPU):: sed_s
      REAL, DIMENSION(1:KTGPU):: sed_g
      REAL, DIMENSION(1:KTGPU):: sed_i
      REAL, DIMENSION(1:KTGPU):: sed_n
      REAL, DIMENSION(1:KTGPU):: sed_c
      REAL, DIMENSION(1:KTGPU):: sed_b
      REAL:: orho
      REAL, DIMENSION(5):: onstep
      REAL, DIMENSION(1:KTGPU+1):: vtik
      REAL, DIMENSION(1:KTGPU+1):: vtnik
      REAL, DIMENSION(1:KTGPU+1):: vtrk
      REAL, DIMENSION(1:KTGPU+1):: vtnrk
      REAL, DIMENSION(1:KTGPU+1):: vtsk
      REAL, DIMENSION(1:KTGPU+1):: vtgk
      REAL, DIMENSION(1:KTGPU+1):: vtngk
      REAL, DIMENSION(1:KTGPU+1):: vtck
      REAL, DIMENSION(1:KTGPU+1):: vtnck
      REAL:: the
      REAL:: dtsave
      REAL:: odts
      REAL:: odt
      REAL:: odzq
      INTEGER:: k
      INTEGER:: n
      INTEGER:: nstep
      INTEGER:: iexfrq
      INTEGER, DIMENSION(5):: ksed1
      dtsave = dt
      odt = 1./dt
      odts = 1./dtsave
      iexfrq = 1
      nstep = 0
      onstep(:) = 1.0
      ksed1(:) = 1
      do k = kte+1, kts, -1
         vtrk(k) = 0.
         vtnrk(k) = 0.
         vtik(k) = 0.
         vtnik(k) = 0.
         vtsk(k) = 0.
         vtgk(k) = 0.
         vtngk(k) = 0.
         vtck(k) = 0.
         vtnck(k) = 0.
      enddo
      if (sp .eq. 1) then
      do k = kts, kte+1
         vtrk(k) = thb_vtq(thic,k,1)
         vtnrk(k) = thb_vtn(thic,k,1)
      enddo
      ksed1(1) = thb_ksed(thic,1)
      onstep(1) = thb_onst(thic,1)
      endif
      if (sp .eq. 2) then
      do k = kts, kte+1
         vtik(k) = thb_vtq(thic,k,2)
         vtnik(k) = thb_vtn(thic,k,2)
      enddo
      ksed1(2) = thb_ksed(thic,2)
      onstep(2) = thb_onst(thic,2)
      endif
      if (sp .eq. 3) then
      do k = kts, kte+1
         vtsk(k) = thb_vtq(thic,k,3)
      enddo
      ksed1(3) = thb_ksed(thic,3)
      onstep(3) = thb_onst(thic,3)
      endif
      if (sp .eq. 4) then
      do k = kts, kte+1
         vtgk(k) = thb_vtq(thic,k,4)
         vtngk(k) = thb_vtn(thic,k,4)
      enddo
      ksed1(4) = thb_ksed(thic,4)
      onstep(4) = thb_onst(thic,4)
      endif
      if (sp .eq. 5) then
      do k = kts, kte+1
         vtck(k) = thb_vtq(thic,k,5)
         vtnck(k) = thb_vtn(thic,k,5)
      enddo
      ksed1(5) = thb_ksed(thic,5)
      endif
      pptrain = 0.
      pptsnow = 0.
      pptgraul = 0.
      pptice = 0.
      if (sp .eq. 1) then
      if (ANY(thb_l_qr(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(1))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_r(k) = vtrk(k)*thb_rr(thic,k,thjjb)
            sed_n(k) = vtnrk(k)*thb_nr(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qrten(thic,k,thjjb) = thb_qrten(thic,k,thjjb) - sed_r(k)*odzq*onstep(1)*orho
         thb_nrten(thic,k,thjjb) = thb_nrten(thic,k,thjjb) - sed_n(k)*odzq*onstep(1)*orho
         thb_rr(thic,k,thjjb) = MAX(R1, thb_rr(thic,k,thjjb) - sed_r(k)*odzq*DT*onstep(1))
         thb_nr(thic,k,thjjb) = MAX(R2, thb_nr(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(1))
         do k = ksed1(1), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qrten(thic,k,thjjb) = thb_qrten(thic,k,thjjb) + (sed_r(k+1)-sed_r(k))                 &
                                               *odzq*onstep(1)*orho
            thb_nrten(thic,k,thjjb) = thb_nrten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(1)*orho
            thb_rr(thic,k,thjjb) = MAX(R1, thb_rr(thic,k,thjjb) + (sed_r(k+1)-sed_r(k)) &
                                           *odzq*DT*onstep(1))
            thb_nr(thic,k,thjjb) = MAX(R2, thb_nr(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(1))
         enddo

         if (thb_rr(thic,kts,thjjb).gt.R1*1000.) &
         pptrain = pptrain + sed_r(kts)*DT*onstep(1)
      enddo
      endif



      endif
      if (sp .eq. 5) then
      if (ANY(thb_l_qc(thic,kts:kte,thjjb))) then
      do k = kte, kts, -1
         sed_c(k) = vtck(k)*thb_rc(thic,k,thjjb)
         sed_n(k) = vtnck(k)*thb_nc(thic,k,thjjb)
      enddo
      do k = ksed1(5), kts, -1
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qcten(thic,k,thjjb) = thb_qcten(thic,k,thjjb) + (sed_c(k+1)-sed_c(k)) *odzq*orho
         thb_ncten(thic,k,thjjb) = thb_ncten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) *odzq*orho
         thb_rc(thic,k,thjjb) = MAX(R1, thb_rc(thic,k,thjjb) + (sed_c(k+1)-sed_c(k)) *odzq*DT)
         thb_nc(thic,k,thjjb) = MAX(10., thb_nc(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) *odzq*DT)
      enddo
      endif



      endif
      if (sp .eq. 2) then
      if (ANY(thb_l_qi(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(2))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_i(k) = vtik(k)*thb_ri(thic,k,thjjb)
            sed_n(k) = vtnik(k)*thb_ni(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) - sed_i(k)*odzq*onstep(2)*orho
         thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) - sed_n(k)*odzq*onstep(2)*orho
         thb_ri(thic,k,thjjb) = MAX(R1, thb_ri(thic,k,thjjb) - sed_i(k)*odzq*DT*onstep(2))
         thb_ni(thic,k,thjjb) = MAX(R2, thb_ni(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(2))
         do k = ksed1(2), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qiten(thic,k,thjjb) = thb_qiten(thic,k,thjjb) + (sed_i(k+1)-sed_i(k))                 &
                                               *odzq*onstep(2)*orho
            thb_niten(thic,k,thjjb) = thb_niten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(2)*orho
            thb_ri(thic,k,thjjb) = MAX(R1, thb_ri(thic,k,thjjb) + (sed_i(k+1)-sed_i(k)) &
                                           *odzq*DT*onstep(2))
            thb_ni(thic,k,thjjb) = MAX(R2, thb_ni(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(2))
         enddo

         if (thb_ri(thic,kts,thjjb).gt.R1*1000.) &
         pptice = pptice + sed_i(kts)*DT*onstep(2)
      enddo
      endif



      endif
      if (sp .eq. 3) then
      if (ANY(thb_l_qs(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(3))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_s(k) = vtsk(k)*thb_rs(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qsten(thic,k,thjjb) = thb_qsten(thic,k,thjjb) - sed_s(k)*odzq*onstep(3)*orho
         thb_rs(thic,k,thjjb) = MAX(R1, thb_rs(thic,k,thjjb) - sed_s(k)*odzq*DT*onstep(3))
         do k = ksed1(3), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qsten(thic,k,thjjb) = thb_qsten(thic,k,thjjb) + (sed_s(k+1)-sed_s(k))                 &
                                               *odzq*onstep(3)*orho
            thb_rs(thic,k,thjjb) = MAX(R1, thb_rs(thic,k,thjjb) + (sed_s(k+1)-sed_s(k)) &
                                           *odzq*DT*onstep(3))
         enddo

         if (thb_rs(thic,kts,thjjb).gt.R1*1000.) &
         pptsnow = pptsnow + sed_s(kts)*DT*onstep(3)
      enddo
      endif



      endif
      if (sp .eq. 4) then
      if (ANY(thb_l_qg(thic,kts:kte,thjjb))) then
      nstep = NINT(1./onstep(4))
      do n = 1, nstep
         do k = kte, kts, -1
            sed_g(k) = vtgk(k)*thb_rg(thic,k,thjjb)
            sed_n(k) = vtngk(k)*thb_ng(thic,k,thjjb)
            sed_b(k) = vtgk(k)*thb_rb(thic,k,thjjb)
         enddo
         k = kte
         odzq = 1./dzq(k)
         orho = 1./thb_rho(thic,k,thjjb)
         thb_qgten(thic,k,thjjb) = thb_qgten(thic,k,thjjb) - sed_g(k)*odzq*onstep(4)*orho
         thb_ngten(thic,k,thjjb) = thb_ngten(thic,k,thjjb) - sed_n(k)*odzq*onstep(4)*orho
         thb_qbten(thic,k,thjjb) = thb_qbten(thic,k,thjjb) - sed_b(k)*odzq*onstep(4)
         thb_rg(thic,k,thjjb) = MAX(R1, thb_rg(thic,k,thjjb) - sed_g(k)*odzq*DT*onstep(4))
         thb_ng(thic,k,thjjb) = MAX(R2, thb_ng(thic,k,thjjb) - sed_n(k)*odzq*DT*onstep(4))
         thb_rb(thic,k,thjjb) = MAX(R1/thb_rho(thic,k,thjjb)/rho_g(NRHG), thb_rb(thic,k,thjjb) - sed_b(k)*odzq*DT*onstep(4))
         do k = ksed1(4), kts, -1
            odzq = 1./dzq(k)
            orho = 1./thb_rho(thic,k,thjjb)
            thb_qgten(thic,k,thjjb) = thb_qgten(thic,k,thjjb) + (sed_g(k+1)-sed_g(k))                 &
                                               *odzq*onstep(4)*orho
            thb_ngten(thic,k,thjjb) = thb_ngten(thic,k,thjjb) + (sed_n(k+1)-sed_n(k))                 &
                                               *odzq*onstep(4)*orho
            thb_qbten(thic,k,thjjb) = thb_qbten(thic,k,thjjb) + (sed_b(k+1)-sed_b(k))                 &
                                               *odzq*onstep(4)
            thb_rg(thic,k,thjjb) = MAX(R1, thb_rg(thic,k,thjjb) + (sed_g(k+1)-sed_g(k)) &
                                           *odzq*DT*onstep(4))
            thb_ng(thic,k,thjjb) = MAX(R2, thb_ng(thic,k,thjjb) + (sed_n(k+1)-sed_n(k)) &
                                           *odzq*DT*onstep(4))
            thb_rb(thic,k,thjjb) = MAX(thb_rg(thic,k,thjjb)/thb_rho(thic,k,thjjb)/rho_g(NRHG), thb_rb(thic,k,thjjb) + (sed_b(k+1)-sed_b(k))  &
                                           *odzq*DT*onstep(4))
         enddo

         if (thb_rg(thic,kts,thjjb).gt.R1*1000.) &
         pptgraul = pptgraul + sed_g(kts)*DT*onstep(4)
      enddo
      endif





      endif
      if (sp .eq. 1) thb_ppt(thic,sp) = pptrain
      if (sp .eq. 2) thb_ppt(thic,sp) = pptice
      if (sp .eq. 3) thb_ppt(thic,sp) = pptsnow
      if (sp .eq. 4) thb_ppt(thic,sp) = pptgraul
      end subroutine thom_sed

!.. GPU (WRF_GPU_THSPLIT): thom_tail after the sedimentation (instant melting/freezing, final update)
#endif

!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!..Creation of the lookup tables and support functions found below here.
!+---+-----------------------------------------------------------------+
!..Rain collecting graupel (and inverse).  Explicit CE integration.
!+---+-----------------------------------------------------------------+

      subroutine qr_acr_qg(NRHGtable)

      USE module_timing
      implicit none
      
      INTEGER, INTENT(IN) ::NRHGtable

!..Local variables
      INTEGER:: i, j, k, m, n, n2, n3, idx_bg
      INTEGER:: km, km_s, km_e
      DOUBLE PRECISION, DIMENSION(nbg):: N_g
      DOUBLE PRECISION, DIMENSION(nbg,NRHGtable):: vg
      DOUBLE PRECISION, DIMENSION(nbr):: vr, N_r
      DOUBLE PRECISION:: N0_r, N0_g, lam_exp, lamg, lamr
      DOUBLE PRECISION:: massg, massr, dvg, dvr, t1, t2, z1, z2, y1, y2
      LOGICAL force_read_thompson, write_thompson_tables, write_thompson_mp38table
      LOGICAL lexist,lopen
      INTEGER good
      LOGICAL, EXTERNAL :: wrf_dm_on_monitor
      CHARACTER (LEN=20):: qr_acr_qg_name
!+---+

      CALL nl_get_force_read_thompson(1,force_read_thompson)
      CALL nl_get_write_thompson_tables(1,write_thompson_tables)
      CALL nl_get_write_thompson_mp38table(1,write_thompson_mp38table)

      if (is_hail_aware) then
         ! Table for mp=38
         ! V1: new table dimension (NRHG), computes all, rho_g(1:NRHG)
         qr_acr_qg_name="qr_acr_qg_mp38V1.dat"
      else
         ! Table for mp=8 or mp=28
         ! V4: new table dimension (NRHG), computes only rho_g(idx_bg1)
         qr_acr_qg_name="qr_acr_qg_V4.dat" 
   endif

      good = 0
      IF ( wrf_dm_on_monitor() ) THEN
        INQUIRE(FILE=qr_acr_qg_name,EXIST=lexist)
        IF ( lexist ) THEN
          CALL wrf_message("ThompMP: read "//qr_acr_qg_name//" instead of computing")
          OPEN(63,file=qr_acr_qg_name,form="unformatted",err=1234)
          READ(63,err=1234) tcg_racg
          READ(63,err=1234) tmr_racg
          READ(63,err=1234) tcr_gacr
          !READ(63,err=1234) tmg_gacr
          READ(63,err=1234) tnr_racg
          READ(63,err=1234) tnr_gacr
          good = 1
 1234     CONTINUE
          IF ( good .NE. 1 ) THEN
            INQUIRE(63,opened=lopen)
            IF (lopen) THEN
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error reading "//qr_acr_qg_name//". Aborting because force_read_thompson is .true.")
              ENDIF
              CLOSE(63)
            ELSE
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error opening "//qr_acr_qg_name//". Aborting because force_read_thompson is .true.")
              ENDIF
            ENDIF
          ELSE
            INQUIRE(63,OPENED=lopen)
            IF (lopen) THEN
              CLOSE(63)
            ENDIF
          ENDIF
        ELSE
          IF( force_read_thompson ) THEN
            CALL wrf_error_fatal("Non-existent "//qr_acr_qg_name//". Aborting because force_read_thompson is .true.")
          ENDIF
          IF( (is_hail_aware) .AND. (.NOT. write_thompson_mp38table)) THEN
            CALL wrf_error_fatal("Non-existent "//qr_acr_qg_name//". Aborting because write_thompson_mp38table is .false.")
          ENDIF
        ENDIF
      ENDIF
#if defined(DM_PARALLEL) && !defined(STUBMPI)
      CALL wrf_dm_bcast_integer(good,1)
#endif

      IF ( good .EQ. 1 ) THEN
#if defined(DM_PARALLEL) && !defined(STUBMPI)
        CALL wrf_dm_bcast_double(tcg_racg,SIZE(tcg_racg))
        CALL wrf_dm_bcast_double(tmr_racg,SIZE(tmr_racg))
        CALL wrf_dm_bcast_double(tcr_gacr,SIZE(tcr_gacr))
        !CALL wrf_dm_bcast_double(tmg_gacr,SIZE(tmg_gacr))
        CALL wrf_dm_bcast_double(tnr_racg,SIZE(tnr_racg))
        CALL wrf_dm_bcast_double(tnr_gacr,SIZE(tnr_gacr))
#endif
      ELSE
        CALL wrf_message("ThompMP: computing qr_acr_qg table: "//qr_acr_qg_name)
!+---+-----------------------------------------------------------------+
        CALL start_timing

        do n2 = 1, nbr
!        vr(n2) = av_r*Dr(n2)**bv_r * DEXP(-fv_r*Dr(n2))
         vr(n2) = -0.1021 + 4.932E3*Dr(n2) - 0.9551E6*Dr(n2)*Dr(n2)     &
              + 0.07934E9*Dr(n2)*Dr(n2)*Dr(n2)                          &
              - 0.002362E12*Dr(n2)*Dr(n2)*Dr(n2)*Dr(n2)
        enddo
        do n3 = 1, NRHGtable
        do n = 1, nbg
         ! idx_bg indexes module coefficients, not vg
         if (.not. is_hail_aware) idx_bg = idx_bg1
         if (is_hail_aware) idx_bg = n3              
         vg(n,n3) = av_g(idx_bg)*Dg(n)**bv_g(idx_bg)
        enddo
        enddo

!..Note values returned from wrf_dm_decomp1d are zero-based, add 1 for
!.. fortran indices.  J. Michalakes, 2009Oct30.

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_decomp1d ( ntb_r*ntb_r1, km_s, km_e )
#else
        km_s = 0
        km_e = ntb_r*ntb_r1 - 1
#endif

        do km = km_s, km_e
         m = km / ntb_r1 + 1
         k = mod( km , ntb_r1 ) + 1

         lam_exp = (N0r_exp(k)*am_r*crg(1)/r_r(m))**ore1
         lamr = lam_exp * (crg(3)*org2*org1)**obmr
         N0_r = N0r_exp(k)/(crg(2)*lam_exp) * lamr**cre(2)
         do n2 = 1, nbr
            N_r(n2) = N0_r*Dr(n2)**mu_r *DEXP(-lamr*Dr(n2))*dtr(n2)
         enddo

         do n3 = 1, NRHGtable
          if (.not. is_hail_aware) idx_bg = idx_bg1
          if (is_hail_aware) idx_bg = n3              

         do j = 1, ntb_g
         do i = 1, ntb_g1
            lam_exp = (N0g_exp(i)*am_g(idx_bg)*cgg(1,1)/r_g(j))**oge1
            lamg = lam_exp * (cgg(3,1)*ogg2*ogg1)**obmg
            N0_g = N0g_exp(i)/(cgg(2,1)*lam_exp) * lamg**cge(2,1)
            do n = 1, nbg
               N_g(n) = N0_g*Dg(n)**mu_g * DEXP(-lamg*Dg(n))*dtg(n)
            enddo

            t1 = 0.0d0
            t2 = 0.0d0
            z1 = 0.0d0
            z2 = 0.0d0
            y1 = 0.0d0
            y2 = 0.0d0
            do n2 = 1, nbr
               massr = am_r * Dr(n2)**bm_r
               do n = 1, nbg
                  massg = am_g(idx_bg) * Dg(n)**bm_g

                  dvg = 0.5d0*((vr(n2) - vg(n,n3)) + DABS(vr(n2)-vg(n,n3)))
                  dvr = 0.5d0*((vg(n,n3) - vr(n2)) + DABS(vg(n,n3)-vr(n2)))

                  t1 = t1+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvg*massg * N_g(n)* N_r(n2)
                  z1 = z1+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvg*massr * N_g(n)* N_r(n2)
                  y1 = y1+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvg       * N_g(n)* N_r(n2)

                  t2 = t2+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvr*massr * N_g(n)* N_r(n2)
                  y2 = y2+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvr       * N_g(n)* N_r(n2)
                  z2 = z2+ PI*.25*Ef_rg*(Dg(n)+Dr(n2))*(Dg(n)+Dr(n2)) &
                      *dvr*massg * N_g(n)* N_r(n2)
               enddo
 97            continue
            enddo
            tcg_racg(i,j,n3,k,m) = t1
            tmr_racg(i,j,n3,k,m) = DMIN1(z1, r_r(m)*1.0d0)
            tcr_gacr(i,j,n3,k,m) = t2
            !tmg_gacr(i,j,n3,k,m) = DMIN1(z2, r_g(j)*1.0d0)
            tnr_racg(i,j,n3,k,m) = y1
            tnr_gacr(i,j,n3,k,m) = y2
         enddo
         enddo
         enddo
        enddo

!..Note wrf_dm_gatherv expects zero-based km_s, km_e (J. Michalakes, 2009Oct30).

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_gatherv(tcg_racg, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tmr_racg, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tcr_gacr, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
       !CALL wrf_dm_gatherv(tmg_gacr, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_racg, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_gacr, ntb_g*ntb_g1*NRHGtable, km_s, km_e, R8SIZE)
#endif
        CALL end_timing ( TRIM("table computation "//qr_acr_qg_name//"") )
!+---+-----------------------------------------------------------------+


        IF ( write_thompson_tables .AND. wrf_dm_on_monitor() ) THEN
          CALL wrf_message("Writing "//qr_acr_qg_name//" in Thompson MP init")
          OPEN(63,file=qr_acr_qg_name,form="unformatted",err=9234)
          WRITE(63,err=9234) tcg_racg
          WRITE(63,err=9234) tmr_racg
          WRITE(63,err=9234) tcr_gacr
          !WRITE(63,err=9234) tmg_gacr
          WRITE(63,err=9234) tnr_racg
          WRITE(63,err=9234) tnr_gacr
          CLOSE(63)
          RETURN    ! ----- RETURN
 9234     CONTINUE
          CALL wrf_error_fatal("Error writing "//qr_acr_qg_name//"")
        ENDIF
      ENDIF

      end subroutine qr_acr_qg
!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!..Rain collecting snow (and inverse).  Explicit CE integration.
!+---+-----------------------------------------------------------------+

      subroutine qr_acr_qs

      implicit none

!..Local variables
      INTEGER:: i, j, k, m, n, n2
      INTEGER:: km, km_s, km_e
      DOUBLE PRECISION, DIMENSION(nbr):: vr, D1, N_r
      DOUBLE PRECISION, DIMENSION(nbs):: vs, N_s
      DOUBLE PRECISION:: loga_, a_, b_, second, M0, M2, M3, Mrat, oM3
      DOUBLE PRECISION:: N0_r, lam_exp, lamr, slam1, slam2
      DOUBLE PRECISION:: dvs, dvr, masss, massr
      DOUBLE PRECISION:: t1, t2, t3, t4, z1, z2, z3, z4
      DOUBLE PRECISION:: y1, y2, y3, y4
      LOGICAL force_read_thompson, write_thompson_tables
      LOGICAL lexist,lopen
      INTEGER good
      LOGICAL, EXTERNAL :: wrf_dm_on_monitor

!+---+

      CALL nl_get_force_read_thompson(1,force_read_thompson)
      CALL nl_get_write_thompson_tables(1,write_thompson_tables)

      good = 0
      IF ( wrf_dm_on_monitor() ) THEN
        INQUIRE(FILE="qr_acr_qsV2.dat",EXIST=lexist)
        IF ( lexist ) THEN
          CALL wrf_message("ThompMP: read qr_acr_qsV2.dat instead of computing")
          OPEN(63,file="qr_acr_qsV2.dat",form="unformatted",err=1234)
          READ(63,err=1234)tcs_racs1
          READ(63,err=1234)tmr_racs1
          READ(63,err=1234)tcs_racs2
          READ(63,err=1234)tmr_racs2
          READ(63,err=1234)tcr_sacr1
          READ(63,err=1234)tms_sacr1
          READ(63,err=1234)tcr_sacr2
          READ(63,err=1234)tms_sacr2
          READ(63,err=1234)tnr_racs1
          READ(63,err=1234)tnr_racs2
          READ(63,err=1234)tnr_sacr1
          READ(63,err=1234)tnr_sacr2
          good = 1
 1234     CONTINUE
          IF ( good .NE. 1 ) THEN
            INQUIRE(63,opened=lopen)
            IF (lopen) THEN
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error reading qr_acr_qsV2.dat. Aborting because force_read_thompson is .true.")
              ENDIF
              CLOSE(63)
            ELSE
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error opening qr_acr_qsV2.dat. Aborting because force_read_thompson is .true.")
              ENDIF
            ENDIF
          ELSE
            INQUIRE(63,opened=lopen)
            IF (lopen) THEN
              CLOSE(63)
            ENDIF
          ENDIF
        ELSE
          IF( force_read_thompson ) THEN
            CALL wrf_error_fatal("Non-existent qr_acr_qsV2.dat. Aborting because force_read_thompson is .true.")
          ENDIF
        ENDIF
      ENDIF
#if defined(DM_PARALLEL) && !defined(STUBMPI)
      CALL wrf_dm_bcast_integer(good,1)
#endif

      IF ( good .EQ. 1 ) THEN
#if defined(DM_PARALLEL) && !defined(STUBMPI)
        CALL wrf_dm_bcast_double(tcs_racs1,SIZE(tcs_racs1))
        CALL wrf_dm_bcast_double(tmr_racs1,SIZE(tmr_racs1))
        CALL wrf_dm_bcast_double(tcs_racs2,SIZE(tcs_racs2))
        CALL wrf_dm_bcast_double(tmr_racs2,SIZE(tmr_racs2))
        CALL wrf_dm_bcast_double(tcr_sacr1,SIZE(tcr_sacr1))
        CALL wrf_dm_bcast_double(tms_sacr1,SIZE(tms_sacr1))
        CALL wrf_dm_bcast_double(tcr_sacr2,SIZE(tcr_sacr2))
        CALL wrf_dm_bcast_double(tms_sacr2,SIZE(tms_sacr2))
        CALL wrf_dm_bcast_double(tnr_racs1,SIZE(tnr_racs1))
        CALL wrf_dm_bcast_double(tnr_racs2,SIZE(tnr_racs2))
        CALL wrf_dm_bcast_double(tnr_sacr1,SIZE(tnr_sacr1))
        CALL wrf_dm_bcast_double(tnr_sacr2,SIZE(tnr_sacr2))
#endif
      ELSE
        CALL wrf_message("ThompMP: computing qr_acr_qs")
        do n2 = 1, nbr
!        vr(n2) = av_r*Dr(n2)**bv_r * DEXP(-fv_r*Dr(n2))
         vr(n2) = -0.1021 + 4.932E3*Dr(n2) - 0.9551E6*Dr(n2)*Dr(n2)     &
              + 0.07934E9*Dr(n2)*Dr(n2)*Dr(n2)                          &
              - 0.002362E12*Dr(n2)*Dr(n2)*Dr(n2)*Dr(n2)
         D1(n2) = (vr(n2)/av_s)**(1./bv_s)
        enddo
        do n = 1, nbs
         vs(n) = 1.5*av_s*Ds(n)**bv_s * DEXP(-fv_s*Ds(n))
        enddo

!..Note values returned from wrf_dm_decomp1d are zero-based, add 1 for
!.. fortran indices.  J. Michalakes, 2009Oct30.

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_decomp1d ( ntb_r*ntb_r1, km_s, km_e )
#else
        km_s = 0
        km_e = ntb_r*ntb_r1 - 1
#endif

        do km = km_s, km_e
         m = km / ntb_r1 + 1
         k = mod( km , ntb_r1 ) + 1

         lam_exp = (N0r_exp(k)*am_r*crg(1)/r_r(m))**ore1
         lamr = lam_exp * (crg(3)*org2*org1)**obmr
         N0_r = N0r_exp(k)/(crg(2)*lam_exp) * lamr**cre(2)
         do n2 = 1, nbr
            N_r(n2) = N0_r*Dr(n2)**mu_r * DEXP(-lamr*Dr(n2))*dtr(n2)
         enddo

         do j = 1, ntb_t
            do i = 1, ntb_s

!..From the bm_s moment, compute plus one moment.  If we are not
!.. using bm_s=2, then we must transform to the pure 2nd moment
!.. (variable called "second") and then to the bm_s+1 moment.

               M2 = r_s(i)*oams *1.0d0
               if (bm_s.gt.2.0-1.E-3 .and. bm_s.lt.2.0+1.E-3) then
                  loga_ = sa(1) + sa(2)*Tc(j) + sa(3)*bm_s &
                     + sa(4)*Tc(j)*bm_s + sa(5)*Tc(j)*Tc(j) &
                     + sa(6)*bm_s*bm_s + sa(7)*Tc(j)*Tc(j)*bm_s &
                     + sa(8)*Tc(j)*bm_s*bm_s + sa(9)*Tc(j)*Tc(j)*Tc(j) &
                     + sa(10)*bm_s*bm_s*bm_s
                  a_ = 10.0**loga_
                  b_ = sb(1) + sb(2)*Tc(j) + sb(3)*bm_s &
                     + sb(4)*Tc(j)*bm_s + sb(5)*Tc(j)*Tc(j) &
                     + sb(6)*bm_s*bm_s + sb(7)*Tc(j)*Tc(j)*bm_s &
                     + sb(8)*Tc(j)*bm_s*bm_s + sb(9)*Tc(j)*Tc(j)*Tc(j) &
                     + sb(10)*bm_s*bm_s*bm_s
                  second = (M2/a_)**(1./b_)
               else
                  second = M2
               endif

               loga_ = sa(1) + sa(2)*Tc(j) + sa(3)*cse(1) &
                  + sa(4)*Tc(j)*cse(1) + sa(5)*Tc(j)*Tc(j) &
                  + sa(6)*cse(1)*cse(1) + sa(7)*Tc(j)*Tc(j)*cse(1) &
                  + sa(8)*Tc(j)*cse(1)*cse(1) + sa(9)*Tc(j)*Tc(j)*Tc(j) &
                  + sa(10)*cse(1)*cse(1)*cse(1)
               a_ = 10.0**loga_
               b_ = sb(1)+sb(2)*Tc(j)+sb(3)*cse(1) + sb(4)*Tc(j)*cse(1) &
                  + sb(5)*Tc(j)*Tc(j) + sb(6)*cse(1)*cse(1) &
                  + sb(7)*Tc(j)*Tc(j)*cse(1) + sb(8)*Tc(j)*cse(1)*cse(1) &
                  + sb(9)*Tc(j)*Tc(j)*Tc(j)+sb(10)*cse(1)*cse(1)*cse(1)
               M3 = a_ * second**b_

               oM3 = 1./M3
               Mrat = M2*(M2*oM3)*(M2*oM3)*(M2*oM3)
               M0   = (M2*oM3)**mu_s
               slam1 = M2 * oM3 * Lam0
               slam2 = M2 * oM3 * Lam1

               do n = 1, nbs
                  N_s(n) = Mrat*(Kap0*DEXP(-slam1*Ds(n)) &
                      + Kap1*M0*Ds(n)**mu_s * DEXP(-slam2*Ds(n)))*dts(n)
               enddo

               t1 = 0.0d0
               t2 = 0.0d0
               t3 = 0.0d0
               t4 = 0.0d0
               z1 = 0.0d0
               z2 = 0.0d0
               z3 = 0.0d0
               z4 = 0.0d0
               y1 = 0.0d0
               y2 = 0.0d0
               y3 = 0.0d0
               y4 = 0.0d0
               do n2 = 1, nbr
                  massr = am_r * Dr(n2)**bm_r
                  do n = 1, nbs
                     masss = am_s * Ds(n)**bm_s
      
                     dvs = 0.5d0*((vr(n2) - vs(n)) + DABS(vr(n2)-vs(n)))
                     dvr = 0.5d0*((vs(n) - vr(n2)) + DABS(vs(n)-vr(n2)))

                     if (massr .gt. 1.5*masss) then
                     t1 = t1+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs*masss * N_s(n)* N_r(n2)
                     z1 = z1+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs*massr * N_s(n)* N_r(n2)
                     y1 = y1+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs       * N_s(n)* N_r(n2)
                     else
                     t3 = t3+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs*masss * N_s(n)* N_r(n2)
                     z3 = z3+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs*massr * N_s(n)* N_r(n2)
                     y3 = y3+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvs       * N_s(n)* N_r(n2)
                     endif

                     if (massr .gt. 1.5*masss) then
                     t2 = t2+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr*massr * N_s(n)* N_r(n2)
                     y2 = y2+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr       * N_s(n)* N_r(n2)
                     z2 = z2+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr*masss * N_s(n)* N_r(n2)
                     else
                     t4 = t4+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr*massr * N_s(n)* N_r(n2)
                     y4 = y4+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr       * N_s(n)* N_r(n2)
                     z4 = z4+ PI*.25*Ef_rs*(Ds(n)+Dr(n2))*(Ds(n)+Dr(n2)) &
                         *dvr*masss * N_s(n)* N_r(n2)
                     endif

                  enddo
               enddo
               tcs_racs1(i,j,k,m) = t1
               tmr_racs1(i,j,k,m) = DMIN1(z1, r_r(m)*1.0d0)
               tcs_racs2(i,j,k,m) = t3
               tmr_racs2(i,j,k,m) = z3
               tcr_sacr1(i,j,k,m) = t2
               tms_sacr1(i,j,k,m) = z2
               tcr_sacr2(i,j,k,m) = t4
               tms_sacr2(i,j,k,m) = z4
               tnr_racs1(i,j,k,m) = y1
               tnr_racs2(i,j,k,m) = y3
               tnr_sacr1(i,j,k,m) = y2
               tnr_sacr2(i,j,k,m) = y4
            enddo
         enddo
        enddo

!..Note wrf_dm_gatherv expects zero-based km_s, km_e (J. Michalakes, 2009Oct30).

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_gatherv(tcs_racs1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tmr_racs1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tcs_racs2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tmr_racs2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tcr_sacr1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tms_sacr1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tcr_sacr2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tms_sacr2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_racs1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_racs2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_sacr1, ntb_s*ntb_t, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_sacr2, ntb_s*ntb_t, km_s, km_e, R8SIZE)
#endif

        IF ( write_thompson_tables .AND. wrf_dm_on_monitor() ) THEN
          CALL wrf_message("Writing qr_acr_qsV2.dat in Thompson MP init")
          OPEN(63,file="qr_acr_qsV2.dat",form="unformatted",err=9234)
          WRITE(63,err=9234)tcs_racs1
          WRITE(63,err=9234)tmr_racs1
          WRITE(63,err=9234)tcs_racs2
          WRITE(63,err=9234)tmr_racs2
          WRITE(63,err=9234)tcr_sacr1
          WRITE(63,err=9234)tms_sacr1
          WRITE(63,err=9234)tcr_sacr2
          WRITE(63,err=9234)tms_sacr2
          WRITE(63,err=9234)tnr_racs1
          WRITE(63,err=9234)tnr_racs2
          WRITE(63,err=9234)tnr_sacr1
          WRITE(63,err=9234)tnr_sacr2
          CLOSE(63)
          RETURN    ! ----- RETURN
 9234     CONTINUE
          CALL wrf_error_fatal("Error writing qr_acr_qsV2.dat")
        ENDIF
      ENDIF

      end subroutine qr_acr_qs
!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!..This is a literal adaptation of Bigg (1954) probability of drops of
!..a particular volume freezing.  Given this probability, simply freeze
!..the proportion of drops summing their masses.
!+---+-----------------------------------------------------------------+

      subroutine freezeH2O

      implicit none

!..Local variables
      INTEGER:: i, j, k, m, n, n2
      INTEGER:: km, km_s, km_e
      DOUBLE PRECISION:: N_r, N_c
      DOUBLE PRECISION, DIMENSION(nbr):: massr
      DOUBLE PRECISION, DIMENSION(nbc):: massc
      DOUBLE PRECISION:: sum1, sum2, sumn1, sumn2, &
                         prob, vol, Texp, orho_w, &
                         lam_exp, lamr, N0_r, lamc, N0_c, y
      INTEGER:: nu_c
      REAL:: T_adjust
      LOGICAL force_read_thompson, write_thompson_tables
      LOGICAL lexist,lopen
      INTEGER good
      LOGICAL, EXTERNAL :: wrf_dm_on_monitor

!+---+
      CALL nl_get_force_read_thompson(1,force_read_thompson)
      CALL nl_get_write_thompson_tables(1,write_thompson_tables)

      good = 0
      IF ( wrf_dm_on_monitor() ) THEN
        INQUIRE(FILE="freezeH2O.dat",EXIST=lexist)
        IF ( lexist ) THEN
          CALL wrf_message("ThompMP: read freezeH2O.dat instead of computing")
          OPEN(63,file="freezeH2O.dat",form="unformatted",err=1234)
          READ(63,err=1234)tpi_qrfz
          READ(63,err=1234)tni_qrfz
          READ(63,err=1234)tpg_qrfz
          READ(63,err=1234)tnr_qrfz
          READ(63,err=1234)tpi_qcfz
          READ(63,err=1234)tni_qcfz
          good = 1
 1234     CONTINUE
          IF ( good .NE. 1 ) THEN
            INQUIRE(63,opened=lopen)
            IF (lopen) THEN
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error reading freezeH2O.dat. Aborting because force_read_thompson is .true.")
              ENDIF
              CLOSE(63)
            ELSE
              IF( force_read_thompson ) THEN
                CALL wrf_error_fatal("Error opening freezeH2O.dat. Aborting because force_read_thompson is .true.")
              ENDIF
            ENDIF
          ELSE
            INQUIRE(63,opened=lopen)
            IF (lopen) THEN
              CLOSE(63)
            ENDIF
          ENDIF
        ELSE
          IF( force_read_thompson ) THEN
            CALL wrf_error_fatal("Non-existent freezeH2O.dat. Aborting because force_read_thompson is .true.")
          ENDIF
        ENDIF
      ENDIF

#if defined(DM_PARALLEL) && !defined(STUBMPI)
      CALL wrf_dm_bcast_integer(good,1)
#endif

      IF ( good .EQ. 1 ) THEN
#if defined(DM_PARALLEL) && !defined(STUBMPI)
        CALL wrf_dm_bcast_double(tpi_qrfz,SIZE(tpi_qrfz))
        CALL wrf_dm_bcast_double(tni_qrfz,SIZE(tni_qrfz))
        CALL wrf_dm_bcast_double(tpg_qrfz,SIZE(tpg_qrfz))
        CALL wrf_dm_bcast_double(tnr_qrfz,SIZE(tnr_qrfz))
        CALL wrf_dm_bcast_double(tpi_qcfz,SIZE(tpi_qcfz))
        CALL wrf_dm_bcast_double(tni_qcfz,SIZE(tni_qcfz))
#endif
      ELSE
        CALL wrf_message("ThompMP: computing freezeH2O")

        orho_w = 1./rho_w

        do n2 = 1, nbr
         massr(n2) = am_r*Dr(n2)**bm_r
        enddo
        do n = 1, nbc
         massc(n) = am_r*Dc(n)**bm_r
        enddo

! Need to split loops between MPI processes to speedup
! (2017Jul26, Jason Do)
#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_decomp1d ( ntb_IN*45, km_s, km_e )
#else
        km_s = 0
        km_e = ntb_IN*45 - 1
#endif

!..Freeze water (smallest drops become cloud ice, otherwise graupel).
        do km = km_s, km_e
         m = km / 45 + 1
         k = mod( km , 45 ) + 1
         T_adjust = MAX(-3.0, MIN(3.0 - ALOG10(Nt_IN(m)), 3.0))
!         print*, ' Freezing water for temp = ', -k
         Texp = DEXP( DFLOAT(k) - T_adjust*1.0D0 ) - 1.0D0
#ifdef THOMPSON_OMP
!$OMP PARALLEL DO SCHEDULE(dynamic) &
!$OMP PRIVATE(j,i,lam_exp,lamr,N0_r,sum1,sum2,sumn1,sumn2,n2,N_r,vol,prob)
#endif
         do j = 1, ntb_r1
            do i = 1, ntb_r
               lam_exp = (N0r_exp(j)*am_r*crg(1)/r_r(i))**ore1
               lamr = lam_exp * (crg(3)*org2*org1)**obmr
               N0_r = N0r_exp(j)/(crg(2)*lam_exp) * lamr**cre(2)
               sum1 = 0.0d0
               sum2 = 0.0d0
               sumn1 = 0.0d0
               sumn2 = 0.0d0
               do n2 = nbr, 1, -1
                  N_r = N0_r*Dr(n2)**mu_r*DEXP(-lamr*Dr(n2))*dtr(n2)
                  vol = massr(n2)*orho_w
                  prob = MAX(0.0D0, 1.0D0 - DEXP(-120.0D0*vol*5.2D-4 * Texp))
                  if (massr(n2) .lt. xm0g) then
                     sumn1 = sumn1 + prob*N_r
                     sum1 = sum1 + prob*N_r*massr(n2)
                  else
                     sumn2 = sumn2 + prob*N_r
                     sum2 = sum2 + prob*N_r*massr(n2)
                  endif
                  if ((sum1+sum2).ge.r_r(i)) EXIT
               enddo
               tpi_qrfz(i,j,k,m) = sum1
               tni_qrfz(i,j,k,m) = sumn1
               tpg_qrfz(i,j,k,m) = sum2
               tnr_qrfz(i,j,k,m) = sumn2
            enddo
         enddo
#ifdef THOMPSON_OMP
!$OMP END PARALLEL DO

!$OMP PARALLEL DO SCHEDULE(dynamic) &
!$OMP PRIVATE(j,i,nu_c,lamc,N0_c,sum1,sumn2,vol,prob,N_c)
#endif
         do j = 1, nbc
            nu_c = MIN(15, NINT(1000.E6/t_Nc(j)) + 2)
            do i = 1, ntb_c
               lamc = (t_Nc(j)*am_r* ccg(2,nu_c) * ocg1(nu_c) / r_c(i))**obmr
               N0_c = t_Nc(j)*ocg1(nu_c) * lamc**cce(1,nu_c)
               sum1 = 0.0d0
               sumn2 = 0.0d0
               do n = nbc, 1, -1
                  vol = massc(n)*orho_w
                  prob = MAX(0.0D0, 1.0D0 - DEXP(-120.0D0*vol*5.2D-4 * Texp))
                  N_c = N0_c*Dc(n)**nu_c*EXP(-lamc*Dc(n))*dtc(n)
                  sumn2 = MIN(t_Nc(j), sumn2 + prob*N_c)
                  sum1 = sum1 + prob*N_c*massc(n)
                  if (sum1 .ge. r_c(i)) EXIT
               enddo
               tpi_qcfz(i,j,k,m) = sum1
               tni_qcfz(i,j,k,m) = sumn2
            enddo
         enddo
#ifdef THOMPSON_OMP
!$OMP END PARALLEL DO
#endif
        enddo

#if ( defined( DM_PARALLEL ) && ( ! defined( STUBMPI ) ) )
        CALL wrf_dm_gatherv(tpi_qrfz, ntb_r*ntb_r1, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tni_qrfz, ntb_r*ntb_r1, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tpg_qrfz, ntb_r*ntb_r1, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tnr_qrfz, ntb_r*ntb_r1, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tpi_qcfz, ntb_c*nbc, km_s, km_e, R8SIZE)
        CALL wrf_dm_gatherv(tni_qcfz, ntb_c*nbc, km_s, km_e, R8SIZE)
#endif

        IF ( write_thompson_tables .AND. wrf_dm_on_monitor() ) THEN
          CALL wrf_message("Writing freezeH2O.dat in Thompson MP init")
          OPEN(63,file="freezeH2O.dat",form="unformatted",err=9234)
          WRITE(63,err=9234)tpi_qrfz
          WRITE(63,err=9234)tni_qrfz
          WRITE(63,err=9234)tpg_qrfz
          WRITE(63,err=9234)tnr_qrfz
          WRITE(63,err=9234)tpi_qcfz
          WRITE(63,err=9234)tni_qcfz
          CLOSE(63)
          RETURN    ! ----- RETURN
 9234     CONTINUE
          CALL wrf_error_fatal("Error writing freezeH2O.dat")
        ENDIF
      ENDIF

      end subroutine freezeH2O

!+---+-----------------------------------------------------------------+
!ctrlL
!+---+-----------------------------------------------------------------+
!..Cloud ice converting to snow since portion greater than min snow
!.. size.  Given cloud ice content (kg/m**3), number concentration
!.. (#/m**3) and gamma shape parameter, mu_i, break the distrib into
!.. bins and figure out the mass/number of ice with sizes larger than
!.. D0s.  Also, compute incomplete gamma function for the integration
!.. of ice depositional growth from diameter=0 to D0s.  Amount of
!.. ice depositional growth is this portion of distrib while larger
!.. diameters contribute to snow growth (as in Harrington et al. 1995).
!+---+-----------------------------------------------------------------+

      subroutine qi_aut_qs

      implicit none

!..Local variables
      INTEGER:: i, j, n2
      DOUBLE PRECISION, DIMENSION(nbi):: N_i
      DOUBLE PRECISION:: N0_i, lami, Di_mean, t1, t2
      REAL:: xlimit_intg

!+---+

      do j = 1, ntb_i1
         do i = 1, ntb_i
            lami = (am_i*cig(2)*oig1*Nt_i(j)/r_i(i))**obmi
            Di_mean = (bm_i + mu_i + 1.) / lami
            N0_i = Nt_i(j)*oig1 * lami**cie(1)
            t1 = 0.0d0
            t2 = 0.0d0
            if (SNGL(Di_mean) .gt. 5.*D0s) then
             t1 = r_i(i)
             t2 = Nt_i(j)
             tpi_ide(i,j) = 0.0D0
            elseif (SNGL(Di_mean) .lt. D0i) then
             t1 = 0.0D0
             t2 = 0.0D0
             tpi_ide(i,j) = 1.0D0
            else
             xlimit_intg = lami*D0s
             tpi_ide(i,j) = GAMMP(mu_i+2.0, xlimit_intg) * 1.0D0
             do n2 = 1, nbi
               N_i(n2) = N0_i*Di(n2)**mu_i * DEXP(-lami*Di(n2))*dti(n2)
               if (Di(n2).ge.D0s) then
                  t1 = t1 + N_i(n2) * am_i*Di(n2)**bm_i
                  t2 = t2 + N_i(n2)
               endif
             enddo
            endif
            tps_iaus(i,j) = t1
            tni_iaus(i,j) = t2
         enddo
      enddo

      end subroutine qi_aut_qs
!ctrlL
!+---+-----------------------------------------------------------------+
!..Variable collision efficiency for rain collecting cloud water using
!.. method of Beard and Grover, 1974 if a/A less than 0.25; otherwise
!.. uses polynomials to get close match of Pruppacher & Klett Fig 14-9.
!+---+-----------------------------------------------------------------+

      subroutine table_Efrw

      implicit none

!..Local variables
      DOUBLE PRECISION:: vtr, stokes, reynolds, Ef_rw
      DOUBLE PRECISION:: p, yc0, F, G, H, z, K0, X
      INTEGER:: i, j

      do j = 1, nbc
      do i = 1, nbr
         Ef_rw = 0.0
         p = Dc(j)/Dr(i)
         if (Dr(i).lt.50.E-6 .or. Dc(j).lt.3.E-6) then
          t_Efrw(i,j) = 0.0
         elseif (p.gt.0.25) then
          X = Dc(j)*1.D6
          if (Dr(i) .lt. 75.e-6) then
             Ef_rw = 0.026794*X - 0.20604
          elseif (Dr(i) .lt. 125.e-6) then
             Ef_rw = -0.00066842*X*X + 0.061542*X - 0.37089
          elseif (Dr(i) .lt. 175.e-6) then
             Ef_rw = 4.091e-06*X*X*X*X - 0.00030908*X*X*X               &
                   + 0.0066237*X*X - 0.0013687*X - 0.073022
          elseif (Dr(i) .lt. 250.e-6) then
             Ef_rw = 9.6719e-5*X*X*X - 0.0068901*X*X + 0.17305*X        &
                   - 0.65988
          elseif (Dr(i) .lt. 350.e-6) then
             Ef_rw = 9.0488e-5*X*X*X - 0.006585*X*X + 0.16606*X         &
                   - 0.56125
          else
             Ef_rw = 0.00010721*X*X*X - 0.0072962*X*X + 0.1704*X        &
                   - 0.46929
          endif
         else
          vtr = -0.1021 + 4.932E3*Dr(i) - 0.9551E6*Dr(i)*Dr(i) &
              + 0.07934E9*Dr(i)*Dr(i)*Dr(i) &
              - 0.002362E12*Dr(i)*Dr(i)*Dr(i)*Dr(i)
          stokes = Dc(j)*Dc(j)*vtr*rho_w/(9.*1.718E-5*Dr(i))
          reynolds = 9.*stokes/(p*p*rho_w)

          F = DLOG(reynolds)
          G = -0.1007D0 - 0.358D0*F + 0.0261D0*F*F
          K0 = DEXP(G)
          z = DLOG(stokes/(K0+1.D-15))
          H = 0.1465D0 + 1.302D0*z - 0.607D0*z*z + 0.293D0*z*z*z
          yc0 = 2.0D0/PI * ATAN(H)
          Ef_rw = (yc0+p)*(yc0+p) / ((1.+p)*(1.+p))

         endif

         t_Efrw(i,j) = MAX(0.0, MIN(SNGL(Ef_rw), 0.95))

      enddo
      enddo

      end subroutine table_Efrw
!ctrlL
!+---+-----------------------------------------------------------------+
!..Variable collision efficiency for snow collecting cloud water using
!.. method of Wang and Ji, 2000 except equate melted snow diameter to
!.. their "effective collision cross-section."
!+---+-----------------------------------------------------------------+

      subroutine table_Efsw

      implicit none

!..Local variables
      DOUBLE PRECISION:: Ds_m, vts, vtc, stokes, reynolds, Ef_sw
      DOUBLE PRECISION:: p, yc0, F, G, H, z, K0
      INTEGER:: i, j

      do j = 1, nbc
      vtc = 1.19D4 * (1.0D4*Dc(j)*Dc(j)*0.25D0)
      do i = 1, nbs
         vts = av_s*Ds(i)**bv_s * DEXP(-fv_s*Ds(i)) - vtc
         Ds_m = (am_s*Ds(i)**bm_s / am_r)**obmr
         p = Dc(j)/Ds_m
         if (p.gt.0.25 .or. Ds(i).lt.D0s .or. Dc(j).lt.6.E-6 &
               .or. vts.lt.1.E-3) then
          t_Efsw(i,j) = 0.0
         else
          stokes = Dc(j)*Dc(j)*vts*rho_w/(9.*1.718E-5*Ds_m)
          reynolds = 9.*stokes/(p*p*rho_w)

          F = DLOG(reynolds)
          G = -0.1007D0 - 0.358D0*F + 0.0261D0*F*F
          K0 = DEXP(G)
          z = DLOG(stokes/(K0+1.D-15))
          H = 0.1465D0 + 1.302D0*z - 0.607D0*z*z + 0.293D0*z*z*z
          yc0 = 2.0D0/PI * ATAN(H)
          Ef_sw = (yc0+p)*(yc0+p) / ((1.+p)*(1.+p))

          t_Efsw(i,j) = MAX(0.0, MIN(SNGL(Ef_sw), 0.95))
         endif

      enddo
      enddo

      end subroutine table_Efsw
!ctrlL
!+---+-----------------------------------------------------------------+
!..Function to compute collision efficiency of collector species (rain,
!.. snow, graupel) of aerosols.  Follows Wang et al, 2010, ACP, which
!.. follows Slinn (1983).
!+---+-----------------------------------------------------------------+

      real function Eff_aero(D, Da, visc,rhoa,Temp,species)

      implicit none
      real:: D, Da, visc, rhoa, Temp
      character(LEN=1):: species
      real:: aval, Cc, diff, Re, Sc, St, St2, vt, Eff
      real, parameter:: boltzman = 1.3806503E-23
      real, parameter:: meanPath = 0.0256E-6

      vt = 1.
      if (species .eq. 'r') then
         vt = -0.1021 + 4.932E3*D - 0.9551E6*D*D                        &
              + 0.07934E9*D*D*D - 0.002362E12*D*D*D*D
      elseif (species .eq. 's') then
         vt = av_s*D**bv_s
      elseif (species .eq. 'g') then
         vt = av_g(idx_bg1)*D**bv_g(idx_bg1)
      endif

      Cc    = 1. + 2.*meanPath/Da *(1.257+0.4*exp(-0.55*Da/meanPath))
      diff  = boltzman*Temp*Cc/(3.*PI*visc*Da)

      Re    = 0.5*rhoa*D*vt/visc
      Sc    = visc/(rhoa*diff)

      St    = Da*Da*vt*1000./(9.*visc*D)
      aval  = 1.+LOG(1.+Re)
      St2   = (1.2 + 1./12.*aval)/(1.+aval)

      Eff = 4./(Re*Sc) * (1. + 0.4*SQRT(Re)*Sc**0.3333                  &
                             + 0.16*SQRT(Re)*SQRT(Sc))                  &
               + 4.*Da/D * (0.02 + Da/D*(1.+2.*SQRT(Re)))

      if (St.gt.St2) Eff = Eff  + ( (St-St2)/(St-St2+0.666667))**1.5
      Eff_aero = MAX(1.E-5, MIN(Eff, 1.0))

      end function Eff_aero

!ctrlL
!+---+-----------------------------------------------------------------+
!..Integrate rain size distribution from zero to D-star to compute the
!.. number of drops smaller than D-star that evaporate in a single
!.. timestep.  Drops larger than D-star dont evaporate entirely so do
!.. not affect number concentration.
!+---+-----------------------------------------------------------------+

      subroutine table_dropEvap

      implicit none

!..Local variables
      INTEGER:: i, j, k, n
      DOUBLE PRECISION, DIMENSION(nbc):: N_c, massc
      DOUBLE PRECISION:: summ, summ2, lamc, N0_c
      INTEGER:: nu_c
!      DOUBLE PRECISION:: Nt_r, N0, lam_exp, lam
!      REAL:: xlimit_intg

      do n = 1, nbc
         massc(n) = am_r*Dc(n)**bm_r
      enddo

      do k = 1, nbc
         nu_c = MIN(15, NINT(1000.E6/t_Nc(k)) + 2)
         do j = 1, ntb_c
            lamc = (t_Nc(k)*am_r* ccg(2,nu_c)*ocg1(nu_c) / r_c(j))**obmr
            N0_c = t_Nc(k)*ocg1(nu_c) * lamc**cce(1,nu_c)
            do i = 1, nbc
!-GT           tnc_wev(i,j,k) = GAMMP(nu_c+1., SNGL(Dc(i)*lamc))*t_Nc(k)
               N_c(i) = N0_c* Dc(i)**nu_c*EXP(-lamc*Dc(i))*dtc(i)
!     if(j.eq.18 .and. k.eq.50) print*, ' N_c = ', N_c(i)
               summ = 0.
               summ2 = 0.
               do n = 1, i
                  summ = summ + massc(n)*N_c(n)
                  summ2 = summ2 + N_c(n)
               enddo
!      if(j.eq.18 .and. k.eq.50) print*, '  DEBUG-TABLE: ', r_c(j), t_Nc(k), summ2, summ
               tpc_wev(i,j,k) = summ
               tnc_wev(i,j,k) = summ2
            enddo
         enddo
      enddo

!
!..To do the same thing for rain.
!
!     do k = 1, ntb_r
!     do j = 1, ntb_r1
!        lam_exp = (N0r_exp(j)*am_r*crg(1)/r_r(k))**ore1
!        lam = lam_exp * (crg(3)*org2*org1)**obmr
!        N0 = N0r_exp(j)/(crg(2)*lam_exp) * lam**cre(2)
!        Nt_r = N0 * crg(2) / lam**cre(2)
!        do i = 1, nbr
!           xlimit_intg = lam*Dr(i)
!           tnr_rev(i,j,k) = GAMMP(mu_r+1.0, xlimit_intg) * Nt_r
!        enddo
!     enddo
!     enddo

! TO APPLY TABLE ABOVE
!..Rain lookup table indexes.
!         Dr_star = DSQRT(-2.D0*DT * t1_evap/(2.*PI) &
!                 * 0.78*4.*diffu(k)*xsat*rvs/rho_w)
!         idx_d = NINT(1.0 + FLOAT(nbr) * DLOG(Dr_star/D0r)             &
!               / DLOG(Dr(nbr)/D0r))
!         idx_d = MAX(1, MIN(idx_d, nbr))
!
!         nir = NINT(ALOG10(rr(k)))
!         do nn = nir-1, nir+1
!            n = nn
!            if ( (rr(k)/10.**nn).ge.1.0 .and. &
!                 (rr(k)/10.**nn).lt.10.0) goto 154
!         enddo
!154      continue
!         idx_r = INT(rr(k)/10.**n) + 10*(n-nir2) - (n-nir2)
!         idx_r = MAX(1, MIN(idx_r, ntb_r))
!
!         lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
!         lam_exp = lamr * (crg(3)*org2*org1)**bm_r
!         N0_exp = org1*rr(k)/am_r * lam_exp**cre(1)
!         nir = NINT(DLOG10(N0_exp))
!         do nn = nir-1, nir+1
!            n = nn
!            if ( (N0_exp/10.**nn).ge.1.0 .and. &
!                 (N0_exp/10.**nn).lt.10.0) goto 155
!         enddo
!155      continue
!         idx_r1 = INT(N0_exp/10.**n) + 10*(n-nir3) - (n-nir3)
!         idx_r1 = MAX(1, MIN(idx_r1, ntb_r1))
!
!         pnr_rev(k) = MIN(nr(k)*odts, SNGL(tnr_rev(idx_d,idx_r1,idx_r) &   ! RAIN2M
!                    * odts))

      end subroutine table_dropEvap
!
!ctrlL
!+---+-----------------------------------------------------------------+
!..Fill the table of CCN activation data created from parcel model run
!.. by Trude Eidhammer with inputs of aerosol number concentration,
!.. vertical velocity, temperature, lognormal mean aerosol radius, and
!.. hygroscopicity, kappa.  The data are read from external file and
!.. contain activated fraction of CCN for given conditions.
!+---+-----------------------------------------------------------------+

      subroutine table_ccnAct

      USE module_domain
      USE module_dm
      implicit none

      LOGICAL, EXTERNAL:: wrf_dm_on_monitor

!..Local variables
      INTEGER:: iunit_mp_th1, i
      LOGICAL:: opened
      CHARACTER*64 errmess

      iunit_mp_th1 = -1
      IF ( wrf_dm_on_monitor() ) THEN
        DO i = 20,99
          INQUIRE ( i , OPENED = opened )
          IF ( .NOT. opened ) THEN
            iunit_mp_th1 = i
            GOTO 2010
          ENDIF
        ENDDO
 2010   CONTINUE
      ENDIF
#if defined(DM_PARALLEL) && !defined(STUBMPI)
      CALL wrf_dm_bcast_bytes ( iunit_mp_th1 , IWORDSIZE )
#endif
      IF ( iunit_mp_th1 < 0 ) THEN
        CALL wrf_error_fatal ( 'module_mp_thompson: table_ccnAct: '//   &
           'Can not find unused fortran unit to read in lookup table.')
      ENDIF

      IF ( wrf_dm_on_monitor() ) THEN
        WRITE(errmess, '(A,I2)') 'module_mp_thompson: opening CCN_ACTIVATE.BIN on unit ',iunit_mp_th1
        CALL wrf_debug(150, errmess)
        OPEN(iunit_mp_th1,FILE='CCN_ACTIVATE.BIN',                      &
             FORM='UNFORMATTED',STATUS='OLD',ERR=9009)
      ENDIF

#define DM_BCAST_MACRO(A) CALL wrf_dm_bcast_bytes(A, size(A)*R4SIZE)

      IF ( wrf_dm_on_monitor() ) READ(iunit_mp_th1,ERR=9010) tnccn_act
#if defined(DM_PARALLEL) && !defined(STUBMPI)
      DM_BCAST_MACRO(tnccn_act)
#endif


      RETURN
 9009 CONTINUE
      WRITE( errmess , '(A,I2)' ) 'module_mp_thompson: error opening CCN_ACTIVATE.BIN on unit ',iunit_mp_th1
      CALL wrf_error_fatal(errmess)
      RETURN
 9010 CONTINUE
      WRITE( errmess , '(A,I2)' ) 'module_mp_thompson: error reading CCN_ACTIVATE.BIN on unit ',iunit_mp_th1
      CALL wrf_error_fatal(errmess)

      end subroutine table_ccnAct
!^L
!+---+-----------------------------------------------------------------+
!..Retrieve fraction of CCN that gets activated given the model temp,
!.. vertical velocity, and available CCN concentration.  The lookup
!.. table (read from external file) has CCN concentration varying the
!.. quickest, then updraft, then temperature, then mean aerosol radius,
!.. and finally hygroscopicity, kappa.
!.. TO_DO ITEM:  For radiation cooling producing fog, in which case the
!.. updraft velocity could easily be negative, we could use the temp
!.. and its tendency to diagnose a pretend postive updraft velocity.
!+---+-----------------------------------------------------------------+
      real function activ_ncloud(Tt, Ww, NCCN)

      implicit none
      REAL, INTENT(IN):: Tt, Ww, NCCN
      REAL:: n_local, w_local
      INTEGER:: i, j, k, l, m, n
      REAL:: A, B, C, D, t, u, x1, x2, y1, y2, nx, wy, fraction


!     ta_Na = (/10.0, 31.6, 100.0, 316.0, 1000.0, 3160.0, 10000.0/)  ntb_arc
!     ta_Ww = (/0.01, 0.0316, 0.1, 0.316, 1.0, 3.16, 10.0, 31.6, 100.0/)  ntb_arw
!     ta_Tk = (/243.15, 253.15, 263.15, 273.15, 283.15, 293.15, 303.15/)  ntb_art
!     ta_Ra = (/0.01, 0.02, 0.04, 0.08, 0.16/)  ntb_arr
!     ta_Ka = (/0.2, 0.4, 0.6, 0.8/)  ntb_ark

      n_local = NCCN * 1.E-6
      w_local = Ww

      if (n_local .ge. ta_Na(ntb_arc)) then
         n_local = ta_Na(ntb_arc) - 1.0
      elseif (n_local .le. ta_Na(1)) then
         n_local = ta_Na(1) + 1.0
      endif
      do n = 2, ntb_arc
         if (n_local.ge.ta_Na(n-1) .and. n_local.lt.ta_Na(n)) goto 8003
      enddo
 8003 continue
      i = n
      x1 = LOG(ta_Na(i-1))
      x2 = LOG(ta_Na(i))

      if (w_local .ge. ta_Ww(ntb_arw)) then
         w_local = ta_Ww(ntb_arw) - 1.0
      elseif (w_local .le. ta_Ww(1)) then
         w_local = ta_Ww(1) + 0.001
      endif
      do n = 2, ntb_arw
         if (w_local.ge.ta_Ww(n-1) .and. w_local.lt.ta_Ww(n)) goto 8005
      enddo
 8005 continue
      j = n
      y1 = LOG(ta_Ww(j-1))
      y2 = LOG(ta_Ww(j))

      k = MAX(1, MIN( NINT( (Tt - ta_Tk(1))*0.1) + 1, ntb_art))

!..The next two values are indexes of mean aerosol radius and
!.. hygroscopicity.  Currently these are constant but a future version
!.. should implement other variables to allow more freedom such as
!.. at least simple separation of tiny size sulfates from larger
!.. sea salts.
      l = 3
      m = 2

      A = tnccn_act(i-1,j-1,k,l,m)
      B = tnccn_act(i,j-1,k,l,m)
      C = tnccn_act(i,j,k,l,m)
      D = tnccn_act(i-1,j,k,l,m)
      nx = LOG(n_local)
      wy = LOG(w_local)

      t = (nx-x1)/(x2-x1)
      u = (wy-y1)/(y2-y1)

!     t = (n_local-ta(Na(i-1))/(ta_Na(i)-ta_Na(i-1))
!     u = (w_local-ta_Ww(j-1))/(ta_Ww(j)-ta_Ww(j-1))

      fraction = (1.0-t)*(1.0-u)*A + t*(1.0-u)*B + t*u*C + (1.0-t)*u*D

!     if (NCCN*fraction .gt. 0.75*Nt_c_max) then
!        write(*,*) ' DEBUG-GT ', n_local, w_local, Tt, i, j, k
!     endif

      activ_ncloud = NCCN*fraction

      end function activ_ncloud

!+---+-----------------------------------------------------------------+
!+---+-----------------------------------------------------------------+
      SUBROUTINE GCF(GAMMCF,A,X,GLN)
!     --- RETURNS THE INCOMPLETE GAMMA FUNCTION Q(A,X) EVALUATED BY ITS
!     --- CONTINUED FRACTION REPRESENTATION AS GAMMCF.  ALSO RETURNS
!     --- LN(GAMMA(A)) AS GLN.  THE CONTINUED FRACTION IS EVALUATED BY
!     --- A MODIFIED LENTZ METHOD.
!     --- USES GAMMLN
      IMPLICIT NONE
      INTEGER, PARAMETER:: ITMAX=100
      REAL, PARAMETER:: gEPS=3.E-7
      REAL, PARAMETER:: FPMIN=1.E-30
      REAL, INTENT(IN):: A, X
      REAL:: GAMMCF,GLN
      INTEGER:: I
      REAL:: AN,B,C,D,DEL,H
      GLN=GAMMLN(A)
      B=X+1.-A
      C=1./FPMIN
      D=1./B
      H=D
      DO 11 I=1,ITMAX
        AN=-I*(I-A)
        B=B+2.
        D=AN*D+B
        IF(ABS(D).LT.FPMIN)D=FPMIN
        C=B+AN/C
        IF(ABS(C).LT.FPMIN)C=FPMIN
        D=1./D
        DEL=D*C
        H=H*DEL
        IF(ABS(DEL-1.).LT.gEPS)GOTO 1
 11   CONTINUE
      PRINT *, 'A TOO LARGE, ITMAX TOO SMALL IN GCF'
 1    GAMMCF=EXP(-X+A*LOG(X)-GLN)*H
      END SUBROUTINE GCF
!  (C) Copr. 1986-92 Numerical Recipes Software 2.02
!+---+-----------------------------------------------------------------+
      SUBROUTINE GSER(GAMSER,A,X,GLN)
!     --- RETURNS THE INCOMPLETE GAMMA FUNCTION P(A,X) EVALUATED BY ITS
!     --- ITS SERIES REPRESENTATION AS GAMSER.  ALSO RETURNS LN(GAMMA(A)) 
!     --- AS GLN.
!     --- USES GAMMLN
      IMPLICIT NONE
      INTEGER, PARAMETER:: ITMAX=100
      REAL, PARAMETER:: gEPS=3.E-7
      REAL, INTENT(IN):: A, X
      REAL:: GAMSER,GLN
      INTEGER:: N
      REAL:: AP,DEL,SUM
      GLN=GAMMLN(A)
      IF(X.LE.0.)THEN
        IF(X.LT.0.) PRINT *, 'X < 0 IN GSER'
        GAMSER=0.
        RETURN
      ENDIF
      AP=A
      SUM=1./A
      DEL=SUM
      DO 11 N=1,ITMAX
        AP=AP+1.
        DEL=DEL*X/AP
        SUM=SUM+DEL
        IF(ABS(DEL).LT.ABS(SUM)*gEPS)GOTO 1
 11   CONTINUE
      PRINT *,'A TOO LARGE, ITMAX TOO SMALL IN GSER'
 1    GAMSER=SUM*EXP(-X+A*LOG(X)-GLN)
      END SUBROUTINE GSER
!  (C) Copr. 1986-92 Numerical Recipes Software 2.02
!+---+-----------------------------------------------------------------+
      REAL FUNCTION GAMMLN(XX)
!     --- RETURNS THE VALUE LN(GAMMA(XX)) FOR XX > 0.
      IMPLICIT NONE
      REAL, INTENT(IN):: XX
      DOUBLE PRECISION, PARAMETER:: STP = 2.5066282746310005D0
      DOUBLE PRECISION, DIMENSION(6), PARAMETER:: &
               COF = (/76.18009172947146D0, -86.50532032941677D0, &
                       24.01409824083091D0, -1.231739572450155D0, &
                      .1208650973866179D-2, -.5395239384953D-5/)
      DOUBLE PRECISION:: SER,TMP,X,Y
      INTEGER:: J

      X=XX
      Y=X
      TMP=X+5.5D0
      TMP=(X+0.5D0)*LOG(TMP)-TMP
      SER=1.000000000190015D0
      DO 11 J=1,6
        Y=Y+1.D0
        SER=SER+COF(J)/Y
11    CONTINUE
      GAMMLN=TMP+LOG(STP*SER/X)
      END FUNCTION GAMMLN
!  (C) Copr. 1986-92 Numerical Recipes Software 2.02
!+---+-----------------------------------------------------------------+
      REAL FUNCTION GAMMP(A,X)
!     --- COMPUTES THE INCOMPLETE GAMMA FUNCTION P(A,X)
!     --- SEE ABRAMOWITZ AND STEGUN 6.5.1
!     --- USES GCF,GSER
      IMPLICIT NONE
      REAL, INTENT(IN):: A,X
      REAL:: GAMMCF,GAMSER,GLN
      GAMMP = 0.
      IF((X.LT.0.) .OR. (A.LE.0.)) THEN
        PRINT *, 'BAD ARGUMENTS IN GAMMP'
        RETURN
      ELSEIF(X.LT.A+1.)THEN
        CALL GSER(GAMSER,A,X,GLN)
        GAMMP=GAMSER
      ELSE
        CALL GCF(GAMMCF,A,X,GLN)
        GAMMP=1.-GAMMCF
      ENDIF
      END FUNCTION GAMMP
!  (C) Copr. 1986-92 Numerical Recipes Software 2.02
!+---+-----------------------------------------------------------------+
      REAL FUNCTION WGAMMA(y)

      IMPLICIT NONE
      REAL, INTENT(IN):: y

      WGAMMA = EXP(GAMMLN(y))

      END FUNCTION WGAMMA
!+---+-----------------------------------------------------------------+
! THIS FUNCTION CALCULATES THE LIQUID SATURATION VAPOR MIXING RATIO AS
! A FUNCTION OF TEMPERATURE AND PRESSURE
!
      REAL FUNCTION RSLF(P,T)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE
      REAL, INTENT(IN):: P, T
      REAL:: ESL,X
      REAL, PARAMETER:: C0= .611583699E03
      REAL, PARAMETER:: C1= .444606896E02
      REAL, PARAMETER:: C2= .143177157E01
      REAL, PARAMETER:: C3= .264224321E-1
      REAL, PARAMETER:: C4= .299291081E-3
      REAL, PARAMETER:: C5= .203154182E-5
      REAL, PARAMETER:: C6= .702620698E-8
      REAL, PARAMETER:: C7= .379534310E-11
      REAL, PARAMETER:: C8=-.321582393E-13

      X=MAX(-80.,T-273.16)

!      ESL=612.2*EXP(17.67*X/(T-29.65))
      ESL=C0+X*(C1+X*(C2+X*(C3+X*(C4+X*(C5+X*(C6+X*(C7+X*C8)))))))
      ESL=MIN(ESL, P*0.15)        ! Even with P=1050mb and T=55C, the sat. vap. pres only contributes to ~15% of total pres.
      RSLF=.622*ESL/(P-ESL)

!    ALTERNATIVE
!  ; Source: Murphy and Koop, Review of the vapour pressure of ice and
!             supercooled water for atmospheric applications, Q. J. R.
!             Meteorol. Soc (2005), 131, pp. 1539-1565.
!    ESL = EXP(54.842763 - 6763.22 / T - 4.210 * ALOG(T) + 0.000367 * T
!        + TANH(0.0415 * (T - 218.8)) * (53.878 - 1331.22
!        / T - 9.44523 * ALOG(T) + 0.014025 * T))

      END FUNCTION RSLF
!+---+-----------------------------------------------------------------+
! THIS FUNCTION CALCULATES THE ICE SATURATION VAPOR MIXING RATIO AS A
! FUNCTION OF TEMPERATURE AND PRESSURE
!
      REAL FUNCTION RSIF(P,T)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE
      REAL, INTENT(IN):: P, T
      REAL:: ESI,X
      REAL, PARAMETER:: C0= .609868993E03
      REAL, PARAMETER:: C1= .499320233E02
      REAL, PARAMETER:: C2= .184672631E01
      REAL, PARAMETER:: C3= .402737184E-1
      REAL, PARAMETER:: C4= .565392987E-3
      REAL, PARAMETER:: C5= .521693933E-5
      REAL, PARAMETER:: C6= .307839583E-7
      REAL, PARAMETER:: C7= .105785160E-9
      REAL, PARAMETER:: C8= .161444444E-12

      X=MAX(-80.,T-273.16)
      ESI=C0+X*(C1+X*(C2+X*(C3+X*(C4+X*(C5+X*(C6+X*(C7+X*C8)))))))
      ESI=MIN(ESI, P*0.15)
      RSIF=.622*ESI/max(1.e-4,(P-ESI))

!    ALTERNATIVE
!  ; Source: Murphy and Koop, Review of the vapour pressure of ice and
!             supercooled water for atmospheric applications, Q. J. R.
!             Meteorol. Soc (2005), 131, pp. 1539-1565.
!     ESI = EXP(9.550426 - 5723.265/T + 3.53068*ALOG(T) - 0.00728332*T)

      END FUNCTION RSIF

!+---+-----------------------------------------------------------------+
      real function iceDeMott(tempc, qv, qvs, qvsi, rho, nifa)
      implicit none

      REAL, INTENT(IN):: tempc, qv, qvs, qvsi, rho, nifa

!..Local vars
      REAL:: satw, sati, siw, p_x, si0x, dtt, dsi, dsw, dab, fc, hx
      REAL:: ntilde, n_in, nmax, nhat, mux, xni, nifa_cc
      REAL, PARAMETER:: p_c1    = 1000.
      REAL, PARAMETER:: p_rho_c = 0.76
      REAL, PARAMETER:: p_alpha = 1.0
      REAL, PARAMETER:: p_gam   = 2.
      REAL, PARAMETER:: delT    = 5.
      REAL, PARAMETER:: T0x     = -40.
      REAL, PARAMETER:: Sw0x    = 0.97
      REAL, PARAMETER:: delSi   = 0.1
      REAL, PARAMETER:: hdm     = 0.15
      REAL, PARAMETER:: p_psi   = 0.058707*p_gam/p_rho_c
      REAL, PARAMETER:: aap     = 1.
      REAL, PARAMETER:: bbp     = 0.
      REAL, PARAMETER:: y1p     = -35.
      REAL, PARAMETER:: y2p     = -25.
      REAL, PARAMETER:: rho_not0 = 101325./(287.05*273.15)

!+---+

      xni = 0.0
!     satw = qv/qvs
!     sati = qv/qvsi
!     siw = qvs/qvsi
!     p_x = -1.0261+(3.1656e-3*tempc)+(5.3938e-4*(tempc*tempc))         &
!                +  (8.2584e-6*(tempc*tempc*tempc))
!     si0x = 1.+(10.**p_x)
!     if (sati.ge.si0x .and. satw.lt.0.985) then
!        dtt = delta_p (tempc, T0x, T0x+delT, 1., hdm)
!        dsi = delta_p (sati, Si0x, Si0x+delSi, 0., 1.)
!        dsw = delta_p (satw, Sw0x, 1., 0., 1.)
!        fc = dtt*dsi*0.5
!        hx = min(fc+((1.-fc)*dsw), 1.)
!        ntilde = p_c1*p_gam*((exp(12.96*(sati-1.1)))**0.3) / p_rho_c
!        if (tempc .le. y1p) then
!           n_in = ntilde
!        elseif (tempc .ge. y2p) then
!           n_in = p_psi*p_c1*exp(12.96*(sati-1.)-0.639)
!        else
!           if (tempc .le. -30.) then
!              nmax = p_c1*p_gam*(exp(12.96*(siw-1.1)))**0.3/p_rho_c
!           else
!              nmax = p_psi*p_c1*exp(12.96*(siw-1.)-0.639)
!           endif
!           ntilde = MIN(ntilde, nmax)
!           nhat = MIN(p_psi*p_c1*exp(12.96*(sati-1.)-0.639), nmax)
!           dab = delta_p (tempc, y1p, y2p, aap, bbp)
!           n_in = MIN(nhat*(ntilde/nhat)**dab, nmax)
!        endif
!        mux = hx*p_alpha*n_in*rho
!        xni = mux*((6700.*nifa)-200.)/((6700.*5.E5)-200.)
!     elseif (satw.ge.0.985 .and. tempc.gt.HGFR-273.15) then
         nifa_cc = MAX(0.5, nifa*RHO_NOT0*1.E-6/rho)
!        xni  = 3.*nifa_cc**(1.25)*exp((0.46*(-tempc))-11.6)              !  [DeMott, 2015]
         xni = (5.94e-5*(-tempc)**3.33)                                 & !  [DeMott, 2010]
                    * (nifa_cc**((-0.0264*(tempc))+0.0033))
         xni = xni*rho/RHO_NOT0 * 1000.
!     endif

      iceDeMott = MAX(0., xni)

      end FUNCTION iceDeMott

!+---+-----------------------------------------------------------------+
!..Newer research since Koop et al (2001) suggests that the freezing
!.. rate should be lower than original paper, so J_rate is reduced
!.. by two orders of magnitude.

      real function iceKoop(temp, qv, qvs, naero, dt)
      implicit none

      REAL, INTENT(IN):: temp, qv, qvs, naero, DT
      REAL:: mu_diff, a_w_i, delta_aw, log_J_rate, J_rate, prob_h, satw
      REAL:: xni

      xni = 0.0
      satw = qv/qvs
      mu_diff    = 210368.0 + (131.438*temp) - (3.32373E6/temp)         &
     &           - (41729.1*alog(temp))
      a_w_i      = exp(mu_diff/(R_uni*temp))
      delta_aw   = satw - a_w_i
      log_J_rate = -906.7 + (8502.0*delta_aw)                           &
     &           - (26924.0*delta_aw*delta_aw)                          &
     &           + (29180.0*delta_aw*delta_aw*delta_aw)
      log_J_rate = MIN(20.0, log_J_rate)
      J_rate     = 10.**log_J_rate                                       ! cm-3 s-1
      prob_h     = MIN(1.-exp(-J_rate*ar_volume*DT), 1.)
      if (prob_h .gt. 0.) then
         xni     = MIN(prob_h*naero, 1000.E3)
      endif

      iceKoop = MAX(0.0, xni)

      end FUNCTION iceKoop

!+---+-----------------------------------------------------------------+
!.. Helper routine for Phillips et al (2008) ice nucleation.  Trude

      REAL FUNCTION delta_p (yy, y1, y2, aa, bb)
      IMPLICIT NONE

      REAL, INTENT(IN):: yy, y1, y2, aa, bb
      REAL:: dab, A, B, a0, a1, a2, a3

      A   = 6.*(aa-bb)/((y2-y1)*(y2-y1)*(y2-y1))
      B   = aa+(A*y1*y1*y1/6.)-(A*y1*y1*y2*0.5)
      a0  = B
      a1  = A*y1*y2
      a2  = -A*(y1+y2)*0.5
      a3  = A/3.

      if (yy.le.y1) then 
         dab = aa
      else if (yy.ge.y2) then
         dab = bb
      else
         dab = a0+(a1*yy)+(a2*yy*yy)+(a3*yy*yy*yy)
      endif

      if (dab.lt.aa) then 
         dab = aa
      endif
      if (dab.gt.bb) then 
         dab = bb
      endif
      delta_p = dab

      END FUNCTION delta_p 

!+---+-----------------------------------------------------------------+
!ctrlL

!+---+-----------------------------------------------------------------+
!..Compute _radiation_ effective radii of cloud water, ice, and snow.
!.. These are entirely consistent with microphysics assumptions, not
!.. constant or otherwise ad hoc as is internal to most radiation
!.. schemes.  Since only the smallest snowflakes should impact
!.. radiation, compute from first portion of complicated Field number
!.. distribution, not the second part, which is the larger sizes.
!+---+-----------------------------------------------------------------+

      subroutine calc_effectRad (t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d,   &
     &                re_qc1d, re_qi1d, re_qs1d, kts, kte)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE

!..Sub arguments
      INTEGER, INTENT(IN):: kts, kte
      REAL, DIMENSION(kts:kte), INTENT(IN)::                            &
     &                    t1d, p1d, qv1d, qc1d, nc1d, qi1d, ni1d, qs1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: re_qc1d, re_qi1d, re_qs1d
!..Local variables
      INTEGER:: k
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rho, rc, nc, ri, ni, rs
#else
      REAL, DIMENSION(kts:kte):: rho, rc, nc, ri, ni, rs
#endif
      REAL:: smo2, smob, smoc
      REAL:: tc0, loga_, a_, b_
      DOUBLE PRECISION:: lamc, lami
      LOGICAL:: has_qc, has_qi, has_qs
      INTEGER:: inu_c
      real, dimension(15), parameter:: g_ratio = (/24,60,120,210,336,   &
     &                504,720,990,1320,1716,2184,2730,3360,4080,4896/)

      has_qc = .false.
      has_qi = .false.
      has_qs = .false.

      re_qc1d(:) = RE_QC_BG
      re_qi1d(:) = RE_QI_BG
      re_qs1d(:) = RE_QS_BG

      do k = kts, kte
         rho(k) = 0.622*p1d(k)/(R*t1d(k)*(qv1d(k)+0.622))
         rc(k) = MAX(R1, qc1d(k)*rho(k))
         nc(k) = MAX(2., MIN(nc1d(k)*rho(k), Nt_c_max))
         if (.NOT. is_aerosol_aware) nc(k) = Nt_c
         if (rc(k).gt.R1 .and. nc(k).gt.R2) has_qc = .true.
         ri(k) = MAX(R1, qi1d(k)*rho(k))
         ni(k) = MAX(R2, ni1d(k)*rho(k))
         if (ri(k).gt.R1 .and. ni(k).gt.R2) has_qi = .true.
         rs(k) = MAX(R1, qs1d(k)*rho(k))
         if (rs(k).gt.R1) has_qs = .true.
      enddo

      if (has_qc) then
      do k = kts, kte
         if (rc(k).le.R1 .or. nc(k).le.R2) CYCLE
         if (nc(k).lt.100) then
            inu_c = 15
         elseif (nc(k).gt.1.E10) then
            inu_c = 2
         else
            inu_c = MIN(15, NINT(1000.E6/nc(k)) + 2)
         endif
         lamc = (nc(k)*am_r*g_ratio(inu_c)/rc(k))**obmr
         re_qc1d(k) = MAX(2.51E-6, MIN(SNGL(0.5D0 * DBLE(3.+inu_c)/lamc), 50.E-6))
      enddo
      endif

      if (has_qi) then
      do k = kts, kte
         if (ri(k).le.R1 .or. ni(k).le.R2) CYCLE
         lami = (am_i*cig(2)*oig1*ni(k)/ri(k))**obmi
         re_qi1d(k) = MAX(2.51E-6, MIN(SNGL(0.5D0 * DBLE(3.+mu_i)/lami), 125.E-6))
      enddo
      endif

      if (has_qs) then
      do k = kts, kte
         if (rs(k).le.R1) CYCLE
         tc0 = MIN(-0.1, t1d(k)-273.15)
         smob = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2 = smob
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
     &         + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
     &         + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
     &         + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
     &         + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
     &         + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
     &         + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
     &         + sb(10)*bm_s*bm_s*bm_s
            smo2 = (smob/a_)**(1./b_)
         endif
!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
     &         + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
     &         + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
     &        + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc = a_ * smo2**b_
         re_qs1d(k) = MAX(5.01E-6, MIN(0.5*(smoc/smob), 999.E-6))
      enddo
      endif

      end subroutine calc_effectRad

!+---+-----------------------------------------------------------------+
!..Compute radar reflectivity assuming 10 cm wavelength radar and using
!.. Rayleigh approximation.  Only complication is melted snow/graupel
!.. which we treat as water-coated ice spheres and use Uli Blahak's
!.. library of routines.  The meltwater fraction is simply the amount
!.. of frozen species remaining from what initially existed at the
!.. melting level interface.
!+---+-----------------------------------------------------------------+

      subroutine calc_refl10cm (qv1d, qc1d, qr1d, nr1d, qs1d, qg1d,     &
                          ng1d, qb1d, t1d, p1d, dBZ, kts, kte, ii, jj, ke_diag)
#ifdef WRF_GPU
!$acc routine seq
#endif

      IMPLICIT NONE

!..Sub arguments
      INTEGER, INTENT(IN):: kts, kte, ii, jj, ke_diag
      REAL, DIMENSION(kts:kte), INTENT(IN)::                            &
                qv1d, qc1d, qr1d, nr1d, qs1d, qg1d, ng1d, qb1d, t1d, p1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: dBZ
!     REAL, DIMENSION(kts:kte), INTENT(INOUT):: vt_dBZ

!..Local variables
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: temp, pres, qv, rho, rhof
#else
      REAL, DIMENSION(kts:kte):: temp, pres, qv, rho, rhof
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: rc, rr, nr, rs, rg, ng, rb
#else
      REAL, DIMENSION(kts:kte):: rc, rr, nr, rs, rg, ng, rb
#endif

#ifdef WRF_GPU
      DOUBLE PRECISION, DIMENSION(1:KTGPU):: ilamr, ilamg, N0_r, N0_g
#else
      DOUBLE PRECISION, DIMENSION(kts:kte):: ilamr, ilamg, N0_r, N0_g
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: mvd_r
#else
      REAL, DIMENSION(kts:kte):: mvd_r
#endif
#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: smob, smo2, smoc, smoz
#else
      REAL, DIMENSION(kts:kte):: smob, smo2, smoc, smoz
#endif
      REAL:: oM3, M0, Mrat, slam1, slam2, xDs
      REAL:: ils1, ils2, t1_vts, t2_vts, t3_vts, t4_vts
      REAL:: vtr_dbz_wt, vts_dbz_wt, vtg_dbz_wt

#ifdef WRF_GPU
      REAL, DIMENSION(1:KTGPU):: ze_rain, ze_snow, ze_graupel
#else
      REAL, DIMENSION(kts:kte):: ze_rain, ze_snow, ze_graupel
#endif
#ifdef WRF_GPU
      INTEGER, DIMENSION(1:KTGPU):: idx_bg
#else
      INTEGER, DIMENSION(kts:kte):: idx_bg
#endif

      DOUBLE PRECISION:: N0_exp, N0_min, lam_exp, lamr, lamg
      REAL:: a_, b_, loga_, tc0
      DOUBLE PRECISION:: fmelt_s, fmelt_g

      INTEGER:: i, k, k_0, kbot, n, ktop
      LOGICAL:: melti
#ifdef WRF_GPU
      LOGICAL, DIMENSION(1:KTGPU):: L_qr, L_qs, L_qg
#else
      LOGICAL, DIMENSION(kts:kte):: L_qr, L_qs, L_qg
#endif

      DOUBLE PRECISION:: cback, x, eta, f_d
      REAL:: xslw1, ygra1, zans1
      INTEGER :: k_0loop

!+---+

      do k = kts, kte
         dBZ(k) = -35.0
      enddo

!+---+-----------------------------------------------------------------+
!..Put column of data into local arrays.
!+---+-----------------------------------------------------------------+

      do k = kts, kte
         temp(k) = t1d(k)
         qv(k) = MAX(1.E-10, qv1d(k))
         pres(k) = p1d(k)
         rho(k) = 0.622*pres(k)/(R*temp(k)*(qv(k)+0.622))
         rhof(k) = SQRT(RHO_NOT/rho(k))
         rc(k) = MAX(R1, qc1d(k)*rho(k))
         if (qr1d(k) .gt. R1) then
            rr(k) = qr1d(k)*rho(k)
            nr(k) = MAX(R2, nr1d(k)*rho(k))
            lamr = (am_r*crg(3)*org2*nr(k)/rr(k))**obmr
            ilamr(k) = 1./lamr
            N0_r(k) = nr(k)*org2*lamr**cre(2)
            mvd_r(k) = (3.0 + mu_r + 0.672) * ilamr(k)
            L_qr(k) = .true.
         else
            rr(k) = R1
            nr(k) = R1
            mvd_r(k) = 50.E-6
            L_qr(k) = .false.
         endif
         if (qs1d(k) .gt. R2) then
            rs(k) = qs1d(k)*rho(k)
            L_qs(k) = .true.
         else
            rs(k) = R1
            L_qs(k) = .false.
         endif
         if (qg1d(k) .gt. R2) then
            rg(k) = qg1d(k)*rho(k)
            ng(k) = MAX(R2, ng1d(k)*rho(k))
            rb(k) = MAX(qg1d(k)/rho_g(NRHG), qb1d(k))
            rb(k) = MIN(qg1d(k)/rho_g(1), rb(k))
            idx_bg(k) = MAX(1,MIN(NINT(qg1d(k)/rb(k) *0.01)+1,NRHG))
            if (.not. is_hail_aware) idx_bg(k) = idx_bg1
            L_qg(k) = .true.
         else
            rg(k) = R1
            ng(k) = R2
            idx_bg(k) = idx_bg1
            L_qg(k) = .false.
         endif
      enddo

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope, and useful moments for snow.
!+---+-----------------------------------------------------------------+
      do k = kts, kte
         smo2(k) = 0.
         smob(k) = 0.
         smoc(k) = 0.
         smoz(k) = 0.
      enddo
      if ( ( ke_diag > kts .and. ANY(L_qs(kts:kte)) ) .or.  &
            (ke_diag == kts .and. L_qs(kts) .eqv. .true. ) ) then
      do k = kts, ke_diag ! kte
         if (.not. L_qs(k)) CYCLE
         tc0 = MIN(-0.1, temp(k)-273.15)
         smob(k) = rs(k)*oams

!..All other moments based on reference, 2nd moment.  If bm_s.ne.2,
!.. then we must compute actual 2nd moment and use as reference.
         if (bm_s.gt.(2.0-1.e-3) .and. bm_s.lt.(2.0+1.e-3)) then
            smo2(k) = smob(k)
         else
            loga_ = sa(1) + sa(2)*tc0 + sa(3)*bm_s &
     &         + sa(4)*tc0*bm_s + sa(5)*tc0*tc0 &
     &         + sa(6)*bm_s*bm_s + sa(7)*tc0*tc0*bm_s &
     &         + sa(8)*tc0*bm_s*bm_s + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*bm_s*bm_s*bm_s
            a_ = 10.0**loga_
            b_ = sb(1) + sb(2)*tc0 + sb(3)*bm_s &
     &         + sb(4)*tc0*bm_s + sb(5)*tc0*tc0 &
     &         + sb(6)*bm_s*bm_s + sb(7)*tc0*tc0*bm_s &
     &         + sb(8)*tc0*bm_s*bm_s + sb(9)*tc0*tc0*tc0 &
     &         + sb(10)*bm_s*bm_s*bm_s
            smo2(k) = (smob(k)/a_)**(1./b_)
         endif

!..Calculate bm_s+1 (th) moment.  Useful for diameter calcs.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(1) &
     &         + sa(4)*tc0*cse(1) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(1)*cse(1) + sa(7)*tc0*tc0*cse(1) &
     &         + sa(8)*tc0*cse(1)*cse(1) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(1)*cse(1)*cse(1)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(1) + sb(4)*tc0*cse(1) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(1)*cse(1) &
     &        + sb(7)*tc0*tc0*cse(1) + sb(8)*tc0*cse(1)*cse(1) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(1)*cse(1)*cse(1)
         smoc(k) = a_ * smo2(k)**b_

!..Calculate bm_s*2 (th) moment.  Useful for reflectivity.
         loga_ = sa(1) + sa(2)*tc0 + sa(3)*cse(3) &
     &         + sa(4)*tc0*cse(3) + sa(5)*tc0*tc0 &
     &         + sa(6)*cse(3)*cse(3) + sa(7)*tc0*tc0*cse(3) &
     &         + sa(8)*tc0*cse(3)*cse(3) + sa(9)*tc0*tc0*tc0 &
     &         + sa(10)*cse(3)*cse(3)*cse(3)
         a_ = 10.0**loga_
         b_ = sb(1)+ sb(2)*tc0 + sb(3)*cse(3) + sb(4)*tc0*cse(3) &
     &        + sb(5)*tc0*tc0 + sb(6)*cse(3)*cse(3) &
     &        + sb(7)*tc0*tc0*cse(3) + sb(8)*tc0*cse(3)*cse(3) &
     &        + sb(9)*tc0*tc0*tc0 + sb(10)*cse(3)*cse(3)*cse(3)
         smoz(k) = a_ * smo2(k)**b_
      enddo
      endif

!+---+-----------------------------------------------------------------+
!..Calculate y-intercept, slope values for graupel.
!+---+-----------------------------------------------------------------+

      if (ANY(L_qg(kts:kte))) then
      do k = kte, kts, -1
         lamg = (am_g(idx_bg(k))*cgg(3,1)*ogg2*ng(k)/rg(k))**obmg
         ilamg(k) = 1./lamg
         N0_g(k) = ng(k)*ogg2*lamg**cge(2,1)
      enddo
      else
         ilamg(:) = 0.
         N0_g(:) = 0.
      endif

!+---+-----------------------------------------------------------------+
!..Locate K-level of start of melting (k_0 is level above).
!+---+-----------------------------------------------------------------+
      melti = .false.
      k_0 = kts
      do k = kte-1, kts, -1
         if ( (temp(k).gt.273.15) .and. L_qr(k)                         &
     &                            .and. (L_qs(k+1).or.L_qg(k+1)) ) then
            k_0 = MAX(k+1, k_0)
            melti=.true.
            goto 195
         endif
      enddo
 195  continue

! Set loop limit for wet ice according to whether the full 3D field is needed or just k=1
      k_0loop = Min(k_0, ke_diag+1)

!+---+-----------------------------------------------------------------+
!..Do not do the so-called bright band if using the variable density
!.. graupel-hail category since the density increases during melting and
!.. will account for bright band behavior explicitly.
!+---+-----------------------------------------------------------------+
!     if (is_hail_aware) melti = .false.

!+---+-----------------------------------------------------------------+
!..Assume Rayleigh approximation at 10 cm wavelength. Rain (all temps)
!.. and non-water-coated snow and graupel when below freezing are
!.. simple. Integrations of m(D)*m(D)*N(D)*dD.
!+---+-----------------------------------------------------------------+

      do k = kts, ke_diag ! kte
         ze_rain(k) = 1.e-22
         ze_snow(k) = 1.e-22
         ze_graupel(k) = 1.e-22
         if (L_qr(k)) ze_rain(k) = N0_r(k)*crg(4)*ilamr(k)**cre(4)
         if (L_qs(k)) ze_snow(k) = (0.176/0.93) * (6.0/PI)*(6.0/PI)     &
     &                           * (am_s/900.0)*(am_s/900.0)*smoz(k)
         if (L_qg(k)) ze_graupel(k) = (0.176/0.93) * (6.0/PI)*(6.0/PI)  &
     &               * (am_g(idx_bg(k))/900.0)*(am_g(idx_bg(k))/900.0)  &
     &               * N0_g(k)*cgg(4,1)*ilamg(k)**cge(4,1)
      enddo

!+---+-----------------------------------------------------------------+
!..Special case of melting ice (snow/graupel) particles.  Assume the
!.. ice is surrounded by the liquid water.  Fraction of meltwater is
!.. extremely simple based on amount found above the melting level.
!.. Uses code from Uli Blahak (rayleigh_soak_wetgraupel and supporting
!.. routines).
!+---+-----------------------------------------------------------------+

      if (.not. iiwarm .and. melti .and. k_0.ge.2) then
       do k = k_0loop-1, kts, -1

!..Reflectivity contributed by melting snow
          if (L_qs(k) .and. L_qs(k_0) ) then
           fmelt_s = MAX(0.05d0, MIN(1.0d0-rs(k)/rs(k_0), 0.99d0))
           eta = 0.d0
           oM3 = 1./smoc(k)
           M0 = (smob(k)*oM3)
           Mrat = smob(k)*M0*M0*M0
           slam1 = M0 * Lam0
           slam2 = M0 * Lam1
           do n = 1, nrbins
              x = am_s * xxDs(n)**bm_s
#ifdef WRF_GPU
              call rayleigh_soak_wetgraupel_g (x, DBLE(ocms), DBLE(obms), &
     &              fmelt_s, melt_outside_s, m_w_0, m_i_0, lamda_radar, &
     &              CBACK, rcode_s)
#else
              call rayleigh_soak_wetgraupel (x, DBLE(ocms), DBLE(obms), &
     &              fmelt_s, melt_outside_s, m_w_0, m_i_0, lamda_radar, &
     &              CBACK, mixingrulestring_s, matrixstring_s,          &
     &              inclusionstring_s, hoststring_s,                    &
     &              hostmatrixstring_s, hostinclusionstring_s)
#endif
              f_d = Mrat*(Kap0*DEXP(-slam1*xxDs(n))                     &
     &              + Kap1*(M0*xxDs(n))**mu_s * DEXP(-slam2*xxDs(n)))
              eta = eta + f_d * CBACK * simpson(n) * xdts(n)
           enddo
           ze_snow(k) = SNGL(lamda4 / (pi5 * K_w) * eta)
          endif

!..Reflectivity contributed by melting graupel

!         if (L_qg(k) .and. L_qg(k_0) ) then
!          fmelt_g = MAX(0.05d0, MIN(1.0d0-rg(k)/rg(k_0), 0.99d0))
!          eta = 0.d0
!          lamg = 1./ilamg(k)
!          do n = 1, nrbins
!             x = am_g(idx_bg(k)) * xxDg(n)**bm_g
!             call rayleigh_soak_wetgraupel (x, DBLE(ocmg(idx_bg(k))), DBLE(obmg), &
!    &              fmelt_g, melt_outside_g, m_w_0, m_i_0, lamda_radar, &
!    &              CBACK, mixingrulestring_g, matrixstring_g,          &
!    &              inclusionstring_g, hoststring_g,                    &
!    &              hostmatrixstring_g, hostinclusionstring_g)
!             f_d = N0_g(k)*xxDg(n)**mu_g * DEXP(-lamg*xxDg(n))
!             eta = eta + f_d * CBACK * simpson(n) * xdtg(n)
!          enddo
!          ze_graupel(k) = SNGL(lamda4 / (pi5 * K_w) * eta)
!         endif

       enddo
      endif

      do k = ke_diag, kts, -1
         dBZ(k) = 10.*log10((ze_rain(k)+ze_snow(k)+ze_graupel(k))*1.d18)
      enddo


!..Reflectivity-weighted terminal velocity (snow, rain, graupel, mix).
!     do k = kte, kts, -1
!        vt_dBZ(k) = 1.E-3
!        if (rs(k).gt.R2) then
!         Mrat = smob(k) / smoc(k)
!         ils1 = 1./(Mrat*Lam0 + fv_s)
!         ils2 = 1./(Mrat*Lam1 + fv_s)
!         t1_vts = Kap0*csg(5)*ils1**cse(5)
!         t2_vts = Kap1*Mrat**mu_s*csg(11)*ils2**cse(11)
!         ils1 = 1./(Mrat*Lam0)
!         ils2 = 1./(Mrat*Lam1)
!         t3_vts = Kap0*csg(6)*ils1**cse(6)
!         t4_vts = Kap1*Mrat**mu_s*csg(12)*ils2**cse(12)
!         vts_dbz_wt = rhof(k)*av_s * (t1_vts+t2_vts)/(t3_vts+t4_vts)
!         if (temp(k).ge.273.15 .and. temp(k).lt.275.15) then
!            vts_dbz_wt = vts_dbz_wt*1.5
!         elseif (temp(k).ge.275.15) then
!            vts_dbz_wt = vts_dbz_wt*2.0
!         endif
!        else
!         vts_dbz_wt = 1.E-3
!        endif

!        if (rr(k).gt.R1) then
!         lamr = 1./ilamr(k)
!         vtr_dbz_wt = rhof(k)*av_r*crg(13)*(lamr+fv_r)**(-cre(13))      &
!    &               / (crg(4)*lamr**(-cre(4)))
!        else
!         vtr_dbz_wt = 1.E-3
!        endif

!        if (rg(k).gt.R2) then
!         lamg = 1./ilamg(k)
!         vtg_dbz_wt = rhof(k)*av_g(idx_bg(k))*cgg(5,idx_bg(k))*lamg**(-cge(5,idx_bg(k)))               &
!    &               / (cgg(4,1)*lamg**(-cge(4,1)))
!        else
!         vtg_dbz_wt = 1.E-3
!        endif

!        vt_dBZ(k) = (vts_dbz_wt*ze_snow(k) + vtr_dbz_wt*ze_rain(k)      &
!    &                + vtg_dbz_wt*ze_graupel(k))                        &
!    &                / (ze_rain(k)+ze_snow(k)+ze_graupel(k))
!     enddo

      end subroutine calc_refl10cm
!
!+---+-----------------------------------------------------------------+
!
      real function theta_e(pres_Pa,temp_K,w_non,tlcl_K)
!..
!..         The following code was based on Bolton (1980) eqn #43
!..         and claims to have 0.3 K maximum error within -35 < T < 35 C
!..            pres_Pa = Pressure in Pascals
!..            temp_K  = Temperature in Kelvin
!..            w_non   = mixing ratio (non-dimensional = kg/kg)
!..            tlcl_K  = Temperature at Lifting Condensation Level (K)
!..
      IMPLICIT NONE

      real:: pres_Pa, temp_K, w_non, tlcl_K
      real:: pp, tt, rr, tlc, power, xx, p1, p2

!+---+

      pp = pres_Pa
      tt = temp_K
      rr = w_non + 1.e-8
      tlc = tlcl_K

      power=(0.2854*(1.0 - (0.28*rr) ))
      xx = tt * (100000.0/pp)**power

      p1 = (3.376/tlc) - 0.00254
      p2 = (rr*1000.0) * (1.0 + 0.81*rr)
      
      theta_e = xx * exp(p1*p2)

      return
      end
!
!+---+-----------------------------------------------------------------+
!
      real function t_lcl(temp_K,tdew_K)
!..
!..         The following code was based on Bolton (1980) eqn #15
!..         and claims to have 0.1 K maximum error within -35 < T < 35 C
!..            temp_K  = Temperature in Kelvin
!..            tdew_K  = Dewpoint T at Lifting Condensation Level (K)
!..
      IMPLICIT NONE

      real:: temp_K, tdew_K
      real:: tt, tttd, denom

!+---+

      tt = temp_K
      tttd= tdew_K
      denom= ( 1.0/(tttd-56.0) ) + (log(tt/tttd)/800.)
      t_lcl = ( 1.0 / denom ) + 56.0
      return
      end
!
!+---+-----------------------------------------------------------------+
!
      real function t_dew(pres_Pa,w_non)
!..
!..            pres_Pa = Pressure in Pascals
!..            w_non   = mixing ratio (non-dimensional = kg/kg)
!..
      IMPLICIT NONE

      real:: pres_Pa, w_non
      real:: p, RR, ES, ESLN

!+---+

      p = pres_Pa
      RR=w_non+1e-8
      ES=P*RR/(.622+RR)
      ESLN=LOG(ES)
      T_Dew=(35.86*ESLN-4947.2325)/(ESLN-23.6837)
      return
      end
!
!+---+-----------------------------------------------------------------+
!
      real function theta_wetb(thetae_K)
!..
!..              Eqn below was gotten from polynomial fit to data in
!..              Smithsonian Meteorological Tables showing Theta-e
!..              and Theta-w
!..
      IMPLICIT NONE

      real:: thetae_K
      real:: x, answer

!+---+

      real*8 c(0:6), d(0:6)
      data c/-1.00922292e-10, -1.47945344e-8, -1.7303757e-6             &
     &      ,-0.00012709,      1.15849867e-6, -3.518296861e-9           &
     &      ,3.5741522e-12/
      data d/0.00000000,   -3.5223513e-10, -5.7250807e-8                &
     &     ,-5.83975422e-6, 4.72445163e-8, -1.13402845e-10              &
     &     ,8.729580402e-14/

      x=min(475.0,thetae_K)
           
      if( x .le. 335.5 ) then
         answer = c(0)+x*(c(1)+x*(c(2)+x*(c(3)+x*(c(4)+x*(c(5)+         &
     &            x*c(6) )))))
      else
         answer = d(0)+x*(d(1)+x*(d(2)+x*(d(3)+x*(d(4)+x*(d(5)+         &
     &            x*d(6) )))))
      endif

      theta_wetb = answer + 273.15

      return
      end
!
!+---+-----------------------------------------------------------------+
!
      real function compT_fr_The(thelcl_K,pres_Pa)
!..
!..            pres_Pa = Pressure in Pascals
!..            thelcl  = Theta-e at LCL (units in Kelvin)
!..
!..            Temperature (K) is returned given Theta-e at LCL
!..            and a pressure.  This describes a moist-adiabat.
!..            This temperature is the parcel temp at level Pres
!..            along moist adiabat described by theta-e.
!..
      IMPLICIT NONE

      real:: thelcl_K, pres_Pa
      real:: guess, epsilon, w1, w2, tenu, tenup, cor, thwlcl_K
      integer:: iter

!+---+

      guess= (thelcl_K - 0.5 * ( max(thelcl_K-270., 0.))**1.05)         &
     &     * (pres_Pa/100000.0)**.2
      epsilon=0.01
      do iter=1,100
         w1 = rslf(pres_Pa,guess)
         w2 = rslf(pres_Pa,guess+1.)
         tenu = theta_e(pres_Pa,guess,w1,guess)
         tenup = theta_e(pres_Pa,guess+1,w2,guess+1.)
         cor = (thelcl_K - tenu) / (tenup - tenu)
         guess = guess + cor
         if( (cor.lt.epsilon) .and. (-cor.lt.epsilon) ) then
            compT_fr_The=guess
            return
         endif
      enddo
!     print*, '  convergence not reached '
      thwlcl_K=theta_wetb(thelcl_K)
      compT_fr_The = thwlcl_K*((pres_Pa/100000.0)**0.286)

      return
      end

!+---+-----------------------------------------------------------------+
!+---+-----------------------------------------------------------------+
END MODULE module_mp_thompson
!+---+-----------------------------------------------------------------+
