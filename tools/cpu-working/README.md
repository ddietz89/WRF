# Current working selection: longwave whole-draw seed carry

Selected **0ec34714 / archive a30c8df7**, source correspondence **2791f903**, retains all D54 and earlier improvements. Its own unprofiled same256 noon test passed both full products and all 185 ordered timesteps. Complete synthetic MCICA caller wall time fell 18.27%/17.58% on the two nodes; no isolated forecast gain is claimed. The fresh corrected-original/combined three-hour pair is pending. Longer-horizon, profile, restart and other-rank qualification remain image-specific.

[Current selection](selection.json), [binding](CURRENT_SOURCE_BUILD_BINDING.json), [qualification, replay recipe and rollback](../cpu-compute/lw-mcica-whole-draw-seed-carry-20261025/README.md).

The following sections preserve historical image-specific evidence.

# Historical working selection: d54 RK dry U stage split

Selected **d54cb2b7 / archivedeb86e8b**, source correspondence **8302003c**, retains every 51f improvement. Strict native/caller checks and its own INSTRUMENTED same256 noon two-product/185-step application passed. Whole-caller timing was neutral on 01 and 4.59% lower on02; no forecast gain is claimed. Unprofiled/three-hour/nine-hour/four-host/384/restart/full144 scope remains pending. Profile decoding is separate.

[Current selection](selection.json), [binding](CURRENT_SOURCE_BUILD_BINDING.json), [qualification and rollback](../cpu-compute/rk-dry-u-stage-split-simd-20261025/README.md).

The following sections retain image-specific historical results.

# Latest three-hour qualification: 51f combined configuration

All four full products and545 ordered steps matched exactly. Wall was18.006min versus retained original21.400min (15.86% descriptive reduction); main-step elapsed7.83% lower, totalCPU11.77% lower. One later candidate, no new matched pair or isolated mask-gain claim. [Qualification](../cpu-compute/sw-mcica-mask-consumer-20261025/THREE_HOUR_APPLICATION_QUALIFICATION.json).

# Historical working selection: 51f shortwave MCICA mask fusion

Selected **51f1449e / archive63d6a533**, source correspondence **af4cabc0**, retains all B4BC improvements and removes the temporary SW cloud-mask pass. Own noon science passed two complete products and 185 ordered steps on hpc01–03 at256 ranks. Its three-hour check also passed all four full products and 545 steps; parent three-hour results below remain specific to B4BC. No isolated forecast speedup is claimed.

[Current selection](selection.json), [binding](CURRENT_SOURCE_BUILD_BINDING.json), [evidence and rollback](../cpu-compute/sw-mcica-mask-consumer-20261025/README.md).

The following material preserves prior image-specific results.

# Historical working selection: B4BC, October25

The qualified working configuration now includes both clear-sky radiation changes, retaining all previous BACF improvements. Own acceptance is direct12–13 noon,256 ranks on hpc01–03, two full products and 185 ordered steps. Other horizons/configurations are pending; historical BACF timings do not qualify this new image.

[Current selection](selection.json), [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json), [evidence and rollback](../cpu-compute/clear-sky-radiation-batch-20261025/README.md). Source correspondence commit `dcb885b9`; whole tested PP replay only.

The material below is retained campaign history.

# Historical working selection: BACF, exact three-hour science

Selected **bacf12b8** / WRF archive **1d2e1851** / RSL archive **6eb125cc**, source **526e562c**, retains all previous improvements and adds the two V-loop SIMD paths, receive width-5/6 helper and exact original outlined fallback. The unchanged checker passed all four full-grid products and 545 ordered steps in the fresh original-first pair; every model and reader closed normally.

| Three-hour metric | Fresh corrected original 546b | Combined BACF | Reduction |
|---|---:|---:|---:|
| Model/MPI wall (min) | 13.711 | 10.734 | 21.71% |
| Main-step elapsed (min) | 9.950 | 9.011 | 9.43% |
| Aggregate CPU (core-hours) | 102.597 | 86.703 | 15.49% |

One fresh fixed-order pair, one observation per image, with client caches cleared before each arm and symmetric external voltage/temperature/fan monitoring. Main elapsed includes communication and output backpressure. Component caller gains are separate and are not added to these percentages. Own short, one-hour, nine-hour, noon/profile, restart and full-144-hour qualification remain false. Raw producer commit remains unknown; source 526e records post-test correspondence.

The planned reverse-order pair is incomplete: B2 closed, but hpc04 became unreachable during A2 before integration. The failed control is excluded. No completed BACF counterbalanced or repeatability claim is made. The owner excluded hpc04 from future jobs and queries; the next three-host layout needs separate memory and scientific admission.

[Fresh comparison](../cpu-compute/rsl-width56-receive-original-fallback-outline/FRESH_FIXED_ORDER_THREE_HOUR_COMPARISON.json), [scientific qualification, rebuild and rollback](../cpu-compute/rsl-width56-receive-original-fallback-outline/README.md). `FULL_GRID_SUMMARY.json` and `LATEST_APPLICATION_RESULT.json` carry the current fresh-pair observation. `THREE_HOUR_RESULT.json` retains the prior 971c comparison; the previous BACF unpaired observation and historical snapshots below remain identified by their original images.

The PBL/QV traversal-fusion experiment passed native and caller correctness but showed no consistent significant caller gain. It remains [unpromoted with its evidence](../cpu-compute/part2-pbl-qv-traversal-fusion-unpromoted/README.md).

# Historical 971c selection: own fresh three-hour science

Selected executable **971cba3f**, unchanged WRF archive **6c705230**, new RSL archive **29e42be3**, and post-test source **a46f6f48** retain every previous improvement and add restricted width-5/6 packing. All four products, 545 ordered steps, full 512-rank runtime acceptance and all model/reader closures passed the unchanged checker. [Build, qualification and rollback](../cpu-compute/rsl-width56-private-vector-copy/README.md).

| Three-hour metric | Fresh corrected-original 546b | Combined 971c | Reduction |
| --- | ---: | ---: | ---: |
| Model/MPI wall (min) | 13.679 | 10.733 | **21.54%** |
| Main-step elapsed (min) | 9.966 | 9.013 | **9.56%** |
| Aggregate CPU (core-hours) | 102.272 | 86.525 | **15.40%** |

One fresh corrected-original A then combined B pair; client caches cleared before each arm, no profilers. Main elapsed includes communication/waiting; CPU is summed node-core consumption. These are whole-configuration observations, not repeatability or individual packing gains. Own short/one-hour/nine-hour/noon/profile/restart/full-144-hour qualifications remain false. Raw producer commit is unknown. Set `WRF_RSL_WIDE_PRIVATE_VECTOR_COPY=0` and rebuild/recreate RSL and relink to opt out, or restore qualified W50d6.

The following snapshots remain historical to their named images.

# Historical W50d6 selection: own three-hour science

Selected executable **50d67c6a**, archive **6c705230**, source correspondence **952c9dac**, retains all previously selected improvements and adds the W ELSE RHS consumer SIMD path. Its own full 512 three-hour check passed all four products and 545 ordered steps; all models and the unchanged reader closed normally. The qualification is [recorded with build and rollback evidence](../cpu-compute/w-else-rhs-consumer-simd/README.md).

| Metric | Retained original 546b control | Current 50d6 | Descriptive reduction |
| --- | ---: | ---: | ---: |
| Model/MPI wall | 13.695 min | 10.744 min | **21.55%** |
| Integration-loop elapsed | 9.948 min | 9.028 min | **9.25%** |
| Aggregate CPU | 102.400 core-hours | 86.591 core-hours | **15.44%** |

This is a later candidate against a retained control, not a fresh matched pair or isolated W-loop forecast gain. Own short, one-hour, nine-hour, noon/profile, restart and full 144-hour qualifications remain false. Raw producer commit is unknown; source 952c9dac records post-test correspondence. Source defaults can be rolled back with `WRF_W_WDWN_ELSE_RHS_SIMD=0` and a full regenerate/rebuild/rearchive/relink, or by restoring qualified 5aae.

The following publication snapshots are historical to their named images; they do not describe the current selection.

## Historical 90f5: own short and fresh matched three-hour science

Current **90f54730 / archive0f4ccda1**, source correspondence **3c1fdd33**, passed the unchanged original full512 three-hour checker twice: four products and545 ordered steps per candidate arm, all16 model scopes and both readers normal closed. Fresh order was **A1–B1–B2–A2**, with checked caches before every arm. The immutable short qualification remains separate.

|Metric|Original546b mean (range)|Current90f5 mean (range)|Reduction|
|---|---:|---:|---:|
|Model/MPI wall|13.317 (13.315–13.319) min|10.554 (10.423–10.684) min|20.75%|
|Main-step elapsed|9.904 (9.900–9.908) min|9.013 (9.004–9.021) min|9.00%|
|Aggregate node CPU|99.608 (99.573–99.642) core-hours|85.339 (84.430–86.249) core-hours|14.32%|

These are two observations per image, not a confidence interval or broad repeatability claim. They measure the complete combined image; caller/component percentages are not additive and do not isolate a forecast contribution. Main elapsed includes communication/backpressure; aggregate CPU is summed whole-job consumption. Own9h/noon/profile/restart/full144 remain false; parent b21c9h and historical19ad matched results stay attached to their exact images. Raw producer remains NULL; no new whole-image source build is claimed.

---

# Earlier publication snapshots

# Current first-Y zero-seed child — own short science only

Selected 90f5473062922c82d26aaeb68fc95c512a3e0e328d5dab1a365dc5e14ed7b64b / archive 0f4ccda13fbe197ca6ce4c175ee1b1fa3ad12e756765c8d05afcacba2c24dce4. Original35steps/two-products512 science and model/reader closures passed. No current3h/9h/noon/profile/restart/full144 qualification or forecast gain transfers. Component evidence: `../cpu-compute/advect-first-y-zero-seed/APPLICATION_QUALIFICATION.json`.

The following retained material is historical to its named image, including parentb21c own9h and recovered3h with coordinator postprocessor failure preserved.

# Current working imageb21c; latest completed three-hour result89bd

Current executable **b21c9c9f**, archive **0e4d54bf**, retains all previous selected improvements, including scalar-family WW reuse, and adds reuse of already-zero moisture scratch tendencies within each eligible RK stage. Its own two-product/35-step full512 scientific check passed; all four models and reader closed normally. Source correspondence is post-test commit **4d55413f**; the raw producer commit remains unknown. Its own three-hour test is being prepared; longer/profile/restart/full144 scopes remain unqualified. [Evidence, build guard and rollback](../cpu-compute/moisture-hz-zero-reuse/README.md).

The following is the latest completed three-hour result, for **parent89bdbe3d**. Its four products and 545 steps matched exactly; that qualification does not transfer to026c or b21c.

|Forecast / image|Metric|Retained corrected-original546b A1|89bd|Reduction from control|
|---|---|---:|---:|---:|
|3h / 89bd|Model/MPI wall|13.313 min|10.775 min|19.07%|
|3h / 89bd|Main-step elapsed|9.909 min|9.121 min|7.95%|
|3h / 89bd|Aggregate node CPU|99.589 core-hours|87.048 core-hours|12.59%|

This is an **unpaired descriptive** comparison with retained original546b A1, not a fresh matched pair or isolated component gain. Main-step elapsed includes communication, waiting and output backpressure; it is not integration CPU. Aggregate CPU is four-node cgroup core-time. Client-cache checks were retained; server load/cache are uncontrolled. The failed reconciler and external reviewed closure repair are preserved without a model rerun or scientific-checker change.

## Historical parent962b long-horizon observations

The following retained rows belong to **parent962bdf29 / archivebd1ae1d4**, not89bd,026c or b21c. In particular, the ten-product/1,625-step nine-hour qualification does not transfer to these children.

|Forecast|Metric|Retained corrected-original546b control|Combined962b|Reduction from control|
|---|---|---:|---:|---:|
|3h|Model/MPI wall|13.313 min|10.691 min|19.70%|
|3h|Main-step elapsed|9.909 min|9.276 min|6.39%|
|3h|Aggregate node CPU|99.589 core-hours|86.617 core-hours|13.03%|
|9h|Model/MPI wall|34.489 min|30.305 min|12.13%|
|9h|Main-step elapsed|30.859 min|28.932 min|6.24%|
|9h|Aggregate node CPU|280.351 core-hours|254.284 core-hours|9.30%|

These parent observations are also unpaired and do not establish an incremental or repeatability claim.

The separate counterbalanced **19ad** three-hour comparison used A–B–B–A, two observations per image. Mean wall was 13.323→10.990 minutes (**17.51% lower**); main-step elapsed 9.919→9.291 minutes (**6.34% lower**); CPU 99.644→88.823 core-hours (**10.86% lower**). That matched result applies to19ad, not to962b,89bd,026c or b21c.

[Exact values, image identities and evidence](FULL_GRID_SUMMARY.json). [Current selection](selection.json) and [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json) carry support and qualification scope. The currentb21c short qualification and historical89bd three-hour qualification remain separate. Production/master are unchanged; AWS remains suspended.

All selection narratives below are historical snapshots and do not override these current artifact and qualification bindings.

---

# Historical79be selection: U nonhydrostatic pressure-correction SIMD

**79bebebb / archive1ade2c8f / post-test source1f03a738** retains all previous improvements and adds the exact-qualified U pressure-correction SIMD directive. The current image owns short35 and full3h exact science: all four products and545 ordered steps matched. The fresh original-first pair was798.430250→638.924674s wall (**19.9774% lower**),594.341810→554.727540s main-step elapsed (**6.6652% lower**) and358152.909794→310564.250629 aggregate CPU-s (**13.2872% lower**). This is one fixed-order full-package comparison; ownnoon/9h/restart/profile remain pending.

Complete captured callers were10.36% and12.09% shorter in opposite-order pairs. These percentages are not forecast gains and are not added to earlier gains. [Current evidence, build guard and rollback](../cpu-compute/uv-u-nh-correction-simd/README.md). Use `WRF_SMALL_STEP_U_NH_CORRECTION_SIMD=0` and rebuild to omit the new directive. Production/master remain unchanged; AWS remains suspended.

## Historical7087 selection: physics tendency SIMD

**7087c69d / archive a71d7b28 / post-test source634f293d** retains all previous selected improvements and adds one inner-I `add_a2a` SIMD directive with a GNU module-local flag. The selected bindings all identify this artifact set.

| Fresh three-hour pair, October22 | Corrected original546b | Combined7087 | Reduction |
|---|---:|---:|---:|
| Model/MPI wall |821.985931s|659.368571s|19.7835%|
| Main-step elapsed |598.154780s|557.023960s|6.8763%|
| Aggregate node CPU |368750.239428 CPU-s|319850.766687 CPU-s|13.2609%|

New run IDs: `production512-current-add-a2a3h-{control,candidate}-r1`; raw result `de43f90a`. All four complete products and545 ordered steps passed exactly, including metadata/layout,512 ranks,two tiles,all four writer groups and32 field markers. All models and reader closed. Checked client-cache clears preceded each arm. One original-first pair measures the total package, not this directive alone; server cache/load are uncontrolled and repeatability is unestablished. Main elapsed includes communication/output backpressure.

[Evidence, support, recipe and atomic rollback](../cpu-compute/add-a2a-simd/README.md). Own3h is true; ownnoon/9h/restart are false until separate qualification. The eight changed calling routines are disclosed rather than claimed byte-exact. Source634f293d is post-test tracking; raw producer remains null. Production/master are unchanged; AWS is suspended.

All following selection descriptions are historical. The generic three-hour result files now identify the current79be qualification; explicitly named previous files preserve older results. `selection.json` identifies current support and acceptance.

---

# Historical a437 selection: V-advection SIMD and shortwave initialization

**a437888c / archive81f6a950 / post-test sourced5d09385** retains the previous configuration and adds the qualified V Y5 producer directive and seven shortwave initialization guards. The current source/build/application records in this directory all identify this same artifact set.

| Fresh three-hour pair, October22 | Corrected original546b | Combineda437 | Reduction |
|---|---:|---:|---:|
| Model/MPI wall |831.150893s|638.376558s|23.1937%|
| Main-step elapsed |610.539530s|554.898530s|9.1134%|
| Aggregate node CPU |374060.951199 CPU-s|310676.786383 CPU-s|16.9449%|

All four complete products, metadata/layout and545 ordered steps passed the unchanged checker, including512 ranks, both tiles, all four active writer roots and32 acquisition markers. All eight model scopes and the reader closed normally. Separate client-cache clears preceded both arms. This is one unprofiled original-first pair; server load/cache remain uncontrolled, main elapsed includes communication/output backpressure, and no isolated/additive or repeatability claim follows.

This is the new `production512-current-vy-sw-batch3h-{control,candidate}-r2` comparison, raw result `ec263cf2`. It is distinct from the retained4adb comparison. [Current evidence, recipe and rollback](../cpu-compute/vy-sw-qualified-batch/README.md). Own three-hour qualification is true; separate short/one-hour, noon/daytime, nine-hour and restart scopes do not transfer. Source d5d09385 is post-test tracking; raw producer commits remain null. Production/master are unchanged; AWS is suspended.

The generic `THREE_HOUR_RESULT.json` and `THREE_HOUR_FINAL_QUALIFICATION.json` here retain older pinned evidence. Use `selection.json` and its current qualification link above for the latest accepted result. All following selection descriptions are historical.

---

# Historical769 selection: Coriolis U cache and private PHY AVX2 rows

**769195b8 / archive a99fc18e / post-test source014ab2e0** retain all previous improvements and add the exact-qualified Coriolis U cache and wider private height helper. The selected GNU13.3 recipe enables the row API and AVX2 helper; generic PHY source remains macro-off. Global strict arithmetic flags remain unchanged.

| Fresh three-hour full-grid pair | Corrected original | Selected combined | Reduction |
|---|---:|---:|---:|
| Model/MPI wall |964.849634s|659.136806s|31.6850%|
| Main-step elapsed |742.869680s|555.449990s|25.2291%|
| Aggregate node CPU |442089.053462CPU-s|319400.643832CPU-s|27.7520%|

All four complete products and545 ordered steps passed the unchanged exact checker, including metadata/layout,512 ranks,two tiles,all four active writer roots and32 markers. All model and reader jobs closed normally. Both arms had checked client-cache clears and used the same FABA placement, single InfiniBand rail and resource limits. This is one original-first unprofiled pair; main elapsed includes communication/output backpressure, and aggregate CPU includes MPI spin. File-server load/cache remain uncontrolled. No isolated component contribution, additive gain, repeatability or concurrent-throughput claim follows.

Own three-hour science is qualified; this image has no separate short/noon/nine-hour qualification. Parent results below retain their named artifacts. [Evidence, recipe and rollback](../cpu-compute/coriolis-u-phy-fixed8-batch/README.md) describe the support scope. Raw producer commits remainNULL;014ab2e0 is post-test tracking. Production/master are unchanged; AWS is suspended.

All following selection descriptions are historical.

---

# Historical bc54 selection: NH-Y pressure-gradient consumer SIMD

**bc543d56 / archive 9a909457 / NH-Y introduction 9e259378** retains all previous improvements and adds one NH-Y inner-I directive. Complete synthetic HPG caller wall fell **36.85% and 35.72%** in opposite-order host pairs with exact raw output and state; process CPU was unavailable. Native 100-case bounds/O2 checks and the unchanged original full-grid short comparison passed exactly: two products, 35 ordered steps, 512 ranks, two tiles, and normal model/checker closures.

Own short science is qualified; own three-hour, noon and nine-hour science are not. Parent a61a's three-hour result and 1749's nine-hour result below retain their own artifacts. The short candidate observations are 140.797629 seconds whole wall, 39.903320 seconds main-step elapsed and 54631.865472 aggregate CPU-seconds; retained-original differences are unpaired context, with no Y-loop forecast-speedup claim. [Evidence, support and paired rollback](../cpu-compute/hpg-nhy-consumer-i-simd/README.md). The qualified GNU13.3 recipe enables the existing HPG macro; generic source remains portable. Production/master are unchanged; AWS is suspended.

The overall selected source now includes the separately [qualified advection source packaging repair](../cpu-compute/advection-canonical-source/README.md). It rebuilds the selected member exactly in all runtime sections and interface; the executable, scientific qualification and timings are unchanged.

---

# Historical a61a selection: isolated NH-X AVX2 helper

**a61a273b / archive 9dc6b5e5 / post-test source 5f184bcc** retains all prior improvements. The private helper reduced complete synthetic HPG caller wall by **9.28% and 7.67%** in opposite-order pairs; raw output and five state fields matched. The original full-grid short check passed both products and all 35 steps, with normal closures. Process CPU was unavailable in the caller test.

The qualified GNU13.3 EPYC recipe enables the helper; ordinary source keeps the portable Fortran path. Own short and three-hour science are qualified; noon-profile and nine-hour checks remain pending. The three-hour check passed four products and 545 ordered steps. Previous 1749 long-run results below retain their actual artifact scope. [Evidence, build recipe and paired rollback](../cpu-compute/hpg-nhx-isolated-avx2-consumer/README.md). Production/master are unchanged; AWS remains suspended.

The a61a build passed the unchanged original four-product/545-step three-hour check with all 512 ranks, two tiles, all four active writers and normal model/checker closures. Whole wall was 661.160262 versus 914.002706 seconds for the retained original (27.6632% lower); main-step elapsed was 559.247310 versus 692.229380 seconds (19.2107% lower); aggregate CPU was 319721.189654 versus 416098.178201 CPU-seconds (23.1621% lower). These are **unpaired observations from different epochs**, not a matched benchmark, isolated helper gain or repeatability result. Own short and three-hour science are qualified; noon and nine-hour science remain unqualified. Source 5f184bcc is post-test tracking; frozen producer identities remain null. The inherited1749 text in the raw result is retained and explicitly distinguished from the actual a61a artifact.


---

# Historical 1749 working selection: NH-X consumer SIMD

**1749f701 / archivef18c135a / post-test sourcea531104f** retains every f703 improvement. One NH-X inner-I directive delivered20.94%/20.87% lower complete synthetic HPG caller wall time; native100 and original full512 short2product/35step exact checks passed. Extra112B frame/spills are documented; process CPU unavailable. The selected build passed its own short, three-hour and nine-hour scientific checks; its own noon check remains unqualified. [Evidence and rollback](../cpu-compute/hpg-nhx-consumer-simd/README.md).

The latest 1749 three-hour run passed all four products and 545 timesteps: 668.899757 seconds wall, 564.772720 seconds main-step elapsed and 324253.307580 aggregate CPU-seconds. The retained original measured 914.002706 / 692.229380 / 416098.178201, respectively. This comparison is **unpaired**; it does not isolate the consumer change. Earlier three-hour and nine-hour timing results below are historical for their named artifacts. No current forecast-gain claim is transferred. Restore all three BEFORE_HPG_NHX_CONSUMER snapshots and revert source-onlya531104f for rollback. Production/master unchanged; AWS suspended.


The unchanged scientific checker passed all **10 products and 1,625 ordered steps** for the selected 1749 build against a fresh corrected-original 546b control. All eight model scopes and the reader closed normally. Both arms used 512 ranks, two tiles, the same placement and single InfiniBand rail, and checked client-cache clearing before launch. The original ran first; neither arm was profiled.

| Metric | Original 546b | Selected 1749 | Reduction |
| --- | ---: | ---: | ---: |
| Whole model/MPI wall, seconds | 2434.052311 | 1834.780146 | 24.6203% |
| Main-step elapsed sum, seconds | 2217.654070 | 1735.353780 | 21.7482% |
| Aggregate node CPU-seconds | 1196242.042695 | 922523.653012 | 22.8815% |

This is one control-first pair. File-server load and caches were uncontrolled. Original hpc04 reached its 104 GiB memory limit with 2,468 max events and no OOM; the candidate had zero memory events. Both arms encountered CPU-quota throttling. Main-step elapsed includes communication and output backpressure; aggregate CPU includes MPI spin. These totals do not isolate a component, establish repeatability or measure concurrent throughput. The single-pair wall ratio is 1.3266×; the 1.5× and 2× targets remain unmet.

Executable 1749, archive f18, post-test source a531 and the selected libraries/defaults are unchanged. Frozen producer source identities remain NULL. This build now owns separate short, three-hour and nine-hour scientific qualification; its separate noon-profile check remains unqualified. The experimental isolated AVX2 helper is **not included** in this forecast. [Actual qualification](../cpu-compute/hpg-nhx-consumer-simd/NINE_HOUR_APPLICATION_QUALIFICATION.json) retains the evidence and limits.

Legacy `NINE_HOUR_FINAL_QUALIFICATION.json` and `NINE_HOUR_RESULT.json` in this directory retain an older artifact. The current selection points to the consumer evidence above; historical pinned files are preserved.

---

# Historical f703 configuration — October 21, 2026

Selected **f703115b / archivefe72cb2e / post-test sourcec3d2de5d** adds NH-X row-ratio caching to all3cdd improvements. Complete finite500-call HPG timings were1.34–3.04% shorter with exact raw/state results; process CPU unavailable. Original short2product/35step/full512/two-tile science and normal closures passed. OwnshortTRUE; own3h/noon/9hFALSE. [Evidence and rollback](../cpu-compute/hpg-nhx-row-cache/README.md) preserve scope.

Current short observations are137.963208s whole wall,38.623270s main elapsed and53408.251218 aggregateCPU-s; retained-original267.534171s/42.031970s/86843.488941CPU-s is unpaired, not a forecast gain. Main elapsed includes communication/backpressure and is not integration CPU. The prior3cdd nine-hour result below remains historical. Next is one fresh reverse-order3h pair. Production/master unchanged; AWS suspended.

---

# Historical3cdd working configuration — October 21, 2026

Selected **3cdd1c0f / archivebf53b5c5 / post-test sourcecbeb3b19** retains all previous improvements plus shortwave optical producer SIMD. Codec9371, output51a, root input06d/NCa32, two tiles, FABA placement and the qualified single InfiniBand rail remain selected. Production/master remain unchanged; AWS is suspended.

The fresh original-first nine-hour pair passed all10 products and1,625 ordered steps exactly. Whole MPI wall was **2375.176475→1840.543608s (22.5092% lower)**; main-step elapsed **2157.669640→1742.032690s (19.2632% lower)**; aggregate four-node CPU **1166063.791005→925475.897719CPU-s (20.6325% lower)**. Both arms had checked client-cache clearing, all models and reader closed normally, and no profile ran. Own9h and noon75m TRUE; separate ownshort/3h FALSE. [Actual qualification](../cpu-compute/spcvmc-optical-producer/NINE_HOUR_APPLICATION_QUALIFICATION.json) and [support/rollback](../cpu-compute/spcvmc-optical-producer/README.md) preserve scope.

This is one fixed-order pair. Original hpc04 hit104GiB with2,385 max events and no high/oom/oom-kill; the candidate had zero memory events. Server load/cache were uncontrolled. The latest original was14.82% slower than the previous retained original, while the optimized observations differ by0.44% across source epochs. No isolated/additive kernel gain, repeatability, concurrent throughput or1.5x/2x target achievement is claimed. Main-step elapsed includes communication/backpressure and is not integration CPU.

The following selection descriptions are historical and retain their actual source and qualification epochs.

---

# Historical f4b working configuration — October 21, 2026

The working configuration selects the **actual three-hour-tested f4b executable / a43 archive**, with all prior improvements, codec9371, output51a, root-only input06d/NCa32, HDF825, two tiles and the existing single InfiniBand rail. Production and master are unchanged.

The unchanged original checker passed four complete products and 545 ordered steps, all512 ranks, all four positive output writers, 32 markers and exact metadata/layout. All model and reader jobs closed normally. The actual candidate-only unprofiled run took **661.040449s whole model/MPI wall**, **558.885370s main-step elapsed** and **320470.901248 aggregate node CPU-s**. Against retained corrected-original2aef (819.278306s /597.239960s /367612.405251CPU-s), these are **19.31% /6.42% /12.82% lower**, respectively. This is **UNPAIRED**, without a fresh control or repeatability claim. Main-step elapsed includes communication/backpressure and is not integration CPU. File-server cache/load remain uncontrolled. No component gains are added or attributed from these totals. Own3h TRUE; separate ownshort and own9h FALSE. Single-run wall ratio1.239377x; concurrent throughput is unmeasured and the1.5x/2x goals are not met.

Calc_php adds one independent-I SIMD directive while retaining scalar expression order. Its complete synthetic caller (including per-call output restoration) measured55.95–59.63% lower wall; 96 finite/IEEE cases and genuine module checks passed. Boundary-copy adds one independent-I directive with private `bc_source`; 672 exact cases passed, and its repeated complete synthetic caller measured70.08–73.33% lower wall. Those are caller gains, not forecast gains. The boundary module requires its **module-local `-fopenmp-simd`** flag in the qualified GNU13.3 recipe; generic builds lacking that flag are not performance-qualified. Existing global arithmetic flags remain unchanged. AOCC/Intel remain experimental, without new qualification here.

[Application qualification](../cpu-compute/calc-php-bc-simd/APPLICATION_QUALIFICATION.json), [raw reference map](../cpu-compute/calc-php-bc-simd/APPLICATION_RAW_MAP.json), native/caller JSON records and [source-backed rebuild](../cpu-compute/calc-php-bc-simd/source-rebuild/README.md) retain evidence. The actual source-backed rebuild produced3db1 with exact allocated sections/relocations/non-file symbols for both members and preserved other582 members; **3db1 itself has no application qualification**. Frozen producer source identities remain null; [source identity](../cpu-compute/calc-php-bc-simd/POST_TEST_SOURCE_IDENTITY.json) records the later source-only commit separately.

Rollback restores the three paired `BEFORE_CALC_PHP_BC_SIMD` working records and reverses [the two directives](../cpu-compute/calc-php-bc-simd/SOURCE_ONLY.diff), selecting previous3582/15b2 with the same9371 codec/output/input. Selection metadata is not a launcher. Use fresh leases, existing resource/worker/input/rank guards and checked cache clears before each timing arm.

---

The following sections are historical records. Their uses of “selected” or “current” refer to their own recorded builds and do not override the selection above.

## Historical working selection (October 20, 2026, EDT)

Selected **FINISH8bfe/archive6f44/sourcea92fc86b** retains all prior improvements and adds one exact-qualified U reconstruction SIMD directive. Original two-product/35-step/full512/two-tile science passed; complete FINISH caller wall fell8.24–11.81% in the bounded opposite-order tests. OwnshortTRUE; own3h/9hFALSE. The previous E3 long-run records below do not apply to this child. Output51a/codece1d8/input06dNCa32/faba/single-IB remain unchanged. [Evidence and paired rollback](../cpu-compute/smallstep-finish-u-simd/README.md).

## Historical combined selection (2026-10-21)

The working fork now selects **e3da6907 / archive4f2a0cf0 / post-test source1ae0c6ee**. It retains all prior improvements and adds final-U velocity SIMD, Prep V coupling SIMD and split rain/cloud staging during Thompson initialization. The unchanged original checker passed all four complete products,545 ordered timesteps,512 ranks,two tiles,all four positive writer groups and all32 field markers. All model and reader jobs closed normally.

| Three-hour measure | Retained corrected original | Current combined | Reduction |
|---|---:|---:|---:|
| Whole model/MPI wall, including I/O and final drain |819.278306s|661.793683s|19.22%|
| Integration-step elapsed, including communication/backpressure |597.239960s|560.596320s|6.14%|
| Aggregate four-node cgroup CPU |367612.405251CPU-s|321402.587962CPU-s|12.57%|

This is **UNPAIRED**, using the actual retained fresh original2aef control; no new control was run. Both arms had checked client-cache clearing at their own execution. The candidate's actual clear-to-launch delay is retained after a pre-model launcher-reference repair. File-server cache/load remain uncontrolled. Main-step elapsed is not integration CPU; whole-minus-main is not pure I/O. These values establish no isolated candidate contribution, additive percentage, repeatability or nine-hour result. The observed single-forecast wall ratio is1.2380x; the1.5x throughput and2x speedup goals remain unmet, and concurrent-forecast throughput is unmeasured.

### Historical nine-hour qualification (2026-10-21)

The same selected image passed the unchanged original comparison through 15:00: **ten complete products, 1,625 ordered timesteps, all 512 ranks, two tiles, all four positive writers and 32 field markers**. Every model and reader scope closed normally; no observer or profiler was active.

| Nine-hour measure | Retained corrected original 546b | Current E3DA combined | Reduction |
|---|---:|---:|---:|
| Whole model/MPI wall, including output and drain |2068.620428s|1832.427071s|11.4179%|
| Integration-step elapsed, including communication/backpressure |1852.829220s|1734.321620s|6.3960%|
| Aggregate four-node cgroup CPU |1009950.954887CPU-s|921737.195426CPU-s|8.7345%|

This is an **unprofiled UNPAIRED** comparison with the retained actual original nine-hour control; no fresh control was run. Client-cache receipts and the original control's pressure context remain bound: hpc04 reached 104 GiB with 2,466 `memory.max` events and no OOM kill. File-server cache/load remain uncontrolled. It is not a pressure-free compute comparison or evidence of isolated contributions, additive percentages or repeatability. Main-step elapsed is not integration CPU. The observed single-forecast wall ratio is 1.1289x; 1.5x throughput and 2x speedup remain unmet, and concurrent-forecast throughput is unmeasured.

[Own nine-hour qualification](../cpu-compute/uvb-batch/NINE_HOUR_QUALIFICATION.json) (`76cb0073`) binds 32 actual references and preserves the separate three-hour `2ed4c147` and historical parent `0de` nine-hour efbfe35f records. Raw producer commits remain NULL; post-test source `1ae0c6ee` is unchanged. A report-helper mismatch between Python compensated sum and the original collector's sequential CPU accumulation was repaired by using the collector's exact operation order; no timing value, science check or tolerance changed.

The previous db5a fresh pair remains separately qualified at819.278306→659.076161s wall,597.239960→558.363350s main elapsed and367612.405251→319636.456690CPU-s. The new candidate is about0.4% higher in wall/main than that earlier candidate observation; these separate runs do not isolate an attributable regression. Inclusion rests on exact application science, measured complete-caller gains and the staging mechanism's resource benefit.

- Final-U SIMD passed genuine full-module raw/IEEE/five-state, captured-caller, readonly and physical-boundary checks. Complete captured UV callers, including identical restores and state observation, were5.28–5.54% shorter with5.29–5.53% less process CPU.
- Prep V SIMD passed the original60 procedure cases plus12 targeted V cases at bounds-checked O0 and strict O2. Complete synthetic Prep callers, including restoration and observation, were0.49–2.02% shorter with0.49–2.03% less process CPU. These positive, uneven observations support the one-directive inclusion; they are not isolated-loop or forecast gains.
- Thompson staging publishes/releases rain buffers before allocating cloud buffers in the supported shared-table path. Named READ, full-computation and partial-record fallback tests preserved all23 table byte streams,11 caller records, FP state and ownership/release requirements. The generic path and public module interface remain exact. Whole successful-INIT/creator-libm errno preservation is not qualified; original ALL15 failures remain preserved. Three-hour observed charged peaks were58.698/56.582/56.520/56.491GiB per node, with every memory-event counter zero. Those include file cache and are separate from caps and RSS/PSS; no isolated causal saving or two-forecast admission is claimed.

The combined build reused two qualified objects, preserved582 other ordered archive members, compiled no WRF source and linked once. Raw producer source commits remainNULL;1ae0c6ee records the tested source afterward. Own three-hour and unprofiled nine-hour science are qualified; no separate child short test is claimed. Output51a, codece1d8, input06d/NCa32, faba placement and qualified single-IB transport are unchanged. Production/master remain untouched and AWS remains suspended.

Rollback restores the paired BEFORE_UV_B_BATCH selection/build-binding/latest snapshots and reverts source-only1ae0c6ee, returning to db5a/0c91/sourcec883c564 with unchanged libraries. Actual qualification2ed4c147 binds58 verified raw references. The initial pre-model missing-control-reference failure and the first build's private-symbol guard failure are preserved; neither is relabeled as a successful original attempt.

The coefficient-loop SIMD candidate is [rejected with exact evidence](../cpu-compute/calc-coef-w-middle-i-simd-rejected/README.md). It produced packed divisions but selected a different NaN payload in ALPHA(1,2,0): parent0x7fc12345 versus child0xffc54321. Cases7–8 across all four rounding modes contained4464 differing words; the other72 complete CALC records matched. No O0, timing, application test or source promotion followed this hard O2 failure. The separate first fixture-parser failure remains preserved. The earlier U-DPn pragma is also rejected on exact IEEE output. A distinct FINISH-U reconstruction candidate passed80 complete native cases and all four complete-caller timing arms (8.2–11.8% shorter); experimental8bfe/archive6f44 is built, with original short application qualification pending. It is not included in the selected E3DA timings. The next current-build writer profile uses a bounded short diagnostic, with no forecast timing claim. Continue measured investigations after closing these decisions; a status or promotion is not a stopping point.

Evidence: [actual combined qualification](../cpu-compute/uvb-batch/APPLICATION_QUALIFICATION.json), [all three-hour observations](../cpu-compute/uvb-batch/THREE_HOUR_RESULT.json), [component evidence and rollback](../cpu-compute/uvb-batch/README.md).

## Historical combined LW + block-carry three-hour qualification (2026-10-20)

The selected build is now **LW0de7/archiveBA63**, with post-test source commit `d27df44f`, codec **e1d8**, outputpool51a and rootinput06d/NCa32. The unchanged original comparison passed **four complete hourly products,545 ordered steps,all512 ranks,two tiles,all four positive writers and all32 field-view markers**. All eight model scopes and the reader strongly closed; no observer/perf was active.

The fresh control-first pair measured **848.677401 → 657.745680s whole model/MPI wall (22.497562% lower,1.290282×)**, **382698.863204 → 318965.303819 aggregate CPU-seconds (16.653710% less)**, and **626.316100 → 556.643430s main-step elapsed (11.124202% lower)**. Main elapsed includes communication/backpressure. This is a single-forecast observation, not measured multi-job throughput; the1.5×/2× goals remain unmet.

Cross-pair variation matters: the prior optimized main560.3518s is only0.66% above this candidate, while the original control rose597.12504→626.3161s (4.89%). Do not attribute the new percentage to LW or codec alone, add component gains, or claim repeatability. **Current own3h is qualified; own9h remains false.** The prior41b/51a/3edf profiled nine-hour science stays historical. Raw producer source commits remain NULL; `d27df44f` is POST_TEST_SOURCE_IDENTITY only. Rollback uses the paired `BEFORE_ABSCLD_SCALAR` selection/binding and reverses only the four ABSCLD source changes, retaining e1d8 and other accepted components.

## Historical block-carry short acceptance, before combined LW three-hour (2026-10-20)

At this historical short-only milestone, codec **e1d8 block-carry** used unchanged WRF41b/sourceb37/archiveCF22, outputpool51a/source909, rootinput06d/NCa32, HDF825, faba map and two tiles. The original short check passed **two complete products,35 ordered steps,all512 ranks**, with exact input/worker/runtime checks; all model and reader scopes strongly closed. The existing067e diagnostic observer was retained. Codec source was recorded after testing in commit `862bae1e`; frozen raw producerNULL records are unchanged.

The fixed synthetic complete compress_block kernel was7.15%/7.23% shorter in wall and7.03%/7.14% lower processCPU across opposite-order hostpairs, with exact bytes/state/FENV. Complete-provider timings were mixed. **This short-only milestone established no provider or forecast gain and no three-hour or nine-hour qualification; current combined qualification is above.**

The preceding matched three-hour observation—**6.15838% lower main elapsed,19.46952% lower whole wall,12.88798% less aggregateCPU**—belongs to **prior3edf**. Its exact four-product545-step records and the prior profiledUNPAIRED ten-product1625-step nine-hour records are archived under `BEFORE_BLOCK_CARRY`; neither is transferred to e1d8. Main elapsed includes communication/backpressure, not integrationCPU. Rollback restores the paired BEFORE_BLOCK_CARRY selection/binding and slide-hash/3edf codec only.

[Historical block-carry component short qualification](../cpu-output/quilt512/codec/compress-block-local-carry/APPLICATION_QUALIFICATION.json).

# Prior3edf combined DF + private scratch three-hour qualification (2026-10-20)

A fresh control-first corrected-original546b versus current DF41b/pool51a/3edf comparison passed **four complete products,545 ordered steps,all512 ranks,two tiles,all four positive writers and32 field-view markers**. Whole MPI/model wall was **822.587693 → 662.433817s (19.46952% lower,1.241766×)**; aggregate node cgroup CPU was **368895.741336 → 321352.545937s (12.88798% lower)**. Main-step elapsed was597.12504 →560.35180s (6.15838% lower); it includes communication/backpressure and is not integration CPU.

Whole wall includes input, initialization, compute, communication, output and final writer drain. Caches were cleared on every node before each arm; all model and reader scopes closed. One fixed-order pair establishes no isolated, additive or repeatability claim; server cache/load remained uncontrolled. Current nine-hour SCI is now separately qualified by the profiled UNPAIRED diagnostic below. Raw WRF/output producer commits stayNULL; post-test tracking b37e02ce/909ab6ef remains separate. [Evidence](THREE_HOUR_FINAL_QUALIFICATION.json). Earlier CEC/de5b aliases are archived with BEFORE_DIFCOF_POOL names.

Prior3edf nine-hour scientific scope (2026-10-20): then-selected41b/51a/3edf passed the unchanged original ten-product/1625-step checker, all512 ranks, two tiles, all four positive writers and all32 field markers; model and reader scopes strongly closed. The three actual noon captures contain700/704/710 samples with14.926s common overlap. This was a PROFILED_UNPAIRED diagnostic versus retained original546b:1833.850289s wall/922292.209006s aggregate CPU/1736.849780s main, descriptive differences11.378754%/8.617392%/6.194550%. These are not a fresh or sustained matched speedup. At that prior milestone, the matched unprofiled benchmark was the fresh three-hour pair19.469520% wall/12.887980% CPU/6.158380% main; the current LW+e1d8 pair is above. ProducerNULL and post-testb37/909 source tracking remain separate; Those prior measurements exclude block-carry. See [nine-hour qualification](NINE_HOUR_FINAL_QUALIFICATION.json).


# Historical output addition: private shuffle-scratch reuse (2026-10-20)

Selected output51a/source909ab6ef is combined with WRF41b/sourceb37 and all earlier improvements. Native/fullshim/publicAPI and original2products35/all512/twoTiles/input/worker/closure checks passed. Provider37.26%/37.28% gains describe32steady **synthetic** W-shaped calls after excluded warm proof, with bounded225.72MB/writer retention; no isolated or overall forecast gain is claimed. [Evidence](../cpu-output/quilt512/private-shuffle-scratch-reuse/QUALIFICATION.json). The actual fresh combined three-hour result is now recorded above; current nine-hour SCI is separately qualified above. Rollback restores pairedBEFORE_PRIVATE_SHUFFLE_SCRATCH records tode5b, retaining41b/3edf/input.

# Historical working build: MYJPBL DIFCOF SIMD (2026-10-20)

Selected41b/sourceb37e adds the exact ordered DIFCOF SIMD directives to all prior improvements. Complete captured-caller wall fell2.38%/1.18% and processCPU2.44%/1.20% in opposite-order pairs. Original two products/35orderedsteps/all512/twoTiles/writer/input/runtime checks passed; all model/reader jobs closed. The application carried the ABI-qualified diagnostic write observer. The original short gate alone established no long-horizon gain; the current combined three-hour qualification is now above, with current nine-hour SCI separately qualified above. [Evidence](../cpu-compute/myj-difcof-simd/QUALIFICATION.json).

The previous CEC+3edf three-hour result below remains19.30% lower whole-wall/12.79%lessaggregateCPU, and is explicitly not transferred to41b. Rollback uses the paired `BEFORE_MYJ_DIFCOF` records and removes only the two new directives if rebuilding. Production/master remain unchanged.

## Prior CEC+3edf qualification

# Qualified WRF CPU working configuration

## Previous CEC+de5b+3edf combined three-hour result (2026-10-20)

A fresh corrected-original546b/control-first comparison of the then-selected CEC compute build, root06d/NCa32 input, de5b quilting provider and 3edf codec passed **all four products and 545 ordered steps**, all512 ranks, two tiles and all four positive I/O writers. Wall time was **821.054461 → 662.590205 seconds (19.30% lower, 1.239159×)**; aggregate node cgroup CPU was **368084.978303 → 321016.008953 CPU-seconds (12.79% lower)**. Main-step elapsed fell597.98535 → 559.81599s (6.38%); it includes communication/backpressure and is not integration CPU.

Whole model/MPI wall includes input, initialization, computation, communication, quilting, HDF5 writes and final writer drain. Production-style settings are480 compute ranks in8×60 plus4×8 dedicated I/O ranks, NetCDF format2, hourly history and one frame/file. Checked client-cache clears preceded both arms; all model and reader jobs closed. File-server cache/load remained uncontrolled. This is one fixed-order matched pair, without isolated component, additive or repeatability claims; nine-hour qualification was absent at that historical qualification. Neither1.5× nor2× target is met.

[Qualification](PREVIOUS_THREE_HOUR_FINAL_QUALIFICATION_BEFORE_DIFCOF_POOL.json) binds actual CEC/3edf artifacts and preserves the raw collector record, whose inherited candidate-name string incorrectly said1d6e. Only the separate reporting label is corrected from the actual leases; frozen runtime/checker/raw records are unchanged. Previous1d6e/de5b19.05% remains a separate result. Source identities remain80a9/624bc116; raw producer commits remain null. Production/master are unchanged; rollback of slide-hash alone remains the paired `BEFORE_SLIDE_HASH_UNROLL4` records or codec `huffman`.

The private FAST level-invariant prototype passed native/complete-provider exact checks, but complete-provider wall changed0.13% slower/0.03% faster and process CPU0.11% slower/0.51% faster on hpc02/04. No significant saving was established; it is parked and excluded. MYJPBL DIFCOF SIMD now passed complete-caller performance and the original short application; see the current selection above. Output-boundary attribution and bounded private shuffle-scratch reuse are continuing investigations, with no new benefit claim.

## Prior codec: slide-hash unrolling (2026-10-20)

The codec `3edf15a2` was qualified with the then-selected CEC compute build and de5b provider; current DF41b/pool51a reuses it. One loop-unroll directive preserves the original AVX2 saturating arithmetic and array traversal. Complete-function tests on hpc02/04 measured **12.29–16.49% less wall time** and **15.03–17.72% less process CPU**, with exact arrays and IEEE state. These are standalone function gains, including per-call clock overhead, not output-stage or forecast gains.

The composed codec passed seven corpora, five streaming cases, generic fallback and stock decoding, then the current complete output provider. The short full-grid run passed the original checker on **two complete products and 35 ordered steps**, all512 ranks/two tiles, actual new-codec library hashes and worker lifetimes. Both active writer groups completed216 balanced callbacks; the other two groups had the required zero counters. All model/reader/build jobs closed. The repository build helper reproduced the qualified object and library byte for byte.

[Application evidence](../cpu-output/quilt512/codec/slide-hash-unroll4/APPLICATION_QUALIFICATION.json) records exact artifacts and raw receipts. Code commit `624bc116` records the tested codec source after qualification; its WRF source identity was `80a9cd6f`, executableCEC/archive6034, with frozen raw producer commits unchanged. Restore the paired `PREVIOUS_*_BEFORE_SLIDE_HASH_UNROLL4.json` working records, or choose codec `huffman`, to roll back only this addition while retaining the previous compute/output improvements. Production/master remain unchanged.

That previous CEC+3edf configuration has the historical three-hour qualification above. The preceding short gate remains component evidence; current nine-hour qualification is still absent. Private FAST728b remains excluded after neutral complete-provider measurements.

## Retained MCICA compute improvement (2026-10-20)

The working build now includes MCICA cloud-mask fusion. It passed the original checker on two complete outputs, 35 ordered steps, all 512 ranks and two tiles; all model and reader jobs exited successfully. Complete-caller wall time fell **12.32% and 13.90%**, with **11.41% and 13.76% less process CPU** in opposite-order pairs. Its isolated forecast-wide benefit remains unmeasured; the current combined three-hour result is above, and current nine-hour qualification remains pending. [Evidence](../cpu-compute/mcica-mask-fusion/QUALIFICATION.json) and [selection](selection.json) identify the exact artifacts and rollback. Source commit `80a9cd6f` records the tested source after qualification; raw producer commits remain `null`.

## Previous selected build: fresh three-hour qualification

Previous1d6e/de5b fresh three-hour qualification (not newCEC): corrected-original546b wall 818.818689s → 662.845312s (**19.05% shorter**, **1.235309×** speedup); aggregate cgroup CPU 367148.357295 → 321081.188328s (**12.55% lower**). Original four products/545 ordered steps/all512/two tiles and all four positive writers passed; caches cleared on every node before each arm, all model and reader scopes strongly closed. Main-step elapsed 595.98539 → 560.99084s (5.87% lower) includes communication/backpressure and is not integration CPU. One fixed-order whole-inclusive-IO comparison, without isolated component, additive or repeatability claims. Producer source_commit stays NULL; nine-hour qualification was absent at that historical stage, with the previous output172 result retained separately.

Earlier noon-only and previous-output measurements below retain their historical scope.

The previous selection retained WRF1d6e/source495f, input06d/privateNCa32, compute/Thompson/lazy-group improvements, codec881/HDF825/faba/two tiles/shared1/singleIB/OMP1. Its then-default fused provider was source8db/fullshimde5b: accepted padding-only fill plus the 32-word AVX2 byte transpose, retaining exact scalar tails, four chunks/workers, compressed bytes/layout/API/state/lifetimes. [Selection](selection.json), [binding](CURRENT_SOURCE_BUILD_BINDING.json) and [combined output evidence](../cpu-output/quilt512/padding-block32/README.md) identify literal tested artifacts; producer commits remain NULL.

The actual noon12:00–13:15 application passed two complete original products, 230 ordered steps,512 ranks/two tiles/all library/affinity/input/lifetime checks and model/reader closures (SCIc6481002, reader5e7e4b18). Writer487/495 callbacks216 each were balanced;503/511 were inactive. Input root0 supplied17, declined118 and restored135; these whole-noon counts do not replace historical short-run counts. Two opposite-order complete-provider synthetic comparisons were 2.19%/1.78% shorter with 3.60%/3.04% less process CPU than the padding-only parent. No additive or forecast gain is claimed. That noon-only record did not cover four active writers; the latest three-hour record above now does. Current9h/restart/other-compiler/144h acceptance remains absent.

The historical [output172 nine-hour comparison](PREVIOUS_NINE_HOUR_RESULT_BEFORE_CURRENT_DAYTIME9H.json) used previous output172 with the same1d6e/root06dNCa32: ten products/1625 steps exact,2069.312→1842.395s (10.9658% lower whole wall/8.2181% less aggregate CPU), UNPAIRED against retained original546b. Summed main wall fell5.7709%; it includes communication/backpressure and is not integration CPU. Server cache/load were uncontrolled; scope does not transfer to de5b. The [previous fresh three-hour pair](PREVIOUS_THREE_HOUR_RESULT_OUTPUT375.json) used still-earlier output375:818.040→670.778s,18.0018% lower wall/11.6971% less CPU, four products/545 steps/all512/two tiles/four positive writers. Both remain historical measurements.

Production quilting remains480 compute ranks in8×60 plus four groups of eight I/O ranks, NetCDF format2/hourly full history/one frame per file. Whole wall includes input/init/output/drain. Rank0 alone gets input06d/NCa32 and temporarily borrows occupied CPUs0–3, restoring0; the other511 retainNC8adc/selectedoutputpool51a with codec3edf. Current noon profiles retain actual reports without changing coarse UNAVAILABLE defaults; sample costs are diagnostic, not a matched benchmark.

Rollback restores [previous329f selection](PREVIOUS_SELECTION_BEFORE_PADDING_BLOCK32.json) and [matching binding](PREVIOUS_SOURCE_BUILD_BINDING_BEFORE_PADDING_BLOCK32.json), returning output329f/provider1e0 with compute/input unchanged. Revert source8db→1e0 only if building again; no rebuild is needed merely to select the existing329f artifact. Production/master remain unchanged. Continue the active campaign; the periodic fresh3h qualification above is complete; no automatic9h replay.

The current a437 executable also owns [its noon75m scientific qualification](../cpu-compute/vy-sw-qualified-batch/NOON75M_SCIENCE_QUALIFICATION.json): two complete outputs and 230 ordered steps. The corresponding four-host acquisition failed before native recording; no fresh daytime timing comparison or usable profile is claimed.
