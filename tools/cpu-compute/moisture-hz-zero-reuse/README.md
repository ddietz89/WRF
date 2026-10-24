# Moisture h/z zero reuse

This component reuses the defined-zero h/z tile scratch for later admitted moisture species in nonfinal RK stages. The first admitted species clears both tiles normally; readiness resets each RK stage. Final-stage, IEVA, absent/false-option and unsupported threaded paths keep the original clears. The new option is independent of WW readiness.

Five-role native comparisons passed the original full raw, physical-footprint, read-only and five-state gates. The configured six-species, two-tile caller measured wall reductions of **1.5746% on hpc01** and **0.2571% on hpc04**, with process CPU reductions of **1.5558%** and **0.6452%**. These are single opposite-order node pairs of 1,152 complete routine calls, approximately 0.4 seconds of call-only elapsed time. Checks/restores stay outside the clocks. Shared NFS/server load was not isolated; no forecast or statistical-significance claim follows.

The independent assessment recommended parking integration; the owner explicitly retained the candidate for guarded integration. Both records remain preserved. The isolated b21c/0e4d child build passed the two-member inventory and link checks. The b21c child passed its own original two-product, 35-step scientific comparison and positive model/reader closures. All child long-horizon/profile/restart flags remain false.

`WRF_MOISTURE_HZ_ZERO_REUSE=0` opts out independently within the existing qualified WW build contract. The qualified ON interface changes h/z to INOUT and adds a separate optional flag; all four selected solve callsites were freshly compiled against MOD165d. Generic OFF preserves the original interface. See [rebuild](REBUILD_RECIPE.json), [evidence](NATIVE_AND_CALLER_QUALIFICATION.json) and [rollback](ROLLBACK.txt).

Source/default publication is backed by the actual own short science PASS. Raw producer commit is unknown; a later source commit records correspondence after testing.
