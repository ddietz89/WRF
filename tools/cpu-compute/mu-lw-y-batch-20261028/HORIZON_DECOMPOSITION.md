| Horizon / observation | Wall s | Main elapsed s | Wall−main s | Wall / forecast h | Main / forecast h | Residual / forecast h | CPU core-s |
|---|---:|---:|---:|---:|---:|---:|---:|
| 3h_candidate | 638.537897 | 540.475790 | 98.062107 | 212.845966 | 180.158597 | 32.687369 | 310728.238527 |
| 3h_own_control_median3 | 800.024121 | 596.450450 | 203.573671 | 266.674707 | 198.816817 | 67.857890 | 359327.346984 |
| 9h_candidate | 1780.503969 | 1685.381070 | 95.122899 | 197.833774 | 187.264563 | 10.569211 | 896312.353044 |
| 9h_own_control_N1 | 2049.434142 | 1850.758020 | 198.676122 | 227.714905 | 205.639780 | 22.075125 | 1001366.876019 |

Same5e21/8839/e418+64bb own unprofiled SAME512 nine-hour1625/tenFULL and retained own3h545/fourFULL. Nine-hour timing DESCRIPTIVE UNPAIRED versus separate currentepoch originalN1; three-hour timing DESCRIPTIVE versus its own median3. No cohort pooling, extrapolated speedup, causal/additive or repeatability claim. Wall-minus-main includes initialization/output/drain/other overhead and is not an I/O-only measure. Noon/profile/restart/full144 remain false. Existing scoped compiler/reference limitations and rawproducerNULL remain unchanged.

Within-horizon descriptive reductions:3h {'wall_seconds': 20.185169434792716, 'cpu_seconds': 13.525023593365415, 'main_step_sum_seconds': 9.38462868122576};9h {'wall_seconds': 13.122167101847083, 'main_step_sum_seconds': 8.935633303374802, 'cpu_seconds': 10.491112247755918}. Different baseline cohorts and horizon composition can change percentages; these observations do not establish which component caused the gap.
