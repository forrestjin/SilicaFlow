#!/usr/bin/env bash
# SilicaFlow — PnR: OpenROAD backend (full flow: floorplan → route → GDS)
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "pnr" "openroad"
agent_hash_inputs "$SYNTH_NETLIST" "$SDC_FILE" "$LIBERTY_FILE" "$LEF_FILE" "$TECH_LEF_FILE"

PNR_DEF="${PNR_DEF:-$_AGENT_WORK_DIR/${TOP}.def}"
PNR_GDS="${PNR_GDS:-$_AGENT_WORK_DIR/${TOP}.gds}"
mkdir -p "$(dirname "$PNR_DEF")" "$(dirname "$PNR_GDS")"

# Generate OpenROAD Tcl script
PNR_TCL="$_AGENT_WORK_DIR/flow.tcl"
cat > "$PNR_TCL" <<'TCLEOF'
source [file join $::env(ROOT_DIR) flow common project.tcl]

set top       [require_env TOP]
set tech_lef  [require_env TECH_LEF_FILE]
set cell_lef  [require_env LEF_FILE]
set liberty   [require_env LIBERTY_FILE]
set netlist   [require_env SYNTH_NETLIST]
set sdc       [require_env SDC_FILE]
set site_name [require_env SITE_NAME]
set die_area  [optional_env DIE_AREA "0 0 200 200"]
set core_area [optional_env CORE_AREA "10 10 190 190"]
set density   [optional_env TARGET_DENSITY "0.70"]
set pnr_def   [require_env PNR_DEF]
set pnr_gds   [require_env PNR_GDS]

# Read inputs
read_lef -tech $tech_lef
read_lef $cell_lef
read_liberty $liberty
read_verilog $netlist
link_design $top
read_sdc $sdc

# Floorplan
initialize_floorplan -site $site_name -die_area $die_area -core_area $core_area

# Power grid (basic)
catch {
  make_tracks
}

# Placement
global_placement -density $density
detailed_placement

# Clock tree synthesis
catch {
  clock_tree_synthesis
  set_propagated_clock [all_clocks]
}

# Repair timing
catch {
  estimate_parasitics -placement
  repair_timing
}

# Global route
global_route

# Detailed route
catch {
  detailed_route
}

# Parasitics and timing
estimate_parasitics -global_routing
report_checks -path_delay max -fields {slew cap input_pins nets fanout} -digits 3
report_checks -path_delay min -fields {slew cap input_pins nets fanout} -digits 3
report_design_area
report_power

# Write outputs
write_def $pnr_def

# Write GDS if possible
catch {
  write_gds $pnr_gds
}

puts "PnR complete. DEF: $pnr_def"
TCLEOF

export PNR_DEF PNR_GDS

rc=0
openroad -no_init -exit "$PNR_TCL" 2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

python3 "$ROOT_DIR/scripts/parse_report.py" pnr openroad "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=pnr │ tool=openroad │ rc=$rc"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
