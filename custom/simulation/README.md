# Circuit Simulation

SPICE-level simulation for custom blocks.

## Subdirectories

- `testbenches/` — SPICE testbench files
- `corners/` — PVT corner definitions

## Simulation Types

| Type | Purpose | Tool Examples |
|------|---------|---------------|
| DC | Operating point, bias verification | ngspice, Spectre, HSPICE, Xyce |
| AC | Frequency response, stability | ngspice, Spectre, HSPICE |
| Transient | Time-domain behavior, switching | ngspice, Spectre, HSPICE, Xyce |
| Monte Carlo | Process variation sensitivity | Spectre, HSPICE |
| Noise | Noise figure, phase noise | Spectre, HSPICE |
| Reliability | HCI, NBTI, EM stress analysis | Spectre, RelXpert, MOSRA |

## Corner Definitions

Standard PVT corners should be defined in `corners/` as YAML files:
```yaml
corner_name: tt_25c_0p9v
process: typical
voltage: 0.9
temperature: 25
models: [tt]
```
