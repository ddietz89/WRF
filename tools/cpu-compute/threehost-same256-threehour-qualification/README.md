# Three-host SAME256 three-hour qualification, October 25

Corrected original546b and the unchanged combined BACF image passed a fresh original-first comparison on hpc01–03. All four complete06–09 products and545 ordered steps matched exactly under the unchanged scientific, metadata/layout, rank/tile/library and writer checks. All six model scopes and the reader closed normally.

| Metric | Original546b | BACF | Reduction |
|---|---:|---:|---:|
| Model/MPI wall (min) |21.320|18.322|14.06%|
| Main-step elapsed (min) |17.989|16.727|7.02%|
| Aggregate CPU (core-hours) |83.861|75.730|9.70%|

This uses256 ranks:224 compute in8×28 and32 quilt in4×8, explicit physical-core affinity,100GiB/node and zero swap. Checked compute-client cache clearing preceded each arm. Qualified UCX shared-memory/InfiniBand transport and production-style quilting remain. The narrowly adapted provider host/CPU/memory context guards passed fresh native tests; algorithms, ABI, science and layouts stayed fixed. All earlier promoted code/provider improvements are included; helicity fusion is excluded.

| Lifetime cgroup peak (GiB) | Original | BACF |
|---|---:|---:|
|hpc01|84.58|54.50|
|hpc02|76.18|50.74|
|hpc03|85.22|54.20|

All memory-event counters were zero. Peaks are per-node lifetime maxima, not simultaneous total memory. External read-only voltage/temperature/fan observations used the same schedule in both arms; no sampled numeric voltage alarm was seen. Normal samples do not exclude shorter transients.

One fixed-order pair establishes this comparison, not repeatability or an isolated component gain. This separate256-rank/threehost configuration is not pooled with the earlier512-rank/fourhost comparison or the ten-minute pilot. Main-step elapsed includes communication and output backpressure; whole-minus-main is not pure I/O. No own threehost nine-hour, restart, full144-hour or daytime-profile qualification follows.

Exact artifacts, leases, map, native prerequisites and closures are referenced in EVIDENCE_REFS.json and APPLICATION_QUALIFICATION.json. Reuse that exact external runtime to reproduce the case. Rollback selects the earlier qualified placement only when its required hosts are available; do not silently redistribute its ranks or transfer acceptance. The selected scientific executable is unchanged. Production and master remain untouched.
