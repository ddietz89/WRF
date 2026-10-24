# Curvature VXGM horizontal difference cache

The qualified GNU13.3 pure-MPI default computes the first VXGM horizontal J difference once per row before K using an existing row. The original subtraction, multiplication order, second metric difference, consumers and empty-K behavior are preserved. No new allocation, ABI, ISA, fast-math or compiler flag is added.

Native coverage:70 complete cases/four rounding modes; genuine and fresh O2 plus O0 bounds; full raw/read-only/guard/five-state and public MOD checks. Opposite-order500-call complete-curvature pairs reduced wall time3.6878% on hpc01 and0.5328% on hpc04, with exact outputs/state and actual cache clear before every arm. These are bounded caller observations, not isolated forecast gains.

The combined ECA4 image retains all previous169c/90f5 improvements. Its fresh corrected-original control-first three-hour pair passed all four products,545 ordered steps and original metadata/layout/runtime/writer checks. All eight model jobs and the reader closed normally. Whole model/MPI wall821.726553→643.246820s(21.7201% lower), main-loop elapsed596.857180→540.671580s(9.4136%), whole-job CPU368640.275284→311583.185499s(15.4777%). One pair does not establish repeatability or attribute the gain to this cache.

Only own three-hour science is qualified; own one-hour/nine-hour/profile/restart/full144 scopes are false. The source-only commit is post-test correspondence; raw producer commit is unknown. See APPLICATION_QUALIFICATION.json, EVIDENCE_INDEX.json and REBUILD_RECIPE.json for compact actual bindings.

Explicit opt-out:WRF_CURVATURE_VXGM_J_DIFF_CACHE=0, regenerate preprocessing, rebuild BigStep, replace the archive member and relink. Generic unsupported builds remain on the original path.
