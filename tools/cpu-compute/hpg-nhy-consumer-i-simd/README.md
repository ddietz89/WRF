# NH-Y pressure-gradient consumer SIMD

The qualified GNU 13.3 EPYC configuration selects executable `bc543d56`, archive `9a909457`, and post-test source commit `9e259378`. It retains the isolated NH-X helper and all previous improvements. One `SIMD PRIVATE(dpy)` directive vectorizes the independent inner-I NH-Y consumer; one blank line is removed to preserve unrelated source-line constants. Expressions, true divisions, flags and the existing C helper are unchanged.

The genuine current-module native gate passed 100 cases at bounds-checked O0 and strict O2, including the original 72-case prefix, raw output, readonly inputs and five state fields. The current `99bf` module interface is byte-exact. Generated code contains a four-lane body, cleanup/tails, and explicit empty-range guards. Its frame grows from 824 to 1176 bytes and has floating-point spills; these costs are included in the caller measurement.

Opposite-order pairs on hpc01 and hpc02 measured **36.85% and 35.72% less wall time** for 500 complete synthetic HPG calls. Every arm had a checked cache clear and exact raw/state output. Process CPU was unavailable. This is a complete-caller result, not an isolated Y-loop or forecast gain.

The unchanged original full-grid checker passed **two products and all 35 ordered steps** with 512 ranks and two tiles. All four model scopes and the independent reader closed normally. Active writers 487/495, inactive writers 503/511, all 32 quilt FIELDVIEW environments and the expected 16 short-run markers passed. The one-member link changes only archive slot 559; the other 583 members retain their order and bytes. There were no production source compiles and one ordinary link; the guarded source was checked separately with exact canonical CPP projections.

This image owns **short scientific qualification only**. Parent a61a's three-hour and 1749's nine-hour results are historical and do not qualify this child. Short observations were 140.797629 seconds whole MPI wall, 39.903320 seconds main-step elapsed, and 54631.865472 aggregate CPU-seconds. The original reference was retained from a different epoch: these are unpaired descriptive observations, with no forecast-speedup or repeatability claim. Main-step elapsed includes communication/backpressure; aggregate CPU includes MPI spin.

## Evidence and support

- `APPLICATION_QUALIFICATION.json` binds 95 actual references; `RESULT.json`, `science-receipt.json`, and `reader-closure.json` retain raw acceptance. The raw result's inherited 1749/X wording is preserved; actual lease, build and scientific proof bind bc54/NH-Y.
- `NATIVE_QUALIFICATION.json`, `CALLER_QUALIFICATION.json`, `BUILD_QUALIFICATION.json` and the canonical CPP/build receipt retain separate scopes. Frozen producer commits remain null; `POST_TEST_SOURCE_IDENTITY.json` records the later source commit.
- `REBUILD_RECIPE.json` enables the existing experimental HPG macro in the qualified recipe. Generic source keeps its portable macro-off path. The existing C977 helper and its explicit archive-link position remain unchanged. AOCC/Intel are experimental and gain no new qualification here.

## Rollback

Restore `dyn_em/module_big_step_utilities_em.F` and all three `tools/cpu-working/` selection records together from `83ee0e60a7bbc35918e372a974f4729803997356`; remove only this new component's evidence/recipe pointers. Retain the existing NH-X C helper. This restores a61a/9dc6/source5f18 with its own short and three-hour qualification. See `ROLLBACK.json` and `SOURCE_ONLY.diff`. Production and master are unchanged; AWS remains suspended.
