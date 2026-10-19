# C-owned quilt field views

The qualified working configuration sets `WRF_QUILT_OWNED_FIELD_VIEW=1`. Ordinary quilt output can gather directly from each C-owned cached field, avoiding the previous copy into a Fortran retrieval buffer. The independent root output buffer and original STORE deep copy remain. This is not MPI zero copy and establishes no physical-memory peak reduction.

The typed contiguous view remains separate from the gather ALLOCATABLE. The blocking gather completes before its pointer is nullified and the C field is released; the backend reads the independent root buffer afterward. Whole-batch admission checks size, alignment and integer representation before freeing the gather allocation or advancing the cursor. Unsupported batches and an unset/zero option use the original retrieval path. Parallel NetCDF remains outside this change and its qualification.

Opposite-order complete synthetic buffer-handling intervals were **5.0390% and 5.9249% shorter**, with exact bytes and state. Each arm includes restoring 8 GiB of input, STORE deep copies and the ownership protocol; the candidate removes a separate 8 GiB retrieval copy. MPI and the backend consumer are absent from this fixture. These percentages are not forecast gains.

The native production-C/typed-Fortran gate, four-local-rank MPI lifetime fixture and repaired ten-minute application passed. The initial short application recorder failure and premature configuration-getter guard remain preserved in the campaign evidence. The repaired build removes that lookup and reports the first successful acquisition directly.

The combined three-hour application passed the unchanged original checker: all four complete products, 545 ordered steps, all-512 runtime checks and successful acquisitions on all four required roots. The result and scope are recorded in `QUALIFICATION.json`. Qualification is GNU 13.3 strict arithmetic, ordinary NetCDF2, the documented 512-rank/two-tile layout and current runtime; no other compiler, restart, 144-hour or current-image nine-hour result is claimed.

Rollback: set `WRF_QUILT_OWNED_FIELD_VIEW=0` or unset it for the legacy retrieval path. Select retained executable `f0641466ada307c221b8a0247120bd612367336bee25191dab3ec0c07a0a3211` to roll back both this change and the first MYJPBL input-pack directive, with provider375/codec881/HDF5825/rankmapfaba unchanged. The dedicated source commit can also be reverted and rebuilt. Production and master are untouched.
