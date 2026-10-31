# Final-history drain: quilt-root heap retention

Date 2026-10-31. Status: candidate running (production512-current352f-heapretain3h-r2).

## Evidence

- After the last model step the job waits for the final history file (09Z), written by quilt root 511 on
  hpc04. Root 511 event span: 26.2 s (halobench run), 28.4 s (drain-profile run, perf attached);
  final step → file close ≈ 25–27 s. Earlier files (roots 487/495/503) take 55–62 s but overlap compute.
- Split of the 26.2 s: 11.8 s inside compression windows (4 workers; each variable has exactly 4 chunks, so
  wider workers cannot help), 14.4 s between windows. Gap per variable scales with field size (0.5–0.66 s
  for 3D fields).
- perf -g on rank 511 for 35 s from the final step (selected runtime, run
  production512-current352f-quiltroot-drainprof3h-r2): deflate 42% (workers); kernel anonymous page
  faults 12% (do_anonymous_page/clear_page); MPI gatherv receive 9%, of which UCX memory registration
  (ucs_rcache_get → ib_uverbs ioctl) 7%. Non-root group member 506 mostly waits in UCX progress.
- Mechanism: per-field buffers on the root (outbuf, transpose temp XField, receive buffers) exceed glibc's
  dynamic mmap ceiling (32 MiB), so each is mmap'd and unmapped; every field re-faults and re-zeroes pages and
  UCX must register fresh memory.

## Change

Shim constructor, writer roots only (enabled ⇒ slot ≥ 0, hpc04), compile-time
`WRF_EXPERIMENTAL_QUILT_ROOT_HEAP_RETAIN=1`: `mallopt(M_MMAP_MAX,0)`, `M_TRIM_THRESHOLD=INT_MAX`,
`M_TOP_PAD=INT_MAX`; logs a `heap_retain` event. Allocation policy only — no arithmetic or data path change.

- Source `heapretain-proposed.c` sha b6f4a60f…; parent source 6e6f13dd….
- Default-off build (macro 0, original compile environment) reproduces the selected shim byte-for-byte:
  object 4f3ef4fa…, DSO 1e0f3ce7…. Candidate DSO 04e7cf1d….
- Memory headroom: hpc04 peak 54.9 GiB on the selected image (MemoryMax ~100 GiB).

## Gates

Original 3h exact reader; drain span on root 511 and wall vs selected-runtime median (621.3/619.2/618.1 →
619.2 s). 9h exact if retained.
