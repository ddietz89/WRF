# Original-protocol typed receive: unpromoted

The fixed per-call candidate remains unpromoted. Its first complete HALOC caller pair took **336.73 ms versus 292.79 ms** for the original, about **15.01% longer**; summed thread CPU was 14.94% higher. This is diagnostic evidence only: the strict cross-arm five-state comparison failed, and the two remaining arms were not run.

All physical U/V and record-header bytes matched on all nine ranks, for both the warm and terminal records. Differences were confined to warm `errno` on ranks 3, 5, 7 and 8, and terminal inexact flag/MXCSR bit `0x20` on ranks 5 and 6. Rounding mode and x87 control word matched. The cause was not established. No state reset, restoration, exclusion or waiver was introduced.

The preceding bounded native test passed complete physical/raw five-state checks for 16 records on each of nine ranks, including exceptional payloads, ordinary fallback and mixed receiver-local fallback. The original point-to-point send ordering, tags, byte envelopes and request completion were checked. This finite native result remains valid within its scope; it does not qualify the failed caller wave or an application.

The candidate retains original Y-to-X send staging and replaces receive scratch/unpack with MPI_CHAR derived receives into final ghosts. Datatype creation, commit and free occur on every complete call and were included in the timer. There was no cached datatype/communicator context or eligibility collective. The caller uses a synthetic local 3×3 footprint, not the production 224-compute-rank map. There is no global MPI headroom, wire-time or forecast-gain claim.

Both timed units closed normally. The frozen first compile failure and repaired native R2 are retained separately. No application/default/working-selection change occurred; the selected original protocol is retained. No further arms or repairs are proposed for this fixed candidate.
