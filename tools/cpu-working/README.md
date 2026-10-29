# Selected working configuration

Image `6bc47f88` and archive `aeb4f38f` change only the CU helper. The other 592 archive members are unchanged, including the module and PBL, LW, MYJ, and Thompson code. RSL, the output provider, and all 18 direct link inputs are preserved.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.496159 | 21.2812% |
| Main-step elapsed minutes | 9.940841 | 8.845775 | 11.0158% |
| Aggregate CPU core-hours | 99.813152 | 85.051337 | 14.7894% |

Only this image's unprofiled three-hour run on the same 512-rank configuration is qualified: 545 steps and four full outputs passed the unchanged checker, and all four model processes and the reader closed normally. Its noon, nine-hour, profile, restart, full 144-hour, O0, and clean source rebuild qualifications remain false. One CU helper changed; the other 592 archive members, including the module and PBL helper, are unchanged, as are RSL, the output provider, and all 18 direct link inputs. The failed R1 producer retains two successful links. The normally closed R2 continuation reused those exact artifacts, performed zero compiles or links, and passed all 320 complete-procedure comparisons for physical outputs, read-only inputs, and all five processor-state words. The source commit records correspondence after testing; the raw producer commit remains NULL. Timing is one unpaired descriptive observation against the fixed median of three original controls. The raw A2 scientific control remains separate. These timings do not isolate a forecast speedup caused by this helper.

[Evidence](../cpu-compute/cu-fourcolumn-simd-20261029/README.md) · [Selected binding](CURRENT_SOURCE_BUILD_BINDING.json)
