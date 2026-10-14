# Private quick-insertion codec

The current world-512 one-hour working configuration passed the original exact application comparison. This package does not install into `/pool/wrf/WPS_new`, change system loader configuration or activate a model.

Upstream zlib-ng commit `12731092979c6d07f42da27da673a9f6c7b13586` supplies the integer insertion body. The private helper in `deflate_fast.c` preserves endian reads, uint32 hash wrap/shift/mask, full-width head comparison, uint16 narrowing and prev-before-head store order. Only two direct call names change. Level 2, window 15, memory level 8, default strategy, format and all match/tree decisions remain unchanged. Original source, configured build and installed library are immutable.

Reproduce from the retained qualified GNU 13.3 build, into a fresh directory:

```sh
python3 tools/cpu-output/quilt512/codec/build.py --output-dir /pool/wrf-experiment/wrf-cpu/builds/<fresh-codec-directory>
```

The recipe uses the exact pinned original compiler/flags/headers and 71 PIC objects, replacing only `deflate_fast.lo`. It checks the other 70 objects, original sources/library, exports, SONAME/dependencies and eliminated calls, then requires exact qualified library `bac29f50`. It never configures/rebuilds the original dependency or writes its installation. This is reproducibility for the retained GNU 13.3 setup, not a portable arbitrary-toolchain build or new runtime qualification. Scope is the tested private compatibility ABI and world-512 working configuration; production, other compilers/CPUs, restart and other consumers remain separate.

The world-512 provider builder selects `--codec inline` by default. `--codec original` explicitly selects retained `5d69c443`; `--codec-library <absolute-path>` may select a reproducible private rebuild only if its bytes match the chosen variant. The generated `rank-preload.env` defines `WRF_QUILT_RANK_PRELOAD`; use it only in the WRF-rank `mpirun -x LD_PRELOAD=...` argument. Do not globally export LD_PRELOAD to Python, ssh, helpers or mpirun. The provider binary itself is unchanged by codec selection.

Native evidence: seven complete corpus encodings and stock decodes were exact; five actual-chunk codec pairs showed median 2.948989% wall / 2.936469% CPU savings. The complete four-worker provider replay matched all streams and 40 stock decodes, with median 4.205883% wall / 3.332020% CPU savings. One provider wall pair regressed 2.096627%, and variation remained substantial. These are separate caller observations, not additive percentages, callback wall ceilings or application benefits. The fresh combined transpose/inline-codec one-hour comparison passed both complete 06/07 products and all 185 ordered steps, metadata/layout/runtime checks. Control-first model wall was 477.813882 → 427.452763 seconds (10.539903% lower), aggregate CPU 221168.801980 → 197710.480472 seconds (10.606524% lower). This is one combined fixed-order observation with cache/order/shared-load limits, not isolated attribution, additive kernel gain, repeatability or a three-hour claim. SCI `b669bd67` and reader closure `bb51636e` are pinned in selection.json.

Rollback codec selection independently with `--codec original` and the retained library. Revert the codec-selection commit to restore the previous build interface if necessary; no physics or I/O rebuild is required for runtime-library rollback. Retain the private candidate and all original failure/historical records.
