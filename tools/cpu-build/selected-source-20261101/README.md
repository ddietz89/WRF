# Reproducible build of the selected configuration (2026-11-01)

Rebuilds the selected optimised WRF from committed branch source — no manually swapped objects.

Inputs
- Source: `perf/cpu-20261012` commit 3919078b (tree 1d6c9774). Upstream sets `* export-ignore`, so the source tarball is
  a `git worktree` checkout of that commit tarred with `--sort=name --owner=0 --group=0 --mtime='2026-11-01 00:00Z'`
  (sha256 recorded in build_selected_source.sh). Pinned submodules (phys/GFL, MYNN-EDMF, MYNN-SFC, TEMPO,
  fire_behavior, noahmp, physics_mmm) are copied from the clean r4 source tarball.
- Toolchain: GNU 13.3.0, OpenMPI+UCX+xpmem under /pool/wrf-experiment/toolchains/gnu/13.3.0.
- configure.wrf: clean-head-generic-r4 (sha 6d2d788b…) with ONE edit `FC = $(DM_FC)` (the stock `time` prefix makes
  every qualified-optimisation eligibility probe fail), then `configure.overlay.wrf` appended.

Overlay (configure.overlay.wrf)
- Per-target CPPFLAGS (same `private override` mechanism the Makefiles use) for TPI Thompson/start_em/module_wrf_top,
  big-step utilities (HPG-NHX AVX2, phy-height row, ordered diffusion, …) and RRTMG LW/SW macro sets.
- `-fopenmp-simd` for module_bc; forced GWDO first-hit eligibility (source hash still verified by select_pp.py).
- Corrected RSL_LITE rule (compiler and flags passed separately) so the RSL feature gates evaluate.
- Helper objects built from tools/ (TPI shared_table*, thompson_tpi_bridge, HPG-NHX AVX2, phy-height row) via LIB_LOCAL.

Result vs preserved selected artifact (352f lineage + radar-v2, wrf.exe 63f29332)
- libwrflib 585/598 members byte-identical; RSL 14/14; libwrfio_nf 3/3; pack_utils .text identical; 4/5 helpers identical.
- Remaining 13 members: 5 differ only in embedded path strings; 8 come from older source revisions of the selected
  lineage (line numbers / error-call forms; module_dm and module_io_quilt verified cosmetic). Whole-executable byte
  identity with 63f29332 is therefore NOT claimed. Acceptance is by the original exact science checks and timing.
