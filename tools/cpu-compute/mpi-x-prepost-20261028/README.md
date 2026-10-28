# Non-typed X receive preposting: closed unpromoted

The complete counterbalance passed the original exact checker in all four arms: two complete outputs and 185 ordered steps each. The fixed candidate stays **unpromoted** because the first application improvement did not repeat in reverse order; the uniform 480-rank caller screen was also slightly slower.

| Arm, in execution order; means separately labelled | Wall seconds | Main-step seconds | Aggregate CPU core-seconds |
|---|---:|---:|---:|
| R4-parent | 270.888027 | 177.23237 | 122953.786788 |
| R4-candidate | 258.028361 | 175.70620 | 116142.014978 |
| R5-candidate | 259.253595 | 176.04737 | 116651.672321 |
| R5-parent | 258.166585 | 176.02129 | 116244.985785 |
| Parent mean (n=2) | 264.527306 | 176.62683 | 119599.386286 |
| Candidate mean (n=2) | 258.640978 | 175.87678 | 116396.843649 |

In R4 (parent→candidate), wall/CPU/main-step elapsed were **4.7472% / 5.5401% / 0.8611% lower**. In R5 (candidate→parent), the candidate was **0.4211% / 0.3499% / 0.0148% higher**, respectively. The two-arm means are descriptively 2.2252% / 2.6777% / 0.4246% lower; these averages are driven by the initially slower R4 parent and do not establish a stable gain. About 88% of the first pair's wall difference was outside main-step elapsed time. That residual includes initialization, output and draining, not pure I/O or removable wire time.

Every candidate compute rank emitted its once-only admission marker; all 32 output ranks and every parent rank emitted none. The same current `00c6` baseline, unprofiled one-hour workload, 512-rank layout, limits and individual cache boundaries were retained. The original 75-minute reference supplied exact science only and is never a timing denominator. The MPI-only owner rule treats errno/inexact differences as diagnostics; every other state/control bit and raw science/guard check remains hard, without state normalization.

The private tracked-source draft remains unqualified for canonical integration: the tested module used a target inserted after preprocessing, while the normal canonical source filter removes comments. Only a minimal Registry fixture and enabled target-stream identity were shown; full-module ON/OFF source equivalence and a clean canonical rebuild were not established. No source, default or selected-image change is made, and no further variant, build or timing run is planned for this fixed candidate. [All four observations, pair reductions, descriptive means, exact scope and rollback](EXPERIMENT.json).
