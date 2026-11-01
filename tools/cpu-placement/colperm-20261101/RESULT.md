# Column-to-host permutation (placement only) — 2026-11-01

Motivation: rank map faba puts each decomposition column on one host (i→hpc0(1+i%4)); hpc01/hpc02 sustain
~9% lower clocks (node-clock-r1/FINDING.md). Rank→patch unchanged, so science is unchanged by construction;
each host keeps its exact core pattern (rank (i,j) takes the host/cpu of original rank (P(i), j)).

| Map | Columns → hosts | Main-step s | Wall s | Science |
|---|---|---|---|---|
| control (faba) | 0,4→01  1,5→02  2,6→03  3,7→04 | 514.4, 513.3, 511.0 (median 513.3) | 599.4, 599.0 | exact |
| colperm-a | 0,4→01  3,5→02  1,2→03  6,7→04 | 507.0, 508.7 (median 507.9, −1.1%) | 591.5, 594.1 | PASS ×2 |
| colperm-c | 0,1→01  4,5→02  2,3→03  6,7→04 | 511.5 | 591.8 | PASS |
| colperm-b | (rank 0 moved to hpc02) | — | — | refused: input adapter requires rank 0 on hpc01 cpu 0 |

All maps equal through step 402 (373–375 s); colperm-a's gain is in the late, precipitation-heavy steps.
Adjacency alone (colperm-c) gives no measurable gain; the effect is heavy columns on fast nodes.
Pins: map-pins.json. Harness: scratchpad colperm_patch.py (variant registered in multinode_mpi, runtime_combined,
placement_map_proof pins; runtime_checks variant list; batch_release allows rank_map/variant and per-host
rank_physical_cpus order).
9h exact check: production512-radarv2-colperma-ninehour-r2 PASS_ORIGINAL_TEN_HISTORY, wall 1623.6 s vs 1657.2 s (−2.0%), main 1538.8 vs 1572.4 s.
