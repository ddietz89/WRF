# Timing SOP

Effective 2026-10-14: **clear compute-node filesystem caches before every timing run.** This applies to controls, candidates, standalone kernel benchmarks, individual stages and full forecasts. Every separately timed arm/invocation must be covered by a recorded cache clear before it starts. Model timesteps and inner benchmark iterations remain inside their normal timed invocation.

## Required order

1. Prepare the case, stage files, finish source/binary/library provenance checks and full scientific/static input checks. Fix executable, configuration, inputs, MPI transport, rank map, affinity, cgroup limits and output policy for the comparison.
2. Confirm all prior benchmark/model/checker jobs and their residual process groups have closed on every participating node. Serialize cache maintenance with timed work. For concurrent experiments on one node, prepare the whole wave, clear once at a shared pre-launch barrier, then start all members; perform no further clearing until the wave finishes.
3. On every participating compute node, run a bounded `sync`, then write `3` to `/proc/sys/vm/drop_caches`. Use the reviewed helper with explicit host selection and timeouts. A failed/partial clear, failed sync or surviving helper process blocks the timing run; retain the failure rather than labeling the run cache-cleared.
4. Retain each node's actual result, boot identity, timestamps, helper closure and `/proc/meminfo` cache values before/after. Require all participating nodes to pass. Record the clear-to-launch delay using the same host clock where available.
5. Launch promptly after clearing. Use metadata/read-only file-identity checks at this boundary; avoid re-copying or re-hashing scientific inputs. Normal executable/library/control checks and loading are retained and their cache warming is disclosed. Preserve original post-run input hashes and the original scientific checker.
6. Start the established model/kernel timing clock at its existing boundary. Setup, sync and cache maintenance remain outside that clock. Whole forecast time still includes initialization, computation, communication, output and final writer drain/shutdown.
7. After model scopes close, run the bounded original exact checker. Preserve numerical/nonfinite, metadata, layout and runtime acceptance. Close that checker before any next cache-clear operation on its nodes.

## Reporting

- Apply the same cache policy to both arms. Retain all individual wall/CPU values, run order, resource settings, clear receipts and exact results; report medians/ranges when repeated.
- Label this **compute-client filesystem cache clearing**. File-server caches and traffic remain uncontrolled unless separately measured and explicitly managed. A successful drop does not guarantee every cache stays empty until every rank starts.
- Keep earlier runs under their actual historical cache policy. Do not pool them with the new policy without labeling the difference.
- Whole wall, main-step sums and kernel/provider timings retain their separate scopes. Whole-minus-main is not pure I/O; do not add component percentages or infer an I/O/MPI/cache cause from timing alone.

The reviewed implementation is retained in the experimental workspace at `/home/ddietz/wrf/investigation/wrf-cpu/science-discovery/production512-original-latest3h-client-cache-runtime-r1/`: `prepare_arm.py`, `clear_arm.py`, `cache_clear_host.py`, `cache_boundary.py` and `launch_arm.py`. Future timing adapters must preserve this ordering and original acceptance checks. Timing-insensitive checks may run without clearing, but their timings are not optimization evidence.
