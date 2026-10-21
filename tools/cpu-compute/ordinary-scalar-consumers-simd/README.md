# Ordinary scalar-consumer SIMD

The qualified working configuration selects **bb65f657 / archive05075008 / post-test source38580817**. Two independent final consumers in `advect_scalar` (Y order5 and vertical order3) gain SIMD directives with unchanged expressions, schedule and flags. All previous compute, shared-table, input and output improvements remain included. The result-capacity-reuse and PD final-X/Y candidates are separate experiments and are not included.

The genuine captured caller, original13 edges and32 targeted IEEE cases passed at O0/bounds and O2, with exact raw words, read-only inputs and five return-state fields. Actual packed main/remainder/tail paths were reviewed. The fixed frame grows32bytes; no floating-point spills occur inside these two packed backedges, while setup/tail stack loads remain.

Two opposite-order, cache-cleared4096-call whole-caller pairs measured3.579917813→2.759142198s (22.9272%) and3.596660965→2.726474594s (24.1943%). Both include the same in-clock tendency restore. Process CPU timing is unavailable. These are complete captured-caller observations, not isolated-loop or forecast gains.

The unchanged original full-grid checker passed **four products and545 identical ordered timesteps** through09:00, using512 ranks/two tiles, four positive writer roots and32 field-view markers. All eight model jobs and the reader closed normally. This image owns three-hour science; separate own short/noon75m/nine-hour qualifications remain false. [Application qualification](APPLICATION_QUALIFICATION.json) binds68 actual references and verifies the1177-file runtime manifest; [raw result](THREE_HOUR_RESULT.json) retains exact metric values.

| Fresh original-first three-hour pair | Corrected original546b | Combined bb65 | Reduction |
|---|---:|---:|---:|
| Model/MPI wall, including output/drain |980.207680s|661.484224s|32.5159%|
| Integration-step elapsed, including communication/backpressure |757.688050s|559.029630s|26.2190%|
| Aggregate four-node CPU |449620.407146 CPU-s|320418.104722 CPU-s|28.7359%|

One fixed-order pair with checked compute-client cache clearing before each arm; server load/cache uncontrolled. Both arms had zero memory events and actual CPU-quota throttling. NodeCPU includes MPI spin, main elapsed is not integration CPU, and whole-minus-main is not pure I/O. The single-forecast wall ratio is1.48183x; no repeatability, concurrent-throughput or isolated incremental gain is established. Caller and forecast percentages are not added.

Combined bb65/0507 changes only ordered archive slot555 (advection8ec→a36);583 members and external inputs remain unchanged, with zero production source compiles and one link. Source2fbc/PP64e9/membera36/publicMOD88e9 bind the supported GNU13.3/Zen2 strict recipe: `-O2 -fno-fast-math -ffp-contract=off -fopenmp-simd -march=znver2 -mno-fma`. Preserve the existing four helpers,6518 I/O link tail and isolated HPG helper macro recipe. This is not a generic full-image rebuild certificate or Intel/AOCC qualification. [Build](BUILD_QUALIFICATION.json), [native](NATIVE_QUALIFICATION.json), [caller](CALLER_TIMING.json), [CFG](CFG_REVIEW.json) and [post-test source](POST_TEST_SOURCE_IDENTITY.json) retain exact provenance; frozen raw producer commits remain NULL.

Rollback: restore `dyn_em/module_advect_em.F` and the three `tools/cpu-working/{selection.json,CURRENT_SOURCE_BUILD_BINDING.json,LATEST_APPLICATION_RESULT.json}` records together from commit8d53764fb6847260c2caefbfe054f6609fb22739, then select the retained bc54/9a90 image. This preserves the earlier NHY improvement. Production and master are unchanged.
