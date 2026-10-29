# CU four-column helper

Image `6bc47f88` and archive `aeb4f38f` passed the original three-hour science check on the same 512-rank configuration: **545 steps and four full outputs**, with normal model and reader closures.

| Metric | Original control, median of three | Child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.496159 | 21.2812% |
| Main-step elapsed minutes | 9.940841 | 8.845775 | 11.0158% |
| Aggregate CPU core-hours | 99.813152 | 85.051337 | 14.7894% |

Only this image's unprofiled three-hour run on the same 512-rank configuration is qualified: 545 steps and four full outputs passed the unchanged checker, and all four model processes and the reader closed normally. Its noon, nine-hour, profile, restart, full 144-hour, O0, and clean source rebuild qualifications remain false. One CU helper changed; the other 592 archive members, including the module and PBL helper, are unchanged, as are RSL, the output provider, and all 18 direct link inputs. The failed R1 producer retains two successful links. The normally closed R2 continuation reused those exact artifacts, performed zero compiles or links, and passed all 320 complete-procedure comparisons for physical outputs, read-only inputs, and all five processor-state words. The source commit records correspondence after testing; the raw producer commit remains NULL. Timing is one unpaired descriptive observation against the fixed median of three original controls. The raw A2 scientific control remains separate. These timings do not isolate a forecast speedup caused by this helper.

The separate complete CU-region screen reduced wall time by 22.25% on host 02 and 25.03% on host 04 compared with scalar fused CU. All eight restores, the admission check, and the full region were timed. These initialized region cases do not measure the whole procedure or establish an additive or causal forecast gain. Both whole-procedure native checks passed all 320 comparisons.

The failed R1 producer retains two successful links and its failed, drained closure. The successful R2 continuation performed zero compiles or links, verified the existing artifact identities, and completed all four original rounding-mode checks. The earlier timing attempt stopped on a pending receipt field before any timed driver ran; that failure is also preserved.

The only source change is `dyn_em/cu_fused_row.c`; Make rules, the module, the PBL helper, and compiler flags are unchanged. Source commit `8d2aa02c` records correspondence after testing; the raw producer commit remains NULL.

Rollback: Select retained qualified image 3c3a and archive da52 to restore scalar fused CU while retaining PBL SSE2. WRF_CU_FACTOR_FUSION=0 rebuilds original unfused CU; WRF_PBL_FACTOR_FUSION=0 disables both nested features. This source promotion changes no Make rule or global flag.
