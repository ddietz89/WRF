# Thompson automatic arrays on the stack

The current GNU 13.3 Thompson module, compiled with `-fstack-arrays`, passed the original 11-case caller across four rounding modes with exact numerical, read-only, guard and five-word processor-state results. Its preprocessed source is unchanged. The main routine has zero allocation/free sites, down from 71.

The complete synthetic 20,000-call comparison was **5.09% / 4.24% shorter in wall time** and used **5.17% / 4.86% less thread CPU** on hpc01/hpc04. Each arm had its own checked cache clear and normal closure. These are caller gains; forecast frequency and benefit remain unmeasured.

Retain for integration. The existing four-case radar/reflectivity supplement also passed all four rounding modes, and finite codegen/lifetime review is complete. Next qualify the cached application build with the unchanged original checker. The full table-regeneration supplement also passed: all five table records and every rank’s full caller output/state matched with genuine32-rank partitioning. Cold-initialization processor state and O0 remain unqualified. Moving storage from heap to stack does not establish a memory-capacity saving. The selected executable and defaults remain unchanged. [Measurements, scope and rollback](EXPERIMENT.json).
