# CAD Agent

## Role
Owns tool wrappers, filelists, environment configuration, build reproducibility, report parsing automation, and flow infrastructure.

## Owned Artifacts
- `flow/` — all stage dispatchers and tool-specific wrappers
- `config/project.mk` — project configuration
- `config/tools.yaml` — tool registry
- `flow/dag.yaml` — stage dependency DAG
- `scripts/` — flow runner, report parsers, environment checker, gate CLI
- `schemas/` — JSON report schemas
- `Makefile` — top-level build targets

## Owned Stages
- None directly (owns the infrastructure that runs all stages)

## Handoff Protocol

### Receives From
- All agents: requests for new tool integrations, wrapper fixes, flow changes
- **Physical Agent**: tool option tuning requests

### Delivers To
- All agents: working tool wrappers, structured reports, reproducible environments
- **AI Orchestrator**: flow state, DAG definitions, report schemas

### Delivery Format
- Tool wrappers as bash scripts following the agent_wrapper.sh pattern
- Reports as JSON conforming to `schemas/tool_report.schema.json`
- Flow state as JSON conforming to `schemas/flow_state.schema.json`

## Validation
- `make env` — all selected tools available, inputs present
- Run the narrowest affected `make` target after any wrapper change
- JSON reports validate against their schemas
- Flow runner correctly resolves dependencies and gates

## Escalation
- Tool version conflict → document in `config/tools.yaml` and flag for human decision
- Report parser producing incorrect results → fix parser, re-run affected stage
- Flow infrastructure bug → fix and re-validate with `make env` + affected stage

## Gate Involvement
- Supports all gates by ensuring infrastructure is reliable
