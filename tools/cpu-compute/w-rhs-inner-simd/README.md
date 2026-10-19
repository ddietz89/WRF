# W RHS inner-I SIMD

The qualified working configuration includes one inner-I SIMD directive in advance_w's geopotential RHS fill. It retains the original arithmetic, loop bounds and top-lid assignment. Actual generated packed multiply/add/divide executes before the top-lid zero blend, with no FMA and scalar tails.

Current whole-module reproduction, captured complete-W replay and 32 synthetic complete-W O0/bounds/O2 raw/state cases passed. Two opposite-order same-host pairs showed **4.64% and 6.24% shorter complete captured-caller wall**, including identical restoration/reset/state work inside both clocks. These are caller gains, not isolated-loop or forecast percentages. Component cache clears passed; boot/before-after memory telemetry was unavailable and remains unknown.

Combined executable **e55c97e6**, tracked source **ef7fed90**, passed the original three-hour full-grid gate: four products, 545 ordered steps, all 512 ranks, two tiles and four writer groups. All scopes closed. Its **669.628s versus retained 820.506s** observation is unpaired and does not isolate this directive's forecast contribution. All preceding 3bb2 improvements and pinned runtime remain included; the parked Thompson reflectivity copy-removal candidate is excluded.

[Qualification](QUALIFICATION.json), [native proof](NATIVE_QUALIFICATION.json), [caller timings](CALLER_TIMING.json), [object overlay](BUILD_QUALIFICATION.json) and [application proof](APPLICATION_QUALIFICATION.json) retain the exact support and immutable producer records. Rollback restores tools/cpu-working/PREVIOUS_SELECTION_3BB2.json and PREVIOUS_SOURCE_BUILD_BINDING_3BB2.json, executable3bb2/source26bc, with the same runtime. Production and master are unchanged.
