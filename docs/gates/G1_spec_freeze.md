# G1: Spec Freeze — Review Checklist

**Gate:** spec_freeze
**Question:** Are we building the right thing?

## Entry Criteria
- [ ] All product requirements have unique IDs (REQ-xxx)
- [ ] Every requirement has acceptance criteria
- [ ] Every requirement has an owner (architecture, design, verification, test)
- [ ] Ambiguity list is empty or all ambiguities explicitly accepted with rationale
- [ ] Compliance / regulatory requirements captured (if applicable)
- [ ] Traceability hooks exist from requirements → architecture → verification

## Review Items
- [ ] Requirements are feasible within PPA budget envelope
- [ ] No duplicate or contradictory requirements
- [ ] Non-functional requirements addressed (power, thermal, reliability, security)
- [ ] Customer-visible feature set matches roadmap commitment
- [ ] Risk register updated with product-level risks

## Artifacts to Inspect
- `product/requirements/` — requirement database
- `product/traceability/` — traceability matrix
- `product/market/` — market context and competitive analysis

## Approval
Run: `make approve GATE=spec_freeze`
