# Prompt: Timing Triage

## Task
Read a static timing analysis report and cluster violations by root cause, with actionable next steps.

## Inputs
- **STA report**: `reports/sta_pre/report.json` or `reports/sta_post/report.json` (JSON) + raw log
- **SDC constraints**: `design/constraints/*.sdc`
- **Synthesized netlist**: `work/synth/*_netlist.v`
- **PPA budgets**: `architecture/budgets/` (for context on timing targets)

## Outputs (Markdown format)
1. **Violation summary table**: columns = Path Group/Clock Domain, WNS, TNS, Count, Likely Cause
2. **Root cause classification**: each group tagged as: constraint issue, logic depth, fanout, transition, physical effect (placement/routing), or multi-cycle path
3. **Concrete next steps**: specific commands or changes (not generic advice)
4. **Setup vs. hold distinction**: separate analysis for setup and hold violations

## Validation
- Rerun `make sta_pre` or `make sta_post` after any SDC or netlist change
- Every recommendation is actionable (specific file, line, or command)

## Worked Example
Violation: "WNS = -0.5ns on path clk → reg_a → combinational_cloud → reg_b"
Classification: "Logic depth — 12 levels of combinational logic"
Next step: "Consider retiming or pipeline insertion between stages 6 and 7. See `design/rtl/datapath.sv:142`."

## Linkage
- Receives from → `make sta_pre` or `make sta_post` output
- Outputs feed → `spec_to_rtl.md` (if RTL change needed) or `report_diff.md` (to track improvement)
- Gate: **G3 (synth_handoff)** — timing must be clean before gate approval
