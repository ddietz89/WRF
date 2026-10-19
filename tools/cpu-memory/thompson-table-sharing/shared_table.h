#ifndef SHARED_TABLE_H
#define SHARED_TABLE_H
#include <mpi.h>
#include <stddef.h>
/* Experimental byte owner, not a Fortran ALLOCATABLE replacement.
 * All calls collective on the same valid supplied compute intracommunicator.
 * No concurrent helper calls/readers during create/destroy. Staging is caller owned.
 * All staging bytes must agree within each admitted NUMA cohort. Opt-in and size
 * must agree across the supplied communicator. Invalid/fabricated handles are UB.
 * MPI errors abort; validation errors leave input storage and existing live owner
 * unchanged. Fresh failed creates leave owner/view NULL. Never free a view. */
typedef struct st_owner st_owner;
enum { ST_SHARED=0, ST_PRIVATE=1, ST_UNSUPPORTED=2, ST_ARGUMENT=3,
       ST_STATE=4, ST_MISMATCH=5, ST_RESOURCE=6 };
int st_create(MPI_Fint compute, const void *staging, size_t bytes, int opt_in,
              st_owner **owner, void **view);
int st_destroy(MPI_Fint compute, st_owner **owner, void **view);
/* Diagnostic fields only; no topology/physical-page residency promise. */
int st_describe(const st_owner *, int *compute_rank, int *node_rank,
                int *numa_node, int *cohort_rank, int *cohort_size,
                int *cpu_count, size_t *bytes);
#endif
