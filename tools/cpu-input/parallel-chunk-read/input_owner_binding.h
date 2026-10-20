#ifndef INPUT_OWNER_BINDING_H
#define INPUT_OWNER_BINDING_H
/* Actual eight-case-qualified private NC; runtime/build preflight verifies SHA.
 * Constructor also requires the loaded get/begin/end DSO to be this exact path.
 * No hash-loop/model I/O is introduced by the adapter. */
#define INPUT_OWNER_EXPECTED_PATH "/pool/wrf-experiment/wrf-cpu/kernels/ordinary-nc-predecoded-fp-admission-build-hpc02-r3/output/libnetcdf.so.19"
#define INPUT_OWNER_EXPECTED_SHA256 "a32aa6cdf5e7154b974afb699f6be8f0b0632cfb4bc00226b7b6a34e0b04f41d"
#define INPUT_OWNER_HEADER_SHA256 "c5c83cb35f383cc5877303c9ba17c3ab23943637e0f8ff2ebafef20182c7bd2f"
#endif
