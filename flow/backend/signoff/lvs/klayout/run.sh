#!/usr/bin/env bash
# SilicaFlow — LVS: KLayout backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "lvs" "klayout"

PNR_GDS="${PNR_GDS:-$WORK_DIR/pnr/${TOP}.gds}"
NETLIST="${SYNTH_NETLIST:-$WORK_DIR/synth/${TOP}_netlist.v}"
LVS_SCRIPT="${KLAYOUT_LVS_SCRIPT:-$ROOT_DIR/flow/backend/signoff/lvs/klayout/lvs_rules.rb}"

agent_hash_inputs "$PNR_GDS" "$NETLIST"

if [[ ! -f "$PNR_GDS" ]]; then
  echo "ERROR: Expected GDS at $PNR_GDS — run 'make pnr' first" >&2
  agent_finish 2 false "GDS not found: $PNR_GDS"
  exit 2
fi

rc=0
klayout \
  -b \
  -r "$LVS_SCRIPT" \
  -rd "input=$PNR_GDS" \
  -rd "schematic=$NETLIST" \
  -rd "report=$_AGENT_REPORT_DIR/klayout_lvs.lyrdb" \
  2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" lvs klayout "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=lvs │ tool=klayout │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
