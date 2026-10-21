# BigStep Zen 2 screen: local HPG gain, whole-module rejection

One unchanged-source configuration added `-march=znver2 -mno-fma` to BigStep only, retaining strict GNU13.3 flags. Both arms used canonical8aba/PP438d. The actual ISA object is f219; the selected generic object is670b. No source or working default changed.

The pressure-gradient native screen passed all100 cases in O2 and O0/bounds with fresh72-case prefixes, exact complete outputs, read-only/physical guards and five floating-point state fields. Its rounding scope is nearest/downward. The NH-X main loop widened4→8 lanes and lost its main-loop vector spills. Frame reservation increased936→960 bytes with additional alignment; scalar staging and tails remain. [Native evidence](HPG_NATIVE_QUALIFICATION.json), [literal code review](LOCAL_CODEGEN_REVIEW.json).

The unchanged complete500-call HPG benchmark then passed exact outputs/state and normal job closures, with checked compute-client cache clears before every arm:

| Host/order | Selected generic, seconds | ISA candidate, seconds | Caller wall reduction |
| --- | ---: | ---: | ---: |
| hpc01: generic then ISA |0.544268403|0.505117086|7.1934%|
| hpc02: ISA then generic |0.535268524|0.507357516|5.2144%|

These are finite synthetic complete-caller timings, not forecast gains or repeatability evidence. Process CPU time is unavailable. They do not add to the earlier20.9% consumer gain. [Caller qualification](HPG_CALLER_QUALIFICATION.json).

**Reject this fixed whole-module ISA configuration.** It changed41 of42 functions, and the first additional physics-preparation check failed exact same-opt raw/state equality. The genuine object and freshly rebuilt generic parent matched in all four tested rounding modes. The ISA nearest-mode buffer differed:908e53b2 versus64e417ca, both4,277,244 bytes. All15 executed commands returned zero; the exact comparison caused the failure. The receipt does not identify the differing case, output/state field or cause. O0 and the remaining theta, density-counterexample, geopotential, diffusion and moisture tests were not reached. The failed job is positively closed, with PID0, no cgroup processes and an invocation-bound failure journal. [Rejection](WHOLE_MODULE_REJECTION.json), [receipt](ADDITIONAL_NATIVE_FAILED_RECEIPT.json), [closure](ADDITIONAL_NATIVE_FAILED_CLOSURE.json).

The HPG gain remains useful evidence for a possible function-local implementation; it does not qualify the wider module flags. No retry, variant sweep, relaxed checker or application run followed. Selected1749/sourcea531 remains unchanged, so no rollback is required. Production/master are untouched and AWS stays suspended. Raw producer source identities remain null; later source identity is recorded separately.
