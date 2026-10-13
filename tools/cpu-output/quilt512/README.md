# World-512 quilt compression providers

The original qualified provider remains the default. The explicit `simd-pack` variant adds runtime-selected SIMD byte shuffle and packing in the existing workers. Both complete hourly products and all 185 ordered steps passed the original scientific, metadata and layout checker on the current CPU map, with all 512 runtime identities and worker lifetimes qualified.

The optional variant is retained for further experiments. Parallel packing reduced full-provider wall time by a median 7.99% in five alternating pairs, with 2.08% more provider CPU, versus the SIMD-only provider. Its one-hour application used 12.42% more wall time and 15.10% more aggregate CPU than the retained original-provider control. Intervening runs and checks limit that timing comparison; it establishes no application gain. Kernel, caller and model percentages are separate.

Build from the WRF repository root into a fresh directory:

```sh
python3 tools/cpu-output/quilt512/build.py --output-dir <fresh-original-directory>
python3 tools/cpu-output/quilt512/build.py --provider simd-pack --output-dir <fresh-optional-directory>
```

Omitting `--provider` selects the original parent provider `ee9ebe79` and the existing generic GNU 13.3 recipe. The optional branch builds local provider `e29a6a59` with the qualified strict C flags. SIMD is function-scoped and runtime-guarded; no Fortran flags or dependencies change. Parent world-16/64 sources remain unchanged. Check the built artifact against [qualification.json](qualification.json): retained original `4cb1c2` or optional `375aa7e3`. Both branches reproduced those libraries byte for byte in one closed build-only check. The receipts are in [variant-build/result.json](variant-build/result.json); this adds no model qualification.

Use the frozen [current rankfile](placement/current.rankfile) and [rank table](placement/current-rank-map.json): 480 compute ranks in 8×60 plus four groups of eight quilt ranks across hpc01–04. Preserve 128 physical CPUs per node, 100 GiB on hpc01–03 and 104 GiB on hpc04, swap disabled. Writer roots 487/495/503/511 use CPUs 31/63/95/127. Their worker slots are respectively `[31,28,29,30]`, `[63,60,61,62]`, `[95,92,93,94]`, `[127,124,125,126]`, sharing existing compute CPUs. The rejected proposed map is excluded. Preserve the [worker event contract](WORKER_EVENT_SCHEMA.md).

Preload only rank executables with `SELECTED_SHIM:NG`; launcher and helpers have no preload. NG is `/pool/wrf/WPS_new/runtime/zlib-ng/lib/libz.so.1.3.1.zlib-ng`; its directory lacks the required SONAME alias. Preserve the owner-first dependency search and set `WRF_ROOT_SHIM_WORLD=512`, `WRF_ROOT_SHIM_OPTIN=1`, `WRF_ROOT_SHIM_CPUS=0-127`, `WRF_ROOT_SHIM_OWNER=/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19`, `WRF_ROOT_SHIM_LOGDIR=<fresh-log-directory>` and `OMPI_MPI_THREAD_LEVEL=1`. Use `OMPI_MCA_pml=ucx`, `UCX_TLS=rc,sm,self` and `UCX_NET_DEVICES=ibp1s0f0:1`. MPI, NetCDF and HDF5 remain on the main thread; workers join and the main affinity restores before continuation.

Rollback on a new run selects the original provider/retained `4cb1c2` with the same current map, dependencies, b9 physics executable, inputs and resource limits. To disable the shim, omit it or set `WRF_ROOT_SHIM_OPTOUT=1`. For ordinary I/O also remove the NG preload and restore stock dependency search. Existing activation records and [historical qualification](historical-qualification-4cb.json) describe the original artifact; they are not optional-variant launchers.

The optional one-hour gate exercises writers 487/495; 503/511 were idle. It inherits no original-provider three-hour coverage, restart, 144-hour or complete production-chain qualification. The scalar fallback is source-reviewed, with tails tested on AVX2; execution on non-AVX2 hardware remains unqualified. Production deployment is separate.
