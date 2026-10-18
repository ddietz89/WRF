# Retained co-located output groups

This optional world-512 placement preserves all 480 compute rows and puts each eight-rank quilt group on one host. Writer roots 487/495/503/511 use hpc01/02/03/04 and CPUs 31/63/95/127. The exact table and matching host-specific guard source are retained here; the working default remains the legacy map and provider.

The actual three-hour d02/801d control/candidate pair passed four complete products, all 545 ordered steps and all-512 runtime/writer checks. Wall was 687.949623 to 676.891422 seconds (1.6074% lower), CPU 1.4854% lower and main-step elapsed 1.3946% higher. This is one fixed-order placement comparison, not a new original-code or sustained speedup result. Client caches were cleared before each arm; server cache/load was uncontrolled. Do not add this percentage to prior combined gains.

Memory headroom is the practical cost. Candidate peaks were 100.000/99.751/99.749/99.584 GiB; host01 recorded 2,482 cap events, with no OOM on any host. Control peaks were 92.230/94.311/94.232/100.254 GiB under 100/100/100/104 GiB limits. Sampled high usage was predominantly anonymous. Per-host peaks are separate events and must not be added into a simultaneous total. The source audit identifies overlapping receive buffers, remaining-field caches and root assembly/provider buffers; it does not attribute the measured charge or timing to a particular allocation.

Use the exact provider and R3 candidate lease recorded in QUALIFICATION.json with a fresh run/log/lease namespace and the existing bounded launcher. This source needs the unchanged parent-directory headers/provider/adapter and strict native recipe; the historical native public fixture used its recorded older codec/HDF5 stack, while the actual512 placement pair used current 881d/825e. Do not assume the ordinary build.py selector chooses this alternative. Keep MPI/NetCDF/HDF5 on the main thread and UCX rc,sm,self over the qualified InfiniBand interface.

The pre-MPI R2 candidate failure and its fixed launcher assertion remain historical failures. The successful R3 reader selects the immutable R2 control manifest/grant explicitly; no old grant or model output was rewritten. Protected science, compare_one, runtime, output-layout and sequence predicates remain unchanged.

Rollback uses the unchanged tools/cpu-working/selection.json (375aa7 provider and faba map). No production or master changes are part of this retained alternative. Revisit it when buffer-memory mitigation or a selected sustained forecast provides new evidence.
