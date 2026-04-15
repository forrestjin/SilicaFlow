# Custom Layout

Custom layout databases for hand-crafted blocks.

## Supported Formats

- GDS II (`.gds`, `.gds2`) — primary layout exchange format
- LEF (`.lef`) — abstract for digital PnR integration
- DEF (`.def`) — placed/routed custom blocks
- OpenAccess (via tool-specific flows)

## Layout Checklist (per block)

- [ ] DRC clean against process design rules
- [ ] LVS clean against schematic netlist
- [ ] Antenna rule clean
- [ ] Density fill applied
- [ ] Pin access verified for digital integration
- [ ] LEF abstract generated and validated
