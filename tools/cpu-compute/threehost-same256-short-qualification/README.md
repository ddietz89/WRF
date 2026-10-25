# Three-host SAME256 short qualification, October 25

After the owner excluded hpc04, corrected original546b and the unchanged BACF executable ran on hpc01–03 with 224 compute ranks (8×28) and 32 quilt ranks. The new host/CPU placement and narrowly adapted input/output context guards passed fresh I/O and Thompson-sharing native checks before this pilot. The scientific checker was unchanged.

Both complete 06:00/06:10 products and all35 ordered steps matched exactly. All six model workers and the reader closed normally with invocation-bound manager evidence. Checked cache clears preceded each arm; every memory-event counter was zero and every node stayed below100GiB. The context repair retained the original science, interfaces, layouts and provider algorithms.

| Metric | Original546b | BACF | Reduction |
|---|---:|---:|---:|
| Model/MPI wall (min) |4.622|2.728|40.97%|
| Main-step elapsed (s) |80.384|71.747|10.75%|
| Aggregate CPU (core-hours) |12.794|9.248|27.72%|

This is one original-first ten-minute pair. Startup/output occupy a large share; its wall reduction is not a three-hour or sustained-speedup estimate. Main-step elapsed includes communication and backpressure. The separate four-host512-rank three-hour comparison is a different configuration and horizon. Kernel/caller/forecast percentages are not additive.

| Lifetime cgroup peak (GiB) | Original | BACF |
|---|---:|---:|
| hpc01 |84.57|54.47|
| hpc02 |75.85|49.23|
| hpc03 |63.31|44.69|

These are per-node lifetime maxima, not simultaneous total memory. Own three-hour science, all-four-writer coverage over that horizon and long-run memory remain pending. The selected executable and its earlier application qualification are unchanged; this record does not promote a new scientific code change or replace that qualification.

Reproduce the short configuration using the exact external package and hashes in EVIDENCE_REFS.json. To roll back the placement, stop owned jobs after closure and select the earlier qualified configuration only when all of its hosts are available; do not silently redistribute ranks or reuse its scientific coverage. Production and master remain untouched.
