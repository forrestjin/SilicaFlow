#!/usr/bin/env bash
# SilicaFlow — Parse: Surelog backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "parse" "surelog"
agent_hash_inputs "$RTL_FILELIST"

mkdir -p "$_AGENT_WORK_DIR"

rc=0
surelog \
  -f "$RTL_FILELIST" \
  -parse \
  -elabuhdm \
  -top "$TOP" \
  -odir "$_AGENT_WORK_DIR" \
  -l "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" parse surelog "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=parse │ tool=surelog │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
