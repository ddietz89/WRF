Why the three-hour and nine-hour integration comparisons differ

The larger reported nine-hour reduction (21.84%, versus 9.28% at three hours) comes mainly from slower retained original controls, not a newly observed acceleration in the selected executable. On the **same first 545 timesteps, 06:00–09:00**, the original nine-hour controls were 20.08% slower than the recent three-hour controls; selected 4974 was effectively unchanged. These comparisons remain descriptive and unpaired.

| Integration time for identical first 545 steps | Recent three-hour runs | Nine-hour runs, first three hours |
|---|---:|---:|
| Original 546b, median of 3 distinct runs |596.45045 s|716.21278 s|
| Selected 4974, one run each |541.10874 s|540.55227 s|

The difference persists through ordinary steps after excluding the first 15 steps and hourly-output endpoints plus adjacent steps: median 1.064345 s in recent original controls versus 1.27139 s in the older originals. The first-step difference is only 1.6319 s of the 119.76233 s prefix gap, so warm-up alone cannot explain it. Hourly endpoints are descriptive labels; no radiation, I/O or MPI attribution follows from them.

The audit establishes:

- All six original controls bind the same 546b executable and f340 buildreceipt/archive 36072784; exact 512-rank FABA host/CPU mapping, 8×60 compute decomposition, two tiles and matching first 545 time/dt/domain sequence. Retained original namelists differ only in horizon.
- Monitored libraries actually loaded by WRF ranks match, including the pinned MPI/UCX, HDF5, netCDF and pool zlib. The changed system-zlib hash appears among launcher/monitor processes, not WRF ranks.
- Old hpc04 cgroups reached the 104 GiB cap later, but their first reclamation samples occur at 1344–1407 elapsed seconds. Even assigning all non-integration elapsed time before the prefix places its completion by 909–943 seconds. This excludes that later cgroup reclamation as the cause of the first 545 slowdown; it does not certify all host-wide memory behavior.
- CPU accounting shows about 128 busy cores in old and recent runs. It excludes a 20% quota-underfill explanation, but busy polling and useful computation both consume CPU time. Historical frequency, IPC, governor and memory-channel performance were not captured.

The retained UCX logs also rule out an observed intra-node TAG transport switch: all three older nine-hour originals and recent A2 report the same 512 configurations—508 cfg0 and 4 cfg1—with `tag(sysv/memory cma/memory)`. They do not report active XPMEM for those configurations. This does not establish historical module/device state or rule out performance differences under an unchanged configuration. `MAX_RNDV_RAILS=2` is an environment allowance, not proof that two inter-node rails were active. No further log acquisition is proposed for this lead.

The owner reports that **the power supply was replaced**, with nothing else/settings changed and no intentional BIOS/configuration changes. That is a repair report, not evidence that the PSU caused a performance change. The underlying slowdown remains unresolved. A fresh corrected-original nine-hour control started on October 26 at 11:21 UTC to test the current operational epoch against the already completed selected 4974 run. The run and unchanged exact checker have now completed: all ten full products and all 1,625 ordered timesteps match selected 4974 exactly. This single reverse-order observation cannot create a repeated or bracketed comparison. No source, default or science check changes are proposed.


The fresh original first545 takes598.32161s, within0.314% of the recent3h original median596.45045s; the older9h median was716.21278s. The fresh full9h comparison is below. It is one selected-first/original-later observation, not a repeated or bracketed pair. Historical medians and qualification receipts remain unchanged.

| Nine-hour measure | Fresh original (n=1) | Selected4974 (n=1) | Descriptive reduction |
|---|---:|---:|---:|
| Model/MPI wall, minutes |34.16|29.78|12.81%|
| Main-step elapsed, minutes |30.85|28.11|8.88%|
| Aggregate CPU, CPU-hours |278.16|249.39|10.34%|

Main-step elapsed includes communication and waiting. No I/O decomposition, isolated component gain or causal PSU explanation follows. Original models and reader closed normally; the garbage-collected reader retains numeric exit_code null with invocation-bound manager success and an absent cgroup. The new evidence adds no qualification for an unrelated child executable.
