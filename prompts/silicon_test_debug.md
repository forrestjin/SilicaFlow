# Prompt: Silicon Test Debug

## Task
Cluster post-silicon failures by probable root cause and propose the next debug split to isolate the issue.

## Inputs
- **Tester logs**: ATE datalog with failing bins, pass/fail counts
- **Failing signatures**: pattern names, failing vectors, scan chain data
- **Characterization data**: Vmin/Fmax shmoo plots, voltage/temperature sweeps
- **Netlist/DFT context**: scan chain mapping, ATPG coverage report

## Outputs (Markdown format)
1. **Failure mode table**: columns = Cluster ID, Symptom, Volume (count/%), Likely Root Cause Category
2. **Root cause categories**: logic bug, timing (setup/hold), power (IR drop/EM), package (SI/PI/thermal), process (defect density), test infrastructure (ATE/pattern/socket)
3. **Next debug action**: specific action for lab, ATE, FA, or design — with expected outcome
4. **Fact vs. hypothesis separation**: clearly label what is observed vs. what is inferred

## Validation
- Observed facts are separated from hypotheses
- Each hypothesis has a falsifiable test
- Debug actions are specific (not "investigate further")

## Worked Example
Cluster: "15% of units fail at Vmin on scan pattern group 'mem_bist_chain_3'"
Observed: fails only at Vmin, passes at nominal; localized to memory BIST chain 3
Hypothesis: [Medium] "Hold-time violation on memory output path — marginal at low voltage"
Next: "Run shmoo at 5mV steps around Vmin; cross-reference with STA hold slack on mem_out path"

## Linkage
- Receives from → Silicon Test agent (tester data) + Physical agent (timing/power reports)
- Outputs feed → Design agent (if logic fix needed) or Physical agent (if timing fix needed)
- Gate: **G6 (test_signoff)** — all critical failures must be resolved or waived
