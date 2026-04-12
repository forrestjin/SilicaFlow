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
