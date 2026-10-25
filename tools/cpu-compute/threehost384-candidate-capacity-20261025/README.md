# 384-rank short capacity observation; strict comparison failed

The B4BC candidate completed 35 ordered steps through 06:10 and produced both histories on 01–03 using 384 ranks (352 compute, 8×44, plus 32 quilt), fixed 100 GiB/node and zero swap. All three model workers closed normally; all memory-event counters werezero. This is one short capacity observation, not accepted 384 application science.

| Host | Lifetime cgroup peak bytes | GiB | Memory events |
|---|---:|---:|---:|
| hpc01 | 67,950,804,992 | 63.284 | 0 |
| hpc02 | 68,185,931,776 | 63.503 | 0 |
| hpc03 | 62,143,852,544 | 57.876 | 0 |

Model/MPI wall was145.597406s, main-step elapsed sum53.730400s, and summed CPU43733.032022s. These are candidate observations only; no 256 speed comparison is made.

The unchanged protected comparator rejected the initial 06:00 output because global attributes `NTASKS_TOTAL` and `NTASKS_Y` differ from the retained original 256 reference. It continued checking all 275 initial-file variables and reported no variable-value/mask/nonfinite/layout errors or localized field mismatches. The first-result assertion stopped the reader, so there is **no admitted 06:10 comparison or full-trajectory equality**. Ordered-step equality and independent per-map tile proofs had passed before the file comparison.

The first failed reader lost its detailed return; a distinct reader-only diagnostic persisted that same strictFAIL and also exited 1. Both failures remain. The prior original 384 initialization OOM at 100 GiB remains a separate failed attempt; no new original 384 forecast was run. Default 256, the protected oracle and all resource caps stay unchanged. No attribute exemption, tolerance, further 384 run or reader is proposed. Exact artifact hashes and invocation references are in `EVIDENCE.json`.
