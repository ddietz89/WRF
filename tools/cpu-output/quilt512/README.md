# Opt-in world-512 quilt compression package

This package is promoted to the working fork as an explicit opt-in configuration. Production deployment remains separate. The source is the frozen `313e18ed` fresh shim; qualified world 16/64 source and binary remain untouched. The existing provider and ABI headers are reused from the parent `tools/cpu-output` directory by exact hashes, not copied or rewritten. Package path: `tools/cpu-output/quilt512/`.

Native R6 passed real world 1 owner/provider/resource tests, same-source four-worker lifecycle observation, independent packing/fill/raw-bit decode and same-codec encoded comparisons, and the final shared object's ineligible-world decline. Native R6 alone is not positive world 512 activation. The separate one-hour world 512 model now passes the original two complete history products, science/metadata/layout and all 185 observed steps, with all 512 runtime identities qualified. Writers 487 and 495 each completed 216 balanced callbacks/releases/restores with zero errors or pending batches. Writers 503 and 511 were not exercised. The original coordinator-wrapper failure `8416859b` is retained; additive revalidation `5d773da5` and its closed receipt `1215868e` establish the runtime evidence used by the successful original checker. Exact science/closure pins are recorded in [qualification.json](qualification.json). The subsequent three-hour matched pair passed all four complete products and all 545 ordered observed steps under the original scientific/metadata/layout checker. All 512 runtime identities and all four writer lifecycles passed; each writer completed 216 balanced callbacks/releases/restores, with zero errors or pending batches. Stock model/MPI wall was 1,099.838 seconds versus 946.006 seconds combined (13.99% lower), with 9.53% less aggregate cgroup CPU. This is one stock-first pair with uncontrolled order/cache/shared-load effects, not an isolated compression or statistical gain.

Only actual world 512 ranks 487/495/503/511 on hpc04 may activate. Main MPI rank/thread/FUNNELED-or-better, exact owner symbols, cgroup and singleton guards remain mandatory. Other ranks and unsupported worlds follow the ordinary public entrypoint.

| Writer rank | Owner CPU | Worker CPU slots |
|---|---:|---|
| 487 | 31 | 31, 28, 29, 30 |
| 495 | 63 | 63, 60, 61, 62 |
| 503 | 95 | 95, 92, 93, 94 |
| 511 | 127 | 127, 124, 125, 126 |

Extra slots share existing compute CPUs. There are no dedicated spare cores: each node retains 128 available CPUs/quota cores. The qualified lease is 104 GiB on hpc04, 100 GiB on the other nodes, swap0, with fresh admission. Both arms used equal new caps; any future comparison must preserve them; existing 100 GiB runs are not mutated. No automatic OOM retry or cap increase.

HDF/NetCDF/MPI stay on the main thread. Byte workers join and the main singleton restores before backend continuation. One unreleased batch/process, first-request 56 MiB chunk / 64 MiB compressBound envelope, immutable request fields and terminal later errors prevent ordinary fallback after partial commit. Shared worker lifetimes must pass the exact [event contract](WORKER_EVENT_SCHEMA.md).

`build.py` is a tested build-only recipe for existing GNU 13.3 / OpenMPI 4.1.6 / NetCDF-C 4.9.2 owner 8adc / Fortran 4.6 / HDF 1.14.3 dependencies. Its C flags match the tested package recipe: O2, C11, pthread, PIC, with no fast-math enabled. It installs nothing, fetches nothing, and does not rebuild dependencies. From the fork root, use the command below with a fresh owned output directory; shared sources resolve from the parent package. The package recipe ran once on hpc02 and reproduced the qualified native SO `4cb1c2` byte for byte. The unit closed successfully; exact source, compiler/link argv, binary and closure receipts are recorded in [qualification.json](qualification.json). This build result adds no model coverage or timing claim.

From the intended repository root, build into a fresh owned directory:

```sh
python3 tools/cpu-output/quilt512/build.py --output-dir <fresh-owned-directory>
```

The nested recipe defaults to the adjacent `tools/cpu-output` shared sources.

On a new run, preload ONLY rank executables with `NEW_SHIM:NG`, where NG is `/pool/wrf/WPS_new/runtime/zlib-ng/lib/libz.so.1.3.1.zlib-ng`. Helpers and launcher have no preload. NG directory lookup alone is insufficient because it lacks the needed SONAME alias. Set `WRF_ROOT_SHIM_WORLD=512`, `WRF_ROOT_SHIM_OPTIN=1`, `WRF_ROOT_SHIM_CPUS=0-127`, `WRF_ROOT_SHIM_OWNER=/pool/wrf/WPS_new/runtime/netcdf-owner/lib/libnetcdf.so.19` and `WRF_ROOT_SHIM_LOGDIR=<fresh-owned-log-directory>`, plus numeric `OMPI_MPI_THREAD_LEVEL=1`. The owner directory precedes stock NetCDF; qualified MPI precedes deps in library search. Actual maps, all 512 identities, main/worker lifetimes, positive exercised-writer callbacks and balanced releases/restores must be checked. No callback count is invented.

To opt out on a NEW run, omit the new shim or set `WRF_ROOT_SHIM_OPTOUT=1`. For full ordinary rollback, remove both new shim and NG preloads and restore the original stock dependency search while retaining the qualified b9 physics executable, input cadence, decomposition and quilts. Do not change a live process or lease. Retained corrected-stock 546b is a separate source-control reference, not an automatic rollback of b9 correctness/performance source changes.

Original complete scientific equality/masks/nonfinites, metadata/layout and ordered observed steps remain the model gate. Native raw-bit guarantees are separate. No 144-hour, restart, ISA, alternate topology, external compiler or full-chain coverage is inherited. The measured gain applies to this combined three-hour configuration only; individual kernel and earlier application percentages are not added.
