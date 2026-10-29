# Final five sampled TAUMOL fractions

Image `31a40b14` and archive `7a947696` passed the original three-hour science check: 545 steps and four full outputs, with normal model and reader closures.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.515430 | 21.1367% |
| Main-step elapsed minutes | 9.940841 | 8.861602 | 10.8566% |
| Aggregate CPU core-hours | 99.813152 | 85.187000 | 14.6535% |

This image is qualified only for its own unprofiled three-hour run on the same 512-rank configuration: 545 steps and four full outputs passed the unchanged original checker, with all four models and reader normally closed. Own nine-hour, noon, profile, restart, full 144-hour and clean full-source rebuild scopes remain false. Direct parent 7f26 owns its exact nine-hour science, which remains historical. Only module_ra_rrtmg_lw.o changed; 592 archive members, RSL, provider and all 18 direct inputs remain unchanged. Exactly five sampled lower fractions across bands 5, 13, 15 and 16 reuse their original integer conversions under binary32/int32 admission with literal fallback. Sixteen genuine-table complete TAUMOL calls passed full outputs, read-only inputs, guards and all five processor state words, with 44 positive-normal admission witnesses at each new site in both roles. One fixed 20,000-call comparison per host measured 1.24% and 2.82% lower complete caller wall time and 1.17%/2.74% lower process CPU, including full output restores and all callee work. These bounded observations establish no forecast gain or repeatability. Earlier 50–54% primitive gain is separate formula evidence. Three-hour application timing is one unpaired descriptive observation versus the fixed median of three original controls; raw A2 stays separate. Source correspondence is post-test; raw producer commit remains NULL.

Only band 5 fmo3, band 13 fs/fmco2, band 15 fs and band 16 fs1 changed, plus one target Makefile opt-out. Original integer conversions, unsupported precision/configuration/input fallbacks and all other sites remain unchanged.

Rollback: Reselect retained 7f268b11/e20d77b3. For source rollback set WRF_LW_TAUMOL_FIVE_SAMPLED_FRACTIONS_REUSE=0, rebuild only module_ra_rrtmg_lw.o and relink; retain every other component.
