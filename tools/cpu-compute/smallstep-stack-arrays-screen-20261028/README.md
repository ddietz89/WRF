# SmallStep stack arrays — rejected for default use

Adding only `-fstack-arrays` to the current strict O2 SmallStep module passed the retained complete native checks: W392 plus the full 40-role W capture, UV70, MU87 and coefficient80. Raw outputs, physical guards, read-only inputs and all five processor-state values remained hard requirements. The preprocessed source and original public module interface bytes were unchanged.

Actual malloc/free sites fell from 15 to zero: W8, UV4, MU2 and coefficient1. The flag changes placement rather than array capacity; no peak-memory or capacity benefit was measured. Five other procedure bodies and their complete relocations remained exact. Changed target bodies and unwind records retain their finite machine scope in the evidence.

The complete captured W caller included three full mutable restores and the entire callee inside both clocks, for 1,024 calls per arm. The four opposite-order arms each cleared cache and passed the original full raw/read-only/state checks before closing normally.

| Host | Parent wall (s) | Candidate wall (s) | Wall cost | Process CPU cost |
|---|---:|---:|---:|---:|
| hpc01 | 1.786358 | 1.898369 | 6.2704% higher | 6.1969% higher |
| hpc02 | 1.792177 | 1.806602 | 0.8049% higher | 0.8182% higher |

This is one genuine historical 450-by-342, 16-rank `advance_w` capture with `damp_opt=3`. It is not a production 512-rank tile or a full forecast, and does not measure UV/MU/coefficient performance. The slower caller on both hosts supplies no significant gain for the whole-module default. Keep this candidate **unpromoted**, with no further performance sweep or repeats without a new mechanism. The prepared cached build and noon application context remain inactive; the selected source and image are unchanged.

The first native attempt's directory-collision failure remains preserved. Its fresh cached continuation passed every original scientific gate; that success does not erase the operational failure. No O0 or application qualification was performed.

[Decision](DECISION.json) · [Native, machine, failure history and all four caller observations](EVIDENCE.json)
