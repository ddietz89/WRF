# MCICA mask fusion

The working build CEC evaluates the existing cloud-mask comparison directly in the property loop. It removes the temporary logical mask, its separate population loop and readback. RNG calls, CDF construction, comparison order, five property outputs, arithmetic, flags and public API stay unchanged.

The complete production-shaped caller was **12.32% and 13.90% shorter**, with **11.41% and 13.76% less process CPU**, in two opposite-order host pairs of20,000 calls. Raw outputs, readonly inputs, padding, RNG and five-state observations matched. This is a caller measurement, not a forecast speedup.

Native O0/bounds and O2 gates passed120 original+12 masked cases in direct and adapter modes, both with seed150 present. Six generated MODULE files reorder compiler records; the fixed-hash/type/reference proof checks their semantics, while MCICA and all unaffected MODULE bytes remain exact. The original byte-equality gate failure is preserved; no numerical check was waived.

The compiled6d00 whole LW object replaces only one of584 archive members;583 are exact, with zero physics compilation and one ordinary link. The original short scientific checker passed both complete outputs,35 steps,512 ranks and two tiles, all model/reader scopes closed. Writers487/495 are positive;503/511 are correctly inactive. Root input06d/NCa32 and outputde5b remain unchanged.

CurrentCEC has **no own three-hour or nine-hour qualification**. The previous1d6e nineteen-percent three-hour observation remains bound to its previous executable. [Qualification](QUALIFICATION.json) links compact native/build/timing/application records. The full application record5a2051 remains unmodified outside git; the tracked projection omits512 zero/inactive lifecycle rows while retaining full512 observed count, positive roots, zero roots, closure truth and all17 verified evidence references.

Source commit80a9 is **POST_TEST_SOURCE_IDENTITY**, committed after scientific acceptance; frozen raw producer commits remainNULL. Rollback uses `tools/cpu-working/PREVIOUS_SELECTION_BEFORE_MCICA_MASK_FUSION.json`, restoring retained1d6e and keeping all other selected input/output improvements.

`caller_benchmark.f90`/`benchmark_clock.c` are the meaningful complete-caller iteration driver. `full_caller_driver.f90`, `masked_boundary_driver.f90` and `region_observer.c` preserve the native oracle. They require the exact qualified dependency/object/compiler/fixture bindings recorded in the external producer recipes; these are not standalone whole-WRF builders. No broad compiler sweep, recapture or long forecast replay is implied.
