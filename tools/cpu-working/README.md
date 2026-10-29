# Selected working configuration

Image `6bc47f88`, archive `aeb4f38f`, source `8d2aa02c`. Both its own unprofiled three-hour and nine-hour runs are qualified.

| Metric | Retained original N1 | Selected 6bc4 | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 34.157236 | 29.128442 | 14.7225% |
| Main-step elapsed minutes | 30.845967 | 27.552611 | 10.6768% |
| Aggregate CPU core-hours | 278.157466 | 244.440840 | 12.1214% |

Selected 6bc4/aeb4 passed its own unprofiled nine-hour run on the same 512-rank configuration, from 06:00 to 15:00: 1,625 ordered steps and ten FULL products exact under the unchanged original checker; all four models and reader normally closed. Its existing own-three-hour qualification remains immutable and separate. Its noon, profile, restart, full 144-hour, O0 and clean-source-rebuild qualification remain false. Source 8d2aa02c records correspondence after testing; the raw producer commit remains NULL. Nine-hour timings are candidate-only UNPAIRED descriptive against retained original N1 only, not pooled/rolling median, matched repeatability, isolated helper gain, or additive kernel percentages. All runtime guards/resources/providers unchanged; no memory-capacity claim.

[Evidence](../cpu-compute/cu-fourcolumn-simd-20261029/README.md) · [Selected binding](CURRENT_SOURCE_BUILD_BINDING.json)
