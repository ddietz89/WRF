# pqdownheap child-control: closed, unpromoted

Correctness passed, but this fixed candidate loses in both complete constructor and complete provider measurements. Keep selected codec `937130c2…`; no forecast or default/source promotion is needed.

| Complete measured scope | Host | Wall increase | CPU increase |
| --- | --- | ---: | ---: |
| constructor | hpc01 | 9.3343% | 9.3191% |
| constructor | hpc02 | 9.5607% | 9.5811% |
| provider | hpc01 | 0.3970% | 0.0693% |
| provider | hpc02 | 1.4727% | 0.1920% |

All eight separate arms passed exact data/five-state checks and normal closure, with cache cleared before each. Constructor timing covers 131,072 whole `build_tree` calls, including bit-length/code generation and identical state restores inside both integer clocks. Its dense literal-tree histogram is synthetic. Provider timing uses the unchanged 32-call four-chunk fixture, including allocation, packing, compression and thread lifecycle; owner release remains outside the clock equally in both roles. These are separate scopes, not additive forecast gains.

The literal source preserves the right-child tie priority and root-exit predicate. Native testing passed genuine whole-tree 12 cases, 13 codec corpora, five streaming cases, stock decoding, and both complete-provider roles with full raw/read-only/five-state and real thread-join checks. Actual code changed, but static conditional sites increased 54→57 and no new conditional move appeared. This does not identify the causal cost of the regression.

Preserved attempts: native R1 failed in the original provider because the gate allowed two CPUs while its unchanged affinity contract required four. Fresh four-core R2 reused the successful prior checks and passed the provider checks. The first cached-wrapper query failed a full-stat equality assertion that included access time; fresh R2 retained identity/content checks while excluding access time. Neither failure is rewritten as a numerical failure or a pass.

The candidate remains private. The existing selected codec/source needs no rollback. Raw receipts, closures, actual provider responses, source inverse and machine classification remain referenced with hashes in `EVIDENCE_REFS.json`. No further arms, variant or forecast is proposed.
