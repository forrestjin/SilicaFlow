# Skill: Diagnose Custom Design Failures

## When to Use

Use this skill when any custom design stage fails:
- `schematic_entry` — netlist export errors
- `circuit_sim` — SPICE simulation failures or convergence issues
- `custom_layout` — GDS/LEF export errors
- `custom_drc` — DRC violations in custom blocks
- `layout_vs_sch` — LVS mismatches in custom blocks
- `extraction` — parasitic extraction failures
- `char` — characterization failures or Liberty model issues

## Procedure

### Step 1: Read the report
```bash
cat reports/<stage>/report.json
```
Identify: `exit_code`, `errors`, `warnings`, `summary`.

### Step 2: Classify the failure

**Circuit Simulation failures:**
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Convergence failure | Unrealistic initial conditions, bad device models | Check .IC statements, verify model paths |
| Spec violation at one corner | Marginal design | Review biasing, consider design centering |
| Spec violation at all corners | Fundamental design issue | Escalate to Architecture for spec review |
| Missing testbench | Incomplete test setup | Create testbench in custom/simulation/testbenches/ |

**Custom DRC failures:**
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Metal spacing violations | Dense routing | Widen spacing, re-route |
| Via enclosure violations | Misaligned vias | Adjust via placement |
| Density violations | Insufficient fill | Run density fill |
| Well/implant violations | Incorrect device construction | Review device layout vs rules |

**Custom LVS failures:**
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Device count mismatch | Missing or extra devices in layout | Compare schematic vs layout device list |
| Net mismatch (opens) | Broken connections in layout | Check routing continuity |
| Net mismatch (shorts) | Unintended connections | Check for overlapping metals |
| Parameter mismatch | Wrong W/L or multiplier | Verify device dimensions |

**Extraction failures:**
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Missing layers | Incomplete layer mapping | Check tech file layer definitions |
| Unreasonable parasitics | Wrong extraction settings | Verify extraction rule deck |
| Tool crash | Memory or complexity issue | Simplify hierarchy, extract sub-blocks |

**Characterization failures:**
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Liberty vs SPICE >5% timing | Insufficient characterization points | Increase slew/load table density |
| Liberty vs SPICE >10% power | Wrong switching activity | Verify input stimulus in char template |
| Missing timing arcs | Incomplete template | Add missing arcs to char template |
| Negative delay values | Extraction or simulation issue | Re-extract, verify clock path |

### Step 3: Propose fix

For each failure, propose:
1. **Root cause** — what went wrong
2. **Fix** — specific file/setting to change
3. **Validation** — which `make` target to re-run
4. **Escalation** — if the fix requires spec/architecture changes

### Step 4: Report

```json
{
  "stage": "<stage_name>",
  "diagnosis": "<root cause>",
  "severity": "blocking|warning|info",
  "proposed_fix": "<specific action>",
  "validation_command": "make <stage>",
  "escalation_needed": true|false,
  "escalation_target": "architecture|human|null"
}
```
