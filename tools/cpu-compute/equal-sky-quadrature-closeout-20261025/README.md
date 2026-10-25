# Equal-sky quadrature: fixed candidate closed unpromoted

The exact-input guard was numerically successful in the bounded actual-module tests but slower in every measured workload. It is closed without promotion, application testing, or another repair. The selected BACF source, executable and defaults are unchanged.

| Workload | Parent wall (s) | Candidate wall (s) | Wall increase | Process CPU increase |
|---|---:|---:|---:|---:|
| Whole pair, exact hit | 0.910183 | 1.043275 | 14.6225% | 14.6208% |
| Whole pair, late mismatch | 0.903077 | 1.084911 | 20.1349% | 20.1426% |
| Complete SPCVMC, mixed cloud | 1.472283 | 1.499055 | 1.8184% | 1.8189% |
| Complete SPCVMC, clear | 1.273145 | 1.364936 | 7.2098% | 7.2022% |

These are eight normally closed, cache-cleared arms on hpc01, physical CPU24: one parent→candidate observation per workload. Whole-pair arms made1,048,576 calls; complete-SPCVMC arms made4,096 calls. The hit/miss inputs and clear/mixed columns are synthetic. Guard and copy costs remain inside the measured paired routine; complete-SPCVMC includes its original physical-output reset and full call. Native warm-ups, raw/state checks and table/read-only checks are outside the integer clocks. No counterbalanced repeatability, production hit frequency, isolated recurrence share, global headroom or forecast gain is established.

The actual full paired routine passed the original32 cases×4rounds and an additional256 equal-input/readset/exceptional calls at strict O2 and bounds-checked O0. The additional619,520-byte streams match exactly, as do the original12 complete-SPCVMC finite calls (11,360bytes), including physical padding, read-only data and final errno/FP state. This is a performance rejection of the fixed candidate, not a numerical failure. Earlier R1 syntax and preflight metadata failures remain retained; they are not successful tests.

[Structural adjudication](DECISION.json) preserves the mixed scope. Source outside the target procedure and shared pools/full pool relocations are exact; the target public module is byte-exact. A small named tail-call placement change is proved, but SPCVMC and its enclosing generated radiation caller genuinely change. Their full raw code/relocations are not declared identical. Three other raw module-file differences remain explicit. The callee fixture covers changed SPCVMC, not the complete outer radiation wrapper; no application qualification follows.

A plausible explanation, **inference only**, is that the bit-comparison scans and B-output copies outweigh the saved arithmetic, while the original two independent recurrences expose instruction-level parallelism that the single-sky path loses. Changed caller code generation may also matter. The available evidence does not quantify these causes separately. The candidate is already slower on exact hits, so no production-frequency study or additional profiling is needed to close it.

[Decision and metrics](DECISION.json) · [Actual receipts, closures, cache evidence and source proof](EVIDENCE_REFS.json). All positive numerical evidence is retained. No scientific checker, production source, selection, build default, runtime or qualification record is changed by this report.
