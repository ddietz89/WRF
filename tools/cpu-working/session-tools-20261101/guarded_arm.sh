#!/bin/bash
# Usage: guarded_arm.sh <runtime-dir> <run-id>
# Runs the existing stage/prepare/clear/launch scripts unchanged, gated on no
# foreign wxplatform scopes on hpc01-04, then audits the run window for overlap.
set -euo pipefail
R=$1; RUN=$2; SHA=${CANDIDATE_SHA:-352f86ce75a95187744bdd414e5410841d4f08187389f4eaebd5645764a97312}
J="ssh -o ConnectTimeout=15 -o BatchMode=yes -o HostKeyAlias=hpc00 100.103.134.47"
U=wrf-cpu-$RUN-hpc01.service
cd "$R"
foreign() { # $1 = journal --since; prints count of wxplatform scopes active now or started since
  local n=0
  for h in hpc01 hpc02 hpc03 hpc04; do
    c=$($J "ssh $h 'a=\$(systemctl --user list-units --plain --no-legend \"run-r*.scope\" 2>/dev/null | wc -l); b=\$(journalctl --since \"$1\" --no-pager _UID=1000 2>/dev/null | grep -c \"Started run-r.*wxplatform\"); echo \$((a+b))'")
    n=$((n+c))
  done; echo $n; }
python3 stage_only.py --stage-reviewed | tail -c 120; echo
# Quiet gate: no foreign scopes active and none started in the last 4 minutes.
until [ "$(foreign '-4min')" = 0 ]; do echo "$(date -u +%T) waiting for quiet nodes"; sleep 30; done
echo "$(date -u +%T) quiet gate passed"
python3 prepare_arm.py candidate --execute-approved --candidate-sha $SHA | tail -c 150; echo
python3 clear_arm.py candidate --execute-approved | tail -c 120; echo
T0=$(date -u '+%Y-%m-%d %H:%M:%S')
python3 launch_arm.py candidate --execute-approved --candidate-sha $SHA | tail -c 250; echo
until s=$($J "ssh hpc01 systemctl show $U -p ActiveState --value"); [ "$s" = inactive ] || [ "$s" = failed ]; do sleep 15; done
$J "ssh hpc01 'systemctl show $U -p Result,ExecMainStatus'"
[ "$s" = failed ] && { echo "COORDINATOR_FAILED $RUN"; exit 3; }
python3 reconcile_models.py candidate | tail -c 120; echo
F=$(foreign "$T0")
echo "{\"run_id\":\"$RUN\",\"window_start_utc\":\"$T0\",\"window_end_utc\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"foreign_wxplatform_scopes\":$F}" | tee CONTENTION_AUDIT.json
