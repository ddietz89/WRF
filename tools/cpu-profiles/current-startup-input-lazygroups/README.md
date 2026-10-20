# Current-build startup input profile

Selected executable81d35/source3de4 passed the unchanged original two-product/35-step,512-rank,two-tile runtime and writer checks. Every model, recorder, watcher, reader and renderer scope closed. This is an observational profile, not a timing comparison or a configuration change.

[Final qualification](FINAL_QUALIFICATION.json) and [parsed summary](ACTUAL_STARTUP_PROFILE_SUMMARY.json) preserve literal raw-report paths and hashes. FQd409eeb3, sciencea131a31f, reader closure9168314e. The previous unavailable captures remain preserved; the successful retry used a fresh0755 directory without weakening a metadata guard.

The root main thread produced362 cycles:u samples over14.9929seconds. Early observations confirmed the same open input inode and raw recorder growth. This bounds selected input-open points, not a continuous or exclusive full-input phase.

| Actual leaf | Samples | Selected cycle-period share |
|---|---:|---:|
|881 zlib-ng inflate_fast_avx2|140|51.2732%|
|WRF input Transpose|16|8.5816%|
|Unresolved high native addresses|109|13.3402%|

The denominator includes all unresolved samples. Counts and cycle-period shares differ; neither establishes whole-forecast removable cost. Native perf marked high-address leaves[k] despite exclude_kernel=1; their mechanism remains unknown. Zero observed LOST records does not establish zero loss. This is on-CPU data with no off-CPU/I/O-wall attribution.

Actual callchains show inflate through HDF5 deflate/chunk reads and NetCDF, and Transpose through ext_ncd_read_field and input_wrf. The16 transpose IPs map to the current XZY read DI1 scalar ABS loop. A separate guarded affine READ candidate is being tested; the accepted earlier affine specialization is WRITE-only. No candidate benefit or application qualification follows from this profile.

All140 inflate samples were joined to the exact retained881 assembly. They hit existing Huffman field decode and AVX2 overlap-safe copy paths already covered by the closed audit. No distinct scalar optimization was identified, so no repeated codec benchmark was launched. Parallel input decode is a separate feasibility question.

Source, scientific checker and selected runtime remain unchanged. Rollback is unnecessary for these evidence-only files; model rollback remains the selection's recorded b1fb/source4e70.
