# Prompt: CDC Review

## Task
Review clock domain crossing analysis results and classify each crossing by synchronization adequacy.

## Inputs
- **CDC report**: `reports/cdc/report.json` + raw tool log
- **RTL source**: `design/rtl/` (to inspect synchronizer implementations)
- **Clock strategy**: from architecture docs or SDC (clock domains, relationships)

## Outputs (Markdown format)
1. **Crossing table**: columns = Source Clock, Dest Clock, Signal, Synchronizer Type, Status (safe/unsafe/missing)
2. **Violation list**: crossings without adequate synchronization
3. **Recommended fixes**: specific synchronizer insertion or protocol change per violation

## Validation
- `make cdc` — zero unwaived violations after fixes
- Every crossing has a documented synchronization strategy
- Multi-bit crossings use gray coding or handshake protocols

## Worked Example
Crossing: `clk_a → clk_b : data_valid` — single-bit, no synchronizer
Fix: "Add 2-FF synchronizer in `design/rtl/cdc_sync.sv`"

## Linkage
- Receives from → `make cdc` output
- Outputs feed → `spec_to_rtl.md` (synchronizer insertion)
- Gate: **G2 (rtl_freeze)** — CDC must be clean before gate approval
