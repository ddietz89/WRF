# Selected working configuration

Image `4d258a49` changes only the LW member; 592 other archive members and all direct inputs are unchanged.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.515850 | 21.1335% |
| Main-step elapsed minutes | 9.940841 | 8.855933 | 10.9136% |
| Aggregate CPU core-hours | 99.813152 | 85.230792 | 14.6097% |

This image is qualified only for its own unprofiled three-hour run on the same 512-rank configuration: 545 steps and four full outputs passed the unchanged checker, with all four models and the reader normally closed. Its noon, nine-hour, profile, restart, full 144-hour and clean full-source rebuild scopes remain false. Only module_ra_rrtmg_lw.o changed; the other 592 archive members, RSL, provider and all 18 direct inputs are unchanged. Two additional lower band4 remainder sites reuse their preceding original integer conversions with binary32/integer32 admission and literal fallback. The identical primitive formula previously passed 1,824 raw/state comparisons and measured 50–54% lower primitive time. The current 16 genuine-table complete TAUMOL calls passed full outputs, read-only inputs, guards and all five compute state words. Current complete caller wall estimates were 0.94% lower on one host and 0.57% higher on the other; no consistent caller or forecast gain is established. Retention follows the owner significant-kernel inclusion policy. Three-hour timing is an unpaired descriptive observation against the fixed median of three original controls; raw A2 remains separate. Source correspondence is post-test; raw producer commit remains NULL.

[Evidence](../cpu-compute/taumol-band4-fractions-20261029/README.md) · [Selected binding](CURRENT_SOURCE_BUILD_BINDING.json)
