# SilicaFlow Toolchain Matrix

## Public-syntax reference stack

These templates are executable and based on current public documentation.

| Stage | Tool | Status | Notes |
| --- | --- | --- | --- |
| Lint | Verible | Ready | Uses `verible-verilog-lint` with a flagfile. |
| Parse | Surelog | Ready | Uses `-f`, `-parse`, `-elabuhdm`, `-top`, and `-odir`. |
| Sim | Verilator | Ready | Uses `--cc --exe --build --sv --top-module`. |
| Formal | SymbiYosys | Ready | Uses an `.sby` file and a minimal harness. |
| Synth | Yosys | Ready | Uses `read_verilog -sv`, `hierarchy -check -top`, `synth`, and `write_verilog`. |
| STA | OpenSTA | Ready | Uses `read_liberty`, `read_verilog`, `link_design`, `read_sdc`, and `report_checks`. |
| PnR | OpenROAD | Scaffold | Tcl is structurally valid, but requires real LEF/Liberty/technology inputs to do useful work. |
| DRC | KLayout | Scaffold | Runset is minimal and intended as a placeholder for process-specific decks. |

## Lifecycle layers above and below implementation

These layers are documented and structured in-repo, but not represented as runnable `make` targets because their source-of-truth tools are usually enterprise ALM, architecture, package, lab, and ATE systems rather than a uniform CLI flow.

| Layer | Primary artifacts | Tool examples |
| --- | --- | --- |
| Product specification | PRD, requirements database, compliance matrices, feature acceptance criteria | IBM DOORS Next, Siemens Polarion, Jama Connect, Jira/Confluence |
| Architecture design | workload models, PPA budgets, interface specs, virtual platforms, trade studies | MATLAB/Simulink, SystemC/TLM, Synopsys Virtualizer, Cadence Palladium/Protium |
| Package realization | bump maps, substrate layouts, SI/PI/thermal studies, assembly handoff | Cadence Integrity/Allegro packaging tools, Siemens Xpedition Package Designer, Synopsys 3DIC/package co-design tools, Ansys analysis tools |
| Post-silicon test | DFT plans, ATPG patterns, ATE programs, bring-up logs, characterization and yield data | Siemens Tessent, Cadence Modus, Synopsys TestMAX, Teradyne/Advantest ATE, lab debug tools |

## Commercial tool adapters

These directories are included for repo hygiene and methodology alignment, not as validated executable templates:

- `flow/commercial/synopsys/`
- `flow/commercial/cadence/`
- `flow/commercial/siemens/`

They are intentionally left as documented integration points because official current command references for those tools are not publicly accessible.
