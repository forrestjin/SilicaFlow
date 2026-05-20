# Wafer Binning In ASIC Silicon Test

This note documents wafer binning for SilicaFlow's silicon-test layer. Operationally, wafer binning happens at electrical wafer sort or wafer probe, before singulation, package assembly, and final test. It still belongs in the silicon-test body of knowledge because it is the main decision layer that connects wafer-level measurements to die disposition, package cost, KGD strategy, yield learning, and production quality.

Tool examples and standards references in this note were checked on May 20, 2026.

## Why It Matters

Wafer binning decides which die:

- are scrapped immediately
- are re-probed or retested
- are sent to package
- are downgraded into lower-value SKUs
- qualify for speed or power grades
- qualify for known good die (KGD) or advanced package integration

For advanced ASICs, chiplets, and expensive substrates, this is a major economic control point. If bad die are packaged, downstream scrap and field risk go up. If good die are over-screened, yield and margin go down.

## Theory

### 1. Classification Under Uncertainty

Each die has an unknown true state. Wafer sort only observes that state through imperfect measurements:

- scan and ATPG outcomes
- MBIST/BISR status
- functional vectors
- leakage and supply current
- timing or frequency margin
- analog trims and calibration windows
- temperature and voltage behavior

Wafer binning is the rule set that maps those measurements into a disposition. In other words, it is a classification problem with manufacturing noise, tester noise, probe-contact effects, and process variation in the loop.

### 2. False Pass Versus False Fail

The central tradeoff is:

- false pass: a bad die is shipped or packaged
- false fail: a good die is scrapped or downgraded

This is why binning is not just pass/fail logic. It is a quality, yield, and cost optimization problem.

### 3. Hard Bins And Soft Bins

Industry practice commonly separates:

- soft bins: logical or diagnostic categories such as `scan_fail`, `mbist_unrepaired`, `speed_bin_b`, `contact_suspect`, or `iddq_outlier`
- hard bins: factory disposition categories such as `scrap`, `reprobe`, `package`, `kgd_hold`, or `route_to_sku_c`

Many soft bins can map to a single hard bin. The soft bins preserve diagnosis value. The hard bins drive physical disposition at the prober, handler, MES, or OSAT handoff.

### 4. Guardbands, Screens, And Outliers

Production binning limits are usually tighter than the public datasheet. Mature ASIC flows add:

- internal guardbands
- temperature or voltage corner screening
- speed and power grading
- parametric outlier screens
- part average testing (PAT) for automotive or high-reliability products

This is one reason automotive guidance such as AEC-Q001, Q002, Q004, and Q100-009 matters for ASIC programs with strict DPPM goals.

### 5. Spatial Correlation

Wafer failures are not spatially random. Common patterns include:

- edge rings
- center hot spots
- scribeline or reticle effects
- scratches and contamination
- probe-card contact signatures
- CMP or lithography process gradients

Because of that, wafer maps, stacked wafer analysis, and die genealogy are core binning tools, not just reporting artifacts.

## Standard ASIC Practice

### Test Content Used At Wafer Sort

For digital ASICs and SoCs, the typical content is:

- scan and compressed ATPG
- transition or at-speed testing
- MBIST and BISR/BIRA outcomes
- limited functional tests that are probe-feasible
- DC parametrics such as leakage and static current
- clocking, reset, and access sanity checks
- analog or mixed-signal trims where applicable

The exact balance depends on:

- probe time budget
- package cost
- DFT architecture
- product reliability target
- whether the die may be shipped as KGD

### Typical Decision Flow

1. A prober steps across the wafer and contacts each die.
2. ATE runs the wafer-sort program.
3. The test program classifies failures and measurements into soft bins.
4. Soft bins are mapped into hard bins for disposition.
5. Selected contact-suspect bins may be re-probed.
6. Good die move to package, advanced-package assembly, or KGD inventory.
7. Wafer maps, STDF-like data, and diagnosis outputs feed yield learning.

### Common Bin Categories In ASIC Programs

The exact numbering is product-specific, but mature programs often keep separate categories for:

- contact or probe issue suspected
- scan fail
- transition or path-delay fail
- MBIST repaired pass
- MBIST unrepaired fail
- leakage or current outlier
- analog trim out of range
- speed grade A/B/C
- low-power premium grade
- engineering hold
- KGD candidate

The point is not the exact labels. The point is to preserve enough resolution to separate yield loss, tester artifacts, contact issues, and true design/process failures.

### Reprobe Policy

Standard practice is to reprobe only narrow, evidence-based categories such as suspected contact failures. Overusing reprobe destroys diagnosis value and can wash real defect signatures out of the dataset.

Typical reprobe candidates:

- open-contact signatures
- unstable continuity results
- obvious pad contamination or touchdown issues
- first-touch anomalies on newly qualified probe hardware

Typical non-reprobe candidates:

- repeatable scan fails
- stable leakage outliers
- memory repair exhaustion
- repeatable speed failures

### Correlation To Final Test

Wafer binning should never be managed in isolation. Good practice requires correlation between:

- wafer sort bins
- package final test bins
- burn-in fallout
- characterization data
- RMA or field-return signatures
- failure analysis results

Without that loop, teams cannot tell whether screening is too loose, too aggressive, or simply misclassifying failures.

## Industry Standard Expectations

### 1. DFT-Driven Binning

Good binning quality starts with good testability. Standard ASIC expectations include:

- high stuck-at and transition coverage
- meaningful diagnosis support
- memory test and repair visibility
- at-speed coverage where performance matters
- cell-aware or defect-oriented methods where justified

Wafer binning cannot compensate for weak DFT.

### 2. Automotive And Zero-Defect Programs

For automotive ASICs, binning is usually tied to:

- AEC-Q001 Part Average Testing
- AEC-Q002 Statistical Yield Analysis
- AEC-Q004 Zero Defects framework
- AEC-Q100-009 Electrical Distribution Assessment

In practice this means:

- statistically justified test limits
- stronger outlier detection
- lot and wafer abnormality detection
- more discipline around bin drift and yield excursions

### 3. KGD And Advanced Package Flows

KGD and known good wafer flows are stricter than ordinary wafer sort because package rework is limited or impossible in:

- SiP and MCM assemblies
- chiplet integration
- expensive fan-out or 2.5D/3D packages
- aerospace, defense, or medical high-reliability modules

In these flows, teams often add:

- stronger wafer-level screening
- tighter parametric limits
- high-temperature screening or equivalent qualification screens
- stronger die traceability into assembly

### 4. Data Standards And Traceability

Common practice today is:

- STDF remains widely used in production test data exchange
- wafer and substrate map traceability rely on SEMI mapping standards such as E142
- newer data infrastructures are moving toward richer, more real-time models such as SEMI RITdb for adaptive and streaming test data

For SilicaFlow, the practical lesson is that wafer binning is a data-management problem as much as a test-program problem.

### 5. Diagnosis And Yield Learning

Modern ASIC teams do not stop at bin paretos. They use diagnosis and analytics to connect binning outcomes to likely root causes:

- systematic scan yield limiters
- contact or interface noise
- layout-sensitive defects
- process excursions
- package-sensitive fallout
- test-program drift

This is why volume diagnosis and yield-learning platforms from Siemens, Synopsys, NI, OSAT analytics stacks, and internal data pipelines are standard companions to wafer binning.

## Speed Binning, Power Binning, And Repair Binning

### Speed Binning

Some ASICs are sold into multiple frequency grades. At wafer sort or final test, die may be separated into speed bins based on:

- measured pass frequency
- at-speed pattern margin
- voltage-frequency shmoo behavior
- temperature-corner margin

Speed binning should be based on tested margin and business intent, not just an optimistic single-corner result.

### Power And Leakage Binning

Premium low-power or thermally constrained SKUs may use additional binning for:

- standby leakage
- active power proxies
- IDDQ or ICC distribution tails
- thermal-sensitive performance behavior

### Repair Binning

Embedded memories often produce repair-aware bins such as:

- pass with no repair used
- pass with spare rows or columns consumed
- fail because repair budget exhausted

That separation matters because repaired-pass units can still be useful for yield but may need tighter tracking depending on the product class.

## What Good Wafer Binning Looks Like

A strong wafer-binning methodology for ASICs has these characteristics:

- bin definitions are intentional and documented
- contact issues are separated from real device failures
- soft bins preserve diagnosis value
- hard bins match actual manufacturing disposition
- reprobe is tightly controlled
- guardbands are justified by data, not folklore
- outlier screens are validated against downstream quality
- wafer maps and stacked-wafer views are reviewed routinely
- final-test and field data feed back into bin policy
- KGD rules are stricter than basic commercial sort

## Common Failure Modes In Binning Programs

- using only a generic fail bin
- letting probe-card issues corrupt device-yield data
- making speed grades from insufficient corner coverage
- over-screening and silently losing good yield
- under-screening and creating quality escapes
- failing to correlate wafer sort with package final test
- allowing bin number churn without version control
- keeping test limits outside formal review control

## Recommended SilicaFlow Usage

SilicaFlow should keep wafer-binning artifacts primarily under `silicon_test/yield_reliability/`, with cross-links from DFT, ATPG, characterization, and package handoff when needed.

Recommended artifacts:

- bin definition table with version history
- soft-bin to hard-bin mapping
- reprobe policy
- speed or power grade definitions
- PAT and outlier-screen configuration
- wafer map reviews and stacked-wafer summaries
- sort-to-final-test correlation studies
- KGD qualification rule set if applicable

Recommended filenames:

- `silicon_test/yield_reliability/wafer_binning_policy.md`
- `silicon_test/yield_reliability/bin_map.csv`
- `silicon_test/yield_reliability/sort_to_final_test_correlation.md`
- `silicon_test/yield_reliability/pat_limits.csv`

## Relationship To Other SilicaFlow Layers

- Product: wafer binning must align with shipped SKU definitions and outgoing quality targets.
- Architecture: speed and power grades must reflect real product segmentation, not just test convenience.
- Design and verification: DFT architecture and fault coverage strongly constrain what binning can detect.
- Physical: systematic fail bins often need layout-aware diagnosis and timing/power correlation.
- Package: KGD and advanced package flows need stronger binning and traceability.
- Silicon test: owns the operational bin policy, analytics loop, and production disposition logic.

## References

Official references used to anchor this note:

- [NI: Reducing Quality Escapes in Semiconductor Manufacturing](https://www.ni.com/en/solutions/semiconductor/enterprise-data-management-analytics/reducing-quality-escapes-manufacturing.html)
- [NI: Lifecycle Analytics](https://www.ni.com/en/solutions/lifecycle-analytics.html)
- [Advantest: Prober](https://www.advantest.com/en/products/component-test-system/prober/)
- [SEMI: Improving Test Data Communication Focus of CAST](https://www.semi.org/en/blogs/semi-news/improving-test-data-communication-focus-of-semi-collaborative-alliance-for-semiconductor-test-sig)
- [SEMI E142: Specification for Substrate Mapping](https://store-us.semi.org/products/e14200-semi-e142-specification-for-substrate-mapping)
- [AEC Documents](https://www.aecouncil.com/AECDocuments.html)
- [Siemens Tessent YieldInsight](https://eda.sw.siemens.com/en-US/products/ic/tessent/yield-learning/yieldinsight/)
- [Synopsys TestMAX Diagnosis](https://www.synopsys.com/implementation-and-signoff/test-automation/testmax-diagnosis.html)
- [TI Die and Wafer Services](https://www.ti.com/die-wafer-services/overview.html)
- [Infineon Wafer and Die Memory Solutions](https://www.infineon.com/products/memories/wafer-die-memory-solutions)
