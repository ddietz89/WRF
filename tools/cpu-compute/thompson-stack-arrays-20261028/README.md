# Thompson automatic arrays on the stack

The current GNU 13.3 Thompson module, compiled with `-fstack-arrays`, passed the original 11-case caller across four rounding modes with exact numerical, read-only, guard and five-word processor-state results. Its preprocessed source is unchanged. The main routine has zero allocation/free sites, down from 71.

The complete synthetic 20,000-call comparison was **5.09% / 4.24% shorter in wall time** and used **5.17% / 4.86% less thread CPU** on hpc01/hpc04. Each arm had its own checked cache clear and normal closure. These are caller gains; forecast frequency and benefit remain unmeasured.

Retain for integration. First finish radar-reflectivity and table-regeneration coverage, review the other changed procedures and stack requirements, then qualify the application with the unchanged original checker. Moving storage from heap to stack does not establish a memory-capacity saving. The selected executable and defaults remain unchanged. [Measurements, scope and rollback](EXPERIMENT.json).
