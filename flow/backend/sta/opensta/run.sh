#!/usr/bin/env bash
# SilicaFlow — STA: OpenSTA backend (setup + hold analysis)
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

STAGE="${SILICAFLOW_STAGE:-sta_pre}"
agent_init "$STAGE" "opensta"
agent_hash_inputs "$SYNTH_NETLIST" "$SDC_FILE" "$LIBERTY_FILE"

# Generate OpenSTA Tcl script
STA_TCL="$_AGENT_WORK_DIR/run_sta.tcl"
cat > "$STA_TCL" <<EOF
source [file join $::env(ROOT_DIR) flow common project.tcl]

set liberty [require_env LIBERTY_FILE]
set netlist [require_env SYNTH_NETLIST]
set sdc     [require_env SDC_FILE]
set top     [require_env TOP]

read_liberty \$liberty
read_verilog \$netlist
link_design \$top
read_sdc \$sdc

puts "=== Setup (max) analysis ==="
report_checks -path_delay max -fields {slew cap input_pins nets fanout} -digits 3
report_worst_slack -max
report_tns

puts "=== Hold (min) analysis ==="
report_checks -path_delay min -fields {slew cap input_pins nets fanout} -digits 3
report_worst_slack -min
EOF

rc=0
sta "$STA_TCL" 2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" "$STAGE" opensta "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=$STAGE │ tool=opensta │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
