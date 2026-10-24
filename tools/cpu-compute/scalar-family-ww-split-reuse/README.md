# Scalar-family WW preparation reuse

The selected `026c` executable retains all previous improvements and reuses WW preparation across the QNI/QNR scalar species. The first species completes both tiles before reuse; readiness resets each RK stage. The callee and its public interface remain unchanged.

Two opposite-order node pairs reduced the complete synthetic caller's elapsed time by **1.34% and 1.48%**, and process CPU time by **1.43% and 1.90%**. These measurements exclude scalar updates, halos and the full forecast.

The combined executable passed its own original two-output, 35-step scientific check at 512 ranks. Its three-hour, nine-hour, noon, profile, restart and full-144-hour scopes remain unqualified. The parent `89bd` three-hour result remains historical. [Scientific qualification](APPLICATION_QUALIFICATION.json), [source/build evidence](EVIDENCE.json), [rollback](ROLLBACK.txt).

The qualified GNU 13.3 build enables `WRF_SCALAR_WW_SPLIT_REUSE=1` by default. Set it to `0`, regenerate and rebuild `solve_em`, replace its archive member and relink to opt out. Keep the qualified callee and runtime providers. Canonical preprocessing matched the already compiled objects exactly; source commit `6fdcb52d` records correspondence after testing, and the raw producer commit is unknown.
