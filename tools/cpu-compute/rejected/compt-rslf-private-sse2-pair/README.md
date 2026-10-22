# Rejected: private SSE2 RSLF pair inside complete compT

The fixed helper passed the scoped exact whole-function native checks but made the complete function slower on both hosts. It is not selected or promoted.

| Host/order | Parent wall | Candidate wall | Wall longer | CPU longer |
|---|---:|---:|---:|---:|
| hpc02 P→C | 0.142650746 s | 0.162739923 s | 14.0828% | 14.0804% |
| hpc04 C→P | 0.142174092 s | 0.162898321 s | 14.5767% | 14.5771% |

Each measured arm executed 20,000 repetitions of original finite cases1–8:160,000 complete compT calls. One generic driver object linked both the genuine current Thompson function and candidate. The final eight returned words, aggregate returned-bit checksum, input/physical guards and all five observed states matched for the before, measured and after workloads. The timing screen does not retain every intermediate return word. Each arm had its own checked cache clear and normal strong closure; memory events and quota throttling were zero. Ordinary acceptance hashes and proof calls warm executable/data; these are not cold-cache results.

The exact native scope retained the original24case same-opt prefix and ran those cases under all four rounding modes with current five-state observations, including exceptional inputs. Current compT text was independently verified against the retained genuine1027-byte function. The emitted helper packed two useful lanes plus duplicate upper lanes with explicit O2/O0 operand order and true division. This is finite tested coverage, not universal IEEE/trap first-fault equivalence.

The public MOD bytes differ by the sole exact observed compT `ARRAY_OUTER_DEPENDENCY` token. Other decoded interface tokens match; fresh caller conservatism may change. Unrelated Thompson text/relocation changes remain **unqualified**. R1/R2 guard failures, the provider's unusable literal, old scalarized prototype and the driver's initial compile failure are retained. No full Thompson or application qualification was pursued.

The original function inlines both RSLF expressions. A new private call can lose inlining and register scheduling; that is a possible explanation for the measured regression, not a proven causal attribution. This one opposite-order pair on each host is synthetic and exploratory, with0.142–0.163s durations; it supports rejecting this fixed implementation without a rerun matrix or forecast-gain claim.

`DISPOSITION.json` contains actual hashes, component references and per-arm resource/closure evidence. Source/default selection remains unchanged. Raw producer/posttest source commits for this rejected candidate are NULL.
