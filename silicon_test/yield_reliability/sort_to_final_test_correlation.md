# Sort-To-Final-Test Correlation

## Document Control

| Field | Value |
| --- | --- |
| Product | `<product_or_family>` |
| Analysis Window | `<start_date>` to `<end_date>` |
| Wafer Sort Program | `<ws_program_rev>` |
| Final Test Program | `<ft_program_rev>` |
| Package Flow | `<package_or_osat_flow>` |
| Owner | `<owner>` |

## Objective

This review checks whether wafer-sort binning is classifying die appropriately when compared with downstream packaged-unit outcomes. The main questions are:

1. Are wafer-sort pass bins stable at final test?
2. Are reprobe decisions recovering good units without masking real failures?
3. Are speed or power grades holding through package test and characterization?
4. Are PAT and outlier screens preventing escapes without excessive yield loss?

## Datasets Used

| Dataset | Source | Revision / Range | Notes |
| --- | --- | --- | --- |
| Wafer sort records | `<source>` | `<range>` | Include wafer ID, die coordinates, soft bin, hard bin, tester, prober |
| Final test records | `<source>` | `<range>` | Include packaged unit ID, final-test bin, failing test class |
| Assembly genealogy | `<source>` | `<range>` | Link die to packaged units |
| Characterization / shmoo | `<source>` | `<range>` | Optional but recommended for speed-grade validation |
| RMA / FA feedback | `<source>` | `<range>` | Optional downstream validation |

## Cohort Summary

| Metric | Value |
| --- | --- |
| Total die probed | `<count>` |
| Wafer-sort pass hard-bin rate | `<percent>` |
| Reprobe rate | `<percent>` |
| Reprobe salvage rate | `<percent>` |
| Final-test fallout from wafer-sort pass bins | `<percent>` |
| KGD fallout rate | `<percent_or_na>` |

## Correlation Matrix

Summarize the dominant flow from wafer-sort bins into final-test outcomes.

| Wafer Sort Bin | Wafer Sort Units | Final-Test Pass | Final-Test Fail | Main Final-Test Fail Class | Comment |
| --- | --- | --- | --- | --- | --- |
| `PASS_STD` | `<count>` | `<count>` | `<count>` | `<class>` | `<observation>` |
| `PASS_SPEED_A` | `<count>` | `<count>` | `<count>` | `<class>` | `<observation>` |
| `PASS_REPAIRED_MBIST` | `<count>` | `<count>` | `<count>` | `<class>` | `<observation>` |
| `CONTACT_SUSPECT` reprobed | `<count>` | `<count>` | `<count>` | `<class>` | `<observation>` |
| `IDDQ_OUTLIER` held | `<count>` | `<count_or_na>` | `<count_or_na>` | `<class>` | `<observation>` |

## Key Checks

### Wafer-Sort Pass Integrity

- `PASS_STD` final-test fallout target: `<target>`
- `PASS_SPEED_A` downgrade or fail rate target: `<target>`
- `PASS_REPAIRED_MBIST` special-watch fallout target: `<target>`

### Reprobe Effectiveness

- Was reprobe limited to approved bins?
- Did reprobe salvage mostly contact-limited units?
- Is the reprobe salvage rate stable by tester, prober, and probe-card revision?

### Grade Stability

- Do speed bins remain stable after package, burn-in, and characterization?
- Do low-leakage bins preserve their intended separation at final test?

### Screen Effectiveness

- Are PAT and outlier-screen catches correlated with downstream quality risk?
- Is there evidence of over-screening or unnecessary yield loss?

## Top Findings

| Severity | Finding | Evidence | Likely Owner | Recommended Action |
| --- | --- | --- | --- | --- |
| `<high/med/low>` | `<finding>` | `<metric_or_bin>` | `<owner>` | `<action>` |
| `<high/med/low>` | `<finding>` | `<metric_or_bin>` | `<owner>` | `<action>` |
| `<high/med/low>` | `<finding>` | `<metric_or_bin>` | `<owner>` | `<action>` |

## Action Tracker

| Action | Owner | Due Date | Status | Link |
| --- | --- | --- | --- | --- |
| `<action>` | `<owner>` | `<YYYY-MM-DD>` | `<open/in_progress/closed>` | `<ticket_or_doc>` |
| `<action>` | `<owner>` | `<YYYY-MM-DD>` | `<open/in_progress/closed>` | `<ticket_or_doc>` |

## Sign-Off Recommendation

Recommendation: `<release / hold / release_with_actions>`

Rationale:

- `<reason_1>`
- `<reason_2>`
- `<reason_3>`

