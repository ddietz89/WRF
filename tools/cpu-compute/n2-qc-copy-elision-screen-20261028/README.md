# N2 QC-copy elimination: retained, unpromoted

Both private candidates passed the same strict native checks: five roles, 16 defined synthetic cases, four masked rounding modes, full physical/read-only/guard checks and all five compute-state words. No captured N2 fixture or full-forecast qualification is claimed.

| Candidate | hpc01 wall / CPU change | hpc02 wall / CPU change |
|---|---:|---:|
| R1 direct QC with inner validity checks | 3.2532% / 3.2493% slower | 3.1930% / 3.1756% slower |
| R2 once-only valid-QC dispatch | 3.2248% / 3.2186% slower | 3.2834% / 3.2717% slower |

Each arm measured 2,048 complete 188×19×33 synthetic N2 calls with identical BN2 restoration and all routine allocation/free costs included. Both opposite-order pairs passed checked cache, original complete pre/post gold, raw/state and normal-closure requirements. CPU means main-thread CPU.

Actual generated code removes one allocation/free pair and the QC copy/zero materialization. R2 also removes both repeated QC-validity tests from the consumer loops and retains the literal original routine for absent QC. The static removed array is 471,504 bytes for this geometry; peak-memory and capacity benefits were not measured. Hoisting the guards did not recover performance, so their primary causal role is unsupported. The remaining slowdown mechanism is unmeasured.

Retain both source/native/cost records and the static saving as evidence. Do not promote either candidate or try further layout/guard variants without a new measured mechanism. The selected source/build and forecast checker are unchanged. `EVIDENCE_REFS.json` pins external evidence; artifacts are not recursively copied here.

The timed R2 executable was verified against the actual new object: unique 973-byte wrapper and 7,092-byte direct body match outside their recorded relocation words. Its actual hot tail jump reaches the new direct body and its absent-QC jump reaches the original routine. The old R1 private object is absent from the R2 link command. This excludes accidental reuse of the old candidate as an explanation of the unchanged cost result.
