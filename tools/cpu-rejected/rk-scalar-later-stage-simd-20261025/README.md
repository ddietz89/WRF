### Later-stage RKscalar SIMD: rejected after strict payload counterexample

The current D54 profile joined +e2d/+e32 to the scalar later-stage reconstruction loop in ModuleEM647bb/c78. The separate +12d9 tendency loop was already packed and excluded. One returned SIMD directive, with one blank consumed to preserve PP rows, retained the literal expression and every other source statement.

Actual native hpc01 invocation `3dde98f5e066475c9ae97ece24975576` failed the O2 round-0 focused raw comparison. First mismatch byte791984 maps to case42, width2, `scalar_2(i=1,k=2,j=2,species=2)`. The fixture places quietNaN `7fc12345` in MU_OLD and distinct quietNaN `ffc54321` in scalar_1 at every active I. Parent returns `7fc12345`; candidate returns `ffc54321`. This is consistent with changed generated operand priority, without asserting an uninspected exact opcode. NaN-class equality does not satisfy the raw contract.

Both focused executables returned zero and passed their internal readonly/physical/config guards. Cross-arm five-state equality is not separately established by this first-mismatch metadata. Ten preceding width1 records were byteexact; broader qualification did not complete. Only the candidate O2 module was compiled. Original28, partialK/species3, remaining rounding modes, O0, caller timing and application did not run. The actual unit exited1 and closed with PID0/empty absent cgroup.

Reject this fixed candidate, retain all source/provider/codegen/native evidence, and leave selected871 unchanged. No repair, normalization, timing or performance claim follows. Exact references, raw hashes and the record-layout derivation are in REJECTION.json.
