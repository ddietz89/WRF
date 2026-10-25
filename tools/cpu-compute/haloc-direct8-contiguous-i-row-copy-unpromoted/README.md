# HALOC direct8 contiguous-I copy: unpromoted

This private candidate replaces the direct8 prototype's per-word four-byte copies with one row-span memcpy per field/J/K row. Ownership, packet ordering, MPI calls, allocation, metadata, fallback, and the public entry remain unchanged.

The standalone leaf passed 72 reference/candidate transfer pairs across raw payloads, unaligned storage, empty ranges, four masked rounding controls, readonly inputs, guards, and five-state checks. The retained genuine nine-rank native oracle also passed all 16 records per rank, including 12 fast and four fallback records, physical bytes, five-state, and request completion.

The complete caller screen was rejected. On hpc01, the original Y/X path took 290,831,389 ns maximum rank wall time versus 484,773,721 ns for row-copy direct8, approximately 1.67 times as long. Summed rank main-thread CPU was 2,615,268,789 versus 4,361,392,601 ns. These are diagnostic first-pair costs on a synthetic local 3x3 footprint, not forecast or global critical-path measurements.

Both arms used cache clearing and closed normally. The strict cross-arm raw/state comparison failed, so hpc02 arms 2/3 were never run. Readonly classification verified all 18 artifact hashes and before/after file identity. All synthetic U/V bytes and headers match for every rank in both records. The only differences are warm errno on ranks 0, 1, and 7, and batch inexact flags (0x20) with the corresponding MXCSR bit on ranks 2, 3, and 5. Rounding mode and x87 control word match. These observed state differences remain strict failures; the classifier does not establish their MPI/libc cause. See ACTUAL_CLASSIFICATION_SUMMARY.json for exact values and byte offsets.

The prior word-copy wave remains failed and preserved. Comparing its earlier 925 ms with this candidate's 485 ms across separate runs is not a paired gain measurement. Native protocol evidence is retained, but this candidate has no complete-caller, application, or default qualification. No retry, state normalization, source promotion, or default change follows.

Rollback is the unchanged selected implementation: these files document only a private rejected candidate. See DECISION.json and EVIDENCE_REFS.json for exact receipts and scope.
