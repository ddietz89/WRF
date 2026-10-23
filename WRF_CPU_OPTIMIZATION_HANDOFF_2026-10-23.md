# WRF CPU optimization — continuation hand-off, October 23, 2026

Prepared during active work on October 23 UTC; live experiment snapshot at 10:25 UTC. This is a delta from WRF_CPU_OPTIMIZATION_HANDOFF_2026-10-19.md, whose current-selection section had been updated through October 21 and selected WRF3582 plus codec 9371. The older hand-off remains historical evidence. This document does not replace the detailed findings or transfer qualification between executable versions.

## 1. Resume here

- Repository: /home/ddietz/wrf/WRF; remote git@github.com:ddietz89/WRF.git; working branch perf/cpu-20261012.
- Last code/evidence HEAD before this hand-off: 63bc040d725ff621ebb4343dbf685eb88a6f7367, pushed and remote-verified. It closes the quota-period screen. The selected scientific executable is a separate artifact, identified below.
- Recovery authority: /home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/CURRENT_STATE.json. Read its newest active-root experiment fields and actual job records before any retry. Earlier keys can describe historical investigations.
- Governing procedure: TIMING_SOP.md and OPTIMIZATION_FINDINGS.md in this repository. The persistent campaign Goal is ACTIVE. A status, hand-off, failed candidate, successful test, commit or promotion is not a stopping point.
- Production and master remain excluded. /pool/wrf/WPS remains read-only. AWS remains SUSPENDED: no new AWS calls or resources.
- Finish the new U/V copy-fusion application qualification and worthwhile promotion. Finish the already prepared original/current world256 forecast pair. Continue actual MPI source investigation alongside incremental kernels; do not substitute a placement/settings sweep for MPI code work.

For compact paths below, C means /home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016; F means C/current13fe-lower-rank-throughput-dedup-r1/224compute-same-baseline-feasibility-r1; G means F/genuine256-native-authority-plan-r1; UV means C/portfolio-a-current79be-rk1-uv-copy-fusion-r1.

## 2. What is selected now

The working selection retains all earlier accepted compute, Thompson table/lifetime, input, codec, output and quilting improvements. Its current identities are:

| Identity | Actual value |
| --- | --- |
| Selected WRF executable SHA256 | 79bebebbfb646a367a7e62b8befcbe2c672225d2efc5f8d4d4f0743476ab2bf2 |
| Selected archive SHA256 | 1ade2c8fa3df604d077cbbeb0815ef246b0ba32aa8c480c8f4aa150d8cef12b2 |
| Post-test source tracking commit | 1f03a73849d0149161120d6ae130a9a66e9e0116 |
| Corrected-original scientific executable | 546b99156cbd809e1cae5e0ea8cebeea44dafd6331abf89e4daea00e0dd0a5e7 |
| Selected executable location | /pool/wrf-experiment/wrf-cpu/builds/current13fe-uv-u-nh-correction-simd-one-member-native-r1/wrf.exe |
| Selected archive location | Same directory, libwrflib.a |

Current 79be owns exact short two-product/35-step and three-hour four-product/545-step qualification. Its own noon, nine-hour, restart and profile qualification are not established. Earlier images' longer-horizon proofs remain scoped to those images. Raw build producer fields that were null remain null; later source-tracking commits are not retroactively treated as raw producer commits.

### Accepted additions since the prior current-selection hand-off

These are local/caller measurements under their named tests, not additive forecast percentages. Each accepted change has its own native and application evidence in tools/cpu-compute or tools/cpu-output and the findings.

| Addition | Measured local evidence / important scope |
| --- | --- |
| calc_php SIMD and open-boundary copy SIMD | Complete callers about 55.95–59.63% and 70.08–73.33% shorter; combined original three-hour science passed. Boundary module uses its qualified module-local SIMD flag. |
| Moist-theta producer and shortwave case-2 direct-CDF work | Accepted combined three-hour and daytime science; later shortwave optical producer SIMD also qualified. See the theta/SW and optical-producer evidence rather than inferring an isolated gain from forecast totals. |
| NH-X pressure-gradient ratio caching, consumer SIMD and isolated AVX2 helper | Distinct qualified mechanisms. The X consumer caller improved about 20.9%; the narrower private AVX2 consumer improved about 7.7–9.3%. Whole-module Zen 2 targeting was rejected, so the narrow helper preserves the local opportunity. |
| NH-Y pressure consumer SIMD | Complete HPG caller 35.72–36.85% shorter; exact native and original application checks passed. |
| Ordinary scalar-advection final consumers | Complete caller 22.93–24.19% shorter; fresh original three-hour qualification passed. |
| PD final-consumer SIMD | Complete caller 6.07–9.19% shorter; combined application accepted. |
| Compressed-result capacity reuse | Warm complete-provider-plus-owner-release wall 4.18–6.06% lower; exact compressed/raw/state and application checks passed. Selected output DSO is 8bee, separate from the new world256 experimental shim below. |
| Ordered PHY height rows and wider private AVX2 row | Ordered SSE2 complete-PHY gain about 1.56–1.66%; wider AVX2 standalone row 42.38–45.71% shorter, while complete-PHY totals were neutral/mixed. The exact local improvement was retained and qualified in the combined application rather than discarded because whole-stage noise was larger. |
| Coriolis U metric cache | Complete caller 0.80–1.22% shorter; qualified with the wider PHY helper. |
| Ordinary fifth-order X tendency consumer SIMD | Captured complete caller 17.09–17.83% shorter; original application and fresh three-hour comparison passed. |
| V-advection fifth-order Y-flux SIMD and skipped overwritten shortwave initialization | Complete callers about 25.0–25.2% and 39.0–39.6% shorter; combined original three-hour and subsequent daytime science passed. |
| add_a2a SIMD | Complete synthetic caller 55.81–55.91% shorter. Eight neighboring routines change generated code, so representative full-grid qualification, rather than a false neighbor-byte identity claim, supplies application acceptance. |
| RK1 temperature-copy fusion | Removes a separate snapshot traversal while retaining required stores; complete RK1 preparation caller 8.16–8.62% shorter. |
| Thompson REAL15 tendency bank | Removes 14 static allocation/free sites. Complete caller 0.25–0.49% shorter, essentially neutral/slightly positive. Accepted with the fresh combined three-hour science; no memory-capacity saving is claimed from this bank. |
| RK1 geopotential-copy fusion | Complete caller 7.23–7.93% shorter. Its guard preserves the original vertical copy extent; W snapshot and arithmetic remain. |
| U nonhydrostatic pressure-correction SIMD | Current 79be addition; captured complete UV caller 10.36–12.09% shorter. It is after DPn formation and is distinct from the rejected DPn interpolation. |

Each source/default promotion retains an explicit inverse and a rebuild/selection rollback. GNU13.3/qualified pure-MPI scopes are the authoritative scope; AOCC and Intel remain eligible experiments, without transferred qualification. A source guard lacking a DM_PARALLEL condition is not evidence that serial execution was tested.

## 3. Full-grid comparisons since the previous hand-off

All numbers below are whole combined configurations. Main-step elapsed includes communication and output backpressure; it is not integration CPU. Aggregate node CPU includes MPI spin. Whole model/MPI wall includes initialization, output and final writer drain. Client filesystem caches were cleared before the timed arms; server cache/load remained uncontrolled.

| Fresh three-hour pair | Model/MPI wall, original → combined | Main-step elapsed, original → combined | Aggregate CPU-s, original → combined |
| --- | --- | --- | --- |
| Ordinary consumers, bb65 | 980.207680 → 661.484224; 32.5159% lower | 757.688050 → 559.029630; 26.2190% lower | 449620.407146 → 320418.104722; 28.7359% less |
| Coriolis + wider PHY, 769 | 964.849634 → 659.136806; 31.6850% lower | 742.869680 → 555.449990; 25.2291% lower | 442089.053462 → 319400.643832; 27.7520% less |
| X5, 4adb | 824.177365 → 640.243832; 22.3172% lower | 607.316250 → 555.898960; 8.4663% lower | 371218.489792 → 311320.066538; 16.1356% less |
| VY + shortwave, a437 | 831.150893 → 638.376558; 23.1937% lower | 610.539530 → 554.898530; 9.1134% lower | 374060.951199 → 310676.786383; 16.9449% less |
| add_a2a, 7087 | 821.985931 → 659.368571; 19.7835% lower | 598.154780 → 557.023960; 6.8763% lower | 368750.239428 → 319850.766687; 13.2609% less |
| T-copy + REAL15, f272 | 819.292170 → 662.571286; 19.1288% lower | 596.585480 → 555.256950; 6.9275% lower | 367680.356847 → 321156.487294; 12.6533% less |
| Latest completed pair, 79be | 798.430250 → 638.924674; 19.9774% lower | 594.341810 → 554.727540; 6.6652% lower | 358152.909794 → 310564.250629; 13.2872% less |

These are distinct fixed-order original-first pairs, not repeated samples of one unchanged candidate. The original executable remains 546b; control runtime varied substantially. Differences between paired percentages do not demonstrate an attributable code regression. The latest optimized wall is about 638.9 seconds versus about 638.4 seconds for a437 in another epoch; neither those two observations nor wall-minus-main identifies an I/O or MPI cause.

Latest completed fresh nine-hour pair belongs to the older fbcd/8bee image, not current79be:

| Nine-hour measure | Corrected original | fbcd combined | Reduction |
| --- | ---: | ---: | ---: |
| Whole model/MPI wall | 2306.344228 s | 1825.229316 s | 20.8605% |
| Main-step elapsed | 2092.728550 s | 1730.649040 s | 17.3018% |
| Aggregate node CPU | 1132283.412013 CPU-s | 919086.074160 CPU-s | 18.8290% |

All ten products and 1625 ordered steps passed. This is one unprofiled pair, about 1.2636× single-forecast speed, without an isolated component, repeatability or concurrent-throughput claim. Later current79be has not inherited this nine-hour acceptance.

The latest 79be three-hour pair is about 1.24965× single-run speed. Neither 1.5× concurrent throughput nor 2× speed has been established. Do not select a noisier high control merely to claim the target, pool different epochs as repeats, or add component percentages.

A preceding 13fe three-hour candidate was interrupted by unattended host maintenance restarting its coordinator. The replacement invocation rejected the existing directory correctly. That failed attempt is retained; both later79be timing arms were run fresh. It is not a completed performance pair or a numerical failure.

## 4. MPI: actual code trials, settings trials and remaining gap

MPI code work was performed; recent code trials did not earn promotion. Preserve the distinctions below.

| Trial | Actual result / decision |
| --- | --- |
| Compact Waitall rewrite in genuine RSL | Complete asymmetric 480-rank packing/exchange/unpacking caller 0.887617377 → 0.889089860 s, 0.1659% longer; CPU 425.692453 → 426.418540 CPU-s. Raw/state passed in this pair. Earlier larger-message state limitations remain separate. Neutral; retain unpromoted. |
| Deferred XPOST/XCOMPLETE plus actual independent computation | Genuine-library/callee correctness passed. Four-host net caller 0.357648845 → 0.406082932 s, 13.5424% longer; CPU 1.411052 → 1.559132 CPU-s, 10.4943% more. Scoped exact checks passed. Hold WRF/generator integration; no demonstrated benefit. |
| Vector-aligned early/edge computation partition | All 21 finite/IEEE correctness cases passed. Complete callee cost was 7.03–7.23% higher across opposite-order pairs. Closed unpromoted; no alignment ladder. |
| TKE halo field deferral | Keep xkmh/xkhh in the first exchange; delay xkmv/xkhv until the existing later full exchange in uniformly eligible nonperiodic diff_opt=1 cases. Four-rank real-RSL protocol and typed compile checks passed. Four-host cost attempts failed original-path floating-state admission, including INEXACT; no accepted timing or generated-wrapper/forecast qualification. No check waiver or further warmup variant is planned. This is unqualified, not proven scientifically wrong. |
| Wide RSL copy directives | Intended mechanism absent: original memcpy calls remained. Closed before numerical/timing/application work; no flag/helper ladder. |
| Y-slab placement — settings, not source | Complete packed caller 54.91% faster, but actual same-build one-hour WRF 3.5570% higher wall, 8.7504% higher main elapsed and 3.9788% more CPU. Exact science passed. FABA remains default; no attributable slowdown cause established. |

The qualified noon request/profile diagnostic passed two products/185 steps, all 512 runtime checks, normal model/reader closures and both selected profile joins. It retained 25,932,224 request records. Selected ranks 122/386 each had 58,144 records, 95.9411% uniquely attributable; ambiguous records remain excluded. X/Y receive Wait sample-period weights were 24.40%/13.19% on 122 and 16.09%/22.71% on 386. These are selected-thread observations, not global removable wall fractions or wire latency.

The stack/request join conserves all 1391/1395 primary sample keys and weights. Local C/C2 witnesses include selected same-host receives with long waits, but exact peer-send matching and preceding-work causality remain incomplete. Captured libc build identity was unavailable: exact libc-function attribution is UNKNOWN. Actual WRF instruction ownership did identify allocation/free contexts in Thompson and copy calls in packing/unpacking/small-step preparation without claiming the libc implementation.

Evidence: tools/cpu-compute/current7087-mpi-diagnostic/README.md and its result JSONs. Next MPI work must target a distinct source-proven mechanism—packing/memory movement, necessary synchronization/message aggregation or actual delayed-peer work. Do not repeat placement/XPMEM/progress sweeps or create another broad observer framework merely because a wait is large. A new explicit caller-state support contract could be investigated only with new production evidence; do not disguise a failed clean-state gate with another warmup.

## 5. New code experiments completed during this continuation

### U/V RK1 snapshot fusion — worthwhile; application promotion pending

The original RK1 U1/V1 snapshots were separate traversals immediately preceding later save/coupling loops with the same respective bounds. The new variants move the literal snapshot store before the unchanged save/arithmetic body, under an RK1 branch outside the I loop. Required U1/V1 stores remain; RK2/3, current T/PH fusions, W copies, expression/operand order, compiler flags and public MOD remain.

Actual DeepSeek author/review calls were made. The first author declined despite supplied context; one 3147-byte literal-context repair returned usable exact edits. False reviewer claims about a missing U directive and V division were adjudicated against actual source; no arithmetic was changed to satisfy them.

Three variants—U-only, V-only and combined—passed the genuine-current full-module gate: 70 shared controls plus 9 U and 9 V cases, matching O0 with bounds and strict O2. Tests include paired NaN coefficient/data operand roles, defined physical outputs, readonly/guards and five-word state. A fresh parent reproduced current runtime sections/relocations; non-target functions/constants remain exact.

| Complete RK1 small_step_prep caller; 2048 calls | Parent | U-only | V-only | Combined |
| --- | ---: | ---: | ---: | ---: |
| hpc02, parent first | 1.295512 s | 1.153663 s; 10.9492% shorter | 1.146986 s; 11.4647% shorter | 1.081613 s; 16.5108% shorter |
| hpc03, reverse order | 1.318650 s | 1.177223 s; 10.7251% shorter | 1.186110 s; 10.0512% shorter | 1.043720 s; 20.8493% shorter |

All eight arms passed per-call and cross-host raw/state checks, their own cache boundaries and normal closures. Restores/checks are outside integer-clock call intervals. These are complete synthetic caller gains, not isolated-loop or forecast gains. Process CPU was recorded in the raw comparison; the table reports elapsed only.

Combined actual qualified object: ee83f15431c2ba7041daab446f2035c6357324c6245e0868733321c5cf8f0547. The parent is7493. Evidence is UV/{actual-native-r1,actual-caller-build-r1,ROOT_CALLER_TIMING.stdout}. Root has not yet promoted this candidate to the working selection.

Prepared, inactive next steps:

1. UV/one-member-artifact-preparation-r1: no WRF module compilation, replace only SmallStep member in actual79be archive, preserve the other583 ordered occurrences, link once. Inactive pins d8259f54e609a84ec97d19e4da4fca399da3cee9ae68116b5e06940ca8c69e84.
2. UV/canonical-promotion-preparation-r1: unapplied canonical source/Makefile patch and full inverse. A single WRF_SMALL_STEP_UV_COPY_FUSION default1 uses the existing GNU13.3/emptyOMPCPP/SmallStepSIMD/Zen2 guard; explicit0 plus rebuild restores the U/V schedule. No serial qualification is claimed.
3. UV/canonical-delivery-one-object-r1: actual Make/three-stage preprocessing plus one strict O2 object compile must reproduce qualified ee83 runtime semantics/public MOD. Inactive pins7f4ec8e02ea6ca793fc077432b4d8ed99c7766e720fd41e9f3fab622172848d8.
4. The minimal full512 two-history/35-step application adapter is prepared at /home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-current79be-uvcopy10m-runtime-r1, inactive manifest a8dd605c151a640f51595dc6e69189a941f243e581fdba3c76a349b6a56191fc. Instructions and protected-comparator proof are in UV/short-application-preparation-r1. It uses a retained qualified corrected-original546b oracle and existing512 I/O shims, not the experimental world256 shim. Bind actual new-image receipts only after the link; flags and child identities remain false/null until root release. Promote source/default/selection only after the actual application passes, then commit/push with rollback.

A worker-dispatch error briefly left this integration task idle: send_message to a completed worker did not restart it. Root restarted it with followup_task at10:08 UTC. Future new work must use followup_task and verify live status.

### Thompson mvd_g scalarization — exact; timing neutral; retained unpromoted

All23 executable uses in three graupel blocks assign the current K value before use. A local scalar replaces one automatic per-level array without arithmetic or lifetime-hoist changes. Actual GNU codegen removed one malloc/free pair:72→71 each, memset26 unchanged. The original eleven complete private-table caller cases matched202196 raw/state bytes exactly; public MOD is exact.

The first source declaration added one physical line, changing diagnostic source-line immediates/strings outside the target. Its evidence is retained. Same-line deliveryR2 uses a semicolon declaration, preserving those diagnostic/nonmerge bytes. A finite actual audit accepts only decoded direct-branch displacement changes to identical symbol+offset roles and exact referenced merge-literal values; it does not mask arbitrary instructions, diagnostic bytes or constants. R2 has no unresolved non-target difference.

R2 object f1c9baa70fa6e6d98ada9fcbab30b6bd265b341add7889171d21dfd7e912327c passed the same eleven cases and normal closure. Opposite-order whole 20,000-call tests measured2.061322780→2.065138357s on01 (0.1851% longer), and2.050408740→2.049014402s on04 (0.0680% shorter). All raw/state/cache/closure checks passed.

Decision: retain exact source/evidence, unpromoted in this batch. No significant caller saving is established; one small per-level temporary is not a demonstrated memory-capacity saving. This is not a scientific rejection or an attributable forecast-regression claim. No additional timing matrix is planned. Evidence: C/thompson-graupel-mvd-scalar-r1/same-line-delivery-r2/.

## 6. Architectural throughput investigation: genuine world256

Purpose: establish a fresh corrected-original/current comparison at 224 compute ranks plus 32 quilt ranks, using 64 physical cores per node. This is a throughput/capacity investigation, not an MPI code optimization or proof of equivalence to the512-rank decomposition. Prior cross-decomposition bitwise failures remain preserved; fresh original256 is the scientific reference for candidate256.

Map SHA1995060aa9f180035373425aee4ebfc5f2fad29f5b369b0ea968e17d915f463e uses physical0–63 on each host,224compute in8×28 and32quilt. Caps are100/100/100/104GiB, zero swap; qualified UCX rc,sm,self and ibp1s0f0:1, no TCP data or dual-rail claim.

### Actual native prerequisites now passed

- Genuine TPI224/14-per-NUMA private and shared modes passed on all four hosts,256 real identities and 16 actual cohorts. The current module/helpers remained unchanged. Both modes had 2688 matched module creates/destroys and 3136 strict scoped records, with full table/publication/readonly/state checks. Summary SHA8530f4e82ba9bf5011cc2325ee7c45203aed311402a675195295714d6db4fa41. This is native ownership qualification, not a WRF memory or throughput result.
- New world256 input/output authority ports were built without changing production libraries. Initial native attempts exposed genuine harness defects: cgroup slash slicing, ET_EXEC/PLT owner attribution (fixed with PIE), and unfair reuse of the same output file. Those failed runs remain failed with actual four-host closures.
- Fair separate output files still exposed a real API floating-state difference: ordinary compression added SSE INEXACT while the precompressed path did not. Actual825 HDF filter assembly contains inexact-capable floating size arithmetic before compress2; this supports a mechanism but is not a complete dynamic instruction attribution.
- A new conservative shim admission fixes that support boundary: capture actual caller flags/MXCSR before activation; when SSE INEXACT is clear, forward exactly once to the original public put before begin/provider/workers. Do not fabricate or clear flags. Separate clean, x87-only, SSE-only and both-set cases retain hard before/after five-state equality and full raw/HDF/extent/error checks. Positive cases require actual workers, preventing a fallback-only false pass.
- All 256 real ranks and all four writers completed. Each writer passed 12 paired output API records, 6 pre-begin fallbacks and 4 supplied callbacks/16 real worker creations with balanced lifetimes. A final log validator compared cgroup-relative and absolute paths incorrectly; a separately normally closed read-only replay corrected only that representation comparison. No MPI rerun or original-file rewrite occurred. The original failed validator result remains retained.
- Derived strict NC summary SHA82143a41b39bbce2140a804ccfd1241de9c48ab7edde13fcebda4d231cf40267. New experimental output DSO b756513ac40ccf7d94f5dd2cdffaf78af88c3928755a005d4046d847add06c3b at /pool/wrf-experiment/wrf-cpu/kernels/world256-output-fp-admission-build-hpc01-r1/work/liboutput_world256_fp.so. Input DSO66667e7f remains unchanged. Old95eb output is retained as baseline only, not used to qualify the new port.

Evidence: G/output-fp-admission-investigation-r1/{compile-only-build-r1,fourhost-native-r6,readonly-validator-replay-r1}. The source-only and literal independent DeepSeek reviews were actually dispatched; false claims and local finite repairs are retained, not described as external certification.

### Actual forecast state at this hand-off

Package F/same256-wrf10m-pair-preparation-r1/runtime-r1 is root-activated, staged and preflighted. Manifest881465d366d532922cb687380544b8327f55ad93c0d51995125045565f36e602 binds newb756 and both actual NC/TPI summaries in both leases. Own scientific, memory-admission and dual-job qualification remain FALSE.

Fresh original256 control was launched after all four checked cache clears:

- Run: production256-current79be-same10m-control-r1.
- Coordinator unit: wrf-cpu-production256-current79be-same10m-control-hpc01-r1.service.
- Actual invocations:01 81a06661e39246bd91c8df1bec66ee84;02 d508351fa66748aaa190bf40353bf5a6;03 28fb8a6e5ebc49a387e4b4a8425e4cfd;04 266a6c24c50743f2b809c07fdad7d59d.
- Control completed both products and 35 ordered steps through06:10. Root reconciled all four actual normal model closures at10:19UTC: matching invocation IDs, successful actual worker exits, no remaining processes/cgroups. Status is EXECUTED_PENDING_SAME256_ORIGINAL_TWO_HISTORY_COMPARISON. Collected manager exit fields that were unavailable remain null, separate from actual worker exit0; see ROOT_RECONCILE_CONTROL.stdout.
- Candidate256 preparation passed with explicit79be identity; its granted lease SHA is728c0b219871183804dbd0e625f34d8a289e5dfb25b2348380e7ca7bc0b3ab8e. All four checked cache clears passed at10:23UTC, then the candidate actually launched. Coordinator invocation b722ae07b7434f299982f76e3757fc43, PID4101827, unit wrf-cpu-production256-current79be-same10m-candidate-hpc01-r1.service. Early RSL confirms the8×28 decomposition, four eight-task quilt groups, qualified IB transport and initial-data admission. It is still running at this snapshot; neither a new world256 science pass nor a timing/peak/dual-throughput result is established yet.

Continue with the existing scripts: monitor the actual candidate invocation, reconcile candidate after positive closure, launch the unchanged exact reader only after all eight model scopes close, then collect_results.py. Both arms' preparation/clears/launch and control reconciliation are already complete: do not duplicate them. Compare both complete products and 35 ordered steps, metadata/layout and actual256 runtime/tile/writer acceptance. For the two-output case, roots231/239 are positive and247/255 inactive; all 32 quilt identities still matter.

Do not admit two forecasts by summing individual peaks. Own memory behavior at a representative horizon and the actual concurrent makespan/CPU/science must precede a throughput claim. A fast short forecast is not 1.5× or 2× measured throughput.

## 7. Other closed or rejected work since the prior hand-off

The detailed findings and per-candidate JSON are authoritative. Preserve failure categories: numerical failure, absent generated mechanism, measured cost, unresolved qualification and duplicate investigation are different conclusions.

- calc_cq and SUMFLUX directive variants: hard O2 raw/state failures; no timing/application promotion.
- Broad BigStep Zen2 flags: useful HPG local gain, but other PHY exact checks failed. Kept the opportunity through the narrower accepted helper; rejected the broad flag configuration.
- V/VO3 metric cache and deformation pass fusion: targeted dual-NaN payload failures; rejected without relaxing science.
- MYJPBL initial grid directive: remained scalar. Optional-QCI unswitch produced packed work but failed directed-rounding/subnormal exact output. Closed both fixed implementations.
- VDIFH backsolve SIMD: native exact, but full MYJ slower0.62–1.41% and direct result mixed. Closed unpromoted, without calling a forecast regression.
- Paired Thompson RSLF polynomial helper: native exact but complete compT about14.1–14.6% slower. Closed unpromoted.
- Thompson guaranteed-zero allocation: GNU still emitted malloc plus37 memset calls over1095200bytes; proposed lazy-zero mechanism absent.
- Horizontal-diffusion metric cache: no useful measured complete-caller benefit; closed. Plain time-level ownership swap was semantically invalid because later RK preparation and history/restart aliases still consume both physical levels.
- Two-tile X orientation: actual exact science failed; retain the two-Y-tile default.
- Payload nonblocking gather, tree run-descriptor replay and several reissued producer directives: retained scoped negative/absent-mechanism results. Do not repeat without a new source or measured mechanism.
- CPU quota-period reverse screen: original approximately5% forward signal did not reproduce. Current 79be1s-first versus100ms-second wall119.373628/119.642381s, main36.818790/36.904000s, CPU45400.410216/45205.085056CPU-s; both exact two-product/35-step runs and all closures passed. Keep100 ms default; no further period run planned. Earlier host-maintenance context remains disclosed.

## 8. Execution, permissions and cost rules

Standing owner authorization covers project preparation/staging/readiness, bounded transient jobs/cgroups/profiling/cache clears/model runs/validation/repairs/retries on hpc00–04, actual project DeepSeek exports and working-branch commits/pushes. Do not ask for the same grant again. If normal automatic review rejects a specific action, report the exact rejection and use the five-minute approval/fallback procedure; never bypass review. Production/master, credential disclosure, scientific algorithm changes without separate approval, AWS resumption and additional spending remain excluded.

DeepSeek endpoint https://api.deepseek.com, model deepseek/deepseek-flash, tools denied,240seconds per call. Keep credentials and scientific arrays out. C/DEEPSEEK_USAGE.json currently records692 actual returned receipts and 7,459,991 reported tokens; provider dollar billing is unknown and separate from AWS. Receipts, not prepared packets, count as offloading.

AWS remains suspended; the frozen conservative commitment is $4.6495, not a settled invoice. Do not resume cloud/IAM work or spend against the $100 authorization without the owner's renewed instruction.

Cache policy: checked sync/drop_caches3 before every separately timed arm, after all affected model/reader/helper scopes positively close. Serialize shared-node cache maintenance with all active work; use explicit affinity/cgroup CPU/memory/swap/runtime limits. Four-node authoritative timing remains exclusive. Keep unprofiled final comparisons and short native/caller iterations; no broad acceptance/compiler matrix.

Transport: qualified single InfiniBand interface ibp1s0f0:1 with UCX rc,sm,self; MEMLOCK infinity on native/model jobs. TCP is not the data transport. No dual-rail qualification is claimed. hpc00 supports metadata/Python work but cannot execute the qualified GNU13 MPI compiler because of its GLIBC requirements.

Session holder: C/current79be-experiment-wave-20261023-r1-session-hold/STATUS.json; foreground exec 51537, all four real SSH/PAM sessions were ready. It started about09:40UTC with a10800-second bound. Old holder 73415 was released only after all old scopes closed and the replacement was ready. Recheck liveness; do not release the last sessions during MPI. Release only after all model/reader/helper scopes close, using the existing exact release-file protocol. Do not change global PAM/RemoveIPC settings.

Local root filesystem cleanup supplied about 181 GiB free at the start of this continuation. Preserve unique scientific/evidence artifacts; do not delete unrelated active work. Shell tool calls currently require the normal require_escalated route because default bwrap execution fails; this is an environment constraint, not authority to bypass approvals.

## 9. Immediate continuation checklist

1. Control256 is completed and all four closures reconciled. Candidate256 is running under invocation b722ae07b7434f299982f76e3757fc43; finish its actual closure/reconciliation and original exact reader. Preserve all honest failures. Do not start a duplicate uncertain job.
2. Execute the already prepared U/V one-member link and canonical delivery once node timing scopes are closed. Activate the prepared fresh512 short application adapter only after binding actual linked-image receipts; finish actual exact science, worthwhile source/default selection and rollback documentation. Commit/push the working branch.
3. Keep Thompson scalarization exact evidence but unpromoted; its complete-caller result is neutral. No further matrix is justified now.
4. Keep MPI source investigation active. Two attempts to start a fresh Codex MPI worker hit the agent-thread limit; they did not start a worker. Root must perform this bounded source analysis or offload it directly, rather than falsely claiming a background stream. Existing advection/profile workers completed the U/V delivery and application preparation; no unstarted task should be described as running.
5. Use the shortest meaningful new source/caller test. Retain significant exact-qualified local gains even when individually below full-run variation, unless a concrete exclusion is demonstrated. Do not mistake settings experiments or extra reporting machinery for code progress.
6. Run the next periodic original three-hour combined qualification after worthwhile new additions are actually integrated. Select nine-hour work for sustained/daytime/repeatability questions, not for every small candidate. Report wall, main-step elapsed and aggregate CPU together.
7. Maintain consolidated findings and current recovery state, continue the active Goal, and provide new-progress updates. Writing this hand-off does not close the campaign.
