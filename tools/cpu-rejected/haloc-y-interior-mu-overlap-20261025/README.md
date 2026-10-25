# HALO_EM_C Y/interior-MU overlap: bounded complete-caller result

Close this fixed implementation unpromoted. Both opposite-order comparisons regressed.

- Pair 1: 6.399587752 s → 7.410268025 s (15.793% longer wall; 15.790% higher aggregate rank thread CPU).
- Pair 2: 6.582787694 s → 7.532865567 s (14.433% longer wall; 14.442% higher aggregate rank thread CPU).

The same executable ran sync/split/split/sync over four hosts, one rank per node on CPU24, with a checked cache clear before every arm and all scopes closed. Each batch ran 2,048 complete Y+X+advance_mu_t calls and identical mutable restores inside one wall/thread-CPU interval. Geometry was a controlled captured 113×43×33 patch with two J tiles, not a measured production decomposition. Captured values may include qNaNs despite the inherited FINITE status label. Raw output, read-only/physical guards, and all five state fields passed the retained same-call-count comparisons.

The actual native O2 gate remains passed: seven cases, four rounding modes, three sequences and four ranks. Cached original SmallStep and RSL code were reused; exactly twelve private cursor/request bindings were exposed in a replay-only object with allocated bytes and relocation effects preserved. The current calculation body was moved literally into one outer scratch lifetime and a contained rectangle worker; Y completion/unpack still precedes X packing.

The first timing runtime remains failed. Its baseline compared errno after one warm call with errno after 2,048 calls. The fresh repair retained both errno values, removed only that different-count equality, and kept all five state fields strict between sync and split at matching counts. No failed-run timing was admitted.

This result measures the joint cost of the Y overlap schedule and one-scratch compute organization. It does not isolate wire progress, allocation cycles or the cause of regression. Earlier X-overlap regression remains separate historical evidence. No O0, generated-wrapper/solve_em integration, canonical source, public ABI or forecast qualification is claimed. No selected source, default or working selection changes follow.
