#ifndef RAW_CHUNK_DECODE_H
#define RAW_CHUNK_DECODE_H
#include <stddef.h>
#include <hdf5.h>
/* Prototype-local parallel raw-chunk reader for the synthetic T field only.
 * Return:  1 = out fully supplied (byte-exact bytes of the 4D field, C order)
 *          0 = unsupported by this helper; caller MUST use original NC4 path
 *         <0 = operational/decode failure; out is byte-exact unchanged
 * why/whycap: bounded NUL-terminated integer/log message; may be written on any return.
 * On any return != 1, *out is unchanged (strict transactional commit).
 * out, cpus and why point to distinct non-overlapping caller-owned storage;
 * the caller owns dset and keeps it open and immutable until return.
 * No HDF5/NC/MPI calls are made from worker threads. */
int raw_parallel_read(hid_t dset, unsigned char *out, size_t out_bytes,
                      const int cpus[4], char *why, size_t whycap);
#endif
