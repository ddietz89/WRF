# World-512 quilt compression working default

## Latest fresh three-hour qualification

Current de5b fresh three-hour qualification: corrected-original546b wall 818.818689s → 662.845312s (**19.05% shorter**, **1.235309×** speedup); aggregate cgroup CPU 367148.357295 → 321081.188328s (**12.55% lower**). Original four products/545 ordered steps/all512/two tiles and all four positive writers passed; caches cleared on every node before each arm, all model and reader scopes strongly closed. Main-step elapsed 595.98539 → 560.99084s (5.87% lower) includes communication/backpressure and is not integration CPU. One fixed-order whole-inclusive-IO comparison, without isolated component, additive or repeatability claims. Producer source_commit stays NULL; current nine-hour remains false, with the previous output172 nine-hour result retained separately.

Earlier noon-only and previous-output measurements below retain their historical scope.

Current complete working selection: [promoted combined CPU configuration](../../cpu-working/README.md). Its exact-qualified executable/provider/codec/private-HDF5 combination supersedes the older whole-build selections below; historical measurements remain preserved.

The selected `fused-pack` default is provider source `8db4037d`, full shim `de5b3c27`: direct fused packing/shuffle, padding-only initialization and the32-word AVX2 byte transpose with scalar tail. Shim313e, codec881, owner8adc, HDF825, workerplacement/API/layout/state are unchanged. Current [native/caller/application evidence](padding-block32/README.md) binds exact artifacts; the selector uses source8db but has not been rebuilt merely for promotion. `--provider simd-pack` retains375/e29; `--provider original` retains4cb.

The incremental complete-provider caller was2.19%/1.78% shorter with 3.60%/3.04% less process CPU than padding1e0. Actual full512 noon two-products/230-steps/two-tiles/487495-positive/503511-inactive passed original science and closures; those caller/noon records did not establish a forecast gain or3h9h claim; current three-hour acceptance is documented above. [Previousfusion](fusion/README.md) and[padding-onlyfill](padding-only-fill/README.md) retain their own historical scopes, including47.30%/48.92%fusioncaller and5.13%/5.20%paddingcaller gains. Those percentages are not added or transferred to WRF. Earlier whole-build/application paragraphs below remain historical.

A new [co-located output-group alternative](placement/co-located-groups/README.md) is retained with exact paired qualification, measured timing and memory tradeoffs. It has its own host-specific guard source and explicit bounded lease; the working default remains unchanged.

This default is limited to the qualified GNU 13.3 / Zen2 world-512 campaign, its current rank map and exact dependency closure. It does not claim qualification for other compilers, processors, maps, restart or the full production chain.

The historical fresh combined executable `1799376a` with provider `375aa7e3` passed all four complete products, 545 ordered timesteps and all four balanced writer lifetimes against current default `12d3cf5e` / `4cb1c2ab`. Science receipt `d7570776` and reader closure `5808a21a` are recorded in [qualification.json](qualification.json). Whole model/MPI wall was 900.083647 → 894.374113 seconds (0.6343% lower), with 0.8940% lower aggregate CPU. One fixed-order pair with a staging gap and shared-load/cache limits establishes no repeatable whole-model or meaningful trajectory speedup. The working selection adopts exact-qualified kernel improvements with successful combined compatibility; component percentages are not summed or attributed from this pair.

The retained earlier provider-only one-hour comparison was 12.42% slower in wall time and used 15.10% more aggregate CPU, with limitations from intervening runs, cache state and shared load. Its kernel screen showed 7.99% lower wall time with 2.08% more CPU. Those historical results remain recorded and are not relabeled as the new combined result.

Build from the WRF repository root into a fresh directory:

```sh
python3 tools/cpu-output/quilt512/build.py --output-dir <fresh-fused-pack-directory>
python3 tools/cpu-output/quilt512/build.py --provider simd-pack --output-dir <fresh-parallel-pack-directory>
python3 tools/cpu-output/quilt512/build.py --provider original --codec original --output-dir <fresh-original-directory>
python3 tools/cpu-output/quilt512/build.py --codec original --output-dir <fresh-simd-pack-original-codec-directory>
```

Selected fused provider `8db4037d` retains the strict C recipe; previous fusedsource is `b938317c`, padding-onlysource `1e0dee40`; previous parallel packing is `e29a6a59`, and the original is shared `ee9ebe79`. SIMD dispatch is function-scoped and runtime-guarded; non-AVX2-host execution remains unqualified. Parent world-16 and world-64 sources are unchanged. The actual full-shim artifact was built by the pinned native recipe; this updated package selector has not been rebuilt merely for this source/default promotion.

Existing `native_artifact`, activation and historical qualification records describe original `4cb` and remain preserved. Current de5b records are under `optional_build_variants.fused-pack` in [qualification.json](qualification.json); prior `simd-pack` records keep their historical scope.

Use the frozen [current rankfile](placement/current.rankfile) and [rank table](placement/current-rank-map.json): 480 compute ranks in an 8 × 60 decomposition, plus four groups of eight quilt ranks across hpc01–04. Each node has 128 physical CPUs. Memory caps are 100 GiB on hpc01–03 and 104 GiB on hpc04, with swap disabled.

Writer roots 487, 495, 503 and 511 retain CPUs 31, 63, 95 and 127, respectively, and worker slots `[31, 28, 29, 30]`, `[63, 60, 61, 62]`, `[95, 92, 93, 94]` and `[127, 124, 125, 126]`. These share compute slots; they are not dedicated free cores. The rejected alternate placement is excluded. Keep the [worker event contract](WORKER_EVENT_SCHEMA.md).

Preload only rank executables with `SELECTED_SHIM:NG`; launchers and helpers have no preload. The working codec selector is `--codec huffman`, qualified paired Code/Len loads `881d0a1a`. `--codec guarded` retains exact prior `f85f24ba`; `--codec inline` retains `bac29f50`, and `--codec original` retains `5d69c443`. Paths and SHA256 values are explicit in codec/selection.json and build receipts; rank-preload.env defines the rank-only preload. Current a630/provider375 plus881d passed the original exact two-history185-step one-hour comparison against retained current f85 control (SCI77450a38, reader2e4a2ba9). The subsequent fresh original/latest combined three-hour comparison with INATM0d2150/provider375/881d passed four histories/545 steps (SCI7506848a, readera176412b): 12.3272% less model/MPI wall, 5.0182% less CPU and3.7423% less summed main time. One fixed control-first pair, checked four-client cache clears before each arm, file-server cache uncontrolled; no isolated/additive or repeatable component gain is established. Main includes communication/backpressure and residual is not pure I/O. See [private codec reproduction and rollback](codec/README.md). Installed WPS_new remains unchanged.

Preserve owner-first dependency search, `WRF_ROOT_SHIM_WORLD=512`, `WRF_ROOT_SHIM_OPTIN=1`, `WRF_ROOT_SHIM_CPUS=0-127`, `WRF_ROOT_SHIM_OWNER=/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19`, `WRF_ROOT_SHIM_LOGDIR=<fresh-log-directory>`, `OMPI_MPI_THREAD_LEVEL=1`, `OMPI_MCA_pml=ucx`, `UCX_TLS=rc,sm,self` and `UCX_NET_DEVICES=ibp1s0f0:1`. MPI, NetCDF and HDF5 remain main-thread only; workers join and affinity restores before continuation.

Immediate rollback restores `tools/cpu-working/PREVIOUS_SELECTION_BEFORE_PADDING_BLOCK32.json` and its matching binding: select output329f/provider1e0 while retaining executable1d6e, root-input06d/NCa32, codec881 and all prior improvements. `--provider simd-pack` selects the retained provider source. To remove the shim entirely, use its existing opt-out or omit the rank preload; ordinary I/O retains its own scope. Production deployment remains separate.

For generic Fortran ISA, use `make WRF_SMALL_STEP_ZEN2=0 WRF_ADVECTION_ZEN2=0`. Changing a knob does not alter an already built executable. Production deployment is separate.

The new integer transpose plus inline-codec configuration passed the fresh full-grid one-hour comparison: both complete 06/07 products, 185 ordered steps and original scientific/metadata/layout/runtime checks. Model wall was 477.813882 → 427.452763 seconds (10.539903% lower), and aggregate CPU was 10.606524% lower. This single control-first combined observation establishes no isolated component attribution, additive or repeatable forecast gain, or three-hour qualification. SCI `b669bd67` and reader closure `bb51636e` remain exact; see [codec selection evidence](codec/selection.json).

Final direct three-hour closeout passed original SCI 0a13cd71 and reader closure be636a60: corrected stock 1033.064578→latest 906.067103 seconds (12.2933% lower), aggregate CPU 476650.905977→440787.653496 seconds (7.5240% lower), with all four complete histories and all 545 steps exact. This is one stock-first combined observation, not isolated codec/provider attribution or repeatability. Earlier one-hour records remain unchanged. Current source and rank-only defaults are merged on master cb858aff; opt-outs above remain available. No restart/long-horizon/other hardware or production scope is inferred.

That historical freeze is superseded by the activecampaign: the latest periodic freshoriginal/currentthree-hour qualification is recorded above; source opportunities and bounded profiles are scheduled separately. Earlieroriginal/combined/candidate categories remain distinct.


The qualified GNU Fortran 13.3.0 working configuration now enables both scoped SmallStep and advection Zen 2 targeting by default. CPU/OS admission remains required; other compiler versions retain generic defaults. `WRF_ADVECTION_ZEN2=0` opts out of the advection setting, and the object/archive/executable must be rebuilt. The exact-qualified paired shortwave helper is also included in working source. These kernel inclusion decisions do not establish a new combined forecast-speedup result; see the latest consolidated findings and timing SOP.
