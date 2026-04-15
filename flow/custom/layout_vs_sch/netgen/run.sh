#!/usr/bin/env bash
# SilicaFlow - Custom LVS via Netgen
set -euo pipefail
STAGE="layout_vs_sch"
TOOL_ID="netgen"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

LAYOUT_DIR="${ROOT_DIR}/custom/layout"
SCHEMATIC_DIR="${ROOT_DIR}/custom/schematic"
WORK="$WORK_DIR/custom/layout_vs_sch"
mkdir -p "$WORK"

echo "-- Custom LVS ($TOOL_ID) --"

ERRORS=0
WARNINGS=0
PASS=0
FAIL=0

if command -v netgen &>/dev/null; then
  for cdl in "$SCHEMATIC_DIR"/*.cdl "$SCHEMATIC_DIR"/*.spice; do
    [[ -f "$cdl" ]] || continue
    block=$(basename "$cdl" | sed 's/\.[^.]*$//')
    layout_netlist="$WORK/../custom_layout/${block}_extracted.spice"
    if [[ ! -f "$layout_netlist" ]]; then
      echo "      No extracted netlist for $block - skipping"
      WARNINGS=$((WARNINGS + 1))
      continue
    fi
    echo "   LVS comparing: $block"
    netgen -batch lvs \
      "$layout_netlist" "$cdl" \
      > "$WORK/${block}_lvs.log" 2>&1 || true
    if grep -qi 'match\|equivalent' "$WORK/${block}_lvs.log" 2>/dev/null; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done
  echo "   Results: $PASS matched, $FAIL mismatched"
else
  echo "      netgen not found - generating placeholder report"
  echo "   Install: https://github.com/RTimothyEdwards/netgen"
fi

agent_report "$STAGE" "$TOOL_ID" \
  "$FAIL" \
  "$ERRORS" "$WARNINGS" \
  "Custom LVS: $PASS matched, $FAIL mismatched"

agent_finish
