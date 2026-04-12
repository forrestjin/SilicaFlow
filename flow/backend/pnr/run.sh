#!/usr/bin/env bash
# SilicaFlow — PnR stage dispatcher (tool-agnostic)
set -euo pipefail
STAGE="pnr"
TOOL="${TOOL_PNR:-openroad}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SCRIPT="$SCRIPT_DIR/$TOOL/run.sh"

if [[ ! -f "$TOOL_SCRIPT" ]]; then
  echo "ERROR: No PnR backend for tool '$TOOL' at $TOOL_SCRIPT" >&2
  exit 2
fi

export SILICAFLOW_STAGE="$STAGE"
export SILICAFLOW_TOOL="$TOOL"
exec bash "$TOOL_SCRIPT"
