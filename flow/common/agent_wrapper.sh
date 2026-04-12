#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# SilicaFlow — Universal Tool Agent Wrapper
# ─────────────────────────────────────────────────────────────
# Every stage run.sh sources this file to get:
#   - Standardized directory setup
#   - Input hash computation (for staleness detection)
#   - Timing measurement
#   - Structured JSON report generation
#   - Uniform exit-code semantics
#
# Exit codes:
#   0 = pass (tool ran, no errors)
#   1 = fail (tool ran, reported violations/errors)
#   2 = error (tool could not run — missing input, crash, etc.)
#
# Usage in a stage run.sh:
#   source "$ROOT_DIR/flow/common/agent_wrapper.sh"
#   agent_init <stage_name>
#   # ... run the tool, capture exit code ...
#   agent_finish <exit_code>
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── Globals set by agent_init ────────────────────────────────
_AGENT_STAGE=""
_AGENT_TOOL=""
_AGENT_START_TIME=""
_AGENT_REPORT_DIR=""
_AGENT_WORK_DIR=""
_AGENT_LOG_FILE=""
_AGENT_REPORT_FILE=""
_AGENT_INPUT_HASHES=""

# ── Helpers ──────────────────────────────────────────────────

_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_sha256() {
  # Portable SHA-256: works on macOS (shasum) and Linux (sha256sum)
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "no-hash-tool"
  fi
}

_tool_version() {
  local binary="$1"
  # Try common version flags; fall back to "unknown"
  local ver=""
  ver=$("$binary" --version 2>/dev/null | head -1) \
    || ver=$("$binary" -version 2>/dev/null | head -1) \
    || ver=$("$binary" -V 2>/dev/null | head -1) \
    || ver="unknown"
  echo "$ver"
}

# ── JSON helpers (pure bash, no jq dependency) ───────────────

_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "$s"
}

# ── Core API ─────────────────────────────────────────────────

agent_init() {
  # Usage: agent_init <stage_name>
  _AGENT_STAGE="${1:?agent_init requires a stage name}"
  _AGENT_TOOL="${2:-unknown}"
  _AGENT_START_TIME=$(date +%s)

  _AGENT_REPORT_DIR="${REPORTS_DIR:?}/${_AGENT_STAGE}"
  _AGENT_WORK_DIR="${WORK_DIR:?}/${_AGENT_STAGE}"
  _AGENT_LOG_FILE="${_AGENT_REPORT_DIR}/${_AGENT_TOOL}.log"
  _AGENT_REPORT_FILE="${_AGENT_REPORT_DIR}/report.json"

  mkdir -p "$_AGENT_REPORT_DIR" "$_AGENT_WORK_DIR"

  echo "──────────────────────────────────────────────────"
  echo "SilicaFlow │ stage=$_AGENT_STAGE │ tool=$_AGENT_TOOL"
  echo "──────────────────────────────────────────────────"
}

agent_hash_inputs() {
  # Usage: agent_hash_inputs file1 file2 ...
  # Computes SHA-256 of each input file and stores for the report.
  local hashes="{"
  local first=true
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      local h
      h=$(_sha256 "$f")
      if $first; then first=false; else hashes+=","; fi
      hashes+="\"$(_json_escape "$f")\": \"$h\""
    fi
  done
  hashes+="}"
  _AGENT_INPUT_HASHES="$hashes"
}

agent_finish() {
  # Usage: agent_finish <exit_code> <pass:true|false> <summary> [metrics_json] [violations_json] [artifacts_json]
  local exit_code="${1:?}"
  local pass="${2:?}"
  local summary="${3:?}"
  local metrics="${4:-{}}"
  local violations="${5:-[]}"
  local artifacts="${6:-[]}"

  local end_time
  end_time=$(date +%s)
  local duration=$(( end_time - _AGENT_START_TIME ))

  local tool_ver=""
  if command -v "$_AGENT_TOOL" >/dev/null 2>&1; then
    tool_ver=$(_tool_version "$_AGENT_TOOL")
  fi

  # Write structured JSON report
  cat > "$_AGENT_REPORT_FILE" <<REPORT_EOF
{
  "schema_version": "1.0.0",
  "stage": "$(_json_escape "$_AGENT_STAGE")",
  "tool": "$(_json_escape "$_AGENT_TOOL")",
  "tool_version": "$(_json_escape "$tool_ver")",
  "timestamp": "$(_timestamp)",
  "duration_seconds": $duration,
  "exit_code": $exit_code,
  "pass": $pass,
  "summary": "$(_json_escape "$summary")",
  "metrics": $metrics,
  "violations": $violations,
  "artifacts": $artifacts,
  "input_hashes": ${_AGENT_INPUT_HASHES:-{}},
  "raw_log": "$(_json_escape "$_AGENT_LOG_FILE")"
}
REPORT_EOF

  echo "──────────────────────────────────────────────────"
  echo "SilicaFlow │ stage=$_AGENT_STAGE │ pass=$pass │ ${duration}s"
  echo "Report: $_AGENT_REPORT_FILE"
  echo "──────────────────────────────────────────────────"

  return "$exit_code"
}

# ── Convenience: run tool and capture exit code ──────────────

agent_run_tool() {
  # Usage: agent_run_tool <command> [args...]
  # Runs the command, tees to the log file, captures exit code.
  # Does NOT call agent_finish — caller must do that.
  local rc=0
  "$@" 2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?
  return $rc
}
