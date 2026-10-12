#ifndef ROOT_CHUNK_PROVIDER_H
#define ROOT_CHUNK_PROVIDER_H
#include "netcdf_precompressed.h"
typedef struct {int threads;int cpus[4];} root_chunk_options;
int wps_root_provider(const nc_precompressed_float_layout*,const void*,size_t,nc_precompressed_float_batch*,void*);
#endif
