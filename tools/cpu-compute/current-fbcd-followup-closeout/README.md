# Current-build follow-up: two directives parked

The selected `6697020f` / `fbcd0463` configuration is unchanged. Both proposed directives passed exact native and complete-caller checks, including same-optimization raw results, read-only data, guards and observed floating-point state. Neither has application qualification or a demonstrated isolated-region speedup.

| Fixed candidate / measured caller | hpc01 or hpc03 wall change | hpc02 or hpc04 wall change |
| --- | ---: | ---: |
| VO3 boundary-zero SIMD: 256 captured whole-PD calls | +1.3932% | −0.1033% |
| Final-flux SIMD: 1,048,576 whole-pair calls | −2.2031% | +3.4150% |
| Final-flux SIMD: 4,194,304 whole-pair calls | +0.7736% | +1.3307% |
| Final-flux SIMD: 4,096 complete SPCVMC calls | −0.6357% | −0.5145% |
| Final-flux SIMD: 16,384 complete SPCVMC calls | −1.8330% | +0.0448% |

Negative changes mean shorter time. PD uses hpc01/02; radiation uses hpc03/04. Each row has one opposite-order parent/candidate pair per host, exact output/state checks, a checked client-cache clear before every timed invocation and positive job closure. Process CPU follows wall closely; exact individual wall and process-CPU values are retained in [DECISION.json](DECISION.json). These are caller observations, not forecast timings or statistical repeatability estimates.

Park both fixed directives. The PD caller shows no clear gain. Radiation's longer whole-pair caller is slower on both hosts, while its complete-SPCVMC observations remain small positive/neutral; preserve both findings. This is not evidence of forecast regression. Packed instructions alone do not establish a measured kernel gain, and no proven isolated gain is being discarded. Significant exact-qualified kernel improvements remain eligible without a separately conclusive forecast speedup.

The original wrong-VO6 attribution and failed cache-host admission remain preserved. Radiation's original object-scope failure also remains: later finite analysis proved constant-label identity changes, identical direct-jump targets and the intended callee-size change before strict numerical continuation. No scientific checker, tolerance or floating-point rule changed. No source/default promotion follows from these screens.

The four libc-copy questions were also closed: actual aligned call-site/source joins identify required time-level and saved-state copies, without demonstrated duplicate traffic. A distinct SPCVMC producer/recurrence split is under a separate codegen-first investigation. Existing communication stacks identify halo contexts but do not establish sender lateness, transport cost or global removable time.

No rollback is needed for this evidence-only commit. The retained production reference and master are untouched. Existing selected-build rollback remains documented in `tools/cpu-working/CURRENT_SOURCE_BUILD_BINDING.json` and `tools/cpu-compute/pd-result-capacity-combined/README.md`.
