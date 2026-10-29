# Selected working configuration — October 29

The selected image is `fb13c7be`, archive `184db5bb`. It retains all previous improvements, including MYJ and Thompson stack storage, RSL `e418b187`, provider `64bb4cf2` and all 18 direct inputs. This batch replaces two module objects and appends one PBL helper; the other 589 archive member payloads remain exact.

PBL factor fusion and guarded longwave two-channel interleaving are defaults within the qualified GNU Fortran/C 13.3 strict-O2 pure-MPI x86-64 build with four-byte default kinds. The complete PBL region was 21.77% / 22.05% faster; the guarded actual longwave caller was 9.09% / 8.91% faster. These are separate local measurements.

Own three-hour qualification passed the unchanged original checker: **four FULL products and 545 ordered steps**, with all four model jobs and the reader closed normally.

| Metric | Corrected-original control, median of 3 | Combined build | Descriptive reduction |
|---|---:|---:|---:|
| Wall minutes | 13.333735 | 10.490535 | 21.3234% |
| Main-step elapsed minutes | 9.940841 | 8.857374 | 10.8991% |
| Aggregate CPU core-hours | 99.813152 | 85.010204 | 14.8307% |

The table compares one candidate run with three retained controls and is **unpaired descriptive evidence**. Main-step elapsed includes communication and waiting. Kernel percentages are not added to forecast results.

This image owns only its three-hour application qualification. Its own noon, nine-hour, profile, restart and full-144-hour qualification remain pending. Parent `efa608eb` evidence is retained in the historical snapshot. Source commit `fd2d641d` records post-test correspondence; no clean or byte-identical rebuild is claimed.

Unlimited process stack remains required. Set `WRF_PBL_FACTOR_FUSION=0` or `WRF_LW_RTRNMC_TWO_G_CHANNEL=0` and rebuild the relevant module/helper/archive and relink to opt out. The longwave path uses the existing `WRF_PHY_INTERPOLATION_SIMD=1` helper owner. Whole-image rollback selects the retained efa6/05cc configuration.

[Component evidence and rollback](../cpu-compute/pbl-lw-guarded-batch-20261029/README.md) · [Own three-hour qualification](../cpu-compute/pbl-lw-guarded-batch-20261029/THREE_HOUR_APPLICATION_QUALIFICATION.json) · [Selected artifact binding](CURRENT_SOURCE_BUILD_BINDING.json)
