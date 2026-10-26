SW cloud-copy branch unswitch and SmallStep saved-w traversal

Both changes are defaults in the qualified GNU 13.3 working configuration. The combined build includes all previously selected improvements and passed the original checker for all four complete products and all 545 ordered timesteps in its own unprofiled, four-node, 512-rank three-hour forecast. All model jobs and the reader closed normally.

| Run | Wall seconds | Integration seconds | CPU-hours |
|---|---:|---:|---:|
| production512-current0b40-fourhost-threehour-pair2-r1-control | 800.215 | 596.450 | 99.866 |
| production512-current0b40-fourhost-threehour-pair1-r1-control | 798.620 | 595.327 | 99.624 |
| production512-current5c75-fourhost-threehour-pair1-r1-control | 800.024 | 596.594 | 99.813 |
| Control median (n=3) | 800.024 | 596.450 | 99.813 |
| Combined 4974f103 (n=1) | 625.747 | 541.109 | 84.376 |

Descriptive reductions against the retained control median: **21.78% wall, 9.28% integration elapsed, 15.47% aggregate CPU**. Control ranges: wall 798.620–800.215 s; integration 595.327–596.594 s; CPU 99.624–99.866 CPU-hours.

These timings use three distinct retained original invocations selected before the candidate timing. This is an unpaired historical comparison; unresolved operational-epoch differences prevent a fresh matched or isolated-gain claim. Integration elapsed includes communication and backpressure. This child has no independent nine-hour, noon, profile, restart or alternate-layout qualification.

SmallStep keeps the required copies but shares their traversal with the existing W/PH work. Its complete caller, including identical restores, took 3.82% and 7.66% less wall time on hpc01/hpc02. SW moves the invariant snow decision outside the inner copy loop; actual GNU code uses scalar unrolling, not packed SIMD in that loop. Its complete caller took 13.97% and 13.36% less time on hpc03/hpc04. All caller raw outputs and five-state checks were exact. These caller gains are separate from forecast gains and are never added together.

Qualified delivery uses the retained preprocessed sources and tested O2 objects. Commit 214e7cf3 is the post-test canonical target/guard correspondence, not a fresh whole-source build producer. O2 non-target differences, typed module-reference identities, O0 target-only limits and the original failed preparation records remain documented in the evidence references.

To opt out, set WRF_SW_INATM_COPY_UNSWITCH=0 and/or WRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION=0, regenerate the affected preprocessed source, rebuild the corresponding object, rearchive and relink. The retained c51b executable with archive 5575 is the tested image rollback. Restore source and coupled selection metadata from commit 91470089 to return the working fork to that parent. Production and master are untouched.
