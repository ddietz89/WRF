# Diffusion3dmp direct SIMD: rejected

One independent-I SIMD directive, with six scalar temporaries private and expressions/bounds unchanged, altered competing-NaN payload selection. The first difference was case25 at tendency(3,2,2): selected `7fc12345`, candidate `ffc54321`. Across the complete96-case candidate nearest-round record,15 exceptional cases differed in27 output words; allfive processor-state words, read-only/config checks and target canaries passed. The first24 finite/bounds/control cases were output/state exact.

The actual selected procedure and freshly compiled scalar parent matched all96 cases under four rounding modes (384 records each). Their2478-byte function bodies were identical; constant references were recorded separately. Candidate function size was4713 bytes. O0 parent/candidate compiled but were not linked or executed after the O2 rejection. No timing, full-module candidate/ABI, application or speedup qualification is claimed.

R1 failed before compilation due to a missing ELF helper. R2 added the unchanged helper in a fresh namespace and reached the native rejection. Both actual manager failures and absent cgroups are retained; neither is relabeled as a successful original invocation. The selected source, defaults and image remain unchanged. Complete receipts and the15 historical sampled-PC joins are pinned in [DECISION.json](DECISION.json).
