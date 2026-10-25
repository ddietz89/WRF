# V correction and final-update SIMD

Two independent SIMD directives vectorize the V nonhydrostatic pressure correction and final V update in `advance_uv`. The final update also applies on the hydrostatic route. Literal arithmetic, loop ordering, bounds and public interfaces are retained.

| Complete captured caller | hpc01 reduction | hpc02 reduction | Compared parent |
| --- | ---: | ---: | --- |
| V nonhydrostatic correction | 15.8000% | 13.3895% | Selected 971c SmallStep |
| Final V update | 7.8905% | 8.6533% | Correction-enabled SmallStep |

Each arm made 1,024 complete calls, including private allocations, with restore/raw/state checks outside integer-clock intervals. The node orders were opposite; client caches were cleared before every arm. These are separate caller comparisons and their percentages are not added.

Native O2/O0-bounds gates passed raw IEEE values, five-part floating state, readonly inputs, guards, public MOD and unchanged non-target code. Fixtures cycle masked rounding modes; they do not establish every case in every mode or unmasked-trap behavior. Canonical OFF/ON preprocessing and strict object correspondence passed before reusing the qualified object. Only member 558 of the 584-member WRF archive changed; 583 members remain exact.

Both paths are promoted in combined BACF after all four complete full-grid products and 545 ordered steps passed the unchanged corrected-original checker. All model and reader jobs closed normally. Own three-hour science is qualified; short/one-hour/nine-hour/noon/profile/restart/full144 scopes are not inherited. The separate interrupted b362 run and failed BACF R1 validation wrapper remain preserved; the fresh R2 supplied acceptance. No isolated forecast gain is claimed.

[Combined qualification](../rsl-width56-receive-original-fallback-outline/APPLICATION_QUALIFICATION.json), [native/caller evidence](EVIDENCE_REFS.json), [independent opt-outs and rebuild](REBUILD_ROLLBACK.md). Defaults apply within the qualified GNU13.3, type4, pure-MPI SmallStep SIMD/Zen2 scope. Production and master are unchanged.
