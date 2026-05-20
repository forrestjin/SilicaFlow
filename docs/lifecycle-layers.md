# SilicaFlow Lifecycle Layers

This document extends SilicaFlow beyond implementation-only flows. Tool examples were checked against public vendor materials on April 11, 2026; use them as current industry anchors, not as a claim that one vendor is mandatory.

## 1. Product Specification

Purpose: decide what the silicon must do, for whom, and how success will be measured.

Major steps:

1. Market and customer problem framing.
2. Product requirements definition and prioritization.
3. External interface and compliance requirement capture.
4. Feature-to-requirement traceability setup.
5. Acceptance criteria and measurable KPIs.
6. Change control across marketing, systems, hardware, software, validation, and program teams.

Typical artifacts:

- PRD or MRD
- interface requirements
- safety/security/compliance requirements
- feature acceptance matrix
- requirement IDs linked to architecture and verification

Tool classes and current examples:

- Requirements/traceability: IBM DOORS Next, Siemens Polarion, Jama Connect
- Collaboration and change management: Jira/Confluence or equivalent ALM stack
- Review/signoff: controlled document workflows and baseline comparison in the chosen ALM

AI agent use:

- turn draft product text into structured requirements
- detect ambiguous or untestable requirements
- build traceability matrices from PRD to RTL and verification hooks
- summarize requirement deltas across program reviews

## 2. Architecture Design

Purpose: transform requirements into a technically feasible SoC or ASIC definition with explicit performance, power, area, cost, safety, and schedule tradeoffs.

Major steps:

1. Use-case and workload definition.
2. Top-level partitioning into hardware, firmware, software, and off-chip dependencies.
3. Clock/reset/power-domain concept planning.
4. Interface and NoC/memory architecture definition.
5. PPA budgeting by subsystem.
6. Modeling, architecture exploration, and virtual prototyping.
7. Verification strategy and observability definition.
8. Architecture review and handoff into detailed micro-architecture and front-end execution.

Typical artifacts:

- block diagrams
- interface contracts
- PPA budget tables
- workload/performance models
- memory maps and interrupt maps
- virtual prototypes and early software platforms
- tradeoff records with rationale

Tool classes and current examples:

- Modeling: MATLAB/Simulink, SystemC/TLM
- Virtual prototyping: Synopsys Virtualizer and TLM model flows
- Emulation/prototyping for architecture and software bring-up: Cadence Palladium and Protium
- Interconnect planning: NoC design/exploration tools such as Arteris platforms where applicable

AI agent use:

- enforce interface consistency across architecture docs
- extract budgets and assumptions into machine-checkable tables
- compare architecture revisions and summarize impact on FE/BE
- generate starter specs for subsystems, CSRs, interrupts, and memory maps

## 3. Front-End Design And Verification

Purpose: convert architecture into correct, synthesizable RTL with validated functional behavior.

Major steps:

1. Micro-architecture definition.
2. RTL coding and review.
3. Lint, elaboration, CDC/RDC, and local static checks.
4. Simulation, formal, and coverage closure.
5. Constraint and low-power intent alignment.
6. Synthesis handoff readiness.

Current executable reference stack in this repo:

- Verible
- Surelog
- Verilator
- SymbiYosys
- Yosys

## 3b. Custom Design (Technology, Analog, Manual Layout, Characterization)

Purpose: design, verify, and characterize blocks that fall outside the standard automated digital flow — analog/mixed-signal circuits, custom logic, memory compilers, IO cells, and process-dependent structures — and deliver them as hard macros for digital integration.

This layer runs **in parallel** with the digital front-end (Layer 3). Custom blocks are independently designed, simulated, laid out, verified, extracted, and characterized. Their outputs (Liberty timing models, LEF abstracts, GDS) feed into the digital flow at synthesis and PnR.

### Sub-layers

#### 3b.1 Technology Co-Optimization (DTCO/STCO)

Purpose: explore and lock process options before custom design begins.

Major steps:

1. Define PPA targets from architecture budgets.
2. Evaluate process options: Vt flavors, metal stack variants, device options.
3. Run circuit simulation across process options to quantify tradeoffs.
4. System-Technology Co-Optimization (STCO): evaluate package/board impact on process choices.
5. Feed results back to architecture for tradeoff decisions.
6. Lock process options and custom device models.

Typical artifacts:

- process option comparison tables
- custom device SPICE models (beyond standard PDK)
- DTCO/STCO tradeoff records with rationale
- locked process option configuration

#### 3b.2 Custom Schematic Design

Purpose: capture custom block schematics and export simulation-ready netlists.

Major steps:

1. Schematic entry for analog, mixed-signal, memory, IO, and custom logic blocks.
2. CDL netlist export for LVS.
3. SPICE netlist export for circuit simulation.
4. Verilog behavioral model creation for digital integration.

Typical artifacts:

- CDL netlists
- SPICE netlists
- Verilog behavioral models
- schematic review checklists

#### 3b.3 Circuit Simulation

Purpose: verify custom block functionality across process, voltage, and temperature corners.

Major steps:

1. DC operating point and bias verification.
2. AC frequency response and stability analysis.
3. Transient time-domain behavior and switching characteristics.
4. Monte Carlo process variation sensitivity analysis.
5. Noise analysis (noise figure, phase noise) for analog blocks.
6. Reliability analysis (HCI, NBTI, EM) for stress-sensitive paths.

Typical artifacts:

- simulation results per corner
- spec-vs-measured comparison tables
- Monte Carlo yield estimates
- corner coverage matrix

#### 3b.4 Custom Layout

Purpose: create physical layout for custom blocks with manual placement and routing.

Major steps:

1. Floorplanning and device placement.
2. Manual routing of critical paths (matching, shielding, symmetry).
3. Power grid and guard ring construction.
4. Density fill and antenna fix.
5. GDS and LEF abstract export.

Typical artifacts:

- GDS II layout databases
- LEF abstracts for digital PnR integration
- layout review checklists

#### 3b.5 Custom Physical Verification (DRC, LVS)

Purpose: verify custom layout against design rules and schematic.

Major steps:

1. DRC against process design rules.
2. LVS against schematic netlist.
3. Antenna rule checking.
4. ERC (electrical rule check) for well ties, substrate contacts.

#### 3b.6 Parasitic Extraction

Purpose: extract parasitics from verified custom layout for post-layout simulation and characterization.

Major steps:

1. RC extraction with process-calibrated rule decks.
2. Coupling capacitance extraction for cross-talk analysis.
3. Post-extraction simulation to validate against pre-extraction results.

#### 3b.7 Library Characterization

Purpose: generate Liberty timing/power models from extracted custom blocks.

Major steps:

1. Define characterization templates (timing arcs, slew/load tables, power tables).
2. Run characterization simulations across PVT corners.
3. Generate Liberty models (CCS, ECSM, or NLDM format).
4. Validate Liberty models against golden SPICE simulation.
5. Deliver .lib files to digital flow for synthesis and STA.

Typical artifacts:

- Liberty (.lib) timing/power models per PVT corner
- characterization correlation reports (Liberty vs SPICE)
- model validation summaries

### Tool classes and current examples

| Stage | Open-Source | Commercial |
|-------|-----------|------------|
| Schematic entry | xschem | Cadence Virtuoso, Synopsys Custom Compiler |
| Circuit simulation | ngspice, Xyce | Cadence Spectre, Synopsys HSPICE, Siemens Eldo |
| Custom layout | Magic VLSI, KLayout | Cadence Virtuoso Layout, Synopsys Custom Compiler, Siemens L-Edit |
| DRC | Magic | Siemens Calibre, Cadence Pegasus, Synopsys ICV |
| LVS | Netgen | Siemens Calibre, Cadence Pegasus, Synopsys ICV |
| Extraction | Magic | Synopsys StarRC, Cadence QRC, Siemens Calibre xRC |
| Characterization | ngspice (basic) | Cadence Liberate, Synopsys SiliconSmart |

### Current executable reference stack in this repo

- xschem (schematic entry)
- ngspice (circuit simulation, basic characterization)
- Magic VLSI (custom layout, DRC, extraction)
- Netgen (LVS)

### AI agent use

- summarize circuit simulation results across PVT corners and flag out-of-spec metrics
- classify DRC/LVS violations by severity and propose fixes
- compare Liberty model timing against SPICE golden reference
- track DTCO/STCO tradeoff decisions and their impact on downstream stages
- generate Custom Freeze (G2b) gate readiness summaries
- diff custom block revisions and assess impact on digital integration

### Human gate

**G2b: Custom Freeze** — blocks digital synthesis until all custom blocks are DRC/LVS clean,
circuit simulation passes across corners, and characterized Liberty models are validated.
See `docs/gates/G2b_custom_freeze.md` for the full checklist.

## 4. Back-End Implementation And Signoff

Purpose: convert validated RTL into a physically realizable design that meets timing, power, area, signal integrity, and signoff criteria.

Major steps:

1. Logic synthesis and netlist generation.
2. STA and constraint refinement.
3. Floorplanning and power planning.
4. Placement, CTS, routing, extraction, and timing closure.
5. Physical verification and tapeout package generation.

Current executable reference stack in this repo:

- OpenSTA
- OpenROAD
- KLayout scaffold

## 5. Post-Backend Package Realization

Purpose: transform the taped-out die into an assembled product with a manufacturable package, acceptable SI/PI/thermal behavior, and a clean OSAT handoff.

Important note: package planning starts before tapeout, but assembly/package realization becomes a downstream gate after back-end. This repo places the persistent package artifacts after back-end so the handoff is explicit.

Major steps:

1. Package architecture selection: wire-bond, flip-chip, fan-out, 2.5D, 3D, SiP, or chiplet package style.
2. Bump map, escape planning, substrate/interposer planning, and pin assignment confirmation.
3. Power delivery and decap strategy across die, package, and board boundaries.
4. SI/PI/thermal/mechanical co-analysis.
5. Package-route implementation and cross-domain co-design with die and board.
6. Assembly rules, material stackup, and OSAT handoff package.
7. Package qualification feedback loop into die ECOs or board changes if needed.

Typical artifacts:

- bump map and RDL constraints
- package stackup
- substrate/interposer database
- SI/PI/thermal reports
- assembly drawings and bill of materials
- OSAT handoff checklist

Tool classes and current examples:

- Package/system co-design: Cadence Integrity System Planner
- Package implementation: Cadence Allegro X Advanced Package Designer, Siemens Xpedition Package Designer
- Multi-die/package planning: Cadence Integrity 3D-IC and Synopsys 3DIC/package co-design offerings
- Analysis: Ansys thermal/SI/PI tools and package-aware signoff/analysis stacks

AI agent use:

- summarize package-rule changes and SI/PI findings
- diff bump maps and package constraints across revisions
- build handoff checklists for OSAT and board teams
- cluster package-related issue logs by electrical, thermal, mechanical, or manufacturability root cause

## 6. Post-Silicon Testing And Productization

Purpose: turn manufactured packaged parts into production-worthy silicon through bring-up, characterization, diagnosis, yield ramp, and reliability learning.

Major steps:

1. DFT plan closure and ATPG handoff validation.
2. Probe and package-test program preparation.
3. ATE vector generation, tester bring-up, and limits programming.
4. First-silicon bring-up in the lab using JTAG, firmware, scan access, and debug interfaces.
5. Characterization over process, voltage, and temperature corners.
6. Yield analysis, diagnosis, binning, and test-cost optimization.
7. Failure analysis and corrective-action loop into design, process, package, or test.

Typical artifacts:

- DFT architecture and coverage reports
- ATPG patterns and tester translation logs
- ATE program revisions and test limits
- bring-up checklists and issue trackers
- characterization dashboards
- yield paretos and diagnosis summaries
- FA requests and corrective-action records

Tool classes and current examples:

- DFT/ATPG/diagnosis: Siemens Tessent, Cadence Modus, Synopsys TestMAX
- Production ATE: Teradyne UltraFLEXplus, Advantest V93000-class platforms
- Lab bring-up/debug: JTAG/debug probes, trace/debug tools, scopes, logic analyzers, and protocol analyzers
- Yield analytics: internal data pipelines plus diagnosis/yield learning tools from the test stack

AI agent use:

- summarize failing test signatures and group them by suspected logic, package, or process cause
- compare characterization results across lots, corners, or tester revisions
- turn lab notes into structured issue trackers and retest plans
- generate FA intake packages and cross-link them to design changes

Detailed note:

- [Wafer Binning In ASIC Silicon Test](silicon_test/wafer_binning.md)
