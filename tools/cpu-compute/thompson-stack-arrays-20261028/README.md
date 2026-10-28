# Thompson automatic arrays on the stack

The qualified GNU 13.3 strict-O2 build now enables `-fstack-arrays` for the Thompson module. Its preprocessed Fortran and arithmetic flags are unchanged. The main routine has zero allocation/free sites, down from 71. Other compilers, O0, other modules and unsupported build configurations retain their existing recipes.

The complete synthetic 20,000-call comparison was **5.09% / 4.24% shorter in wall time** and used **5.17% / 4.86% less thread CPU** on hpc01/hpc04. Each arm passed exact checks, its own checked cache clear and normal closure. These are caller gains, not whole-forecast gains.

The original 11-case caller and four radar/reflectivity cases passed across four rounding modes. Genuine 32-rank regeneration produced all five table records byte-exact, with every rank's complete caller output and five protected state words exact. Cold-initialization processor state and O0 remain unqualified. Moving storage from heap to stack establishes no memory-capacity saving.

The cached application image `9010be04` passed its own unprofiled noon check: two complete outputs and 185 ordered steps matched the unchanged original checker. It took 268.368 seconds wall, 174.037 seconds main-step elapsed and 120785.246 aggregate core-seconds. Against the predeclared median of two eligible current-parent one-hour runs, wall/CPU were 1.45% / 0.99% higher and main-step elapsed 1.47% lower. Wall time falls within the observed parent range; this unpaired observation establishes neither an isolated forecast gain nor a reproducible regression. The significant exact caller gains support inclusion under the standing policy. [Own application evidence](NOON_APPLICATION_QUALIFICATION.json).

The periodic combined three-hour qualification is running. Nine-hour, profile, restart, full-144-hour and clean full-source-build qualification do not transfer from the parent. The cached link replaced one of 591 archive members; the other 590 and all 18 direct inputs were unchanged.

Set `WRF_THOMPSON_STACK_ARRAYS=0`, rebuild the Thompson object, rearchive and relink to opt out. Retained image `00c6bcb3` is the whole-image rollback. The qualified runtime uses unlimited process stack; other stack limits have not been qualified. [Native measurements, scope and rollback](EXPERIMENT.json).
