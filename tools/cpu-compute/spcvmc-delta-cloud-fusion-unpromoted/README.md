# SPCVMC delta/cloud fusion — unpromoted

The fixed neighboring-pass fusion passed strict native checks and removes three clear-array reloads in actual compiled SPCVMC. It remains unpromoted: both complete-caller and direct-stage cost screens were mixed, so neither demonstrates a reproducible meaningful saving.

| Scope | First P→C wall | Reverse-order P/C wall | CPU reduction |
|---|---:|---:|---:|
| Complete SPCVMC, 4,096 calls | 1.506924→1.476558 s; **+2.0151%** | 1.464477/1.530815 s; **−4.5298%** | +2.0255% / −4.5166% |
| Extracted 33-layer stage, 4,194,304 calls | 0.701946→0.675985 s; **+3.6985%** | 0.662254/0.675665 s; **−2.0250%** | +3.7353% / −2.0215% |

Positive percentages mean lower candidate time. Every executable had its own checked cache clear and normal closure on hpc01, CPU24/4GiB/zero swap. Raw gold, five-state, read-only and guard checks passed; all eight units recorded zero memory events and zero throttling. The stage restores the same six inout buffers inside both clocks. Its actual arms were only0.662–0.702s, below the initial2+second aim; no calibration or additional repetitions followed. The extracted wrapper has a different compiler context from complete SPCVMC.

This decision retains both positive observations and the demonstrated load removal. It does not reject scientific exactness, establish a forecast regression, or prove fusion can never help. Under the bounded owner decision, no further repetitions or source variants are proposed without new evidence.

The literal provider replacement is based on tested clear-active PP8ae, not old9ee: positive `icpr` executes delta and cloud work once per layer; other values retain delta-only work and the original `icpr==0` cloud path. Actual replacement lengths are47/47 newlines; the provider's44/45 claim is retained as incorrect. The existing clear-active helper, all outside source bytes and physical coordinates remain unchanged. This is the qualified PP-replay route, with no new canonical-F producer or source commit claimed.

Native coverage preserves general REFTRA128, clear-entry72 and complete-SPC12 cases, plus32 exact-source stage records for fallback, bounds and exceptional values, at O2 and bounds-checked O0 with same-opt gold. Public declarations and defined-global ABI remain checked; original-parent MOD callers are used. Two wrapper MOD files differ in serialization and are disclosed; whole-MOD byte identity and whole-module IEEE qualification are not claimed. Actual codegen retains all six output stores and four true divisions, has no hot fused-loop spills/calls, and preserves the fallback.

`NATIVE_AND_CALLER_QUALIFICATION.json` contains the bounded decision and actual measurements. `SOURCE_EVIDENCE_INDEX.json` pins retained source, provider returns, receipt/closure/cache and assembly records. Exact wave copies, source diff/inverse and generated-code review accompany them. Selected B4BC and source HEADb06f89e5 remain unchanged; this candidate has no application qualification or promotion.
