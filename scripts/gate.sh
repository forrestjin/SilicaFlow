#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# SilicaFlow — Human Gate CLI
# ─────────────────────────────────────────────────────────────
# Approve or reject milestone gates. Gate state is persisted in
# $WORK_DIR/gates/ as JSON records.
#
# Usage:
#   gate.sh status                    — show all gate statuses
#   gate.sh approve <gate> [notes]    — approve a gate
#   gate.sh reject  <gate> [reason]   — reject a gate
#   gate.sh reset   <gate>            — reset gate to pending
#   gate.sh check   <gate>            — exit 0 if approved, 1 if not
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
# project.mk is a Makefile include, not a bash source — skip it.
# All needed vars come from the environment (exported by Make).

GATE_STATE_DIR="${GATE_STATE_DIR:-${WORK_DIR:-$ROOT_DIR/work}/gates}"
GATES_ENABLED="${GATES_ENABLED:-true}"
USER_NAME="${USER:-$(whoami)}"

mkdir -p "$GATE_STATE_DIR"

# Valid gate names (must match dag.yaml)
VALID_GATES=(
  spec_freeze
  rtl_freeze
  custom_freeze
  synth_handoff
  tapeout
  package_release
  test_signoff
)

_timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

_gate_file() { echo "$GATE_STATE_DIR/${1}.json"; }

_validate_gate() {
  local gate="$1"
  for g in "${VALID_GATES[@]}"; do
    [[ "$g" == "$gate" ]] && return 0
  done
  echo "ERROR: Unknown gate '$gate'. Valid gates: ${VALID_GATES[*]}" >&2
  exit 2
}

_get_status() {
  local f
  f=$(_gate_file "$1")
  if [[ -f "$f" ]]; then
    # Extract status field (no jq dependency)
    grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
  else
    echo "pending"
  fi
}

_color() {
  case "$1" in
    approved) echo -e "\033[32m$1\033[0m" ;;  # green
    rejected) echo -e "\033[31m$1\033[0m" ;;  # red
    pending)  echo -e "\033[33m$1\033[0m" ;;  # yellow
    *)        echo "$1" ;;
  esac
}

cmd_status() {
  echo "═══════════════════════════════════════════════════"
  echo " SilicaFlow — Human Milestone Gates"
  echo "═══════════════════════════════════════════════════"
  printf " %-20s %s\n" "GATE" "STATUS"
  echo "───────────────────────────────────────────────────"
  for g in "${VALID_GATES[@]}"; do
    local s
    s=$(_get_status "$g")
    printf " %-20s %s\n" "$g" "$(_color "$s")"
  done
  echo "═══════════════════════════════════════════════════"
}

cmd_approve() {
  local gate="${1:?Usage: gate.sh approve <gate> [notes]}"
  _validate_gate "$gate"
  local notes="${2:-}"
  local f
  f=$(_gate_file "$gate")

  cat > "$f" <<EOF
{
  "gate": "$gate",
  "action": "approve",
  "status": "approved",
  "by": "$USER_NAME",
  "timestamp": "$(_timestamp)",
  "notes": "$notes"
}
EOF
  echo "✅ Gate '$gate' APPROVED by $USER_NAME at $(_timestamp)"
  [[ -n "$notes" ]] && echo "   Notes: $notes"
}

cmd_reject() {
  local gate="${1:?Usage: gate.sh reject <gate> [reason]}"
  _validate_gate "$gate"
  local reason="${2:-}"
  local f
  f=$(_gate_file "$gate")

  cat > "$f" <<EOF
{
  "gate": "$gate",
  "action": "reject",
  "status": "rejected",
  "by": "$USER_NAME",
  "timestamp": "$(_timestamp)",
  "notes": "$reason"
}
EOF
  echo "❌ Gate '$gate' REJECTED by $USER_NAME at $(_timestamp)"
  [[ -n "$reason" ]] && echo "   Reason: $reason"
}

cmd_reset() {
  local gate="${1:?Usage: gate.sh reset <gate>}"
  _validate_gate "$gate"
  local f
  f=$(_gate_file "$gate")
  rm -f "$f"
  echo "🔄 Gate '$gate' reset to PENDING"
}

cmd_check() {
  local gate="${1:?Usage: gate.sh check <gate>}"
  _validate_gate "$gate"

  if [[ "$GATES_ENABLED" != "true" ]]; then
    echo "⚠️  Gates disabled (GATES_ENABLED=$GATES_ENABLED) — treating '$gate' as approved"
    exit 0
  fi

  local s
  s=$(_get_status "$gate")
  if [[ "$s" == "approved" ]]; then
    echo "✅ Gate '$gate' is approved"
    exit 0
  else
    echo "🔒 Gate '$gate' is $s — cannot proceed"
    echo "   Run: make approve GATE=$gate"
    exit 1
  fi
}

# ── Main dispatch ────────────────────────────────────────────
case "${1:-status}" in
  status)  cmd_status ;;
  approve) cmd_approve "${2:-}" "${*:3}" ;;
  reject)  cmd_reject  "${2:-}" "${*:3}" ;;
  reset)   cmd_reset   "${2:-}" ;;
  check)   cmd_check   "${2:-}" ;;
  *)
    echo "Usage: gate.sh {status|approve|reject|reset|check} [gate] [notes]" >&2
    exit 2
    ;;
esac
