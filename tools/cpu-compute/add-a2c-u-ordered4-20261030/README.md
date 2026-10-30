# Ordered ADD_A2C_U prefix

Reuse the existing ordered V SSE helper for four U columns with the read-only current and I-minus-one streams. Preserve U's i_end=ite, kts:min(kte,kde-1), scalar tail and trap-enabled fallback. Enable only under the tested GNU13.3 pure-MPI strict-O2 REAL4/INTEGER4 x86_64 guard with the existing V helper owner. No helper source or arithmetic changes.

Original-MOD comparisons passed 128 masked observations plus 18 finite unmasked observations at each O2 and O0. Full physical arrays, read-only/configuration/guards and all five numerical state words were exact. The only added MOD token is U's conservative ARRAY_OUTER_DEPENDENCY attribute; all other 368844 tokens remain exact. Raw public MOD equality remains false.

The sole O2 non-target raw-code difference is a fixed SHCU stack-argument bundle. Symbolic replay proves six register and fifteen stack arguments plus restored stack pointer equal; the remaining 1017 non-NOP instruction/branch graph matches. O0 non-target raw code is equal. Actual numerical relocation references and mutable sections match. Diagnostic source filenames and line positions differ; the exact source insertion maps each affected non-target diagnostic to the identical source line. No diagnostic-byte or unwind equivalence is claimed.

A fixed 8192-call synthetic complete-caller comparison includes every 311712-byte restore, mask query, existing helper, scalar tail and full callee inside integer wall/thread-CPU clocks. One opposite-order pair per host measured 52.2084% and 36.4747% lower wall time, with similar thread-CPU reductions. All four same-count physical/state records matched. This does not establish production geometry, isolated-loop, repeatability or whole-forecast gains.

The same experimental image passed its own unchanged 545-step/four-full-product three-hour scientific checker with all models and reader normally closed before source/default delivery. Own nine-hour/noon/profile/restart/full144 and clean full-source rebuild remain false. Post-test source correspondence only; raw producer commit is unknown.

Opt out with WRF_ADD_A2C_U_ORDERED4=0, regenerate PP, rebuild/rearchive the module and relink; the V helper remains owned by V. Whole-image rollback is the previous V image69fb5625/archive59d661c2. Original pre-compile wrapper failures remain preserved.

| Metric | Original3h median3 | Ordered U interpolation child | Descriptive reduction |
|---|---:|---:|---:|
| Whole wall (min) | 13.333735 | 10.549171 | 20.8836% |
| Main-step elapsed (min) | 9.940841 | 8.827869 | 11.1960% |
| Aggregate CPU (core-hours) | 99.813152 | 85.012374 | 14.8285% |

Single unpaired candidate observation against three distinct original controls; raw A2 remains the exact-science reference.

## Independent nine-hour qualification

Same image:1,625 ordered steps/ten full outputs passed original scientific checks; all models and reader normally closed.

| Nine-hour metric | Original N1 (n=1) | Same U image | Descriptive reduction |
|---|---:|---:|---:|
| Whole model/MPI wall (min) | 34.157236 | 29.309427 | 14.1926% |
| Main-step elapsed (min) | 30.845967 | 27.645504 | 10.3756% |
| Aggregate CPU (core-hours) | 278.157466 | 245.443438 | 11.7610% |

Selected U image owns independent unprofiled SAME512 three-hour545/fourFULL and nine-hour1625/tenFULL exact science, each with allfour models and original reader normally closed. Ninehour06:00–15:00 qualifies continuous daylight coverage only; own instrumented/noon1h/profile/restart/full144/clean full-source rebuild remain false. Same ELF/archive/providers and source3c3925fd; no relink or source/default change for9h. Raw producer commit NULL. Threehour fixed-originalmedian3 and ninehour sole originalN1 are separate UNPAIRED descriptive comparisons; no pooling, newmatched/isolated/additive/repeatability gain or memory-capacity claim. Literal historical3h validators run in their exact isolated1200s context; current9h retains3600s caps and originalten-output checker.
