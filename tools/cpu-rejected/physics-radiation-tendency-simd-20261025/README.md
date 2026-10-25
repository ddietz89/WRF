# Radiation physics-tendency SIMD: rejected at the extracted strict gate

The one-directive proposal targets only the radiation I loop in `calculate_phy_tend`. Actual D54 source/IP evidence confirms that the current loop is scalar. The exact returned source arithmetic and all guards remain unchanged; one existing blank compensates the inserted directive.

The required extracted-source O2 round-0 comparison failed in invocation `05be844ecf3f4a04b1b084c1b3c2aa21`. First differing byte8388 (word2097) maps to case3, width1, `RTHRATEN(i=1,k=1,j=1)`. The fixture supplies quietNaN `7fc12345` in `c1(k)` and distinct quietNaN `ffc54321` in `mut(i,j)`; `c2` and the old tendency are finite. Parent output is `ffc54321`; candidate output is `7fc12345`. This is a concrete raw IEEE counterexample in the required extracted gate, consistent with changed generated operand selection. The exact responsible opcode is not asserted.

Both programs returned zero and passed their individual physical, readonly and read-configuration checks. The cross-arm raw comparison failed; separate all-state equality and case1/2 equality are not claimed from the first-byte report. The full streams, source, actual stage objects and codegen log remain hashbound in REJECTION.json.

The unit exited1 and closed with PID0 and an absent empty cgroup. No other rounding mode, O0, full ModuleEM compile, genuine 83-argument caller, timing or application test followed. The separate whole-caller wiring remains unexecuted and unqualified. This does not claim that an uncompiled full ModuleEM candidate itself was tested.

Close this fixed candidate without a repair ladder, tolerance or NaN normalization. Selected871 is unchanged; no performance or forecast claim is made.
