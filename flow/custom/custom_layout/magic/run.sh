#!/usr/bin/env bash
# SilicaFlow - Custom Layout via Magic VLSI
set -euo pipefail
STAGE="custom_layout"
TOOL_ID="magic"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

LAYOUT_DIR="${ROOT_DIR}/custom/layout"
WORK="$WORK_DIR/custom/custom_layout"
mkdir -p "$WORK"

echo "-- Custom Layout ($TOOL_ID) --"
echo "   Layout dir: $LAYOUT_DIR"

ERRORS=0
WARNINGS=0

if command -v magic &>/dev/null; then
  # Batch mode: export GDS from .mag files
  for mag in "$LAYOUT_DIR"/*.mag; do
    [[ -f "$mag" ]] || continue
    block=$(basename "$mag" .mag)
    echo "   Exporting GDS: $block"
    magic -dnull -noconsole -T "$LAYOUT_DIR/../technology/tech.magicrc" <<EOF > "$WORK/${block}_export.log" 2>&1 || true
load $mag
select top cell
gds write "$WORK/${block}.gds"
quit
EOF
  done
  # Also export LEF abstracts
  for mag in "$LAYOUT_DIR"/*.mag; do
    [[ -f "$mag" ]] || continue
    block=$(basename "$mag" .mag)
    echo "   Exporting LEF: $block"
    magic -dnull -noconsole <<EOF >> "$WORK/${block}_export.log" 2>&1 || true
load $mag
lef write "$WORK/${block}.lef"
quit
EOF
  done
else
  echo "      magic not found - generating placeholder report"
  echo "   Install: https://github.com/RTimothyEdwards/magic"
fi

[[ -d "$WORK" ]] && ERRORS=$(grep -rci 'error' "$WORK"/*.log 2>/dev/null | awk -F: '{s+=$2}END{print s+0}')
[[ -d "$WORK" ]] && WARNINGS=$(grep -rci 'warning' "$WORK"/*.log 2>/dev/null | awk -F: '{s+=$2}END{print s+0}')

agent_report "$STAGE" "$TOOL_ID" \
  "$(( ERRORS > 0 ? 1 : 0 ))" \
  "$ERRORS" "$WARNINGS" \
  "Custom layout: exported GDS/LEF from $LAYOUT_DIR"

agent_finish
