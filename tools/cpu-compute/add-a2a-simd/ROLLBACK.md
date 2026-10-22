# Rollback

Restore the parent executable `a437888cd99708fc1b10dc05ce2c3c2441c1170a4c1916b7b606a5c2757526fd` and archive `81f6a9509878fe6e94afb15e0a5de41af5e4329e9ca52951f358b81e35951fae` from `/pool/wrf-experiment/wrf-cpu/builds/current4adb-vy-optional-sw-qualified-batch-hpc02-r1` together with the three parent working-selection records. The exact records and their hashes are retained under the experiment's `publication-preparation-r1/PRE_PUBLICATION_A437_SNAPSHOT/`; its full path is in the selected rollback binding after promotion.

Revert the dedicated source promotion of `phys/module_physics_addtendc.F` and `phys/Makefile` together. Alternatively, `WRF_ADDTENDC_SIMD=0` omits this module's SIMD flag in the qualified GNU pure-MPI configuration, but requires explicitly rebuilding the object, archive and executable. Changing a make variable does not invalidate existing objects. An opt-out does not disable externally supplied OpenMP flags.

Keep native failures, caller measurements and application evidence. Restoring the parent does not overwrite installed libraries or production files. Parent a437 qualifications remain historical evidence for that image; they do not qualify a new rebuild.
