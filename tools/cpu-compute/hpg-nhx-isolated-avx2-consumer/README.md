# Isolated AVX2 NH-X pressure-gradient consumer

The qualified working configuration selects **a61a273b / archive 9dc6b5e5**, retaining every 1749 improvement and adding one private C helper for the NH-X consumer. Post-test source commit **5f184bcc** is separate from the frozen NULL native/build producer identities. Production and master are unchanged.

Two opposite-order pairs of the unchanged complete synthetic HPG caller, 500 calls per arm, measured **9.28% lower wall on hpc01** (0.538645115→0.488684011 s) and **7.67% on hpc02** (0.544414889→0.502685044 s). All four arms had checked cache clearing, exact 8,407,988-byte raw output and five return-state fields, and normal closures. Process CPU was not measured. This is a finite caller gain, without an isolated-X, statistical-repeatability or forecast-gain claim. [Actual caller wave](CALLER_ACTUAL_WAVE.json).

The actual native test passed 100 cases plus the original 72-case prefix, at same-option O0/bounds and O2: raw output, readonly/physical guards and all five state fields matched. Rounding coverage is nearest/downward, with finite/IEEE cases, legal readonly aliases, tails and empty extents. No universal IEEE/trap claim is made. [Native proof](NATIVE_QUALIFICATION.json).

The helper processes K then contiguous I, with eight-wide unaligned operations and a scalar tail; it preserves operand order and uses no FMA, reciprocal approximation, restrict assumption or allocation. Actual generated-code review found no FP spills in the helper's vector body; pointer stack traffic remains, and the separate helper frame prevents a total-stack-saving claim. Other module function text is unchanged; the two shifted couple relocations retain their targets and semantics. [Code review](GENERATED_CODE_REVIEW.json).

## Application qualification

The unchanged original checker passed **two complete products and 35 ordered steps**, all 512 ranks, 480 compute ranks, two tiles, 16 required short-window markers, all 32 quilt FIELDVIEW1 settings, positive writers 487/495 and inactive writers 503/511. All model and reader scopes closed normally. [Actual qualification](APPLICATION_QUALIFICATION.json), [result](SHORT_RESULT.json), [reader closure](READER_CLOSURE.json).

| Short observation | Retained original 546b | a61a candidate | Descriptive reduction |
| --- | ---: | ---: | ---: |
| Whole model/MPI wall, seconds | 267.534171 | 138.848954 | 48.1005% |
| Main-step elapsed sum, seconds | 42.031970 | 38.866750 | 7.5305% |
| Aggregate node CPU-seconds | 86843.488941 | 53688.507095 | 38.1779% |

These are **unpaired observations from different epochs**, used for science qualification. They establish no matched forecast speedup or helper contribution. Main-step elapsed includes communication/output backpressure; aggregate CPU includes MPI spin. Own short qualification is true; own three-hour, noon-profile and nine-hour qualifications remain false. A three-hour combined qualification is prepared. The prior 1749 nine-hour result remains historical for that image.

## Build, portability and rollback

The actual image reuses the qualified 2b056 module and ae13 helper: one BigStep replacement at archive slot 559, 583 other members unchanged, and one explicit helper object immediately before the archive in one ordinary link. No production source was compiled for this overlay. [Build qualification](BUILD_QUALIFICATION.json), [receipt](BUILD_RECEIPT.json), [closure](BUILD_CLOSURE.json), [archive proof](ORDERED_ARCHIVE_PROOF.json).

Only the helper C translation unit uses AVX2, with `-mno-fma -fno-fast-math -ffp-contract=off`. Existing Fortran flags stay unchanged. Standard source leaves `WRF_EXPERIMENTAL_HPG_NHX_AVX2` off and uses the original Fortran path; the qualified GNU13.3 EPYC recipe enables it explicitly and links the helper. Runtime admission requires AVX2. AOCC and Intel remain experimental. [Recipe](REBUILD_RECIPE.json).

Actual guarded-source preprocessing matches the qualified inputs byte-for-byte: OFF 438d1910 and ON 0632694b. This proves the source projection, without claiming a source-rebuilt full image. The compiler MOD differs (0170→99bf) by the meaningful ARRAY_OUTER_DEPENDENCY analysis attribute; typed calling layout and actual old-caller use passed, but fresh-caller code identity is not claimed. The whole HPG branch is duplicated to preserve both canonical forms, whose historical blank-line differences prevent two minimal seams. Literal tested source trailing blanks are retained for provenance; [formatting scope](SOURCE_FORMATTING_SCOPE.json) records this style-only finding. [CPP receipt](CANONICAL_CPP_RECEIPT.json), [closure](CANONICAL_CPP_CLOSURE.json), [source identity](POST_TEST_SOURCE_IDENTITY.json).

[Rollback](ROLLBACK.json) restores the Fortran source and all three working records together from `fe25000b`, returning to 1749/f18/source a531 and its own short/three-/nine-hour evidence. Remove only the new helper/recipe source files; retain experiment evidence. No production deployment is included.
