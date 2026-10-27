# WRF CPU campaign hand-off — October 26, 2026

## Governing state

Continue the existing campaign on `perf/cpu-20261012`. Read `TIMING_SOP.md`, `OPTIMIZATION_FINDINGS.md`, `tools/cpu-working/selection.json` and the private campaign `CURRENT_STATE.json` before acting. The persistent Goal is active. A result, negative experiment, promotion or hand-off is not a stopping point.

DeepSeek and AWS are suspended. Use local Codex agents and hpc00–04. Run qualified GNU13 native work on hpc01–04; hpc00 is limited to timing-insensitive metadata/portable tools because its older GLIBC cannot run that toolchain. Production and master remain excluded. Preserve the original exact checker, metadata/layout, ordered steps, FP/exception state and supported source guards. Never enable fast math. Clear caches before every timing invocation; record normal closure before a dependent clear or launch. Use qualified UCX shared memory/InfiniBand, explicit affinity and existing cgroup limits. Monitor voltages, temperatures and fans before/during/after model load. Keep large artifacts on cluster storage.

## Selected build and newest experiment

The authoritative selected executable, archive, source correspondence and application qualifications are in `tools/cpu-working/selection.json` and `CURRENT_SOURCE_BUILD_BINDING.json`; their bytes must agree. Source correspondence uses tested preprocessed source/cached objects plus post-test canonical target projection. No clean whole-source rebuild certificate is claimed.

Selected image `330db1c1` / archive `b3794efe` / post-test source `6311634d` retains all preceding improvements and replaces two pre-delta beam scratch arrays in SPCVMC with scalars. Complete-caller wall reductions were0.6276/0.9271% and threadCPU reductions1.1468/0.9513% on hpc01/02. Its own unprofiled noon185/two-full original science passed; all model and reader scopes closed. See `tools/cpu-compute/spcvmc-predelta-beam-scalars-20261026/` for scope and rollback.

The child owns noon qualification only: its three-hour, nine-hour, profile, restart and full144-hour qualifications remain false. Historical da1c/source d501 owns its three-hour545/four-full, noon185/two-full and subsequent two15-second source/count captures. Those observations remain attributed to da1c. Both builds use qualified GNU13.3/defaultREAL4INT4/strictO2/pure-MPI support guards and original fallbacks.

## Recent full-grid evidence

| Observation | Wall minutes | Main-step elapsed minutes | Aggregate CPU core-hours | Exact science |
|---|---:|---:|---:|---|
| Original three-hour median, three distinct controls | 13.33374 | 9.94084 | 99.81315 | Retained original references |
| Prior parent56d2 three-hour | 10.36987 | 8.97816 | 84.00883 | Four full products /545 steps pass |
| Historical parent da1c three-hour | 10.46069 | 9.04669 | 84.58097 | Four full products /545 steps pass |
| Fresh original nine-hour, n=1 | 34.15724 | 30.84597 | 278.15747 | Ten full products /1625 steps pass |
| Earlier parent3f86 nine-hour, n=1 | 29.44540 | 28.10415 | 247.06853 | Ten full products /1625 steps pass |

The latest selected build's descriptive reductions from the retained three-control median are21.5472% wall,8.9947% main-step elapsed and15.2607% aggregateCPU. These are unpaired comparisons; no incremental SPC forecast benefit follows. Main-step elapsed includes waiting and communication and is not integration CPU time. Nine-hour observations belong to their named images; they do not qualify the newer child. Historical matched A–B–B–A three-hour mean reductions were21.8975% wall/9.3585% main/15.6218% CPU for image0b40.

Single-forecast goals remain1.5× and2×. Approximately1.27–1.29× observed three-hour wall speed does not meet either goal. Do not add kernel percentages or substitute concurrent throughput for latency.

## Retained improvements

The current selection retains prior advection/pressure/coefficient caching and SIMD, mass-update and SmallStep row pipelines/copy fusion, scalar tendency work, physics-preparation passes, radiation/MCICA improvements, supported MYJPBL and Thompson scratch/memory changes, RSL wide-copy/unpack changes, and the qualified input/output provider and codec work. Component-specific guards, opt-outs and evidence remain authoritative; this list does not extend compiler/ISA/thread/workload support.

Recent additions:

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

1. SPC own daylight science passed; source/default and coupled metadata are promoted. Preserve both caller waves and the modest capacity claim; rollback is56d2/b88f or the SPC opt-out plus regeneration/rebuild/relink. Continue the next measured investigations after committing/pushing this closeout.
2. MYJPBL: current source audit found no safe deletion in required species/RHOK/coefficient copies or the three ZINT phases. The two-second synthetic four-counter admission reached actual hpc03 execution but perf rejected the L2 alias before running the synthetic target. Its failed scope is closed and preserved; actual perf/AMD/Linux definitions identify the correct alias `l2_cache_req_stat.ls_rd_blk_c` (event0x64/umask0x08), and the corrected two-second hpc03 admission passed all four grouped events at100.0% running without scaling. The earlier02controller failed before launch on a service-list bullet and remains preserved. Support is now established onhpc03; prepare one short current-build observation using the existing collector. Rank/window counter totals cannot attribute stalls to exact loops; ordinary event sampling has skid, IBS is unqualified. Do not build another general observer framework.
3. Shared-table alignment: a new C-only congruent-alias design may make the existing DATA mapping eligible for2MiB pages without moving MPI's original pointer or changing host settings. It needs explicit published-view ownership, full bytes/state after staging release, cleanup before Win_free and actual reader PMD evidence. The finite synthetic returned-view fixture built normally on hpc02 and its four-rank native test passed values/state/shape/staging-release/ownership/cleanup. All four readers consumed the alias; each successful collapse was followed by66MiB ShmemPmdMapped in its VMA snapshot. These are per-rank VMA observations, not exact page-by-page DATA/TLB or performance proof. A representative lookup/caller performance screen is being prepared. Extra VA/PTE/collapse costs and NUMA effects remain unknown. An unused alias proves no optimization.
4. Use fresh evidence to choose the next source change. Periodic original three-hour and selected nine-hour qualification remain required; do not run a long forecast for every small directive. Keep models, readers and independent native work parallel where their resource/cache contracts permit it.

Private recovery root: `/home/ddietz/wrf/investigation/wrf-cpu/campaign/spot100-20261016/`. Own child runtime root: `/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-56d2-spc-{3h,noon1h}-runtime-r1/`. Preserve exact invocation IDs and receipts in those directories before retrying uncertain jobs.


Current-build follow-up: the two-main-thread MYJ source/count capture completed and its instrumented forecast passed185 ordered steps/two complete outputs. All model, recorder, reader and parser scopes closed normally. Four events ran at100% without scaling; the counts cover whole rank windows and cannot assign misses or stalls to MYJ loops. The observed MYJ locations revisit required species packing; no safe new removal was established. No further MYJ profile is planned from this result. See `tools/cpu-profiles/currentda1c-myj-two-main-tid-counts-20261026/README.md`. The separate Thompson congruent-alias genuine-caller wave completed four exact arms: hpc01 wall1.1506% slower/CPU0.8982% slower, hpc02 wall0.3391% shorter/CPU0.1296% shorter. It is closed unpromoted because no consistent caller or separate resource benefit was demonstrated. Actual huge-page eligibility/reader mapping capability remains proven within the tested scope. See `tools/cpu-rejected/thompson-returned-view-large-pages-20261026/README.md`.


October27 continuation: selected working child is now330db1c1/archiveb3794efe, source6311634d. It adds only two pre-delta beam scratch scalars in SPCVMC; full-caller wall was0.6276/0.9271% lower and threadCPU1.1468/0.9513% lower on01/02. Its own unprofiled noon185/twoFULL original science passed and all scopes closed. It owns noon only: no child3h/9h/profile/restart inheritance. Previous da1c three-hour and profile evidence above remains historical. Rollback WRF_SW_SPC_NODEL_SCALARS=0 then regenerate/recompile/rearchive/relink, or use retained da1c. See `tools/cpu-compute/spcvmc-predelta-beam-scalars-20261026/README.md`. MPI U/V-only halo reuse passed its genuine nine-rank native test and is proceeding to complete-protocol caller measurement. Physics interpolation SIMD remains unpromoted after strict state and MOD failures; the read-only mask guard interface is being investigated, with all failures retained. DeepSeek and AWS remain suspended.
