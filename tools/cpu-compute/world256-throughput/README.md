# Fresh world256 throughput groundwork

Corrected original `546b` and combined `79be` passed both complete histories at 06:00/06:10 and all 35 ordered steps on the same 224-compute (8×28) plus 32-quilt decomposition. The protected exact checker, metadata/layout, observed rank/affinity/library/tile and writer gates remained. All eight model scopes and the reader closed normally. This establishes a separate same256 baseline; historical cross-decomposition failures remain failures.

| One fresh ten-minute pair | Original first | Combined second | Reduction |
|---|---:|---:|---:|
| Model/MPI wall, including initialization/output/drain |280.672480 s|149.068401 s|46.8888%|
| Main-step elapsed, including communication/backpressure |99.698070 s|74.416590 s|25.3580%|
| Aggregate node CPU |48182.987019 CPU-s|30671.378045 CPU-s|36.3440%|

Both arms had checked client cache clears. These are short fixed-order measurements with initialization/output-heavy totals, uncontrolled server load and no isolated, additive, repeatability or long-forecast speedup claim. Main-step elapsed is not integration CPU; wall minus main is not pure I/O. No concurrent throughput or 1.5×/2× target is established.

Candidate lifetime cgroup peaks were 36.11–38.41 GB/node (decimal), versus original 57.83–60.33 GB/node; all memory-event counters were zero. These are ten-minute footprints, not sustained capacity or two-job admission. The next bounded concurrent experiment requires explicit half-B and 48 GiB native I/O/TPI support: current authority guards reject those profiles. Summing the measured peaks alone does not qualify concurrency.

The experimental world256 output shim `b756` preserves actual caller floating state by using the original public put before provider activation when SSE INEXACT is clear. Genuine 256-rank native tests passed clean/x87-only/SSE-only/both-set cases, byte/layout/state/error/lifetime checks and positive worker witnesses. The separate input port and both 14-rank-per-NUMA TPI modes also passed. This shim is confined to the new world256 experiment; selected512 output `8bee`, its providers, production and master remain unchanged.

[Exact qualification](QUALIFICATION.json), [actual short result](SHORT_RESULT.json) and the model/reader closure records retain artifact paths and hashes. Raw native failures and the separately closed read-only validator repair remain under campaign `current13fe-lower-rank-throughput-dedup-r1/224compute-same-baseline-feasibility-r1/genuine256-native-authority-plan-r1`. No historical failed invocation was relabeled. Rollback is to use the unchanged selected512 lease/image/providers; no default or scientific source was changed by this experiment.
