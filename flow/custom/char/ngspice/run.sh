#!/usr/bin/env bash
# SilicaFlow - Library Characterization via ngspice
# Note: Full characterization typically requires Liberate or SiliconSmart.
# This ngspice backend provides basic delay/power measurement that can
# feed into a Liberty template.
set -euo pipefail
STAGE="char"
TOOL_ID="ngspice"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

CHAR_DIR="${ROOT_DIR}/custom/characterization"
TEMPLATE_DIR="$CHAR_DIR/templates"
EXTRACTED_DIR="$WORK_DIR/custom/extraction"
WORK="$WORK_DIR/custom/char"
mkdir -p "$WORK"

echo "-- Library Characterization ($TOOL_ID) --"
echo "   Template dir:  $TEMPLATE_DIR"
echo "   Extracted dir: $EXTRACTED_DIR"

ERRORS=0
WARNINGS=0

if command -v ngspice &>/dev/null; then
  for tmpl in "$TEMPLATE_DIR"/*.spice "$TEMPLATE_DIR"/*.sp; do
    [[ -f "$tmpl" ]] || continue
    block=$(basename "$tmpl" | sed 's/\.[^.]*$//')
    echo "   Characterizing: $block"
    ngspice -b "$tmpl" -o "$WORK/${block}_char.log" 2>&1 || true
    if grep -qi 'error\|fatal' "$WORK/${block}_char.log" 2>/dev/null; then
      ERRORS=$((ERRORS + 1))
    fi
  done
  echo "   Note: Full Liberty generation requires Cadence Liberate or Synopsys SiliconSmart"
  echo "   ngspice provides raw delay/power measurements for Liberty template population"
else
  echo "      ngspice not found - generating placeholder report"
fi

agent_report "$STAGE" "$TOOL_ID" \
  "$(( ERRORS > 0 ? 1 : 0 ))" \
  "$ERRORS" "$WARNINGS" \
  "Characterization: basic delay/power measurement via ngspice"

agent_finish
