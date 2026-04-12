# SilicaFlow Flow Overview

SilicaFlow follows a full ASIC productization progression:

1. Product specification defines requirements, compliance targets, customer-visible behavior, and acceptance criteria.
2. Architecture design converts requirements into partitioning, interfaces, PPA budgets, safety/security concepts, and verification intent.
3. Front-end implementation validates RTL semantics through lint, elaboration, simulation, and formal methods.
4. Back-end implementation converts validated RTL into a timing-closed, physically implementable database and tapeout package.
5. Package realization translates die requirements into bump, substrate, power delivery, thermal, and assembly artifacts.
6. Post-silicon test and characterization turn manufactured parts into measurable quality, yield, and debug feedback.

## Source separation

- `product/`: PRD, market requirements, compliance requirements, and requirement traceability
- `architecture/`: models, interface contracts, budgets, virtual prototypes, and trade studies
- `design/rtl/`: synthesizable RTL
- `design/tb/`: simulation harnesses and TB code
- `design/formal/`: formal wrappers and properties
- `design/constraints/`: SDC and stage-specific constraint fragments
- `design/filelists/`: reusable source manifests
- `design/upf/`: power intent placeholders
- `package/`: package planning, substrate, analysis, and OSAT handoff artifacts
- `silicon_test/`: DFT intent, ATE collateral, bring-up notes, characterization, yield learning, and failure-analysis records

## Report separation

- `reports/`: human-consumable summaries and raw report dumps
- `logs/`: tool stdout/stderr logs
- `work/`: generated intermediates, compiled models, databases, and netlists

## Industry-aligned practices captured here

- Requirements and architecture are versioned before RTL.
- Workload assumptions, PPA budgets, and interface contracts are explicit artifacts, not tribal knowledge.
- Constraints are versioned independently of RTL.
- Tool entry points are one per stage, not one monolithic script.
- Physical-flow inputs are parameterized through `config/project.mk`.
- The synthesized netlist becomes the handoff boundary from front-end to back-end.
- Package and test artifacts are tracked after back-end because product success depends on assembly, SI/PI/thermal closure, ATE coverage, and yield learning in addition to GDS.
- Vendor-specific flows are isolated so you can swap Synopsys, Cadence, or open-source back-ends without changing the repository contract.
