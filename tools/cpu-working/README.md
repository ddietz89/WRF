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

Own unprofiled three-hour qualification also passed: all four FULL outputs and 545 ordered steps matched the unchanged original checker. All four model units and the reader closed normally.

| Metric | Retained original median, 3 three-hour runs | Current combined image | Descriptive reduction |
|---|---:|---:|---:|
| Wall time (seconds) | 800.0241 | 629.6362 | 21.2978% |
| Main-step elapsed (seconds) | 596.4505 | 530.4991 | 11.0573% |
| Aggregate CPU (core-seconds) | 359327.3470 | 306042.9733 | 14.8289% |

This candidate-only, unpaired comparison describes the combined image against the retained original median of three runs. It does not isolate Thompson's contribution, establish repeatability or form a matched speedup measurement. The raw collector's retained A2 control row is the scientific reference, not the timing median. The separate noon comparison above uses its own current-parent cohort; the two cohorts are not pooled. [Three-hour evidence](../cpu-compute/thompson-stack-arrays-20261028/THREE_HOUR_APPLICATION_QUALIFICATION.json).

Own nine-hour, profile, restart and full-144-hour qualifications remain false; parent results remain historical.

The qualified runtime uses unlimited process stack. Heap-to-stack movement establishes no capacity saving. Set `WRF_THOMPSON_STACK_ARRAYS=0`, rebuild the Thompson object, rearchive and relink to opt out. Retained `00c6bcb3` / `ff31e972` is the whole-image rollback. [Exact evidence and recipe](../cpu-compute/thompson-stack-arrays-20261028/README.md).
