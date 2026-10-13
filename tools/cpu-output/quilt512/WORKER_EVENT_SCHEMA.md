# Scoped observational worker events

Every time is an absolute CLOCK_MONOTONIC integer `monotonic_ns`. Every event carries actual `rank` and per-byte-batch `generation`. No elapsed time or CPU fractions are inferred from these lifecycle records.

`widen_begin` and `widen_end`: main `tid`, `/proc/self/task/TID/stat` `startticks`, slot−1, actual `observed_mask`, `affinity_status`, status, and declared `worker_mask`. Begin precedes the original widening operation; end follows verified original singleton restoration. A bracketed sampler read may straddle either transition; outside the interval main affinity remains its ordinary singleton.

`worker_create_begin` and `worker_create_return`: main identity and slot, before/after forwarding the exact pthread_create operation. Success does not invent a worker TID; the worker records itself below. The creation bracket bounds the birth transition. Unsuccessful creation remains recorded and lets the original provider return its error.

`worker_register`: actual new worker `tid`, `startticks`, slot, `expected_cpu`, `observed_mask` and affinity read status. It is emitted at entry to an observational trampoline. The original function and argument are preserved. Its initial four-core inherited mask is startup, NOT an asserted singleton. A sample just before this event can be recognized only retroactively from the matching registered TID/startticks inside that exact slot creation bracket; never allow arbitrary writer threads.

`worker_bound`: emitted after the original pthread_setaffinity_np call from a registered worker only; same worker identity, actual observed mask, affinity read status, and actual setter status. No extra affinity operation is introduced. The unchanged provider independently checks the same singleton before packing/compressing. Only an actual successful bound event with the exact expected singleton supports post-bind acceptance. Failed/unknown binding is retained as failure, never broadened.

`worker_exit`: original worker function has returned; same worker identity and actual mask. `worker_join` follows a successful or completed original join and carries worker identity, slot, expected CPU and actual join status. An unsuccessful join emits only main-identity `worker_join_error`, then the unchanged provider's failure behavior applies. Every successful creation must join before provider return; an unjoined record is fatal rather than returning to HDF/NetCDF.

`callback` carries the same generation after all joins and checked main restoration. Guard decline/terminal events can have no widening interval and are not byte-provider success. Release remains memory-only/main-thread/once, after owner use.

Wrappers observe only main-thread create/join calls while the byte callback is active, and binding from its registered TLS trampoline. Every unrelated API call forwards its original arguments and status without logging or registration. Logger state uses integer timestamps and saves/restores errno and fenv. Provider source, header, flags and science expressions are unchanged.

The sampler must preserve every process/library/environment/host/cgroup identity guard. Main four-mask is allowed only within this generation's recorded widening interval; worker inherited mask only within its recorded birth/pre-bind interval, then expected singleton until join. Bracketed reads that straddle a recorded transition are explicitly classified, not treated as stationary observations. No blanket four-mask allowance for all writer threads.
