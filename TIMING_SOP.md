# Timing SOP

## Autonomous continuation

Standing owner rule, reaffirmed 2026-10-18: **DO NOT STOP after answering a question, giving a status update, completing a test or reaching a milestone.** Treat questions as steering within the active campaign. Answer briefly, then continue the next authorized implementation, test, review or promotion in the same active session. A report is not a stopping point.

Recoverable SSH, gateway or tool failures are recovery work, not campaign closeout. Keep bounded retries at a reasonable cadence, investigate existing authorized access paths, and continue independent local work. An unsuccessful retry is not sufficient reason to end the turn. Preserve existing job identities and recover their actual state before any retry of a model, cache clear or dependent launch; never duplicate an uncertain remote job. Report a persistent access problem while continuing recovery within the active session, unless the execution limit or a truly exhausted external dependency prevents further work.

Keep independent work moving while jobs or approvals are pending, provide brief progress updates at least every 60 seconds during active work, and preserve a durable recovery checkpoint. Stop only at an explicit owner request, a genuinely required authorization that blocks all meaningful work, an external blocker that blocks all meaningful work, or the execution limits of the active session. Do not promise unattended progress beyond those limits. Existing scientific, resource, AWS-suspension, production and master exclusions remain in force.

A transient approval-service capacity error or review timeout is not a completed investigation. Keep the active turn open, retain the unexecuted action and retry through the normal review route at a paced cadence; use one coordinator to avoid parallel retry traffic. Never bypass approval controls. Check recovery while continuing independent work, and resume the existing test immediately when service returns. Do not ask the owner to repeat standing authorization for an infrastructure failure. If the active session reaches a hard execution limit, preserve exact pending job and action state without claiming background continuation. A persistent Codex Goal, when explicitly requested by the owner, supplies continuation across turns; an SOP entry does not activate that feature.

## Campaign storage

Keep large build, profile and model artifacts on the experimental cluster storage. Return compact summaries and selected receipt fields to the conversation; retain complete records in evidence files instead of repeatedly printing them. Check local free space before large copies. Reuse immutable fixtures and source archives where their contracts permit it, preserving required independent scientific-file copies. Reclaim only campaign-generated reproducible duplicates after verifying the retained counterpart and recording recovery instructions. Preserve unique evidence, scientific oracles and active application databases.

## Investigation cadence

Effective 2026-10-17: use the shortest experiment that can answer the current question. Reuse retained current-build profiles and captured callers before launching another forecast.

- Iterate code changes in existing standalone/full-caller tests first. Run exact correctness checks, then bounded timing arms long enough to distinguish a gain from noise. Reject insignificant or incorrect changes promptly.
- Default targeted application profiles to 5–15 simulated minutes and a 10–30 second capture, with a longer capture only when the measured event rate requires it. Verify actual recorder start, target identity and data growth promptly. When retargeting collectors, check the actual tool path and hash on each recording and rendering host before launch; a valid path on one host does not establish another host’s tool binding. Keep initialization and output effects explicit.
- Match the required physical phase. A short nighttime profile does not establish daytime or radiation behavior. Prefer an already qualified checkpoint near the desired phase; do not imply restart equivalence from a successful restart launch. Existing historical continuous-versus-restart failures remain failures, and no current daylight checkpoint is qualified by this note.
- Keep mid-run health checks small and symmetric between arms, using existing telemetry. Perform additional full-executable reads before the cache boundary or after timing; preserve the original runtime acceptance hashes. A local SSH timeout leaves remote process lifetime unknown unless its actual identity and closure are recorded.
- Reserve original three-hour full-grid comparisons for periodic combined qualification. Use selected nine-hour runs for daylight coverage or sustained/repeated benefit that shorter evidence cannot establish. Do not require a long forecast for every isolated candidate or block independent caller work while a scientific reader runs on another node.
- Keep exact science, metadata and layout checks unchanged. Short caller/profile screens do not replace full-grid acceptance or establish whole-forecast speedup. Preserve the cache policy below for every timed arm.

Effective 2026-10-14: **clear compute-node filesystem caches before every timing run.** This applies to controls, candidates, standalone kernel benchmarks, individual stages and full forecasts. Every separately timed arm/invocation must be covered by a recorded cache clear before it starts. Model timesteps and inner benchmark iterations remain inside their normal timed invocation.

## Retaining significant kernel improvements

Standing owner rule, effective 2026-10-17: **do not dismiss a significant kernel improvement without an evidence-backed explanation of why it should not be included.**

- Generally promote a significant, exact-qualified kernel gain into the qualified working configuration unless a concrete exclusion reason is documented. Small gains need not individually exceed whole-run variation. Retain candidates while remaining caller/integration science checks are completed. Record its mechanism, absolute saving, tested numerical/input scope, caller coverage and outstanding qualification. Kernel, phase and whole-forecast gains remain separate claims.
- Mixed or slower whole-run totals alone do not establish that the change caused a regression. Preserve all timings and run order, consider unrelated work and shared-storage/load variation, and isolate the changed path when that uncertainty matters. A missing measurable whole-forecast gain is not, by itself, a reason to discard a local improvement.
- An exclusion or deferral must name a concrete reason and its evidence: for example an exact-science failure, unsupported caller/alias/thread behavior, a demonstrated attributable cost that outweighs the saving, or specific integration/maintenance costs disproportionate to the measured opportunity. Distinguish a verified failure from uncertainty or unfinished qualification; generic caution is insufficient.
- Prefer the shortest useful caller or same-binary comparison to resolve a disputed benefit. Do not require a full forecast speedup for every kernel or repeat broad timing matrices solely to recover a small signal. Preserve the original exact scientific acceptance before source/default promotion.
- State whether the result supports default inclusion, an explicit optional path, retained investigation or exclusion, and explain that choice. Retaining a local gain does not authorize a whole-forecast speedup claim, relaxed science or premature promotion.

## Required order

1. Prepare the case, stage files, finish source/binary/library provenance checks and full scientific/static input checks. Fix executable, configuration, inputs, MPI transport, rank map, affinity, cgroup limits and output policy for the comparison. Validate both arms' run IDs and derived unit names against the unchanged launcher constraints before launching either arm; the current multi-node adapter requires run IDs matching `[a-z0-9][a-z0-9-]{2,90}` (3–91 characters).
2. Confirm all prior benchmark/model/checker jobs and their residual process groups have closed on every participating node. Serialize cache maintenance with timed work. The barrier covers the nodes used by that experiment: an independent kernel on hpc01–02 may run while a reader uses hpc03, and a separate hpc03–04 wave may begin after that reader closes. Each node must remain free of other active work at its own cache clear; a four-node forecast still waits for all four nodes. For concurrent experiments on one node, prepare the whole wave, clear once at a shared pre-launch barrier, then start all members; perform no further clearing until the wave finishes.
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

For native MPI/InfiniBand jobs, retain the established transient service setting `LimitMEMLOCK=infinity` alongside the explicit cgroup CPU/memory limits. Verify the actual job setting before launch; the default 8 MiB locked-memory limit prevented UCX from registering a roughly 40 MiB receive allocation in a diagnostic fixture. Keep subprocess logs bounded and written directly to files so repeated startup errors cannot exhaust the collector. These are job settings, not persistent host changes.

## Historical lease horizon routing

Historical qualification leases must use their exact retained validator bodies and their own scope, including __file__-relative rank-map tables. The historical three-hour checks retain 1,200-second caps; current nine-hour runtime checks retain 3,600 seconds. Do not route historical leases through cached current-horizon modules or widen resource guards to pass ancestry. Preserve preflight failures and repair routing before any cache clear or model launch.
