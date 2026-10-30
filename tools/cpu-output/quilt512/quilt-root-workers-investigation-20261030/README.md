# Fixed quilt-root worker experiment

This proposal keeps all 512 MPI ranks in their existing positions and moves the four compression workers onto CPUs 31, 63, 95 and 127, with the active writer's core first. It changes no worker count, codec, output shape, CPU quota, memory limit or MPI progress setting. The build-time switch defaults off.

The actual active `64bb` library and cached `78fa` shim object were reproduced exactly before building the candidate. Only twelve CPU words (48 bytes) differ in allocated data; code, runtime relocations, symbols, unwind data and other allocated data are unchanged. The DSO build-ID checksum also changes. Both libraries passed the retained eleven-case encoded-byte, independent stock-decode, five-state, read-only, layout, release and partial-join checks. The bounded native unit closed normally. These checks do not activate the real 512-rank constructor or qualify placement, application science or performance.

Current completed three-hour writer records contain 216 callbacks per writer, each with exactly four chunks and four workers. Worker slots 1–3 share exact physical cores with compute ranks. Their inclusive lifetimes differ from slot 0, but the records do not separate scheduling, packing, codec work or chunk contents. No callback scopes overlap across writers; this does not establish that the other quilt roots are idle.

The previous unloaded 64 MiB provider test was slower with quilt-only workers. That negative result remains retained. The new question is whether avoiding interference with useful forecast computation compensates for that known placement cost in the busy model. The whole-eight-rank group relocation and unrestricted mapping searches remain closed.

Retain this component for one fixed, bounded application comparison using the same WRF image, original scientific checker and full resource/cache/closure rules. Positive 512-rank worker placement and performance remain pending. The selected runtime is unchanged.
