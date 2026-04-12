#!/usr/bin/env bash
# SilicaFlow — Power: OpenROAD power analysis backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "power" "openroad"
agent_hash_inputs "$SYNTH_NETLIST" "$SDC_FILE" "$LIBERTY_FILE" "${PNR_DEF:-}"

POWER_TCL="$_AGENT_WORK_DIR/power.tcl"
cat > "$POWER_TCL" <<'TCLEOF'
source [file join $::env(ROOT_DIR) flow common project.tcl]

set top      [require_env TOP]
set tech_lef [require_env TECH_LEF_FILE]
set cell_lef [require_env LEF_FILE]
set liberty  [require_env LIBERTY_FILE]
set netlist  [require_env SYNTH_NETLIST]
set sdc      [require_env SDC_FILE]

read_lef -tech $tech_lef
read_lef $cell_lef
read_liberty $liberty
read_verilog $netlist
link_design $top
read_sdc $sdc

# Read DEF if available (post-PnR power)
set pnr_def [optional_env PNR_DEF ""]
if {$pnr_def ne "" && [file exists $pnr_def]} {
  read_def $pnr_def
}

estimate_parasitics -placement
report_power
TCLEOF

rc=0
openroad -no_init -exit "$POWER_TCL" 2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" power openroad "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=power │ tool=openroad │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
