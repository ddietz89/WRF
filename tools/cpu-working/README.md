# Qualified WRF CPU working configuration

Selected **f3ea8bf8**, source **e4754d23**, retains all prior4c improvements and adds final positive-definite scalar-consume SIMD. [Qualification](../cpu-compute/pd-rk-final-consume-simd/QUALIFICATION.json) and [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json) retain exact artifacts and rollback to4c. Runtime375/881/825/faba/FIELD_VIEW1 is unchanged.

The fresh corrected-original-first three-hour pair passed four complete products,545 ordered steps,all512 ranks,two tiles and all four writer admissions exactly. Wall **819.213→666.622s:18.6266% lower**, aggregate CPU **12.2066% lower**, summed main-step elapsed **5.7700% lower**, throughput **1.22890×**. [Result](THREE_HOUR_RESULT.json) retains cache boundaries, actual closures and resource counters. One pair; uncontrolled server state and nonzero CPU throttling. All eight model memory-event counters were zero. Main includes MPI/backpressure; no integration-only CPU or pure-I/O attribution.

Standalone complete synthetic PD callers were31.13/26.52% shorter. These percentages are not added or claimed as the individual forecast contribution. New RHS/RNG/codec-inline candidates are excluded from this image. Production/master are unchanged.

[Previous41a](PREVIOUS_THREE_HOUR_RESULT_41A.json), [f064](PREVIOUS_THREE_HOUR_RESULT_F064.json), [8b101](PREVIOUS_THREE_HOUR_RESULT_8B101.json), [ba422](PREVIOUS_THREE_HOUR_RESULT_BA422.json) and [fresh6365](PREVIOUS_THREE_HOUR_RESULT_6365.json) preserve their own epochs. [Current nine-hour evidence](NINE_HOUR_RESULT.json) remains historicalba422 at11.9214% lower wall, not a result forf3ea. The1.5× and2× goals remain unmet.

Rollback selects retained4c/source8583a312 with unchanged runtime or reverts e4754d23 and rebuilds. Qualification scope is strictGNU13.3/Zen2/world512/two tiles, with no transferred restart144h/AOCC/Intel scope.
