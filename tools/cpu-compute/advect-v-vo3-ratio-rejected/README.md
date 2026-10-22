# Rejected V/VO3 map-ratio cache

The proposed cache moved an invariant division outside the vertical loop and passed the initial captured/focused O0/bounds/O2 tests. Generated-code review then found commuted multiplication operands, requiring two focused dual-NaN tests before timing.

The additional full-procedure checks failed exact O2 raw output. The genuine current object and fresh parent agreed; the candidate preserved floating-point state, inputs and guards but selected a different NaN payload. Case10 changes one word, case11 two words, in both tested rounding/seed recipes. The original explicit horizontal-order0 no-op isolates the vertical contribution. [Actual payload differences](ACTUAL_SYNTHETIC_RAW_DIFFERENCES.json) and [failed-unit closure](FAILED_UNIT_CLOSURE.json) are retained.

This fixed candidate is rejected under the unchanged exact IEEE rule. No caller timing, application run, source variant or promotion followed. Supplemental O0 execution was not reached; the earlier finite native PASS retains its narrow scope. The promoted PD SIMD/output-buffer configuration remains selected. [Decision](REJECTION.json).
