SPC scratch-column reuse: own three-hour and daylight science

| Metric | Original median (n=3) | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.33374 | 10.46069 | 21.5472% |
| Main-step minutes | 9.94084 | 9.04669 | 8.9947% |
| Aggregate core-hours | 99.81315 | 84.58097 | 15.2607% |

Controls:

- production512-current0b40-fourhost-threehour-pair2-r1-control, INV2eeee20b4cf0457cb582710bce30dc0b: wall 800.214591s, main 596.450450s, CPU 359516.463363s
- production512-current0b40-fourhost-threehour-pair1-r1-control, INV81febf86a6734f4fa77d57fd1b467c30: wall 798.619809s, main 595.327090s, CPU 358644.885565s
- production512-current5c75-fourhost-threehour-pair1-r1-control, INVc9768c1474f648329ff3e41b664aac99: wall 800.024121s, main 596.593540s, CPU 359327.346984s

Ranges (seconds): {"wall_seconds": [798.6198086068034, 800.2145909662358], "main_step_sum_seconds": [595.32709, 596.59354], "cpu_seconds": [358644.885565, 359516.46336299996]}

Own unprofiled SAME512 threehour545/fourFULL AND daylight12-13onehour185/twoFULL. Exact science versus retained original546bA2; timing descriptive/unpaired versus median3 distinct original controls, unresolved hardware epoch. No freshmatched/isolated/additive/statistical/globalheadroom claim. Own daylight SCI required before SW default promotion. Child9h/profile/restart FALSE. Noon retainedoriginal75m is scienceprefix only, no75m-to1h timingcomparison. Only actual listed cached members changed over selected56d2; RSL/18deps/othermembers exact. Qualified testedPP/cachedOO delivery plus posttest target source projection, raw producer NULL; no cleanF-only build or wholeTU certificate. SPC firstcallerwave mixed (01wall+2.7124%,CPU+2.7503%;02wall-0.2682%,CPU-0.1878%); sole reversed-startrepeat01wall+0.58996%,CPU+0.04430%,02wall+0.69275%,CPU+0.08998%. Bothwavesretained; smallwall/neutralCPU, no established significantCPU/kernel gain. Four allocations remainfour; requestedcapacity60928to544bytes at33levels only, notRSS or forecastgain.

WRF_SW_SPC_SINGLE_COLUMN defaults to1 only within the qualified GNU13.3 strictO2/type4/pureMPI guard and enabled VRTQDR stack path. It reuses one private scratch column; the spectral traversal and arithmetic stay unchanged. Set WRF_SW_SPC_SINGLE_COLUMN=0, or define its DISABLE macro, to restore the original spectral scratch columns while retaining the independently guarded stack path. An optout changes source selection and requires regenerating/recompiling the SW module, rearchiving and relinking; it does not switch an existing executable. No new compiler/ISA/FP flags are added. The retained parent defaults WRF_CALC_ALT_SIMD=1 and WRF_SW_VRTQDR_PAIR_FIXED_STACK=1 remain within their own qualified guards. Set WRF_CALC_ALT_SIMD=0 to restore the original scalar calc_alt addition loop after rebuilding BigStep/archive/image. Set WRF_SW_VRTQDR_PAIR_FIXED_STACK=0 to restore the original paired scratch allocation path after rebuilding SW/archive/image; this also makes the dependent SPC current-column path fall back to its original spectral columns. Their public parent component README/source inventory remains the evidence; no standalone calc_alt source-rebuild recipe or new clean-build certificate is invented.
