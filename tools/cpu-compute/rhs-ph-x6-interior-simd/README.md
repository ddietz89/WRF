# Sixth-order X geopotential-tendency SIMD

One `OMP SIMD` directive in the independent sixth-order X interior loop of `rhs_ph` is promoted in the working configuration. Bounds, expressions and other loops are unchanged; fast math remains disabled. [Qualification](QUALIFICATION.json) records exact native, caller, build and application evidence.

All33 complete synthetic RHS cases pass raw/state/readonly/physical checks at bounds-checked O0 and strict O2. Opposite-order complete synthetic caller bodies were5.0695/4.9773% shorter, including identical restore/state work. These are short0.694–0.732s observations, not production-tile or forecast contributions.

The combined3a executable/source3e290fdb passed a fresh corrected-original546b-first nine-hour full-grid comparison: ten products,1,625 ordered steps,all512 ranks,two tiles and four writer admissions exact. Wall2069.312230→1849.618368s is10.6168% lower, aggregate CPU8.0348% lower and summed main-step elapsed5.7321% lower. This is one combined pair, with no isolated/additive X gain or repeatability claim. Both writer-node models reached104GiB with zero OOM; throttling and uncontrolled server load remain limitations. Main includes MPI/backpressure.

Rollback selects retained PDf3ea/sourcee4754d23 with the unchanged375/881/825/faba/FIELD_VIEW1 runtime, or reverts3e290fdb and rebuilds. Production and master are unchanged. The prior PD three-hour result remains separately bound to that older executable; it is not transferred to3a. No restart,144-hour or othercompiler qualification is claimed.
