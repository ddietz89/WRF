# Final-RK theta SIMD

Image `604cfb52` and archive `21643e0c` passed the original three-hour science check: 545 steps and four full outputs, with normal model and reader closures.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.501492 | 21.2412% |
| Main-step elapsed minutes | 9.940841 | 8.861294 | 10.8597% |
| Aggregate CPU core-hours | 99.813152 | 85.046994 | 14.7938% |

This image is qualified only for its own unprofiled three-hour run on the same 512-rank configuration: 545 steps and four full outputs passed the unchanged checker, with all four models and the reader normally closed. Its noon, nine-hour, profile, restart, full 144-hour and clean full-source rebuild scopes remain false. The parent own nine-hour qualification remains historical. Only module_small_step_em.o changed; the other 592 archive members, RSL, provider and all 18 direct inputs are unchanged. Native same-option O2/O0 tests passed 544 complete raw comparisons, including all five processor-state words. The final-RK complete synthetic FINISH caller was 15.3% and 16.8% faster; the nonfinal control showed no consistent gain. These measurements are not a forecast speedup. The source commit records correspondence after testing; raw producer commit remains NULL. Three-hour timing is one unpaired descriptive observation against the fixed median of three original controls; raw A2 remains separate.

The one source change adds a SIMD directive to the final-RK theta loop in `small_step_finish`. Arithmetic, bounds, Make rules and compiler flags are unchanged. All 544 same-option native comparisons passed. The complete final-RK caller, including the same array restores, was 15.3192% faster on host 01 and 16.8351% faster on host 03. The nonfinal control varied from 1.2737% lower to 0.3652% higher wall time, so no control-stage gain is claimed. These synthetic caller results do not establish a forecast gain.

Source correspondence commit `0470ec1d` follows the tests; raw producer commit remains NULL.

Rollback: Select retained qualified 6bc4/aeb4 image/archive. To rebuild from source remove this one directive, rebuild module_small_step_em.o using the unchanged qualified flags, and relink.
