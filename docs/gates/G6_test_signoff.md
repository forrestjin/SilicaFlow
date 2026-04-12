# G6: Test Sign-off — Review Checklist

**Gate:** test_signoff
**Question:** Is this ready for production?

## Entry Criteria
- [ ] Bring-up checklist complete — all functional blocks alive
- [ ] Characterization data within datasheet spec (Vmin, Fmax, power)
- [ ] Yield meets target (or root-cause plan for shortfall)
- [ ] All known failures triaged and categorized
- [ ] ATE program correlated with bench measurements

## Review Items
- [ ] Shmoo plots show adequate voltage/frequency margins
- [ ] No systematic failure modes unresolved
- [ ] DFT coverage meets target (stuck-at, transition, path-delay)
- [ ] Reliability screening (burn-in, HTOL) results acceptable
- [ ] Failure analysis on critical fails complete

## Artifacts to Inspect
- `silicon_test/bringup/` — bring-up logs and checklist
- `silicon_test/characterization/` — Vmin/Fmax/power data
- `silicon_test/yield_reliability/` — yield and reliability data
- `silicon_test/fa/` — failure analysis reports
- `silicon_test/atpg/` — test coverage metrics

## Approval
Run: `make approve GATE=test_signoff`
