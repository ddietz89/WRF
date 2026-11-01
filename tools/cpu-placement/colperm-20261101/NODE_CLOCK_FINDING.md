# Node clock asymmetry (2026-11-01)

Critical path = decomposition columns i=1 and i=5 (diag v3: column-mean compute 321.1 / 307.2 s vs 290–310).
Rank map faba places each column on ONE host: i=0,4→hpc01; i=1,5→hpc02; i=2,6→hpc03; i=3,7→hpc04.

Same-row profile (run production512-radarv2-prof3h-r6, ranks 72/73/74/77 all on cpu 34 or 50): dynamics
symbols take ~40–130% more samples on the hpc02 ranks for identical work (advance_w 3.73/5.92% vs 2.57/2.60%).

Measured during production512-heapretain-radarv2-3h-r4 (scaling_cur_freq mean over compute cores, 15 s cadence,
steps 20–544; BMC temps):
  hpc01 2697 MHz (max 2746)   hpc02 2721 MHz (max 2836) CPU 67/56 C
  hpc03 2972 MHz (max 3396) CPU 60/60 C   hpc04 2954 MHz (max 3398) CPU 67/64 C
→ hpc01/hpc02 sustain ~9% lower clocks and never boost above ~2.84 GHz. Not thermal (hpc04 equally hot at full
clock). OS-visible settings identical (acpi-cpufreq, schedutil, boost=1, max 2.25 GHz nominal, BIOS 2.1
02/21/2020, 16x8 GB 3200 MT/s, EDAC 0). Points to firmware power policy (determinism slider / cTDP / PPT /
boost policy) on hpc01/hpc02.

Estimated value if matched: column compute normalized to full clock → critical becomes i=7 (~310 s) instead of
i=1 (321 s): ~3–4% of main step. Requires BIOS/BMC change on hpc01/hpc02 — owner/admin action, not applied.
Control sample this run: main 511.0 s (radar-v2 selected runtime; exact reader pending).
