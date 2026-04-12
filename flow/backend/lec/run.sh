#!/usr/bin/env bash
# SilicaFlow — LEC stage dispatcher (tool-agnostic)
set -euo pipefail
STAGE="lec"
TOOL="${TOOL_LEC:-yosys}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SCRIPT="$SCRIPT_DIR/$TOOL/run.sh"

if [[ ! -f "$TOOL_SCRIPT" ]]; then
  echo "ERROR: No LEC backend for tool '$TOOL' at $TOOL_SCRIPT" >&2
  exit 2
fi

export SILICAFLOW_STAGE="$STAGE"
export SILICAFLOW_TOOL="$TOOL"
exec bash "$TOOL_SCRIPT"
