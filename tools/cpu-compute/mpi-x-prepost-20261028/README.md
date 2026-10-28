# Non-typed X receive preposting

The first full-grid, one-hour baseline→candidate pair passed the original exact checker: two complete products and 185 ordered steps per arm. Against the current optimized baseline, wall time was **4.75% lower**, aggregate CPU use **5.54% lower**, and main-step elapsed time **0.86% lower**.

Most of the wall-time difference was outside the timestep loop. Retain this candidate as promising and check the reverse order before promotion; prior uniform caller timings were slightly slower. These are incremental results against the current build. [Measurements, scope and rollback](EXPERIMENT.json).
