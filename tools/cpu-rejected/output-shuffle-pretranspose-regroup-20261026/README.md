The fixed pretranspose lane-regroup candidate is **closed unpromoted**. Correctness passed; the one cache-cleared complete-provider pair regressed. The selected db0d provider and NG9371 codec remain unchanged.

| hpc04,32 complete-provider calls | Parent | Candidate | Candidate slower |
|---|---:|---:|---:|
| Wall seconds | 1.624104389 | 1.664526740 | 2.488901% |
| Aggregate process CPU seconds | 6.116909827 | 6.204628272 | 1.434032% |

This was one parent→candidate observation on hpc04, with checked sync/drop-caches before each executable and normal closures. Both roles preserved all encoded bytes against immutable gold, stock decoding, read-only inputs/layout/options, and errno/rounding/IEEE flags/MXCSR/x87 state. Native32-call correctness also passed;136 actual worker creates/joins per role were retained. There were no native or timing failures.

Actual GNU13 code replaces four final variable VPERMD operations and their index-vector load with four early immediate lane permutes. It retains sixteen shuffle operations and has no stack spills. The compiler folds each C/D source into both permutes: six32-byte memory operands cover the same unique128-byte input footprint, versus four in the parent. This repeated192-byte operand traffic is observed; it is **not a proven cause** of the regression. Memory peaks do not demonstrate a resource benefit.

The timer includes full packing/shuffling/compression and worker creation/join, with release/checks/decode outside the call clock. Isolated shuffle timing was not collected, so this result does not establish that the shuffle kernel itself is slower. The partial-helper profile101records/5.6856%selectedperiod is source-identity context, not global writer cost or removable critical-path time. No forecast, default, application qualification or statistical claim follows.

Retain the fixed candidate, inverse, actual provider responses (including malformed ancillary author JSON), native receipt/closure, scoped machine classification and both caller receipts/closures through EVIDENCE_REFS.json. No additional variant, repeat or forecast is proposed. Rollback requires no action because this candidate was never selected.
