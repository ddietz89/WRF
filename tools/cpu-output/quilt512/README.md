# World-512 quilt compression working default

The selected working default is `simd-pack`: runtime-selected SIMD byte shuffle and parallel packing in the existing four workers. `--provider original` selects the retained `4cb1c2` provider. The selector changes no provider, shim, header, owner or codec bytes; package builds previously reproduced selected `375aa7e3` and original `4cb1c2` byte for byte.

This default is limited to the qualified GNU 13.3 / Zen2 world-512 campaign, its current rank map and exact dependency closure. It does not claim qualification for other compilers, processors, maps, restart or the full production chain.

The fresh combined executable `1799376a` with provider `375aa7e3` passed all four complete products, 545 ordered timesteps and all four balanced writer lifetimes against current default `12d3cf5e` / `4cb1c2ab`. Science receipt `d7570776` and reader closure `5808a21a` are recorded in [qualification.json](qualification.json). Whole model/MPI wall was 900.083647 → 894.374113 seconds (0.6343% lower), with 0.8940% lower aggregate CPU. One fixed-order pair with a staging gap and shared-load/cache limits establishes no repeatable whole-model or meaningful trajectory speedup. The working selection adopts exact-qualified kernel improvements with successful combined compatibility; component percentages are not summed or attributed from this pair.

The retained earlier provider-only one-hour comparison was 12.42% slower in wall time and used 15.10% more aggregate CPU, with limitations from intervening runs, cache state and shared load. Its kernel screen showed 7.99% lower wall time with 2.08% more CPU. Those historical results remain recorded and are not relabeled as the new combined result.

Build from the WRF repository root into a fresh directory:

```sh
python3 tools/cpu-output/quilt512/build.py --output-dir <fresh-simd-pack-directory>
python3 tools/cpu-output/quilt512/build.py --provider original --output-dir <fresh-original-directory>
```

The selected provider remains nested `e29a6a59`, with the qualified strict C recipe; the original is shared `ee9ebe79`. SIMD dispatch is function-scoped and runtime-guarded; the non-AVX2 execution path remains unqualified. Parent world-16 and world-64 sources are unchanged.

Existing `native_artifact`, activation and historical qualification records describe original `4cb` and remain preserved. The selected variant's receipts are under `optional_build_variants.simd-pack` in [qualification.json](qualification.json). Optional terminology in those historical records is not rewritten into a new qualification claim.

Use the frozen [current rankfile](placement/current.rankfile) and [rank table](placement/current-rank-map.json): 480 compute ranks in an 8 × 60 decomposition, plus four groups of eight quilt ranks across hpc01–04. Each node has 128 physical CPUs. Memory caps are 100 GiB on hpc01–03 and 104 GiB on hpc04, with swap disabled.

Writer roots 487, 495, 503 and 511 retain CPUs 31, 63, 95 and 127, respectively, and worker slots `[31, 28, 29, 30]`, `[63, 60, 61, 62]`, `[95, 92, 93, 94]` and `[127, 124, 125, 126]`. These share compute slots; they are not dedicated free cores. The rejected alternate placement is excluded. Keep the [worker event contract](WORKER_EVENT_SCHEMA.md).

Preload only rank executables with `SELECTED_SHIM:NG`; launchers and helpers have no preload. NG is `/pool/wrf/WPS_new/runtime/zlib-ng/lib/libz.so.1.3.1.zlib-ng`. Use its absolute path because the directory lacks the required SONAME alias.

Preserve owner-first dependency search, `WRF_ROOT_SHIM_WORLD=512`, `WRF_ROOT_SHIM_OPTIN=1`, `WRF_ROOT_SHIM_CPUS=0-127`, `WRF_ROOT_SHIM_OWNER=/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19`, `WRF_ROOT_SHIM_LOGDIR=<fresh-log-directory>`, `OMPI_MPI_THREAD_LEVEL=1`, `OMPI_MCA_pml=ucx`, `UCX_TLS=rc,sm,self` and `UCX_NET_DEVICES=ibp1s0f0:1`. MPI, NetCDF and HDF5 remain main-thread only; workers join and affinity restores before continuation.

Roll back a new run to the retained qualified `12d3` executable and original `4cb`, using the same fixture, current map, dependencies and resources. Select `--provider original` or its retained binary. To remove the shim, set its opt-out or omit it; for ordinary I/O, remove NG and restore stock dependency search. Revert the promotion commit and rebuild the object, archive, executable and provider as required.

For generic Fortran ISA, use `make WRF_SMALL_STEP_ZEN2=0 WRF_ADVECTION_ZEN2=0`. Changing a knob does not alter an already built executable. Production deployment is separate.
