---
title: STA Time Borrowing and Cycle Stealing
status: reference
owner: SilicaFlow
scope: STA signoff, latch timing, flip-flop timing
last_updated: 2026-05-25
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

## 7. Flip-flop versus latch borrowing

### 7.1 Normal edge-triggered flip-flop

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

### 7.2 Level-sensitive latch

A latch can borrow because it has a transparent window:

```text
Latch A -> Logic -> Latch B

Data may arrive after Latch B opens,
as long as it arrives before Latch B closes safely.
```

### 7.3 Pulsed latch or pulsed flip-flop

A pulsed latch is latch-like during a short pulse:

```text
pulse window:
      |----|
      open close
```

It may allow limited borrowing, usually bounded by pulse width. Signoff must check how the standard-cell library models the cell. Some teams call these cells pulsed flops, but for STA behavior they may be closer to latches.

---

## 8. Similar concepts that are not true latch borrowing

### 8.1 Useful skew

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

### 8.2 Multicycle path

A multicycle path allows data to be captured after more than one clock cycle:

```text
single-cycle path: capture after 1 cycle
multicycle path:   capture after N cycles
```

This is not borrowing. It is only valid if the architecture and control protocol guarantee that the data is not required every cycle.

A multicycle exception must not be used merely to hide a setup violation.

### 8.3 Retiming

Retiming changes the placement of sequential elements to rebalance logic delay across stages. It changes the circuit structure. Borrowing does not change the structure; it uses latch transparency.

---

## 9. Signoff acceptance criteria

A latch-borrowed timing path should be accepted only if all of the following pass across all signoff scenarios:

```text
actual_borrow <= allowed_borrow_cap
setup_slack >= required_setup_margin
hold_slack >= required_hold_margin
min_pulse_width_slack >= 0
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

## 10. Recommended borrow policy

A practical policy is:

```text
Hard fail:
  actual_borrow > borrow_cap
  setup slack < required setup margin
  hold slack < required hold margin
  min pulse width violation
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

---

## 11. STA constraint guidance

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

## 12. Race-through risk

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

## 13. SilicaFlow integration checklist

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
4. Flag borrow ratio above policy threshold, for example 0.70 or 0.80.
5. Report downstream slack after borrow.
6. Report hold slack on corresponding min-delay paths.
7. Report min pulse width slack.
8. Report latch phase overlap or transparent race-through risk.
9. Fail unintended latches or latches outside the approved clocking scheme.
10. Block signoff if any latch borrow is unconstrained or not covered by MMMC signoff.
```

Example report fields:

```text
instance_name
clock_name
mode
corner
open_edge_time
close_edge_time
physical_borrow_limit_ps
actual_borrow_ps
borrow_cap_ps
borrow_ratio
setup_slack_after_borrow_ps
hold_slack_ps
min_pulse_width_slack_ps
status
```

Example status policy:

```text
PASS:
  actual_borrow_ps <= borrow_cap_ps
  setup_slack_after_borrow_ps >= setup_margin_ps
  hold_slack_ps >= hold_margin_ps
  min_pulse_width_slack_ps >= 0

WARN:
  borrow_ratio >= warning_threshold
  residual_window_margin_ps is small

FAIL:
  actual_borrow_ps > borrow_cap_ps
  setup/hold/min-pulse check fails
  transparent race-through is possible
  latch is unintended or unconstrained
```

---

## 14. One-line rules

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

---

## 15. References for methodology context

The following vendor documents discuss latch timing borrowing and maximum borrow constraints. Use the project STA tool documentation as the source of truth for exact syntax and report behavior.

- Intel Quartus Prime Timing Analyzer: `set_max_time_borrow`
  - https://docs.altera.com/r/docs/683432/25.3.1/quartus-prime-pro-edition-user-guide-scripting/set_max_time_borrow-quartus-sdc
- Intel Quartus Prime Timing Analyzer: time borrowing with latches
  - https://docs.altera.com/r/docs/683243/25.3/quartus-prime-pro-edition-user-guide-timing-analyzer/time-borrowing-with-latches
- AMD Vivado Tcl command reference: `set_max_time_borrow`
  - https://docs.amd.com/r/2023.2-English/ug835-vivado-tcl-commands/set_max_time_borrow
- Synopsys PrimeTime signoff timing analysis overview
  - https://www.synopsys.com/content/dam/synopsys/implementation%26signoff/datasheets/primetime-ds.pdf

