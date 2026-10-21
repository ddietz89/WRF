# Ordinary scalar-consumer SIMD: qualification in progress

Two independent final consumers in `advect_scalar` (Y order5 and vertical order3) gain SIMD directives with unchanged expressions, schedule and flags. The current selected image remains bc54; combined bb65 is experimental until its own full-grid checker passes.

The genuine captured caller, original13 edges and32 targeted IEEE cases passed at O0/bounds and O2, with exact raw words, read-only inputs and five return-state fields. Actual packed main/remainder/tail paths were reviewed. The fixed frame grows32bytes; no floating-point spills occur inside these two packed backedges, while setup/tail stack loads remain.

Two opposite-order, cache-cleared4096-call whole-caller pairs measured3.579917813→2.759142198s (22.9272%) and3.596660965→2.726474594s (24.1943%). Both include the same in-clock tendency restore. CPU timing is unavailable. These are caller measurements, not isolated-loop or forecast gains.

Combined bb65/0507 changes only archive slot555 (advection8ec→a36);583 members and external inputs remain unchanged. The fresh original-first three-hour full-grid comparison is running; four products/545 ordered steps remain pending. No default/source promotion or qualification transfer is claimed. Failed attempts remain in the campaign evidence.
