# Combined V-advection and shortwave improvements

Promoted after a fresh original-first three-hour full-grid comparison. All four complete products, metadata/layout, 545 ordered timesteps, 512 ranks, both Y tiles and all four output-writer groups passed the unchanged scientific checker. All eight model jobs and the reader closed normally.

| Measure | Corrected original546b | Combineda437 | Reduction |
|---|---:|---:|---:|
| Model/MPI wall |831.150893s|638.376558s|23.1937%|
| Main-step elapsed sum |610.539530s|554.898530s|9.1134%|
| Aggregate node CPU |374060.951199 CPU-s|310676.786383 CPU-s|16.9449%|

[Qualification](THREE_HOUR_APPLICATION_QUALIFICATION.json), [derived result](RESULT.json), [unaltered raw result](RAW_RESULT.json), [build recipe](REBUILD_RECIPE.json) and [rollback](ROLLBACK.md). The inherited raw result label says X5 child; the actual granted executable is a437 with both VY and SW changes. Only the derived label is corrected; no values or acceptance changed.

One fixed-order pair with separate checked client cache clears, unchanged placement and qualified InfiniBand transport. File-server load/cache remain uncontrolled. Main elapsed includes communication/output backpressure; residual wall is not pure I/O. This is a package observation, not an isolated or additive gain or repeatability claim. The separate VY and SW caller reductions remain separate.

This executable owns this three-hour case only. Daytime/noon, separate one-hour/short, nine-hour and restart qualification do not transfer from its parents. Source d5d09385 is post-test tracking; the raw build producer commit remains null. SW uses the explicit qualified-PP replay recipe. Production and master are unchanged; AWS remains suspended.
