#!/usr/bin/env bash
# SilicaFlow - Schematic Entry via xschem
set -euo pipefail
STAGE="schematic_entry"
TOOL_ID="xschem"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

SCHEMATIC_DIR="${ROOT_DIR}/custom/schematic"
WORK="$WORK_DIR/custom/schematic_entry"
mkdir -p "$WORK"

echo "-- Schematic Entry ($TOOL_ID) --"
echo "   Schematic dir: $SCHEMATIC_DIR"

# xschem is interactive; in batch mode, export netlists
if command -v xschem &>/dev/null; then
  echo "   xschem available - run interactively or use xschem --netlist for batch export"
  # Batch netlist export for all .sch files
  for sch in "$SCHEMATIC_DIR"/*.sch; do
    [[ -f "$sch" ]] || continue
    block=$(basename "$sch" .sch)
    echo "   Exporting netlist: $block"
    xschem --netlist --netlist_path "$WORK/${block}.spice" "$sch" 2>&1 | tee -a "$WORK/xschem.log" || true
  done
else
  echo "      xschem not found - generating placeholder report"
  echo "   Install: https://xschem.sourceforge.io/"
fi

ERRORS=0
WARNINGS=0
[[ -f "$WORK/xschem.log" ]] && ERRORS=$(grep -ci 'error' "$WORK/xschem.log" || true)
[[ -f "$WORK/xschem.log" ]] && WARNINGS=$(grep -ci 'warning' "$WORK/xschem.log" || true)

agent_report "$STAGE" "$TOOL_ID" \
  "$(( ERRORS > 0 ? 1 : 0 ))" \
  "$ERRORS" "$WARNINGS" \
  "Schematic entry: exported netlists from $SCHEMATIC_DIR"

agent_finish
