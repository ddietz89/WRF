# Promoted CPU working configuration

[selection.json](selection.json) selects the complete exact-qualified combination from the October 18 three-hour run as the working default. It supersedes older individual opt-in selection descriptions within this GNU13.3/Zen2 world-512 campaign. All source improvements are already committed; use the selected executable together with its pinned provider, codec, NetCDF owner, private HDF5 and rank/runtime settings. No additional candidate toggle is required.

The combination passed four complete products and all 545 ordered timesteps exactly. Wall was 848.674051 to 694.263724 seconds (18.1943% lower), CPU 12.4921% lower. This is one original-first pair, including all preceding improvements; it does not isolate the latest four additions or establish repeatability. See [findings](../../OPTIMIZATION_FINDINGS.md) and [timing SOP](../../TIMING_SOP.md).

Use the existing bounded campaign launcher and actual CPU/OS, rank, loaded-library and resource admission checks. Preserve two tiles, 480 compute plus 32 quilt ranks, the pinned map, main-thread MPI/HDF5, and actual checked client cache clears before each timed arm. Supply a fresh run and rank-log directory. Rank-only preload is selected provider plus codec; never preload the launcher or helper processes. The selection record itself performs no launch, installation or host change.

For rollback, select retained qualified executable `0fb5f827` with its existing pinned runtime, or reverse an individual dedicated source change and rebuild its object/archive/executable. Generic ISA opt-outs require rebuilding; ordinary I/O opt-out removes the provider/codec preload and restores the corresponding dependency search. These alternatives retain their own qualification scope.

Production and master are unchanged. AOCC/Intel remain experimental; this selection does not transfer GNU qualification to them.
