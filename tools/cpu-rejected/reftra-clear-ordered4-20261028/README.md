# Clear-sky four-layer output buffering: closed unpromoted

This distinct experiment buffers seventeen operands for four adjacent layers after the original scalar table/prelude work, then uses exact packed output arithmetic. It preserves conservative, small-denominator, mixed/tail and unmasked scalar paths. The selected `1d16` WRF executable and `64bb` output provider remain unchanged.

The complete extracted routine passed O2 and bounds-enabled O0 checks: 324 valid whole-routine cases, 80 separate direct-consumer operand-role checks and six exactly representable unmasked witnesses per optimization level. Actual machine review confirmed true packed divides without reciprocal approximations, FMA or added observer calls. This is not whole-SW or forecast qualification; unrestricted nonfinite table-index inputs are outside the original defined-input scope.

Four cache-cleared arms used opposite order on hpc01/02, CPU24, one core, 4 GiB, zero swap and a 30-second cap. Each timed 262,144 sets of three complete 59-layer profiles, including scalar prelude, table access, grouping, buffering, mask admission and helper calls. Output restore occurs outside the clocks because outputs are not inputs and are overwritten. All four full physical/table records and warm/batch state bytes matched; all jobs and cache helpers closed normally.

| Host | Original seconds | Candidate seconds | Wall reduction | Thread CPU reduction |
|---|---:|---:|---:|---:|
| hpc01 | 0.935380076 | 1.067566269 | -14.1318% | -14.1294% |
| hpc02 | 0.933411491 | 1.072956293 | -14.9500% | -14.9518% |

Negative reductions mean longer candidate time. No isolated consumer speedup was established. Added grouping and operand-buffer/gather/scatter work is included in these complete-routine measurements; its separate cycle contribution was not measured. Close this fixed variant unpromoted because the complete caller is slower on both nodes. No whole-SW build, forecast test, default change or universal negative claim follows.

Retained private preparation: `investigation/wrf-cpu/campaign/spot100-20261016/current1d16-reftra-clear-ordered4-source-question-r1/`. Original raw receipts, failed startup history, driver, fixtures and commands remain there. Reproduction starts from the exact current preprocessed source pinned in SOURCE_CONTRACT.json and the retained source-only diff. No runtime rollback is needed because selection did not change.
