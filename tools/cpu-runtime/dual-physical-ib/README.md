# Dual physical InfiniBand diagnostic

Before this diagnostic, reported full-grid forecasts whitelisted only ibp1s0f0:1, despite eager/rendezvous rail caps2. Those results used one physical port; it remains the default. Both100Gb/s EDR ports on all four nodes are active, on distinct PCI paths/NUMA nodes; that inventory alone does not prove usable aggregate bandwidth or separate fabrics.

This four-rank hpc02/03 diagnostic now passed6912 exact payload/source/tag/count checks in each arm, fixed affinity, current system UCX/MPI and full mapped-dependency identity. Only UCX_NET_DEVICES changed from ibp1s0f0:1 to ibp1s0f0:1,ibp33s0f0:1. TLS remained rc,sm,self and both rail caps2. Checked cache clears preceded each arm. Both parent and peer scopes closed successfully after each. Resource limits were CPUs24–25,4GiB/node,zero swap,180seconds per arm. No source compilation or selected default changed.

[Actual qualification](ACTUAL_QUALIFICATION.json) binds both literal receipts, all four cache receipts, rank proofs and closures. [Protocol tables](ACTUAL_INTERHOST_PROTOCOL_TABLES.json) retain the actual message/API-specific policies. Root rehashed all25 qualification references.

Single-port logs selected the first endpoint, with zero second-port data-counter deltas on both hosts. Dual-port logs selected both rc_mlx5 endpoints and contain50/50 policies for eligible eager/rendezvous ranges. Second-port Tx/Rx raw counters each advanced41,253,422 on both hosts; first-port counters also advanced. This establishes configured dual-port operation and device activity consistent with the fixture. Per-message physical attribution remains explicitlyUNKNOWN; counters are devicewide and their units/width/background are not asserted.

The fixed single-first/dual-second observation includes a1MiB interhost cell whose sum of four rank-local MPI elapsed regions was0.109596420 versus0.035127948seconds. This is descriptive component timing, not global wall time, bandwidth, repeatability or a WRF speedup. Other cells are retained without collapsing them into an overall percentage. That component result did not by itself qualify a four-node forecast or change a default.

R1 stopped before payload execution because the wrapper expected the launcher library path without OpenMPI's known --prefix prepending. Both scopes drained; dualR1 was not launched. R2 restored only that strict expectation and used fresh namespaces. Actual runtime environment, fixture, scientific/payload checks and resources were unchanged; failed evidence remains preserved.

The subsequent same-image512-rank, three-hour comparison passed eight complete original-reference products and545steps per mode. All eight model scopes and the original reader closed positively; the unloaded reader exit-code property remainsNULL, with same-invocation manager success and absent/empty cgroup proof. Root rehashed all46 qualification references. Actual selected RSL output logs on all four hosts show first-port-only inter-node configurations in the single arm and both physical ports in the dual arm. Model port counters, per-message byte shares and striping thresholds were not recorded.

| Whole case measure | Single port | Dual port | Dual change |
|---|---:|---:|---:|
| Model/MPI wall |670.495863s|672.644788s|+0.3205%|
| Aggregate model cgroup CPU |323940.189933s|324383.392689s|+0.1368%|
| Main-step elapsed sum |562.185160s|562.465090s|+0.0498%|

This is one fixed single-first/dual-second pair, with client cache clears and uncontrolled file-server load. It establishes no speedup, causal regression or repeatability. Main elapsed includes communication/backpressure and is not integration CPU. Saved CPU-quota throttling counters are nonzero in both arms; their placement/cost is not attributed. Memory limit/reclaim events do not demonstrate pressure.

The dual case retained roughly6.4–7.8GiB more charged anonymous memory per node in matched main-loop samples; file/shmem charges were nearly identical. Peak charges were6.69–6.82GiB higher. Allocation owner, exact peak categories and physical RSS/PSS remainunknown; these observations do not prove a UCX allocation cause. [Full-grid qualification](FULLGRID_QUALIFICATION.json), [all timings](FULLGRID_RESULT.json), [literal endpoint evidence](FULLGRID_ENDPOINTS.json) and [retained memory audit](RETAINED_MEMORY_AUDIT.json) preserve the scope.

[Disposition](WORKING_DISPOSITION.json): retain the scientifically qualified dual-port option for this exact configuration and keep the current single-port default. No source/runtime promotion or new broad transport sweep follows. Selected-source rollback remains b1fb/source4e70; switching back from the optional mode requires only the original single-port whitelist in its reviewed lease.
