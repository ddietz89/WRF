# Fixed paired VRTQDR ABAB candidate: unpromoted

The fixed four-lane ABAB implementation is rejected for performance. It passed the retained O2/O0 raw output and five-state tests, and all eight complete-caller arms passed their checks and normal closure. The complete paired routine took 38.52% longer on hpc01 and 38.08% longer on hpc04; process CPU agrees.

Whole SPCVMC on hpc01: parent 5.880212794s, candidate 6.741815954s (+14.6526% longer).

Whole SPCVMC on hpc04: parent 5.891979751s, candidate 6.741684000s (+14.4214% longer).

Actual assembly contains 4 DIVPS, 31 MULPS, 12 ADDPS and 8 SUBPS, with ABAB construction and serial vertical recurrences. Packed arithmetic did not produce a paired-caller gain. No isolated positive kernel timing was measured, so the significant-kernel-gain policy is not triggered. These measurements do not isolate a cycle-level cause, establish forecast impact or imply global headroom.

The experiment preserves original interfaces and the kind fallback. Original parent module callers were used; three dependent module byte changes and diagnostic source-line changes remain explicit. Whole-module byte/full-relocation identity is not claimed. Unmasked traps are outside the tested scope.

The selected height 5c75 source/defaults remain unchanged. Rollback requires no action because this source was isolated and unpromoted. No further candidate, timing matrix or forecast run is proposed. Exact native,codegen,caller and closure references are in EVIDENCE_REFS.json.
