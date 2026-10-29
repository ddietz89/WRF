# Selected working configuration — October 29

The selected image is `3c3a0b54`, archive `da52db9a`. It retains LW `2325b160`, MYJ `24926bfd`, Thompson `9a255bfd`, RSL `e418b187`, provider `64bb4cf2`, all 18 direct inputs and the other 590 archive payloads. Two members were replaced and one helper appended.

Own three-hour science passed the unchanged original checker: **545 ordered steps and four FULL products**, with normal model and reader closures.

| Metric | Corrected-original control, median of 3 | Combined child | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.498019 | 21.2672% |
| Main-step elapsed minutes | 9.940841 | 8.863131 | 10.8412% |
| Aggregate CPU core-hours | 99.813152 | 85.084204 | 14.7565% |

This image owns only its unprofiled three-hour qualification. Own noon, nine-hour, profile, restart, full-144-hour, O0 and clean rebuild remain false. Parent fb13 profile/application records and older long-run records are historical. Main-step elapsed includes communication/waiting. Timing is one UNPAIRED descriptive observation versus fixed original median3; raw A2 scientific reference metrics stay separate.

The finite complete PBL-region screen was 15.34% / 27.79% shorter in wall time versus the selected scalar-fused helper; the scalar CU-region screen was 10.11% / 15.89% shorter versus its original schedule. All restores, admission guards and full regions were charged. These are separate initialized region fixtures, not captured forecast inputs, whole49 timings or additive application gains.

PBL SSE2 and scalar CU fusion use the existing qualified GNU Fortran/GCC 13.3 strict-O2 pure-MPI x86-64/default-kind envelope. Unlimited stack remains required.

Rollback: WRF_CU_FACTOR_FUSION=0 restores originaldeepCU while retaining qualifiedPBL. WRF_PBL_FACTOR_FUSION=0 restores originalPBL and disables nestedCU admission; regenerate/recompile corresponding module/helper/archive and relink. No flags change alreadycachedimage. Immediate image rollback selects retained fb13/184d with e418/provider64bb/all18.

Source commit `86c5c831` records post-test correspondence; raw producer commit stays NULL.

[Component evidence and rollback](../cpu-compute/pbl-simd-cu-fusion-20261029/README.md) · [Own three-hour qualification](../cpu-compute/pbl-simd-cu-fusion-20261029/THREE_HOUR_APPLICATION_QUALIFICATION.json) · [Selected artifact binding](CURRENT_SOURCE_BUILD_BINDING.json)
