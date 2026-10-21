## Current combined selection (2026-10-21)

The working fork now selects **e3da6907 / archive4f2a0cf0 / post-test source1ae0c6ee**. It retains all prior improvements and adds final-U velocity SIMD, Prep V coupling SIMD and split rain/cloud staging during Thompson initialization. The unchanged original checker passed all four complete products,545 ordered timesteps,512 ranks,two tiles,all four positive writer groups and all32 field markers. All model and reader jobs closed normally.

| Three-hour measure | Retained corrected original | Current combined | Reduction |
|---|---:|---:|---:|
| Whole model/MPI wall, including I/O and final drain |819.278306s|661.793683s|19.22%|
| Integration-step elapsed, including communication/backpressure |597.239960s|560.596320s|6.14%|
| Aggregate four-node cgroup CPU |367612.405251CPU-s|321402.587962CPU-s|12.57%|

This is **UNPAIRED**, using the actual retained fresh original2aef control; no new control was run. Both arms had checked client-cache clearing at their own execution. The candidate's actual clear-to-launch delay is retained after a pre-model launcher-reference repair. File-server cache/load remain uncontrolled. Main-step elapsed is not integration CPU; whole-minus-main is not pure I/O. These values establish no isolated candidate contribution, additive percentage, repeatability or nine-hour result. The observed single-forecast wall ratio is1.2380x; the1.5x throughput and2x speedup goals remain unmet, and concurrent-forecast throughput is unmeasured.

### Current nine-hour qualification (2026-10-21)

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


# Current output addition: private shuffle-scratch reuse (2026-10-20)

Selected output51a/source909ab6ef is combined with WRF41b/sourceb37 and all earlier improvements. Native/fullshim/publicAPI and original2products35/all512/twoTiles/input/worker/closure checks passed. Provider37.26%/37.28% gains describe32steady **synthetic** W-shaped calls after excluded warm proof, with bounded225.72MB/writer retention; no isolated or overall forecast gain is claimed. [Evidence](../cpu-output/quilt512/private-shuffle-scratch-reuse/QUALIFICATION.json). The actual fresh combined three-hour result is now recorded above; current nine-hour SCI is separately qualified above. Rollback restores pairedBEFORE_PRIVATE_SHUFFLE_SCRATCH records tode5b, retaining41b/3edf/input.

# Current working build: MYJPBL DIFCOF SIMD (2026-10-20)

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