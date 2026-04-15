# Custom Design

Custom design covers activities outside the standard automated digital ASIC flow:
technology co-optimization, custom/analog schematics, manual layout, circuit simulation,
parasitic extraction, and library characterization.

## Directory Structure

```
custom/
├── technology/          — DTCO/STCO options, process corners, custom device models
│   ├── process_options/ — Process option files and DTCO exploration configs
│   ├── device_models/   — Custom device SPICE models (beyond standard PDK)
│   └── README.md
├── schematic/           — Custom block schematics (analog, memory, IO, custom logic)
│   └── README.md
├── layout/              — Custom layout databases (GDS, OA, LEF/DEF for hard macros)
│   └── README.md
├── simulation/          — Circuit-level simulation configs and stimulus
│   ├── testbenches/     — SPICE testbenches
│   ├── corners/         — PVT corner definitions for circuit sim
│   └── README.md
├── characterization/    — Library re-characterization and extraction configs
│   ├── templates/       — Characterization templates (CCS, ECSM, NLDM)
│   ├── extraction/      — Parasitic extraction rule decks and configs
│   └── README.md
└── README.md            — This file
```

## Relationship to Digital Flow

Custom blocks are designed, simulated, and verified independently, then integrated
into the digital flow as hard macros (LEF/GDS + Liberty timing models). The handoff
points are:

- **Custom → Digital synthesis**: Liberty (.lib) timing/power models
- **Custom → Digital PnR**: LEF abstracts + GDS for merge
- **Custom → Digital LVS**: GDS + CDL/netlist for full-chip LVS
- **Custom → Digital STA**: Liberty models with all PVT corners

## Human Gate

Custom design has its own milestone gate (**G2b: Custom Freeze**) that must be
approved before custom blocks can be integrated into the digital backend.
This gate verifies that all custom blocks pass DRC, LVS, circuit simulation
across corners, and have characterized Liberty models.
