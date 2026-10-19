# Positive-definite scalar final-consume SIMD

One SIMD directive vectorizes the final independent I loop in `rk_update_scalar_pd`. Bounds, operands, zero/add/reset passes and strict floating-point flags are unchanged.

Twelve full synthetic native cases passed raw/state/readonly/guard checks at bounds-checked O0 and strict O2. Packed divides replace scalar divides in the target. Opposite-order complete synthetic callers were 31.13% and 26.52% shorter, including identical restores/state work; these are not production-tile or forecast gains.

The combined f3ea build passed a fresh corrected-original three-hour full-grid comparison: four exact products, 545 steps, all512 ranks and two tiles. Wall819.213→666.622s (18.6266% lower), aggregate CPU12.2066% lower and summed main-step elapsed5.7700% lower. One fixed-order pair; server state uncontrolled, CPU throttling present, all eight model memory-event counters zero. Main time includes MPI/backpressure. No individual contribution or nine-hour/restart/othercompiler qualification is inferred.

[Qualification](QUALIFICATION.json) and [combined result](../../cpu-working/THREE_HOUR_RESULT.json) retain actual artifacts and evidence. Rollback selects retained4c with the same runtime, or reverts e4754d23 and rebuilds. Production and master are unchanged.
