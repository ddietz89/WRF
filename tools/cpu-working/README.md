# Selected working configuration

Image `40b229ba` and archive `e599c2b3` change only the LW and PBL driver members; the other 591 members and all selected direct inputs are unchanged.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.532793 | 21.0064% |
| Main-step elapsed minutes | 9.940841 | 8.870776 | 10.7643% |
| Aggregate CPU core-hours | 99.813152 | 85.267094 | 14.5733% |

This image is qualified only for its own unprofiled three-hour run on the same 512-rank configuration: 545 steps and four full outputs passed the unchanged checker, with all four models and the reader normally closed. Its noon, nine-hour, profile, restart, full 144-hour and clean full-source rebuild scopes remain false. Only module_pbl_driver.o and module_ra_rrtmg_lw.o changed; the other 591 archive members, RSL, provider and all 18 direct inputs are unchanged. The two TAUMOL sites passed 1,824 primitive comparisons and 16 complete calls with genuine absorption tables and exact outputs, inputs, guards and all five processor-state words. The primitive improved 50.7–54.3%; the complete TAUMOL caller estimates were 0.04–0.28% lower wall time, without an established material caller gain. The MYJ pressure-copy screen was neutral on one host and positive on the other; no general gain or whole public PBL native fixture is claimed. Both were retained under the owner inclusion policy. These observations do not establish a forecast speedup. The source commit records correspondence after testing; raw producer commit remains NULL. Three-hour timing is one unpaired descriptive observation against the fixed median of three original controls; raw A2 remains separate.

[Evidence](../cpu-compute/taumol-psfc-batch-20261029/README.md) · [Selected binding](CURRENT_SOURCE_BUILD_BINDING.json)
