# SilicaFlow — Comprehensive Critique & Improvement Plan

> **Date:** 2026-04-11
> **Scope:** Full repository audit with a plan to evolve SilicaFlow into an end-to-end
> AI-orchestrated silicon design flow where EDA tools act as agents and the human
> engineer gatekeeps critical milestones.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [What SilicaFlow Gets Right](#2-what-silicaflow-gets-right)
3. [Structural Critique](#3-structural-critique)
4. [Content Critique by Area](#4-content-critique-by-area)
5. [The Vision: AI Orchestrator → EDA Agents → Human Gates](#5-the-vision-ai-orchestrator--eda-agents--human-gates)
6. [Improvement Plan — Phases](#6-improvement-plan--phases)
7. [Proposed Directory Structure (v2)](#7-proposed-directory-structure-v2)
8. [Milestone Gate Definitions](#8-milestone-gate-definitions)
9. [Risks & Open Questions](#9-risks--open-questions)

---

## 1. Executive Summary

SilicaFlow is a **well-conceived ASIC project skeleton** that covers an unusually broad
lifecycle — from product requirements through post-silicon yield debug. It is structured
for AI-agent consumption with clear role boundaries, a consistent prompting pattern, and
a clean separation between source-of-truth inputs and disposable outputs.

However, it is currently a **scaffold, not a flow.** The backend pipeline is broken
(no tech mapping, no routing, no GDS export), half the agent roles have no automatable
validation, inter-agent handoffs are undefined, and the orchestration layer that would
tie everything together does not exist. Critical signoff activities (CDC, LVS, LEC,
power analysis) are unowned.

This plan proposes evolving SilicaFlow from a static skeleton into a **living,
orchestrated flow** with three tiers:

| Tier | Role | Examples |
|------|------|----------|
| **AI Orchestrator** | Sequence stages, interpret reports, propose fixes, manage state | Goose / LLM-based controller |
| **EDA Tool Agents** | Execute bounded tasks, produce structured reports | Verilator, Yosys, OpenROAD, OpenSTA, KLayout, commercial tools |
| **Human Gates** | Approve/reject at critical milestones, set policy, override | You, the engineer |

---

## 2. What SilicaFlow Gets Right

These are genuine strengths to preserve and build on:

| # | Strength | Why It Matters |
|---|----------|----------------|
| 1 | **Full lifecycle coverage** (6 layers, product → silicon test) | Rare for any ASIC template; most stop at RTL or PnR. |
| 2 | **Clean source-of-truth separation** (`design/`, `config/`, `docs/` vs. `work/`, `logs/`, `reports/`) | Enables reproducibility and safe agent writes. |
| 3 | **Agent role boundaries** (8 roles with explicit scope) | Mirrors a real ASIC org chart; prevents agent scope creep. |
| 4 | **Override-friendly config** (all `?=` in `project.mk`) | Easy to specialize without forking the Makefile. |
| 5 | **Anti-hallucination prompt guardrails** (confidence ratings, fact/hypothesis separation, evidence-linking) | Critical for a domain where wrong answers cost millions. |
| 6 | **"Smallest follow-up" philosophy** in prompts | Prevents open-ended agent sprawl; keeps actions verifiable. |
| 7 | **Open-source reference stack** with commercial adapter slots | Lowers barrier to entry while acknowledging industry reality. |
| 8 | **Consistent prompt schema** (Task → Inputs → Outputs → Validation) | Predictable for both AI agents and human reviewers. |

---

## 3. Structural Critique

### 3.1 The Backend Pipeline Is Broken

The flow cannot run end-to-end. Two critical breaks:

| Break | Location | Impact |
|-------|----------|--------|
| **Yosys synth has no technology mapping** | `flow/frontend/synth/yosys/run.sh` — no `abc -liberty` | Produces a generic gate netlist; PnR and STA cannot use it meaningfully. |
| **OpenROAD PnR has no CTS, routing, or GDS export** | `flow/backend/pnr/openroad/flow.tcl` — stops after placement | KLayout DRC expects a `.gds` that is never produced; signoff is unreachable. |

**Consequence:** `make synth → make sta → make pnr → make drc` is a sequence of
individually runnable but disconnected steps. There is no actual data flow from
synthesis through signoff.

### 3.2 No Dependency Chain in the Makefile

Every `make` target is independent. Nothing prevents running `make sta` without a
netlist, or `make drc` without a GDS. This is the most dangerous structural flaw
for an AI orchestrator — it will happily execute stages out of order.

### 3.3 Missing Signoff Activities

| Activity | Status | Risk |
|----------|--------|------|
| **CDC/RDC** | Unowned, no tool, no agent | Top-3 silicon killer |
| **LVS** | Missing entirely | Tapeout blocker |
| **LEC (Formal Equivalence)** | Missing entirely | Silent post-synth bugs |
| **Power Analysis** (IR drop, EM, dynamic) | Unowned | Late-stage surprise |
| **Hold-time STA** | Not run (`-path_delay min` absent) | Silicon failure |

### 3.4 Agent Roles Are Skeletal

Each role file is 3–6 lines. They define *what* is owned but not:
- **How** — no artifact templates, naming conventions, or directory conventions.
- **Handoffs** — no definition of what one agent delivers to the next.
- **Escalation** — no path for ambiguous situations or inter-agent conflicts.
- **Validation** — 4 of 8 agents (Product, Architecture, Package, Test) have zero
  automatable validation gates.

### 3.5 No Orchestration Layer

There is no mechanism to:
- Sequence stages with dependency awareness.
- Interpret tool reports and decide next actions.
- Track flow state (which stages have passed, which are stale).
- Route decisions to the human for approval at milestone gates.
- Retry or re-route on failure.

This is the single biggest gap relative to your vision.

### 3.6 Prompt Templates Are Islands

The 7 prompt templates are individually well-crafted but:
- They don't reference each other (no dependency graph).
- They don't specify input/output *formats* (file types, schemas).
- They have no worked examples.
- They can't be chained by an orchestrator without glue logic.

### 3.7 Minor but Real Issues

| Issue | Location |
|-------|----------|
| Broken README links (absolute paths, wrong directory segment) | `README.md` |
| `design/include/` referenced in filelist but doesn't exist | `design/filelists/rtl.f` |
| `check_env.sh` prints Liberty/LEF paths but doesn't validate existence | `scripts/check_env.sh` |
| No clock period / PVT / multi-corner config variables | `config/project.mk` |
| `clean` target doesn't remove `reports/` (stale report risk) | `Makefile` |

---

## 4. Content Critique by Area

### 4.1 Design Artifacts

| Artifact | Assessment |
|----------|------------|
| `block_top.sv` | Functional but trivial (8-bit +1 pipeline). No parameterization, no backpressure, no multi-clock. Adequate as a skeleton placeholder. |
| `block_top_tb.cpp` | Single-vector testbench. No corner cases (0xFF overflow, reset-mid-transaction, back-to-back valid). No waveform dump. No coverage. |
| `block_top.sdc` | Reasonable for a single-clock design. Missing `set_driving_cell`, `set_load`, max-transition/capacitance. |
| `block_top_properties.sv` | Checks reset behavior and ready/valid relationship. **Missing data-path assertion** (`data_o == prev(data_i) + 1`). No cover properties. No `assume` on reset release. |
| UPF | Placeholder only — acceptable for single-domain. |

**Verdict:** The design artifacts are honest placeholders. They demonstrate structure
but would need to be replaced wholesale for any real project. This is fine — the
value of SilicaFlow is the *flow*, not the design.

### 4.2 Flow Scripts

| Stage | Tool | Runnable? | Quality |
|-------|------|-----------|---------|
| Lint | Verible | ✅ Yes | Clean wrapper. No error-count parsing. |
| Parse | Surelog | ✅ Yes | Clean wrapper. No post-parse error check. |
| Sim | Verilator | ✅ Yes | Works. No `--trace`, no `--coverage`, no timeout. |
| Formal | SymbiYosys | ✅ Yes | Clean. Missing `expect pass` directive. |
| Synth | Yosys | ⚠️ Partial | Runs but produces unmapped netlist (no `abc -liberty`). |
| STA | OpenSTA | ⚠️ Partial | Runs but no hold analysis, no parasitics. |
| PnR | OpenROAD | ⚠️ Partial | Stops after placement. No CTS, routing, GDS. |
| DRC | KLayout | ❌ Broken | Expects GDS that PnR never produces. Single rule. |

**Verdict:** The frontend (lint → formal) is functional. The backend (synth → DRC)
is a broken chain of scaffolds.

### 4.3 Documentation

| Document | Quality | Gap |
|----------|---------|-----|
| `README.md` | Good intro, broken links | Links use wrong absolute paths |
| `AGENTS.md` | Strong contract | No escalation, no human-gate mechanism |
| `flow.md` | Solid overview | No dependency ordering, no incremental runs |
| `lifecycle-layers.md` | Best document in repo | Layers 3–4 thinner than 1, 2, 5, 6 |
| `toolchain-matrix.md` | Useful reference | No version requirements, no mandatory/optional distinction |
| `codex-workflows.md` | Good examples | Too short; needs worked end-to-end example |

### 4.4 Prompt Templates

| Template | Quality | Key Gap |
|----------|---------|---------|
| `product_spec_review.md` | ⭐ Best in set | No requirement ID schema |
| `spec_to_rtl.md` | ⭐ Most operational | No coding style reference |
| `report_diff.md` | Strong | Missing explicit validation rule |
| `timing_triage.md` | Strong | No multi-corner/multi-mode guidance |
| `architecture_tradeoff.md` | Good | No option matrix format spec |
| `package_planning.md` | Good | No mechanical/warpage coverage |
| `silicon_test_debug.md` | Good | No shmoo/Vmin/Fmax guidance |

**Cross-cutting prompt gaps:** No input/output format specs, no worked examples,
no inter-template linkage, no error/edge-case handling.

---

## 5. The Vision: AI Orchestrator → EDA Agents → Human Gates

Your stated goal: **AI tools orchestrate, EDA tools execute, humans gatekeep.**

Here is a concrete architecture for that:

```
┌─────────────────────────────────────────────────────────────┐
│                    AI ORCHESTRATOR (Goose)                   │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐ │
│  │  State    │  │  Report  │  │  Decision │  │  Human     │ │
│  │  Tracker  │  │  Parser  │  │  Engine   │  │  Gate API  │ │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘ │
│        │              │              │              │        │
│        ▼              ▼              ▼              ▼        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              FLOW STATE MACHINE                      │   │
│  │  product → arch → lint → sim → formal → synth →     │   │
│  │  sta → pnr → signoff → package → test               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
          │                                        ▲
          ▼                                        │
┌─────────────────────┐                  ┌─────────────────────┐
│   EDA TOOL AGENTS   │                  │    HUMAN GATES      │
│                     │                  │                     │
│  Verilator          │   structured     │  🔒 Spec Freeze     │
│  Yosys + ABC        │   reports +      │  🔒 RTL Freeze      │
│  SymbiYosys         │◄─ exit codes ──► │  🔒 Synth Handoff   │
│  OpenSTA            │                  │  🔒 Tapeout         │
│  OpenROAD           │                  │  🔒 Package Release  │
│  KLayout            │                  │  🔒 Test Sign-off   │
│  Commercial tools   │                  │                     │
└─────────────────────┘                  └─────────────────────┘
```

### 5.1 Three-Tier Responsibilities

**AI Orchestrator (Goose / LLM controller):**
- Maintains a flow state machine (DAG of stages with dependencies).
- Invokes EDA tool agents with correct inputs and config.
- Parses structured reports (JSON/YAML, not just logs).
- Interprets results: pass → advance; fail → diagnose, propose fix, re-run.
- Escalates to human at defined milestone gates.
- Tracks history: what ran, what passed, what changed since last pass.

**EDA Tool Agents (the tools themselves, wrapped):**
- Each tool is wrapped in a standardized interface: `invoke(inputs) → {exit_code, report, artifacts}`.
- Reports are structured (JSON metrics + human-readable summary).
- Tools are stateless — all state lives in the orchestrator and the filesystem.
- Commercial and open-source tools implement the same interface.

**Human Gates (you, the engineer):**
- Approve/reject at defined milestones (not every step).
- Set policy (waivers, target overrides, scope changes).
- Override orchestrator decisions when domain judgment is needed.
- Review AI-proposed fixes before they're applied to source-of-truth files.

### 5.2 What This Requires That SilicaFlow Doesn't Have

| Requirement | Current State | Needed |
|-------------|---------------|--------|
| Flow state machine / DAG | Flat Makefile, no deps | Dependency-aware DAG with stage status tracking |
| Structured tool reports | Raw log files | JSON/YAML report schema per stage |
| Tool agent interface | Ad-hoc `run.sh` scripts | Standardized wrapper: inputs → invoke → structured output |
| Report parsing | None | Per-stage parsers that extract pass/fail, metrics, violations |
| Human gate mechanism | None | Gate definitions + approval workflow (CLI or UI) |
| Flow state persistence | None | State file tracking stage status, timestamps, hashes |
| Retry / re-route logic | None | Orchestrator decision tree per failure type |
| Inter-stage contracts | None | Explicit input/output schemas per stage |

---

## 6. Improvement Plan — Phases

### Phase 0: Fix the Foundation (Week 1–2)
> *Make what exists actually work end-to-end.*

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 0.1 | **Fix Yosys synthesis** — add `abc -liberty $LIBERTY_FILE` for technology mapping | 🔴 Critical | 1 hr |
| 0.2 | **Complete OpenROAD PnR** — add CTS, global route, detailed route, DEF/GDS export | 🔴 Critical | 4 hr |
| 0.3 | **Fix KLayout DRC** — point at actual GDS output, expand rule set | 🔴 Critical | 2 hr |
| 0.4 | **Add hold-time STA** — add `-path_delay min` analysis to `run.tcl` | 🟡 High | 30 min |
| 0.5 | **Add Makefile dependencies** — `sta: synth`, `pnr: synth`, `drc: pnr` | 🟡 High | 1 hr |
| 0.6 | **Fix `check_env.sh`** — validate Liberty/LEF existence, check TB_CPP, add version checks | 🟡 High | 1 hr |
| 0.7 | **Fix README links** — use repo-relative paths | 🟢 Low | 15 min |
| 0.8 | **Create `design/include/`** directory (even if empty) or remove from filelist | 🟢 Low | 5 min |
| 0.9 | **Add `project.mk` variables** — `CLK_PERIOD_NS`, `PROCESS_CORNER`, `PVT_CORNERS` | 🟡 High | 30 min |
| 0.10 | **Add `make all` meta-target** — runs `lint parse sim formal synth sta pnr drc` in order | 🟡 High | 30 min |

**Exit criteria:** `make all` runs from a clean checkout and produces a GDS + timing
report with no tool errors (violations are acceptable at this stage).

---

### Phase 1: Structured Reports & Tool Agent Interface (Week 3–4)
> *Make tool outputs machine-readable so the AI orchestrator can interpret them.*

| # | Task | Priority |
|---|------|----------|
| 1.1 | **Define a universal tool-agent report schema** (JSON): `{tool, stage, exit_code, pass, metrics: {}, violations: [], artifacts: [], summary: ""}` | 🔴 Critical |
| 1.2 | **Add report parsers** for each stage — post-process raw logs into the JSON schema: lint (warning/error counts), sim (pass/fail + coverage), formal (proved/failed/unknown), synth (cell count, area), STA (WNS, TNS, WHS, THS), PnR (utilization, congestion, DRVs), DRC (violation count by rule) | 🔴 Critical |
| 1.3 | **Wrap each `run.sh`** in a standardized agent interface: accept JSON config, produce JSON report, return structured exit code (0=pass, 1=fail, 2=error) | 🟡 High |
| 1.4 | **Add a `reports/` manifest** — `reports/manifest.json` tracking which stages have run, when, input hashes, and pass/fail status | 🟡 High |
| 1.5 | **Create `schemas/`** directory with JSON Schema definitions for tool reports and stage configs | 🟡 High |

**Exit criteria:** Every `make <stage>` produces both a raw log and a
`reports/<stage>/report.json` conforming to the schema.

---

### Phase 2: Flow State Machine & Dependency DAG (Week 5–6)
> *Replace the flat Makefile with an orchestration-aware flow engine.*

| # | Task | Priority |
|---|------|----------|
| 2.1 | **Define the stage DAG** in a declarative config (`flow/dag.yaml`): stages, dependencies, inputs, outputs, human-gate flags | 🔴 Critical |
| 2.2 | **Build a flow runner** (`scripts/flow_runner.py` or extend Makefile) that: reads the DAG, checks prerequisites, invokes stages in order, tracks state | 🔴 Critical |
| 2.3 | **Add state persistence** — `work/flow_state.json` tracking: stage status (pending/running/passed/failed/stale), timestamps, input file hashes (to detect staleness) | 🟡 High |
| 2.4 | **Implement staleness detection** — if an input to a stage changes, mark it and all downstream stages as stale | 🟡 High |
| 2.5 | **Add `make status`** target — pretty-print the flow state (which stages passed, which are stale, what's next) | 🟡 High |
| 2.6 | **Add incremental run support** — `make run` only executes stale stages | 🟡 High |

**Exit criteria:** `make status` shows the full DAG with color-coded stage status.
Changing an RTL file automatically marks lint → sim → formal → synth → downstream as stale.

---

### Phase 3: Human Gate Mechanism (Week 7–8)
> *Define where you, the engineer, must approve before the flow advances.*

| # | Task | Priority |
|---|------|----------|
| 3.1 | **Define 6 milestone gates** (see [Section 8](#8-milestone-gate-definitions) below) with entry criteria, review checklist, and approval mechanism | 🔴 Critical |
| 3.2 | **Implement gate-check in the flow runner** — when a stage with `gate: true` passes, pause and prompt for human approval before advancing | 🔴 Critical |
| 3.3 | **Add `make approve GATE=<name>`** command — records approval with timestamp, approver, and optional notes in `work/gates.json` | 🟡 High |
| 3.4 | **Add `make reject GATE=<name>`** command — records rejection with reason, blocks downstream | 🟡 High |
| 3.5 | **Add gate status to `make status`** output — show which gates are pending, approved, or rejected | 🟡 High |
| 3.6 | **Create gate review templates** — per-gate checklists in `docs/gates/` that the orchestrator presents to you at review time | 🟡 High |

**Exit criteria:** The flow pauses at each gate and cannot advance without explicit
`make approve`. Gate history is tracked and auditable.

---

### Phase 4: AI Orchestrator Integration (Week 9–12)
> *Connect Goose (or equivalent LLM) as the orchestration brain.*

| # | Task | Priority |
|---|------|----------|
| 4.1 | **Create orchestrator prompt/recipe** — a Goose recipe that understands the DAG, can invoke `make <stage>`, parse JSON reports, and decide next actions | 🔴 Critical |
| 4.2 | **Implement report interpretation** — orchestrator reads `report.json`, classifies results (clean pass / pass-with-warnings / fail-fixable / fail-needs-human), and acts accordingly | 🔴 Critical |
| 4.3 | **Implement fix-propose-verify loop** — on fixable failures, orchestrator: diagnoses root cause using prompt templates, proposes a fix (patch), presents to human for approval, applies fix, re-runs stage | 🔴 Critical |
| 4.4 | **Wire prompt templates into the orchestrator** — each template becomes a callable "skill" the orchestrator invokes with structured inputs from the report JSON | 🟡 High |
| 4.5 | **Add orchestrator memory** — conversation/session state that persists across runs, tracking what was tried, what worked, what the human decided | 🟡 High |
| 4.6 | **Implement multi-agent coordination** — orchestrator dispatches to the correct agent role based on the stage and failure type | 🟡 High |
| 4.7 | **Add a `make orchestrate`** target — launches the AI orchestrator in a loop: check status → run next stage → interpret → gate or continue | 🟡 High |

**Exit criteria:** `make orchestrate` can drive the flow from lint through DRC with
minimal human intervention, pausing at gates and proposing fixes for common failures.

---

### Phase 5: Fill the Signoff Gaps (Week 13–16)
> *Add the missing critical signoff stages.*

| # | Task | Priority |
|---|------|----------|
| 5.1 | **Add CDC/RDC stage** — integrate a CDC tool (e.g., open-source: `cdc_check` via Yosys passes; commercial: Spyglass/Questa CDC). Assign to Verification agent. | 🔴 Critical |
| 5.2 | **Add LVS stage** — KLayout LVS or commercial (Calibre/PVS). Assign to Physical agent. | 🔴 Critical |
| 5.3 | **Add LEC stage** — Yosys `equiv_*` commands or commercial (Formality/Conformal). Assign to Physical agent. | 🔴 Critical |
| 5.4 | **Add power analysis stage** — OpenROAD power analysis or commercial (Voltus/RedHawk). Assign to Physical agent. | 🟡 High |
| 5.5 | **Add DFT insertion stage** — scan chain insertion flow. Assign to Design agent (insertion) + Test agent (intent/verification). | 🟡 High |
| 5.6 | **Update the DAG** with new stages and dependencies | 🟡 High |
| 5.7 | **Update agent role files** with ownership of new stages | 🟡 High |

**Exit criteria:** The DAG includes all signoff-critical stages. `make status` shows
a complete flow from lint through LVS/LEC/power.

---

### Phase 6: Harden & Scale (Week 17+)
> *Production-grade robustness.*

| # | Task | Priority |
|---|------|----------|
| 6.1 | **Multi-corner/multi-mode support** — PVT corner configs, per-corner STA, per-corner signoff | 🟡 High |
| 6.2 | **Commercial tool adapters** — implement the same agent interface for Synopsys/Cadence/Siemens tools | 🟡 High |
| 6.3 | **CI/CD integration** — GitHub Actions or similar running `make all` on every PR | 🟡 High |
| 6.4 | **Regression management** — nightly runs, pass-rate tracking, coverage trending | 🟡 High |
| 6.5 | **Expand prompt templates** — add worked examples, input/output format specs, inter-template linkage | 🟢 Medium |
| 6.6 | **Agent role hardening** — expand each role file to 30+ lines with artifact templates, naming conventions, handoff protocols, escalation paths | 🟢 Medium |
| 6.7 | **Observability dashboard** — web UI or CLI dashboard showing flow state, QoR trends, gate history | 🟢 Medium |
| 6.8 | **Design complexity scaling** — test with a non-trivial design (e.g., RISC-V core) to validate the flow at scale | 🟢 Medium |

---

## 7. Proposed Directory Structure (v2)

```
SilicaFlow/
├── agents/
│   └── roles/                    # (existing, expanded)
│       ├── architecture.md       #   30+ lines each with handoff protocols
│       ├── cad.md
│       ├── design.md
│       ├── package.md
│       ├── physical.md
│       ├── product.md
│       ├── test.md
│       └── verification.md
├── architecture/                 # (existing)
├── config/
│   ├── project.mk               # (existing, expanded with CLK/PVT/MCMM)
│   ├── corners/                  # NEW: per-corner config files
│   │   ├── ss_0p75v_125c.mk
│   │   ├── tt_0p85v_25c.mk
│   │   └── ff_0p95v_m40c.mk
│   └── tools.mk                 # NEW: tool version requirements
├── design/                       # (existing)
├── docs/
│   ├── gates/                    # NEW: per-gate review checklists
│   │   ├── G1_spec_freeze.md
│   │   ├── G2_rtl_freeze.md
│   │   ├── G3_synth_handoff.md
│   │   ├── G4_tapeout.md
│   │   ├── G5_package_release.md
│   │   └── G6_test_signoff.md
│   ├── flow.md                   # (existing)
│   ├── lifecycle-layers.md       # (existing)
│   ├── toolchain-matrix.md       # (existing, expanded)
│   └── codex-workflows.md        # (existing, expanded with worked examples)
├── flow/
│   ├── dag.yaml                  # NEW: declarative stage DAG
│   ├── common/
│   │   ├── project.tcl           # (existing)
│   │   └── agent_wrapper.sh      # NEW: standardized tool-agent wrapper
│   ├── frontend/                 # (existing, expanded)
│   │   ├── lint/
│   │   ├── parse/
│   │   ├── sim/
│   │   ├── formal/
│   │   ├── cdc/                  # NEW
│   │   └── synth/
│   ├── backend/                  # (existing, expanded)
│   │   ├── sta/
│   │   ├── pnr/
│   │   ├── power/                # NEW
│   │   ├── lec/                  # NEW
│   │   └── signoff/
│   │       ├── drc/              # (existing, fixed)
│   │       └── lvs/              # NEW
│   └── commercial/               # (existing)
├── libs/                         # (existing)
├── orchestrator/                 # NEW: AI orchestration layer
│   ├── recipe.yaml               #   Goose recipe for flow orchestration
│   ├── skills/                   #   Per-stage AI skills (wired from prompts/)
│   │   ├── diagnose_lint.md
│   │   ├── diagnose_timing.md
│   │   ├── diagnose_drc.md
│   │   └── ...
│   ├── decision_trees/           #   Per-failure-type decision logic
│   │   ├── timing_failure.yaml
│   │   ├── drc_failure.yaml
│   │   └── ...
│   └── state/                    #   Runtime state (gitignored)
│       ├── flow_state.json
│       └── gates.json
├── package/                      # (existing)
├── pdks/                         # (existing)
├── product/                      # (existing)
├── prompts/                      # (existing, expanded with format specs + examples)
├── reports/                      # (existing)
├── schemas/                      # NEW: JSON schemas for reports and configs
│   ├── tool_report.schema.json
│   ├── stage_config.schema.json
│   ├── flow_state.schema.json
│   └── gate_record.schema.json
├── scripts/
│   ├── check_env.sh              # (existing, hardened)
│   ├── flow_runner.py            # NEW: DAG-aware flow execution engine
│   ├── parse_report.py           # NEW: raw log → JSON report converter
│   └── gate.sh                   # NEW: approve/reject CLI
├── silicon_test/                 # (existing)
├── AGENTS.md                     # (existing, expanded)
├── Makefile                      # (existing, expanded with deps + new targets)
└── README.md                     # (existing, fixed links)
```

---

## 8. Milestone Gate Definitions

These are the points where the flow **must pause for your approval** before
advancing. The AI orchestrator cannot bypass these.

### G1: Spec Freeze 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After product requirements are baselined |
| **Entry criteria** | All requirements have IDs, acceptance criteria, and traceability hooks. Ambiguity list is empty or explicitly accepted. |
| **You review** | Requirements completeness, feasibility, priority. Are we building the right thing? |
| **Artifacts** | `product/requirements/`, `product/traceability/` |
| **Blocks** | Architecture exploration, RTL design |

### G2: RTL Freeze 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After all front-end stages pass (lint ✅, parse ✅, sim ✅, formal ✅, CDC ✅) |
| **Entry criteria** | Zero lint errors (warnings reviewed). Sim regression 100% pass. All formal properties proved. CDC clean or waivers documented. Coverage targets met. |
| **You review** | Micro-architecture decisions, code quality, verification completeness. Is the design correct? |
| **Artifacts** | `design/rtl/`, `design/formal/`, `reports/lint/`, `reports/sim/`, `reports/formal/`, `reports/cdc/` |
| **Blocks** | Synthesis handoff |

### G3: Synthesis Handoff 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After synthesis + pre-layout STA pass |
| **Entry criteria** | Synthesis completes without errors. STA: WNS ≥ 0 (setup), WHS ≥ 0 (hold) or documented exceptions. Area within budget. LEC passes (RTL vs. netlist). |
| **You review** | QoR metrics (area, timing, power estimates). Are we on budget? Any synthesis artifacts that need constraint tuning? |
| **Artifacts** | `reports/synth/`, `reports/sta/`, `reports/lec/`, synthesized netlist |
| **Blocks** | PnR |

### G4: Tapeout 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After PnR + all signoff checks pass |
| **Entry criteria** | Timing clean (all corners, setup + hold). DRC clean. LVS clean. Power analysis within budget (IR drop, EM). Post-route LEC passes. |
| **You review** | Final QoR, all signoff reports, waiver list. Is this ready for fabrication? |
| **Artifacts** | GDS, final STA reports (all corners), DRC/LVS reports, power reports |
| **Blocks** | GDS submission to foundry |

### G5: Package Release 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After package design and analysis complete |
| **Entry criteria** | Bump map finalized. SI/PI/thermal analysis clean. OSAT handoff artifacts generated. |
| **You review** | Package-die integration risks, thermal margins, SI/PI margins. |
| **Artifacts** | `package/` artifacts, analysis reports |
| **Blocks** | OSAT submission |

### G6: Test Sign-off 🔒
| Aspect | Detail |
|--------|--------|
| **When** | After silicon bring-up and characterization |
| **Entry criteria** | Bring-up checklist complete. Characterization data within spec. Yield meets target. Known failures triaged. |
| **You review** | Silicon health, yield, failure modes. Is this ready for production? |
| **Artifacts** | `silicon_test/` artifacts, characterization reports, yield data |
| **Blocks** | Production release |

---

## 9. Risks & Open Questions

### Risks

| # | Risk | Mitigation |
|---|------|------------|
| R1 | **AI orchestrator makes wrong diagnosis** and proposes a harmful fix | Human gate on all source-of-truth edits. Fix-propose-verify loop always shows diff before applying. |
| R2 | **Tool report parsing is brittle** — log formats change between versions | Pin tool versions in `config/tools.mk`. Use structured output flags where tools support them (e.g., OpenROAD JSON metrics). |
| R3 | **Open-source tools can't reach signoff quality** for real tapeouts | Commercial adapter slots are already scaffolded. The agent interface is tool-agnostic. |
| R4 | **Scope creep** — trying to automate everything at once | Phased plan with clear exit criteria per phase. Phase 0 alone makes the repo usable. |
| R5 | **Single-engineer bottleneck** at human gates | Gates are designed to be fast (checklist-based). Orchestrator pre-digests reports into summaries. Over time, trust calibration may allow some gates to become advisory. |

### Open Questions

| # | Question | Needs Decision From |
|---|----------|---------------------|
| Q1 | Should the flow runner be a Python script, a Makefile extension, or a dedicated tool (e.g., Snakemake, Nextflow)? | You — tradeoff between simplicity and power |
| Q2 | Should the AI orchestrator run as a Goose recipe, a standalone agent, or a scheduled job? | You — depends on interaction model (interactive vs. batch) |
| Q3 | What is the first non-trivial design to test the flow with? (e.g., PicoRV32, SERV, Ibex) | You — depends on complexity appetite |
| Q4 | Should commercial tool adapters share the same `run.sh` interface or have a separate adapter layer? | You — depends on licensing and access patterns |
| Q5 | How should gate approvals be stored long-term? (Git commits? External database? Signed artifacts?) | You — depends on audit/compliance requirements |
| Q6 | What is the trust calibration model? (i.e., when can a human gate be relaxed to advisory?) | You — evolves with experience |

---

## Summary: What Changes and What Stays

| Stays | Changes |
|-------|---------|
| 6-layer lifecycle model | Backend pipeline fixed and completed |
| 8 agent roles (expanded) | Roles get handoff protocols and validation gates |
| Open-source reference stack | New stages: CDC, LVS, LEC, power, DFT |
| Source-of-truth separation | Structured JSON reports alongside raw logs |
| Prompt templates (enhanced) | Templates get format specs, examples, linkage |
| Commercial adapter slots | Standardized tool-agent interface |
| Override-friendly config | Multi-corner/multi-mode support |
| — | **NEW: Flow DAG with dependency tracking** |
| — | **NEW: Human milestone gates** |
| — | **NEW: AI orchestrator layer** |
| — | **NEW: Report parsing and interpretation** |
| — | **NEW: State persistence and staleness detection** |

The core philosophy of SilicaFlow is sound. The improvement plan preserves everything
that works and adds the three missing layers — structured tool output, flow orchestration,
and human gating — that transform it from a skeleton into the AI-orchestrated silicon
design flow you envision.
