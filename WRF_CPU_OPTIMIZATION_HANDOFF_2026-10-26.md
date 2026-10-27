# WRF CPU campaign hand-off — October 26, 2026

## Governing state

Continue the existing campaign on `perf/cpu-20261012`. Read `TIMING_SOP.md`, `OPTIMIZATION_FINDINGS.md`, `tools/cpu-working/selection.json` and the private campaign `CURRENT_STATE.json` before acting. The persistent Goal is active. A result, negative experiment, promotion or hand-off is not a stopping point.

DeepSeek and AWS are suspended. Use local Codex agents and hpc00–04. Run qualified GNU13 native work on hpc01–04; hpc00 is limited to timing-insensitive metadata/portable tools because its older GLIBC cannot run that toolchain. Production and master remain excluded. Preserve the original exact checker, metadata/layout, ordered steps, FP/exception state and supported source guards. Never enable fast math. Clear caches before every timing invocation; record normal closure before a dependent clear or launch. Use qualified UCX shared memory/InfiniBand, explicit affinity and existing cgroup limits. Monitor voltages, temperatures and fans before/during/after model load. Keep large artifacts on cluster storage.

## Selected build and newest experiment

The authoritative selected executable, archive, source correspondence and application qualifications are in `tools/cpu-working/selection.json` and `CURRENT_SOURCE_BUILD_BINDING.json`; their bytes must agree. Source correspondence uses tested preprocessed source/cached objects plus post-test canonical target projection. No clean whole-source rebuild certificate is claimed.

Selected image `ccbe6128` / archive `8d1dbcf4` / post-test source `1872ec9a` retains all prior improvements, including guarded PHY interpolation, and adds guarded `mass_weight` and AdvectW X5 SIMD. Both complete callers include mutable restores: mass_weight was 31.9237% and 32.1409% shorter on hpc01/02; AdvectW was 20.6758% and 20.4636% shorter on hpc01/04, with matching CPU reductions. Own unprofiled three-hour science passed exactly for all four full products and 545 ordered steps; all model and reader scopes closed normally. See `tools/cpu-compute/mass-weight-advectw-batch-20261027/` and its two component references. These caller results do not establish separate or additive forecast gains.

This child owns three-hour qualification only. Its noon, nine-hour, profile, restart and full144-hour qualifications remain false. Parent33a2/source4c9 owns its historical three-hour result; historical330d/source6311 owns its noon185/two-full check. Neither qualification transfers to ccbe. The qualified strict GNU13.3/defaultREAL4INT4/pure-MPI paths reuse the existing read-only mask helper once. Any unmasked hardware exception selects the literal scalar fallback. `WRF_MASS_WEIGHT_SIMD=0` or `WRF_ADVECT_W_X5_SIMD=0`, followed by regeneration, member compilation, rearchiving and relinking, opts out of that feature. Retained33a2/archive5b482a is the whole-image rollback.

MW R1's raw MOD failure and R2's scalar-tail NaN payload failure are retained. R3 uses only complete four-lane prefixes plus the original scalar remainder and passes all 128 cases at both O2/O0. Raw MW MOD equality remains false: exactly three conservative GNU13.3 compiler dependency-analysis bits were admitted, with all other typed tokens unchanged, for the proven non-elemental/direct-call route. This is not a global rebuilt-caller ABI certificate or a rewritten MOD. AdvectW's first genuine NaN failure is also retained; its full-eight-prefix repair passes 80 comparisons per optimization with the original MOD exact. Production O2 containment is scoped; O0 non-target code is not generally classified. Canonical correspondence is a post-test target projection to the tested preprocessed sources/cached objects, not a clean whole-source rebuild or a raw producer commit.

## Recent full-grid evidence

| Observation | Wall minutes | Main-step elapsed minutes | Aggregate CPU core-hours | Exact science |
|---|---:|---:|---:|---|
| Original three-hour median, three distinct controls | 13.33374 | 9.94084 | 99.81315 | Retained original references |
| Prior parent56d2 three-hour | 10.36987 | 8.97816 | 84.00883 | Four full products /545 steps pass |
| Historical parent da1c three-hour | 10.46069 | 9.04669 | 84.58097 | Four full products /545 steps pass |
| Historical parent33a2 three-hour | 10.67923 | 9.03276 | 86.64113 | Four full products /545 steps pass |
| Latest ccbe joint three-hour | 10.42766 | 9.04823 | 84.51915 | Four full products /545 steps pass |
| Fresh original nine-hour, n=1 | 34.15724 | 30.84597 | 278.15747 | Ten full products /1625 steps pass |
| Earlier parent3f86 nine-hour, n=1 | 29.44540 | 28.10415 | 247.06853 | Ten full products /1625 steps pass |

Latest ccbe metrics are wall **625.659422053 s**, main-step elapsed **542.89388 s**, and aggregate CPU **304268.93518 s**. Descriptive reductions from the retained three-control median are **21.794930% wall, 8.979215% main-step elapsed, and 15.322633% aggregate CPU**. These are unpaired comparisons; they do not isolate either new kernel. Main-step elapsed includes waiting and communication. Nine-hour observations belong to their named images and do not qualify ccbe. Historical matched A–B–B–A three-hour mean reductions were 21.8975% wall / 9.3585% main / 15.6218% CPU for image0b40.

The single-forecast 1.5× and 2× goals remain unmet. This observation is about 1.28× wall speed against the stated historical median. Never add kernel percentages or substitute concurrent throughput for latency.

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

1. The next SW cloud-consumer candidate has passed genuine native R2 and scoped machine review. Its driver build closed normally (INV `0f93f4f19b9a4d8f867e9871c2e6278b`); root's complete-caller wave, session `91511`, is running on hpc01/02. Actual full-caller cost and any retention decision remain pending. Its earlier metadata failure and standalone results remain distinct. DeepSeek and AWS remain suspended; root owns node launches and defaults.
2. MW and AdvectW are completed, selected components of ccbe/source1872, not work in progress. The unused MW-only image c5d8 has no own application qualification.
3. Both MPI prototypes remain unqualified on strict saved-state differences despite exact field/corner records. Early/late U/V reuse and adjacent diagnostic-phase combination retain their failures and no gain claim. A narrow MPI-only errno/sticky-inexact policy question is pending owner review; no dependent qualification changes or tests until answered. Preserve all other exact numerical/control/state and original forecast checks. Continue periodic3h and selected9h qualification at meaningful combined milestones.

4. MYJ source/count observation and Thompson congruent-alias caller work are closed. No safe new MYJ deletion was established. The alias capability worked, but its complete caller was mixed with no demonstrated resource gain; it remains unpromoted. See the existing profile and rejected-candidate components. Do not repeat either fixed investigation without new evidence.

Private recovery root: `/home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/`. Own selected-child runtime: `/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-33a2-mw-advectw-batch-3h-runtime-r1/`. Preserve exact invocation IDs and receipts in those directories before retrying uncertain jobs.

