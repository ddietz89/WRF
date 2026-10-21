# Original-provider result-allocation attribution

The exact original-only32-call W4 diagnostic passed128 allocations/128 frees,256 same-return-state checks, compressed/raw/readonly/stock-decode checks and136 matched real worker joins. All jobs closed normally; caches were cleared first. An actual non-PIE PLT-address comparison error in the observer was repaired using versioned loader-resolved libc aliases; failed attempts remain preserved.

Allocation took2.032442ms and free20.912112ms in total, against2199.956714ms provider time and21.371098ms separate release time. The observed wrapper component is1.0329% of provider-plus-release wall phases, not an optimization gain or global headroom. Instrumentation overhead is unknown, the separate empty control is not subtracted, and later first-touch/page faults are excluded.

Retain one bounded result-capacity reuse candidate. Ownership/fallback/state checks and measured memory admission remain pending; estimated extra retained capacity is about254MB per writer root (about1GB across four roots). No source/default changes or performance claims follow from this diagnostic alone.
