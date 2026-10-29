# Lower band12 fraction reuse

Image `7f268b11` and archive `e20d77b3` passed the original nine-hour science check: 1,625 steps and ten full outputs, with normal model and reader closures.

| Metric | Retained original nine-hour N1 | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 34.157236 | 29.156626 | 14.6400% |
| Main-step elapsed minutes | 30.845967 | 27.555877 | 10.6662% |
| Aggregate CPU core-hours | 278.157466 | 244.596439 | 12.0655% |

This image is qualified only for its own unprofiled nine-hour run on the same 512-rank configuration: 1,625 steps and ten full outputs passed the unchanged original checker, with all four models and reader normally closed. Own three-hour, noon, profile, restart, full 144-hour and clean full-source rebuild scopes remain false. Direct parent 4d25 has an exact three-hour result that remains historical; no horizon transfers. Only module_ra_rrtmg_lw.o changed; 592 archive members, RSL, provider and all 18 direct inputs remain unchanged. One lower band12 fraction reuses its original integer conversion under binary32/int32 admission with literal fallback. The same primitive previously passed 1,824 exact state comparisons and measured 50–54% lower primitive time. Current 16 genuine-table TAUMOL calls passed full output/read-only/guard/all-five checks. Complete caller wall estimates were 1.46% lower on one host and 0.67% higher on the other; no consistent caller or forecast gain is established. Retention follows owner policy. Nine-hour timing is one UNPAIRED descriptive observation against ONLY retained original nine-hour N1; no median3, pooling, paired, isolated or repeatable forecast claim. Source correspondence follows testing; raw producer commit remains NULL.

Only one lower band12 MOD-by-one site changed, plus its target Makefile opt-out. The preceding original integer conversion and all unsupported precision/configuration/domain fallbacks remain.

Rollback: Reselect retained4d258a49/adacab0c. For source rollback set WRF_LW_TAUMOL_BAND12_FRACTION_REUSE=0, rebuild only module_ra_rrtmg_lw.o and relink; preserve every other component.
