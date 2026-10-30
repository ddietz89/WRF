# Ordered ADD_A2C_V prefix

Process four independent I columns through unaligned SSE operations with explicit destination/source roles matching the original scalar add, multiply and accumulation. Masked traps and a nonempty four-column prefix are required; the scalar tail and unsupported-state fallback retain their original loops. The guard admits the tested GNU13.3 pure-MPI strict-O2 REAL4/INTEGER4 x86_64 configuration and existing mask getter.

Original-MOD native comparisons passed 120 masked observations plus 18 finite unmasked observations at each of O2 and O0, with full physical arrays, read-only input/configuration, guards and all five hard state words exact. Raw public MOD equality is false: exactly five conservative ARRAY_OUTER_DEPENDENCY attributes are separately admitted. The defined global ABI is exact; two new undefined helper references are recorded explicitly.

O2 non-target phy_shcu_ten raw code differs in stack argument marshalling. A fixed symbolic proof preserves six register and fifteen stack argument values and restored stack pointer, with the remaining branch/instruction graph equal. O0 non-target raw code is equal. Actual relocation targets/constants are classified individually; diagnostic source paths differ and no diagnostic-byte or unwind equivalence is claimed. Original failed gates are retained.

Complete synthetic caller clocks include the 311712-byte left restore, mask query, helper, tail and entire callee over fixed 8192 calls. One opposite-order pair per host measured 59.6105% and 50.5505% lower wall time, with corresponding thread CPU reductions. These are caller observations, not isolated-loop, production-geometry, repeatability or forecast gains.

The actual experimental image passed its own unchanged 545-step/four-product three-hour checker with normal model and reader closures before source delivery. Nine-hour, noon, profiling, restart, full144 and clean full-source rebuild remain unqualified. The canonical source is post-test correspondence to cached tested objects; raw producer commit remains unknown.

Opt out with WRF_ADD_A2C_V_ORDERED4=0 and regenerate PP, rebuild module/archive and relink. Whole-image rollback is the previous pressure-damping image e2580e95, archive4c5eed41.
