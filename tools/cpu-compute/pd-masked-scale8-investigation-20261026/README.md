# Masked PD scale producer: exact application, fixed variant held

The AVX2 helper substantially improves a mixed-active extracted kernel and passes the native and application checks below. It remains **unpromoted** because the complete captured caller was slower on both measured hosts and used a different mask distribution. Canonical source, defaults and selected executable `8280933d` are unchanged.

| Measurement scope | First host: wall reduction | Opposite-order host: wall reduction |
|---|---:|---:|
| Initial masked kernel, 8,388,608 calls | 75.21% | 75.46% |
| Initial complete captured PD caller, 256 calls | -3.68% | -1.59% |
| Empty-block-skip mixed kernel, 8,388,608 calls | 73.36% | 73.54% |
| Empty-block-skip complete captured caller, 256 calls | -2.42% | -3.64% |

All four-arm screens passed full raw-output and five-state equality, per-arm cache clearing and normal service closure. Equal output restores are inside the integer wall/thread-CPU clocks. The synthetic 188-lane kernel has 134 active lanes (71.28%). The captured caller's full eight-lane blocks were all inactive in both proof modes. Neither fixture establishes forecast-wide mask frequency. Kernel, caller and forecast gains are separate measurements.

The helper performs the original signaling ordered comparison first. It stores minus one and skips arithmetic for an entirely inactive block; mixed blocks mask inactive operands before addition and true division. The original Fortran scalar loop handles tails and rows with unmasked SSE exception traps. No floating-point controls or errno values are normalized. The new helper source is `3ae7e18d`, object `84ad785e`; qualified Fortran PP `632dac10` and O2 object `8c9cebad` are unchanged. The original public module interface remains exact. All eight original whole-PD protocols at O2/O0 and 228 direct helper witnesses passed with the new C object. Their tested final-state scope does not certify trapping chronology, every CPU or other compiler stacks.

A separate perf-stat diagnostic counted 8.53% fewer instructions and 0.77% fewer cycles across the complete spawned userspace process, including startup, warmup, proof, timed batch and output. These counts do not isolate the timed caller or explain its negative timings. The slowdown cause remains unresolved.

The experimental executable `2b4e35ae` and archive `0475852b` replace one Advect member and append one helper: 585 archive members, with the other 583 unchanged. RSL and all 18 direct link inputs remain exact. Delivery uses qualified preprocessed source/cached objects and a scoped canonical projection; no clean whole-source build certificate is claimed.

Its own unprofiled three-hour SAME512 forecast passed **four complete products and all 545 ordered timesteps** against the corrected original. All four model jobs and the original checker closed normally.

| Metric | Retained original median, n=3 | Experimental child, n=1 | Descriptive reduction |
|---|---:|---:|---:|
| Model/MPI wall, minutes | 13.33374 | 10.41787 | 21.8683% |
| Main-step elapsed, minutes | 9.94084 | 9.02623 | 9.2006% |
| Aggregate CPU, CPU-hours | 99.81315 | 84.43229 | 15.4097% |

This candidate-only comparison is unpaired. The original cohort membership, individual values and aggregation rule are retained in `THREE_HOUR_APPLICATION_QUALIFICATION.json`. Main-step elapsed includes communication and waiting. The raw collector retains inherited CalcWW labels; the actual lease and build identify the masked PD child. No nine-hour, noon, restart or full-144-hour qualification is inherited.

Selected parent `8280933d` measured 624.404618 seconds wall, 540.431350 seconds main-step elapsed and 303161.584874 CPU-seconds. This child measured 625.072422, 541.573710 and 303956.239108 respectively: effectively neutral single observations, without an isolated incremental gain or regression claim.

Hold this fixed variant because of the **measured captured-caller cost and mask-distribution mismatch**, not merely the neutral forecast. Retain its significant mixed-kernel gain and exact-qualified experimental image. Reopen only for a distinct mechanism that removes the inactive-workload dispatch cost or measured relevant production mask activity; do not repeat the existing matrix without new evidence. The prototype is preserved for review under `prototype/`; it is not wired into the default build.

Rollback requires no action: selected `8280933d`, canonical source and working defaults remain unchanged. Original failures and subsequent packaging/fixture repairs remain referenced in the private evidence. Evidence JSON files separate native, kernel, caller, process-counter, build and application claims.
