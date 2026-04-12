#!/usr/bin/env bash
# SilicaFlow — Synth stage dispatcher (tool-agnostic)
set -euo pipefail
STAGE="synth"
TOOL="${TOOL_SYNTH:-yosys}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SCRIPT="$SCRIPT_DIR/$TOOL/run.sh"

if [[ ! -f "$TOOL_SCRIPT" ]]; then
  echo "ERROR: No synth backend for tool '$TOOL' at $TOOL_SCRIPT" >&2
  exit 2
fi

export SILICAFLOW_STAGE="$STAGE"
export SILICAFLOW_TOOL="$TOOL"
exec bash "$TOOL_SCRIPT"
