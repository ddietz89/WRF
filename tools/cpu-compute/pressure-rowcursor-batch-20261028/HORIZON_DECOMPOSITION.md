| Observation | Wall s | Main elapsed s | CPU core-s | Wall−main s | Wall / forecast h | Main / forecast h | CPU / forecast h | Residual / forecast h |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 3h candidate | 642.662552 | 540.643620 | 311297.711114 | 102.018932 | 214.220851 | 180.214540 | 103765.903705 | 34.006311 |
| 3h control metric medians (N=3) | 800.024121 | 596.450450 | 359327.346984 | 203.573671 | 266.674707 | 198.816817 | 119775.782328 | 67.857890 |
| 9h candidate | 1778.833264 | 1682.947950 | 895554.478168 | 95.885314 | 197.648140 | 186.994217 | 99506.053130 | 10.653924 |
| 9h control (N=1) | 2049.434142 | 1850.758020 | 1001366.876019 | 198.676122 | 227.714905 | 205.639780 | 111262.986224 | 22.075125 |

Wall-minus-main includes initialization, output, drain and other elapsed overhead; it is not I/O-only. Main-step elapsed also includes communication, waiting and backpressure. The residual gaps are 101.554738s at three hours and 102.790808s at nine hours; a similar absolute residual gap is a smaller fraction of the longer total. This arithmetic decomposition, alongside the separate controls, describes the horizon percentage gap without assigning a cause. The three-hour control residual is the difference of separately reported metric medians, not the median of per-run residuals.

Own noon/profile/restart/full144 remain false. The raw collector’s inherited selected3f86 labels are preserved by reference and explicitly annotated; current lease and artifact identities establish the tested bundle. Existing scoped compile/reference limitations and raw producer commit null remain unchanged.
