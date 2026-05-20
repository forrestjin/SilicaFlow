# G6: Test Sign-off — Review Checklist

**Gate:** test_signoff
**Question:** Is this ready for production?

## Entry Criteria
- [ ] Bring-up checklist complete — all functional blocks alive
- [ ] Characterization data within datasheet spec (Vmin, Fmax, power)
- [ ] Yield meets target (or root-cause plan for shortfall)
- [ ] All known failures triaged and categorized
- [ ] ATE program correlated with bench measurements
- [ ] Wafer-sort bin definitions and sort-to-final-test correlation reviewed

## Review Items
- [ ] Shmoo plots show adequate voltage/frequency margins
- [ ] No systematic failure modes unresolved
- [ ] DFT coverage meets target (stuck-at, transition, path-delay)
- [ ] Reliability screening (burn-in, HTOL) results acceptable
- [ ] Failure analysis on critical fails complete
- [ ] Reprobe policy is controlled and not masking real yield loss
- [ ] Soft-bin and hard-bin mapping still matches factory disposition and SKU policy

## Artifacts to Inspect
- `silicon_test/bringup/` — bring-up logs and checklist
- `silicon_test/characterization/` — Vmin/Fmax/power data
- `silicon_test/yield_reliability/` — yield and reliability data
- `silicon_test/fa/` — failure analysis reports
- `silicon_test/atpg/` — test coverage metrics
- `docs/silicon_test/wafer_binning.md` — binning theory, policy, and standard practice

## Approval
Run: `make approve GATE=test_signoff`
