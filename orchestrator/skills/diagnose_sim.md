# Skill: Diagnose Simulation Failures

## When to Use
When `make sim` fails (reports/sim/report.json shows pass=false).

## Procedure
1. Read `reports/sim/report.json` — extract assertion failure count and pass/fail
2. Read the raw Verilator/VCS/Xcelium log for assertion messages and error traces
3. For each failing assertion or test:
   a. Identify the failing signal, time, and expected vs. actual value
   b. Trace backward through the RTL to find the root cause
   c. Classify: RTL bug, testbench bug, spec misunderstanding, or race condition
4. Propose a fix:
   - RTL bug → show the specific RTL patch
   - Testbench bug → show the TB fix
   - Spec ambiguity → escalate to Architecture or Product agent
5. Present to engineer, apply approved fixes, re-run `make sim`

## Key Diagnostics
- Check waveform dump (if --trace enabled) for signal transitions
- Look for X-propagation issues (uninitialized signals)
- Check reset sequence (adequate reset assertion time?)
- Look for clock-edge race conditions in the testbench
