#!/usr/bin/env bash
# SilicaFlow — CDC: Yosys backend (basic clock-domain analysis)
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "cdc" "yosys"
agent_hash_inputs "$RTL_FILELIST"

rtl_sources=$(sed '/^\s*$/d;/^\s*#/d;/^\+incdir\+/d' "$RTL_FILELIST" | tr '\n' ' ')

rc=0
yosys \
  -ql "$_AGENT_LOG_FILE" \
  -p "read_verilog -sv $rtl_sources" \
  -p "hierarchy -check -top $TOP" \
  -p "proc; opt" \
  -p "cd $TOP" \
  -p "select -list t:\$dff t:\$adff t:\$sdff" \
  -p "stat" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" cdc yosys "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=cdc │ tool=yosys │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
