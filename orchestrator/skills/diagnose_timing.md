# Skill: Diagnose Timing Failures

## When to Use
When `make sta_pre` or `make sta_post` fails (WNS < 0 or hold violations).

## Procedure
1. Read `reports/sta_pre/report.json` or `reports/sta_post/report.json`
2. Extract WNS, TNS, WHS, THS, and violating path count
3. Read the raw STA log for detailed path reports
4. Cluster violations by:
   - Path group / clock domain
   - Root cause: constraint issue, logic depth, fanout, transition, physical effect
5. For each cluster, propose a specific fix:
   - Constraint fix → SDC change (show exact lines)
   - Logic depth → pipeline insertion or retiming (show RTL location)
   - Fanout → buffer insertion (tool option or manual)
   - Physical → placement/routing guidance
6. Use `prompts/timing_triage.md` template for structured analysis
7. Present to engineer, apply approved fixes, re-run STA

## Key Metrics to Report
- WNS (Worst Negative Slack) — setup
- TNS (Total Negative Slack) — setup
- WHS (Worst Hold Slack) — hold
- Number of violating endpoints
- Worst path details (start → end, levels of logic, slack)
