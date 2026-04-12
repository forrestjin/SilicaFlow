# Prompt: Report Diff

## Task
Compare two structured reports from the same flow stage and explain what changed, with confidence-rated hypotheses.

## Inputs
- **Old report**: `reports/<stage>/report.json` (previous run)
- **New report**: `reports/<stage>/report.json` (current run)
- **Config/constraint delta**: any changes to SDC, project.mk, or tool options between runs

## Outputs (Markdown format)
1. **Delta summary table**: columns = Metric, Old Value, New Value, Change (abs/%), Direction (better/worse/neutral)
2. **Hypotheses**: for each major regression or improvement, a confidence-rated explanation (High/Medium/Low)
3. **Follow-up command**: the smallest command to confirm each hypothesis

## Validation
- Every hypothesis ties to a specific config/constraint/RTL change
- Confidence ratings are calibrated (High = strong evidence, Low = speculation)
- Follow-up commands are runnable

## Worked Example
Delta: "WNS changed from +0.3ns to -0.2ns"
Hypothesis: "[High confidence] New combinational logic added in commit abc123 increased path depth by 3 levels"
Follow-up: "`make sta_pre` with `report_checks -through new_mux` to isolate the new path"

## Linkage
- Receives from → any stage's `report.json` (before/after comparison)
- Outputs feed → `timing_triage.md` (if timing regressed) or relevant stage prompt
