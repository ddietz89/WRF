# Promoted CPU working configuration

[selection.json](selection.json) selects executable `08f831e8`, adding initial-U tendency SIMD to the complete preceding combination. Source commit `5e4ae45e` contains the one-line change and [qualification](../cpu-compute/uv-initial-tendency-simd/QUALIFICATION.json). Use the executable with its pinned provider, codec, NetCDF owner, private HDF5 and rank/runtime settings. No additional candidate toggle is required.

The new directive passed native captured output, 17 finite/boundary cases and six IEEE-state cases, plus the original full-grid noon checker: two complete products and all 230 ordered steps through 13:15 matched exactly. Opposite-order caller pairs were 0.26% and 1.68% shorter; those clocks include identical restore/state helpers and establish no whole-forecast speedup.

The last three-hour benchmark belongs to preceding executable `f1d7ad6f`, before this directive. Four complete products and 545 ordered steps matched exactly. Wall was 848.674051 to 694.263724 seconds (18.1943% lower), CPU 12.4921% lower, in one original-first pair. [THREE_HOUR_RESULT.json](THREE_HOUR_RESULT.json) remains its historical evidence, explicitly bound to that executable in selection.json. No percentage is transferred to the new executable or added to caller observations. See [findings](../../OPTIMIZATION_FINDINGS.md) and [timing SOP](../../TIMING_SOP.md).

Use the existing bounded campaign launcher and actual CPU/OS, rank, loaded-library and resource admission checks. Preserve two tiles, 480 compute plus 32 quilt ranks, the pinned map, main-thread MPI/HDF5, and checked client cache clears before each timed arm. Supply fresh run and rank-log directories. Rank-only preload is selected provider plus codec; never preload the launcher or helper processes. The selection record itself performs no launch, installation or host change.

For rollback, select retained qualified executable `f1d7ad6f` with the same pinned runtime, or remove only the initial-U directive and rebuild SmallStep/archive/executable. ISA opt-outs require rebuilding; ordinary I/O opt-out removes the provider/codec preload and restores the corresponding dependency search. These alternatives retain their own qualification scope.

Production and master are unchanged. Qualification is GNU13.3/Zen2/world-512/two tiles; AOCC/Intel remain experimental. This new selection has no separate three-hour, nine-hour or restart qualification.
