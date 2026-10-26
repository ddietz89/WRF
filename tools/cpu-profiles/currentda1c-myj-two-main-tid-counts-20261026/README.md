Current da1c MYJ two-main-thread observation

Own instrumented SAME512 noon science passed185orderedsteps/twoFULL; allfourmodels, reader and parser closed normally. Exact selectedda1c/a8d9/source d501; mainTIDs114/122 onhpc03 CPUs67/99. Requested15s capture; collectorintervals17.994/17.348s includeinitialization/finalization. Primarysample spans15.006/14.993s; actualstatstart/endunknown, countedscheduledruntime14.204/14.166s. Allfourcount events ran100% withoutscaling.

| Rank | Cycles/instruction | L1DTLB misses/reloads /1000 instructions | L2 datarequestmisses /1000 instructions | DirectMYJ main samples |
|---|---:|---:|---:|---:|
| 114 | 0.432807 | 0.638362 | 1.490529 | 8 |
| 122 | 0.425156 | 0.485005 | 1.457594 | 16 |

These are whole-main-thread counts including MPI/libraries andotherphysics. Rank114 has more instruction-normalizedTLB events while rank122 has twice as many directMYJ-main samples. That supplies no per-loop miss attribution and does not establish MYJ cache/TLB limitation, compute limitation, stalls, criticalrank or globalheadroom. Neither rank is labelled typical/slow from this capture.

DirectWRF coverage is radiation-heavy: SWpair/SPC/reftra have48/46/38 samples on114 and38/32/53 on122. W33/27, PD31/28, UV28/22 and MYJ8/16 remain visible. These are actual local samplecounts, not globaltime shares or additivecallercost. MYJ+3219 recurs on122 in already-audited SPECIESpacking; no new distinct removal/vector mechanism survives dedup. No additional experiment is proposed from these counters alone.

Numericloss remains UNKNOWN despite no observedLOST lines. Current/recordedbuildIDs remain UNKNOWN; parser rawrecorded-ID field contains anELFpathname, not a usableID. Exact currentELF hash/ranges still admitted. MainTIDonly/mixedIO/radiation overlap means no writerworker or MPIcausal headroom claim.

R1 partialacquisition and invalidsupportalias failures are retained in ACQUISITION_HISTORY.json; R2 doesnotrewrite them. Selectedsource/default/unprofiled3h/noon/9h results areunchanged. Profilequalification is restricted to this owninstrumented185/twoFULL scientific and source/count acquisition scope.
