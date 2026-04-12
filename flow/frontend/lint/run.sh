#!/usr/bin/env bash
# SilicaFlow — Lint stage dispatcher (tool-agnostic)
set -euo pipefail
STAGE="lint"
TOOL="${TOOL_LINT:-verible}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOL_SCRIPT="$SCRIPT_DIR/$TOOL/run.sh"

if [[ ! -f "$TOOL_SCRIPT" ]]; then
  echo "ERROR: No lint backend for tool '$TOOL' at $TOOL_SCRIPT" >&2
  echo "Available backends:" >&2
  ls -d "$SCRIPT_DIR"/*/run.sh 2>/dev/null | sed 's|.*/\([^/]*\)/run.sh|  \1|' >&2
  exit 2
fi

export SILICAFLOW_STAGE="$STAGE"
export SILICAFLOW_TOOL="$TOOL"
exec bash "$TOOL_SCRIPT"
