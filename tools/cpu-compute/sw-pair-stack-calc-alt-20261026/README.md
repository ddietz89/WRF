# Qualified paired shortwave scratch and calc_alt SIMD

Cached radiation/physics batch: own three-hour science

| Metric | Original median (n=3) | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.33374 | 10.36987 | 22.2283% |
| Main-step minutes | 9.94084 | 8.97816 | 9.6841% |
| Aggregate core-hours | 99.81315 | 84.00883 | 15.8339% |

Controls:

- production512-current0b40-fourhost-threehour-pair2-r1-control, INV2eeee20b4cf0457cb582710bce30dc0b: wall 800.214591s, main 596.450450s, CPU 359516.463363s
- production512-current0b40-fourhost-threehour-pair1-r1-control, INV81febf86a6734f4fa77d57fd1b467c30: wall 798.619809s, main 595.327090s, CPU 358644.885565s
- production512-current5c75-fourhost-threehour-pair1-r1-control, INVc9768c1474f648329ff3e41b664aac99: wall 800.024121s, main 596.593540s, CPU 359327.346984s

Ranges (seconds): {"wall_seconds": [798.6198086068034, 800.2145909662358], "main_step_sum_seconds": [595.32709, 596.59354], "cpu_seconds": [358644.885565, 359516.46336299996]}

Own unprofiled SAME512 threehour545/fourFULL AND daylight12-13onehour185/twoFULL. Exact science versus retained original546bA2; timing descriptive/unpaired versus median3 distinct original controls, unresolved hardware epoch. No freshmatched/isolated/additive/statistical/globalheadroom claim. Own daylight SCI required before SW default promotion. Child9h/profile/restart FALSE. Noon retainedoriginal75m is scienceprefix only, no75m-to1h timingcomparison. Only actual listed cached members changed over selected3f86; RSL/18deps/othermembers exact. Qualified testedPP/cachedOO delivery plus posttest target source projection, raw producer NULL; no cleanF-only build or wholeTU certificate. SWR2 tiny genuinecaller0.1311/0.2663% shorter only, no significant gain established or standalone/BLOCKgain inheritance.


Both paths default on only for the qualified GNU 13.3, strict O2, REAL4/INTEGER4, pure-MPI configuration. Their original fallbacks remain. To disable them, set `WRF_CALC_ALT_SIMD=0` and/or `WRF_SW_VRTQDR_PAIR_FIXED_STACK=0`, then regenerate, rebuild and relink. The retained parent executable is `3f86bd1c885d5e9f1c20b056a5659f2d51d2cada523afb20aaf6aa6d3bbb861a` with archive `455a2a943140132a4122d9b14374d7a2c5f5341ace04ce70305016d789843a3c`; its runtime/dependency records remain in Git history. Production and master were not changed.

The calc_alt complete-caller screen shortened wall time by 41.9420% and 42.0168%, with matching thread-CPU reductions. SW R2 shortened its genuine complete-caller time by only 0.1311% and 0.2663%; it removes two allocations for 1–33 layers, with no established significant caller or separate forecast gain. The earlier BLOCK variant's isolated gains are not transferred to R2. The new single-column SPC investigation is not included in this executable.

The source commit records post-test correspondence for the tested targets and cached objects; this is not a clean full-source build certificate. Nine-hour and profile qualifications of parent 3f86 remain historical and do not qualify this child. Before/during/after hardware samples exist for the daylight case; the three-hour case has incomplete earlier all-host hardware coverage, recorded as unknown.
