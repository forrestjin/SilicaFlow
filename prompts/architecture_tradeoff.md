# Prompt: Architecture Tradeoff Study

## Task
Compare architecture options for a bounded design decision and recommend one with explicit tradeoffs, cross-domain fallout, and risk assessment.

## Inputs
- **Workload assumptions**: traffic patterns, bandwidth, latency requirements (from `architecture/workloads/`)
- **Interface constraints**: protocol, timing, width (from `architecture/interfaces/`)
- **PPA targets**: area, timing, power budgets (from `architecture/budgets/`)
- **Software/package constraints**: if relevant to the decision

## Outputs (Markdown format)
1. **Option matrix** (table): columns = Option Name, Area Impact, Timing Impact, Power Impact, Complexity, Risk, Notes
2. **Recommendation**: chosen option with rationale tied to specific budgets/requirements
3. **Cross-domain fallout**: impact on front-end (RTL changes), back-end (constraint changes), package (I/O changes), test (DFT impact)
4. **Open risks**: items requiring measurement or modeling before the decision is final

## Validation
- Every recommendation ties back to a budget, workload, or requirement
- Rejected alternatives are documented with rationale
- Fallout section covers all affected domains

## Worked Example
Decision: "Pipeline depth for data path: 2-stage vs. 3-stage"
Option matrix row: `3-stage | +15% area | +200MHz Fmax | +10% power | Medium | Low | Meets timing budget with margin`
Recommendation: "3-stage — meets 500MHz timing target with 20% margin; 2-stage fails by 50MHz."

## Linkage
- Receives from → `product_spec_review.md` (requirements as constraints)
- Outputs feed → `spec_to_rtl.md` (chosen architecture → RTL implementation)
- Gate: **G1 (spec_freeze)** — architecture must be feasible before gate approval
