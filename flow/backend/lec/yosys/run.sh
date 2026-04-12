#!/usr/bin/env bash
# SilicaFlow — LEC: Yosys equivalence checking backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "lec" "yosys"
agent_hash_inputs "$RTL_FILELIST" "$SYNTH_NETLIST" "${LIBERTY_FILE:-}"

rtl_sources=$(sed '/^\s*$/d;/^\s*#/d;/^\+incdir\+/d' "$RTL_FILELIST" | tr '\n' ' ')

# Build equivalence checking script
LEC_CMDS=""
LEC_CMDS+="read_verilog -sv $rtl_sources; "
LEC_CMDS+="prep -top $TOP; "
LEC_CMDS+="splitnets -ports; "
LEC_CMDS+="design -save gold; "
LEC_CMDS+="design -reset; "

if [[ -n "${LIBERTY_FILE:-}" && -f "${LIBERTY_FILE:-}" ]]; then
  LEC_CMDS+="read_liberty -lib $LIBERTY_FILE; "
fi
LEC_CMDS+="read_verilog $SYNTH_NETLIST; "
LEC_CMDS+="prep -top $TOP; "
LEC_CMDS+="splitnets -ports; "
LEC_CMDS+="design -save gate; "
LEC_CMDS+="design -copy-from gold -as gold $TOP; "
LEC_CMDS+="design -copy-from gate -as gate $TOP; "
LEC_CMDS+="equiv_make gold gate equiv; "
LEC_CMDS+="prep -top equiv; "
LEC_CMDS+="equiv_simple; "
LEC_CMDS+="equiv_induct; "
LEC_CMDS+="equiv_status -assert"

rc=0
yosys \
  -ql "$_AGENT_LOG_FILE" \
  -p "$LEC_CMDS" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" lec yosys "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=lec │ tool=yosys │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
