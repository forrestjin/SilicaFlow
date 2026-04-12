# Prompt: Package Planning Review

## Task
Review package planning artifacts and identify the highest-risk integration issues across die, package, board, and OSAT boundaries.

## Inputs
- **Bump map**: `package/planning/` (CSV or structured table: bump ID, signal, x, y, layer)
- **Package stackup**: `package/substrate/` (layer count, materials, dimensions)
- **Power delivery targets**: from `architecture/budgets/` (current per rail, voltage tolerance)
- **SI/PI/thermal reports**: `package/analysis/` (PDF or structured summaries)

## Outputs (Markdown format)
1. **Ranked issue list**: columns = Rank, Issue, Severity (Critical/High/Medium/Low), Owner (die/package/board/OSAT/test)
2. **Follow-up analysis**: the smallest analysis needed to resolve each issue
3. **Cross-domain impact**: how each issue affects die design, package, board, or test

## Validation
- Every issue ties to a concrete artifact or report section
- Severity ratings are justified
- Follow-up analyses are specific and bounded

## Worked Example
Issue: "High-speed SerDes bumps adjacent to power bumps — SI coupling risk"
Severity: High | Owner: package + board
Follow-up: "Run SI simulation with actual bump assignment; check eye diagram degradation"

## Linkage
- Receives from → Physical agent (die GDS, pad ring) + Architecture agent (I/O plan)
- Outputs feed → Package agent action items
- Gate: **G5 (package_release)** — all critical issues must be resolved
