# Technology

Process technology artifacts for custom design.

## Subdirectories

- `process_options/` — DTCO/STCO exploration configs, process option comparisons
- `device_models/` — Custom device SPICE models beyond standard PDK offerings

## DTCO Split Tables

Use split tables to connect process options to device, circuit, and design consequences.

- [dtco_split_table.md](dtco_split_table.md) — methodology note and field guidance
- [split_table_template.csv](split_table_template.csv) — factor-definition and hypothesis table
- [split_run_template.csv](split_run_template.csv) — lot/sublot/wafer execution traceability
- [split_response_template.csv](split_response_template.csv) — measured outcomes and keep/drop decisions

## DTCO/STCO Workflow

Design-Technology Co-Optimization (DTCO) and System-Technology Co-Optimization (STCO)
iterate between process options and design targets:

1. Define PPA targets from architecture budgets
2. Evaluate process options (Vt flavors, metal stacks, device variants)
3. Run circuit simulation across options
4. Feed results back to architecture for tradeoff decisions
5. Lock process options before custom design begins

## Artifacts

| File | Description |
|------|-------------|
| `process_options/*.yaml` | Process option definitions (Vt, metal stack, etc.) |
| `device_models/*.spice` | Custom device SPICE models |
| `device_models/*.scs` | Spectre-format device models |
| `split_table_template.csv` | DTCO factor definition and split manifest |
| `split_run_template.csv` | DTCO experiment execution and revision traceability |
| `split_response_template.csv` | DTCO measured responses and decisions |
| `dtco_split_table.md` | DTCO split-table methodology note |
