# Thompson guaranteed-zero allocation: closed before native tests

The qualified mode-1 recipe keeps the original public allocatable table and contents while attempting a guaranteed-zero first allocation and skipping only its redundant fill. Already-allocated reset behavior, generic and mode-0 paths remain in the proposal. The actual provider proposal's module marker was corrected locally to a per-call local marker; provider context-only review is not native acceptance.

The actual GNU13 O2 parent reproduced genuine Thompson242c, canonical PPf552 and public MOD2b20. The proposed object also retained MOD2b20. This establishes code-generation feasibility only. The new mode-1 allocation calls `malloc` for1,095,200bytes, then executes37 calls to `memset`, each covering29,600bytes. All payload pages are still eagerly written. No `calloc` relocation exists in this INIT.

Close this fixed candidate because the proposed lazy-zero mechanism is absent. The two module compilations and bounded job completed normally, invocation22c5331646ca4676816f98d9b6fd6a23. No numerical/reentry/errno,11-caller,23-table-prefix, residency, timing or application qualification follows. No physical or peak-memory saving is claimed. No source/default change or sharing fallback is promoted; current4adb/f911 remains selected. Production/master are unchanged.

Actual source joins, allocator relocations, object/PP/MOD identities and terminal closure are retained here; full aligned assembly remains in the experimental workspace listed by the receipt. The separate unimplemented closed-world unused-allocation idea changes public allocation observability and is not qualified by this experiment.

The retained raw unified source diff contains seven space-only context lines reported by Git whitespace checking. Its original bytes are preserved as evidence; this source proposal is not applied to the working source.
