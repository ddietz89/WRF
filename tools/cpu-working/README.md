# Selected working configuration — October 28

The vertical scratch array now reuses a horizontal-flux buffer after its last use. This removes one allocation/free pair and one temporary array while retaining the original arithmetic. The combined build passed the unchanged scientific checker: four FULL products and all 545 ordered steps matched exactly.

| Metric | Original median, 3 runs | Latest combined | Descriptive reduction |
|---|---:|---:|---:|
| Wall time (minutes) | 13.33374 | 10.66057 | 20.0482% |
| Main-step elapsed (minutes) | 9.94084 | 9.00643 | 9.3997% |
| Aggregate CPU (core-hours) | 99.81315 | 86.37483 | 13.4635% |

These candidate-only timings are unpaired comparisons with the retained A2/A1/5c75 control median. Main-step elapsed includes communication and waiting. The complete captured caller was 0.25% and 1.30% shorter on hpc01/02; these small observations are distinct from the combined forecast result and establish no isolated forecast gain.

Native O2/O0 checks passed exact raw-output, read-only, processor-state and public-interface checks. The change removes 24,816 bytes of scratch for an example 188-by-33 tile; this is a static per-call saving, not a measured whole-forecast memory reduction. Earlier package/fixture failures and diagnostic line/unwind differences remain recorded.

The selected executable is `00c6bcb3`, archive `ff31e972`, with post-test source correspondence at `ee073e32`. The cached build replaces one of 591 archive members and retains PD, all previous improvements, RSL `e418b187`, and output provider `64bb4cf2`. This image has its own unprofiled three-hour qualification only. Parent noon/profile/nine-hour results remain historical; no clean full-source rebuild, restart or full 144-hour qualification is claimed.

The change defaults on in the qualified strict GNU 13.3/O2, REAL4/INTEGER4, pure-MPI configuration. Set `WRF_ORDINARY_VFLUX_REUSE=0`, regenerate and rebuild advection, rearchive and relink to opt out. Retained executable `b8e2e921` is the whole-image rollback. [Exact qualification](../cpu-compute/ordinary-vflux-scratch-20261028/THREE_HOUR_APPLICATION_QUALIFICATION.json) and [source/rebuild scope](../cpu-compute/ordinary-vflux-scratch-20261028/SOURCE_REBUILD_RECIPE.json).
