# PD tendency SIMD and compressed-result buffer reuse

The qualified working configuration selects executable `fbcd0463`, archive `a49db4d9` and output shim `8bee3346`. It retains previous input, compute, codec and output improvements. Tested source was recorded afterward in commit `6697020f800df164e3dee6d04d7c3639b297cca6`; original producer commits remain NULL.

PD adds two independent-I SIMD directives to the final X/Y tendency consumers in `advect_scalar_pd`. The captured complete caller, including identical tendency restoration, was 6.0683% and 9.1884% shorter in opposite-order host pairs; process CPU was 6.0745% and 9.2053% lower. Exact same-opt captured, edge, IEEE, ordinary-regression, readonly and five-state checks passed under O0/bounds and O2. The original failed source-coordinate attempt is retained; the repaired source preserves other-function bytes/relocations and the public module. Actual generated-code review found packed consumer loops, unchanged 0x7a0 frame and no floating-point spills in their main vector backedges; setup/tail stack traffic remains.

Output reuse retains four separate compressed-result capacities under the existing nonblocking bank lease until the real owner release. A busy bank keeps the original private-allocation fallback. Per-call compression bounds, error cleanup, public ABI, four-stream layout and codec remain unchanged. Warm fixed32-call provider-plus-real-owner-release wall phases were 6.0574% and 4.1843% shorter; process CPU was 2.6287% and 2.6570% lower. These component clocks exclude byte checking and are not whole-output timings. Original layout/scratch cases, added ownership/error cases, exact compressed/decoded bytes, five-state checks, full-shim ABI/thread observations and negative eligibility tests passed. The parent bb65 short test is component evidence, not a new-image short certificate.

## Original three-hour science and timing

The unchanged checker passed all four products and 545 ordered timesteps through09:00, with512 ranks, two tiles, four positive writers487/495/503/511, exactly32 field markers and all32 quilt FIELDVIEW1 settings. Every model and reader job closed normally. [Actual application qualification](APPLICATION_QUALIFICATION.json) binds83 raw references and the1262-file runtime graph. This combined image owns three-hour science only; separate short, noon and nine-hour qualification remain false.

| Measure | Retained corrected original546b | Combined fbcd/8bee | Descriptive reduction |
|---|---:|---:|---:|
| Whole model/MPI wall, including output and drain |980.207680s|658.139651s|32.8571%|
| Integration-step elapsed, including communication/backpressure |757.688050s|556.421030s|26.5633%|
| Aggregate four-node CPU |449620.407146 CPU-s|318924.867798 CPU-s|29.0680%|

This is **UNPAIRED**: the original is retained from the preceding fresh original/bb65 comparison; no new original forecast ran. Each arm had checked compute-client cache clearing at its own execution. Normal source/library loading and uncontrolled file-server cache/load remain. These values establish no isolated PD/buffer contribution, additive gain, repeatability or concurrent throughput. Main-step elapsed is not integration CPU, node CPU includes MPI spin, and whole-minus-main is not pure I/O. The descriptive single-forecast wall ratio is1.48936x; 1.5x throughput and2x speedup are not established.

Actual candidate node peaks were 58.699/56.568/56.517/56.501GiB against100/100/100/104GiB caps, with zero memory events and recorded CPU-quota throttling. All four writer roots were active. Retained logical capacities are not measured per-root physical memory costs or a future-horizon bound.

## Build scope and rollback

The qualified recipe is GNU13.3 on the admitted EPYC/AVX2 stack, with strict original numerical flags. [PD build proof](PD_BUILD_QUALIFICATION.json) replaces only archive slot555 (a36→241989), preserving583 members, the public module, four helper objects and6518 IO tail; it performs no WRF source compile and one link. [Full-shim proof](CAPACITY_FULL_SHIM_QUALIFICATION.json) separately reproduces parent51a and builds8bee by changing only the provider source. These are component/overlay proofs, not a whole-image rebuild claim. The default `fused-pack` builder now pins provider86aa and artifact8bee; generic compiler/architecture qualification is not inferred.

Rollback to commit `69f3e9a06fa0e9ca07eb27e82d21b08d79e018cc`: restore `dyn_em/module_advect_em.F`, `tools/cpu-output/quilt512/root_chunk_provider.c`, `tools/cpu-output/quilt512/qualification.json` and all three `tools/cpu-working` JSON records together. Select retained bb65/0507 and51a. The selector must accompany the source because it validates the provider hash. Production and master are untouched.
