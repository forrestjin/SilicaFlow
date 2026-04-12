# G2: RTL Freeze — Review Checklist

**Gate:** rtl_freeze
**Question:** Is the design functionally correct?

## Entry Criteria
- [ ] Lint: zero errors, warnings reviewed and waived/fixed
- [ ] Parse: clean elaboration, no unresolved references
- [ ] Simulation: regression 100% pass
- [ ] Formal: all properties proved (or bounded to sufficient depth)
- [ ] CDC: clean or all crossings have documented synchronizers
- [ ] Coverage targets met (functional, code, assertion)

## Review Items
- [ ] Micro-architecture matches architecture spec
- [ ] Interface contracts honored (protocol, timing, width)
- [ ] Reset strategy correct and verified
- [ ] Clock domain crossings properly synchronized
- [ ] Assertions cover critical data-path invariants
- [ ] Code quality: no latches, no incomplete case, no width mismatches

## Artifacts to Inspect
- `design/rtl/` — RTL source
- `design/formal/` — formal properties and assumptions
- `reports/lint/report.json` — lint results
- `reports/sim/report.json` — simulation results
- `reports/formal/report.json` — formal results
- `reports/cdc/report.json` — CDC results

## Approval
Run: `make approve GATE=rtl_freeze`
