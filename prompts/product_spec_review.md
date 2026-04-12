# Prompt: Product Spec Review

## Task
Turn a product-level draft (PRD or market requirement document) into a structured, testable requirement set with traceability hooks.

## Inputs
- **PRD draft**: Markdown or text document with product feature descriptions
- **Compliance constraints**: regulatory or customer-mandated requirements (if any)
- **Prior acceptance criteria**: existing test criteria from previous revisions (if any)
- **Architecture budgets**: `architecture/budgets/` (for feasibility cross-check)

## Outputs (Markdown table format)
1. **Requirement table**: columns = ID (REQ-xxx), Description, Priority (P0/P1/P2), Acceptance Criteria, Owner (arch/design/verif/test), Status
2. **Ambiguity list**: items the spec leaves unclear — each with a proposed resolution and impact if unresolved
3. **Traceability hooks**: mapping of REQ-xxx → target architecture/verification/test artifact
4. **Non-functional checklist**: power, thermal, reliability, security, compliance — flagged if not addressed

## Validation
- No requirement is untestable, duplicate, or missing an owner
- Every ambiguity has a proposed resolution
- Traceability covers all requirements

## Worked Example
Input: "The device shall support 10Gbps Ethernet"
Output row: `REQ-NET-001 | Support 10Gbps Ethernet | P0 | Link training completes in <500ms, BER < 1e-12 | design + verif | Draft`
Ambiguity: "10Gbps — is this 10GBASE-R, 10GBASE-KR, or both? Impact: PHY design and SerDes spec differ."

## Linkage
- Outputs feed → `architecture_tradeoff.md` (requirements as constraints)
- Outputs feed → Verification agent (acceptance criteria → coverage plan)
- Gate: **G1 (spec_freeze)** — all outputs must be complete before gate approval
