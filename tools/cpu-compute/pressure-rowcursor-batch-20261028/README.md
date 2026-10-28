Pressure consumers and output row packing — October 28

The working configuration now includes the ordered four-cell pressure consumer and bounded coordinate carry in output packing. The combined 512-rank, three-hour forecast passed the unchanged checker: all four complete outputs and all 545 ordered timesteps matched the approved corrected-original baseline exactly.

| Metric | Original control median (3 runs) | Latest combined run | Reduction |
|---|---:|---:|---:|
| Whole-run wall time | 13.33374 min | 10.71104 min | 19.6696% |
| Integration elapsed time | 9.94084 min | 9.01073 min | 9.3565% |
| Aggregate CPU | 99.81315 core-hours | 86.47159 core-hours | 13.3665% |

The controls are the unchanged, preselected A2/A1/5c75 cohort. These historical comparisons are descriptive; unresolved operating-epoch differences prevent a fresh matched-speedup claim. Integration elapsed time is the sum of main-step wall times, separate from aggregate CPU.

Compared with the preceding PWAT configuration, whole-run wall time was essentially unchanged (642.85 to 642.66 seconds). Integration elapsed time and aggregate CPU were 0.41% and 0.46% lower. These adjacent runs do not isolate either candidate's effect.

The extracted pressure row-consumer screen was 42.6–44.5% shorter, preserving raw results and IEEE state; it excludes the original power operation and the rest of the procedure. Output packing passed encoded-byte, decoded-field, layout, ownership and IEEE checks. Its longer complete-provider pairs were 1.0% and 10.0% shorter; shorter pairs were mixed. These kernel/caller results support retaining both changes and are separate from forecast performance.

The pressure path defaults on within its qualified strict GNU 13.3 configuration; `WRF_POSTPOW_FINAL_CONSUMER=0` plus regeneration/rebuild/relink restores its scalar path. The output build remains `fused-pack`; its current selector now identifies the qualified guard and row-cursor source. The repaired recipe compiled and linked successfully, while byte-identical reproduction of the selected provider remains unqualified. Exact artifacts, support limits, retained failures and rollback are recorded in `tools/cpu-compute/pressure-rowcursor-batch-20261028/`. The same bundle subsequently passed its own nine-hour daylight qualification.

See THREE_HOUR_APPLICATION_QUALIFICATION.json, PRESSURE_COMPONENT.json, ROWCURSOR_COMPONENT.json and SOURCE_REBUILD_RECIPE.json for the exact evidence and rollback.

## Pressure and output packing: nine-hour qualification — October 28

The same combined build passed the unchanged nine-hour full-grid checker: all ten complete outputs and 1,625 ordered steps matched exactly. All four model jobs and the checker closed normally. All prior improvements remain included.

| Metric | Retained original nine-hour control | Latest combined run | Reduction |
|---|---:|---:|---:|
| Whole-run wall time | 34.15724 min | 29.64722 min | 13.2037% |
| Main-step elapsed time | 30.84597 min | 28.04913 min | 9.0671% |
| Aggregate CPU | 278.15747 core-hours | 248.76513 core-hours | 10.5668% |

This is an unpaired comparison with one separate current-epoch original control. The three-hour comparison below retains its own three-control median; the cohorts are kept separate. Main-step elapsed includes communication and waiting, and is separate from CPU consumption.

The wall-time reduction is smaller at nine hours while the main-step reduction stays near 9%. The measured wall-minus-main gap between control and candidate is about 102 seconds at either horizon. That similar absolute gap contributes a smaller percentage of the longer run. This remainder includes initialization, output, drain and other overhead; it does not identify I/O time alone. See `HORIZON_DECOMPOSITION.md` in the evidence package for normalized values.

Exact qualification: `tools/cpu-compute/pressure-rowcursor-batch-20261028/NINE_HOUR_APPLICATION_QUALIFICATION.json`. The executable, archive and output provider are unchanged from the qualified three-hour run. The same build subsequently passed instrumented daytime/source-identity qualification; restart and full 144-hour qualification remain outside this result.

Four-host daytime source identity is qualified in INSTRUMENTED_NOON_PROFILE_QUALIFICATION.json. FOURHOST_PROFILE_REPORT.md records the selected-thread counts and limits. The unprofiled three-hour and nine-hour timing results remain unchanged.
