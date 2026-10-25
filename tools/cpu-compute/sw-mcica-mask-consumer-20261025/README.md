# Shortwave MCICA cloudy-mask consumer fusion

The working configuration retains all B4BC improvements and removes the temporary `isCloudy` array and its population pass. The existing consumer evaluates the identical `CDF >= 1 - cldf` predicate; RNG draws, seeds, eight output assignments and their order remain unchanged. Source correspondence commit: `af4cabc0`.

The complete generator was **19.32% and 22.79% faster** in one 16,384-call P-C-C-P screen on hpc01. The four arms lasted 0.58–0.76 seconds. These are localized caller observations, with exact raw/state checks, not forecast percentages or a repeatability distribution. Strict native O2/O0 full-generator and exceptional/read-only controls passed in their documented scopes; undefined absent-seed paths are not qualified.

The resulting image `51f1449e` passed its own unprofiled noon one-hour application: both complete products and all 185 ordered steps matched the original exactly. All three models and the protected reader closed normally. Candidate wall was 422.577 seconds, main-step elapsed 345.500 seconds and aggregate CPU 99,916.821 seconds. The retained original is a scientific reference; this application establishes no fresh timing gain. Own three-hour qualification is next. Nine-hour, 512/384-rank, profile, restart and full-144-hour qualifications do not transfer from the parent.

The delivery replaced one cached SW archive member, retained the other 583 members and RSL archive, and linked once. The original build receipt's pending label records its state at build time. The actual code-generation review documents target pass removal and limited relocation/ABI checks without claiming whole-object, MOD or unwind identity.

**Rebuild:** use the exact tested preprocessed source and recorded strict compiler recipe in [REBUILD_RECIPE.json](REBUILD_RECIPE.json). The five-row canonical-source correspondence is exact and invertible; a general clean canonical-F-only rebuild is not certified.

**Rollback:** apply [ROLLBACK_SOURCE_ONLY.diff](ROLLBACK_SOURCE_ONLY.diff), or restore the five rows from `preimages/phys/module_ra_rrtmg_sw.F`, and select the tested B4BC executable/archive recorded in the recipe. This preserves the earlier longwave change and all other improvements. No new runtime knob or compiler flag was introduced.

[Application qualification](APPLICATION_QUALIFICATION.json), [native/caller evidence](EVIDENCE_INDEX.json), [actual noon measurements](noon/RESULT.json).
