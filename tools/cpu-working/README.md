# Qualified WRF CPU working configuration

Selected executable **1d6e5213**, WRF source **495f1000**, includes all preceding compute, Thompson shared-table/lazy-initialization, codec and HDF5 changes plus the READ_DI1 affine reader. The working binding enables root-input **06d0232d/NetCDF a32aa6cd** and fused output **172306f3/provider b938317c**. Input sources were committed in **614267f3**. [Selection](selection.json) and [source/build binding](CURRENT_SOURCE_BUILD_BINDING.json) distinguish the unchanged WRF image from additional libraries; original build producers retain their null source-commit fields.

Fused output passed its own native/API and **two-complete-product/35-step/all512** original scientific canary, with all jobs closed. Its complete synthetic W-shaped provider caller was47.30–48.92% shorter with36.79–38.33% less process CPU and exact compressed/decoded bytes and state. These are caller gains, not forecast gains. Own three-/nine-hour qualification for the newly fused configuration is pending; the following fresh three-hour comparison used previous output375. See [fusion evidence](../cpu-output/quilt512/fusion/APPLICATION_QUALIFICATION.json).

The fresh corrected-original/previous-working three-hour pair passed **four complete products, 545 ordered steps, all 512 ranks, two serial tiles and four positive quilt writer groups**. It includes root-input06d/NCa32 and output375, before fusion172. All model and reader scopes closed. [Timing evidence](THREE_HOUR_RESULT.json) records:

| Measurement | Corrected original | Combined working build | Reduction |
|---|---:|---:|---:|
| Model/MPI wall | 818.040 s | 670.778 s | 18.0018% |
| Aggregate node-cgroup CPU | 366,874.261 s | 323,960.583 s | 11.6971% |
| Summed main-step elapsed | 595.758 s | 566.691 s | 4.8789% |

This is one fresh control-first pair, with checked compute-client cache clears before each arm and uncontrolled file-server load. It measures the combined configuration, not an isolated input or kernel contribution or repeatability. Main-step elapsed includes communication/backpressure and is not integration CPU; wall-minus-main is not pure I/O. The control's MPI children exited successfully, then its coordinator failed a telemetry field-name lookup. [Qualification](THREE_HOUR_FINAL_QUALIFICATION.json) preserves that failure and the separate runtime postprocessing recovery; the original numerical comparison was unchanged.

The production quilting layout is retained: **480 compute ranks in 8×60 plus four groups of eight I/O ranks**, hourly history, NetCDF history/restart format 2 and one frame per file. Whole wall includes initialization, output and final writer drain. Runtime remains GNU13.3/Zen2, OMP1, output172/codec881/HDF5825, shared tables/FIELDVIEW1, faba affinity and UCX `rc,sm,self` over the selected single InfiniBand port. The separate dual-port comparison qualified only its older 81d35 image and did not establish a gain.

Only rank 0 receives the input adapter/private NetCDF prefix. Other 511 ranks keep the previous libraries. The root temporarily borrows occupied same-job CPUs0–3, joins all workers and restores CPU0 before return/MPI. Actual logs record 17 supplied reads, 14 fallbacks and 31 restores. Unsupported selections and IEEE states take the original path. See [input qualification and rollback](../cpu-input/parallel-chunk-read/README.md).

First-table private/shared testing established **6.74–7.47 GiB/node lower cgroup peaks with neutral timing**. Later table extensions remain exact-qualified; combined current/control peaks are not isolated PSS or component savings. The retained nine-hour result belongs to **b1fb/source4e70**, before the latest additions: 2069.312 → 1855.505 seconds, 10.3323% lower wall, ten products and 1625 steps. It does not qualify this selection. Kernel, caller and forecast percentages are not added; 1.5× throughput and 2× speedup remain unmet.

Immediate rollback restores [the pre-fusion selection](PREVIOUS_SELECTION_BEFORE_FUSED_OUTPUT.json) and [matching binding](PREVIOUS_SOURCE_BUILD_BINDING_BEFORE_FUSED_OUTPUT.json), retaining executable1d6e, input06d/NCa32 and codec881 while selecting output375. The separate pre-input selection remains preserved. Production and master remain unchanged. Own sustained nine-hour, restart, cycling, nesting, other-compiler and144-hour qualification is absent. AOCC and Intel remain eligible experimental stacks.
