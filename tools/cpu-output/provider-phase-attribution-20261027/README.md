# Output provider cost attribution

The current four-worker provider passed its complete W-shaped synthetic fixture, including exact compressed bytes, stock decoding, read-only inputs, floating-point state and release checks. Separate cache-cleared original and instrumented arms completed normally.

Across eight measured callbacks, worker CPU comprised **43.70% fused packing/byte shuffle**, **56.22% compression**, and 0.07% other work. This supports investigating the packing loop. It does not isolate row-index calculation or establish a fraction of total forecast time. Worker wall times overlap and must not be summed.

A prior full-grid public-I/O diagnostic found provider work accounted for 23.16 of 25.36 seconds in one active writer's public put calls, while direct HDF5 chunk writes took 2.03 seconds. This is one writer's nested output envelope; it is not a global critical-path or durable-storage measurement.

Next: test one integer row cursor that removes repeated coordinate reconstruction, preserving row order, fills, shuffle operations, streams and ownership. The instrumented-versus-original observations are diagnostic context, not an optimization result. Exact references, metrics and limitations are in RESULT.json. Earlier startup failures remain preserved in private evidence.
