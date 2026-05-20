# Wafer Binning Policy

## Document Control

| Field | Value |
| --- | --- |
| Product | `<product_or_family>` |
| Revision | `<rev>` |
| Owner | `<product_engineering_owner>` |
| Reviewers | `<test>`, `<yield>`, `<design>`, `<quality>`, `<operations>` |
| Effective Date | `<YYYY-MM-DD>` |
| Applies To | `<wafer_sort_program>`, `<package_family>`, `<sku_family>` |
| Supersedes | `<prior_revision_or_none>` |

## Purpose

This document defines the production wafer-sort binning policy for the product named above. It establishes:

- soft-bin and hard-bin intent
- die disposition rules
- reprobe policy
- speed, power, and repair-grade handling
- PAT and outlier-screen usage
- required downstream correlation checks

## Scope

This policy applies to:

- electrical wafer sort / wafer probe
- die disposition into package, hold, reprobe, or scrap
- speed and power grade assignment at wafer sort
- KGD or advanced-package eligibility, if applicable

This policy does not replace:

- datasheet limit ownership
- DFT coverage sign-off
- final-test release criteria
- customer-specific screening agreements

## Linked Artifacts

- [bin_map.csv](bin_map.csv)
- [sort_to_final_test_correlation.md](sort_to_final_test_correlation.md)
- [pat_limits.csv](pat_limits.csv)
- [Wafer Binning In ASIC Silicon Test](/Users/flin/Documents/Playground/SilicaFlow/docs/silicon_test/wafer_binning.md)

## Policy Objectives

Primary objectives:

1. Prevent false passes that create package scrap, outgoing quality risk, or field escapes.
2. Minimize false fails that unnecessarily reduce sellable yield.
3. Preserve enough bin resolution to support diagnosis and yield learning.
4. Keep bin definitions stable, versioned, and review-controlled.

## Required Inputs Before Release

- approved wafer-sort test program revision
- approved DFT coverage summary
- approved datasheet parametric limits
- approved product SKU policy
- approved package-cost and KGD strategy inputs
- approved PAT or outlier-screen configuration, if applicable

## Bin Taxonomy

Definitions used in this policy:

- `soft bin`: diagnostic or logical classification assigned by the test program
- `hard bin`: physical disposition bucket used by prober, MES, or OSAT flow
- `reprobe`: one additional probe attempt allowed under controlled conditions
- `KGD`: known good die or known good wafer disposition with enhanced screening expectations

## Release Rules

### Soft-Bin Rules

- Every soft bin must map to exactly one hard bin.
- Soft-bin meaning must be specific enough to distinguish contact, scan, memory, timing, leakage, analog, and engineering-hold cases where applicable.
- New soft bins require owner, rationale, and expected yield impact before release.

### Hard-Bin Rules

- Hard bins must match actual factory disposition.
- Pass hard bins must never be fed by fail-intent soft bins without explicit cross-functional approval.
- Engineering hold bins must not silently route to package.

### Reprobe Rules

- Reprobe is allowed only for bins explicitly marked as reprobe-eligible in `bin_map.csv`.
- Maximum reprobe count per die: `<max_reprobe_count>`
- Reprobe reasons must be logged and reviewable by lot, wafer, and tester/prober setup.
- Repeatable structural failures are not eligible for reprobe.

### Speed And Power Grading

- Speed and power bins must map to approved SKU definitions.
- Grade limits must be based on validated test content and correlation data, not single-corner optimism.
- Any grade change requires comparison against downstream final-test stability.

### Memory Repair Policy

- Repair-used pass bins must be separated from no-repair pass bins if repair status matters to product quality, yield learning, or customer commitments.
- Exhausted-repair fail bins must be diagnosis-visible.

### KGD Policy

- If KGD is enabled, KGD-eligible bins must be explicitly identified in `bin_map.csv`.
- KGD screening must be at least as strict as the program's released KGD rule set.
- KGD traceability must be preserved into package and module assembly.

## Required Reviews

### Pre-Release Review

- DFT/test coverage review
- product engineering review
- manufacturing operations review
- quality/reliability review
- package or module-integration review if KGD is relevant

### Ongoing Production Review

Review cadence: `<weekly_or_per_lot_family>`

Required topics:

- bin pareto drift
- reprobe rate and reprobe salvage rate
- sort-to-final-test fallout by wafer-sort bin
- outlier-screen hit rate
- speed-bin stability
- tester/prober hardware effects

## Stop-Ship Or Escalation Triggers

Escalate immediately if any of the following occur:

- unexplained increase in final-test fallout from wafer-sort pass bins
- abnormal reprobe hit rate
- wafer-map spatial pattern suggesting systematic process or contact issue
- PAT or outlier-screen excursion
- unexpected drift in speed or power grade distribution
- KGD fallout inconsistent with released expectations

## Change Log

| Date | Revision | Change Summary | Owner | Approval Reference |
| --- | --- | --- | --- | --- |
| `<YYYY-MM-DD>` | `<rev>` | Initial template release | `<owner>` | `<ticket_or_review_id>` |

## Release Sign-Off

| Function | Name | Status | Date |
| --- | --- | --- | --- |
| Product Engineering | `<name>` | `<approved/pending>` | `<YYYY-MM-DD>` |
| Test Engineering | `<name>` | `<approved/pending>` | `<YYYY-MM-DD>` |
| Yield Engineering | `<name>` | `<approved/pending>` | `<YYYY-MM-DD>` |
| Quality/Reliability | `<name>` | `<approved/pending>` | `<YYYY-MM-DD>` |
| Operations/Manufacturing | `<name>` | `<approved/pending>` | `<YYYY-MM-DD>` |

