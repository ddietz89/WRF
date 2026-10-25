# PART2 PBL/QV traversal fusion: unpromoted

The private candidate passed numerical checks but showed no consistent significant complete-caller gain. It remains unpromoted; selected source, defaults and application qualification are unchanged.

The change moves admitted QV decoupling into the existing PBL U/V/theta traversal, retaining each true division and denominator tree. Inactive QV uses the original trio fallback; QC/QI and all other procedures remain unchanged.

| Host/order | Regime | Wall reduction | Process CPU reduction |
| --- | --- | ---: | ---: |
| hpc01 P-C | PBL_ONLY | 0.84419% | 0.83877% |
| hpc01 P-C | COMBINED_FORCING | -0.98995% | -0.98489% |
| hpc02 C-P | PBL_ONLY | 0.06022% | 0.04772% |
| hpc02 C-P | COMBINED_FORCING | 0.84404% | 0.82527% |

Each arm executes 1,024 complete synthetic PART2 calls per regime at 188×19×32. Restoring 31 tendencies, th_phy and RMUNDGDTEN is included inside both clocks. Allocation, initialization, warm call, raw/read-only/guard validation and state controls are outside. The driver resets state before the clock and reads/compares final state against the warm call after the clock; it does not observe state after every timed call. The four arms used checked cache clearing each time and positive normal closures; all 43,061,744 output bytes match. These are complete-caller results, not isolated-region or forecast measurements. Two opposite orders are insufficient to establish repeatability or a material regression.

R1 failed before commands because external archive ownership was looked up in the wrong receipt map. R2 reproduced the genuine parent but stopped at the strict non-target full-RELA comparison: the unchanged 2,950-byte couple routine had two named callee placement fields shifted. Physical pools and their allocated relocations remained exact. R3 retains that failure and qualifies only the actual pair: unchanged global named callee body/full RELA plus four actual linked executable checks at the two E8 calls. PLT32 is not inferred to resolve directly from an unlinked zero immediate. Full tuple equality remains explicitly false.

R3 then passed genuine/O2 parent/candidate and O0 bounds parent/candidate: the original 68 cycling cases (their historical rounding distribution is retained) and eight added whole-procedure cases in four masked rounding modes. The 14,772,864-byte legacy and 6,951,936-byte payload records match across all five roles, including physical outputs, read-only inputs, guards and five state observations. This does not qualify unmasked traps or a new forecast.

No application or canonical build is warranted by this screen. Rollback is to keep the already selected BACF component and omit this private candidate; no deployed source needs reverting. All failed attempts and actual proofs are retained by reference in EVIDENCE_REFS.json.

Actual generated code confirms the mechanism: parent packed loops 0x6590–0x65c6 (trio) and 0x69b0–0x69cd (QV) separately form the denominator; candidate 0x6ff0–0x7033 forms it once and shares xmm0 across four divps before one backedge. Four true divisions and tendency loads/stores remain. Both versions already use packed 128-bit operations; no reciprocal approximation or FMA was introduced. Static whole-function counts include the new fallback and cannot predict executed work. No register-spill bottleneck or causal explanation of timing was established. GENERATED_CODE_REVIEW.json contains exact snippets and artifact hashes.
