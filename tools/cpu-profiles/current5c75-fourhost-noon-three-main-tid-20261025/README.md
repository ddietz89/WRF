# Current5c75 four-host noon: three main TIDs

Three requested 15-second native captures passed source-identity parsing after the instrumented 12→13 forecast passed the protected 185-step/two-FULL comparison. All four model scopes, scientific reader, recorders and both parser services closed normally. This is additional profile evidence for exact executable SHA `5c758822…`; it changes no selection, timing result or existing long-horizon qualification.

| Rank | Host / CPU | Observed thread | Primary records | NON_WRF period | Radiation records / period |
|---:|---|---|---:|---:|---:|
| 122 | hpc03 / 99 | compute_mainTID | 1393 | 45.95% | 218 / 15.96% |
| 386 | hpc03 / 12 | compute_mainTID | 1396 | 56.55% | 130 / 9.46% |
| 487 | hpc04 / 31 | writer_mainTID | 1432 | 100.00% | 0 / 0.00% |

Period percentages use that rank's sampled primary cycles as denominator. Radiation membership is explicit in PROFILE_QUALIFICATION.json. These selected main-TID shares are neither global headroom nor procedure costs. Primary/direct, nearest-frame and inclusive ancestry remain separate in the verbatim summaries; inclusive entries are nonadditive. NON_WRF does not establish a library implementation, idle time or causal MPI wait.

All collectors were admitted from the last completed model step at **12:25:15** (1515 simulated seconds), within an entry band 12:25–12:35. This does not pin all samples to that model time or guarantee radiation overlap. Both compute captures contain current SW/LW direct samples; the writer main TID has no direct current-WRF samples. Writer helper/compressor threads were not observed (`--no-inherit`, main-TID attach). Collector intervals include initialization/finalization and must not be called pure recording duration. Host-local monotonic timestamps are not a cross-host causal alignment.

Numeric loss and current/recorded build IDs are **UNKNOWN**. No LOST lines appeared in the retained primary/stack render outputs, which does not prove zero loss. Compute summaries retain an executable-path token in their raw recorded_buildID field; a pathname is not a build ID. Exact executable SHA, target lifetime, mappings, recorder identity, live FD/inode bridge, raw growth/stability and normal closures provide the admitted source identity. Original summaries are unchanged.

The first hpc04 metadata admission failed because its historical writer sampler snapshot held `[28,29,30,31]`, while the validator expected `[31]`. R2 admits only those two exact snapshots for writer487, and still requires live singleton CPU31 with identical PID/start ticks/executable/cgroup and all recorder/FD/raw/science predicates. The qualified wrapper's explicit borrowed pack cores explain the wider historical snapshot. Failure, source/lease classification and exact diff are retained under writer-snapshot-recovery. This proves neither continuous CPU31 affinity nor compressor-worker attribution. The compute admissions and hpc03 parser are unchanged; no forecast or capture was repeated.

The raw RESULT is retained for provenance, not for a speedup claim: its retained control is a 75-minute scientific prefix reference and its full-arm timings are not one-hour comparator metrics. Existing SAME512 fresh-three-hour and SAME256/long-horizon results remain separate and unchanged.

Top direct entries (each rank's own sampled period):

| Rank | Verified direct routine | Records | Period share |
|---:|---|---:|---:|
| 122 | `NON_WRF` | 649 | 45.948% |
| 122 | `__rrtmg_sw_vrtqdr_MOD_vrtqdr_sw_pair` | 52 | 3.824% |
| 122 | `__rrtmg_sw_spcvmc_MOD_spcvmc_sw` | 38 | 2.800% |
| 122 | `__rrtmg_sw_reftra_MOD_reftra_sw_clear` | 37 | 2.729% |
| 122 | `__module_small_step_em_MOD_advance_w` | 38 | 2.485% |
| 122 | `__module_advect_em_MOD_advect_scalar_pd` | 30 | 2.187% |
| 122 | `__rrtmg_lw_rtrnmc_MOD_rtrnmc` | 29 | 2.079% |
| 386 | `NON_WRF` | 793 | 56.549% |
| 386 | `__module_mp_thompson_MOD_mp_thompson` | 32 | 2.355% |
| 386 | `__rrtmg_lw_rtrnmc_MOD_rtrnmc` | 29 | 2.111% |
| 386 | `__module_small_step_em_MOD_advance_uv` | 25 | 1.762% |
| 386 | `__rrtmg_sw_vrtqdr_MOD_vrtqdr_sw_pair` | 22 | 1.602% |
| 386 | `__module_small_step_em_MOD_advance_mu_t` | 24 | 1.595% |
| 386 | `__rrtmg_sw_spcvmc_MOD_spcvmc_sw` | 19 | 1.389% |
| 487 | `NON_WRF` | 1432 | 100.000% |

The compute captures provide current instruction/routine leads in radiation and dynamics without transferring old executable addresses. Any source mechanism, supported inputs, numerical fidelity and complete-caller benefit need independent examination; these samples alone do not establish optimization benefit.

`EVIDENCE_REFS.json` binds original science, live watches, bindings and retained render facts by path and SHA. Verbatim summaries/primary records, parser closures and the scientific RESULT/reader/model closures are included. Large raw perf data and full rendered text stay in their original hash-bound locations. `MANIFEST.json` hashes this component, excluding itself. No runtime, scientific source, working alias or default was changed by this publication.
