# RK1 W snapshot fusion

The selected GNU13.3 SmallStep path copies W into its required RK1 snapshot during the existing guarded W/PH traversal. Original bounds, required stores, subtraction/division order, RK2/3 branches and every previous fusion remain. The separate W traversal is removed; the rejected MU preparation fusion is excluded.

Complete restored synthetic RK1 callers were **9.00% and9.51% shorter** in opposite-order node pairs, with exact raw bytes/five-state, cache clearing before each arm and normal closures. The genuine/same-opt O0-bounds/O2 gate passed102 cases. These are caller gains, not forecast percentages.

Image526e/archivec252 passed both complete original products and35 ordered steps, full512/two-tile/writer/fieldview admission and all model/reader closures. Its137.365313s wall,38.463250s main-step elapsed and53540.863983CPU-s are unpaired context. Its separate own three-hour gate now also passes four full products and545 ordered steps, with all models and reader normally closed. The655.739263s wall/557.652750s main/319010.318735CPU-s are unpaired context; no new forecast gain is claimed. Own9h/noon/profile/restart/full144 remain pending; parent19ad ABBA evidence stays separate.

The compile-free artifact replaces only member558 and retains583 others. Actual canonical WRF preprocessing plus one strictO2 compile reproduces its runtime code/data, relocations and publicMOD; PP/debug-object bytes differ. Source9712688c is post-test canonical correspondence, not a new whole-image build.

Default eligibility: GNU13.3.0, emptyOMPCPP, SmallStepSIMD=1, Zen2=1 and PHfusion=1. Matching serial remains unqualified. Roll back with `WRF_SMALL_STEP_W_COPY_FUSION=0` followed by full regeneration, rebuild and relink; restore the prior19ad selection if an immediate artifact rollback is needed. Source inverse is the two-file diff of9712688c. Production/master are unchanged.

See [native/caller evidence](NATIVE_CALLER_QUALIFICATION.json), [build correspondence](BUILD_QUALIFICATION.json) and [short application qualification](APPLICATION_QUALIFICATION.json).

See [separate three-hour application qualification](THREE_HOUR_APPLICATION_QUALIFICATION.json); the short qualification stays immutable for already frozen experiment packages.
