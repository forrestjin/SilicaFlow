# Custom Layout

Custom layout databases for hand-crafted blocks.

## Supported Formats

- GDS II (`.gds`, `.gds2`) — primary layout exchange format
- LEF (`.lef`) — abstract for digital PnR integration
- DEF (`.def`) — placed/routed custom blocks
- OpenAccess (via tool-specific flows)

## Tapeout Support Artifacts

- [testline_design.md](testline_design.md) — scribe-line / kerf-line monitor strategy for tapeout
- [testline_content_template.csv](testline_content_template.csv) — sample content and ownership manifest

## Layout Checklist (per block)

- [ ] DRC clean against process design rules
- [ ] LVS clean against schematic netlist
- [ ] Antenna rule clean
- [ ] Density fill applied
- [ ] Pin access verified for digital integration
- [ ] LEF abstract generated and validated

## Tapeout Checklist (scribe line / testline)

- [ ] Testline content fits within foundry scribe and seal-ring constraints
- [ ] Probe pads and routing match intended wafer-sort access assumptions
- [ ] PCM and reliability monitors have named consumers and correlation goals
- [ ] Testline additions do not compromise dicing, seal ring, or die integrity
