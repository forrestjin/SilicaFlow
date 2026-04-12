# Prompt: LEC Review

## Task
Review logic equivalence checking results and diagnose any non-equivalent points.

## Inputs
- **LEC report**: `reports/lec/report.json` + raw tool log
- **RTL source**: `design/filelists/rtl.f`
- **Synthesized netlist**: `work/synth/*_netlist.v`
- **Synthesis log**: `reports/synth/report.json` (for optimization context)

## Outputs (Markdown format)
1. **Equivalence summary**: total compare points, equivalent, non-equivalent, aborted
2. **Non-equivalent point analysis**: for each failing point — signal name, likely cause (optimization, constant propagation, retiming, tool bug)
3. **Recommended action**: constraint fix, synthesis option change, or RTL annotation

## Validation
- `make lec` — all compare points equivalent after fixes
- Non-equivalences are explained, not just listed

## Worked Example
Non-equivalent: `reg_output[3]` — synthesis optimized away a redundant mux
Action: "Add `(* keep *)` attribute to `reg_output` in RTL, or verify the optimization is functionally correct"

## Linkage
- Receives from → `make lec` output
- Outputs feed → Physical agent (synthesis constraint tuning) or Design agent (RTL annotation)
- Gate: **G3 (synth_handoff)** — LEC must pass before gate approval
