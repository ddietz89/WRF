# VDIFQ coefficient SIMD candidate

One `!$OMP SIMD` directive precedes VDIFQ's independent DTOZ/AKQ/CR coefficient producer. Bounds, expression order, precision, recurrence order and compiler flags are unchanged. The accepted VDIFV directive and all previous improvements remain present.

Local and actual GNU13.3/EPYC full-module gates passed: the current parent reproduced its allocated bytes/relocations, module interfaces matched, the complete captured MYJPBL caller matched raw outputs/read-only inputs/state, and the 32 Q plus retained 8+48 V cases passed O0 bounds checks and strict O2. Actual code uses packed square roots and divisions; allocation/free counts stay at five. This does not qualify other compiler stacks or unmasked trap order.

Two opposite-order caller pairs on hpc01/02 measured complete VDIFQ 9.7574%/9.7823% shorter and the same captured full MYJPBL caller 1.6131%/2.0453% shorter. Identical restores, allocations and state helpers are included. Bodies lasted 3.17–3.73 seconds; every arm had checked cache clearing and positive closure. Memory events were zero. One candidate arm recorded 593 microseconds of unit throttling; no correction or repeat was made. These are separate caller gains, not additive or forecast speedups.

[Native and caller qualification](NATIVE_CALLER_QUALIFICATION.json) records the raw proof hashes. Canonical source SHA256 is `1e82472bd07c7fb807ac84a7a8ce0c7bf7b12d4ead0f395ca5de7ab62abcc4a8`. Combined build and original four-product/545-step three-hour qualification are pending. The selected qualified runtime remains `8b101` until application qualification passes.

Rollback removes only this directive, restoring canonical source SHA256 `50ab31392c654d168b666414fcd356ec73a5bd4a017730b784d6eab9bbbc424d`, or selects retained `8b101` with the same accepted provider/codec/HDF5/rank map.
