# CPU quota period: reverse screen closed

Keep the working configuration at a 100 ms CPU-quota period. A fresh same-current79be comparison ran one second first and 100 ms second, with the same 512 ranks, FABA placement, two tiles, providers and 128 physical cores/quota per host.

| Measure | 100 ms | One second | One-second reduction |
|---|---:|---:|---:|
| Model/MPI wall |119.642381 s|119.373628 s|0.2246%|
| Main-step elapsed |36.904000 s|36.818790 s|0.2309%|
| Aggregate node CPU |45205.085056 CPU-s|45400.410216 CPU-s|−0.4321%|

Both forecasts passed the unchanged retained-original two-product/35-step checker. All eight model units and both scientific readers closed normally. Checked client-cache clearing preceded each arm. All four nodes proved actual `cpu.max` at start and end: `12800000 100000` or `128000000 1000000`. [Period/identity/cache/science proof](QP.json), [measured results](REVERSE_RESULT.json), [decision](DECISION.json).

The earlier approximately 5% signal did not reproduce. That separate13fe forward pair had intervening host maintenance and is not pooled here. One fixed-order reverse pair does not establish a small gain or regression; the result does not justify changing the default or another long forecast solely for this setting. Main-step elapsed includes communication/backpressure; aggregate CPU includes spin. Throttle counters do not measure causal lost wall time.

The historical original546b run supplied scientific reference outputs only; its unpaired timings are excluded from this period comparison. Inherited raw collector labels remain preserved. A separate post-model wrapper corrected exactly one stale13fe executable-identity literal to79be; frozen manifests and the scientific checker stayed unchanged. Private complete evidence: `investigation/wrf-cpu/campaign/spot100-20261016/current79be-cpu-quota-period-reverse-feasibility-r1/`.

No executable, scientific source, default, production or master changed. Rollback requires no configuration action; revert this evidence commit only to remove the report. Working-source qualification and historical nine-hour evidence keep their original scopes.
