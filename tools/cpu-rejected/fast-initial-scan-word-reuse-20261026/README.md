FAST initial scan-word reuse — closed unpromoted

Actual GNU13 native correctness passed:24 wholematcher cases,6 unchanged prefix guards,13 complete codec cases,5 stream cases and both32call providers; fullbytes/read-only/chaintrace/five-state exact. One private FAST object changed,51 other codec objects unchanged.

The requested initial short-path overlapping load is removed in actual assembly. The replacement reads the firstword stackslot through SHRX and adds a shiftcount dependency; two savedword spills remain. No cycle-cause claim is made.

Complete provider32calls, one oppositeorder pair perhost with checked cacheclear before EACH arm and all four normal closures: hpc01 wall0.268812%/CPU0.328888% slower; hpc02 wall1.532665%/CPU0.587806% slower. All raw/gold/stockdecode/read-only/five-state checks passed unchanged. These measured complete-provider regressions establish no benefit for this fixed candidate. Native internal untimed numbers are excluded from performance conclusions. No separately demonstrated positive kernel gain or resource benefit is discarded.

No forecast, additional arms or spelling variants planned. Selected NG9371 and all WRF/default/source configuration remain unchanged. Rollback requires no action.
