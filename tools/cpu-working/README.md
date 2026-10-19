# Qualified WRF CPU working configuration

Selected **3a203299**, source **3e290fdb**, retains all prior improvements and adds sixth-order X geopotential-tendency SIMD. [Qualification](../cpu-compute/rhs-ph-x6-interior-simd/QUALIFICATION.json) and [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json) bind actual artifacts. Runtime375/881/825/faba/FIELD_VIEW1 is unchanged. Production/master are unchanged.

The fresh corrected-original-first nine-hour pair passed ten complete products,1,625 ordered steps,all512 ranks,two tiles and four writer admissions exactly. Wall **2069.312→1849.618s:10.6168% lower**, aggregate CPU **8.0348% lower**, summed main-step elapsed **5.7321% lower**, throughput **1.11878×**. [Result](NINE_HOUR_RESULT.json) retains cache boundaries, actual closures and resource counters. One fixed-order pair; uncontrolled server state, nonzero CPU throttling and104GiB writer-node cap hits in both arms, with zero OOM. Main includes MPI/backpressure; no integration-only CPU or pure-I/O attribution.

Complete synthetic X callers were5.07/4.98% shorter, with short0.694–0.732s bodies. These gains are not added or attributed individually to the forecast. Y-direction SIMD and Thompson sharing remain experimental.

The prior PDf3ea/sourcee475 [three-hour result](THREE_HOUR_RESULT.json) remains byte-exact:819.213→666.622s,18.6266% lower wall/12.2066% lower CPU/5.7700% lower main. That timing belongs to PDf3ea. [Historical ba422 nine-hour](PREVIOUS_NINE_HOUR_RESULT_BA422.json) remains separate at11.9214% lower wall; its1850.148s candidate is close to current1849.618s but its control/configuration differ. Separate epochs do not isolate changes or regressions. The1.5× and2× goals remain unmet.

Rollback selects PDf3ea/sourcee4754d23 with unchanged runtime or reverts3e290fdb and rebuilds. Qualification is strict GNU13.3/Zen2/world512/two tiles; no transferred restart144h/AOCC/Intel scope.
