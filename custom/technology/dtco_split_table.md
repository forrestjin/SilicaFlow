# DTCO Split Tables

This note documents how SilicaFlow uses split tables for Design-Technology Co-Optimization (DTCO) and System-Technology Co-Optimization (STCO).

## Purpose

In DTCO, a split table is the experiment manifest that connects:

- process options and tuning knobs
- manufacturing split hierarchy such as lot, sublot, wafer, or structure
- measurement structures and model-refresh requirements
- downstream circuit, library, SRAM, and PPA decisions

If a table only records process settings, it is just a process DOE sheet. A DTCO split table must also preserve the path from process change to design consequence.

## Why It Matters

DTCO is used to evaluate and down-select process options using real design metrics such as power, performance, and area. In practice, semiconductor experiments are constrained by multistage batch processing, so split-lot or split-plot planning is usually required rather than free randomization.

That means a useful DTCO split table must answer:

1. Which process knob changed?
2. At what manufacturing hierarchy was it changed?
3. Which structures measure the impact?
4. Which models or views must be regenerated?
5. Which design targets and success metrics decide keep or drop?

## Recommended SilicaFlow Structure

SilicaFlow uses three linked tables:

- `split_table_template.csv`: factor definitions, baselines, hypotheses, and intended downstream impact
- `split_run_template.csv`: actual lot/sublot/wafer execution and revision traceability
- `split_response_template.csv`: measured outcomes and keep/drop decisions

This separation keeps planning, execution, and results distinct.

## Required Fields

At minimum, the split table should include:

- `split_id`: unique split identifier
- `parent_split`: genealogy from the baseline
- `module`: FEOL, MOL, BEOL, SRAM, thermal, or patterning domain
- `factor_name`: the tuned variable
- `factor_level`: the actual trial value
- `change_granularity`: lot, sublot, wafer, reticle, or structure
- `baseline_value`
- `hypothesis`
- `structures`
- `models_to_refresh`
- `design_targets`
- `success_metrics`
- `owner`
- `status`

## Practical Rules

### Split Hierarchy

Use the coarsest legal hierarchy for expensive or tightly coupled steps:

- lot-level for hard-to-change process integration choices
- sublot-level for intermediate splits
- wafer-level for more flexible tuning steps
- structure-level only when the change can be localized safely

### Model Traceability

Every split should explicitly state which downstream artifacts must be refreshed:

- TCAD decks
- compact models
- SPICE views
- RC extraction techfiles
- Liberty or SRAM characterization
- block-level PPA evaluation

### Decision Discipline

Do not wait until after the experiment to decide what matters. Each split should carry its intended success metrics up front, such as:

- `Ion`
- `Ioff`
- `Vt`
- `DIBL`
- `Rcontact`
- `Cwire`
- `RO_FO4`
- SRAM `read_SNM`
- leakage
- EM margin
- full-block PPA

## Example Flow

1. Architecture provides PPA budgets.
2. Process and custom-design teams choose candidate knobs.
3. The split table defines baselines, hypotheses, and legal split hierarchy.
4. The run table captures lot, sublot, wafer, and revision execution details.
5. The response table records measurements, design impacts, and keep/drop decisions.
6. Architecture and custom-design teams down-select the winning process option set.

## Sample Interpretation

Example:

- `spacer_thickness` at lot level may improve leakage control but slow FO4.
- `contact_cd` at wafer level may reduce `Rcontact` and improve timing, but increase variability risk.
- `lowk_k` at lot level may reduce BEOL capacitance, but hurt reliability or integration margin.

Those are exactly the kinds of tradeoffs the split tables are meant to capture.

## Files In This Directory

- [split_table_template.csv](split_table_template.csv)
- [split_run_template.csv](split_run_template.csv)
- [split_response_template.csv](split_response_template.csv)

## References

These references anchor the methodology and terminology:

- [Synopsys DTCO Solutions](https://www.synopsys.com/manufacturing/tcad/dtco.html)
- [Design technology co-optimization towards sub-3 nm technology nodes](https://www.jos.ac.cn/en/article/doi/10.1088/1674-4926/42/2/020301)
- [Split-Lot Designs: Experiments for Multistage Batch Processes](https://www.tandfonline.com/doi/abs/10.1080/00401706.1998.10485195)
- [Noise and Learning in Semiconductor Manufacturing](https://doi.org/10.1287/mnsc.41.1.31)
- [VisualFab Workbench for Process Experiments](https://www.cogenda.com/article/VisualFab)

