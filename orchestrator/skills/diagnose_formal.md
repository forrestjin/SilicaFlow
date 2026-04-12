# Skill: Diagnose Formal Verification Failures

## When to Use
When `make formal` fails (reports/formal/report.json shows failed > 0 or unknown > 0).

## Procedure
1. Read `reports/formal/report.json` — extract proved, failed, unknown counts
2. For each failed property:
   a. Read the counter-example trace from the tool log
   b. Identify the failing assertion and the input sequence that triggers it
   c. Classify: RTL bug, over-constrained assumption, or property error
3. For unknown (timeout) properties:
   a. Check proof depth — is it sufficient for the design?
   b. Consider adding helper assertions or cutting the cone of influence
   c. Suggest increasing depth or switching to k-induction
4. Propose fixes and present to engineer

## Common Issues
- **Failed property** → usually an RTL bug; trace the counter-example
- **Unknown/timeout** → increase depth, add assumptions, or simplify the property
- **Vacuous pass** → property is trivially true due to over-constraining; review assumptions
- **Missing assume** → formal tool explores unreachable states; add `assume` on reset or protocol
