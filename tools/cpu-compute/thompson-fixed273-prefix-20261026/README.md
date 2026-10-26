# Thompson fixed-temperature saturation prefix

The liquid-saturation polynomial for the fixed 273.15 K argument is evaluated once at first use per column invocation. Pressure-dependent clipping, division, humidity subtraction and the original variable-temperature call remain per level. A volatile runtime temperature operand preserves evaluation in the current rounding environment; no nearest-mode literal, fast math, shared cache or new ISA flag is used.

Promoted to the qualified GNU 13 working configuration after exact native and application checks. Other compiler stacks remain experimental. The existing private tables and all prior improvements remain included.

| Scope | hpc01 wall reduction | hpc04 wall reduction | hpc01 thread CPU reduction | hpc04 thread CPU reduction |
|---|---:|---:|---:|---:|
| Isolated 32-level kernel, 4 million entries | 73.596% | 73.578% | 73.596% | 73.580% |
| Complete Thompson caller, 20,000 calls | 0.312% | 0.012% | 0.897% | 0.110% |

Both waves include equal mutable restores inside their clocks, checked cache clearing before each arm, strict raw/read-only/five-state checks, and normal closure. The isolated kernel removes unrelated variable-temperature and full-MP work. Its percentage is not a whole-Thompson or forecast speedup; production frequency is not established.

The full module passed 11 original cases under four rounding modes at O2 and bounds-checked O0. The child image `ccbb77e7` passed the unchanged full-grid scientific checker for two output files and 185 ordered noon steps. Its one-hour model/MPI wall was 4.306 minutes, main-step elapsed 2.937 minutes, aggregate CPU 32.365 CPU-hours. The retained original ran 75 minutes and supplies only the scientific prefix; no comparable one-hour timing control or forecast reduction is claimed.

The child owns this unprofiled one-hour qualification. Its own three-hour, nine-hour, restart, profiling and other rank configurations remain unqualified; earlier 4b87 and 0b40 observations are retained separately. Source commit `8b28a688` is actual post-test patch correspondence, with raw producer NULL. Exact tested PP and cached-object delivery are recorded; a clean canonical-F-only build has not been certified.

Intermediate MIN operand priority differs in generated code. Supported source-valid finite thermodynamic inputs and all tested raw/five-state observations pass; this is not a universal NaN-pressure or trapping-environment certificate. Raw whole-module/non-target/pool identity false facts remain in the scoped classification instead of being normalized.

See OWN_NOON_APPLICATION_QUALIFICATION.json, QUALIFICATION.json, EVIDENCE_REFS.json and SOURCE_REBUILD_RECIPE.json. Rollback instructions are in ROLLBACK.md.
