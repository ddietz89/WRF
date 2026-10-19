# Closed four-column MYJPBL screen

Neither implementation is qualified or promoted. They leave the selected `8b101` build unchanged. No native caller, timing or forecast was run for these prototypes.

The standalone helper preserved the public VDIFV body and all 23 arithmetic expression trees, while adding a four-column lane dimension. Strict O2 emitted packed arithmetic in all five stages, including forward and backward recurrences. O0 bounds checks passed the eight direct and 48 supplemental fixtures, but O2 changed NaN payloads in direct case 6. Matching exception-state words did not make the differing output bits acceptable.

One integer-only nonfinite-input guard routed exceptional inputs through four original scalar calls. It passed the direct O2 cases, then failed supplemental case 7: finite inputs with zero height differences generated intermediate NaNs whose signs differed. This demonstrates why a finite-input guard is insufficient for the required bitwise behavior. Both failures and independent source/harness reviews are retained; no tolerances, predicates or compiler flags were relaxed.

[Unguarded decision](UNGUARDED.json) and [guarded decision](GUARDED.json) record exact scope, counterexamples and artifact hashes. Raw evidence is under `/home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/myj-horizontal-batch-feasibility-r1/fixed4-prototype-r1/`. The four constructed lanes varied velocity and surface velocity; they were not captured diverse full-MYJPBL columns. No performance gain or application failure is claimed.

Four approved DeepSeek feasibility/implementation-contract calls actually returned across this lane, totaling 35,431 reported tokens; charges are unknown. The returned implementation was rejected for shape/index/bound defects. The tested helper was a separately recorded local mechanical repair; the independent provider review saw its original packet rather than that repair. Local independent reviewers examined the actual tested code.
