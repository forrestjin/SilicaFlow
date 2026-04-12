#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# SilicaFlow — Environment Checker
# ─────────────────────────────────────────────────────────────
# Validates that the selected tools are available and required
# input files exist. Tool selection is driven by TOOL_<STAGE>
# variables from config/project.mk.
#
# Usage: make env
# ─────────────────────────────────────────────────────────────
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# ── Color helpers ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { printf "${GREEN}  ✅ %-30s %s${NC}\n" "$1" "$2"; }
warn() { printf "${YELLOW}  ⚠️  %-30s %s${NC}\n" "$1" "$2"; }
fail() { printf "${RED}  ❌ %-30s %s${NC}\n" "$1" "$2"; }

missing=0

echo "═══════════════════════════════════════════════════════"
echo " SilicaFlow — Environment Check"
echo "═══════════════════════════════════════════════════════"

# ── Tool-to-binary mapping ───────────────────────────────────
# Maps TOOL_<STAGE> values to the binary name to check.
# This avoids a hard YAML dependency — the mapping mirrors tools.yaml.
declare -A TOOL_BINARY_MAP=(
  # Lint
  [verible]="verible-verilog-lint"
  [spyglass_lint]="sg_shell"
  [hal]="hal"
  [ascent_lint]="ascentlint"
  # Parse
  [surelog]="surelog"
  [xcelium_parse]="xrun"
  [vcs_parse]="vcs"
  # Sim
  [verilator]="verilator"
  [xcelium]="xrun"
  [vcs]="vcs"
  [questa]="vsim"
  [iverilog]="iverilog"
  # Formal
  [symbiyosys]="sby"
  [jasper]="jg"
  [vc_formal]="vcf"
  [questa_formal]="qformal"
  # CDC
  [spyglass_cdc]="sg_shell"
  [questa_cdc]="qcdc"
  [conformal_cdc]="lec"
  # Synth
  [yosys]="yosys"
  [genus]="genus"
  [dc_shell]="dc_shell"
  # STA
  [opensta]="sta"
  [primetime]="pt_shell"
  [tempus]="tempus"
  # PnR
  [openroad]="openroad"
  [innovus]="innovus"
  [icc2]="icc2_shell"
  # Power
  [voltus]="voltus"
  [redhawk]="redhawk"
  # LEC
  [conformal]="lec"
  [formality]="fm_shell"
  # DRC
  [klayout]="klayout"
  [calibre_drc]="calibre"
  [pegasus_drc]="pegasus"
  [icv_drc]="icv"
  # LVS
  [calibre_lvs]="calibre"
  [pegasus_lvs]="pegasus"
  [icv_lvs]="icv"
)

# ── Check selected tools ────────────────────────────────────
echo ""
printf "${CYAN} Selected Tools:${NC}\n"
echo " ─────────────────────────────────────────────────────"

STAGES=(LINT PARSE SIM FORMAL CDC SYNTH STA PNR POWER LEC DRC LVS)
for stage in "${STAGES[@]}"; do
  var="TOOL_${stage}"
  tool="${!var:-not_set}"
  binary="${TOOL_BINARY_MAP[$tool]:-$tool}"

  if [[ "$tool" == "not_set" ]]; then
    warn "$stage" "not configured (TOOL_${stage} not set)"
    continue
  fi

  if command -v "$binary" >/dev/null 2>&1; then
    ver=$("$binary" --version 2>/dev/null | head -1) \
      || ver=$("$binary" -version 2>/dev/null | head -1) \
      || ver=$("$binary" -V 2>/dev/null | head -1) \
      || ver="(version unknown)"
    ok "$stage ($tool)" "$ver"
  else
    fail "$stage ($tool)" "binary '$binary' not found in PATH"
    missing=1
  fi
done

# ── Check Python (needed for flow_runner.py) ─────────────────
echo ""
printf "${CYAN} Infrastructure:${NC}\n"
echo " ─────────────────────────────────────────────────────"

if command -v python3 >/dev/null 2>&1; then
  pyver=$(python3 --version 2>&1)
  ok "python3" "$pyver"
  # Check for PyYAML
  if python3 -c "import yaml" 2>/dev/null; then
    ok "PyYAML" "available"
  else
    warn "PyYAML" "not installed — flow_runner.py will use fallback parser"
  fi
else
  fail "python3" "required for flow_runner.py"
  missing=1
fi

# ── Check required input files ───────────────────────────────
echo ""
printf "${CYAN} Input Files:${NC}\n"
echo " ─────────────────────────────────────────────────────"

required_inputs=(
  "${RTL_FILELIST:-}"
  "${FORMAL_FILELIST:-}"
  "${SDC_FILE:-}"
)

for path in "${required_inputs[@]}"; do
  if [[ -z "$path" ]]; then
    continue
  fi
  if [[ -f "$path" ]]; then
    ok "$(basename "$path")" "$path"
  else
    fail "$(basename "$path")" "$path — MISSING"
    missing=1
  fi
done

# ── Check technology files (warn only) ───────────────────────
echo ""
printf "${CYAN} Technology Files (needed for backend):${NC}\n"
echo " ─────────────────────────────────────────────────────"

tech_files=(
  "${LIBERTY_FILE:-}"
  "${LEF_FILE:-}"
  "${TECH_LEF_FILE:-}"
)

for path in "${tech_files[@]}"; do
  if [[ -z "$path" ]]; then
    continue
  fi
  if [[ -f "$path" ]]; then
    ok "$(basename "$path")" "$path"
  else
    warn "$(basename "$path")" "$path — not found (needed for synth/sta/pnr)"
  fi
done

# ── Check flow infrastructure ────────────────────────────────
echo ""
printf "${CYAN} Flow Infrastructure:${NC}\n"
echo " ─────────────────────────────────────────────────────"

for f in flow/dag.yaml config/tools.yaml schemas/tool_report.schema.json; do
  if [[ -f "$ROOT_DIR/$f" ]]; then
    ok "$f" "present"
  else
    fail "$f" "MISSING"
    missing=1
  fi
done

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
if [[ "$missing" -ne 0 ]]; then
  printf "${RED} ❌ Environment check FAILED — see errors above${NC}\n"
  echo "═══════════════════════════════════════════════════════"
  exit 2
else
  printf "${GREEN} ✅ Environment looks good for the selected tool configuration${NC}\n"
  echo "═══════════════════════════════════════════════════════"
  exit 0
fi
