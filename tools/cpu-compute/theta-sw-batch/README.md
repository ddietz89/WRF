# Moist-theta SIMD and shortwave direct CDF

The qualified working configuration selects actual executable **a50e5cf7** and archive **4b16c9ff**, retaining every previous f4b improvement and its runtime libraries. Source-only commit **97512cc69b4f144c399fb04bcebf8d146ddc78ff** installs the two tested canonical sources; frozen build/native/caller producer commits remain null. Production and master are unchanged.

The moist-theta change adds one independent-I SIMD directive without changing scalar arithmetic. Its isolated loop is 74.6–74.9% shorter; complete `phy_prep` timings are neutral. The shortwave case-2/irng-0 change writes the original KISS result directly into CDF, preserving seed-update order, conversion and burn draws. Its complete generator is 34.42–34.58% shorter in opposite-order pairs. These are separate kernel/caller measurements, not additive forecast savings.

The unchanged original scientific checker passed four outputs/545 ordered steps in a fresh corrected-original control followed by the combined candidate, then two outputs/230 steps in the existing noon daylight case. All new model and reader scopes closed normally. Both source files match the actual tested canonical SHA256 identities in [POST_TEST_SOURCE_IDENTITY.json](POST_TEST_SOURCE_IDENTITY.json).

| Fresh three-hour pair | Original | Combined | Reduction |
|---|---:|---:|---:|
| Whole model/MPI wall |947.713664s|661.091632s|30.2435%|
| Main-step elapsed sum |725.013200s|560.407420s|22.7038%|
| Aggregate four-node CPU |432906.028505 CPU-s|320598.551647 CPU-s|25.9427%|

One fixed-order pair establishes no repeatability or isolated contribution. The candidate is almost unchanged from the previous f4b run (661.040449s), while this control is slower than the previous retained control (819.278306s). The larger percentage therefore cannot be credited to the two newest changes. Main-step elapsed includes communication/backpressure and is not integration CPU; whole-minus-main is not pure I/O. Client caches were cleared before each fresh arm; server cache/load were uncontrolled. The wall ratio is 1.43356×, without a concurrent-throughput or sustained nine-hour claim.

The noon candidate's descriptive totals are311.369271s whole wall,235.055660s main-step elapsed and151882.834889 CPU-s. Its retained scientific reference is444.666163s/262.597160s/194209.614414 CPU-s. Those are unpaired scientific-context observations, not a new benchmark. Own three-hour and noon75m science are qualified; own ten-minute and nine-hour qualification remain false.

Qualifications bind GNU13.3 strict flags, the existing module-local SIMD configuration,512 ranks/480 compute/two tiles, the qualified single InfiniBand rail and selected input/output/codec/table-sharing artifacts. AOCC and Intel remain experimental. Shortwave's target MCICA module interface and callers compiled against original MODs passed; all32 raw compiler MOD bytes are explicitly **not** certified. Bounds/O2, rounding/exceptional-state coverage, codegen, caller records and retained failures are preserved in the component proofs.

The retained noon control uses its original historical closure schema; unavailable historical manager-journal/absent-cgroup certificates are not fabricated. The supplemental assembler handles that exact frozen reference explicitly. New candidate/reader and fresh three-hour strong closure checks remain unchanged. The original assembler failure and parser-only repair are retained under `historical-parser/`.

[THREE_HOUR_APPLICATION_QUALIFICATION.json](THREE_HOUR_APPLICATION_QUALIFICATION.json) and [NOON_APPLICATION_QUALIFICATION.json](NOON_APPLICATION_QUALIFICATION.json) bind actual science, original checker, cache boundaries, runtime identities and closures. [RAW_SOURCE_MAP.json](RAW_SOURCE_MAP.json) distinguishes byte-exact copies from detailed raw receipts/member tables retained at their original recorded paths. `theta/REBUILD_RECIPE.json` and `sw/REBUILD_RECIPE.json` retain the actual ordered overlay recipes and member hashes. They are frozen build records, not launchers. A fresh whole-image source rebuild has not inherited application qualification merely from source identity.

Rollback: restore **both** canonical source files from the parent of97512cc6 and the three paired working records in [ROLLBACK.json](ROLLBACK.json). That selects actual f4b/a43 with the same runtime libraries. Reversing only the SW patch leaves theta enabled. Use fresh leases and the cache-before-each-arm SOP for later runs.
