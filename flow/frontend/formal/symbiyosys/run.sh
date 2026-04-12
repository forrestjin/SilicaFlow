#!/usr/bin/env bash
# SilicaFlow — Formal: SymbiYosys backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "formal" "symbiyosys"
agent_hash_inputs "$FORMAL_FILELIST" "$SBY_FILE"

rc=0
sby \
  --prefix "$_AGENT_WORK_DIR/$TOP" \
  -f "$SBY_FILE" \
  2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" formal symbiyosys "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=formal │ tool=symbiyosys │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
