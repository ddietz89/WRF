# Pressure damping SIMD

Vectorize only the separate nonzero-step damping suffix in `calc_p_rho`, preserving the original subtraction, multiplication and addition order and private `ptmp`. The NH producer is unchanged. The GNU13.3 pure-MPI default REAL4/INTEGER4 guard and existing mask helper are required. The SIMD route requires masked traps and a nonempty I/J/K domain; other states retain the literal scalar suffix.

Native parent/candidate comparisons passed 440 observations at each of O2 and O0, including finite and focused IEEE cases, all four rounding modes, full physical outputs, read-only inputs, halos, guards and all five hard numerical state words. Raw public MOD equality is false: the separately checked original-MOD interface admits exactly one conservative ARRAY_OUTER_DEPENDENCY attribute. O2 non-target code and relocation records are exact. O0 pool/relocation bytes differ, with fixed referenced-constant/string equivalence only. The O2 containing worker later failed an O0 metadata gate; its successful native subprocesses are retained without relabeling that worker.

Complete synthetic pressure caller measurements include four mutable-field byte restores, the entire callee and the query/dispatch inside fixed 1024-call integer wall/thread-CPU clocks. One opposite-order pair per host gave 37.4053% and 26.3644% lower wall time on hpc01/hpc03, with matching thread CPU reductions. This does not establish isolated damping, repeatability or forecast gains.

The same experimental image passed its own unchanged three-hour checker: 545 ordered steps and four full products, with all model and reader units normally closed. Other horizons, restart, profiling and clean full-source rebuild remain unqualified. Source delivery is post-test correspondence to a cached tested object; raw producer commit is unknown.

Opt out with `WRF_CALC_P_RHO_DAMPING_SIMD=0`, regenerate SmallStep PP, rebuild/rearchive/relink. Whole-image rollback is the previous curvature executable `083398d7`, archive `5ce20b60`.
