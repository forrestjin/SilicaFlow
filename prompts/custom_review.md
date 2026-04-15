# Prompt: Custom Block Design Review

## When to Use

Use this prompt when reviewing custom/analog block design quality before
the Custom Freeze gate (G2b), or when diagnosing failures in custom design stages.

## Inputs

- Custom block name and function
- Circuit simulation reports (`reports/circuit_sim/report.json`)
- Custom DRC report (`reports/custom_drc/report.json`)
- Custom LVS report (`reports/layout_vs_sch/report.json`)
- Extraction report (`reports/extraction/report.json`)
- Characterization report (`reports/char/report.json`)
- Architecture PPA budgets for the block

## Task

You are reviewing a custom-designed block for integration readiness.
Analyze the reports and answer these questions:

### 1. Functional Correctness
- Does the circuit simulation pass across all specified PVT corners?
- Are there convergence issues at any corner?
- For analog blocks: are gain, bandwidth, phase margin, noise within spec?
- For memory blocks: are read/write margins within spec across corners?

### 2. Physical Verification
- Is the block DRC clean? If not, classify violations by severity.
- Is the block LVS clean? If not, identify the mismatch type (opens, shorts, device mismatches).
- Are there antenna violations?

### 3. Extraction Quality
- Was parasitic extraction successful for all blocks?
- Does post-extraction simulation match pre-extraction within tolerance?
- Are coupling capacitances reasonable (no unexpected cross-talk paths)?

### 4. Characterization Quality
- Do Liberty timing values correlate with SPICE within 5%?
- Do Liberty power values correlate with SPICE within 10%?
- Are all timing arcs characterized (setup, hold, CK-to-Q, etc.)?
- Are all PVT corners characterized?

### 5. Integration Readiness
- Are Liberty, LEF, GDS, and CDL files all generated and consistent?
- Does the LEF abstract have correct pin access for the digital PnR tool?
- Is the GDS merge-ready (correct layer mapping, boundary, etc.)?

## Output Format

```
## Custom Block Review: <block_name>

### Summary
- Status: PASS / FAIL / CONDITIONAL
- Blocking issues: <count>
- Warnings: <count>

### Circuit Simulation
- Corners tested: <list>
- Pass/Fail: <summary>
- Key metrics: <table of spec vs measured>

### Physical Verification
- DRC: <clean / N violations>
- LVS: <matched / N mismatches>
- Antenna: <clean / N violations>

### Characterization
- Timing correlation: <max deviation %>
- Power correlation: <max deviation %>
- Corners characterized: <list>

### Recommendations
1. <specific action items>
```

## Validation

After review, the human engineer should verify:
- [ ] All blocking issues resolved before approving G2b
- [ ] Liberty models loaded into synthesis and STA runs clean
- [ ] LEF abstracts accepted by PnR tool without errors
