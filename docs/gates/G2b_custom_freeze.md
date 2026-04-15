# G2b: Custom Freeze

> **Gate question:** Are all custom blocks verified, extracted, and characterized?

This gate must be approved before custom block Liberty models and LEF abstracts
can be integrated into the digital synthesis and PnR flow.

## Entry Criteria

- [ ] All custom block schematics complete and reviewed
- [ ] All custom block layouts complete
- [ ] Architecture budgets for custom blocks finalized

## Review Checklist

### Schematic & Simulation
- [ ] All custom blocks have CDL netlists exported from schematics
- [ ] SPICE testbenches exist for all custom blocks
- [ ] Circuit simulation passes across minimum 3 PVT corners (fast, typical, slow)
- [ ] Monte Carlo simulation run for variation-sensitive blocks (if applicable)
- [ ] Noise/stability analysis complete for analog blocks (if applicable)

### Layout & Physical Verification
- [ ] All custom blocks DRC clean (`make custom_drc` — 0 violations)
- [ ] All custom blocks LVS clean (`make layout_vs_sch` — all matched)
- [ ] Antenna rule violations resolved
- [ ] Density fill applied where required
- [ ] Pin access verified for digital integration

### Extraction & Characterization
- [ ] Parasitic extraction complete for all custom blocks (`make extraction`)
- [ ] Post-extraction simulation matches pre-extraction within tolerance
- [ ] Liberty models generated for all PVT corners (`make char`)
- [ ] Liberty model validation: timing within 5% of SPICE golden reference
- [ ] Liberty model validation: power within 10% of SPICE golden reference
- [ ] LEF abstracts generated and pin geometry verified

### Integration Readiness
- [ ] Liberty files (.lib) delivered to `libs/` or `CUSTOM_LIBERTY_FILES` path
- [ ] LEF files (.lef) delivered to `CUSTOM_LEF_FILES` path
- [ ] GDS files (.gds) delivered to `CUSTOM_GDS_FILES` path
- [ ] Verilog behavioral models delivered to `design/rtl/` or include path
- [ ] CDL netlists delivered for full-chip LVS

## Artifacts to Inspect

| Artifact | Location | What to Check |
|----------|----------|---------------|
| Circuit sim reports | `reports/circuit_sim/` | All corners pass, no convergence issues |
| Custom DRC report | `reports/custom_drc/` | 0 violations |
| Custom LVS report | `reports/layout_vs_sch/` | All blocks matched |
| Extraction report | `reports/extraction/` | Extraction completed, no errors |
| Characterization report | `reports/char/` | Liberty vs SPICE correlation |
| Liberty models | `CUSTOM_LIBERTY_FILES` | Timing/power tables populated |
| LEF abstracts | `CUSTOM_LEF_FILES` | Pin geometry, obstruction layers |

## Approval

```bash
make approve GATE=custom_freeze NOTES="All N custom blocks verified and characterized"
```

## Rejection Reasons (common)

```bash
make reject GATE=custom_freeze REASON="LVS mismatch in block_X — missing via connection"
make reject GATE=custom_freeze REASON="Liberty timing >10% off SPICE at slow corner"
make reject GATE=custom_freeze REASON="DRC violations in density fill region"
make reject GATE=custom_freeze REASON="Missing Monte Carlo analysis for PLL block"
```

## Impact of Re-opening

If this gate is re-opened after approval:
- **G3 (synth_handoff)** may need re-review if Liberty models changed
- **G4 (tapeout)** will need re-review for GDS merge changes
- All downstream digital stages (synth, STA, PnR) may need re-run
