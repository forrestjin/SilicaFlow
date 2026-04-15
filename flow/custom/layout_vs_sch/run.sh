#!/usr/bin/env bash
# SilicaFlow — Custom LVS (Layout vs Schematic) dispatcher
set -euo pipefail
STAGE="layout_vs_sch"
TOOL_VAR="TOOL_CUSTOM_LVS"
DEFAULT_TOOL="netgen"
TOOL="${!TOOL_VAR:-$DEFAULT_TOOL}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_DIR="$SCRIPT_DIR/$TOOL"
if [[ ! -d "$TOOL_DIR" ]]; then
  echo "ERROR: Unknown $TOOL_VAR='$TOOL'. Available:" >&2
  ls -1 "$SCRIPT_DIR" | grep -v run.sh >&2
  exit 2
fi
exec bash "$TOOL_DIR/run.sh" "$@"
