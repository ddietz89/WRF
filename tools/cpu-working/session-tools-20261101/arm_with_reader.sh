#!/bin/bash
# Usage: arm_with_reader.sh <runtime-dir> <run-id> <tag>; guarded model run, then the unchanged reader and collector.
SP=/tmp/claude-1000/-home-ddietz-wrf/0df3e64e-9311-4710-8322-9babb0b17cad/scratchpad
B=$1; RUN=$2; T=$3
$SP/guarded_arm.sh $B $RUN > $SP/$T.log 2>&1; rc=$?; echo "guarded rc=$rc" >> $SP/$T.log
[ $rc = 0 ] || exit $rc
cd $B && python3 launch_reader.py --execute-approved >> $SP/$T.log 2>&1 || exit 4
for i in $(seq 1 ${READER_POLLS:-90}); do o=$(python3 collect_results.py 2>&1); echo "$o" | head -1 | grep -q "'MainPID': '0'" && echo "$o" | head -1 | grep -qE "PASS_|FAIL" && break; sleep 10; done
echo "$o" > $SP/$T.result.txt
