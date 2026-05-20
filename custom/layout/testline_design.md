# Testline Design

This note documents how SilicaFlow treats testline design at tapeout. In this context, "testline" means the scribe-line, kerf-line, or frame-region structures that travel with the product masks and support wafer-level process control, wafer acceptance, reliability screening, and early yield diagnosis.

## Purpose

Testline design is the tapeout-time design of manufacturing observability around the die. Its job is to provide monitor structures that help answer:

1. Is the wafer process in control?
2. Which wafers, lots, or reticles are abnormal?
3. Are failures likely coming from devices, contacts, BEOL, lithography, CMP, or probing?
4. Does the wafer qualify for continued package investment?
5. How well do scribe-line measurements correlate with real product behavior?

Testline design is not a replacement for product test or DFT. It is a complementary monitor layer.

## Scope

SilicaFlow places testline design under `custom/layout/` because it is fundamentally a tapeout-layout concern with strong ties to:

- process technology and PCM strategy
- seal ring and dicing geometry
- wafer sort probing
- reliability monitors
- yield-learning workflows

It must be reviewed before `G4: tapeout`.

## Typical Testline Content

Common classes of structures include:

- transistor PCM monitors for `Vt`, `Idlin`, `Idsat`, and leakage
- contact and via chains
- serpentine and comb structures for metal resistance and capacitance
- lithography, CD, and overlay monitors
- ring oscillators or simple path-delay monitors
- SRAM or bitcell monitors where supported by area and foundry rules
- electromigration, TDDB, or other wafer-level reliability structures
- dedicated probe pads and routing for parametric access

Not every tapeout needs all of these. The right set depends on the process node, product risk, foundry offering, and characterization plan.

## Design Principles

### 1. Isolation From Product Die

Testline structures must be electrically and physically isolated from product circuitry. They must not disturb die operation, pad ring integrity, seal ring behavior, or dicing robustness.

### 2. Scribe-Line Reality

The scribe or kerf region is small. Testline content must fit within:

- foundry scribe-width rules
- seal-ring keepout
- saw or laser dicing margins
- overlay and alignment requirements

Do not treat the testline as free area.

### 3. Probeability

Probe pads and routing must be designed for real wafer-sort use:

- consistent pad pitch and orientation
- acceptable scrub and probe-force assumptions
- controlled access direction
- minimal risk of pad damage or adjacent structure coupling

### 4. Correlation, Not Blind Faith

Scribe-line structures are indicators, not perfect surrogates for full-die behavior. A good testline plan explicitly identifies which product-level concerns each structure is meant to correlate with.

### 5. Release Ownership

Testline content should be cross-functional:

- process integration chooses meaningful PCM and module monitors
- physical/layout owners ensure tapeout-safe geometry
- silicon-test and product engineering define how data will be consumed
- quality/reliability owners decide whether added reliability structures are needed

## Recommended SilicaFlow Artifacts

- `custom/layout/testline_design.md` — this note and release rationale
- `custom/layout/testline_content_template.csv` — content and ownership manifest
- links to wafer-sort, yield, and reliability consumers under `silicon_test/`

## Sample Review Questions

Before tapeout, SilicaFlow expects the team to answer:

- Which structures are for process control versus yield debug versus reliability?
- Are the structures representative of actual product layers and pattern sensitivities?
- Do the pads and routes match realistic wafer-sort probing assumptions?
- Is the seal ring and scribe geometry still compliant after inserting the structures?
- Which product metrics are expected to correlate to each testline structure?
- Who owns data review after first silicon?

## Relationship To Other Flow Layers

- Product: testline content should support outgoing quality goals and wafer acceptance strategy.
- Architecture: timing or SRAM monitors should reflect the product's real performance risks.
- Custom technology: DTCO/STCO may require dedicated monitors to evaluate process options.
- Physical: seal ring, pad ring, dicing margin, and tapeout assembly must remain safe.
- Silicon test: wafer sort, binning, and yield analytics consume testline data heavily.

## Files In This Directory

- [testline_content_template.csv](testline_content_template.csv)

## References

These references anchor the concepts and constraints described here:

- [SWTest 2021: Parametric Test Structures and Probing Process Attributes](https://www.swtest.org/library/2021proc/pdf/t02_01_palumbo_swtest_2021.pdf)
- [SWTest 2012: Parametric Testing / scribe-line PCM discussion](https://www.swtest.org/swtw_library/2012proc/PDF/S03_01_Levy_SWTW2012.pdf)
- [NIST: metrology challenges and scribe-line correlation](https://nvlpubs.nist.gov/nistpubs/jres/112/1/V112.N01.A02.pdf)
- [NASA/JPL ASIC part acceptance and wafer acceptance](https://parts.jpl.nasa.gov/asic/Sect.4.1.html)
- [NASA NEPP: scribe-line testing and inline monitoring](https://nepp.nasa.gov/docs/etw/2024/2024-06-06-Thur/1000-Porter-Prevention-CL24-2778.pdf)

