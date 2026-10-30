# Ordered ADD_A2C_U prefix

Reuse the existing ordered V SSE helper for four U columns with the read-only current and I-minus-one streams. Preserve U's i_end=ite, kts:min(kte,kde-1), scalar tail and trap-enabled fallback. Enable only under the tested GNU13.3 pure-MPI strict-O2 REAL4/INTEGER4 x86_64 guard with the existing V helper owner. No helper source or arithmetic changes.

Original-MOD comparisons passed 128 masked observations plus 18 finite unmasked observations at each O2 and O0. Full physical arrays, read-only/configuration/guards and all five numerical state words were exact. The only added MOD token is U's conservative ARRAY_OUTER_DEPENDENCY attribute; all other 368844 tokens remain exact. Raw public MOD equality remains false.

The sole O2 non-target raw-code difference is a fixed SHCU stack-argument bundle. Symbolic replay proves six register and fifteen stack arguments plus restored stack pointer equal; the remaining 1017 non-NOP instruction/branch graph matches. O0 non-target raw code is equal. Actual numerical relocation references and mutable sections match. Diagnostic source filenames and line positions differ; the exact source insertion maps each affected non-target diagnostic to the identical source line. No diagnostic-byte or unwind equivalence is claimed.

A fixed 8192-call synthetic complete-caller comparison includes every 311712-byte restore, mask query, existing helper, scalar tail and full callee inside integer wall/thread-CPU clocks. One opposite-order pair per host measured 52.2084% and 36.4747% lower wall time, with similar thread-CPU reductions. All four same-count physical/state records matched. This does not establish production geometry, isolated-loop, repeatability or whole-forecast gains.

The same experimental image passed its own unchanged 545-step/four-full-product three-hour scientific checker with all models and reader normally closed before source/default delivery. Own nine-hour/noon/profile/restart/full144 and clean full-source rebuild remain false. Post-test source correspondence only; raw producer commit is unknown.

Opt out with WRF_ADD_A2C_U_ORDERED4=0, regenerate PP, rebuild/rearchive the module and relink; the V helper remains owned by V. Whole-image rollback is the previous V image69fb5625/archive59d661c2. Original pre-compile wrapper failures remain preserved.
