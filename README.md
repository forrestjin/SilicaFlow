# SilicaFlow

**AI-orchestrated, EDA-tool-agnostic, human-gated silicon design flow.**

SilicaFlow is a full-lifecycle ASIC project framework spanning product definition through post-silicon test. It is designed around three tiers:

| Tier | Role | Examples |
|------|------|----------|
| **AI Orchestrator** | Sequences stages, interprets reports, proposes fixes, manages state | LLM-based controller (e.g. any AI coding agent) |
| **EDA Tool Agents** | Execute bounded tasks, produce structured reports | Any tool — open-source or commercial |
| **Human Gates** | Approve/reject at critical milestones, set policy, override | You, the engineer |

## Key Principles

- **Tool-agnostic**: every stage dispatches to a configurable tool backend. Switch tools by setting `TOOL_<STAGE>=<tool>` — no flow rewrite needed.
- **Structured output**: every tool produces JSON reports via standardized parsers, enabling AI interpretation.
- **Human-gated**: 6 milestone gates where the flow pauses for engineer approval before advancing.
- **Dependency-aware**: a declarative DAG (`flow/dag.yaml`) enforces stage ordering and detects staleness.
- **Full lifecycle**: from product requirements through post-silicon yield debug.

## Quick Start

```bash
# 1. Review and customize configuration
vi config/project.mk          # Project settings, tool selection
cat config/tools.yaml          # Available tool backends

# 2. Check your environment
make env

# 3. See the flow DAG and gate status
make status

# 4. Run individual stages
make lint                      # Uses TOOL_LINT (default: verible)
make sim                       # Uses TOOL_SIM (default: verilator)
make synth                     # Uses TOOL_SYNTH (default: yosys)

# 5. Override tools on the fly
make synth TOOL_SYNTH=genus    # Use Cadence Genus instead
make sta_pre TOOL_STA=primetime # Use Synopsys PrimeTime

# 6. Run the full flow (stops at human gates)
make all

# 7. Approve gates when ready
make gates                     # Show gate status
make approve GATE=rtl_freeze   # Approve a gate
```

## Lifecycle Layers

1. **Product specification** — requirements, compliance, acceptance criteria
2. **Architecture design** — PPA budgets, interface contracts, tradeoff studies
3. **Front-end design & verification** — RTL, lint, simulation, formal, CDC
3b. **Custom design** — DTCO/STCO, analog/custom schematic, manual layout, circuit sim, extraction, library characterization
4. **Synthesis & back-end implementation** — synthesis, STA, LEC, PnR, power
5. **Physical signoff** — DRC, LVS, timing closure
6. **Package realization** — bump map, substrate, SI/PI/thermal, OSAT handoff
7. **Post-silicon test** — DFT, ATE, bring-up, characterization, yield

## Flow Stages (DAG)

```
                    ┌─── DIGITAL FRONTEND ───┐
                    │                        │
lint ──┐            │ schematic_entry ──┐    │
parse ─┤── sim ──┐  │   ├── circuit_sim │    │
       ├── formal┤  │   └── custom_layout   │
       └── cdc ──┤  │        ├── custom_drc │
                 │  │        └── layout_vs_sch
                 │  │             └── extraction
                 │  │                  └── char ─┐
                 │  │    CUSTOM DESIGN ──────────┘
                 │  │                             │
                 └──┴── synth ── sta_pre ──┐      │
                              lec ─────────┤
                                           └── pnr ── sta_post
                                                ├──── power
                                                ├──── drc
                                                └──── lvs
```

**Human Gates** (🔒 = flow pauses for approval):
- 🔒 **G1: Spec Freeze** — before frontend and custom stages
- 🔒 **G2: RTL Freeze** — before synthesis
- 🔒 **G2b: Custom Freeze** — before custom blocks integrate into synthesis
- 🔒 **G3: Synth Handoff** — before PnR
- 🔒 **G4: Tapeout** — before GDS submission
- 🔒 **G5: Package Release** — before OSAT handoff
- 🔒 **G6: Test Sign-off** — before production release

## Repository Layout

```
SilicaFlow/
├── agents/roles/        9 agent role definitions with handoff protocols
├── architecture/        workloads, budgets, interfaces, tradeoffs, models
├── config/
│   ├── project.mk       project configuration (all ?= overridable)
│   └── tools.yaml       tool registry (open-source + commercial)
├── design/
│   ├── rtl/             synthesizable RTL
│   ├── tb/              simulation testbenches
│   ├── formal/          formal properties and assertions
│   ├── constraints/     SDC timing constraints
│   ├── filelists/       source manifests
│   └── upf/             power intent
├── custom/
│   ├── technology/      DTCO/STCO configs, process options, device models
│   ├── schematic/       custom block schematics (CDL, SPICE, Verilog)
│   ├── layout/          custom layout (GDS, LEF, Magic .mag)
│   ├── simulation/      SPICE testbenches, PVT corner definitions
│   └── characterization/ Liberty model generation, extraction configs
├── docs/
│   ├── gates/           7 gate review checklists (G1–G6 + G2b)
│   ├── flow.md          flow methodology overview
│   ├── lifecycle-layers.md  detailed lifecycle documentation
│   └── toolchain-matrix.md  tool capabilities matrix
├── flow/
│   ├── dag.yaml         stage dependency DAG + gate definitions
│   ├── common/          shared infrastructure (agent_wrapper.sh, project.tcl)
│   ├── frontend/        lint, parse, sim, formal, cdc, synth
│   │   └── <stage>/
│   │       ├── run.sh           tool-agnostic dispatcher
│   │       └── <tool>/run.sh   tool-specific implementation
│   ├── custom/          schematic_entry, circuit_sim, custom_layout,
│   │                    custom_drc, layout_vs_sch, extraction, char
│   │   └── <stage>/<tool>/run.sh
│   ├── backend/         sta, pnr, lec, power
│   │   └── <stage>/<tool>/run.sh
│   └── commercial/      adapter slots for Synopsys, Cadence, Siemens
├── orchestrator/        AI orchestration recipe and skills
├── package/             bump map, substrate, SI/PI/thermal, OSAT handoff
├── pdks/                technology inputs (Liberty, LEF, tech files)
├── libs/                standard cell libraries
├── product/             requirements, traceability, roadmap
├── prompts/             10 reusable AI prompt templates
├── reports/             structured JSON reports (per stage)
├── schemas/             JSON schemas for reports, state, gates
├── scripts/
│   ├── flow_runner.py   DAG-aware execution engine
│   ├── parse_report.py  raw log → JSON report parsers
│   ├── check_env.sh     environment validator
│   └── gate.sh          human gate CLI
├── silicon_test/        DFT, ATPG, bring-up, characterization, yield
├── AGENTS.md            agent operating contract
└── Makefile             top-level targets (tool-agnostic, dependency-aware)
```

## Adding a New Tool Backend

To add support for a new EDA tool to any stage:

1. **Register** it in `config/tools.yaml` under the appropriate stage
2. **Create** `flow/<phase>/<stage>/<tool_id>/run.sh` following the pattern:
   - Source `flow/common/agent_wrapper.sh`
   - Call `agent_init`, `agent_hash_inputs`
   - Invoke the tool
   - Call `parse_report.py` to generate structured JSON
3. **(Optional)** Add a parser in `scripts/parse_report.py` for the tool's log format
4. **Select** it: `make <stage> TOOL_<STAGE>=<tool_id>`

## Agent Roles

| Agent | Scope | Key Stages |
|-------|-------|------------|
| Product | Requirements, acceptance criteria, traceability | — |
| Architecture | PPA budgets, interfaces, tradeoffs | — |
| Design | RTL, assertions, constraints | lint, parse |
| Verification | Testbenches, formal, CDC, coverage | sim, formal, cdc |
| CAD | Tool wrappers, flow infrastructure, report parsing | — |
| Physical | Synthesis, STA, PnR, signoff | synth, sta, lec, pnr, power, drc, lvs |
| Package | Bump map, substrate, SI/PI/thermal, OSAT | — |
| Silicon Test | DFT, ATE, bring-up, characterization, yield | — |

See `agents/roles/` for detailed role definitions with handoff protocols.

## Documentation

- [Flow Overview](docs/flow.md) — methodology and source separation
- [Lifecycle Layers](docs/lifecycle-layers.md) — detailed layer documentation
- [Toolchain Matrix](docs/toolchain-matrix.md) — tool capabilities and status
- [AI Agents In Chip Design And EDA](docs/eda-ai-agents.md) — agent-stack patterns for EDA orchestration
- [Testline Design](custom/layout/testline_design.md) — tapeout-time scribe-line and PCM monitor strategy
- [Wafer Binning](docs/silicon_test/wafer_binning.md) — theory and standard ASIC practice for wafer sort disposition
- [Gate Checklists](docs/gates/) — review checklists for each milestone gate
- [Agent Contract](AGENTS.md) — operating rules for AI agents
- [Critique & Plan](docs/CRITIQUE_AND_PLAN.md) — repository audit and improvement roadmap

## License

This project is a methodology framework. Replace the demo design in `design/rtl/` with your actual design, populate `libs/` and `pdks/` with your technology data, and customize `config/project.mk` for your project.
