# Prompt: Power Analysis Review

## Task
Review power analysis results and identify violations or budget exceedances with actionable recommendations.

## Inputs
- **Power report**: `reports/power/report.json` + raw tool log
- **Power budget**: from `architecture/budgets/` (per-block and total power targets)
- **Activity data**: switching activity file or estimates (if available)
- **PnR database**: `work/pnr/` (for IR drop context)

## Outputs (Markdown format)
1. **Power summary table**: columns = Component (leakage/internal/switching/total), Value (mW), Budget (mW), Margin (%)
2. **Hotspot identification**: blocks or regions exceeding local power density limits
3. **IR drop / EM violations**: specific nets or regions with excessive voltage drop or current density
4. **Recommendations**: specific actions (clock gating, power gating, decap insertion, floorplan change)

## Validation
- Total power within architecture budget
- IR drop within PDK limits (typically < 5-10% of VDD)
- EM current density within foundry limits
- `make power` — re-run after any mitigation changes

## Worked Example
Issue: "Leakage power = 45mW, budget = 30mW — 50% over budget"
Recommendation: "Apply power gating to idle datapath blocks; estimated savings = 20mW. Requires UPF update."

## Linkage
- Receives from → `make power` output
- Outputs feed → Architecture agent (budget reallocation) or Design agent (clock/power gating)
- Gate: **G4 (tapeout)** — power must be within budget before gate approval
