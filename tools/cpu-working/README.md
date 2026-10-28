# Selected working configuration — October 28

The Thompson module now uses `-fstack-arrays` within the qualified GNU 13.3 strict-O2, default-kind, pure-MPI recipe. Its numerical source is unchanged. Complete-caller wall time was 5.09% / 4.24% lower on hpc01/hpc04, with exact raw output, read-only inputs, guards and all five protected state words. Reflectivity and all five regenerated table records also passed exact checks.

The selected cached image is `9010be04`, archive `47c3847f`. It retains all prior improvements, RSL `e418b187`, output provider `64bb4cf2` and all 18 direct inputs; only the Thompson member changed. Raw producer commit is unknown; `1edd43ea` records post-test source/recipe correspondence. No clean full-source rebuild or byte-identical recipe rebuild is claimed.

Own unprofiled noon qualification passed: two FULL outputs and 185 ordered steps matched the unchanged original checker.

| Metric | Current-parent median, 2 one-hour runs | Thompson child | Descriptive reduction |
|---|---:|---:|---:|
| Wall time (seconds) | 264.5273 | 268.3684 | −1.4521% |
| Main-step elapsed (seconds) | 176.6268 | 174.0371 | 1.4662% |
| Aggregate CPU (core-seconds) | 119599.3863 | 120785.2459 | −0.9915% |

Negative reductions mean higher cost. This unpaired comparison uses the two predeclared eligible current-parent runs, each once. Wall time is within their observed range; no isolated forecast gain or reproducible regression is established. The significant exact caller gains support default inclusion. Main-step elapsed includes communication and waiting. The retained original 75-minute run is a scientific reference only, never a one-hour timing denominator.

The periodic combined three-hour model has closed normally and its unchanged original scientific checker is running. Own three-hour, nine-hour, profile, restart and full-144-hour qualifications remain pending until their actual checks pass; parent results remain historical.

The qualified runtime uses unlimited process stack. Heap-to-stack movement establishes no capacity saving. Set `WRF_THOMPSON_STACK_ARRAYS=0`, rebuild the Thompson object, rearchive and relink to opt out. Retained `00c6bcb3` / `ff31e972` is the whole-image rollback. [Exact evidence and recipe](../cpu-compute/thompson-stack-arrays-20261028/README.md).
