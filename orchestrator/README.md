# SilicaFlow Orchestrator

The orchestrator is the AI brain that drives the SilicaFlow design flow. It reads
the DAG, invokes EDA tool agents, interprets structured reports, proposes fixes for
failures, and pauses at human gates for engineer approval.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AI ORCHESTRATOR                           │
│                                                             │
│  recipe.yaml          — AI orchestrator recipe for flow orchestration │
│  skills/              — Per-stage diagnostic skills          │
│  decision_trees/      — Per-failure-type decision logic      │
│                                                             │
│  Reads:  flow/dag.yaml, reports/*/report.json               │
│  Writes: work/flow_state.json, work/gates/                  │
│  Calls:  make <stage>, scripts/gate.sh, scripts/flow_runner │
└─────────────────────────────────────────────────────────────┘
```

## How It Works

1. **Check status** — read `work/flow_state.json` and `flow/dag.yaml`
2. **Find next stage** — topological sort, skip passed, identify runnable
3. **Check gate** — if a gate blocks the next stage, present the gate checklist
   to the human and wait for `make approve`
4. **Run stage** — invoke `make <stage>`, which dispatches to the selected tool
5. **Interpret report** — read `reports/<stage>/report.json`
   - **Pass** → advance to next stage
   - **Fail (fixable)** → diagnose using the appropriate skill, propose a fix,
     present to human for approval, apply, re-run
   - **Fail (needs human)** → present diagnosis and escalate
6. **Repeat** until all stages pass or a gate/failure blocks progress

## Usage

```bash
# Run the full orchestrated flow
make orchestrate

# Or use the flow runner directly
python3 scripts/flow_runner.py run-all

# Check current state
make status
```

## Adding Skills

Skills are prompt templates that the orchestrator uses to diagnose failures.
Each skill corresponds to a flow stage and is stored in `skills/`.

To add a new diagnostic skill:
1. Create `skills/diagnose_<stage>.md` following the template pattern
2. The orchestrator will automatically use it when that stage fails
