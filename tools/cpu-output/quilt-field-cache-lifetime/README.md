# Quilt retrieval scratch lifetime

Promoted in selected image `ba422b71`, source `748701ba`, after native checks and exact three-hour full-grid qualification. After STORE finishes its existing owned field snapshots, the full gathered buffer is replaced with scratch sized for the largest committed field. Original retrieval capacity, byte order, truncation and control-message behavior remain intact. Existing C API function bodies are unchanged.

All four products, metadata/layout, 545 ordered timesteps and all-512 runtime/writer/tile/affinity/library/InfiniBand checks passed the unchanged original checker. Every model and reader scope closed. [Qualification](QUALIFICATION.json) joins the [native gate](NATIVE_QUALIFICATION.json), [source binding](SOURCE_COMMIT_BINDING.json) and [application](APPLICATION_QUALIFICATION.json).

| Metric | Retained original | New combined build |
|---|---:|---:|
| Model/MPI wall | 819.733452 s | 669.470947 s |
| Aggregate CPU | 367241.169317 s | 323316.632919 s |
| Main-step sum | 597.578550 s | 563.887060 s |

This is one new candidate versus an immutable retained original control, with checked client cache clears before each run at different times. It is not a fresh two-arm benchmark. The descriptive reductions are 18.3307% wall, 11.9607% CPU and 5.6380% main; file-server cache/load remains uncontrolled. Compared with the separate preceding 6365 run, wall/CPU/main were 4.6749/4.0688/1.9219% lower. These observations do not isolate the scratch change or establish repeatability.

Final per-node cgroup peaks fell from 92.184/94.265/94.257/100.223 GiB in 6365 to 90.979/89.445/89.405/94.506 GiB in ba422 (see exact bytes in the application record). Thirty-second sampled anonymous-memory maxima were 1.40–1.56 GiB lower per host; sampling can miss peaks and is not phase aligned. All model memory-limit/OOM events were zero; CPU throttling was nonzero. No source-causal attribution is made from these separate runs.

Initial STORE duplication peak and payload-copy volume remain unchanged. One additional normal allocation may move fatal OOM timing. No new nine-hour/restart/144-hour or other-compiler qualification is claimed.

Rollback selects retained 6365 with the same 375/faba/881d/825e runtime, or reverts 748701ba and rebuilds the C/quilt objects, archive and executable. Production and master remain unchanged.
