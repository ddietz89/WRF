# PD cross-species mu/cr caches: fixed prototype held

The fixed two-3D-cache prototype is held without a whole-PD implementation or application run. Adequate-duration synthetic sequence costs show no consistent significant gain. Selected828 source/defaults remain unchanged.

| Screen | Host / order | Parent wall(s) | Candidate wall(s) | Wall reduction | Thread CPU reduction |
|---|---|---:|---:|---:|---:|
| R1,64sequences (<100ms) | hpc03 / P→C | 0.087496108 | 0.088632512 | -1.2988% | -1.2995% |
| R1,64sequences (<100ms) | hpc04 / C→P | 0.088345022 | 0.087346483 | +1.1303% | +1.1294% |
| R2,1024sequences | hpc03 / P→C | 1.425142146 | 1.426253789 | -0.0780% | -0.0881% |
| R2,1024sequences | hpc04 / C→P | 1.395004256 | 1.369900189 | +1.7996% | +1.7964% |

Positive reductions mean shorter time. Each screen used one opposite-order pair per host, a checked cache clear before every arm, exact same-count raw/five-state oracles and normal invocation-bound closures. R1's87–89ms arms were too short for the100ms floor. R2 changed only64→1024 complete six-species sequences using the same compiled kernel/support; all arms lasted1.37–1.43s. Actual1024 terminal states were measured and compared across those arms, never borrowed from64-call records.

Actual machine readback proves useful work removal on the ready branch: mu arithmetic and two cr true divisions become cached loads, leaving the original dy/dt true division (three divides become one per corresponding lane). First-use allocation/reset/fill, reuse/free, all original normal-Y5 flux work and equal full output restores remain inside the single integer MONOTONIC/thread-CPU batch. This is a source/machine mechanism, not proof of production frequency or global headroom. No bandwidth, spilling or causal slowdown claim is made.

Correctness remains narrowly scoped:32 local controlled synthetic records (eight sequences/four masked modes), plus the EPYC188×19×32 four-mode warm raw/five-state proof before timing. Genuine whole-PD/ModuleEM/Solve qualification and real production cache lifetime remain untested. The cache requires identical per-stage/per-tile inputs, exact eligible bounds/branch, rounding/control and intervening state behavior; no persistent global cache or state normalization is authorized. Sequence-final flags do not certify every intermediate exception observation.

The original hold record's then-pending codegen note is superseded only by the later scoped machine classification included here. Large logs, binaries, raw arrays and full canonical PP are referenced by hash, not duplicated. Reopen only for a distinct measured mechanism or materially new supported workload evidence; the current fixed prototype does not justify more replay or full application work.
