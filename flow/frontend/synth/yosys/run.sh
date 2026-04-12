#!/usr/bin/env bash
# SilicaFlow — Synth: Yosys backend (with technology mapping)
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "synth" "yosys"
agent_hash_inputs "$RTL_FILELIST" "$SDC_FILE" "${LIBERTY_FILE:-}"

mkdir -p "$(dirname "$SYNTH_NETLIST")"

rtl_sources=$(sed '/^\s*$/d;/^\s*#/d;/^\+incdir\+/d' "$RTL_FILELIST" | tr '\n' ' ')

# Build Yosys script with conditional technology mapping
YOSYS_CMDS="read_verilog -sv $rtl_sources; "
YOSYS_CMDS+="hierarchy -check -top $TOP; "
YOSYS_CMDS+="proc; opt; fsm; opt; memory; opt; "

# Technology mapping if Liberty file is available
if [[ -n "${LIBERTY_FILE:-}" && -f "${LIBERTY_FILE:-}" ]]; then
  YOSYS_CMDS+="read_liberty -lib $LIBERTY_FILE; "
  YOSYS_CMDS+="synth -top $TOP; "
  YOSYS_CMDS+="dfflibmap -liberty $LIBERTY_FILE; "
  YOSYS_CMDS+="abc -liberty $LIBERTY_FILE; "
  YOSYS_CMDS+="opt_clean -purge; "
else
  YOSYS_CMDS+="synth -top $TOP; "
  echo "WARNING: No LIBERTY_FILE — producing unmapped generic netlist" >&2
fi

YOSYS_CMDS+="stat; "
YOSYS_CMDS+="write_verilog -noattr $SYNTH_NETLIST"

rc=0
yosys \
  -ql "$_AGENT_LOG_FILE" \
  -p "$YOSYS_CMDS" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" synth yosys "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=synth │ tool=yosys │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
