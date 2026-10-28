# Thompson sati lifetime screen — closed unpromoted

The private change replaced only the per-level `sati` temporary with a scalar. Its division and subtraction remain in the same iteration and statement order. `satw` stays an array: a later loop reads its earlier values. The unsafe two-scalar premise was rejected before implementation.

The genuine complete 11-case caller passed at O2/O0 under all four rounding modes, with exact same-optimization raw output, read-only inputs, padding, five state observations and original public MOD bytes. Actual main-routine malloc/free sites fell from 71 to 70 at both levels. The static payload saving is only 128 bytes in the 32-level fixture; no peak-memory or capacity benefit was measured.

The complete **synthetic** fixed mixed-column caller used 20,000 calls per arm, including three full mutable restores and the callee allocations/frees inside both clocks. This is genuine current-module execution, not captured forecast input. All four cache-each arms passed the full 46,208-byte raw/state checks and closed normally.

| Host | Wall time | Thread CPU time |
|---|---:|---:|
| hpc01 | 1.1504% lower | 1.1331% lower |
| hpc02 | 0.0638% lower | 0.6066% higher |

The weak wall signal and mixed CPU result do not establish a significant consistent caller gain. The candidate remains **unpromoted**, with no application run, source/default change or further timing matrix. Previous REAL13 bank results remain separate. The selected executable/archive and all earlier improvements are unchanged.

[Decision](DECISION.json) · [Actual native, machine and caller evidence](EVIDENCE.json)
