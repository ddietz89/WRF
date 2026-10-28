# Advection automatic-array stack screen

**Closed unpromoted.** Adding only `-fstack-arrays` to the identical-PP GNU 13.3 strict O2 advection module passed the retained native checks, but did not improve the complete captured PD caller. No application build or forecast ran, and no source, Make default or selected image changed.

| Host / order | Parent wall (s) | Candidate wall (s) | Candidate wall / CPU change |
|---|---:|---:|---:|
| hpc01 P→C | 2.040949361 | 2.091571607 | +2.4803% / +2.4745% |
| hpc02 C→P | 2.045610304 | 2.048435098 | +0.1381% / +0.1856% |

Each arm charged 256 complete `advect_scalar_pd` calls and one full mutable tendency restore per call inside both integer-nanosecond clocks. CPU means main-thread CPU. Cache clearing preceded every arm; all four full 7,840,840-byte records, guards, read-only checks, defined output footprints and five state words matched. All arms closed normally with empty cgroups. The original untimed checks and same-arm warmup were retained. This is one captured caller screen, not a persistent regression or forecast-cause claim.

Actual code generation removes 52 static allocation sites across eleven changed functions, including eleven in PD. Seven residual frees belong to diagnostic TRIM cleanup. PP and raw public MOD remain exact; eight data pools and the seed helper body/full relocations are exact. Target instruction/relocation and unwind differences remain explicit; CFI is unclassified. Finite native coverage includes original ordinary, PD, V and W protocols and the public U supplement. Mono/WENO, O0, all configurations, universal IEEE/trap equivalence and application qualification remain outside scope.

Removing allocation calls did not establish caller speed, peak-stack or capacity benefits. The inactive one-member application kit was cancelled before staging. Current `efa608eb` / `05cc9c67`, including MYJ and Thompson stack changes, remains selected. [Exact evidence and hashes](EXPERIMENT.json).
