# radar-memo-r1 notes
- v1 (memo.F e70a0a8b, exe c7f033e0): 3h exact PASS x2, main 515.9 / 519.3.
- v2 (v2.F fecf6118, exe 63f29332): native bitwise harness 600k calls 0 diffs; microbench 719 -> 371 ns/call
  (-48%); 3h exact PASS r1 main 514.4; r2 pending. (Microbench ran ~2 s on hpc02 cpu 8 during rv2 run.)
- Zen2 small_step/advect already in canonical flags (no lever).
- radar-v2-zen2dyn-352f-r1 INVALID: appended module_em.o, which 352f removed for the rkscalar lineage.
- radar-v2-zen2diff-352f-r1 (exe 6786e3d5): v2 + module_diffusion_em with -march=znver2 -mno-fma; member list
  identical to 352f, .mod unchanged, only scalar libm calls. Pending run.
- TIMING CONTAMINATION (self-inflicted): radar-v2 build 23:09 overlapped v1 r2 window (23:05–); bench 23:41 +
  zen2 builds 23:43/23:44 overlapped v2 r2 window (23:40–23:52, main 571.3 s). Both samples exact PASS but
  timing invalid. Valid: v1 r1 515.9, v2 r1 514.4.
