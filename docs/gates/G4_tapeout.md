# G4: Tapeout — Review Checklist

**Gate:** tapeout
**Question:** Is this ready for fabrication?

## Entry Criteria
- [ ] Post-route STA: timing clean all corners (setup + hold)
- [ ] DRC: zero violations (or all waived with foundry approval)
- [ ] LVS: clean match
- [ ] Power: IR drop and EM within limits
- [ ] Post-route LEC passes
- [ ] All signoff corners run and clean

## Review Items
- [ ] Final QoR vs. budget (area, timing, power)
- [ ] Waiver list reviewed — every waiver has rationale and risk assessment
- [ ] Metal fill and density rules met
- [ ] Antenna rules clean
- [ ] ESD protection verified
- [ ] GDS integrity check (layer map, cell names, bounding box)

## Artifacts to Inspect
- `reports/sta_post/report.json` — post-route timing (all corners)
- `reports/drc/report.json` — DRC results
- `reports/lvs/report.json` — LVS results
- `reports/power/report.json` — power analysis
- `work/pnr/*.gds` — final GDS

## Approval
Run: `make approve GATE=tapeout`
