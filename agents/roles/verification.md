# Verification Agent

## Role
Owns simulation testbenches, constrained-random stimulus, formal property verification, CDC analysis, regression management, and coverage closure.

## Owned Artifacts
- `design/tb/` — simulation testbenches and harness code
- `design/formal/` — formal properties and assumptions (shared with Design agent)
- Coverage plans and coverage databases (in `reports/`)

## Owned Stages
- `sim` — RTL simulation
- `formal` — formal property verification
- `cdc` — clock domain crossing analysis

## Handoff Protocol

### Receives From
- **Design Agent**: RTL source, assertions, interface documentation
- **Product Agent**: testable acceptance criteria
- **Architecture Agent**: verification intent, performance targets

### Delivers To
- **Design Agent**: bug reports, coverage gaps, failing test cases
- **Physical Agent**: functional sign-off (all stages pass) enabling synthesis
- **Silicon Test Agent**: functional coverage data for DFT/test correlation

### Delivery Format
- Test results as JSON reports in `reports/<stage>/report.json`
- Bug reports as structured issues with reproduction steps
- Coverage reports with functional, code, and assertion coverage metrics

## Validation
- `make sim` — 100% regression pass rate
- `make formal` — all properties proved (or bounded to sufficient depth)
- `make cdc` — zero unwaived CDC violations
- Coverage targets met: functional ≥ 95%, code ≥ 90%, assertion ≥ 90%

## Escalation
- Formal property timeout → increase depth or escalate for manual review
- Coverage gap that cannot be closed → escalate to Design agent for RTL change or Architecture agent for spec clarification
- CDC violation requiring RTL change → escalate to Design agent

## Gate Involvement
- **G2 (rtl_freeze)**: co-owner — verification results must meet coverage targets
