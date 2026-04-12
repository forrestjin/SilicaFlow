# G5: Package Release — Review Checklist

**Gate:** package_release
**Question:** Is the package integration sound?

## Entry Criteria
- [ ] Bump map finalized and matches die pad ring
- [ ] Substrate design complete
- [ ] SI analysis: eye diagrams meet spec for all high-speed interfaces
- [ ] PI analysis: PDN impedance and IR drop within budget
- [ ] Thermal analysis: junction temperature within limits at max power

## Review Items
- [ ] Package-die co-design constraints consistent
- [ ] Mechanical stress / warpage within assembly limits
- [ ] OSAT handoff artifacts complete and reviewed
- [ ] Assembly process qualified for this package type
- [ ] Test access (probe, socket) confirmed feasible

## Artifacts to Inspect
- `package/planning/` — bump map, package architecture
- `package/substrate/` — substrate design data
- `package/analysis/` — SI/PI/thermal reports
- `package/osat_handoff/` — OSAT deliverables

## Approval
Run: `make approve GATE=package_release`
