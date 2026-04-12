#!/usr/bin/env python3
"""
SilicaFlow — DAG-Aware Flow Runner

Reads flow/dag.yaml, tracks state in work/flow_state.json, and executes
stages in dependency order. Supports:
  - Dependency-aware execution
  - Staleness detection via input file hashing
  - Human gate enforcement
  - Tool-agnostic dispatch (reads TOOL_<STAGE> from environment)
  - Structured JSON status output

Usage:
  flow_runner.py status          — show DAG status
  flow_runner.py run [stage]     — run a stage (or all runnable stages)
  flow_runner.py run-all         — run all stages in dependency order
  flow_runner.py stale           — list stale stages
  flow_runner.py reset [stage]   — reset a stage (or all) to pending
  flow_runner.py dot             — emit Graphviz DOT of the DAG
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    # Inline minimal YAML parser for dag.yaml (avoids hard dependency)
    yaml = None

# ── Paths ────────────────────────────────────────────────────
ROOT_DIR = Path(os.environ.get("ROOT_DIR", Path(__file__).resolve().parent.parent))
DAG_FILE = ROOT_DIR / "flow" / "dag.yaml"
STATE_FILE = ROOT_DIR / "work" / "flow_state.json"
GATE_DIR = ROOT_DIR / "work" / "gates"

# ── YAML loading ─────────────────────────────────────────────

def load_yaml(path: Path) -> dict:
    """Load YAML file. Uses PyYAML if available, else falls back to subprocess."""
    if yaml:
        with open(path) as f:
            return yaml.safe_load(f)
    # Fallback: try python -c with yaml
    try:
        result = subprocess.run(
            [sys.executable, "-c",
             f"import yaml, json, sys; print(json.dumps(yaml.safe_load(open('{path}'))))"],
            capture_output=True, text=True, check=True
        )
        return json.loads(result.stdout)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"ERROR: Cannot parse {path}. Install PyYAML: pip install pyyaml", file=sys.stderr)
        sys.exit(2)

# ── State management ─────────────────────────────────────────

def load_state() -> dict:
    """Load or initialize flow state."""
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {
        "schema_version": "1.0.0",
        "project": os.environ.get("TOP", "unknown"),
        "last_updated": _now(),
        "stages": {},
        "gates": {}
    }

def save_state(state: dict):
    """Persist flow state."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    state["last_updated"] = _now()
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# ── Hashing ──────────────────────────────────────────────────

def hash_file(path: str) -> str:
    """SHA-256 of a file, with env var expansion."""
    expanded = os.path.expandvars(path)
    p = Path(expanded)
    if not p.exists():
        return "missing"
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def compute_input_hashes(inputs: list) -> dict:
    """Hash all input files for a stage."""
    return {inp: hash_file(inp) for inp in inputs}

# ── Gate checking ────────────────────────────────────────────

def gate_status(gate_name: str) -> str:
    """Check if a gate is approved."""
    gate_file = GATE_DIR / f"{gate_name}.json"
    if not gate_file.exists():
        return "pending"
    with open(gate_file) as f:
        data = json.load(f)
    return data.get("status", "pending")

# ── DAG operations ───────────────────────────────────────────

def topo_sort(dag_stages: dict) -> list:
    """Topological sort of stages by dependencies."""
    visited = set()
    order = []

    def visit(name):
        if name in visited:
            return
        visited.add(name)
        stage = dag_stages.get(name, {})
        for dep in stage.get("depends_on", []):
            visit(dep)
        order.append(name)

    for name in dag_stages:
        visit(name)
    return order

def get_stage_status(state: dict, dag: dict, stage_name: str) -> str:
    """Determine effective status of a stage, including staleness and gate blocks."""
    stage_def = dag["stages"].get(stage_name, {})
    stage_state = state["stages"].get(stage_name, {})
    recorded = stage_state.get("status", "pending")

    # Check if blocked by a gate
    gate_after = stage_def.get("gate_after")
    if gate_after:
        gs = gate_status(gate_after)
        if gs != "approved":
            return "blocked"

    # Check if dependencies have passed
    for dep in stage_def.get("depends_on", []):
        dep_status = state["stages"].get(dep, {}).get("status", "pending")
        if dep_status not in ("passed",):
            if recorded == "pending":
                return "blocked"

    # Check staleness: if inputs changed since last run
    if recorded == "passed" and "input_hashes" in stage_state:
        current_hashes = compute_input_hashes(stage_def.get("inputs", []))
        if current_hashes != stage_state.get("input_hashes", {}):
            return "stale"

    return recorded

# ── Execution ────────────────────────────────────────────────

def resolve_tool(stage_name: str, stage_def: dict) -> str:
    """Resolve which tool to use for a stage."""
    tool_var = stage_def.get("tool_var", f"TOOL_{stage_name.upper()}")
    return os.environ.get(tool_var, "unknown")

def resolve_run_script(stage_def: dict, stage_name: str, tool: str) -> Path:
    """Find the run.sh for a stage. Prefers the dispatcher, falls back to tool-specific."""
    phase = stage_def.get("phase", "frontend")

    # Map phases to directory paths
    if phase == "frontend":
        base = ROOT_DIR / "flow" / "frontend" / stage_name
    elif phase == "synthesis":
        base = ROOT_DIR / "flow" / "frontend" / stage_name  # synth lives under frontend
    elif phase == "backend":
        # Handle sta_pre/sta_post → sta directory
        dir_name = stage_name.replace("_pre", "").replace("_post", "")
        base = ROOT_DIR / "flow" / "backend" / dir_name
    elif phase == "signoff":
        base = ROOT_DIR / "flow" / "backend" / "signoff" / stage_name
    else:
        base = ROOT_DIR / "flow" / phase / stage_name

    # Try dispatcher first, then tool-specific
    dispatcher = base / "run.sh"
    tool_specific = base / tool / "run.sh"

    if dispatcher.exists():
        return dispatcher
    if tool_specific.exists():
        return tool_specific

    return dispatcher  # Will fail at runtime with a clear error

def run_stage(dag: dict, state: dict, stage_name: str, force: bool = False) -> bool:
    """Execute a single stage. Returns True if passed."""
    stage_def = dag["stages"][stage_name]
    status = get_stage_status(state, dag, stage_name)

    if status == "blocked" and not force:
        gate = stage_def.get("gate_after", "")
        deps = stage_def.get("depends_on", [])
        print(f"🔒 {stage_name}: blocked", file=sys.stderr)
        if gate and gate_status(gate) != "approved":
            print(f"   Gate '{gate}' not approved. Run: make approve GATE={gate}", file=sys.stderr)
        for dep in deps:
            ds = state["stages"].get(dep, {}).get("status", "pending")
            if ds != "passed":
                print(f"   Dependency '{dep}' is {ds}", file=sys.stderr)
        return False

    if status == "passed" and not force:
        print(f"✅ {stage_name}: already passed (use --force to re-run)")
        return True

    tool = resolve_tool(stage_name, stage_def)
    script = resolve_run_script(stage_def, stage_name, tool)

    print(f"▶ Running {stage_name} with {tool}...")

    # Set stage-specific env vars
    env = os.environ.copy()
    env["SILICAFLOW_STAGE"] = stage_name
    env["SILICAFLOW_TOOL"] = tool

    # Hash inputs before run
    input_hashes = compute_input_hashes(stage_def.get("inputs", []))

    start = time.time()
    try:
        result = subprocess.run(
            ["bash", str(script)],
            env=env,
            cwd=str(ROOT_DIR)
        )
        rc = result.returncode
    except FileNotFoundError:
        print(f"❌ {stage_name}: script not found: {script}", file=sys.stderr)
        rc = 2
    duration = time.time() - start

    # Read the report if it was generated
    report_path = os.path.expandvars(stage_def.get("report", ""))
    passed = False
    summary = f"exit_code={rc}"
    if report_path and Path(report_path).exists():
        try:
            with open(report_path) as f:
                report = json.load(f)
            passed = report.get("pass", False)
            summary = report.get("summary", summary)
        except (json.JSONDecodeError, KeyError):
            passed = (rc == 0)
    else:
        passed = (rc == 0)

    # Update state
    state["stages"][stage_name] = {
        "status": "passed" if passed else "failed",
        "tool": tool,
        "last_run": _now(),
        "duration_seconds": round(duration, 1),
        "input_hashes": input_hashes,
        "report_path": report_path,
        "pass": passed,
        "summary": summary
    }
    save_state(state)

    icon = "✅" if passed else "❌"
    print(f"{icon} {stage_name}: {'passed' if passed else 'FAILED'} ({duration:.1f}s) — {summary}")
    return passed

# ── Commands ─────────────────────────────────────────────────

def cmd_status(dag: dict, state: dict):
    """Print DAG status."""
    order = topo_sort(dag["stages"])
    gates = dag.get("gates", {})

    print("═" * 70)
    print(" SilicaFlow — Flow Status")
    print("═" * 70)

    # Gates
    print("\n 🔒 GATES:")
    print(f"   {'Gate':<22} {'Status':<12} {'Details'}")
    print("   " + "─" * 55)
    for gname in gates:
        gs = gate_status(gname)
        icon = {"approved": "✅", "rejected": "❌", "pending": "⏳"}.get(gs, "❓")
        details = ""
        gate_file = GATE_DIR / f"{gname}.json"
        if gate_file.exists():
            with open(gate_file) as f:
                gdata = json.load(f)
            details = f"by {gdata.get('by', '?')} at {gdata.get('timestamp', '?')}"
        print(f"   {gname:<22} {icon} {gs:<10} {details}")

    # Stages
    print(f"\n 📋 STAGES:")
    print(f"   {'Stage':<16} {'Phase':<12} {'Status':<10} {'Tool':<14} {'Duration':<10} {'Summary'}")
    print("   " + "─" * 80)
    for sname in order:
        sdef = dag["stages"][sname]
        effective = get_stage_status(state, dag, sname)
        sstate = state["stages"].get(sname, {})
        tool = sstate.get("tool", "-")
        dur = sstate.get("duration_seconds", "")
        dur_str = f"{dur}s" if dur else "-"
        summary = sstate.get("summary", "")[:40]
        icon = {
            "passed": "✅", "failed": "❌", "running": "🔄",
            "stale": "🔶", "blocked": "🔒", "pending": "⏳", "skipped": "⏭"
        }.get(effective, "❓")
        print(f"   {sname:<16} {sdef.get('phase','?'):<12} {icon} {effective:<8} {tool:<14} {dur_str:<10} {summary}")

    print("═" * 70)

def cmd_run(dag: dict, state: dict, stage_name: str = None, force: bool = False):
    """Run a specific stage or the next runnable stage."""
    if stage_name:
        if stage_name not in dag["stages"]:
            print(f"ERROR: Unknown stage '{stage_name}'", file=sys.stderr)
            sys.exit(2)
        run_stage(dag, state, stage_name, force)
    else:
        # Run next runnable stage
        order = topo_sort(dag["stages"])
        ran_any = False
        for sname in order:
            status = get_stage_status(state, dag, sname)
            if status in ("pending", "stale", "failed"):
                # Check deps
                sdef = dag["stages"][sname]
                deps_ok = all(
                    state["stages"].get(d, {}).get("status") == "passed"
                    for d in sdef.get("depends_on", [])
                )
                gate = sdef.get("gate_after")
                gate_ok = not gate or gate_status(gate) == "approved"
                if deps_ok and gate_ok:
                    success = run_stage(dag, state, sname, force)
                    ran_any = True
                    if not success:
                        print(f"\n⛔ Stopping: {sname} failed.", file=sys.stderr)
                        break
        if not ran_any:
            print("Nothing to run. All stages are passed, blocked, or have unmet dependencies.")
            print("Run 'make status' to see the flow state.")

def cmd_run_all(dag: dict, state: dict, force: bool = False):
    """Run all stages in topological order, stopping on failure or gate."""
    order = topo_sort(dag["stages"])
    for sname in order:
        status = get_stage_status(state, dag, sname)
        if status == "passed" and not force:
            print(f"✅ {sname}: already passed")
            continue
        if status == "blocked":
            sdef = dag["stages"][sname]
            gate = sdef.get("gate_after", "")
            if gate and gate_status(gate) != "approved":
                print(f"🔒 {sname}: blocked by gate '{gate}' — pausing flow")
                print(f"   Review: docs/gates/ and run: make approve GATE={gate}")
                return
            print(f"🔒 {sname}: blocked by unmet dependencies")
            return
        success = run_stage(dag, state, sname, force)
        if not success:
            print(f"\n⛔ Flow stopped: {sname} failed.", file=sys.stderr)
            return

    print("\n🎉 All stages complete!")

def cmd_stale(dag: dict, state: dict):
    """List stale stages."""
    order = topo_sort(dag["stages"])
    stale = [s for s in order if get_stage_status(state, dag, s) == "stale"]
    if stale:
        print("Stale stages (inputs changed since last pass):")
        for s in stale:
            print(f"  🔶 {s}")
    else:
        print("No stale stages.")

def cmd_reset(dag: dict, state: dict, stage_name: str = None):
    """Reset a stage or all stages to pending."""
    if stage_name:
        state["stages"].pop(stage_name, None)
        print(f"🔄 Reset {stage_name} to pending")
    else:
        state["stages"] = {}
        print("🔄 Reset all stages to pending")
    save_state(state)

def cmd_dot(dag: dict, state: dict):
    """Emit Graphviz DOT representation of the DAG."""
    print("digraph SilicaFlow {")
    print("  rankdir=LR;")
    print("  node [shape=box, style=rounded];")

    # Color nodes by status
    colors = {
        "passed": "green", "failed": "red", "running": "blue",
        "stale": "orange", "blocked": "gray", "pending": "white"
    }
    for sname, sdef in dag["stages"].items():
        status = get_stage_status(state, dag, sname)
        color = colors.get(status, "white")
        label = f"{sname}\\n({sdef.get('phase', '?')})"
        print(f'  "{sname}" [label="{label}", fillcolor={color}, style="rounded,filled"];')

    # Edges
    for sname, sdef in dag["stages"].items():
        for dep in sdef.get("depends_on", []):
            print(f'  "{dep}" -> "{sname}";')

    # Gate edges (dashed)
    for gname, gdef in dag.get("gates", {}).items():
        print(f'  "{gname}" [shape=diamond, fillcolor=yellow, style=filled];')
        for blocked in gdef.get("blocks", []):
            if blocked in dag["stages"]:
                print(f'  "{gname}" -> "{blocked}" [style=dashed, color=red];')

    print("}")

# ── Main ─────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="SilicaFlow DAG-aware flow runner")
    parser.add_argument("command", choices=["status", "run", "run-all", "stale", "reset", "dot"],
                        help="Command to execute")
    parser.add_argument("stage", nargs="?", default=None, help="Stage name (for run/reset)")
    parser.add_argument("--force", action="store_true", help="Force re-run even if passed")
    args = parser.parse_args()

    dag = load_yaml(DAG_FILE)
    state = load_state()

    if args.command == "status":
        cmd_status(dag, state)
    elif args.command == "run":
        cmd_run(dag, state, args.stage, args.force)
    elif args.command == "run-all":
        cmd_run_all(dag, state, args.force)
    elif args.command == "stale":
        cmd_stale(dag, state)
    elif args.command == "reset":
        cmd_reset(dag, state, args.stage)
    elif args.command == "dot":
        cmd_dot(dag, state)

if __name__ == "__main__":
    main()
