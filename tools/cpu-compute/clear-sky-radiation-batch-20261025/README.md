# Clear-sky radiation batch — October 25, 2026

Promoted to the working fork after the unchanged original checker accepted both complete noon products and all 185 ordered steps on hpc01–03, with 256 ranks and two tiles. All models and the reader closed normally. Production and master are unchanged.

The shortwave change adds a maskless clear-active REFTRA entry and removes the caller’s always-true mask pass; the original masked entry and cloudy call remain. The longwave change defers repeated clear-prefix mirror stores to one band copy, preserving the recurrence, seeds and arithmetic.

REFTRA caller wall reductions were 5.83% and 0.60%; whole SPCVMC was mixed (+1.36%, −0.58%). Partial-prefix whole RTRNMC reductions were 1.18% and 1.19%; other regimes were mixed. These are scoped caller observations, not forecast percentages. Native O2/O0 raw/IEEE/read-only/guard/state checks passed. All 20 caller timing executions had their own cache clear and normal closure.

[Application qualification](APPLICATION_QUALIFICATION.json), [complete observations and limits](DECISION.json), [rebuild recipe](REBUILD_RECIPE.json), [retained original comparison](DESCRIPTIVE_NOON_COMPARISON.json). This image’s own three-hour, nine-hour, 384-rank and four-node qualifications remain pending.

Qualified reproduction uses the exact tested whole preprocessed sources in `qualified-pp/`, matching recorded compiler recipes and private module interfaces. Canonical target patches correspond; a general canonical-F-only rebuild is unproven. Compiled structural differences remain explicitly scoped.

Rollback: restore the [parent selection](PARENT_SELECTION.json) and matching 256-rank providers, or reverse the two [source patches](ROLLBACK_SOURCE_ONLY.diff), restore parent radiation members and relink. Existing parent and failed-attempt evidence stays preserved.

### Own three-hour qualification

B4BC passed its own same256 three-hour 545-step/four-full-product application with all six models and the reader normally closed. One fresh original546b→B4BC fixed-order pair produced the measurements below. The arms were separated by scheduled maintenance (A ended around 06:29 UTC, B began around 06:51 UTC); this is not a counterbalanced or repeatability result. The earlier noon 185-step qualification remains immutable and separate. No own 9h, 512, 384, profile, restart or full144 qualification transfers.

| Metric | Original546b | B4BC | Reduction |
|---|---:|---:|---:|
| Wall (min) | 21.399520 | 18.382313 | +14.0994% |
| Main elapsed (min) | 18.093336 | 16.745051 | +7.4518% |
| Summed CPU (core-h) | 84.375622 | 75.896851 | +10.0488% |

[Qualification](THREE_HOUR_APPLICATION_QUALIFICATION.json); [actual result](three-hour/RESULT.json); [unchanged exact-checker receipt](three-hour/science-receipt.json); [reader normal closure](three-hour/reader-closure.json). The separate original noon qualification above is unchanged. Rollback/build instructions remain unchanged; this adds evidence for the same B4BC image.
