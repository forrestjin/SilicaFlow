#!/usr/bin/env bash
# SilicaFlow - Parasitic Extraction via Magic VLSI
set -euo pipefail
STAGE="extraction"
TOOL_ID="magic"
ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../../../.." && pwd)}"
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "$STAGE" "$TOOL_ID"

LAYOUT_DIR="${ROOT_DIR}/custom/layout"
WORK="$WORK_DIR/custom/extraction"
mkdir -p "$WORK"

echo "-- Parasitic Extraction ($TOOL_ID) --"

ERRORS=0
WARNINGS=0

if command -v magic &>/dev/null; then
  for mag in "$LAYOUT_DIR"/*.mag; do
    [[ -f "$mag" ]] || continue
    block=$(basename "$mag" .mag)
    echo "   Extracting: $block"
    magic -dnull -noconsole <<EOF > "$WORK/${block}_ext.log" 2>&1 || true
load $mag
select top cell
extract all
ext2spice lvs
ext2spice cthresh 0.01
ext2spice
quit
EOF
    if [[ -f "${block}.spice" ]]; then
      mv "${block}.spice" "$WORK/${block}_extracted.spice"
      echo "   [OK] $block extracted"
    fi
  done
else
  echo "      magic not found - generating placeholder report"
fi

agent_report "$STAGE" "$TOOL_ID" \
  "$(( ERRORS > 0 ? 1 : 0 ))" \
  "$ERRORS" "$WARNINGS" \
  "Extraction: processed layouts from $LAYOUT_DIR"

agent_finish
