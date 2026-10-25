# Diff-metric thickness row pipeline: closed unpromoted

The fixed candidate passed the whole-function numerical gate: 12 cases × four FP controls at each O2/O0, including competing NaN payloads, physical/read-only/config guards and all five state words. All four complete-caller arms passed with identical 3,563,480-byte raw output and normal closures, with cache cleared before each arm.

At 8192 complete calls plus five full-output restores per call inside both clocks, host01 improved from 4.830712955 to 4.788827119 seconds (0.8671% wall, 0.8690% thread CPU); host04 regressed from 4.804434305 to 4.814378466 seconds (0.2070% wall, 0.2193% CPU). These small mixed results do not demonstrate a significant repeatable caller gain. No favorable isolated stage or significant kernel gain was measured. No further arms or forecast application are planned.

The actual code retains mandatory loads, divisions, stores, scratch allocation and free. The proposed benefit was cache locality, with no allocation or memory-capacity benefit. Full RELA identity remains false: the finite classification proves unchanged non-target raw bodies and same actual named call/pointer referents despite placement shifts; it does not claim whole-TU identity.

The first benchmark builder failed compilation only because c_loc(warm_state) required TARGET. Its files, receipt and failed closure are preserved. Fresh R2 adds that declaration attribute only and produced the four successful caller arms. The native numerical proof remains separate from this fixture repair.

This private closeout changes no canonical source, selected image, defaults, public findings or Git state. Rollback is to leave the selected implementation unchanged. Exact evidence hashes are in EVIDENCE_REFS.json.
