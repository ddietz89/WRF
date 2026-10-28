# MYJ automatic arrays on stack

The identical-PP GNU 13.3 O2 MYJ module with `-fstack-arrays` completed the captured whole caller **12.98% / 12.81% faster** on hpc01/hpc02; process CPU fell **12.98% / 12.80%**. Each arm included 512 original restores and complete MYJPBL calls inside the clocks. Cache clearing, original raw-gold/read-only/guard checks, and all five compute-state words passed; all four arms closed normally.

Native checks cover the retained complete MYJPBL tile and a public VDIFX six-case, four-round supplement. The PP and raw public MOD are unchanged. Fifty static malloc/free pairs across MYJPBL, MIXLEN and VDIFQ/H/V/X disappear. Three other function bodies/full relocations and all six constant/data pools remain exact. Changed target code and unwind bytes are explicitly retained as different; this is a finite source/native/machine admission, not universal IEEE or unmasked-trap equivalence.

The original replay counts **471200 / 428640 are 32-bit words**, corresponding to **1,884,800 / 1,714,560 bytes**. Earlier misnamed metadata fields remain historical; the checks and raw records were not changed.

Retain this gain for application integration. Application science, forecast speedup and production capacity savings are **not yet demonstrated**. Unlimited stack is part of the tested resource contract; no total stack-peak bound is claimed. No default or public Makefile change is made by this evidence package. The proposed module-only strict-GNU recipe and opt-out remain private pending application science. Prior bank/carry regressions are preserved separately in `EXPERIMENT.json`.
