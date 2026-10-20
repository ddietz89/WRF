# Dual physical InfiniBand diagnostic

Recent reported full-grid forecasts whitelist only ibp1s0f0:1, despite eager/rendezvous rail caps2. They are single-port results. Both100Gb/s EDR ports on all four nodes are active, on distinct PCI paths/NUMA nodes; that inventory alone does not prove usable aggregate bandwidth or separate fabrics.

This four-rank hpc02/03 diagnostic now passed6912 exact payload/source/tag/count checks in each arm, fixed affinity, current system UCX/MPI and full mapped-dependency identity. Only UCX_NET_DEVICES changed from ibp1s0f0:1 to ibp1s0f0:1,ibp33s0f0:1. TLS remained rc,sm,self and both rail caps2. Checked cache clears preceded each arm. Both parent and peer scopes closed successfully after each. Resource limits were CPUs24–25,4GiB/node,zero swap,180seconds per arm. No source compilation or selected default changed.

[Actual qualification](ACTUAL_QUALIFICATION.json) binds both literal receipts, all four cache receipts, rank proofs and closures. [Protocol tables](ACTUAL_INTERHOST_PROTOCOL_TABLES.json) retain the actual message/API-specific policies. Root rehashed all25 qualification references.

Single-port logs selected the first endpoint, with zero second-port data-counter deltas on both hosts. Dual-port logs selected both rc_mlx5 endpoints and contain50/50 policies for eligible eager/rendezvous ranges. Second-port Tx/Rx raw counters each advanced41,253,422 on both hosts; first-port counters also advanced. This establishes configured dual-port operation and device activity consistent with the fixture. Per-message physical attribution remains explicitlyUNKNOWN; counters are devicewide and their units/width/background are not asserted.

The fixed single-first/dual-second observation includes a1MiB interhost cell whose sum of four rank-local MPI elapsed regions was0.109596420 versus0.035127948seconds. This is descriptive component timing, not global wall time, bandwidth, repeatability or a WRF speedup. Other cells are retained without collapsing them into an overall percentage. No four-node512-rank forecast or default promotion follows from this diagnostic.

R1 stopped before payload execution because the wrapper expected the launcher library path without OpenMPI's known --prefix prepending. Both scopes drained; dualR1 was not launched. R2 restored only that strict expectation and used fresh namespaces. Actual runtime environment, fixture, scientific/payload checks and resources were unchanged; failed evidence remains preserved.

Next is one current-build full-grid single/dual comparison with unchanged science/runtime, cache clears and exact original acceptance. No transport default is changed before that application qualification. This folder is evidence-only; selected rollback remains b1fb/source4e70 and its pinned single-port runtime.
