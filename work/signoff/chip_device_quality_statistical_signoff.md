---
title: Statistical Methods in Chip and Device Quality Signoff
status: draft
date: 2026-05-30
tags:
  - statistics
  - semiconductor-quality
  - signoff
  - silicon-validation
  - reliability
  - manufacturing-test
  - STA
---

# Statistical Methods in Chip and Device Quality Signoff

## Purpose

This note summarizes where statistics is used in chip/device quality signoff. It is intentionally broader than STA and timing signoff. It covers pre-silicon timing and circuit validation, process control, manufacturing test, outlier screening, reliability qualification, package qualification, ESD/latch-up, soft-error rate, automotive functional safety, and field quality monitoring.

A good mental model is:

```text
Chip quality signoff = deterministic specs
                     + statistical evidence
                     + physics-based extrapolation
                     + production controls
                     + field feedback.
```

A single statement such as:

```text
3000 Monte Carlo samples passed.
```

is useful evidence, but it is not a complete quality signoff by itself.

---

# 1. Three Core Statistical Questions

Most semiconductor quality-signoff arguments reduce to three statistical questions.

## 1.1 How many bad parts might escape?

This is usually a **binomial**, **Poisson**, or **defect-rate** problem.

Examples:

```text
0 failures in 1000 SPICE Monte Carlo runs
0 failures in 77 HTOL samples
5 rejects in 1,000,000 final-test units
2 RMAs from 10,000,000 shipped units
```

For a pass/fail experiment with true failure probability `p`, the probability of seeing zero failures in `N` independent samples is:

\[
P(0\ failures) = (1-p)^N
\]

For zero observed failures, the one-sided 95% upper bound on failure probability is:

\[
p_{upper} = 1 - 0.05^{1/N}
\]

For large `N`, this is approximately:

\[
p_{upper} \approx \frac{3}{N}
\]

This approximation is often called the **rule of three**.

| Result | Approximate 95% upper bound on failure rate |
|---:|---:|
| 0 / 1,000 fail | `< 0.3%` |
| 0 / 3,000 fail | `< 0.1%` |
| 0 / 10,000 fail | `< 0.03%` |
| 0 / 100,000 fail | `< 30 ppm` |
| 0 / 10,000,000 fail | `< 0.3 ppm` |

Important implication:

```text
0 failures observed does not mean 0 failure probability.
```

## 1.2 What fraction of the population is inside spec?

This is a **population coverage** or **tolerance interval** problem.

Example statements:

```text
With 95% confidence, at least 99.9% of devices meet the Vmin spec.
With 95% confidence, at least 99% of PLL jitter values are below the limit.
With 90% confidence, 99.73% of latch setup times are within the characterized cap.
```

This is not the same as a confidence interval on the mean.

A confidence interval on the mean answers:

```text
Where is the average likely to be?
```

A tolerance interval answers:

```text
Where are individual devices likely to fall?
```

For chip signoff, tolerance intervals are often more relevant than mean confidence intervals because customers receive individual devices, not the population average.

## 1.3 How does accelerated stress map to field lifetime?

This is a **reliability modeling** and **acceleration model** problem.

Examples:

```text
HTOL at high temperature maps to 10 years at use condition.
HAST maps to humidity-related failure risk.
TDDB stress at high voltage maps to oxide lifetime at nominal voltage.
Electromigration stress at high current maps to field lifetime.
Temperature cycling maps to solder/package fatigue lifetime.
```

Typical acceleration models include:

```text
Arrhenius: temperature acceleration
Eyring: temperature plus another stress
Peck: humidity and temperature
Black's equation: electromigration
Voltage acceleration: TDDB / oxide / dielectric wearout
Coffin-Manson: thermal cycling fatigue
```

A stress-test result is only meaningful if the acceleration model matches the actual failure mechanism.

---

# 2. Useful Statistical Formulas and Rules of Thumb

## 2.1 Zero-failure binomial upper bound

For `N` independent samples and zero observed failures:

\[
p_{upper, CL} = 1 - (1-CL)^{1/N}
\]

For 95% confidence:

\[
p_{upper,95\%} = 1 - 0.05^{1/N} \approx \frac{3}{N}
\]

Examples:

```text
N = 1000, 0 fails  -> p_upper ≈ 0.003 = 0.3%
N = 3000, 0 fails  -> p_upper ≈ 0.001 = 0.1%
```

For nonzero failures, use an exact binomial interval, commonly Clopper-Pearson, or a justified Bayesian interval.

## 2.2 Probability of seeing at least one tail sample

If a one-sided tail event has probability `p_tail`, then the probability of seeing at least one such event in `N` independent samples is:

\[
P(\ge 1\ tail\ sample) = 1 - (1-p_{tail})^N
\]

To get a confidence `CL` of observing at least one tail event:

\[
N \ge \frac{\ln(1-CL)}{\ln(1-p_{tail})}
\]

For one-sided normal tails:

| Target tail | One-sided tail probability | Samples for ~95% chance to see at least one tail sample |
|---:|---:|---:|
| 3 sigma | `1.35e-3` | `~2,218` |
| 4 sigma | `3.17e-5` | `~94,600` |
| 5 sigma | `2.87e-7` | `~10.45 million` |

Important implication:

```text
3000x Monte Carlo is not a 5-sigma proof.
```

It gives useful visibility around the 3-sigma regime, depending on the metric, distribution, and pass/fail criterion.

## 2.3 Sigma equivalence from zero-fail data

If `N` samples produce zero failures, the approximate 95% upper-bound failure probability is `3/N`. If that probability is mapped to a one-sided normal tail, the approximate sigma-equivalent is:

| MC samples | Failures | 95% upper-bound fail rate | One-sided sigma-equivalent, approximate |
|---:|---:|---:|---:|
| 1,000 | 0 | `0.3%` | `~2.75 sigma` |
| 2,000 | 0 | `0.15%` | `~2.97 sigma` |
| 3,000 | 0 | `0.1%` | `~3.09 sigma` |
| 10,000 | 0 | `0.03%` | `~3.43 sigma` |
| 100,000 | 0 | `0.003%` | `~4.01 sigma` |
| 10,000,000 | 0 | `0.00003%` | `~5 sigma` |

This equivalence assumes a one-sided normal tail. Many real silicon distributions are skewed, truncated, multimodal, correlated, or non-Gaussian.

## 2.4 Process capability

For a stable, approximately normal process:

\[
C_p = \frac{USL-LSL}{6\sigma}
\]

\[
C_{pk} = \min\left(\frac{USL-\mu}{3\sigma}, \frac{\mu-LSL}{3\sigma}\right)
\]

Where:

```text
USL = upper specification limit
LSL = lower specification limit
mu  = process mean
sigma = process standard deviation
```

Useful interpretation:

```text
Cpk = 1.00 -> nearest spec is 3 sigma away
Cpk = 1.33 -> nearest spec is about 4 sigma away
Cpk = 1.67 -> nearest spec is about 5 sigma away
Cpk = 2.00 -> nearest spec is about 6 sigma away
```

Cpk is meaningful only if the process is stable and the statistical assumptions are reasonable.

## 2.5 Reliability life-test failure-rate bound

For reliability tests, total equivalent device-hours are often computed as:

\[
T_{eq} = \sum_i N_i \cdot t_i \cdot AF_i
\]

Where:

```text
N_i = number of devices in stress condition i
t_i = stress duration for condition i
AF_i = acceleration factor from stress condition to use condition
```

For zero failures and a constant failure-rate model, the 95% upper bound on failure rate is approximately:

\[
\lambda_{upper} \approx \frac{3}{T_{eq}}
\]

If failure rate is reported in FIT:

\[
FIT = \lambda \cdot 10^9\ device\ hours
\]

Important implication:

```text
0 failures in HTOL does not mean 0 FIT.
It gives an upper confidence bound based on equivalent device-hours.
```

---

# 3. Pre-Silicon Statistical Signoff

## 3.1 STA and variation-aware timing

Traditional timing signoff starts with deterministic checks:

```text
slow-corner setup
fast-corner hold
clock uncertainty
RC corners
SI/crosstalk
IR-aware timing
aging
```

Modern timing signoff also uses statistical or semi-statistical variation models:

```text
OCV
AOCV
POCV
SOCV
LVF
sigma-based setup/hold constraints
statistical slack adjustment
correlation-aware clock/data variation
```

Questions answered by statistical timing models:

```text
How much delay variation should be added to the path?
How correlated are launch and capture clocks?
How correlated are common datapath segments?
How much pessimism should be removed through CPPR?
What sigma target is represented by the setup/hold model?
Does the path remain clean across local and global variation?
```

For latch borrowing, statistical timing directly affects values such as:

```text
actual time borrow
statistical adjustment
time given to startpoint
time borrowed from endpoint
available borrow at endpoint
```

Key signoff point:

```text
Positive STA slack is valid only inside the characterized timing model.
```

If a latch, dynamic circuit, or custom macro is used beyond its characterized region, positive slack may be misleading.

## 3.2 Liberty variation modeling and LVF

Liberty Variation Format, or LVF, adds statistical information to library arcs, including:

```text
delay sigma
transition sigma
setup/hold constraint sigma
moment-based or non-Gaussian variation terms, depending on methodology
```

LVF-related signoff questions:

```text
How many SPICE Monte Carlo samples were used per arc?
Were low-voltage and near-threshold tails characterized?
Are setup/hold distributions Gaussian or skewed?
Are tables smooth and monotonic across slew/load?
Was LVF validated against direct SPICE MC?
Are dynamic/pulsed-latch arcs modeled over the actual operating window?
```

This is especially important for dynamic latches and pulsed latches because the timing behavior near the closing edge or pulse edge can be nonlinear.

## 3.3 SPICE Monte Carlo for custom and dynamic circuits

SPICE Monte Carlo is commonly used for:

```text
custom dynamic latches
pulsed latches
sense amplifiers
SRAM bitcells
PLL/DLL circuits
bandgaps and references
ADC/DAC mismatch
level shifters
IO receivers
ESD clamp triggers
analog comparators
```

Randomized parameters may include:

```text
Vth mismatch
channel length/width variation
mobility variation
oxide thickness variation
local device mismatch
resistor/capacitor mismatch
parasitic variation, if modeled
```

For a dynamic latch, MC may be used to characterize:

```text
minimum safe write/evaluate time
setup time distribution
hold time distribution
clock-to-Q distribution
retention time distribution
keeper contention sensitivity
charge-sharing sensitivity
safe timing-borrow window
```

Correct interpretation:

```text
1000x MC is useful for distribution shape and obvious weak tails.
3000x MC gives better but still limited tail visibility.
5-sigma claims require millions of brute-force samples or specialized high-sigma methods.
```

## 3.4 SRAM and memory-array statistics

SRAM yield is deeply statistical because a large array contains many bitcells.

Important metrics:

```text
read static noise margin
write margin
read disturb
write disturb
sense amplifier offset
bitline differential
cell leakage
Vmin distribution
fail-bit probability
array-level yield
repairability with redundancy
```

Key statistical point:

```text
A tiny per-bit failure probability can become a large array failure probability.
```

For `M` independent bits and per-bit failure probability `p`:

\[
P(array\ pass) \approx (1-p)^M
\]

For large arrays, even ppm-level bitcell failure rates can be unacceptable unless redundancy and ECC are included.

## 3.5 Analog, mixed-signal, and RF signoff

Analog and RF signoff uses statistics for parameters such as:

```text
offset
noise
jitter
phase noise
INL/DNL
gain error
bandgap/reference voltage
oscillator frequency
filter corner
ADC/DAC mismatch
PLL lock range
LDO stability margin
```

Common methods:

```text
corner simulation
Monte Carlo mismatch simulation
trim-range analysis
yield estimation
response-surface modeling
worst-case distance analysis
```

Important trap:

```text
Trimming can move the mean or compensate some spread,
but it does not eliminate all tails or all failure mechanisms.
```

## 3.6 Power integrity, EM/IR, and aging

Statistical aspects include:

```text
activity distribution
workload variation
IR-drop distribution across die/wafer/workloads
electromigration lifetime distribution
BTI/HCI aging distribution
thermal gradient distribution
mission-profile weighting
```

Key point:

```text
A design may pass timing at nominal IR drop but fail in rare high-activity or high-temperature conditions.
```

Power/timing co-signoff often needs statistical workload selection or worst-case workload justification.

---

# 4. Process, Wafer, and Yield Statistics

## 4.1 SPC and process monitoring

Foundry and fab quality are based on statistical process control.

Monitored quantities include:

```text
critical dimension, CD
overlay
film thickness
oxide thickness
sheet resistance
via/contact resistance
implant dose
Vth
Idsat
Ioff
metal resistance
defect density
```

Methods include:

```text
Xbar/R charts
I-MR charts
EWMA/CUSUM charts
control limits
process capability Cp/Cpk/Pp/Ppk
excursion detection
lot-to-lot trend analysis
wafer-map signature analysis
```

Signoff relevance:

```text
A design margin is only meaningful if the production process remains within the assumed distribution.
```

## 4.2 WAT / PCM / scribe-line statistics

Wafer Acceptance Test, Process Control Monitor, or scribe-line data measures process monitor structures.

Typical WAT/PCM measurements:

```text
Vth
Idsat
Ioff
contact resistance
via resistance
poly/metal sheet resistance
capacitor density
oxide breakdown indicators
ring oscillator frequency
leakage structures
```

Uses:

```text
wafer acceptance
lot disposition
model-to-silicon correlation
process drift detection
yield prediction
reliability-risk screening
```

Important limitation:

```text
PCM structures do not perfectly represent every product path, macro, layout context, or local variation case.
```

## 4.3 Yield modeling

Yield statistics estimate how many good dies are expected after fabrication and test.

Yield contributors:

```text
random defect yield
systematic yield loss
parametric yield loss
memory repair yield
redundancy yield recovery
lithography hotspots
layout-dependent effects
wafer-edge loss
lot excursions
package yield
```

Common analyses:

```text
Poisson yield models
negative-binomial yield models
critical-area analysis
wafer-map clustering
spatial correlation
bin yield prediction
probe-to-final-test correlation
```

Important distinction:

```text
Yield is the fraction passing test.
Quality is the fraction truly good among shipped parts.
```

High yield does not automatically mean low DPPM.

---

# 5. Manufacturing Test and Test-Escape Statistics

## 5.1 Wafer sort and final test

Production test is a statistical filter.

It attempts to reject defective or marginal units while preserving yield.

Measured or inferred quantities include:

```text
scan pass/fail
MBIST pass/fail
LBIST signature
IDDQ
leakage
Vmin
Fmax
ring oscillator speed
PLL lock
analog trims
ADC/DAC limits
IO margins
thermal sensor readings
```

Statistical questions:

```text
What is the outgoing defect level?
What is the test escape rate?
How much yield is lost by guardbanding?
Are wafer sort and final test correlated?
Are tester-to-tester differences controlled?
Do the test vectors excite the failure mechanism?
```

## 5.2 DPPM and outgoing quality

DPPM means defective parts per million shipped.

A simplified relation is:

```text
outgoing DPPM depends on:
  incoming defect population
  test coverage
  test limits
  measurement uncertainty
  guardbands
  latent failure population
```

Important trap:

```text
99.5% fault coverage does not imply 5000 DPPM.
```

Fault coverage applies to a modeled fault universe, not every real analog, timing, dynamic, reliability, or package defect.

## 5.3 Fault coverage and defect coverage

DFT signoff metrics may include:

```text
stuck-at fault coverage
transition fault coverage
path-delay fault coverage
bridging fault coverage
cell-aware test coverage
IDDQ coverage
MBIST coverage
LBIST coverage
analog test coverage
```

Key distinction:

```text
fault coverage = coverage of modeled logical/electrical faults
defect coverage = coverage of real manufacturing defects
```

The mapping from fault coverage to DPPM is statistical and model-dependent.

## 5.4 Guardbanding and measurement uncertainty

ATE measurements have uncertainty.

Sources:

```text
tester repeatability
tester-to-tester bias
probe-card/load-board variation
DUT socket variation
supply accuracy
temperature-control error
measurement noise
calibration drift
operator/site differences
```

A robust production limit should consider:

```text
measured value
measurement uncertainty
guardband
spec limit
customer use condition
```

Unsafe view:

```text
measured_value <= spec_limit
```

Safer view:

```text
measured_value + measurement_uncertainty + guardband <= spec_limit
```

or, for lower-bound specs:

```text
measured_value - measurement_uncertainty - guardband >= spec_limit
```

## 5.5 Test limits as a yield-quality tradeoff

Every test limit creates a tradeoff:

```text
tighter limit -> fewer escapes, more yield loss
looser limit  -> more yield, more escape risk
```

Statistical test-limit setting should consider:

```text
population distribution
customer spec
measurement uncertainty
process drift
lot-to-lot variation
field return history
outlier risk
screen effectiveness
```

---

# 6. Outlier Screening

## 6.1 PAT: Part Average Testing

Part Average Testing screens devices that pass datasheet limits but are statistical outliers relative to their lot or population.

Example:

```text
Datasheet leakage limit = 10 uA
Lot mean leakage        = 0.8 uA
Lot sigma               = 0.2 uA
Device leakage          = 3.0 uA
```

The device passes the datasheet limit, but it is far from the lot distribution. PAT may reject it as abnormal.

Purpose:

```text
catch latent defects
catch process outliers
reduce early-life failures
improve outgoing quality
```

## 6.2 DPAT and adaptive outlier limits

Dynamic PAT uses lot-specific or population-specific statistics to set test limits.

Typical methods:

```text
mean +/- k sigma limits
median/MAD robust limits
lot-relative limits
wafer-relative limits
site-relative limits
moving-window statistics
```

Important risk:

```text
If the lot itself is bad, purely lot-relative limits can normalize bad behavior.
```

Therefore, DPAT is often combined with absolute datasheet limits and process-control limits.

## 6.3 Multivariate outlier screening

A weak device may not be an outlier on any single parameter but may be abnormal in combination.

Methods:

```text
Mahalanobis distance
principal component analysis
clustering
nearest-neighbor methods
good-die-bad-neighborhood analysis
statistical bin limits
statistical yield limits
machine-learning anomaly detection
```

Example:

```text
Leakage: normal
Vmin: normal
Fmax: normal
IDDQ: normal
Combined vector: unusual
```

Multivariate screens can identify latent-risk devices that simple one-dimensional limits miss.

## 6.4 Wafer-neighborhood and spatial statistics

Many defects are spatially correlated.

Wafer-map analyses include:

```text
edge effects
center effects
radial gradients
scratch signatures
clustered fails
site-to-site patterns
probe-card artifacts
reticle-field signatures
neighbor-die correlation
```

A die surrounded by many failing or marginal neighbors may be higher risk, even if it passes all direct tests.

---

# 7. Reliability Qualification Statistics

## 7.1 Qualification stress tests

Reliability qualification commonly uses stress tests such as:

```text
HTOL: high-temperature operating life
ELFR: early-life failure rate
HAST / uHAST: humidity stress
THB: temperature-humidity bias
HTS: high-temperature storage
TC: temperature cycling
thermal shock
ESD
latch-up
package moisture/reflow
mechanical stress
```

Statistical questions:

```text
How many units were stressed?
How long were they stressed?
What acceleration factor maps stress to field use?
How many failures were observed?
What failure mechanisms were activated?
What FIT or failure-rate bound can be claimed?
```

## 7.2 FIT, MTTF, and confidence bounds

FIT means failures per billion device-hours:

```text
1 FIT = 1 failure / 1e9 device-hours
```

Reliability reports often include:

```text
sample size
stress duration
acceleration factor
equivalent device-hours
failure count
confidence level
FIT upper bound
```

For zero failures:

```text
FIT is not zero.
FIT upper bound depends on equivalent device-hours and confidence level.
```

## 7.3 Bathtub curve and early-life failures

The classic bathtub curve has three regions:

```text
early-life / infant mortality
useful-life random failures
wearout failures
```

Burn-in and ELFR screens target early-life failures, not necessarily wearout or design-margin issues.

Important point:

```text
Burn-in can screen weak parts.
Burn-in does not fix an invalid design margin.
```

If a dynamic latch is over-borrowed beyond its characterized timing window, burn-in may not catch the issue unless the burn-in condition excites that exact failure mode.

## 7.4 Wearout distributions

Wearout mechanisms are modeled statistically because individual devices fail at different times.

Common distributions:

```text
Weibull
lognormal
exponential, for constant random failure rate
```

Common wearout mechanisms:

```text
electromigration
TDDB
BTI / NBTI / PBTI
HCI
stress migration
SILC / leakage degradation
package fatigue
solder fatigue
metal corrosion
```

Important signoff point:

```text
Median lifetime is not enough.
The lower-tail lifetime matters.
```

Better statement:

```text
The 0.1% or 1% percentile lifetime exceeds the mission lifetime with specified confidence.
```

Rather than:

```text
The median lifetime exceeds 10 years.
```

---

# 8. Package and Assembly Statistics

Package-level quality uses statistics for:

```text
moisture sensitivity level, MSL
reflow robustness
HAST / uHAST
thermal cycling
thermal shock
drop/vibration
wirebond reliability
bump reliability
solder fatigue
delamination
package warpage
board-level reliability
```

Statistical questions:

```text
How many packages were stressed?
Were multiple lots and assembly lines represented?
Were failures electrical, mechanical, or visual?
Are failures clustered by package corner, die size, mold compound, or substrate lot?
Does package-family qualification apply to this product?
```

Important limitation:

```text
Package-family qualification is only valid if the new product is inside the qualified family envelope.
```

---

# 9. ESD and Latch-Up Statistics

ESD and latch-up tests often look deterministic, but they still contain statistical elements.

## 9.1 ESD

Common models:

```text
HBM: human body model
CDM: charged device model
MM: machine model, less emphasized in modern standards
```

Statistical questions:

```text
What is the failure threshold distribution?
Were weak pins, weak corners, and package effects sampled?
How many units were stressed?
Do results correlate with production process corners?
Does system-level ESD exceed component-level classification?
```

Important point:

```text
Passing an HBM/CDM classification proves compliance to that model and level.
It does not prove unlimited real-world ESD robustness.
```

## 9.2 Latch-up

Latch-up qualification checks susceptibility to parasitic SCR activation under stress.

Statistical concerns:

```text
process variation in well/substrate resistance
layout-dependent trigger sensitivity
temperature dependence
pin-combination coverage
sample size
stress-level step size
```

A product can pass qualification samples but still require production controls if latch-up margin is process-sensitive.

---

# 10. Soft-Error-Rate Statistics

Soft errors are inherently statistical because they are caused by random radiation events.

Sources:

```text
alpha particles from materials
terrestrial neutron radiation
cosmic rays
heavy ions, for aerospace
```

Metrics:

```text
FIT/Mb
FIT/device
upset cross-section
single-event upset, SEU
single-event transient, SET
single-event latch-up, SEL
silent data corruption rate
uncorrectable error rate
```

Statistical questions:

```text
How many upsets were observed?
What particle flux was used?
What acceleration factor maps test to field?
What confidence interval applies?
How do ECC, parity, retry, lockstep, or scrubbing reduce system-level error rate?
```

Important distinction:

```text
Raw bit upset rate is not the same as system-level silent data corruption rate.
```

System architecture matters.

---

# 11. Automotive and Functional Safety Statistics

Automotive and safety-critical chips add statistical metrics for random hardware faults.

Common terms:

```text
FIT: failures in time
PMHF: probabilistic metric for random hardware failures
SPFM: single-point fault metric
LFM: latent fault metric
diagnostic coverage
residual fault rate
latent fault rate
safe fault fraction
```

Signoff artifacts:

```text
FMEDA
safety manual
fault-injection report
diagnostic coverage analysis
mission-profile-based FIT estimate
ASIL decomposition evidence
```

Important distinction:

```text
Random hardware failures are statistical.
Systematic design bugs are not solved by FIT statistics.
```

A dynamic-latch over-borrow issue is usually a systematic design-margin problem unless it has been fully characterized, modeled, constrained, and qualified.

---

# 12. Field Quality and Silicon Lifecycle Statistics

After release, statistics continues through field monitoring.

Data sources:

```text
RMA returns
warranty claims
customer DPPM
system logs
telemetry
in-field monitors
aging monitors
thermal sensors
error counters
ECC events
fleet-level failure data
manufacturing genealogy
```

Methods:

```text
Bayesian failure-rate update
survival analysis
Weibull/lognormal fitting
change-point detection
anomaly detection
lot/wafer/package correlation
field-to-test correlation
fleet segmentation by mission profile
```

Complications:

```text
censored data
unknown customer stress history
No Trouble Found returns
reporting delay
small-failure-count uncertainty
mixed failure mechanisms
usage bias
```

Field data is valuable because it observes real mission profiles, but it is noisy and often biased.

---

# 13. Specific Application: Dynamic Latch Over-Borrow

The earlier latch-borrow discussion fits into this broader statistical framework.

For a path:

```text
Latch A -> Logic AB -> Dynamic Latch B -> Logic BC -> Latch C
```

`A -> B` borrows at the capture latch `B`. The borrow is physically limited by the open/close window of `B`, but for a dynamic latch it is also limited by circuit-level dynamic validity.

A safe dynamic-latch borrow cap should be based on:

```text
STA physical borrow window
characterized dynamic write/evaluate window
retention time
keeper contention
charge sharing
noise margin
clock feedthrough
pulse-width limits
SI/IR/aging assumptions
downstream B -> C slack
required guardband
```

A robust rule is:

```text
actual_dynamic_latch_borrow
  <= characterized_dynamic_safe_borrow_cap
  - required_statistical_and_design_guardband
```

## 13.1 Why Monte Carlo alone is insufficient

Unsafe statement:

```text
3000 MC runs passed, so the dynamic latch is safe at this over-borrow point.
```

Safer statement:

```text
At each relevant PVT/RC/SI/IR/aging/clock condition,
the actual latch borrow is below the characterized dynamic safe-borrow cap.
The cap is supported by SPICE MC, corner simulation, waveform sensitivity,
retention checks, pulse-width checks, and downstream STA.
The MC sample size and zero-failure confidence bound are explicitly reported.
```

Example signoff record:

```text
Dynamic latch B:
  characterized safe borrow cap = 220 ps
  signoff actual borrow         = 180 ps
  residual margin               = 40 ps
  MC condition                  = SS, low-V, hot, worst clock/data slew
  MC samples                    = 3000
  observed functional fails     = 0
  95% zero-fail upper bound     ≈ 0.1% under this simulation setup
  additional checks             = retention, charge sharing, keeper contention,
                                  SI/IR, pulse width, downstream setup/hold
```

## 13.2 What over-borrow failure means

A chip failure in this context does not necessarily mean the chip is physically damaged. It means the circuit can produce an incorrect logical state or become marginal under some condition.

Possible symptoms:

```text
wrong data capture
weak or half-resolved dynamic node
pattern-dependent failure
frequency shmoo failure
Vmin failure
temperature-dependent failure
scan/BIST failure
lower production yield
field escape
```

Lower speed may help if the issue is purely setup/Fmax-related. But dynamic latches can also have minimum-frequency or retention limits. Slowing down can improve setup while making retention worse.

Correct lower-speed qualification logic:

```text
At lower frequency:
  actual borrow must fall below the characterized dynamic cap
  retention/max-period checks must pass
  pulse-width checks must pass
  hold/race-through checks must pass
  SI/IR/aging assumptions must remain valid
```

Unsafe logic:

```text
The chip failed at high speed, so it must be safe at lower speed.
```

Dynamic circuits can fail at both fast and slow ends, depending on mechanism.

---

# 14. Practical Taxonomy

| Signoff area | Statistical object | Typical metric | Main trap |
|---|---|---|---|
| STA / timing | path delay variation | sigma slack, POCV/LVF adjustment | assuming positive slack means yield-safe |
| Dynamic/custom circuits | circuit behavior distribution | MC fail rate, margin distribution | treating 1000/3000 MC as high-sigma proof |
| SRAM | bitcell/access/sense margin | Vmin distribution, fail-bit rate | array tail much worse than bitcell mean |
| Analog/RF | parameter spread | offset, gain, phase noise, INL/DNL | trim range confused with yield guarantee |
| Power/EM/IR | workload and degradation spread | IR-drop distribution, EM lifetime | rare activity/thermal cases missed |
| WAT/PCM | process monitor distribution | mean, sigma, Cp/Cpk, control limits | assuming PCM perfectly predicts product die |
| Wafer yield | die pass/fail population | yield, bin yield, wafer-map clusters | yield confused with outgoing quality |
| Production test | test filter effectiveness | DPPM, test escape, yield loss | maximizing yield while ignoring escapes |
| Fault coverage | modeled defect detection | stuck-at/transition/cell-aware coverage | fault coverage treated as direct DPPM |
| PAT/outlier screening | abnormal part detection | sigma limit, multivariate outlier score | Gaussian assumption or bad-lot normalization |
| Reliability qualification | lifetime/failure rate | FIT, MTTF, Weibull/lognormal parameters | zero failures treated as zero risk |
| Burn-in/ELFR | early-life population | ELFR, fallout, acceleration | burn-in expected to fix design margin |
| Package | thermo-mechanical population | TC/HAST/MSL pass/fail confidence | package-family qualification misapplied |
| ESD/latch-up | susceptibility distribution | classification level, threshold | compliance model confused with system robustness |
| SER | radiation-induced error process | FIT/Mb, cross-section, CI | bit SER confused with system SDC rate |
| Functional safety | random hardware risk | PMHF, SPFM, LFM, diagnostic coverage | systematic bug misclassified as random fault |
| Field quality | real-use failure process | RMA, field FIT, warranty rate | biased/censored field data ignored |

---

# 15. Statistical Signoff Checklist

For every statistical claim, capture these fields.

## 15.1 Population

```text
What population is represented?
  cell
  path
  latch
  macro
  die
  wafer
  lot
  package
  product family
  customer mission profile
```

## 15.2 Random variable

```text
What is being measured or modeled?
  delay
  setup/hold margin
  latch borrow
  Vmin
  leakage
  offset
  jitter
  lifetime
  fail/pass
  DPPM
  FIT
```

## 15.3 Distribution or model

```text
What model is assumed?
  normal
  lognormal
  Weibull
  exponential
  binomial
  Poisson
  empirical
  Bayesian
  response surface
  importance sampling
```

## 15.4 Sample size and failures

```text
How many samples?
How many fails?
What corners or lots are included?
Are samples independent?
Are correlations included?
```

## 15.5 Confidence level

```text
What confidence level is claimed?
  90%
  95%
  99%
  one-sided
  two-sided
```

## 15.6 Tail coverage

```text
What tail is claimed?
  3 sigma
  4 sigma
  5 sigma
  ppm
  ppb
  FIT
  DPPM
```

## 15.7 Stress-to-use model

```text
If accelerated stress is used:
  What failure mechanism is accelerated?
  What acceleration model is used?
  What activation energy or model parameter is assumed?
  What mission profile is used?
```

## 15.8 Correlation

```text
Are these correlations included?
  local device mismatch
  global process variation
  lot-to-lot variation
  wafer spatial variation
  clock/data correlation
  voltage/temperature correlation
  workload correlation
  package/board correlation
```

## 15.9 Coverage gaps

```text
What is not covered?
  untested data patterns
  unmodeled noise
  unmodeled aging
  unmodeled SI/IR
  field mission variation
  production process drift
  customer board/system effects
```

---

# 16. Recommended Wording for Signoff Reviews

## Weak wording

```text
3000 Monte Carlo runs passed, so this is safe.
```

## Better wording

```text
3000 Monte Carlo samples were run under condition X with 0 observed failures.
This gives an approximate 95% zero-fail upper-bound failure rate of 0.1%
for the simulated setup. The design margin is still accepted only because
the actual operating point is inside the characterized safe region with
specified guardband.
```

## Weak wording

```text
HTOL had 0 failures, so the FIT is 0.
```

## Better wording

```text
HTOL had 0 failures over T equivalent device-hours. Under the assumed
acceleration model and constant failure-rate assumption, the 95% upper-bound
failure rate is approximately 3/T.
```

## Weak wording

```text
Cpk is high, so there is no quality risk.
```

## Better wording

```text
The monitored process parameter has Cpk = X under a stable-process assumption.
This supports process capability for that parameter, but product-level quality
also depends on model correlation, unmonitored parameters, test coverage,
outlier screening, and field mechanisms.
```

---

# 17. Key Takeaways

```text
1. Zero observed failures is not zero risk.
2. 1000x or 3000x MC is useful but not high-sigma proof.
3. Statistical evidence must match the actual failure mechanism.
4. Accelerated stress is valid only if the acceleration model is valid.
5. Production quality depends on design margin, test coverage, process control,
   outlier screening, reliability qualification, and field feedback.
6. Positive STA slack is not enough if the circuit model is outside its
   characterized region.
7. Dynamic latch over-borrow is a design/circuit-validity problem, not merely
   a statistical-yield problem.
8. Tolerance intervals and failure-rate bounds are often more relevant than
   confidence intervals on the mean.
9. Yield is not the same as outgoing quality.
10. A signoff claim should always state sample size, failure count, confidence,
    model assumptions, covered conditions, and uncovered gaps.
```

---

# 18. Selected References

These references are useful starting points for the statistical concepts and semiconductor quality topics discussed in this note.

## General statistics and reliability

- [NIST Engineering Statistics Handbook: Binomial proportion confidence intervals](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm)
- [NIST Engineering Statistics Handbook: Tolerance intervals](https://www.itl.nist.gov/div898/handbook/prc/section2/prc263.htm)
- [NIST Engineering Statistics Handbook: Process monitoring and control](https://www.itl.nist.gov/div898/handbook/pmc/pmc.htm)
- [NIST Engineering Statistics Handbook: Process capability](https://www.itl.nist.gov/div898/handbook/pmc/section1/pmc16.htm)
- [NIST Engineering Statistics Handbook: Reliability](https://www.itl.nist.gov/div898/handbook/apr/apr.htm)
- [NIST Engineering Statistics Handbook: Bathtub curve](https://www.itl.nist.gov/div898/handbook/apr/section1/apr124.htm)

## Semiconductor quality and reliability standards

- JEDEC JESD47: Stress-test-driven qualification of integrated circuits
- JEDEC JESD74: Early life failure rate calculation procedure
- JEDEC JESD85: Methods for calculating failure rates in FIT units
- JEDEC JESD89: Measurement and reporting of alpha-particle and terrestrial cosmic-ray-induced soft errors
- JEDEC JESD91: Method for developing acceleration models for electronic component failure mechanisms
- JEDEC JEP122: Failure mechanisms and models for semiconductor devices
- JEDEC JESD22-A114: HBM ESD testing
- ESDA/JEDEC JS-002: CDM ESD testing
- JEDEC JESD78: IC latch-up testing
- IPC/JEDEC J-STD-020: Moisture/reflow sensitivity classification for nonhermetic surface-mount devices
- AEC-Q001: Guidelines for Part Average Testing
- AEC-Q100: Failure-mechanism-based stress qualification for automotive ICs
- ISO 26262: Road vehicles functional safety

## Practical semiconductor topics

- WAT/PCM process monitor data and model-to-silicon correlation
- DFT fault coverage versus defect coverage
- PAT/DPAT and multivariate outlier screening
- SRAM Vmin and fail-bit statistical modeling
- Soft error rate modeling and system-level mitigation
- Silicon Lifecycle Management and field telemetry analytics

