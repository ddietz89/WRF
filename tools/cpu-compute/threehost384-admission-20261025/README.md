# Three-node 384-rank admission: original exceeds memory cap

The corrected original WRF executable launched on hpc01–03 with 352 compute ranks (8×44) and 32 quilt ranks, 128 physical cores and a 100 GiB memory limit per node. During initialization, hpc01 hit that limit. The kernel records `CONSTRAINT_MEMCG` for this experiment’s cgroup and killed a WRF process. No forecast step completed; the candidate did not launch.

All three owned cgroups are now absent with no remaining processes. The coordinator retains its out-of-memory failure; resource cleanup does not establish a normal model completion. The stale `PREPARED_NOT_EXECUTED` completion field is preserved alongside the actual launch and kernel records.

The prerequisite fixtures passed separately: all 384 ranks passed input/output byte, state, authority and lifecycle checks; shared-table modes 0/1 passed all 24 NUMA cohorts. Their successful closures do not establish model memory fit or scientific qualification. An earlier fixture’s undersized census buffer failed, was preserved and was corrected before the successful fixture.

**Decision:** close this configuration as `ORIGINAL_MEMORY_ADMISSION_FAILED`. No valid 384-rank timing comparison, candidate fit, scientific acceptance or default change follows. The qualified 256-rank setup and selected BACF executable remain in use. No higher cap or further context sweep is planned from this result.

Hardware samples retain actual timestamps and failures. Early hpc01 BMC queries failed because the system tool was absent; the external observer was repaired to reuse its qualified project-local tool. Those missing readings remain unknown. The model package, scientific checker and execution limits were unchanged.

[Decision](DECISION.json) · [Hash-bound actual evidence](EVIDENCE_REFS.json)
