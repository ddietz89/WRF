Both knobs default to 1 only within the existing GNU 13.3.0, SmallStep SIMD=1, Zen2=1, REAL=4/INTEGER=4, empty OpenMP/type-promotion scope. Source guards additionally require DM_PARALLEL and exclude _OPENMP. No compiler/ISA/FP flags were added. Generic, unsupported, and threaded routes retain the original scalar loops.

- `WRF_SMALL_STEP_V_NH_CORRECTION_SIMD=0` restores the pressure-correction loop independently.
- `WRF_SMALL_STEP_V_FINAL_UPDATE_SIMD=0` restores the final V update independently.
- Setting both to 0 restores the original loops from selected971c.

After changing either knob, rebuild `dyn_em/module_small_step_em.o`, rearchive `main/libwrflib.a`, and relink the executable. Reusing an old executable does not apply an opt-out. Public MOD/interface is unchanged; no extra consumer ABI rebuild is required for these directives. Preserve the independent receive-helper and outlined-fallback settings when changing only UV behavior; the combined RSL recipe separately owns their rollback and helper archive membership.

For immediate operational rollback, select the retained qualified971c executable/archive and its original runtime binding. Candidate source/archive evidence does not qualify an interrupted application or transfer the parent's 3h/9h/profile horizons.
