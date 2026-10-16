# World-512 quilt compression working default

The selected working default is `simd-pack`: runtime-selected SIMD byte shuffle and parallel packing in the existing four workers. `--provider original` selects the retained `4cb1c2` provider. The provider selector changes no provider, shim, header or owner bytes; package builds previously reproduced selected `375aa7e3` and original `4cb1c2` byte for byte.

This default is limited to the qualified GNU 13.3 / Zen2 world-512 campaign, its current rank map and exact dependency closure. It does not claim qualification for other compilers, processors, maps, restart or the full production chain.

The fresh combined executable `1799376a` with provider `375aa7e3` passed all four complete products, 545 ordered timesteps and all four balanced writer lifetimes against current default `12d3cf5e` / `4cb1c2ab`. Science receipt `d7570776` and reader closure `5808a21a` are recorded in [qualification.json](qualification.json). Whole model/MPI wall was 900.083647 → 894.374113 seconds (0.6343% lower), with 0.8940% lower aggregate CPU. One fixed-order pair with a staging gap and shared-load/cache limits establishes no repeatable whole-model or meaningful trajectory speedup. The working selection adopts exact-qualified kernel improvements with successful combined compatibility; component percentages are not summed or attributed from this pair.

The retained earlier provider-only one-hour comparison was 12.42% slower in wall time and used 15.10% more aggregate CPU, with limitations from intervening runs, cache state and shared load. Its kernel screen showed 7.99% lower wall time with 2.08% more CPU. Those historical results remain recorded and are not relabeled as the new combined result.

Build from the WRF repository root into a fresh directory:

```sh
python3 tools/cpu-output/quilt512/build.py --output-dir <fresh-simd-pack-directory>
python3 tools/cpu-output/quilt512/build.py --provider original --codec original --output-dir <fresh-original-directory>
python3 tools/cpu-output/quilt512/build.py --codec original --output-dir <fresh-simd-pack-original-codec-directory>
```

The selected provider remains nested `e29a6a59`, with the qualified strict C recipe; the original is shared `ee9ebe79`. SIMD dispatch is function-scoped and runtime-guarded; the non-AVX2 execution path remains unqualified. Parent world-16 and world-64 sources are unchanged.

Existing `native_artifact`, activation and historical qualification records describe original `4cb` and remain preserved. The selected variant's receipts are under `optional_build_variants.simd-pack` in [qualification.json](qualification.json). Optional terminology in those historical records is not rewritten into a new qualification claim.

Use the frozen [current rankfile](placement/current.rankfile) and [rank table](placement/current-rank-map.json): 480 compute ranks in an 8 × 60 decomposition, plus four groups of eight quilt ranks across hpc01–04. Each node has 128 physical CPUs. Memory caps are 100 GiB on hpc01–03 and 104 GiB on hpc04, with swap disabled.

Writer roots 487, 495, 503 and 511 retain CPUs 31, 63, 95 and 127, respectively, and worker slots `[31, 28, 29, 30]`, `[63, 60, 61, 62]`, `[95, 92, 93, 94]` and `[127, 124, 125, 126]`. These share compute slots; they are not dedicated free cores. The rejected alternate placement is excluded. Keep the [worker event contract](WORKER_EVENT_SCHEMA.md).

Preload only rank executables with `SELECTED_SHIM:NG`; launchers and helpers have no preload. The working codec selector is `--codec huffman`, qualified paired Code/Len loads `881d0a1a`. `--codec guarded` retains exact prior `f85f24ba`; `--codec inline` retains `bac29f50`, and `--codec original` retains `5d69c443`. Paths and SHA256 values are explicit in codec/selection.json and build receipts; rank-preload.env defines the rank-only preload. Current a630/provider375 plus881d passed the original exact two-history185-step one-hour comparison against retained current f85 control (SCI77450a38, reader2e4a2ba9). This establishes compatibility, not an isolated or repeatable whole-model gain or three-hour881d qualification. See [private codec reproduction and rollback](codec/README.md). Installed WPS_new remains unchanged.

Preserve owner-first dependency search, `WRF_ROOT_SHIM_WORLD=512`, `WRF_ROOT_SHIM_OPTIN=1`, `WRF_ROOT_SHIM_CPUS=0-127`, `WRF_ROOT_SHIM_OWNER=/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19`, `WRF_ROOT_SHIM_LOGDIR=<fresh-log-directory>`, `OMPI_MPI_THREAD_LEVEL=1`, `OMPI_MCA_pml=ucx`, `UCX_TLS=rc,sm,self` and `UCX_NET_DEVICES=ibp1s0f0:1`. MPI, NetCDF and HDF5 remain main-thread only; workers join and affinity restores before continuation.

Roll back a new run to the retained qualified `12d3` executable and original `4cb`, using the same fixture, current map, dependencies and resources. Select `--provider original` or its retained binary. To remove the shim, set its opt-out or omit it; for ordinary I/O, remove NG and restore stock dependency search. Revert the promotion commit and rebuild the object, archive, executable and provider as required.

For generic Fortran ISA, use `make WRF_SMALL_STEP_ZEN2=0 WRF_ADVECTION_ZEN2=0`. Changing a knob does not alter an already built executable. Production deployment is separate.

The new integer transpose plus inline-codec configuration passed the fresh full-grid one-hour comparison: both complete 06/07 products, 185 ordered steps and original scientific/metadata/layout/runtime checks. Model wall was 477.813882 → 427.452763 seconds (10.539903% lower), and aggregate CPU was 10.606524% lower. This single control-first combined observation establishes no isolated component attribution, additive or repeatable forecast gain, or three-hour qualification. SCI `b669bd67` and reader closure `bb51636e` remain exact; see [codec selection evidence](codec/selection.json).

Final direct three-hour closeout passed original SCI 0a13cd71 and reader closure be636a60: corrected stock 1033.064578→latest 906.067103 seconds (12.2933% lower), aggregate CPU 476650.905977→440787.653496 seconds (7.5240% lower), with all four complete histories and all 545 steps exact. This is one stock-first combined observation, not isolated codec/provider attribution or repeatability. Earlier one-hour records remain unchanged. Current source and rank-only defaults are merged on master cb858aff; opt-outs above remain available. No restart/long-horizon/other hardware or production scope is inferred.

Further probes remain frozen. Next is controlled reverse-order, one-change regression auditing on this fixed benchmark using actual matched comparisons; earlier original/combined/candidate categories remain distinct.
