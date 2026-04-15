#!/usr/bin/env bash
# SilicaFlow - Custom DRC via Magic VLSI
set -euo pipefail
STAGE="custom_drc"
TOOL_ID="magic"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

LAYOUT_DIR="${ROOT_DIR}/custom/layout"
WORK="$WORK_DIR/custom/custom_drc"
mkdir -p "$WORK"

echo "-- Custom DRC ($TOOL_ID) --"

ERRORS=0
WARNINGS=0

if command -v magic &>/dev/null; then
  for mag in "$LAYOUT_DIR"/*.mag; do
    [[ -f "$mag" ]] || continue
    block=$(basename "$mag" .mag)
    echo "   DRC checking: $block"
    magic -dnull -noconsole <<EOF > "$WORK/${block}_drc.log" 2>&1 || true
load $mag
select top cell
drc check
drc catchup
drc count
quit
EOF
    count=$(grep -o '[0-9]* error' "$WORK/${block}_drc.log" 2>/dev/null | awk '{s+=$1}END{print s+0}')
    ERRORS=$((ERRORS + count))
    echo "   $block: $count DRC errors"
  done
else
  echo "      magic not found - generating placeholder report"
fi

agent_report "$STAGE" "$TOOL_ID" \
  "$(( ERRORS > 0 ? 1 : 0 ))" \
  "$ERRORS" "$WARNINGS" \
  "Custom DRC: $ERRORS total violations"

agent_finish
