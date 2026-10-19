# WRF CPU optimization — continuing campaign handoff

Updated **2026-10-19 19:46 UTC**. The persistent Goal is **active**. This file describes the current state, accepted work, closed candidates and remaining investigations. Continue authorized work after a report, failed candidate, successful test or promotion. Recover actual live jobs from `investigation/wrf-cpu/campaign/spot100-20261016/CURRENT_STATE.json` before launching anything; never duplicate an uncertain job.

This consolidated revision supersedes the older live-status paragraphs. Detailed historical snapshots remain in Git commit `8b7c38fe18028a31cb07ceda053d8c19df590957`; raw experimental evidence and failed records remain unchanged. `OPTIMIZATION_FINDINGS.md` retains detailed chronological findings. No production or master changes are authorized. AWS remains suspended.

## Selected source, build and qualification

Working fork: `https://github.com/ddietz89/WRF`, branch **perf/cpu-20261012**. Selected source **26bcd59c507dc76cba49e3e06196bac2fb278dec**, executable **3bb2b8f17ed5c5c8cb2afe9b1e68faf162a66c37546a366a00179411b651c4df**, archive **76b137ef8204cf85a470074dae282b21074605f010fb25692ab04e01a80a3daa**. Evidence-only commits can follow the selected source. Authoritative selection and bindings are in `tools/cpu-working/selection.json` and `CURRENT_SOURCE_BUILD_BINDING.json`; frozen producer `source_commit:null` records are preserved, with post-test tracking separate.

Executable: `/pool/wrf-experiment/wrf-cpu/builds/thompson-tcg-rk-later-pass-combined-current-r1/wrf.exe`. Selected runtime retains shim375aa7e3, codec881d0a1a, HDF5825e2f1f, faba rank map, FIELDVIEW1, shared1, OMP1 and UCX `rc,sm,self` on InfiniBand `ibp1s0f0:1`. Full hashes/paths are in the selection. Do not substitute executable-only changes for pinned library changes.

Support: cold single-domain Thompson, DIMNRHG1, GNU13.3 strict Zen2,512 ranks (480 compute8×60 plus4×8 quilt),128 physical cores/node and two tiles. Shared mode0 has native qualification only; it is a restricted experimental path, not generic fallback. No current-build restart, cycling, nesting, other compiler or144-hour qualification transfers. AOCC/Intel remain eligible experimental stacks with separate qualification.

“Original” means corrected original **546b9915**, not pristine upstream. It includes separately approved AFWA terrain, Thompson ordinal-addressing, MU2 ghost and adaptive-alarm corrections. Those establish science and are not performance gains. Preserve the documented order-2 row restoration and its separate trajectory scope.

## Full-grid results

| Horizon/build | Corrected-original wall | Improved wall | Wall lower | Aggregate CPU lower | Main-step elapsed lower | Design |
|---|---:|---:|---:|---:|---:|---|
| **3h selected3bb2/source26bc** |820.506360s|673.517184s|17.9144%|11.4405%|5.4967%|Later candidate versus retained original, **unpaired**|
|3h previous familye485/source0828|820.506360s|676.104556s|17.5991%|11.1953%|5.2710%|Unpaired|
|3h previous six-ownered095/sourcebe96|820.506360s|673.345750s|17.9353%|11.5875%|5.6418%|Fresh original-first pair|
|9h historical ten-owner322/source4480|2069.312230s|1858.366860s|10.1940%|7.5402%|5.2945%|Unpaired; **does not qualify3bb2**|
|9h historical six-owner6c/sourceeb616|2069.312230s|1868.604428s|9.6993%|7.0607%|4.7871%|Unpaired|
|9h historical X3a|2069.312230s|1849.618368s|10.6168%|8.0348%|5.7321%|Fresh original-first pair; separate configuration|

Selected3bb2 passed **four complete products,545 ordered steps,all512 runtime proofs,two tiles and all four writer groups**. All scopes closed. FQ`28018b19`, science`ddc294c7`, readerclosure`8a82ccb7`. Exact current CPU totals are367800.485597→325722.091547s; main elapsed597.994050→565.124270s. Main includes communication/backpressure and is **not integration-only CPU**. Wall minus main is not pure I/O.

The historical nine-hour322 run passed ten products/1625steps/all512/two tiles/four writers (FQ`bb0c0f6a`). There is **no selected3bb2 nine-hour qualification**. The selected three-hour observation is1.21824× throughput;1.5× would require another18.7839% wall reduction and2× another39.0879% against this reference. Historical9h322 is1.11351×. Goals remain unmet; these are arithmetic gaps, not demonstrated headroom.

Every recent timing arm has checked compute-client cache clears. File-server cache/load and separate epochs remain uncontrolled. Preserve order, throttling and memory context; no isolated/additive/repeatability claim follows from these tables. Never add kernel/caller/forecast percentages. Result files and preserved historical selections under `tools/cpu-working/` bind their own science, libraries and closures.

## Latest memory and RK improvements

TCG is the23rd shared field on the12th fixed owner. Its experimental macro changes PUBLIC ALLOCATABLE sentinel storage to a PRIVATE CONTIGUOUS pointer plus private INIT stage. All12 owner statuses and23 views commit before any staging frees; TCG frees last. The generic no-macro projection, arithmetic, table records and helper ABI are preserved. Actual four-rank O0/bounds/O2 and private native routes retain11 original callers,two initialization calls,23 records and raw/state checks; the consumer rebuild binds the selected image. See `tools/cpu-memory/thompson-table-sharing/TCG_EXTENSION_QUALIFICATION.json`.

First-table same-image private/shared measurements showed6.74–7.47GiB/node saving with neutral timing. Later sharing extensions have qualified exact science and lower nearby-progress memory observations, without isolated PSS attribution. Current peaks82.592/80.431/80.393/80.363GiB had zero memory-limit events; startup peaks did not fall. Near-progress3bb2 snapshots were1.47–1.61GiB/node below the preceding family build, from different/non-atomic samples. Do not label these synchronized phase measurements or isolatedTCG savings.

Later RK2/3 equal-extent pass fusion preserves ordered multiply then addition; unequal extents use original two passes, RK1 unchanged. Complete synthetic public callers were22.9332/21.5093% shorter in two opposite-order same-host pairs; native52cases×4rounding modes/O0bounds/O2 passed. **Whole-harness CPU increased**17.264988→18.610768s and17.094994→18.596748s; cause remains unknown. The measured caller benefit is not a whole-harness CPU claim. Reconstructed canonical parent090d differs from actual0f53 only in three proven Fortran WRITE source-line literals; actual0f53 remains an additional hard raw/state oracle. No binary/PP normalization or science relaxation. See `tools/cpu-compute/rk-later-pass-fusion/QUALIFICATION.json`.

Retain significant exact caller gains and qualified memory savings under the owner rule unless a concrete unacceptable cost is demonstrated. Neutral/noisy forecast timing alone is not grounds to discard them.

## Included improvements

Individual figures below retain their kernel/caller scope. They do not decompose the full-grid saving.

| Area | Included improvements and evidence scope |
|---|---|
| Advection | Y-row/quotient reuse; corrected X-distance caching; ordinary and positive-definite face-fill/vertical-flux SIMD; limiter preparation fusion/SIMD; PD vertical-divergence SIMD; strict GNU Zen 2 member targeting. Corrected X-cache historical caller gain is 1.87%; current ISA captured callers were 12.0–12.4% shorter. Their joint current-source exact gate passed. |
| W and UV advance | Coefficient reuse; heavy W loop SIMD; forward/back substitution SIMD; initial temperature/RHS and WDWN producer SIMD; final geopotential fill; initial UV pressure fills; quotient reuse; W damping-height/curvature reuse; initial U and V tendency-add SIMD. Initial V complete captured UV calls were 2.5575/2.4855% shorter; initial U observations were 0.2584/1.6827% shorter. |
| Pressure, density and RK | Original nonhydrostatic pressure/density SIMD; RK tendency-add SIMD; first-stage scalar copy/update fusion; final PD scalar-consume SIMD. Final PD complete synthetic callers were31.1266/26.5239% shorter. Later RK2/3 equal-extent multiply/add pass fusion is now included; unequal extents retain the original fallback and RK1 is unchanged. |
| Latest geopotential RHS | Sixth-order X and Y interior I-loop SIMD, one directive each, unchanged expressions/bounds. X complete synthetic callers were 5.0695/4.9773% shorter; Y 6.0985/4.8610%. All 33 complete native RHS cases passed raw/state/readonly/physical checks. X andY are in the selected three-hour build; historical nine-hour qualifications bind their own builds. These are synthetic caller observations, not isolated production-loop gains. |
| Diffusion and rotation | Horizontal-diffusion SIMD and retained row cache; Coriolis V quotient-row reuse; C2A SIMD; qualified SmallStep U, W/geopotential and temperature coupling SIMD; member-specific SmallStep Zen 2 default. The T focused loop was 29.3–35.7% shorter despite mixed complete-preparation times; it was retained with that limitation. |
| AFWA | RH guard/locality, contiguous preparation traversal, column-copy removal and five hydrometeor copies guarded by actual consumer routes. The separately approved terrain correction belongs to the baseline, not this gain inventory. |
| MYJPBL | PBL initialization locality; tendency writeback SIMD plus invariant ice-guard split; input packing and UK/VK/ZHK velocity-copy SIMD; independent VDIFV and VDIFQ coefficient-producer SIMD. VDIFQ complete coefficient calls were 9.76–9.78% shorter and captured full MYJPBL calls 1.61–2.05% shorter. VDIFV gains were smaller but exact and positive. Existing recurrences/allocation behavior remain where not explicitly changed. |
| Thompson | Literal constant index and per-call scratch bank, including contiguous 75-column zero initialization. The bank's early caller observations were mixed; its zeroing follow-up was 0.4513/1.4223% shorter. **The qualified working build shares23 immutable fields through12 fixed NUMA-cohort owners, including the rain/snow family andTCG; generic no-macro behavior is preserved.** |
| Radiation and cloud generation | MCICA destination/host-seed access preserving RNG sequence; SUMFLUX final-pass fusion; INATM redundant cloud-fill removal; paired shortwave quadrature; longwave downward clear-prefix. Shortwave radiation-inclusive steps repeatedly saved 1.74/1.52 s in their diagnostic windows; whole-run attribution remains unresolved. Longwave all-clear callers improved about 6.1–6.5%, with a measured 0.5–0.6% mixed-case cost and unknown atmospheric regime weights. |
| RSL and copies | Qualified integer Transpose specializations, narrow integer halo copies, guarded REAL bulk copies and other retained copy specialization. Reversed Transpose checks supported retention; do not substitute another old transpose variant. |
| Output pipeline | Threaded root compression, SIMD byte shuffle, parallel output-chunk packing, guarded zlib-ng/Huffman improvements, reusable startup/output buffers, smaller later quilt retrieval scratch and C-owned per-field views. Owned views measured 5.04/5.92% shorter synthetic buffer handling; initial STORE deep copies remain. Later scratch reduction does not eliminate initial duplication peak or prove all copy traffic disappeared. |
| Input/HDF5 | Private SSE2 four-byte inverse shuffle, exact public/real-caller/application checks, selected through pinned HDF5 rather than an executable-only change. |


Matching qualification records are under `tools/cpu-compute/`, `tools/cpu-output/`, `tools/cpu-input/`, `tools/cpu-memory/` and `tools/cpu-working/`.

## Fresh current-build profile and closed page-layout probe

Selected3bb2 passed the cold12:00–13:15 original case: two outputs,230 ordered steps,all512,two tiles and unchanged two-active/two-inactive writer contract. Three same-host main-thread15s captures retained701/707/707 samples with14.947s common overlap and actual longwave frames. All models, recorders, watchers and readers closed. `tools/cpu-profile/radiationwindow-3bb2/QUALIFICATION.json` binds39 references; FQ`087130d9`, science`d83257e4`, readerclosure`9fe4ab97`.

This is discovery evidence, **not a new timing comparison**. Coarse parent status remains UNAVAILABLE from a late start-window check; actual normal recorder completion, phase/parse and science qualify separately. The13UTC reference has74.8839% positiveCOSZEN; do not call the earlier capture all-domain local noon, or initial12UTC zeros astronomical night. Selected-thread shares are not global removable costs or arrival causality. Unknown library leaves remain unknown.

A four-rank73,260,000-byte shared-table standalone probe passed original full-byte/state/lifetime plus post-probe byte checks and closed. All four observed mappings failed virtual/file-offset congruence for proposed full2MiB data-interior advice; **zero advice calls** occurred. Current helper mappings used4KiB pages with zero shmem/file PMD coverage. This is one allocation's result, not universal ASLR/MPI impossibility or timing evidence. Direct advice is parked without allocation retries. `CLOSED_LARGE_PAGE_ADVICE_SCREEN.json` retains FQ`c7582a64`, receipt`fce84be9`, closure`0c8a2269`; no production helper or global policy changed.

## In-flight work and next actions

1. **W RHS inner-I SIMD:** distinct from earlier initial-RHS and WDWN producer changes. Actual current93b native gate passed captured completeW replay and32 synthetic complete-W O0/bounds/O2 cases, raw/readonly/inactive guards and immediate five-state coverage. Candidate7b89121b retains YMM/XMM multiply/add/divide before top-lid zero blending, no FMA, scalar tails; current native parent reproduction and MODd50c passed. All native scopes closed (INV8287a087, FQ`6e520d26`). Four exact/cache-cleared opposite-order arms now show4.6404/6.2374% shorter complete captured-caller wall (same restoration/reset/state work inside clocks); all scopes closed. Retained for combined application, not selected yet; no forecast gain claim. See `tools/cpu-compute/w-rhs-inner-simd/QUALIFICATION.json`. Component cache boot/meminfo fields are unavailable, not retrospectively invented.
2. **Thompson reflectivity readonly copies:** new `calc_refl10cm` candidate removes temp/pres/qv scratch copies; it is distinct from rejected `calc_effectRad` density work. Actual DeepSeek author/review returned; native preparation adds radar-enabled full-caller coverage because the reused11case fixture uses radar0 and does not exercise reflectivity. Preserve expression/MAX order, legal input aliasing and IEEE behavior. Native whole-parent reproduction, original11+radar1+typed3/raw-state/all23records passed; actual malloc/free28→25 each and module interface unchanged. Complete-caller timing is next; no performance/application claim.
3. **MPI critical-path investigation:** fresh stacks predominantly show C`MPI_Wait` under RSLX/Y halos, including `halo_pwp_sub→first_rk_step_part1`; smaller adaptiveAllgather branch. Historical callsite-qualified tests already attributed99.0139% of overlapping wait brackets to receives versus0.9861% sends. Do not repeat that aggregate question. A10.24s bounded reuse of the retained DWARF data now binds all701/707/707 sampled headers/IPs exactly and maps current caller PCs: X+receive233/180/195 samples for ranks0/384/416, with differentY-direction contexts. All scopes closed. See `tools/cpu-profile/radiationwindow-3bb2/HALO_CALLSITE_ANALYSIS.json`. Choose a concrete new intervention from source/dependency evidence. Progress samples do not establish transport versus late-producer cause. Minimal currentV2Allgather retarget proposal is parked for a later useful combined profile; it cannot explain dominant halo waits.
4. Qualify worthwhile measured candidates as a controlled integration batch, preserving exact science. Run periodic original three-hour full-grid comparisons and selected nine-hour comparisons for sustained behavior. No mandatory full forecast for every small kernel, no broad compiler/map/XPMEM sweep, no repeats of closed mechanisms without new evidence.

Root owns source/default integration, selection, resource scheduling and ledger. Current lane operators: `radiation_resume` W/caller tests, `profile_campaign` Thompson, `spot_campaign` communication. See CURRENT_STATE for actual jobs and release status, not this timestamped snapshot. Full-grid timing exclusively owns01–04; disjoint-node component jobs may proceed independently.

## Closed, parked and alternative candidates

Keep dispositions and failed evidence. Reopen only with new source, measured mechanism or representative evidence.

| Candidate | Decision and concrete reason |
|---|---|
| One serial tile instead of two | **Reject.** Same-image short forecast changed six AFWA fields; one example approximately halved. Two tiles remain required. |
| PD X-divergence, `calc_cq` CQU and SUMFLUX accumulation SIMD variants | **Reject tested variants.** Full-module raw exceptional-value gates exposed NaN-payload changes. Finite replay alone was insufficient. The separately promoted SUMFLUX final-pass fusion is a different change. |
| PHY_PREP theta/density fusion and later height-consumer fusion | **Reject.** Targeted distinct-NaN tests changed density and downstream pressure/temperature payloads. Do not loosen IEEE checks or launch timing after failure. |
| RHS_PH WDWN pass fusion | **Reject.** Observable NaN-payload mismatch. This is distinct from the accepted X/Y interior directives. |
| Four-column MYJPBL recurrence batching | **Reject tested versions.** O2 NaN-payload failures; a nonfinite fallback also failed for finite zero-height inputs producing a changed NaN sign. Packed code and matching FP flags do not override raw-bit failure. |
| Dry V tendency stage-unswitch/SIMD | **Park after local counterexample.** Local Ubuntu GNU13.3/generic-ISA RK2 scalar-tail NaN priority changed. Original32 cases/O0 supplement passed. This is not a qualified project-compiler production failure. No timing gain was established. |
| Thompson exponent-one shortcut | **Park.** Pointwise tests lost underflow/inexact flags despite matching output bits. No complete-caller or forecast performance qualification. |
| Nonhydrostatic pressure/density pass fusion | **Unpromoted.** The selected original-loop SIMD is the separately qualified path; do not conflate their gates or evidence. |
| MYJPBL VDIFQ/VDIFV scratch banks, register-carry/lifetime variants, redundant ZINT initialization | **Unpromoted after caller screens.** Allocation reduction alone did not outweigh actual caller costs; slower/mixed results retained. Accepted independent coefficient SIMD remains. |
| Paired shortwave `reftra` | **Unpromoted after slower complete-caller results.** This is distinct from accepted paired `vrtqdr` quadrature. |
| Thompson `calc_effectRad` scalar density scratch removal | **Unpromoted.** Helper results mixed and complete caller slower. |
| Ordered PHY_PREP total-water SIMD directive | **Unpromoted.** No significant useful gain established in its tested current caller/code-generation scope. |
| Ordinary Y scheduling / earlier ordinary scalar X rescheduling / theta scheduling | **Unpromoted.** Exactness or a smaller loop is not sufficient where actual caller timings are slower/mixed and no distinct useful kernel mechanism is established. |
| Thompson redundant radius fills and paired RSLF polynomial | **Unpromoted.** Requested longer fill screens remained insignificant; paired polynomial emitted separate scalar calls rather than useful packed arithmetic. |
| New contained longwave RNG integer-local helper | **Park.** Native exact gate passed but complete MCICA callers were 2.56% shorter / 2.73% longer; focused standalone fixtures had identical instructions and did not represent the changed reload mechanism. No manufactured timing ratio. Earlier promoted RNG changes remain. |
| Codec FAST multi-insert inlining | **Park.** Exact compressed bytes/decoding passed, but complete codec observations were 0.84% slower / 1.74% faster; no separate significant kernel gain established. Keep codec881. |
| Codec carrier-width, heap packed-key, short/three-byte-prefix, block-local bit-state and leaf-counter variants | **Unpromoted.** Their exact tested screens were mixed, slower or insignificant. Huffman paired Code/Len loads and existing guarded codec remain accepted. |
| Inflate table-word replacement | **Defer without implementation.** Three distinct required entry fields already load efficiently; no demonstrated net native cost reduction. Sampling the routine alone is insufficient. |
| Early-X receive preposting | **Unpromoted.** Native and short/three-hour science passed, but no demonstrated representative speedup. |
| Direct eight-neighbor halo | **Unpromoted standalone protocol.** Exact full-array/guard checks passed at480ranks; four representative arms had inconsistent timing. Not integrated into WRF. |
| Adaptive timestep six-gather bundle | **Park.** Strict gate added FE_INEXACT; separate numeric-output diagnostics passed but did not establish full state equivalence, and local API-only gain was too small. First-gather waiting also includes arrival imbalance. |
| Selective MPI yielding, quilting readiness/wait changes and passive completion helper variants | **Unpromoted.** No useful representative gain, unsupported authority or unresolved fixture/state problems. Diagnostic observers are evidence tools, not model speedups. |
| NUMA/rank remappings, host-contiguous blocks and additional XPMEM settings | **No new default.** Qualified alternatives generally had mixed/slower representative times. A same-build XPMEM pair was2.46% slower; counterbalanced pair0.77% faster. Earlier2.13% faster scientific run lacked full affinity qualification. Later exact XPMEM qualification passed; no robust runtime gain established under the tested map. Native microbenchmarks do not override full-grid variation. |
| Co-located eight-rank output groups | **Retain qualified alternative, not default.** Earlier pair saved1.6074% wall but increased main elapsed1.3946% and hit the100GiB cap. The qualified revisit after sharing was0.834% slower (676.74→682.38s). Keep faba; no new placement sweep without a mechanism. |
| Whole-gather-buffer borrowed views | **Park design.** Retaining the full gather allocation through output conflicts with cache release and memory headroom. The accepted individual C-owned field-view implementation has a different lifetime contract. |
| Global KSM for WRF tables | **Not enabled.** The separately approved tiny synthetic sharing/COW pilot passed and restored scanner run0. It does not establish full-WRF page identity, NUMA or MPI safety, or performance. Current explicit owner experiment avoids global scanning. |

| New array-add SIMD and final-theta SIMD | **Reject tested variants.** StrictO2 NaN payloads changed (array-add124words); no timing or relaxed-state waiver. |
| Current MYJPBL RHOK reuse and calc_coef_w Hk reuse | **No new change.** Actual current code already computes/reuses the proposed quantities. |
| Whole-C2 borrowed-send prototype | **Park.** Generic4rank protocol passed, but actual whole-C2 nine-rank immediate underflow/denormal state failed. No WRF integration or zero-copy claim. |
| Shared-table full2MiB data advice | **Park observed mappings.** Four-rank file-offset congruence failed before any advice; no measured benefit to discard or allocator sweep justified. |

Accepted paired shortwave quadrature, RK first-stage fusion, corrected X-cache, admitted advection Zen2, temperature coupling SIMD and longwave downward clear-prefix stay accepted; they are present in combined qualification.

## Operating rules, costs and rollback

- **Do not stop after a status, milestone, failure or promotion.** Keep meaningful updates and durable recovery. Respect actual session limits; do not promise an external always-running service. Goal is active with no requested token budget.
- Preserve protected checker SHA`0382bcbabfbc16b76114ef552206c6c558ea15cd3c3552dfaed98b977deea2b4`, exact science/metadata/layout/ordered steps, raw IEEE/state, physical guards, rank/affinity/library/tile and writer acceptance. No fast math/tolerances/field exceptions. Scientific changes need separate authority.
- Full-grid caps:128physical cores/node,100/100/100/104GiB,swap0,three-hour1200s/nine-hour3600s. Writer roots487/495/503/511 are04 CPUs31/63/95/127. Keep faba placement,two tiles,qualifiedUCX/IB and job MEMLOCK setting. Use00 for metadata and timing-insensitive work; its known GNU GLIBC limitation is not reason to substitute compilers.
- Checked bounded sync/drop_caches3 precedes **every timed arm**, after all affected jobs positively close. Concurrent same-node waves share a single pre-launch boundary; no clearing during other active work. Preserve actual boot/time/helper/closure receipts. Server caches stay uncontrolled.
- Delegate bounded implementation and independent review **through actual DeepSeek calls**, endpoint`https://api.deepseek.com`, model`deepseek/deepseek-flash`, tools denied,240s. No credentials or scientific arrays. Adjudicate returns; provider assertions are not native science proof. Honor actual review controls, request exact blocked authority promptly and allow five minutes before local fallback while independent work continues; never bypass review.
- Standing authority includes staging/readiness/transient jobs/cgroups/cache clears/models/profiles/checkers/repairs/retries and working-branch pushes. Production,master,credential disclosure,IAM changes and additional spending stay excluded.
- **AWS suspended: no calls/resources.** Frozen conservative commitment$4.6495 is not invoice; ceiling$100 unchanged. No demonstrated net causal cloud testing-throughput benefit before suspension. DeepSeek ledger currently287 returned receipts/2,638,129 reported tokens, actual charge unknown and separate from AWS; deduplicate actual receipts, not prepared tasks.
- Preserve unique evidence and scientific oracles. Keep large builds/profiles/model products on cluster storage and compact summaries locally. Do not clean unrelated files. Do not replace missing final counters with sampled values or reinterpret failed/UNKNOWN receipts.
- Selected rollback: **e485/source0828**, `tools/cpu-working/PREVIOUS_SELECTION_E485.json` and `PREVIOUS_SOURCE_BUILD_BINDING_E485.json`, retaining identical375/881/825/faba/FIELDVIEW1/shared1/IB. HistoricalTEN322 nine-hour records remain preserved separately. Mode0 is not a qualified full-forecast rollback.
- Access gateway hpc00 at100.103.134.47 with existing HostKeyAlias/credentials privately. Recover actual unit/InvocationID and closure before retries. Agents own released complete lifecycles through closure; do not create waits between every preparation/stage/launch/collect step.

Continue measured investigations, close retain/reject decisions, promote worthwhile qualified work into the working branch and push it. Keep production/master unchanged.
