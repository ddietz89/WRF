#ifndef NETCDF_PREDECODED_H
#define NETCDF_PREDECODED_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Experimental per-main-thread single-call read scope.
 * Fixed current-HDF native admission (pending cause proof/native gate): callbacks
 * require PREEXISTING SSE MXCSR.INEXACT plus all SSE/x87 exception masks set.
 * Other FP states use original H5Dread without a private attempt. This ABI never
 * raises/clears/normalizes flags and does not promise arbitrary FP-state speedup. Dataset is BORROWED:
 * provider must not close/store it, use HDF/NC/MPI from worker threads, or retain
 * caller data/user after scope. int64_t matches this pinned HDF5 hid_t ABI.
 * Return1 = all bytes supplied, no owned workers/resources live.
 * Return0 ornegative = caller buffer unchanged, workers joined, affinity restored;
 * owner rolls back PRIVATE attempt state/error stack then original H5Dread wins.
 * Any cleanup/restore uncertainty after publication MUST fail-stop, not fallback.
 * out/user/live callback buffers follow fixed nonalias/lifetime contract. */
typedef int (*nc_predecoded_float_provider)(int64_t dataset_id,void *out,size_t out_bytes,void *user);
int nc_predecoded_provider_begin(nc_predecoded_float_provider provider,void *user);
int nc_predecoded_provider_end(void);
#ifdef __cplusplus
}
#endif
#endif
