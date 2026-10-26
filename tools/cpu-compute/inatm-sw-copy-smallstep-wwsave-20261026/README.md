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

These timings use three distinct retained original invocations selected before the candidate timing. This is an unpaired historical comparison; unresolved operational-epoch differences prevent a fresh matched or isolated-gain claim. Integration elapsed includes communication and backpressure. This child now has its own unprofiled nine-hour qualification, documented below; noon, profile, restart and alternate-layout qualification remain absent.

SmallStep keeps the required copies but shares their traversal with the existing W/PH work. Its complete caller, including identical restores, took 3.82% and 7.66% less wall time on hpc01/hpc02. SW moves the invariant snow decision outside the inner copy loop; actual GNU code uses scalar unrolling, not packed SIMD in that loop. Its complete caller took 13.97% and 13.36% less time on hpc03/hpc04. All caller raw outputs and five-state checks were exact. These caller gains are separate from forecast gains and are never added together.

Qualified delivery uses the retained preprocessed sources and tested O2 objects. Commit 214e7cf3 is the post-test canonical target/guard correspondence, not a fresh whole-source build producer. O2 non-target differences, typed module-reference identities, O0 target-only limits and the original failed preparation records remain documented in the evidence references.

To opt out, set WRF_SW_INATM_COPY_UNSWITCH=0 and/or WRF_SMALL_STEP_WWSAVE_TRAVERSAL_FUSION=0, regenerate the affected preprocessed source, rebuild the corresponding object, rearchive and relink. The retained c51b executable with archive 5575 is the tested image rollback. Restore source and coupled selection metadata from commit 91470089 to return the working fork to that parent. Production and master are untouched.


Own nine-hour update

Selected4974: own unprofiled SAME512 nine-hour1625/tenFULL plus retained three-hour545/fourFULL. All four models and original reader closed normally; reader GC exit_code null is preserved with invocation-bound manager success and empty/absent cgroup.

| Metric | Original median3 (range) | Selected4974 | Descriptive reduction |
|---|---:|---:|---:|
| Wall seconds | 2375.176475 (2306.344228–2434.052311) | 1786.827180 | 24.770761% |
| Main-step seconds | 2157.669640 (2092.728550–2217.654070) | 1686.369150 | 21.843033% |
| Aggregate CPU seconds | 1166063.791005 (1132283.412013–1196242.042695) | 897799.454589 | 23.005974% |

Own unprofiled selected4974 SAME512 nine-hour1625/tenFULL strict science PASS against retained corrected original546b. UNPAIRED descriptive comparison with median latest3 eligible DISTINCT original nine-hour invocations; hardware/cache epoch comparability unresolved, no matched/causal/component-additive or repeatability claim. Own three-hour545/fourFULL Q a208 retained separately. Own noon/profile/restart/384/256/full144 remainFALSE. QualifiedPP/cached-object replay + post-test canonical target correspondence only; rawproducerNULL/no clean whole-source CPP/rebuild certificate. Original native raw/scoped structural limitations retained.

Actual map follows granted FABA lease rows; copied e003 staged file is unused legacy. Raw SCI inherited Current0b40 label is retained, actual4974 proven by runtime/grant. Source214e/image4974/archive02848/NG9371 and all build defaults/components are unchanged. No new deployment/source/build. Rollback is metadata preimages only; existing source opt-outs/retained c51b image remain as documented.
