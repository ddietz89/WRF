# WRF CPU optimization handoff — 2026-10-16

**This round is closed.** The latest combined build passed the nine-hour exact qualification. The final two-hour current-build profile run also passed the unchanged exact checker; two of four profile streams qualified independently. All model, recorder and reader jobs have stopped. No optimization candidate or additional test is queued.

## Scope and source of truth

WRF 4.8.0 working fork: https://github.com/ddietz89/WRF, branch `perf/cpu-20261012`. Consolidated evidence is in `OPTIMIZATION_FINDINGS.md` beside this file and `/home/ddietz/wrf/investigation/wrf-cpu/`. Remote experimental work is under `/pool/wrf-experiment/wrf-cpu`. Production deployment is outside this round. Existing production files and `/pool/wrf/WPS` remain unchanged; WPS work has its own findings and must not be combined with WRF percentages.

The control is **corrected original executable546b**, not pristine upstream WRF. It includes the separately approved AFWA terrain stencil, Thompson ordinal addressing, MU2 ghost and adaptive-alarm corrections. Those correctness changes establish the scientific baseline and carry no performance claim. Legacy source and its failures remain preserved. The working build also retains the separately documented HO2 row restoration; the configured higher-order trajectory does not establish HO2 trajectory qualification.

Verified remote heads before this handoff: working branch `fb78d4cfaf926e0eee8fb15197023533f0a00149`, master `29e297bf4e13cd3c4b779a5f68d950bb617aa6f7`. This closeout publishes to the working branch only. Do not assume master includes all later improvements. Final handoff documentation adds a subsequent working-branch commit.

## Main results

Both comparisons used the full nominal1500×1140 grid,512 MPI ranks across hpc01–04,480 compute ranks in8×60 and32 quilt ranks in4×8, the same qualified placement/InfiniBand configuration, and checked client cache clears before EACH arm.

| Comparison | Corrected original | Combined improvements | Observed reduction |
|---|---:|---:|---:|
| Three-hour model/MPI wall |824.648138s (13.74min)|722.991746s (12.05min)|12.3272%|
| Three-hour aggregate CPU |369296.219257s|350764.342648s|5.0182%|
| Three-hour main-step sum |597.31520s|574.96202s|3.7423%|
| Nine-hour model/MPI wall |2088.254998s (34.80min)|1962.532330s (32.71min)|6.0205%|
| Nine-hour aggregate CPU |1019585.946365s|981815.687986s|3.7045%|
| Nine-hour main-step sum |1856.03949s|1783.90763s|3.8863%|

The three-hour test was06–09 with the pre-final-AFWA combined executable0d2150: **four complete products and545 ordered adaptive steps passed exactly**. The nine-hour test was06–15 with latest1e2c: **ten complete hourly products and1,625 ordered adaptive steps passed exactly**. Original scientific fields, nonfinite/mask behavior, literal metadata and output layout passed; no tolerance or field exception was introduced.

These are individual fixed-order observations, not repeatability estimates or isolated feature gains. The nine-hour run requested identical profiling but actually recorded three control streams and zero candidate streams. Both hpc04 model scopes reached104GiB, with final memory.max-event counters2623(control)/2118(candidate), OOM/kill counters zero. These events establish cap hits/reclaim attempts, not their time cost. File-server load/cache remains uncontrolled. Client cache clearing does not clear the file server.

### Why12% became6%

The timestep benefit stayed broadly similar. Within the nine-hour run, main-step reductions were4.6769% for06–09,3.3861% for09–12 and3.6264% for12–15. The new early block's candidate time574.17943s is close to the earlier574.96202s; control increased597.31520→602.35098s. There is no observed early timestep-benefit collapse.

Absolute wall savings increased101.65639→125.72267s against a larger baseline. The difference outside recorded main steps varied79.30321→53.59081s. This accounting explains the changed percentage arithmetically; it does not isolate startup, output, communication, daylight physics, AFWA or a regression. Wall minus main-step time is **not pure I/O**. Kernel, caller, stage and forecast percentages must never be added.

Evidence: `science-discovery/production512-ih3-runtime-r2/`, `production512-dayprof9h-runtime-r1/`, and `source-discovery/dayprof9h-block-communication-review-r1/` under the local investigation tree. The authoritative nine-hour observational supplement is `OBSERVED_QUALIFICATION_AND_TELEMETRY.json`; the original generated RESULT wording is retained separately and the current RESULT is corrected.

## Current qualified working configuration

| Component | Artifact |
|---|---|
| Corrected control |`/pool/wrf-experiment/wrf-cpu/builds/mass-ghost-alarm55-prototype-r2/wrf.exe`|
| Control SHA256 |`546b99156cbd809e1cae5e0ea8cebeea44dafd6331abf89e4daea00e0dd0a5e7`|
| Latest executable |`/pool/wrf-experiment/wrf-cpu/builds/afwa-five-copy-guard-current-ih-native-r1/wrf.exe`|
| Latest SHA256 |`1e2c6e9af0ee4b3f18af8f0c37aa8437bea685bd4a0e675d89367c29f38eedca`|
| Compute archive SHA256 |`ac80ce1861581df3004a1f3a22e964752c3ab9c6febfdaa781e7c9c399ce66ee`|
| Threaded packing/compression provider |`/pool/wrf-experiment/wrf-cpu/source-discovery/parallel-pack-quilt-shim-native-r1/wrf_quilt_thread_shim.so`|
| Provider SHA256 |`375aa7e3198d42d84e3c95612f5475216354e2c4cb33c053eea42ac29f4bdb2a`|
| Selected Huffman codec |`/pool/wrf-experiment/wrf-cpu/builds/codec-huffman-word-load-native-r1/build/libz.so.1.3.1.zlib-ng`|
| Codec SHA256 |`881d0a1aa84f1ac3f3fc60b0c59f7f9b03125fe68065cf44a04170de5655de3c`|

Qualified compiler is GNU13.3 with retained strict flags; no fast math or additional ISA options were introduced in this round. Existing architecture-specific qualifications remain confined to their documented members. AOCC/Intel are eligible experimental stacks, not newly qualified by these results. Runtime provider/codec selection is separate from the Fortran executable; use the retained launcher/bindings rather than assuming the executable alone contains every output improvement.

The accepted ancestry includes advection row caching; qualified W/UV/scalar/diffusion and pressure/density/RK improvements; AFWA RH guard/locality; damping/curvature reuse; PBL initializer locality, C2A SIMD and Coriolis row caching; integer transpose/RSL copy specializations; MCICA RNG access with exact sequence; SUMFLUX fusion; INATM redundant-fill removal; output packing/shuffle/compression and zlib-ng/Huffman improvements. The final source promotion in this round is the AFWA five-copy guard (`7a86bc6c`): copy hydrometeors on output timesteps or the conservative severe-diagnostics route. Do not infer individual forecast gains from this list.

Latest acceptance is the nine-hour trajectory in this specific configuration. Full144-hour, new weather/decompositions, restart and other compilers are not established by this nine-hour result; older qualifications remain scoped to their original artifacts and source epochs.

## Closed investigations and profiling findings

- **PHY_PREP theta fusion:** rejected. A complete-caller24-case initial pass missed a distinct-NaN pairing; native review and two targeted cases exposed different RHO payloads. Original failed evidence remains retained. No repair/flags/tolerance change or promotion.
- **Huffman leaf-counter locality:** correctness passed, but five short codec pairs had median wall−0.974% and CPU−0.685% reduction (slower). Closed, no provider/forecast adoption.
- **RK dry theta SIMD:** exact caller gate passed; target88native bytes stayed scalar and identical. Closed without timing or variants.
- **Thompson paired RSLF:** actual parallel DeepSeek implementation/review produced a private two-element loop.24 complete caller cases passed at native/O2 and same-optimization O0, including raw returned bits, read-only/physical guards and FP/errno state. Actual code emitted two scalar RSLF calls and no useful packed polynomial arithmetic. Closed unpromoted, no timing/variants/application run; smaller function size is not a speedup.
- **Shortwave:** actual vrtqdr/reftra/spcvmc sampled PCs occur in all three qualified control windows. Exact scoped current function code corresponds to the original control. Dependent recurrences and required arithmetic dominate; no safe removable pass was proved. Vrtqdr's final scalar flux loop was only about0.05% of each selected stream; scratch allocation cost was not isolated. Deferred without an implementation.
- **Other compute/communication:** most original-control hotspots predate already promoted or closed changes. No new copy redundancy justified reopening XPMEM, NUMA, readiness or transpose variants. A selected-rank MPI-progress share is not global critical-path or removable communication time.

The three original-control daylight windows contain4,090/4,111/4,092 actual main-TID sample records spanning approximately90s, with phase audits13:11:40–13:37:20. They support bounded original-stream attribution. ProducerUNAVAILABLE labels and numeric sample lossUNKNOWN are preserved; perf's display of zero lost samples is not promoted to a general no-loss assertion. The unrecorded candidate windows provide no paired daylight comparison.

Actual DeepSeek calls, exact source-payload approvals, responses, literal review and native receipts are retained. The paired-RSLF source came from the actual returned author literal; malformed diff context was recovered mechanically. Reviews were conditional source assessments, not native/scientific certification.

## Final current-profile closeout

R1 uses `science-discovery/production512-current2hprof-runtime-r1/`: its model reached08:00, and the original checker passed all three products and365 ordered steps exactly against the qualified nine-hour prefix. All four model scopes and the reader closed successfully; reader invocation `cb131a47cf1c4d25b0a5d2809a43ce65` has actual own-cgroup absence and invocation-bound manager success. All four collector helpers failed before recorder launch because the embedded scripts retained two obsolete helper-hash literals even though outer/bootstrap pins were current. No raw recording exists and the frozen package was not changed.

The final short profile targets06–08 simulated time and therefore adds current-build nighttime compute evidence if acquisition succeeds. It does not replace the missing current-build daylight capture or establish whole-model/global cost shares. A future daytime investigation would need an explicitly scoped current-build daylight window with the corrected bindings.

The binding mistake is acknowledged. A future-only correction updates those literals and the resulting driver→bootstrap→nested-manifest→binding→outer-manifest chain. Exact old AST blocks reproduce the four failures, and the repaired overlay passes15 offline checks, independently reviewed. Phase/FD guard algorithms remain byte-identical. The previously reviewed race handling allows a later complete observation to recover BEFORE admission; any inconclusive audit DURING acquisition still rejects/marks partial. No retroactive qualification or relaxed guard is allowed.

The final R2 package (`/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-current2hprof-runtime-r2/`) passed all 15 local and actual post-staging helper-binding checks before launch. Checked cache clears preceded the run. All four recorders started; ranks 0 and 2 finished normally without parent errors. Rank 1 stopped early after writer status became inconclusive. Rank 3 finished recording but its parent reported that acquisition crossed the requested phase boundary. Both error streams remain limited evidence, irrespective of native recorder exit status. All four model scopes and all four recorder scopes subsequently closed, with invocation-bound success and actual cgroup absence. The original reader passed all three products and 365 ordered steps exactly against the retained nine-hour candidate prefix, then closed successfully. Independent profile review qualified only ranks 0 and 2. No additional experiment or retry is queued.

### Current-build evidence and next measured opportunities

Independent R2 review (`source-discovery/current2hprof-independent-validation-r2/RESULT.json`) qualified ranks 0/2 with 4,121/4,090 samples over 89.982561/89.999580 seconds, phase audits at model seconds 1,155–2,895 / 1,435–2,955. Identity, eight pinned libraries, FD/phase audit coverage and invocation-bound closure passed. Producer UNAVAILABLE and numeric loss UNKNOWN remain unchanged. The local review required a collection-envelope path correction to resolve the two writer metadata entries at their actual runtime-root paths; the original failure, minimal diff and proof are retained. No acquisition predicate changed.

| Current symbol, selected-stream self share | Rank 0 | Rank 2 |
|---|---:|---:|
| Positive-definite scalar advection |2.765%|3.101%|
| Thompson main microphysics body |1.200%|2.938%|
| MYJPBL main body |1.148%|1.366%|
| Physics preparation |1.028%|1.156%|
| Longwave rtrnmc |0.432%|0.492%|

These are period-weighted self shares of two selected main threads, not global model fractions or demonstrated removable cost. MPI/UCX progress is prominent. Unresolved symbols remain split by actual DSO rather than assigned to WRF compute: UCX about20.62/15.92%, libc7.83/9.26% and libm3.55/4.88%. There is no material new shortwave evidence in these early windows. The older control daylight evidence remains a separate source epoch and phase.

If further optimization is requested, first map the retained current MYJPBL/diffusion PCs and Thompson main-body PCs to their actual source/native operations, then establish a removable mechanism before implementation. Do not reopen previously closed Thompson workspace/pressure-hoist/RSLF or radiation candidates merely because their parent routine appears here. For daytime attribution, obtain one explicitly scoped current-build daylight capture with corrected helper bindings. Broader forecast/restart qualification and matched repeatability measurements remain separate follow-up work. No new candidate is pending promotion from this closeout.

## Continuation rules and rollback

1. Start with the final status below, current `OPTIMIZATION_FINDINGS.md` and `/home/ddietz/wrf/investigation/wrf-cpu/campaign/RESUME.json`. Historical ready queues and older closeout files can be stale; use final receipts and dispositions.
2. Do not reopen a closed screen without a new measured mechanism. Profile current code, isolate a worthwhile region into a standalone complete-caller kernel, attempt actual parallel DeepSeek author/review, then inspect exactness and real generated code before timing. Preserve failed/neutral evidence.
3. Keep the original checker unchanged: exact science, metadata, layout, ordered steps, raw IEEE/nonfinite behavior. No silent tolerance, domain shrink, fast math or flag change. Source correctness changes require explicit separate scientific approval.
4. Before every timing arm, after owned jobs drain, separately check sync and drop_caches3 on all participating clients. Use explicit affinity and cgroup CPU/memory/swap/time limits. Full512 owns128physical cores/node with100/100/100/104GiB and zero swap. Use hpc00 for timing-insensitive parsing/metadata. Use qualified UCX `rc,sm,self`, IB `ibp1s0f0:1`; do not substitute TCP data transport.
5. DeepSeek endpoint/model: `https://api.deepseek.com`, `deepseek/deepseek-flash`, denied tools,240s. User standing approval covers project payloads; credentials must stay out. If automatic review nevertheless blocks, request exact payload approval and allow five minutes before a root-released local fallback. Do not resend closed work after late approval.
6. This requested closeout stops the autonomous campaign. Resume only on a new user instruction; historical queues do not authorize fresh work. Promote worthwhile candidates only into the working fork with concise evidence and rollback. No production deployment or new master update is included in this closeout.

Immediate AFWA rollback is retained executable `/pool/wrf-experiment/wrf-cpu/builds/inatm-cloud-zero-current-pbl-native-r1/wrf.exe`, SHA `0d2150efa67026fd5e3760e1a638b9ddb4da490ec5a0225e25f431cd66005b38`, archive `a3f47d5ee8ff5a7faf98bd6f58662bef28cb85e768a800b31a364da087312931`, keeping provider375/codec881d. Source rollback is a dedicated revert of7a86bc6c. Codec rollback is the retained guarded f85 build (`/pool/wrf-experiment/wrf-cpu/builds/codec-avx2-caller-specialization-r1/build/libz.so.1.3.1.zlib-ng`, SHA `f85f24ba39b67ddb799b3bfcd7e01f9e1c0371fdac24ba7f0e6f400105bc738d`), selected through the retained launcher opt-out rather than overwriting installed files. Removing runtime provider/codec selections restores ordinary pinned I/O but changes the tested package; follow the existing configuration contract. Preserve all original/control artifacts.

## Essential receipts

- Three-hour original SCI: `7506848a56be0d80abb571102700d3f38d824d0158da285f5bf03f15754b5ed0`.
- Nine-hour original SCI: `791bc67e0111a0bfc95488d53a06ede1c65c132548fcdbe4e5318d5a5b8e5bf1`.
- Nine-hour reader closure: `c8732ba57fa6a2b8cfdc6d82af02fd271dbc199c47529efd49b37a4ed1acc6c9`; actual cgroup absence `a967ae24eed4bb1f673787b148f7caba193b3da65c9cc9c7abd0f56422df65e3`.
- Paired-RSLF native receipt: `0ba59dacfe78bdeda698eeb198263181f33cf0f066074a0eef85518c85eb8150`; closure `c32d26646765f0a55fb700d0949a88ccbd754d91a7f98b7176b94ba71424896c`.
- Current two-hour R1 original SCI: `23e58df28c426811fa4a8ff9a71adbeb41d7bf7e3a77386999bc2a0d9e6abba7`; reader closure `b65ceb79f5e7aa0ea0d5b46b66493c5c28e11a3e05b31177259094f9884cf977`. R1 has zero recorded profiles.
- Final R2 independent profile validation: `4f6fca78b2b4e2b0b8eb5db5a1a480a84f180da5fdaee5ca22a18eab26a204a5`; bounded hotspot handoff: `7d5cf4ab061c6462c5cc87c49efbb540397a7fa898908ab9e60b02c19f049470`.
- Final R2 original SCI: `98826b438c3fea284ab8d1dc7552b687ec8e182ee7bf7146bb9ec00baa539050`. Reader invocation `8285702ee5a745f78d8f187059645626`, closure `a11f21a11423931c4672b09d64f3d68b3d4ef1a23a080c5616ca08472a462a80`: manager journal success, PID0/inactive and actual own-cgroup absence. Exit code remains nullable after unit garbage collection; no synthetic value was substituted.
- All four final model/recorder closures: `9d75e252c8d0513fce17cf7ed1cfb72ae9cca1a02204fad6ad3cc4e31c9154bd`. All native work ended by **2026-10-16 15:20:39 UTC**, within the requested hour. The exclusive window was released; no jobs, experiments or approvals remain pending.
