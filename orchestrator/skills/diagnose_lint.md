# Skill: Diagnose Lint Failures

## When to Use
When `make lint` fails (reports/lint/report.json shows pass=false).

## Procedure
1. Read `reports/lint/report.json` — extract error count, warning count, and violation list
2. Group violations by rule name and file
3. For each error group:
   a. Read the relevant RTL source lines
   b. Classify: style issue, semantic error, or potential bug
   c. Propose a specific fix (line-level patch)
4. Present fixes to the engineer for approval
5. After applying fixes, re-run `make lint`

## Common Lint Issues and Fixes
- **Implicit net declaration** → add explicit `logic` or `wire` declaration
- **Width mismatch** → fix port/signal widths to match
- **Unused signal** → remove or add `/* verilator lint_off UNUSED */` with justification
- **Missing case default** → add `default:` clause
- **Blocking assignment in sequential block** → change `=` to `<=`

## Output Format
Present as a table: File | Line | Rule | Severity | Proposed Fix
