# Synthetic KSM sharing pilot

The approved hpc02 pilot passed four independent anonymous mappings, exact bytes and one-page copy-on-write. Each 4,186,112-byte advised interior shared down to 1,046,528 bytes of PSS; aggregate PSS fell 12,558,336 bytes. Unadvised endpoint controls stayed private. All workers unregistered, unmapped and exited normally.

Global scanning ran for 1.7959626 seconds and returned to run0 before mutation. The unit closed successfully with its cgroup absent, and the rollback backstop confirmed run0. Other scanner settings stayed fixed. Global counters remained nonzero after cleanup; this does not establish complete host unmerging or isolation.

[Qualification](QUALIFICATION.json) binds actual artifacts and the same-invocation journal recovery. The initial collector failed on a long journal field; bounded read-only recovery obtained the actual result without rerunning the pilot. Earlier staging and noexec failures remain preserved.

This qualifies synthetic sharing and COW. WRF tables, Fortran allocation lifetimes, MPI/UCX-pinned pages, NUMA effects and forecast benefit still require their own evidence. KSM remains off and the working model configuration is unchanged.
