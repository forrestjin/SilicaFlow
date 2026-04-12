#!/usr/bin/env bash
# SilicaFlow — Sim: Verilator backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "sim" "verilator"
agent_hash_inputs "$RTL_FILELIST" "$TB_CPP"

rc=0
verilator \
  --cc \
  --exe \
  --build \
  --sv \
  --assert \
  --Wall \
  --trace \
  --coverage \
  --top-module "$TOP" \
  --Mdir "$_AGENT_WORK_DIR" \
  -f "$RTL_FILELIST" \
  "$TB_CPP" 2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

if [[ $rc -eq 0 ]]; then
  "$_AGENT_WORK_DIR/V${TOP}" 2>&1 | tee -a "$_AGENT_LOG_FILE" || rc=$?
fi

python3 "$ROOT_DIR/scripts/parse_report.py" sim verilator "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=sim │ tool=verilator │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
