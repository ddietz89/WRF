# RSL wide DEFAULT SIMD trial — unpromoted

The private `!$OMP SIMD LINEAR(p:1)` trial did not eliminate the per-K `memcpy` dispatcher in `f_pack_int_ikj`. It is closed without a caller timing or performance claim. Current RSL source, byte layout, build flags and defaults remain unchanged. `SOURCE_ONLY.diff` records the uninstalled proposal; its directive is excluded when `_OPENMP` is defined.

The actual GNU 13.3 probe confirmed INTEGER32 and that private `-fopenmp-simd` did not define `_OPENMP`. Ten geometries, each under four masked states, passed raw output, cursor, read-only input, guards and five-state checks in each of four roles (genuine, old-flag parent, SIMD-flag parent and SIMD candidate): 40 calls per role, 160 calls total, not 160 distinct geometries. Empty I/K/J and wide-row tails were included.

Actual candidate assembly routes width >4 to DEFAULT at `0x2a0`. A positive row calls `memcpy` at `0x2f5` (relocation `0x2f6`), and the K backedge at `0x306` returns to `0x2d8`. Only empty I/K bypass the copy; this is the normal path rather than a cold fallback. The mechanism check therefore stopped as intended before full translation-unit reproduction, the original full 25-case fixture, caller timing or application qualification.

The native attempt exited 1; its actual invocation, failed manager state, MainPID 0, empty/absent cgroup, receipt and closure hashes are retained in `DECISION.json`. The original failed attempt is preserved. The malformed provider NO_GO response and its unsupported generic LINEAR objections are retained separately; they are not evidence of a native semantic failure. The tiny native semantics passed, while the requested code-generation change did not occur. No alternate implementation, flag sweep or retry was run.
