# Library Characterization

Re-characterization of custom blocks into Liberty timing/power models.

## Subdirectories

- `templates/` — Characterization templates (timing arcs, power tables)
- `extraction/` — Parasitic extraction configs and rule decks

## Characterization Flow

1. **Extract parasitics** from custom layout (QRC, StarRC, or open-source xschem+magic)
2. **Run circuit simulation** across PVT corners with extracted parasitics
3. **Characterize** into Liberty format (CCS, ECSM, or NLDM models)
4. **Validate** Liberty models against golden SPICE simulation
5. **Deliver** .lib files to digital flow for synthesis and STA

## Model Types

| Model | Accuracy | Use Case |
|-------|----------|----------|
| NLDM | Low | Quick estimation, early architecture |
| CCS | High | Production signoff timing |
| ECSM | High | Production signoff timing (alternative) |

## Tools

| Stage | Open-Source | Commercial |
|-------|-----------|------------|
| Extraction | magic (parasitic extraction) | Synopsys StarRC, Cadence QRC |
| Characterization | libretto (experimental) | Cadence Liberate, Synopsys SiliconSmart |
| Validation | ngspice | Spectre, HSPICE |
