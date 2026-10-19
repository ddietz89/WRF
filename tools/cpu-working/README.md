# Qualified WRF CPU working configuration

Selected **885c7b6d**, source **e1870583**, retains prior improvements and adds sixth-order Y geopotential-tendency SIMD. [Qualification](../cpu-compute/rhs-ph-y6-interior-simd/QUALIFICATION.json) and [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json) bind actual artifacts. Runtime375/881/825/faba/FIELD_VIEW1 is unchanged. Production/master are unchanged.

CurrentXY passes four complete products,545 ordered steps,all512 ranks,two tiles and four writer admissions exactly against the retained original control. All jobs closed. Wall **668.776s** versus retained **819.213s** is **18.3637% descriptively lower**, CPU12.1638% and main-step sum5.7670% lower. [Three-hour result](THREE_HOUR_RESULT.json) explicitly records **UNPAIRED** timing: no fresh control or isolated Y gain. CPU throttling was nonzero; all eight control/candidate memory-event counters were zero. Checked client caches do not control server load/cache. Main includes MPI/backpressure, not pure compute.

Complete synthetic Y callers were6.10/4.86% shorter; these gains are not added to forecast percentages. Thompson sharing remains experimental.

The precedingX3a/source3e [fresh nine-hour result](NINE_HOUR_RESULT.json) remains2069.312→1849.618s,10.6168% lower wall/8.0348% lowerCPU/5.7321% lower main,1.11878× in one fixed-order pair. Its10products/1625steps scope belongs to X3a, not currentXY885c. The [fresh PD three-hour pair](PREVIOUS_THREE_HOUR_RESULT_PD.json) remains819.213→666.622s,18.6266% lower wall. Historical epochs and caller/forecast gains are not added. The1.5× and2× goals remain unmet.

Rollback selects X3a/source3e290fdb with unchanged runtime or reverts e1870583 and rebuilds. StrictGNU13.3/Zen2/world512/two tiles only; no transferred restart144h/AOCC/Intel scope.
