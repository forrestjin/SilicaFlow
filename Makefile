# ─────────────────────────────────────────────────────────────
# SilicaFlow — Top-Level Makefile
# ─────────────────────────────────────────────────────────────
# Tool-agnostic, dependency-aware, gate-enforcing.
#
# Tool selection is driven by TOOL_<STAGE> variables in
# config/project.mk. Each stage dispatches to the selected
# tool backend via flow/<phase>/<stage>/run.sh.
#
# Usage:
#   make help          — list targets
#   make env           — check toolchain
#   make status        — show DAG status + gate status
#   make lint          — run lint (selected tool)
#   make all           — run all stages in dependency order
#   make orchestrate   — AI-driven flow (pauses at gates)
#   make approve GATE=rtl_freeze  — approve a human gate
#   make reject  GATE=rtl_freeze  — reject a human gate
# ─────────────────────────────────────────────────────────────

SHELL := /usr/bin/env bash

export ROOT_DIR := $(CURDIR)

include config/project.mk

# ── Export all variables for child scripts ────────────────────
export TOP
export DESIGN_DIR
export RTL_FILELIST
export FORMAL_FILELIST
export TB_CPP
export SDC_FILE
export REPORTS_DIR
export LOGS_DIR
export WORK_DIR
export LIBERTY_FILE
export LEF_FILE
export TECH_LEF_FILE
export GDS_LAYER_MAP
export SITE_NAME
export DIE_AREA
export CORE_AREA
export TARGET_DENSITY
export SYNTH_NETLIST
export PNR_DEF
export PNR_GDS
export CLK_NAME
export CLK_PERIOD_NS
export CLK_UNCERTAINTY_NS
export PVT_CORNERS
export PROCESS_CORNER
export VERIBLE_FLAGS
export SBY_FILE
export GATES_ENABLED
export GATE_STATE_DIR

# Custom design exports
export CUSTOM_DIR
export CUSTOM_SCHEMATIC_DIR
export CUSTOM_LAYOUT_DIR
export CUSTOM_SIM_DIR
export CUSTOM_CHAR_DIR
export CUSTOM_TECH_DIR
export CUSTOM_LIBERTY_FILES
export CUSTOM_LEF_FILES
export CUSTOM_GDS_FILES

# Tool selection exports
export TOOL_LINT
export TOOL_PARSE
export TOOL_SIM
export TOOL_FORMAL
export TOOL_CDC
export TOOL_SYNTH
export TOOL_STA
export TOOL_PNR
export TOOL_POWER
export TOOL_LEC
export TOOL_DRC
export TOOL_LVS
export TOOL_SCHEMATIC
export TOOL_CIRCUIT_SIM
export TOOL_CUSTOM_LAYOUT
export TOOL_CUSTOM_DRC
export TOOL_CUSTOM_LVS
export TOOL_EXTRACTION
export TOOL_CHAR

# ── Phony targets ────────────────────────────────────────────
.PHONY: help env status \
        lint parse sim formal cdc \
        synth \
        sta_pre lec pnr sta_post power \
        drc lvs \
        schematic_entry circuit_sim custom_layout custom_drc \
        layout_vs_sch extraction char \
        frontend custom backend signoff all \
        approve reject gates reset \
        orchestrate run-next stale dot \
        clean clean-reports clean-all

# ── Help ─────────────────────────────────────────────────────
help:
	@printf "%s\n" \
		"" \
		"═══════════════════════════════════════════════════════════" \
		" SilicaFlow — AI-Orchestrated Silicon Design Flow" \
		"═══════════════════════════════════════════════════════════" \
		"" \
		" Environment & Status:" \
		"   make env            check toolchain and inputs" \
		"   make status         show DAG + gate status" \
		"   make stale          list stale stages" \
		"   make dot            emit Graphviz DOT of the DAG" \
		"" \
		" Frontend stages:" \
		"   make lint           RTL lint           ($(TOOL_LINT))" \
		"   make parse          RTL parse          ($(TOOL_PARSE))" \
		"   make sim            RTL simulation     ($(TOOL_SIM))" \
		"   make formal         Formal verification($(TOOL_FORMAL))" \
		"   make cdc            CDC analysis       ($(TOOL_CDC))" \
		"   make frontend       all frontend stages" \
		"" \
		" Custom design stages:" \
		"   make schematic_entry Schematic capture ($(TOOL_SCHEMATIC))" \
		"   make circuit_sim    Circuit simulation ($(TOOL_CIRCUIT_SIM))" \
		"   make custom_layout  Custom layout      ($(TOOL_CUSTOM_LAYOUT))" \
		"   make custom_drc     Custom DRC         ($(TOOL_CUSTOM_DRC))" \
		"   make layout_vs_sch  Custom LVS         ($(TOOL_CUSTOM_LVS))" \
		"   make extraction     Parasitic extract  ($(TOOL_EXTRACTION))" \
		"   make char           Lib characterize   ($(TOOL_CHAR))" \
		"   make custom         all custom stages" \
		"" \
		" Synthesis:" \
		"   make synth          Logic synthesis    ($(TOOL_SYNTH))" \
		"" \
		" Backend stages:" \
		"   make sta_pre        Pre-layout STA     ($(TOOL_STA))" \
		"   make lec            Equivalence check  ($(TOOL_LEC))" \
		"   make pnr            Place and route    ($(TOOL_PNR))" \
		"   make sta_post       Post-layout STA    ($(TOOL_STA))" \
		"   make power          Power analysis     ($(TOOL_POWER))" \
		"   make backend        all backend stages" \
		"" \
		" Signoff stages:" \
		"   make drc            Design rule check  ($(TOOL_DRC))" \
		"   make lvs            Layout vs schem.   ($(TOOL_LVS))" \
		"   make signoff        all signoff stages" \
		"" \
		" Full flow:" \
		"   make all            run all stages (stops at gates)" \
		"   make run-next       run next runnable stage" \
		"   make orchestrate    AI-driven flow loop" \
		"" \
		" Human gates:" \
		"   make gates          show gate status" \
		"   make approve GATE=<name>   approve a gate" \
		"   make reject  GATE=<name>   reject a gate" \
		"   make reset   GATE=<name>   reset a gate" \
		"" \
		" Cleanup:" \
		"   make clean          remove work/ and logs/" \
		"   make clean-reports  remove reports/" \
		"   make clean-all      remove work/, logs/, and reports/" \
		"" \
		" Tool override example:" \
		"   make synth TOOL_SYNTH=genus" \
		"   make sta_pre TOOL_STA=primetime" \
		"   make drc TOOL_DRC=calibre_drc" \
		"═══════════════════════════════════════════════════════════"

# ── Environment ──────────────────────────────────────────────
env:
	@bash scripts/check_env.sh

# ── Status / DAG ─────────────────────────────────────────────
status:
	@python3 scripts/flow_runner.py status

stale:
	@python3 scripts/flow_runner.py stale

dot:
	@python3 scripts/flow_runner.py dot

# ── Frontend stages ──────────────────────────────────────────
lint:
	@bash flow/frontend/lint/run.sh

parse:
	@bash flow/frontend/parse/run.sh

sim: parse
	@bash flow/frontend/sim/run.sh

formal: parse
	@bash flow/frontend/formal/run.sh

cdc: parse
	@bash flow/frontend/cdc/run.sh

frontend: lint parse sim formal cdc

# -- Custom design stages ------------------------------------------
schematic_entry:
	@bash flow/custom/schematic_entry/run.sh

circuit_sim: schematic_entry
	@bash flow/custom/circuit_sim/run.sh

custom_layout: schematic_entry
	@bash flow/custom/custom_layout/run.sh

custom_drc: custom_layout
	@bash flow/custom/custom_drc/run.sh

layout_vs_sch: custom_layout schematic_entry
	@bash flow/custom/layout_vs_sch/run.sh

extraction: custom_drc layout_vs_sch
	@bash flow/custom/extraction/run.sh

char: extraction circuit_sim
	@bash flow/custom/char/run.sh

custom: schematic_entry circuit_sim custom_layout custom_drc layout_vs_sch extraction char


# ── Synthesis ────────────────────────────────────────────────
synth: lint sim formal cdc char
	@bash flow/frontend/synth/run.sh

# ── Backend stages ───────────────────────────────────────────
sta_pre: synth
	@SILICAFLOW_STAGE=sta_pre bash flow/backend/sta/run.sh

lec: synth
	@bash flow/backend/lec/run.sh

pnr: sta_pre lec
	@bash flow/backend/pnr/run.sh

sta_post: pnr
	@SILICAFLOW_STAGE=sta_post bash flow/backend/sta/run.sh

power: pnr
	@bash flow/backend/power/run.sh

backend: sta_pre lec pnr sta_post power

# ── Signoff stages ───────────────────────────────────────────
drc: pnr
	@bash flow/backend/signoff/drc/run.sh

lvs: pnr
	@bash flow/backend/signoff/lvs/run.sh

signoff: drc lvs

# ── Full flow ────────────────────────────────────────────────
all: frontend custom synth backend signoff

run-next:
	@python3 scripts/flow_runner.py run

orchestrate:
	@python3 scripts/flow_runner.py run-all

# ── Human gates ──────────────────────────────────────────────
gates:
	@bash scripts/gate.sh status

approve:
	@bash scripts/gate.sh approve $(GATE) "$(NOTES)"

reject:
	@bash scripts/gate.sh reject $(GATE) "$(REASON)"

reset:
ifdef GATE
	@bash scripts/gate.sh reset $(GATE)
else
	@python3 scripts/flow_runner.py reset
endif

# ── Cleanup ──────────────────────────────────────────────────
clean:
	@rm -rf work logs

clean-reports:
	@rm -rf reports

clean-all:
	@rm -rf work logs reports
