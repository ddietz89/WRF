# Thompson reflectivity fixed-capacity storage: unpromoted

R4 passed correctness, but its complete caller showed mixed performance. The fixed candidate is closed without source, default or application promotion.

| Host | Parent wall (s) | Candidate wall (s) | Wall result | Thread CPU result |
|---|---:|---:|---:|---:|
| hpc01 | 0.653955927 | 0.673641809 | 3.0103% slower | 3.0232% slower |
| hpc02 | 0.655499651 | 0.651543542 | 0.6035% faster | 0.6033% faster |

The genuine complete `calc_refl10cm` screen used 2,048 calls, including the original scratch lifecycle and identical input/output restores inside the integer wall/thread-CPU batch. All four arms passed full raw output, separate warm/batch five-state records, cache clearing and normal closure. No consistent significant caller benefit or separate positive kernel benefit was established. This does not establish a universal regression or forecast effect.

The candidate replaces 28 private scratch allocations with fixed 33-element backing arrays and exact active pointer views for `1 <= kts <= kte <= 33`. Other bounds retain the original dynamic storage. `VOLATILE` on `rhof` backing and its pointer preserves the original runtime division and square root. The original fixed-storage candidate’s exception-state failure remains retained.

R4 passed 112 full physical/read-only/raw/five-state records per role at each of O2 and O0, across four rounding modes. Callers use the original public MOD. Candidate raw MOD bytes differ by the explicitly reviewed procedure-analysis flag; no MOD was rewritten. Scoped O2 machine and referenced constant-byte checks passed. O0 whole-module structural identity, universal unmasked trap chronology and whole-TU byte equality are not claimed. Fixed scratch capacity is not a measured RSS benefit.

The original warm-versus-empty-batch fixture failure and the first 131,072-call parent timeout are preserved. The finite fixture reset repair and one fixed-count correction produced the results above; no failed timing was accepted. The copied decision, native/interface/machine proofs and waveform are byte-exact peer closeout evidence.

No reflectivity application was run. The existing selected Thompson member remains unchanged. Private canonical and conditional three-component proposals remain unused; no reflectivity source or default was installed. Reopening requires a new measured mechanism or concrete production/resource evidence, rather than repetitions of this candidate or count.
