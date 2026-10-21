# NH-X pressure-gradient consumer SIMD

Selected **1749f701 / archivef18c135a / post-test sourcea531104f** retains all f703 improvements and adds one `!$OMP SIMD PRIVATE(dpx)` before the final independent NH-X inner-I loop. Expressions, quotient row cache, Y/hydro branches, API and allocations are unchanged. [Source diff](SOURCE_ONLY.diff).

Two opposite-order complete synthetic HPG caller pairs,500 calls per arm, fell **20.94%** on hpc01 (0.683916601→0.540720948s) and **20.87%** on hpc02 (0.689623751→0.545727149s). Every timing arm had checked cache clearing, exact full raw/five-state output and positive normal closure. Only integer CLOCK_MONOTONIC_RAW complete-invoke wall time was available; process CPU was not measured. These are finite complete-caller gains, not an isolated X-loop or forecast claim. [Caller proof](CALLER_QUALIFICATION.json).

The actual native100-case genuine/O0-bounds/O2 parent/candidate test passed full raw output, five return-state fields, physical/readonly guards, tails/empty extents and legal readonly aliases, with fresh72-case prefix. Rounding coverage is **nearest/downward**, with finite seeded/unseeded DIVBYZERO cases; no universal IEEE/trap claim. [Native proof](NATIVE_QUALIFICATION.json).

Packed code adds112 bytes of stack frame and five packed temporary spills/reloads. This is explicitly retained as `no_unexpected_spills=false`: [code review](GENERATED_CODE_REVIEW.json), [bounded measurement decision](ROOT_SPILL_SCREEN_DECISION.json). The actual net complete-caller gains justify inclusion after exact science; spill counts alone were not treated as a measured slowdown.

The unchanged original full-grid checker passed **two products and35ordered steps,512ranks,480compute,two tiles,16active markers,all32quilt FIELDVIEW1,positive roots487/495 and inactive503/511**. All model/reader jobs closed normally. [Application proof](APPLICATION_QUALIFICATION.json) binds166 actual references. The short candidate measured138.768879s wholewall,38.453670s main-step elapsed and53717.228135 aggregateCPU-s. Comparison with retained original is **unpaired descriptive context**, not a new matched forecast timing result. Main-step elapsed includes communication/backpressure and is not integration CPU.

Only BigStep archive occurrence559 changed;583 others, link inputs, main/helpers and publicMOD0170 were preserved in one ordinary link without source compilation. Fresh canonical8aba reproduces438d exactly. [Build proof](BUILD_QUALIFICATION.json), [recipe](REBUILD_RECIPE.json). GNU13.3strict qualification only; AOCC/Intel remain eligible experimental stacks.

**The selected build has passed its own short and three-hour scientific checks; its own noon and nine-hour checks remain pending.** f703's last fresh three-hour result and3cdd's nine-hour result remain historical, with no horizon/gain transfer. [Post-test source](POST_TEST_SOURCE_IDENTITY.json) is separate from frozen null producer records. [Rollback](ROLLBACK.json): revert source-onlya531104f and restore all three BEFORE_HPG_NHX_CONSUMER records together. Production/master unchanged; AWS suspended.

## Three-hour qualification

The unchanged original checker passed **four products and 545 ordered timesteps**, with all 512 ranks, two tiles, 32 required field markers, all four positive writer roots and `FIELDVIEW1` on every quilt rank. All model and reader jobs closed normally. [Qualification](THREE_HOUR_APPLICATION_QUALIFICATION.json) binds 173 actual references.

| Metric | Retained original 546b | Selected 1749 | Descriptive reduction |
| --- | ---: | ---: | ---: |
| Whole model/MPI wall, seconds | 914.002706 | 668.899757 | 26.8164% |
| Main-step elapsed sum, seconds | 692.229380 | 564.772720 | 18.4125% |
| Aggregate node CPU-seconds | 416098.178201 | 324253.307580 | 22.0729% |

This is an **unpaired comparison**, not an isolated consumer speedup or repeatability result. The previous f703 fresh pair remains separate. Main-step elapsed time includes communication and output backpressure; it is not integration CPU time. The selected build still lacks its own noon and nine-hour qualification.

[Result](THREE_HOUR_RESULT.json), [reader closure](THREE_HOUR_READER_CLOSURE.json), [full science pointer](THREE_HOUR_SCIENCE_POINTER.json).
