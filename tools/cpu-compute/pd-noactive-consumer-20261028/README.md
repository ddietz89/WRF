# Skip the PD consumer when no limiter is active

The unchanged decision loop records whether any cell needs limiting. When none does, the following six-face consumer is skipped. No floating-point operation, allocation or helper was added. The active route keeps the original arithmetic and update order.

The complete captured `advect_scalar_pd` caller, including allocations and tendency restores, was **9.23% shorter on hpc01 and 6.24% shorter on hpc02**. Four opposite-order, cache-cleared arms passed identical defined outputs, read-only inputs and floating-point state. The extracted all-active case was 2.85% slower; the mixed case was 6.92% faster. These remain separate workload observations.

Both O2/O0 genuine module gates and the added all-active/mixed checks passed. The combined image passed its own original three-hour full-grid comparison: all four complete products and 545 ordered steps matched exactly. Incremental whole-forecast speedup is not established by this run. [Kernel/caller evidence](KERNEL_AND_CALLER_EVIDENCE.json).

Default: `WRF_PD_NOACTIVE_SKIP=1` in the qualified strict GNU 13.3/O2/REAL4 INTEGER4/pure-MPI configuration. Explicit `WRF_PD_NOACTIVE_SKIP=0`, then regenerate/rebuild the module, rearchive and relink, restores the prior path. Other compiler/build defaults keep the original route. This is source correspondence to the tested objects, not a clean full-source rebuild certificate. Nine-hour, restart and full-144-hour qualification of this image remain pending.
