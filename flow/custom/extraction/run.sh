#!/usr/bin/env bash
# SilicaFlow — Parasitic Extraction dispatcher
set -euo pipefail
STAGE="extraction"
TOOL_VAR="TOOL_EXTRACTION"
DEFAULT_TOOL="magic"
TOOL="${!TOOL_VAR:-$DEFAULT_TOOL}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_DIR="$SCRIPT_DIR/$TOOL"
if [[ ! -d "$TOOL_DIR" ]]; then
  echo "ERROR: Unknown $TOOL_VAR='$TOOL'. Available:" >&2
  ls -1 "$SCRIPT_DIR" | grep -v run.sh >&2
  exit 2
fi
exec bash "$TOOL_DIR/run.sh" "$@"
