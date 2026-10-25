# Match selected module-local SIMD flags

The qualified working SW and MYJPBL objects were compiled with `-fopenmp-simd`; canonical target recipes omitted it. This change makes that target-local flag explicit for the qualified GNU13.3/defaultREAL4 INTEGER4/pureMPI scope. It creates no OpenMP thread team, global compiler change, ISA change or fast math. SW uses the existing `WRF_SW_MCICA_WHOLE_DRAW_SEED_CARRY=1` opt-in/default guard; MYJ has `WRF_MYJ_SIMD=1`. Either corresponding knob set to0 omits the added flag and requires rebuilding the module/archive/executable.

Actual canonical preprocessing used the existing qualified configuration and standard preprocessor, not a guessed fresh configuration. Three objects were compiled, with no links or model runs. MYJ and SmallStep reproduce allocated machine/data/relocations and public module files exactly. SW retains strict-byte FALSE: its only45 instruction changes are Fortran I/O source-row immediates; its27 changed rodata words are exactly the changed fatal-error source-row arguments. Every other scientific instruction and all allocated relocations/public-module/global-data ABI agree. Source-row diagnostics differ. See the actual receipt and exhaustive classification; no normalization, row padding or acceptance waiver was used.

This is a scoped producer correspondence check, not a clean whole871 build certificate. The qualified871 executable/archive remain unchanged. The actual raw source-producing commit remains unknown. The preserved nine-hour qualification applies to871, not to a newly linked canonical executable.

Rollback: reverse GUARDED_TARGET_FLAGS_ONLY.diff, or use the stated per-module opt-outs and rebuild. Production/master are unchanged.
