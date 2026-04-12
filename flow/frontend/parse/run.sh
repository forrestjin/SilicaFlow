#!/usr/bin/env bash
# SilicaFlow — Parse stage dispatcher (tool-agnostic)
set -euo pipefail
STAGE="parse"
TOOL="${TOOL_PARSE:-surelog}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SCRIPT="$SCRIPT_DIR/$TOOL/run.sh"

if [[ ! -f "$TOOL_SCRIPT" ]]; then
  echo "ERROR: No parse backend for tool '$TOOL' at $TOOL_SCRIPT" >&2
  exit 2
fi

export SILICAFLOW_STAGE="$STAGE"
export SILICAFLOW_TOOL="$TOOL"
exec bash "$TOOL_SCRIPT"
