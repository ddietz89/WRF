# Longwave conditional CDF2 storage

Promoted after its own three-hour full-grid exact qualification.

The cloud generator allocated CDF2 on every call although only overlap modes 4 and 5 use it. The candidate gives those branches their own array of the original shape. Generated code confirms one fewer allocation/free pair on production overlap mode 2; RNG and scientific arithmetic remain unchanged.

All 120 retained caller cases passed exact full-output, read-only, guard and processor-state comparisons, covering both RNG paths and all five overlap modes. The machine review accounts for every non-target routine and unchanged data pools.

| Complete MCICA33 caller | Parent seconds | Candidate seconds | Reduction |
|---|---:|---:|---:|
| hpc01, parent first | 0.493251 | 0.478823 | 2.925% |
| hpc03, candidate first | 0.492735 | 0.477725 | 3.046% |

Each measurement contains 20,000 complete adapter calls; per-call input reset and checks are outside the clocks. Caches were cleared before every measurement. Thread CPU fell 3.086% and 3.127%. These are short caller observations, not forecast gains or repeatability evidence.

One hpc03 attempt stopped on an incorrect hostname guard before execution. The failure is preserved; only its hostname check was repaired, and the completed hpc01 parent was retained without repetition. All actual workers closed normally afterward.

The original raw module-interface failure is also retained. The target interface remained byte exact; six downstream files passed the existing finite symbolic-interface check, with compiler-ID changes only. Scientific acceptance was unchanged.

[Evidence and source hashes](EVIDENCE.json). Rollback: rebuild with `WRF_LW_MCICA_CDF2_SCOPE=0`, or select the retained parent executable `0daea208`. Production is unchanged.

The combined executable `8fa12de9` completed all 545 ordered steps and four history products exactly. Wall time was 630.362 s, integration elapsed 531.654 s and total CPU 306244.506 core-s. Against the retained three-control median these are 21.207%, 10.864% and 14.773% lower, respectively. This descriptive comparison is unpaired and does not attribute the total gain to CDF2. The source projection matches the tested module; this is not a fresh full-source rebuild or nine-hour qualification.
