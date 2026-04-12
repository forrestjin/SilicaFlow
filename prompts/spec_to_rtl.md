# Prompt: Spec to RTL

## Task
Turn a bounded spec section into synthesizable SystemVerilog RTL and local assertions, following the project's coding conventions.

## Inputs
- **Spec excerpt**: the specific micro-architecture section to implement (Markdown or text)
- **Existing modules**: current RTL under `design/rtl/` (for interface consistency)
- **Filelist**: `design/filelists/rtl.f` (to understand module hierarchy)
- **Interface contracts**: from `architecture/interfaces/` (signal names, widths, protocols)
- **Coding conventions**: SystemVerilog, no latches, explicit reset, `_i`/`_o` port suffixes

## Outputs
1. **RTL patch**: one new or modified `.sv` file under `design/rtl/`
2. **Assertion patch**: one new or modified `.sv` file under `design/formal/` (if applicable)
3. **Filelist update**: additions to `design/filelists/rtl.f` and `formal.f`
4. **Assumptions list**: things assumed but not stated in the spec — must be surfaced, not guessed

## Validation
- `make lint` — zero errors
- `make parse` — clean elaboration
- `make sim` — existing tests still pass
- No latches, no incomplete case, no width mismatches
- All ports use `_i`/`_o` suffix convention

## Worked Example
Spec: "Add a 4-deep FIFO between the ingress parser and the pipeline"
Output: `design/rtl/ingress_fifo.sv` — parameterized sync FIFO with valid/ready handshake
Assertion: `design/formal/ingress_fifo_properties.sv` — FIFO never overflows, never underflows, data integrity
Assumption: "FIFO depth of 4 assumes worst-case back-pressure of 3 cycles — verify with Architecture agent"

## Linkage
- Receives from → `architecture_tradeoff.md` (chosen architecture)
- Outputs feed → Verification agent (new module needs testbench)
- Outputs feed → `timing_triage.md` (if new logic creates timing paths)
