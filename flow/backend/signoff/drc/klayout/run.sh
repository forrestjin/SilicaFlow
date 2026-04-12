#!/usr/bin/env bash
# SilicaFlow — DRC: KLayout backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "drc" "klayout"

PNR_GDS="${PNR_GDS:-$WORK_DIR/pnr/${TOP}.gds}"
RUNSET="${KLAYOUT_DRC_RUNSET:-$ROOT_DIR/flow/backend/signoff/drc/klayout/min_rules.drc}"

agent_hash_inputs "$PNR_GDS"

if [[ ! -f "$PNR_GDS" ]]; then
  echo "ERROR: Expected GDS at $PNR_GDS" >&2
  echo "Run 'make pnr' first to generate the GDS." >&2
  agent_finish 2 false "GDS not found: $PNR_GDS"
  exit 2
fi

rc=0
klayout \
  -b \
  -r "$RUNSET" \
  -rd "input=$PNR_GDS" \
  -rd "report=$_AGENT_REPORT_DIR/klayout.lyrdb" \
  2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" drc klayout "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=drc │ tool=klayout │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
