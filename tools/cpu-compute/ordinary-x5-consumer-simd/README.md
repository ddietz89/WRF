# Ordinary advection X5 consumer SIMD

The qualified working recipe adds one `!$omp simd private(mrdx)` directive to the final X-direction fifth-order ordinary-advection tendency update. Arithmetic, loop bounds, compiler flags and public module bytes are unchanged. An adjacent blank line compensates the added source line; canonical preprocessing reproduces the tested candidate exactly.

| Captured whole caller | Parent | Candidate | Wall reduction |
|---|---:|---:|---:|
| hpc01, parent first | 2.870195640 s | 2.379814851 s | 17.0853% |
| hpc03, candidate first | 2.917714533 s | 2.397343977 s | 17.8349% |

Each arm executes 4,096 complete calls with the same tendency restoration inside the clock. Final 404,250-word outputs and 17 immutable inputs match the capture; seeded five-state comparison is a separate single-call check before timing. Each invocation has its own verified cache clear and normal closure. Process CPU is unavailable. These are one opposite-order pair per node, not isolated-loop or forecast gains or repeatability evidence.

Native checks additionally cover the retained 13 edge observations and ten focused target cases under four rounding modes at matching O2/O0, including the two added competing-NaN cases. Generated code packs the intended consumer. The actual integration reuses the unrenamed qualified object, changes archive occurrence 555, preserves the other 583 members and performs one link. Raw build-producer commits remain null; later source tracking is explicit. No fresh whole-source build is claimed.

Executable `4adb20e0` / archive `f9113cba` first passed two complete full-grid outputs and all 185 ordered steps through 07:00 against the matching retained `769195b8` run. The unchanged checker verified scientific values, metadata/layout, 512 ranks, two Y tiles, required writer activity and libraries. All four model scopes and the reader closed normally. That separate one-hour qualification is retained. Its 278.837102-second wall time, 180.829640-second main-step sum and 125863.680378 CPU-seconds are descriptive observations without a fresh timing control.

The subsequent fresh original-first three-hour comparison passed all four products and 545 ordered steps through 09:00. Both arms used 512 ranks, two Y tiles and the same rank placement and single InfiniBand rail; the candidate passed all four positive writer roots, 32 acquisition markers and FIELDVIEW1 environment checks. All eight model jobs and the original scientific reader closed normally. Checked client-cache clearing preceded each arm, and neither forecast was profiled.

| Fresh three-hour measure | Corrected original `546b9915` | Combined `4adb20e0` | Reduction |
|---|---:|---:|---:|
| Model/MPI wall | 824.177365 s | 640.243832 s | 22.3172% |
| Main-step elapsed sum | 607.316250 s | 555.898960 s | 8.4663% |
| Aggregate node CPU | 371218.489792 CPU-s | 311320.066538 CPU-s | 16.1356% |

This is one fixed-order pair, not an isolated X5 contribution or repeatability claim. Main elapsed includes communication/output backpressure, and CPU includes MPI spin. Server load and server caches remain uncontrolled. The previous combined769 pair took 964.849634/659.136806 seconds: both new arms were faster in wall time, with the control moving more. Comparing those percentages alone cannot establish a source regression. This image now owns one-hour and three-hour science; short35, noon, nine-hour and restart scopes remain unqualified. Raw producer commits remain null; `6192344e` records post-test source tracking.

The initial integration wrapper failed while decoding object bytes as text, before replacement/link; the fresh repaired attempt is retained. The candidate-only launch also retained and repaired an inherited fresh-control lookup before any model submission. The external management repair validates the qualified retained reference and preserves all four closure guards; staged workers, grants and the scientific checker remain unchanged. A fresh checked cache clear precedes the successful retry.

Evidence is in `THREE_HOUR_APPLICATION_QUALIFICATION.json`, `THREE_HOUR_RESULT.json`, `THREE_HOUR_READER_CLOSURE.json`, `APPLICATION_QUALIFICATION.json`, `NATIVE_AND_CALLER_QUALIFICATION.json`, `CALLER_TIMINGS.json`, and the actual build/closure records. Restore only the three working records from `d29f7a83` to revert this qualification update; that retains the same X5 image and its earlier one-hour scope. Restore the source and all three working records together from commit `626211e9` to roll back X5 itself. Preserve the evidence. Production and master remain unchanged.
