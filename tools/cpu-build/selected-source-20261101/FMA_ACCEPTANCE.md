# Accepted non-bit-exact compiler optimisation (owner decision 2026-11-02)

Owner: "Compile optimization is accepted" (experiment #2 of the 2026-11-01 result-changing round).

Build: identical to build_selected_source.sh except the overlay appended to configure.wrf is
`configure.overlay-fma.wrf` (= configure.overlay.wrf + one line):

    %.o: FCFLAGS += -O3 -march=znver2 -mtune=znver2 -ffp-contract=fast

No -ffast-math family flags. The Makefile qualified-opt-in gates are still evaluated against the strict FCOPTIM
(-O2 -fno-fast-math -ffp-contract=off), so every qualified feature stays enabled; GCC uses the last -O/-march/-ffp-contract.
Reference artifact: /pool/wrf-experiment/wrf-cpu/builds/selected-source-3919078b-fma-r2
(wrf.exe 7a5b634e…c549, libwrflib.a 60514b62…651a).

Evidence (3h, 09Z end field vs exact reference production512-reprobuild-r4-3h-r2):
- main-step 494.2 s vs 505.6 s (-2.3%).
- 1-ULP ensemble protocol: RMSE <= 1.25x envelope, but domain-mean drift 1.2-5.5x envelope -> not round-off-equivalent.
- Proposed end-field materiality test (investigation/.../round-20261101b/END_FIELD_PROTOCOL.md): PASS; worst field
  Q2 at 0.40 of limit, all biases <= 0.01 of limit; RMSE essentially equal to the 1-ULP spread.
Pending: 9h run production512-fma-9h-r1 (15Z end field + 9h wall), queued 2026-11-02.

Consequences: results are no longer bit-identical to the exact build. The exact reproducible build
(wrf.exe 5559d5a6…, build_selected_source.sh + configure.overlay.wrf) remains the rollback and the reference for
any future exact checks; exact-check tooling (check_pair / wrf_exact) does not apply to the FMA build.
