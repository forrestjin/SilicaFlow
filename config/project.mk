# ─────────────────────────────────────────────────────────────
# SilicaFlow — Project Configuration
# ─────────────────────────────────────────────────────────────
# All variables use ?= so they can be overridden from the
# command line, environment, or a project-local overlay.
# ─────────────────────────────────────────────────────────────

# ── Paths ────────────────────────────────────────────────────
ROOT_DIR       ?= $(CURDIR)
DESIGN_DIR     ?= $(ROOT_DIR)/design
RTL_FILELIST   ?= $(DESIGN_DIR)/filelists/rtl.f
FORMAL_FILELIST?= $(DESIGN_DIR)/filelists/formal.f
TB_CPP         ?= $(DESIGN_DIR)/tb/block_top_tb.cpp
SDC_FILE       ?= $(DESIGN_DIR)/constraints/$(TOP).sdc

REPORTS_DIR    ?= $(ROOT_DIR)/reports
LOGS_DIR       ?= $(ROOT_DIR)/logs
WORK_DIR       ?= $(ROOT_DIR)/work

# ── Design identity ─────────────────────────────────────────
TOP            ?= block_top

# ── Timing ───────────────────────────────────────────────────
CLK_NAME       ?= clk
CLK_PERIOD_NS  ?= 10.0
CLK_UNCERTAINTY_NS ?= 0.2

# ── Technology / PDK ─────────────────────────────────────────
LIBERTY_FILE   ?= $(ROOT_DIR)/libs/example_tt.lib
LEF_FILE       ?= $(ROOT_DIR)/pdks/example/tech/example.lef
TECH_LEF_FILE  ?= $(ROOT_DIR)/pdks/example/tech/example.tech.lef
GDS_LAYER_MAP  ?=

# ── PVT corners (space-separated list of corner config files)
# Each corner file sets CORNER_NAME, LIBERTY_FILE, etc.
PVT_CORNERS    ?= tt
PROCESS_CORNER ?= tt

# ── Physical ─────────────────────────────────────────────────
SITE_NAME      ?= core_site
DIE_AREA       ?= 0 0 200 200
CORE_AREA      ?= 10 10 190 190
TARGET_DENSITY ?= 0.70

# ── Synthesis ────────────────────────────────────────────────
SYNTH_NETLIST  ?= $(WORK_DIR)/synth/$(TOP)_netlist.v

# ── PnR ──────────────────────────────────────────────────────
PNR_DEF        ?= $(WORK_DIR)/pnr/$(TOP).def
PNR_GDS        ?= $(WORK_DIR)/pnr/$(TOP).gds

# ── Custom design ─────────────────────────────────────────────
CUSTOM_DIR     ?= $(ROOT_DIR)/custom
CUSTOM_SCHEMATIC_DIR ?= $(CUSTOM_DIR)/schematic
CUSTOM_LAYOUT_DIR    ?= $(CUSTOM_DIR)/layout
CUSTOM_SIM_DIR       ?= $(CUSTOM_DIR)/simulation
CUSTOM_CHAR_DIR      ?= $(CUSTOM_DIR)/characterization
CUSTOM_TECH_DIR      ?= $(CUSTOM_DIR)/technology

# Custom block Liberty models (space-separated, merged into synthesis)
CUSTOM_LIBERTY_FILES ?=
# Custom block LEF abstracts (space-separated, merged into PnR)
CUSTOM_LEF_FILES     ?=
# Custom block GDS (space-separated, merged into final GDS)
CUSTOM_GDS_FILES     ?=

# ── Tool selection (overrides which backend is used per stage)
# Valid values are tool directory names under flow/<phase>/<stage>/
# e.g. TOOL_LINT=verible, TOOL_SIM=verilator, TOOL_SYNTH=yosys
# See config/tools.yaml for the full registry.
TOOL_LINT      ?= verible
TOOL_PARSE     ?= surelog
TOOL_SIM       ?= verilator
TOOL_FORMAL    ?= symbiyosys
TOOL_CDC       ?= yosys
TOOL_SYNTH     ?= yosys
TOOL_STA       ?= opensta
TOOL_PNR       ?= openroad
TOOL_DRC       ?= klayout
TOOL_LVS       ?= klayout
TOOL_LEC       ?= yosys
TOOL_POWER     ?= openroad
TOOL_SCHEMATIC ?= xschem
TOOL_CIRCUIT_SIM ?= ngspice
TOOL_CUSTOM_LAYOUT ?= magic
TOOL_CUSTOM_DRC ?= magic
TOOL_CUSTOM_LVS ?= netgen
TOOL_EXTRACTION ?= magic
TOOL_CHAR      ?= ngspice

# ── Stage-specific config files ──────────────────────────────
VERIBLE_FLAGS  ?= $(ROOT_DIR)/flow/frontend/lint/flags/verible.flags
SBY_FILE       ?= $(ROOT_DIR)/flow/frontend/formal/$(TOP).sby

# ── Human gate control ───────────────────────────────────────
# Set to "true" to enable mandatory human approval at gates
GATES_ENABLED  ?= true
GATE_STATE_DIR ?= $(WORK_DIR)/gates
