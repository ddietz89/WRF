# Short write-boundary attribution

Source proof SHA256: `286083999438a2a36b996e3df62b11b0e7892b1587404e732ebf5a1926c62e81`.

Each row belongs to one writer PID and monotonic clock. Callback and chunk brackets may overlap; the report does not total writers.

| Rank | PID | Outer put (s) | Callback union (s) | Chunk within put (s) | Overlap (s) | Put remainder (s) |
|---|---|---|---|---|---|---|
| 487 | 1902100 | 23.425117 | 21.069411 | 2.110895 | 0.000000 | 0.244811 |
| 495 | 1902096 | 12.883831 | 11.136823 | 1.527835 | 0.000000 | 0.219173 |
| 503 | 1902103 | 0.000000 | 0.000000 | 0.000000 | 0.000000 | 0.000000 |
| 511 | 1902099 | 0.000000 | 0.000000 | 0.000000 | 0.000000 | 0.000000 |

One short diagnostic: roots487495positive,503511zero expected. No cross-root/process sum, wholeforecast percentage, isolatedkernel gain, pure disk latency, MPI criticalpath or physicalheadroom claim. Originalscientific/runtime acceptance remains separate.

Unresolved:
- MPI gather and wait: Outside these five public wrappers; no matched MPI/gather entry/exit bracket in this proof. Wall-minus-main cannot provide it.
- pack shuffle codec and worker scheduling: Inside callback envelope collectively; this proof cannot split packing, padding, shuffle, compression, thread startup/join and scheduling. Separate older provider profile fractions do not transfer to this actual run.
- copy and NC HDF bookkeeping: Outer-put remainder is measured union subtraction, not a uniquely attributed copy kernel or removable-work bound.
- HDF chunk cost: H5Dwrite_chunk public API envelope includes HDF/filesystem/wait. It is not pure device service or separate compression cost.
- flush close and final drain: Only captured public H5Fflush/H5Fclose/nc_close calls are reported; they may nest with other calls. Missing public hooks do not establish absent internal flush/close work or complete asynchronous/final drain. Destructor CLOSED proves observerlog closure, not filesystem persistence.
