# Skill: Diagnose DRC Failures

## When to Use
When `make drc` fails (reports/drc/report.json shows violations > 0).

## Procedure
1. Read `reports/drc/report.json` — extract violation count by rule
2. Read the raw KLayout/Calibre report for violation locations
3. Cluster violations by:
   - Rule type (width, spacing, enclosure, density, antenna)
   - Region (core, I/O ring, power grid, specific macro)
4. For each cluster, classify root cause:
   - Placement density too high → reduce TARGET_DENSITY
   - Routing congestion → adjust floorplan or add blockages
   - Power grid insufficient → add stripes or vias
   - Antenna violations → add diodes or reroute
5. Propose specific PnR configuration changes
6. Present to engineer, apply approved fixes, re-run `make pnr` then `make drc`

## Common DRC Issues
- **Metal width violations** → routing tool needs min-width constraint
- **Metal spacing violations** → congestion; reduce density or add routing layers
- **Via enclosure violations** → via sizing or alignment issue
- **Density violations** → add metal fill (post-route step)
- **Antenna violations** → insert antenna diodes or break long wires
