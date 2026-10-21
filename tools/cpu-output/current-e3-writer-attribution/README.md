# Current writer attribution — 21 October 2026

The selected E3 build plus the qualified write-boundary observer passed the unchanged original two-file,35-step full-grid comparison. All model and reader jobs closed normally. This diagnostic changes no source/default selection; the separate unprofiled E3 three- and nine-hour qualifications remain authoritative.

| Active writer | Public write-call envelope | Compression callback | Direct HDF5 chunk calls |
|---|---:|---:|---:|
|487|22.704s|20.405s (89.88%)|2.055s (9.05%)|
|495|12.510s|10.780s (86.18%)|1.509s (12.06%)|

These are same-process elapsed envelopes, not global removable forecast costs. MPI/gather time and complete final drain were not measured. Each writer performed216 compression callbacks and864 independent chunk streams. There is one chunk per worker, so moving initialization outside that worker's chunk loop alone would not amortize anything in this trace. A bounded standalone measurement will determine whether codec initialization/teardown warrants a separate cross-callback lifetime change.

The CPU profile is unavailable: the rank495 collector never admitted its initial06:00 file trigger, and no recorder started. Missing samples are not evidence of zero cost. The frozen failure and recorder-absence proof are retained. The root/history trigger pairing is being checked from source and closed logs before any future capture.

The short run took138.025s wall,38.994s main-step elapsed and53,806.518 aggregate CPU-s, versus267.534s,42.032s and86,843.489CPU-s for the retained original. This is an instrumented, unpaired startup/output diagnostic; it does not establish sustained forecast speedup. Main-step elapsed includes communication/backpressure and is not integration CPU. Raw RESULT retains an inherited PART2_PBL descriptive label; actual lease and executable identity establish E3.

[Result and checksummed references](RESULT.json) retain the complete scientific receipt externally, without duplicating scientific data in the repository. No rollback is required because this diagnostic changes no selected code, libraries or defaults.
