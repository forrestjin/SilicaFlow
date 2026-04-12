#!/usr/bin/env bash
# SilicaFlow — Lint: Verible backend
set -euo pipefail
source "$ROOT_DIR/flow/common/agent_wrapper.sh"

agent_init "lint" "verible"

mapfile -t rtl_files < <(sed '/^\s*$/d;/^\s*#/d;/^\+incdir\+/d' "$RTL_FILELIST")
agent_hash_inputs "$RTL_FILELIST" "${VERIBLE_FLAGS:-}"

rc=0
verible-verilog-lint \
  ${VERIBLE_FLAGS:+--flagfile="$VERIBLE_FLAGS"} \
  "${rtl_files[@]}" \
  2>&1 | tee "$_AGENT_LOG_FILE" || rc=$?

# Parse report
python3 "$ROOT_DIR/scripts/parse_report.py" lint verible "$_AGENT_LOG_FILE" "$_AGENT_REPORT_FILE" || true

if [[ -f "$_AGENT_REPORT_FILE" ]]; then
  pass=$(python3 -c "import json; print(json.load(open('$_AGENT_REPORT_FILE'))['pass'])" 2>/dev/null || echo "false")
  summary=$(python3 -c "import json; print(json.load(open('$_AGENT_REPORT_FILE'))['summary'])" 2>/dev/null || echo "exit_code=$rc")
else
  pass=$( [[ $rc -eq 0 ]] && echo "true" || echo "false" )
  summary="exit_code=$rc"
fi

# agent_finish is already handled by parse_report writing the JSON
echo "──────────────────────────────────────────────────"
echo "SilicaFlow │ stage=lint │ tool=verible │ pass=$pass"
echo "Report: $_AGENT_REPORT_FILE"
echo "──────────────────────────────────────────────────"
exit $rc
