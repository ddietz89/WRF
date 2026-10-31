# Clean full-source build: scope corrections (2026-10-31)

- **Memory.** The canonical build peaks at ~86–88 GiB anonymous memory per node in the
  three-hour run, versus ~46–48 GiB for the selected 352f image. The difference is the Thompson
  shared-table path (`WRF_EXPERIMENTAL_TPI_NUMA`), which by design is not defined by canonical
  make (see `tools/cpu-memory/thompson-table-sharing/BUILD_WIRING.json`). Science and main-step
  time match; resource footprint does not.
- **RSL features absent.** `external/RSL_LITE/makefile` derives the compiler version from
  `$(lastword $(FC))`, but WRF passes `FC="time mpif90 <flags>"`, so the version is empty and the
  early-Y and copy features never build; the early-Y guard also reads CFLAGS/CPPFLAGS, which WRF
  does not pass to RSL. The selected image's RSL archive came from a separate recipe.
- **Restart.** See `../restart-canonical-20261031/RESULT.json`: the canonical build restarts
  exactly (split restart files); the selected TPI configuration does not support restart by design.
