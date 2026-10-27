# Guarded physics interpolation SIMD — promoted

The working configuration passed its own unprofiled three-hour full-grid check: four complete outputs and545 ordered timesteps exact. [Application result, controls and scope](APPLICATION_README.md). [Qualification](THREE_HOUR_APPLICATION_QUALIFICATION.json).

The isolated interior loop was47–48% faster on the tested nodes; the completePHY caller remained flat/mixed. These are separate scopes. The read-only hardware guard preserves the original scalar path when any exception is unmasked.

The preparation records below preserve their original pre-application scope.

This file records mechanism, native and timing evidence. The actual application outcome and post-test source binding are recorded separately in APPLICATION_README.md, APPLICATION_DECISION.json and THREE_HOUR_APPLICATION_QUALIFICATION.json when present. PRE_APPLICATION_DECISION.json is an immutable historical snapshot, not current qualification.

This component adds SIMD to the existing interior p8w/t8w interpolation loop. The two original multiply–add trees remain unchanged. A read-only helper checks all six exception masks in both x87 and SSE once before the 3D loop; any unmasked mode takes the literal original scalar loop. The local PURE BIND(C) declaration follows GNU’s own hardware-mask-reader precedent and does not import the IEEE module or change FP state.

Native qualification passed all 55 retained whole-PHY cases in four rounding modes at O2 and O0, with raw outputs, read-only inputs, physical guards, all five state values and exact original public MOD. O2 machine review confirms one real helper call, no IEEE entry/exit envelope, packed interior arithmetic and scalar fallback/tails. The sole non-target difference is two unchanged calc_mu_staggered callees’ relocated symbol values in couple; raw body/size and callee remain exact. O0 non-target equivalence is not claimed.

| Screen | Host | Parent wall (s) | Candidate wall (s) | Wall lower | Thread CPU lower |
|---|---|---:|---:|---:|---:|
| Complete PHY, 512 calls | hpc03 | 3.916703467 | 3.898837740 | 0.4561% | 0.4487% |
| Complete PHY, 512 calls | hpc04 | 3.915765207 | 3.921643166 | -0.1501% | -0.1559% |
| Extracted interpolation, 2048 loops | hpc03 | 0.277829652 | 0.143620589 | 48.3062% | 48.3264% |
| Extracted interpolation, 2048 loops | hpc04 | 0.273089801 | 0.144788716 | 46.9813% | 46.9775% |

Both screens charge mandatory full output restores and one guard per call/loop inside integer wall/thread-CPU intervals. Every same-count arm matches complete raw data and both warm/final five-state observations; caches clear before each arm and all units close normally. The complete caller shows no consistent significant gain. The extracted screen demonstrates a significant exact loop gain on retained synthetic whole-PHY inputs with a genuine warm-output oracle. It is a separate compiled API, not full-module machine identity or a forecast speedup.

The cached experimental child is 33a2bf43 / archive 5b482a49 over parent 330db1c1 / b3794efe: one BigStep member replaced, one helper appended, 585 total members and 583 unchanged, zero science/helper compilations and one link. Application qualification requires its own protected four-FULL/545-step comparison, four normal model closures, reader closure, and a real post-test source commit. No parent noon/profile/nine-hour qualification is inherited. See the application records for the actual outcome.

WRF_PHY_INTERPOLATION_SIMD=0 restores the original interpolation on rebuild. The implementation scopes default1 to the qualified configuration; unsupported configurations retain the original path. This mechanism record makes no current default-selection qualification claim. Source correspondence is scoped to the tested target and cached PP/object, not a clean full-source build certificate. Earlier inventory, state, MOD and caller-fixture failures remain recorded in PRESERVED_FAILURES.json.
