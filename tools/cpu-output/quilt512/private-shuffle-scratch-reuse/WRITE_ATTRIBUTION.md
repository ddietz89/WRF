# Short write-boundary attribution

Source proof SHA256: `5e2257360695167744d0ad727caeaca8cef53f25cbb99b0b6cfb4fae1c3996c8`.

Each row belongs to one writer PID and monotonic clock. Callback and chunk brackets may overlap; the report does not total writers.

| Rank | PID | Outer put (s) | Callback union (s) | Chunk within put (s) | Overlap (s) | Put remainder (s) |
|---|---|---|---|---|---|---|
| 487 | 1906973 | 22.480823 | 20.170185 | 2.043187 | 0.000000 | 0.267451 |
| 495 | 1906953 | 12.581869 | 10.789940 | 1.570739 | 0.000000 | 0.221191 |
| 503 | 1906976 | 0.000000 | 0.000000 | 0.000000 | 0.000000 | 0.000000 |
| 511 | 1906957 | 0.000000 | 0.000000 | 0.000000 | 0.000000 | 0.000000 |

One short diagnostic: roots487495positive,503511zero expected. No cross-root/process sum, wholeforecast percentage, isolatedkernel gain, pure disk latency, MPI criticalpath or physicalheadroom claim. Originalscientific/runtime acceptance remains separate.

Unresolved:
- MPI gather and wait: Outside these five public wrappers; no matched MPI/gather entry/exit bracket in this proof. Wall-minus-main cannot provide it.
- pack shuffle codec and worker scheduling: Inside callback envelope collectively; this proof cannot split packing, padding, shuffle, compression, thread startup/join and scheduling. Separate older provider profile fractions do not transfer to this actual run.
- copy and NC HDF bookkeeping: Outer-put remainder is measured union subtraction, not a uniquely attributed copy kernel or removable-work bound.
- HDF chunk cost: H5Dwrite_chunk public API envelope includes HDF/filesystem/wait. It is not pure device service or separate compression cost.
- flush close and final drain: Only captured public H5Fflush/H5Fclose/nc_close calls are reported; they may nest with other calls. Missing public hooks do not establish absent internal flush/close work or complete asynchronous/final drain. Destructor CLOSED proves observerlog closure, not filesystem persistence.
