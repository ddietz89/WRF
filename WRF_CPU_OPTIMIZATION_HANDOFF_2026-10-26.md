# WRF CPU campaign hand-off — October 26, 2026

## Governing state

Continue the existing campaign on `perf/cpu-20261012`. Read `TIMING_SOP.md`, `OPTIMIZATION_FINDINGS.md`, `tools/cpu-working/selection.json` and the private campaign `CURRENT_STATE.json` before acting. The persistent Goal is active. A result, negative experiment, promotion or hand-off is not a stopping point.

DeepSeek and AWS are suspended. Use local Codex agents and hpc00–04. Run qualified GNU13 native work on hpc01–04; hpc00 is limited to timing-insensitive metadata/portable tools because its older GLIBC cannot run that toolchain. Production and master remain excluded. Preserve the original exact checker, metadata/layout, ordered steps, FP/exception state and supported source guards. Never enable fast math. Clear caches before every timing invocation; record normal closure before a dependent clear or launch. Use qualified UCX shared memory/InfiniBand, explicit affinity and existing cgroup limits. Monitor voltages, temperatures and fans before/during/after model load. Keep large artifacts on cluster storage.

## Selected build and newest experiment

The authoritative selected executable, archive, source correspondence and application qualifications are in `tools/cpu-working/selection.json` and `CURRENT_SOURCE_BUILD_BINDING.json`; their bytes must agree. Source correspondence uses tested preprocessed source/cached objects plus post-test canonical target projection. No clean whole-source rebuild certificate is claimed.

Selected image `03fa935c` / archive `bd1ac8a4` / post-test source `77ce9db9` retains all prior improvements and adds the guarded SW cloud final consumer over parentccbe. The genuine complete generator caller, including eight full output restores, was 2.5126% and 3.9780% shorter on hpc01/02, with matching CPU reductions. Actual GNU13.3 O2 code remains scalar; the directive does not establish a SIMD gain. See `tools/cpu-compute/sw-cloud-consumer-20261027/` for the native, scoped machine, caller, source and application records. No separate or additive forecast gain is established.

This child owns instrumented noon12–13 qualification only: exactly185 ordered steps and two full products, with all model and reader scopes normally closed. Three actual15-second main-thread profiles on hpc03 ranks114/122/386 passed acquisition, identity and parsing checks; they do not establish global shares or a causal critical path. Own unprofiled noon, three-hour, nine-hour, restart and full144-hour qualifications remain false. The current03fa three-hour package is PREPARING, not qualified. Parentccbe/source1872 owns the last unprofiled three-hour545/four-full result; earlier parent results remain historical and do not transfer to03fa. The original75-minute noon reference supports exact science-prefix comparison only, with no timing percentage claim.

The qualified strict GNU13.3/defaultREAL4INT4/pure-MPI consumer guard uses the existing read-only mask helper once; unmasked exceptions select the literal original fallback. `WRF_SW_CLOUD_CONSUMER=0` plus regeneration, SW member compilation, rearchiving and relinking opts out. Existing MW/AdvectW/PHY guards and opt-outs remain authoritative. Parentccbe/archive8d1d is the whole-image rollback. Raw32-MOD equality remains false:25including the generator target are exact, and exactly seven wrappers have verified serialized definition-ID permutations only. All typed bodies, attributes, edges and public aliases remain hard; no MOD bytes were rewritten. The raw historical THOMPSON/unprofiled checker label is retained verbatim and annotated with actual03fa instrumented lease/build identity.

MW R1's raw MOD failure and R2's scalar-tail NaN payload failure are retained. R3 uses only complete four-lane prefixes plus the original scalar remainder and passes all 128 cases at both O2/O0. Raw MW MOD equality remains false: exactly three conservative GNU13.3 compiler dependency-analysis bits were admitted, with all other typed tokens unchanged, for the proven non-elemental/direct-call route. This is not a global rebuilt-caller ABI certificate or a rewritten MOD. AdvectW's first genuine NaN failure is also retained; its full-eight-prefix repair passes 80 comparisons per optimization with the original MOD exact. Production O2 containment is scoped; O0 non-target code is not generally classified. Canonical correspondence is a post-test target projection to the tested preprocessed sources/cached objects, not a clean whole-source rebuild or a raw producer commit.

## Recent full-grid evidence

| Observation | Wall minutes | Main-step elapsed minutes | Aggregate CPU core-hours | Exact science |
|---|---:|---:|---:|---|
| Original three-hour median, three distinct controls | 13.33374 | 9.94084 | 99.81315 | Retained original references |
| Prior parent56d2 three-hour | 10.36987 | 8.97816 | 84.00883 | Four full products /545 steps pass |
| Historical parent da1c three-hour | 10.46069 | 9.04669 | 84.58097 | Four full products /545 steps pass |
| Historical parent33a2 three-hour | 10.67923 | 9.03276 | 86.64113 | Four full products /545 steps pass |
| Historical parentccbe joint three-hour | 10.42766 | 9.04823 | 84.51915 | Four full products /545 steps pass |
| Fresh original nine-hour, n=1 | 34.15724 | 30.84597 | 278.15747 | Ten full products /1625 steps pass |
| Earlier parent3f86 nine-hour, n=1 | 29.44540 | 28.10415 | 247.06853 | Ten full products /1625 steps pass |

Historical parentccbe metrics are wall **625.659422053 s**, main-step elapsed **542.89388 s**, and aggregate CPU **304268.93518 s**. Descriptive reductions from the retained three-control median are **21.794930% wall, 8.979215% main-step elapsed, and 15.322633% aggregate CPU**. These are unpaired comparisons; they do not isolate either new kernel. Main-step elapsed includes waiting and communication. Nine-hour observations belong to their named images and do not qualify03fa. Historical matched A–B–B–A three-hour mean reductions were 21.8975% wall / 9.3585% main / 15.6218% CPU for image0b40.

This observation is about 1.28× single-forecast wall speed against the stated historical median; the 2× speedup goal remains unmet. The separate 1.5× throughput goal still needs matched completed-work/makespan evidence, including any proposed concurrency. Never add kernel percentages or substitute concurrent throughput for latency.

## Retained improvements

The current selection retains prior advection/pressure/coefficient caching and SIMD, mass-update and SmallStep row pipelines/copy fusion, scalar tendency work, physics-preparation passes, radiation/MCICA improvements, supported MYJPBL and Thompson scratch/memory changes, RSL wide-copy/unpack changes, and the qualified input/output provider and codec work. Component-specific guards, opt-outs and evidence remain authoritative; this list does not extend compiler/ISA/thread/workload support.

Recent additions:

- Guarded mass_weight and AdvectW X5 prefix SIMD: genuine whole-callee O2/O0 and complete restore-inclusive caller checks passed, followed by the joint ccbe three-hour qualification above. Per-component native, machine, caller, failure and rollback records remain separate from the joint application result.

- `calc_alt` pointwise SIMD: complete caller41.94–42.02% shorter with matching CPU and exact O2/O0 checks. Qualified default with original fallback and `WRF_CALC_ALT_SIMD=0` opt-out.
- Paired-shortwave stack scratch: removes two allocations for1–33layers;34+ retains original allocation fallback; complete caller near-flat0.13–0.27% reductions. Own three-hour and daylight science passed. Qualified default with `WRF_SW_VRTQDR_PAIR_FIXED_STACK=0` opt-out. Earlier BLOCK kernel gains do not transfer to this separate implementation.
- SPC current-column trial: four scratch arrays request60,928→544bytes at33levels. Allocations remain four. First caller wave was mixed; the single reversed-order repeat had0.59/0.69% wall reductions and near-flat CPU. No significant CPU, RSS or forecast gain is established. Own daylight proof passed and the supported default is enabled; opt-out is `WRF_SW_SPC_SINGLE_COLUMN=0` plus regenerate/rebuild/relink.

## Closed or held candidates — preserve evidence

| Candidate | Decision and concrete evidence |
|---|---|
| Reflectivity fixed33 R4 | Exact native checks pass; complete caller3.01% slower on01 and0.60% faster on02, CPU agrees. Closed unpromoted; no independent gain/RSS claim. Earlier failures retained. |
| Shortwave BLOCK R1 | Genuine caller0.36/0.51% slower despite earlier extracted-kernel gain. Closed; separate qualified R2 stack path retained. |
| Thompson warm quotient | Native exact, caller signs mixed; closed without application. |
| Heating halo combination | Physical values match but the candidate FP-state mismatch persists after identical warmups; original repeat instability explains only errno. Held unqualified without timing. |
| Deformation output-pair fusion | Source counterexample changes partial-store ordering at an unmasked overflow; masked fixtures do not cover that contract. Held before native work, not a forecast-science failure. |
| Disabled FDDA whole halo omission | Surviving AFWA height calculation consumes outer width3 ghost values. Whole skip closed. ODIS-only subset is about2.8–2.9% of field payload and removes no exchange; closed on limited opportunity. |
| PD masked-scale variant84ad | Large extracted-kernel gain, but the same variant's captured whole caller is2.42/3.64% slower; all captured blocks were inactive. Own three-hour science exact. Unpromoted because of measured caller cost, not noisy forecast timing. Reopen only with new activity/cost evidence. |
| Additional evaporation-table sharing | Nominal0.618GiB/node opportunity, but later same-mode/native tests fail errno34→11. Held; old not-implemented notes are stale. |
| Original large-page advice probe | All four mappings were ineligible from virtual/file-offset incongruence; zero advice calls. It did not measure a hugepage or TLB gain. |
| Cross-forecast sharing | Small OS primitive works; WRF integration/admission and actual capacity benefit remain unqualified. Prior throughput screen was negative on three hosts. |

Do not repeat these fixed candidates without new measured evidence. Retain significant exact-qualified kernel gains while remaining caller/application checks are completed. Missing whole-forecast gain alone is not an exclusion. Promotion still requires exact acceptance; exclusions need concrete cost, correctness or maintenance evidence.

## Work in progress and next useful questions

1. The SW cloud consumer is selected as03fa/source77ce after exact own instrumented noon185/two-full science and three-rank profile parsing. Its full-generator caller gains are2.51/3.98%; no forecast gain is inferred. The new03fa periodic three-hour runtime is PREPARING under root ownership; no own3h/9h qualification transfers from ccbe. Continue measured-source triage from the actual current profiles. DeepSeek and AWS remain suspended.
2. MW and AdvectW are completed, retained components inherited from parentccbe/source1872, not work in progress. The unused MW-only image c5d8 has no own application qualification.
3. Both MPI prototypes remain unqualified on strict saved-state differences despite exact field/corner records. Early/late U/V reuse and adjacent diagnostic-phase combination retain their failures and no gain claim. A narrow MPI-only errno/sticky-inexact policy question is pending owner review; no dependent qualification changes or tests until answered. Preserve all other exact numerical/control/state and original forecast checks. Continue periodic3h and selected9h qualification at meaningful combined milestones.

4. MYJ source/count observation and Thompson congruent-alias caller work are closed. No safe new MYJ deletion was established. The alias capability worked, but its complete caller was mixed with no demonstrated resource gain; it remains unpromoted. See the existing profile and rejected-candidate components. Do not repeat either fixed investigation without new evidence.

Private recovery root: `/home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/`. Own selected-child instrumented noon runtime: `/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-ccbe-sw-consumer-day15-runtime-r3/`. The new03fa three-hour runtime remains PREPARING; use current campaign state for its live preparation path. Preserve exact invocation IDs and receipts in those directories before retrying uncertain jobs.

