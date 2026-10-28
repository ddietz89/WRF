# CUADJTQ allocation coalescing: closed unpromoted

Two simultaneously live scratch vectors became separate columns of one array. The compiled routine reduced allocation/free pairs from two to one while preserving the same storage capacity and arithmetic.

The complete extracted procedure passed 176 exact comparisons at O2 and O0, including full physical records, read-only inputs and saved floating-point state. Four complete-caller arms passed raw/state checks, fresh client-cache boundaries and normal closure. Each arm ran 65,536 calls with both input/output restores inside the clocks.

| Host/order | Parent wall | Candidate wall | Wall reduction | Thread CPU reduction |
|---|---:|---:|---:|---:|
| hpc01, parent then candidate | 0.399435 s | 0.399961 s | −0.132% | −0.132% |
| hpc02, candidate then parent | 0.399916 s | 0.404790 s | −1.219% | −1.223% |

No significant caller gain or separate memory benefit was established. The fixed candidate remains unpromoted; no whole-module or forecast test was needed. These observations do not attribute the small timing differences to a specific machine effect. [Retained decision and evidence](DECISION.json).
