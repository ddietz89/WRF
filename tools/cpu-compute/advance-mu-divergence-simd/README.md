# advance_mu_t divergence SIMD

The default source adds one OpenMP SIMD directive to the independent horizontal
divergence loop in `dyn_em/module_small_step_em.F`. The outer vertical loop and
its accumulation order are unchanged. There are no new alignment, reciprocal,
reassociation or fast-math assumptions.

`QUALIFICATION.json` binds the source, native caller checks, canonical executable
and original-versus-combined three-hour full-grid comparison. The captured caller
was about 32.13% faster in opposite-order pairs. The combined configuration took
833.4612 → 702.7395 seconds versus corrected original, with four exact products
and 545 identical ordered timesteps. The 15.6842% combined gain does not isolate
this directive's forecast contribution. File-server state was uncontrolled;
compute-node caches were cleared before each arm.

Qualification covers the existing GNU 13.3 strict configuration and its SmallStep
Zen 2/no-FMA/SIMD flags, 512-rank placement and runtime libraries. Other compiler
stacks and a nine-hour forecast with this candidate are not qualified here.

Rollback: remove the one `!$OMP SIMD` immediately before the `dvdxi`/`DMDT` inner
I loop in `advance_mu_t` and rebuild, or select the prior `940e` executable with
the same qualified runtime libraries. Production and master are unchanged.
