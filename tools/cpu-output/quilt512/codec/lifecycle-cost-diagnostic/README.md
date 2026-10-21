# Codec initialization and teardown cost

Decision: park cross-callback stream reuse. This experiment adds no optimization or selected runtime change.

The bounded current-e1d8/D45 synthetic four-worker provider diagnostic captured128 real initialization and128 teardown calls. Combined brackets measured5.973ms thread CPU out of6.752s process CPU (0.08846%), and4.894ms same-clock interval union out of2.174s complete-provider wall (0.22515%). Bracket overhead is included and uncalibrated; these are component observations, not removable-cost ceilings or forecast fractions. Baseline/observed ordering and instrumentation explain no causal speedup. Do not scale these synthetic timings by production callback counts.

Compressed bytes, independent stock decoding, raw/readonly input, all five state words and136 successful creates/joins per execution passed. Actual interposition count/native library bindings were hard checks. Both build and diagnostic jobs closed with verified same-invocation journal evidence and absent, empty cgroups; the diagnostic had a checked hpc02-only cache clear. The first two connection failures remain preserved in the external evidence.

One chunk is processed per worker in the observed production layout, so a reset inside that worker loop would not amortize initialization. Reusing codec state across callbacks would introduce persistent ownership and cleanup machinery. No significant benefit has been demonstrated to justify that change. A future production profile showing a materially different cost would be new evidence; the older3edf codec capture does not establish currente1d8 fractions.

[Qualification and14 checksummed external references](QUALIFICATION.json) retain scope and limitations. No rollback is needed because selected code/libraries/defaults are unchanged.
