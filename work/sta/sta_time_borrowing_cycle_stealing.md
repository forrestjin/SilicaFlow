---
title: STA Time Borrowing and Cycle Stealing
status: reference
owner: SilicaFlow
scope: STA signoff, latch timing, flip-flop timing
last_updated: 2026-05-29
---

# STA Time Borrowing and Cycle Stealing

## 1. Executive summary

Timing borrowing, also called cycle stealing in latch-based design, is a timing effect enabled by level-sensitive latches.

A slow stage is allowed to finish after the receiving latch opens, as long as the data arrives before that latch closes with all required setup, uncertainty, variation, and guardband margins.

Borrowing does **not** make the logic faster. It does **not** create extra clock period. It only redistributes timing slack between adjacent pipeline stages.

```text
Latch A -> Logic Stage 1 -> Latch B -> Logic Stage 2 -> Latch C

If Stage 1 borrows time at Latch B:

  Stage 1 gets more available time.
  Stage 2 gets less available time.
```

A normal edge-triggered flip-flop does **not** support true latch-style timing borrowing. A flip-flop captures at a discrete clock edge. If the data arrives after that edge, the data misses that capture event unless the path is intentionally defined as multicycle.

For a setup-critical path such as `Latch A -> Logic AB -> Latch B`, the borrow is physically enabled by **Latch B's transparent window**. In timing-budget terms, the cost is paid by the downstream stage, `Latch B -> Logic BC -> Latch C`.

Static and dynamic latches use the same high-level STA borrowing model, but dynamic latches require stricter signoff because their internal state may depend on charge retention, noise margin, clock pulse quality, and transistor-level circuit behavior.

For dynamic latches, STA setup slack obtained by borrowing beyond the characterized dynamic safe window is not valid signoff slack. Lowering the clock frequency may recover a pure setup/Fmax issue, but it must be re-signed off or silicon-characterized at the lower speed because dynamic-node retention, pulse constraints, hold timing, and race-through behavior may become the limiting checks.

---

## 2. Key definitions

| Term | Meaning |
|---|---|
| Transparent latch | A level-sensitive storage element whose output can follow its input while the latch enable/clock is active. |
| Latch opening edge | The edge at which the latch becomes transparent. |
| Latch closing edge | The edge at which the latch stops being transparent and captures the final input value. |
| Transparent window | The time interval between latch opening and latch closing. |
| Borrowed time | The amount by which data arrives after the nominal latch opening boundary but still before the safe latch closing requirement. |
| Cycle stealing | Another name for latch timing borrowing, emphasizing that time is taken from the next stage. |
| Useful skew | Intentional or beneficial clock skew that gives one stage more time and another stage less time. Similar effect, different mechanism. |
| Multicycle path | A path architecturally allowed to take more than one clock cycle. Not the same as borrowing. |
| Pulsed latch | A latch that is transparent only during a short pulse. It may allow limited borrowing depending on pulse width and STA modeling. |
| Static latch | A latch whose state is held by static feedback while power is present. |
| Dynamic latch | A latch whose state may be stored on a capacitance or dynamic node for some time. It may require retention, pulse-width, noise, and circuit-level checks beyond ordinary STA setup. |
| Dynamic borrow cap | The maximum borrow that a dynamic latch is characterized and approved to support across signoff conditions. |
| Over-borrow | A condition where actual latch borrow exceeds the approved borrow cap, or where STA uses an uncharacterized part of the latch transparent window. |
| Speed derating | Qualifying the design at a lower frequency than the original target. This is valid only after the lower-speed operating point is rechecked. |

---

## 3. How latch timing borrowing works

A flip-flop has one capture instant:

```text
FF A -> Logic -> FF B

time ---->

launch edge                         capture edge
    |------------------------------------|
                                      ^
                                      FF B samples here
```

For a flip-flop path, data must arrive before the capture edge:

```text
arrival_time <= capture_edge - setup - uncertainty
```

A latch has a capture window:

```text
Latch B transparent window

time ---->

        |--------------------|
        open               close
                           ^
                           latest safe capture boundary
```

If data arrives after the latch opens but before the latch closes safely, the path has borrowed time:

```text
        |--------------------|
        open               close
              ^
              data arrives: no or small borrow

        |--------------------|
        open               close
                         ^
                         data arrives late but still legal: borrow occurs
```

The required arrival time for a latch-based setup check is tied to the safe closing boundary, not just the opening edge:

```text
latest_safe_arrival = latch_closing_edge
                    - latch_setup_time
                    - clock_uncertainty
                    - variation_margin
                    - signoff_guardband
```

Borrowing is legal only when:

```text
actual_arrival <= latest_safe_arrival
```

---

## 4. What borrowing is not

Timing borrowing does **not** mean the borrowing stage toggles first.

Usually, the borrowing stage is the slow stage. Its data arrives late. Because the receiving latch is still transparent, the late data can still pass through and be captured.

Timing borrowing also does **not** mean the data path is physically faster. The path delay is unchanged. STA is only using the transparent latch window to allow the previous stage more time.

A better mental model is:

```text
Borrowing = slack redistribution
Borrowing != logic speedup
Borrowing != free extra cycle time
Borrowing != automatic functional safety
```

---

## 5. Slack redistribution example

Assume a two-phase latch pipeline where each half-cycle nominally provides 500 ps.

Without borrowing:

```text
Stage 1 budget = 500 ps
Stage 2 budget = 500 ps
Total budget   = 1000 ps
```

If Stage 1 needs 580 ps, it can borrow 80 ps from Stage 2 if the latch window and downstream timing allow it:

```text
Stage 1 uses = 580 ps
Stage 2 left = 420 ps
Total        = 1000 ps
```

No extra time is created. Stage 2 must still meet timing with the reduced budget.

---

## 6. Maximum safe borrow

The maximum signoff-safe borrow is the smaller of:

1. The physical transparent-window limit of the latch.
2. The amount of timing slack available in the next stage after all margins.

```text
B_safe = min(B_physical, S_next - M_residual)
```

Where:

| Symbol | Meaning |
|---|---|
| B_safe | Safe allowed borrow for the latch path. |
| B_physical | Maximum borrow allowed by the latch transparent window and clocking. |
| S_next | Available setup slack in the downstream stage that will lose time. |
| M_residual | Required remaining signoff margin after borrowing. |

The physical maximum is approximately:

```text
B_physical = T_open_window
           - t_setup_closing
           - clock_uncertainty
           - duty_cycle_distortion_margin
           - clock_skew_or_clock_spread
           - variation_margin
           - extra_guardband
```

For a simple 50 percent duty-cycle latch clock:

```text
B_physical ~= Tclk/2
             - latch_setup
             - clock_uncertainty
             - duty_cycle_margin
             - skew_or_spread_margin
             - guardband
```

### Example

```text
Clock period              = 1000 ps
Transparent window         = 500 ps
Latch setup                = 30 ps
Clock uncertainty          = 40 ps
Duty/skew/spread margin    = 25 ps
Guardband                  = 20 ps

B_physical = 500 - 30 - 40 - 25 - 20
           = 385 ps
```

If the downstream stage has only 250 ps slack and the required residual margin is 30 ps:

```text
B_safe = min(385, 250 - 30)
       = 220 ps
```

In this example, 385 ps is the physical window limit, but 220 ps is the safer signoff cap because the next stage cannot pay back more than that.

---


## 7. Borrow location in an A -> B -> C latch chain

For this latch pipeline:

```text
Latch A -> Logic AB -> Latch B -> Logic BC -> Latch C
```

if the setup-critical path is:

```text
Latch A -> Logic AB -> Latch B
```

the path borrows at **Latch B**, not at Latch A.

The reason is that B is the receiving latch. If data from A arrives after B opens but before B closes safely, B's transparent window accepts that late data.

```text
time ---->

Latch B transparent window:

        B opens                         B closes
          |--------------------------------|
          ^                                ^
          nominal boundary                 hard setup boundary

Late A -> B data:
          |--------------------------------|
                         ^
                         data arrives during B transparency
```

### Physical view

The borrow is physically enabled by the capture latch:

```text
A -> B borrows at Latch B.
```

Latch A influences launch time, launch clock-to-Q behavior, and any previous-stage borrow into A. It is not where the `A -> B` path gets its receiving-side borrow allowance.

### Budget view

Although the physical borrow point is B, the cost is paid by the next stage:

```text
A -> B gets more available time.
B -> C gets less available time.
```

The precise wording is:

```text
A -> B borrows through Latch B from the available timing slack of B -> C.
```

### Which latch determines the allowed value?

The immediate physical borrow limit is calculated against **Latch B**, because B supplies the transparent window:

```text
latest_safe_arrival_at_B =
    B_closing_edge
  - setup_time_of_B
  - clock_uncertainty_to_B
  - variation_margin
  - duty_cycle_or_skew_margin
  - signoff_guardband
```

The actual borrow for `A -> B` can be estimated as:

```text
actual_borrow_A_to_B =
    max(0, arrival_time_at_B - nominal_no_borrow_boundary_at_B)
```

For a simple two-phase latch scheme, the nominal no-borrow boundary is often B's opening edge. Then:

```text
physical_borrow_limit_at_B ~= 
    B_closing_edge
  - B_opening_edge
  - setup_time_of_B
  - clock_uncertainty_to_B
  - variation_margin
  - duty_cycle_or_skew_margin
  - signoff_guardband
```

However, B alone is not enough. The final safe value must also account for downstream timing into C:

```text
safe_borrow_A_to_B =
  min(
      physical_borrow_limit_at_B,
      downstream_slack_B_to_C - residual_margin
  )
```

Use this mental model:

```text
B decides how much can physically be borrowed.
C decides whether the next stage can afford that borrow.
```

---

## 8. Static versus dynamic latch treatment

The STA abstraction is similar for static and dynamic latches:

```text
A -> B borrows at capture Latch B.
B -> C pays for the borrow through reduced downstream budget.
```

The signoff risk is different.

A **static latch** holds its state through static feedback. As long as power, setup, hold, pulse-width, and noise assumptions are satisfied, its storage mechanism is robust.

A **dynamic latch** may store state as charge on an internal node. That makes the timing window partly circuit-dependent. Even if a pure STA setup equation appears legal, the real latch may also need margin for:

```text
internal write/evaluate completion
charge sharing
keeper contention
clock feedthrough or injection
coupling noise
local IR drop
leakage and retention time
minimum operating frequency or maximum clock-off time
clock pulse width and duty-cycle distortion
```

For a static latch, a typical signoff cap is:

```text
static_borrow_cap =
    min_physical_borrow_across_scenarios
  - standard_latch_guardband
```

For a dynamic latch, use a stricter cap:

```text
dynamic_borrow_cap =
  min(
      STA_physical_borrow_window,
      characterized_dynamic_safe_window,
      retention_safe_window,
      write_or_evaluate_safe_window,
      downstream_slack_limit
  )
  - dynamic_latch_guardband
```

Practical policy:

```text
Static latch:
  Sign off with normal latch-borrow STA checks plus project guardband.

Library dynamic or pulsed latch:
  Allow borrow only inside the characterized Liberty/circuit validity window.

Custom dynamic latch:
  Do not rely on STA alone. Require transistor-level validation across PVT,
  mismatch, clock slew, data slew, SI/noise, and IR-drop scenarios.
```

Do not give a dynamic latch the same borrow budget as a static latch unless the library or circuit team has explicitly characterized and approved that window.

---

## 9. Dynamic latch over-borrowing impact and remedy

Dynamic-latch over-borrow occurs when:

```text
actual_borrow_at_dynamic_latch > dynamic_borrow_cap
```

or when STA is allowed to use a region of the latch transparent window that has not been characterized or approved by the library/circuit team.

### Signoff interpretation

Treat this as a **hard signoff failure**, even if the STA report shows positive setup slack.

```text
STA setup slack created by over-borrowing a dynamic latch is not valid signoff slack.
```

The timing report may be mathematically consistent, but the circuit is being used outside its guaranteed operating window.

### What chip failure means here

In this context, chip failure does not necessarily mean the chip is physically damaged or that every die is dead. It means the design can produce an incorrect logical state under some condition.

Examples:

```text
expected captured D = 1, actual captured Q = 0
expected captured D = 0, actual captured Q = 1
internal dynamic node is weakly resolved and later disturbed by noise
```

Possible silicon symptoms include:

```text
BIST failure
scan failure
random functional error
frequency shmoo failure
Vmin failure
temperature-sensitive failure
pattern-sensitive failure
yield loss
field escape risk
```

This is often worse than a clean deterministic failure because the chip may work at nominal lab conditions but fail at slow process, low voltage, high temperature, local IR drop, bad clock duty cycle, crosstalk, aging, or specific data patterns.

### Can lower speed fix it?

Lower frequency can help if the problem is purely a setup/Fmax issue:

```text
At high frequency:
  required borrow > dynamic_borrow_cap

At lower frequency:
  required borrow <= dynamic_borrow_cap
```

In that case the chip may be qualified at a lower frequency, but only after the lower-speed operating point is re-signed off or silicon-characterized.

Do not assume slower is always safer for dynamic latches. A dynamic node may also have a retention or maximum-period constraint:

```text
slowing down helps setup
slowing down can hurt dynamic-node retention
```

A lower-speed qualification must prove:

```text
actual_borrow_at_dynamic_latch <= dynamic_borrow_cap
setup_slack >= required_setup_margin
hold_slack >= required_hold_margin
min_pulse_width_slack >= 0
max_pulse_width_or_max_period_check passes, if required
minimum_frequency_or_retention_check passes, if required
no race-through or phase-overlap issue
SI, IR, OCV/POCV/LVF, aging, and duty-cycle checks remain clean
```

Safe statement:

```text
The chip may be usable at a lower frequency only if the lower-frequency point is
requalified and all dynamic-latch validity checks pass.
```

Unsafe statement:

```text
The chip over-borrowed at target frequency, so we can always fix it by lowering
the clock.
```

### Remedy options

Preferred fixes are design or constraint fixes that bring actual borrow back inside the approved cap:

```text
reduce A -> B datapath delay
rebalance logic from A -> B into B -> C if B -> C has slack
retime the pipeline
adjust latch phase only after hold, race-through, and pulse checks remain clean
tighten set_max_time_borrow to the real dynamic cap and fix resulting violations
change the dynamic latch to a static latch if area, power, and timing allow
increase or redesign dynamic-latch robustness if this is a custom latch
recharacterize the latch if the circuit team wants to approve a larger window
qualify a lower Fmax bin only after complete lower-speed signoff
```

For custom or high-speed dynamic latches, require circuit validation for any cap expansion:

```text
SPICE across PVT
Monte Carlo or mismatch validation
clock slew and data slew sweeps
pulse-width and duty-cycle sweeps
local IR-drop cases
coupling/noise injection cases
keeper contention cases
charge-sharing cases
retention and clock-off-time cases
```

SilicaFlow status policy for dynamic over-borrow:

```text
PASS:
  actual_borrow <= dynamic_borrow_cap
  all setup, hold, pulse, race, retention, SI/IR, and variation checks pass

WARN:
  actual_borrow is close to dynamic_borrow_cap
  dynamic margin is small or sensitive to PVT/noise/pulse width

FAIL:
  actual_borrow > dynamic_borrow_cap
  dynamic_borrow_cap is unknown or uncharacterized
  lower-speed operation is assumed but not requalified
```

---

## 10. Flip-flop versus latch borrowing

### 10.1 Normal edge-triggered flip-flop

A normal flip-flop cannot perform true timing borrowing.

```text
FF A -> Logic -> FF B

Data must arrive before FF B capture edge.
```

Setup check:

```text
arrival_time <= capture_edge - setup - uncertainty
```

If data arrives after the capture edge, the flop does not borrow from the next cycle. It misses that edge and will be captured later, which is a setup violation unless the design intentionally defines the path as multicycle.

### 10.2 Level-sensitive latch

A latch can borrow because it has a transparent window:

```text
Latch A -> Logic -> Latch B

Data may arrive after Latch B opens,
as long as it arrives before Latch B closes safely.
```

### 10.3 Pulsed latch or pulsed flip-flop

A pulsed latch is latch-like during a short pulse:

```text
pulse window:
      |----|
      open close
```

It may allow limited borrowing, usually bounded by pulse width. Signoff must check how the standard-cell library models the cell. Some teams call these cells pulsed flops, but for STA behavior they may be closer to latches.

---

## 11. Similar concepts that are not true latch borrowing

### 11.1 Useful skew

Useful skew can move a flip-flop capture edge later to give the previous stage more time:

```text
FF A -> Logic 1 -> FF B -> Logic 2 -> FF C
```

If FF B's capture clock is delayed:

```text
Logic 1 gets more time.
Logic 2 gets less time.
```

This resembles borrowing as slack redistribution, but the mechanism is different. FF B still captures on one edge.

### 11.2 Multicycle path

A multicycle path allows data to be captured after more than one clock cycle:

```text
single-cycle path: capture after 1 cycle
multicycle path:   capture after N cycles
```

This is not borrowing. It is only valid if the architecture and control protocol guarantee that the data is not required every cycle.

A multicycle exception must not be used merely to hide a setup violation.

### 11.3 Retiming

Retiming changes the placement of sequential elements to rebalance logic delay across stages. It changes the circuit structure. Borrowing does not change the structure; it uses latch transparency.

---

## 12. Signoff acceptance criteria

A latch-borrowed timing path should be accepted only if all of the following pass across all signoff scenarios:

```text
actual_borrow <= allowed_borrow_cap
setup_slack >= required_setup_margin
hold_slack >= required_hold_margin
min_pulse_width_slack >= 0
dynamic_latch_borrow <= characterized_dynamic_borrow_cap, if applicable
dynamic retention / max-period / min-frequency checks pass, if applicable
no transparent race-through
no invalid borrowing across asynchronous or unrelated clocks
no unintended latch inference
no unconstrained paths
```

The criteria must be checked across:

```text
all modes
all process corners
all voltage corners
all temperature corners
all RC extraction corners
all clock modes
SI/crosstalk scenarios
IR-drop timing scenarios, if used
aging scenarios, if used
OCV/AOCV/POCV/LVF variation models, if used
```

---

## 13. Recommended borrow policy

A practical policy is:

```text
Hard fail:
  actual_borrow > borrow_cap
  dynamic_latch_borrow > characterized_dynamic_borrow_cap
  dynamic_borrow_cap is unknown for a dynamic latch that needs borrowing
  setup slack < required setup margin
  hold slack < required hold margin
  min pulse width violation
  dynamic retention / max-period / min-frequency violation
  borrow on unintended latch
  borrow across asynchronous clocks
  transparent race-through risk

Review warning:
  actual_borrow > 70-80 percent of physical borrow window
  residual latch-window margin is small
  many consecutive latch stages all borrow heavily
  borrowed path is highly sensitive to duty cycle, skew, SI, IR, or aging
```

Where:

```text
borrow_cap = min_physical_borrow_across_all_scenarios - guardband
```

Or, if using downstream slack accounting:

```text
borrow_cap = min(B_physical, S_next - M_residual)
```

Do not sign off by assuming that half-cycle equals safe borrow. Half-cycle is only the ideal latch-open duration. The real safe value must subtract setup, uncertainty, skew, duty-cycle distortion, variation, SI/IR/aging effects, and project guardband.

For dynamic latches, positive STA slack is not sufficient if it was achieved by using borrow beyond the characterized dynamic cap. Over-borrow is a hard failure until the design is fixed, the latch is recharacterized, or a lower-speed operating point is fully requalified.

---

## 14. STA constraint guidance

Many STA and implementation tools support a maximum time-borrow constraint. Exact syntax depends on the tool.

Generic example:

```tcl
# Example only. Replace with the correct collection for the target STA tool.
set_max_time_borrow 0.080 $latch_collection
```

Recommended methodology:

1. Let the STA engine compute actual latch borrowing.
2. Apply a maximum borrow cap to prevent excessive dependence on latch transparency.
3. Review paths with high borrow ratio.
4. Verify downstream setup, hold, min pulse width, and race-through checks.
5. Keep accidental or unintended latches at zero borrow or flag them as errors.

Avoid forcing exact borrow values unless the methodology explicitly requires it. Capping borrow is usually safer than manually prescribing borrow.

---

## 15. Race-through risk

Latch transparency can create race-through if multiple latch stages are transparent at the same time or if clock phases overlap unexpectedly.

Risky condition:

```text
Latch A open -> Logic -> Latch B open -> Logic -> Latch C open
```

Data may propagate through more than one sequential boundary in a single cycle. This can break functional behavior even when a local setup check looks clean.

Required checks:

```text
hold timing at fast/min corners
non-overlap between latch phases
clock waveform correctness
min pulse width
clock latency and skew after CTS
clock reconvergence pessimism handling
no unintended phase overlap
```

---

## 16. SilicaFlow integration checklist

Suggested location inside the project:

```text
/Users/flin/Documents/Playground/SilicaFlow/docs/sta/time-borrowing-cycle-stealing.md
```

Suggested tags:

```text
sta
signoff
latch
time-borrowing
cycle-stealing
useful-skew
multicycle
```

Suggested review hooks for SilicaFlow timing signoff reports:

```text
1. Report actual borrow per latch.
2. Report maximum allowed borrow per latch.
3. Report borrow ratio = actual_borrow / physical_borrow_window.
4. Report latch type: static, dynamic, pulsed, or unknown.
5. Report dynamic borrow cap for dynamic latches.
6. Flag borrow ratio above policy threshold, for example 0.70 or 0.80.
7. Report downstream slack after borrow.
8. Report hold slack on corresponding min-delay paths.
9. Report min pulse width slack.
10. Report dynamic retention, max-period, or min-frequency slack if applicable.
11. Report latch phase overlap or transparent race-through risk.
12. Fail unintended latches or latches outside the approved clocking scheme.
13. Block signoff if any latch borrow is unconstrained or not covered by MMMC signoff.
14. Block signoff if a dynamic latch uses uncharacterized borrow.
15. Require full requalification if a lower-speed bin is used as the remedy.
```

Example report fields:

```text
instance_name
clock_name
mode
corner
latch_type
open_edge_time
close_edge_time
physical_borrow_limit_ps
dynamic_borrow_cap_ps
actual_borrow_ps
borrow_cap_ps
borrow_ratio
setup_slack_after_borrow_ps
downstream_slack_ps
hold_slack_ps
min_pulse_width_slack_ps
retention_slack_ps
min_frequency_check_status
max_period_check_status
lower_speed_requalified
status
```

Example status policy:

```text
PASS:
  actual_borrow_ps <= borrow_cap_ps
  dynamic latch checks pass, if applicable
  setup_slack_after_borrow_ps >= setup_margin_ps
  hold_slack_ps >= hold_margin_ps
  min_pulse_width_slack_ps >= 0

WARN:
  borrow_ratio >= warning_threshold
  residual_window_margin_ps is small
  dynamic latch borrow is close to characterized cap

FAIL:
  actual_borrow_ps > borrow_cap_ps
  dynamic_latch_borrow_ps > dynamic_borrow_cap_ps
  dynamic_borrow_cap_ps is unknown for a borrowing dynamic latch
  setup/hold/min-pulse/retention check fails
  transparent race-through is possible
  latch is unintended or unconstrained
  lower-speed remedy is assumed but not requalified
```

---

## 17. One-line rules

```text
Latch borrowing allows late data to be accepted while the receiving latch is still open.
```

```text
Borrowing steals time from the next stage; it does not create new time.
```

```text
A normal edge-triggered flip-flop cannot perform true timing borrowing.
```

```text
Useful skew can redistribute time in flip-flop pipelines, but it is not latch borrowing.
```

```text
A multicycle path is an architectural exception, not a borrow mechanism.
```

```text
Safe borrow is bounded by both the latch transparent window and downstream slack.
```

```text
For A -> B, borrow is physically at B; the timing cost is paid by B -> C.
```

```text
A dynamic latch must not borrow beyond its characterized dynamic borrow cap.
```

```text
Lowering frequency can fix a setup/Fmax shortage only after the lower-speed point is requalified.
```

```text
For dynamic latches, slower clocks can help setup but can hurt retention or max-period checks.
```

---

## 18. References for methodology context

The following vendor documents discuss latch timing borrowing and maximum borrow constraints. Use the project STA tool documentation as the source of truth for exact syntax and report behavior.

- Intel Quartus Prime Timing Analyzer: `set_max_time_borrow`
  - https://docs.altera.com/r/docs/683432/25.3.1/quartus-prime-pro-edition-user-guide-scripting/set_max_time_borrow-quartus-sdc
- Intel Quartus Prime Timing Analyzer: time borrowing with latches
  - https://docs.altera.com/r/docs/683243/25.3/quartus-prime-pro-edition-user-guide-timing-analyzer/time-borrowing-with-latches
- AMD Vivado Tcl command reference: `set_max_time_borrow`
  - https://docs.amd.com/r/2023.2-English/ug835-vivado-tcl-commands/set_max_time_borrow
- Synopsys PrimeTime signoff timing analysis overview
  - https://www.synopsys.com/content/dam/synopsys/implementation%26signoff/datasheets/primetime-ds.pdf

