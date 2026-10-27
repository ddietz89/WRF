## PWAT ordered-column4: three-hour qualification

Promoted an ordered four-column PWAT sum. Adjacent columns share vector operations while each column retains its original ascending-level arithmetic. Scalar fallback covers unsupported layouts and unmasked floating-point exceptions; `WRF_AFWA_PWAT_ORDERED_COLUMN4=0` disables the change.

The combined configuration passed the unchanged checker for four full-grid products and all 545 ordered steps in an unprofiled three-hour forecast on four nodes (512 ranks). All prior improvements remain included.

| Metric | Median of three original controls | Latest combined build | Reduction |
|---|---:|---:|---:|
| Model/MPI elapsed (minutes) | 13.33374 | 10.71412 | 19.6465% |
| Main-step elapsed (minutes) | 9.94084 | 9.04825 | 8.9790% |
| Aggregate CPU (core-hours) | 99.81315 | 86.86833 | 12.9691% |

These are descriptive comparisons with the preselected retained control median, not a fresh matched comparison or an isolated PWAT speedup. Main-step elapsed includes communication and waiting. The complete standalone PWAT pass was 84.46–84.82% shorter in two opposite-order pairs; that percentage describes the kernel test only. This new image has its own three-hour qualification; earlier noon profiles and nine-hour results belong to earlier images.

Evidence and rollback: `tools/cpu-compute/afwa-pwat-ordered-column4-20261027/`. Source commit `0de65b499c50e547a392a41fb268daf3ffd847d6`; executable `b92fce9c`; archive `b0e73d34`. The cached build replaced one AFWA member and appended one helper, preserving the other 587 archive members. The canonical three source files match the tested target and helper; a clean full-source rebuild is not certified by this cached build. See `THREE_HOUR_APPLICATION_QUALIFICATION.json` and `SOURCE_REBUILD_RECIPE.json` for exact scope and artifact identities.

