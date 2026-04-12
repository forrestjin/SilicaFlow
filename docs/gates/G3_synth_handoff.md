# G3: Synthesis Handoff — Review Checklist

**Gate:** synth_handoff
**Question:** Are we on PPA budget?

## Entry Criteria
- [ ] Synthesis completes without errors
- [ ] Pre-layout STA: WNS ≥ 0 (setup), WHS ≥ 0 (hold) — or documented exceptions
- [ ] LEC passes: RTL ≡ synthesized netlist
- [ ] Area within architecture budget
- [ ] Estimated power within budget

## Review Items
- [ ] QoR metrics (area, timing slack, cell count) are reasonable
- [ ] No unexpected black-boxes or unmapped cells
- [ ] Clock tree assumptions documented
- [ ] Constraint quality: no false paths masking real issues
- [ ] Synthesis warnings reviewed (especially re-encoding, optimization)

## Artifacts to Inspect
- `reports/synth/report.json` — synthesis QoR
- `reports/sta_pre/report.json` — pre-layout timing
- `reports/lec/report.json` — equivalence check
- `work/synth/` — synthesized netlist

## Approval
Run: `make approve GATE=synth_handoff`
