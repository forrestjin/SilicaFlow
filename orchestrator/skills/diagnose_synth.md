# Skill: Diagnose Synthesis Failures

## When to Use
When `make synth` fails (reports/synth/report.json shows errors > 0 or area exceeds budget).

## Procedure
1. Read `reports/synth/report.json` — extract cell count, area, errors, warnings
2. Read the raw Yosys/Genus/DC log for error messages
3. Classify the failure:
   - **Synthesis error** → unmapped cells, black boxes, missing modules
   - **Area overshoot** → design too large for budget; identify largest blocks
   - **Optimization warnings** → re-encoding, constant propagation, removed logic
4. For each issue, propose a fix:
   - Missing module → check filelist, add missing source
   - Area overshoot → suggest micro-architecture simplification or resource sharing
   - Unmapped cells → check Liberty file coverage, add technology mapping flags
5. Present to engineer, apply approved fixes, re-run `make synth`

## Key Metrics to Check
- Total cell count and area vs. architecture budget
- Number of unmapped or generic cells (should be zero with Liberty)
- Warnings about inferred latches (should be zero)
- Clock gating inference results
