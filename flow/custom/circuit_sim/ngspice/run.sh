#!/usr/bin/env bash
# SilicaFlow - Circuit Simulation via ngspice
set -euo pipefail
STAGE="circuit_sim"
TOOL_ID="ngspice"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

TB_DIR="${ROOT_DIR}/custom/simulation/testbenches"
CORNER_DIR="${ROOT_DIR}/custom/simulation/corners"
WORK="$WORK_DIR/custom/circuit_sim"
mkdir -p "$WORK"

echo "-- Circuit Simulation ($TOOL_ID) --"
echo "   Testbench dir: $TB_DIR"
echo "   Corner dir:    $CORNER_DIR"

ERRORS=0
WARNINGS=0
PASS=0
FAIL=0

if command -v ngspice &>/dev/null; then
  for tb in "$TB_DIR"/*.spice "$TB_DIR"/*.sp; do
    [[ -f "$tb" ]] || continue
    block=$(basename "$tb" | sed 's/\.[^.]*$//')
    echo "   Simulating: $block"
    ngspice -b "$tb" -o "$WORK/${block}.log" 2>&1 || true
    if grep -qi 'error\|fatal\|abort' "$WORK/${block}.log" 2>/dev/null; then
      FAIL=$((FAIL + 1))
      ERRORS=$((ERRORS + 1))
    else
      PASS=$((PASS + 1))
    fi
  done
  echo "   Results: $PASS passed, $FAIL failed"
else
  echo "      ngspice not found - generating placeholder report"
  echo "   Install: brew install ngspice  OR  apt install ngspice"
fi

agent_report "$STAGE" "$TOOL_ID" \
  "$FAIL" \
  "$ERRORS" "$WARNINGS" \
  "Circuit sim: $PASS passed, $FAIL failed"

agent_finish
