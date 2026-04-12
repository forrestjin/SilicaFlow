#!/usr/bin/env python3
"""
SilicaFlow — Report Parser Library

Parses raw EDA tool logs into the structured JSON report format
defined in schemas/tool_report.schema.json.

Each parser function takes a raw log path and returns a dict
conforming to the report schema. The agent_wrapper.sh calls
these parsers after tool execution.

Usage as CLI:
  parse_report.py <stage> <tool> <log_path> <report_path>

Usage as library:
  from parse_report import parse_lint_verible
  report = parse_lint_verible("reports/lint/verible.log")
"""

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _base_report(stage: str, tool: str) -> dict:
    return {
        "schema_version": "1.0.0",
        "stage": stage,
        "tool": tool,
        "tool_version": "",
        "timestamp": _now(),
        "duration_seconds": 0,
        "exit_code": 0,
        "pass": True,
        "summary": "",
        "metrics": {"errors": 0, "warnings": 0, "info": 0},
        "violations": [],
        "artifacts": [],
        "input_hashes": {},
        "raw_log": ""
    }


# ── Lint parsers ─────────────────────────────────────────────

def parse_lint_verible(log_path: str) -> dict:
    """Parse Verible lint output."""
    report = _base_report("lint", "verible")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    errors, warnings = 0, 0
    for line in text.splitlines():
        # Verible format: file:line:col: error/warning: message [rule]
        m = re.match(r'(.+?):(\d+):(\d+):\s*(error|warning|note):\s*(.+?)(?:\s*\[(.+?)\])?\s*$', line)
        if m:
            sev = {"error": "error", "warning": "warning", "note": "info"}.get(m.group(4), "info")
            if sev == "error": errors += 1
            elif sev == "warning": warnings += 1
            report["violations"].append({
                "severity": sev,
                "message": m.group(5).strip(),
                "file": m.group(1),
                "line": int(m.group(2)),
                "rule": m.group(6) or ""
            })

    report["metrics"] = {"errors": errors, "warnings": warnings, "info": 0}
    report["pass"] = errors == 0
    report["summary"] = f"{errors} errors, {warnings} warnings"
    report["exit_code"] = 1 if errors > 0 else 0
    return report


# ── Parse parsers ────────────────────────────────────────────

def parse_parse_surelog(log_path: str) -> dict:
    """Parse Surelog output."""
    report = _base_report("parse", "surelog")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    errors = len(re.findall(r'\[ERR:', text))
    warnings = len(re.findall(r'\[WRN:', text))
    fatals = len(re.findall(r'\[FAT:', text))

    report["metrics"] = {"errors": errors + fatals, "warnings": warnings, "info": 0}
    report["pass"] = (errors + fatals) == 0
    report["summary"] = f"{errors + fatals} errors, {warnings} warnings"
    report["exit_code"] = 1 if (errors + fatals) > 0 else 0
    return report


# ── Sim parsers ──────────────────────────────────────────────

def parse_sim_verilator(log_path: str) -> dict:
    """Parse Verilator simulation output."""
    report = _base_report("sim", "verilator")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    # Look for common pass/fail patterns
    passed = "PASS" in text.upper() or "ALL TESTS PASSED" in text.upper()
    failed = "FAIL" in text.upper() or "ERROR" in text.upper() or "ABORT" in text.upper()
    assertions = len(re.findall(r'Assertion failed', text, re.IGNORECASE))

    if assertions > 0:
        passed = False
        failed = True

    report["metrics"] = {"errors": assertions, "warnings": 0, "tests_passed": 1 if passed else 0}
    report["pass"] = passed and not failed
    report["summary"] = "PASS" if report["pass"] else f"FAIL ({assertions} assertion failures)"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── Formal parsers ───────────────────────────────────────────

def parse_formal_symbiyosys(log_path: str) -> dict:
    """Parse SymbiYosys output."""
    report = _base_report("formal", "symbiyosys")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    proved = len(re.findall(r'PASS', text))
    failed = len(re.findall(r'FAIL', text))
    unknown = len(re.findall(r'UNKNOWN', text))

    report["metrics"] = {"proved": proved, "failed": failed, "unknown": unknown}
    report["pass"] = failed == 0 and unknown == 0
    report["summary"] = f"{proved} proved, {failed} failed, {unknown} unknown"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── CDC parsers ──────────────────────────────────────────────

def parse_cdc_yosys(log_path: str) -> dict:
    """Parse Yosys CDC check output."""
    report = _base_report("cdc", "yosys")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    crossings = len(re.findall(r'CDC crossing', text, re.IGNORECASE))
    violations = len(re.findall(r'ERROR|VIOLATION', text, re.IGNORECASE))

    report["metrics"] = {"crossings": crossings, "violations": violations}
    report["pass"] = violations == 0
    report["summary"] = f"{crossings} crossings found, {violations} violations"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── Synth parsers ────────────────────────────────────────────

def parse_synth_yosys(log_path: str) -> dict:
    """Parse Yosys synthesis output."""
    report = _base_report("synth", "yosys")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    # Extract cell count from stat output
    cells = 0
    m = re.search(r'Number of cells:\s+(\d+)', text)
    if m:
        cells = int(m.group(1))

    wires = 0
    m = re.search(r'Number of wires:\s+(\d+)', text)
    if m:
        wires = int(m.group(1))

    area = 0.0
    m = re.search(r'Chip area.*?:\s+([\d.]+)', text)
    if m:
        area = float(m.group(1))

    errors = len(re.findall(r'^ERROR:', text, re.MULTILINE))
    warnings = len(re.findall(r'^Warning:', text, re.MULTILINE))

    report["metrics"] = {
        "errors": errors, "warnings": warnings,
        "cells": cells, "wires": wires, "area": area
    }
    report["pass"] = errors == 0
    report["summary"] = f"{cells} cells, area={area}, {errors} errors, {warnings} warnings"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── STA parsers ──────────────────────────────────────────────

def parse_sta_opensta(log_path: str) -> dict:
    """Parse OpenSTA output."""
    report = _base_report("sta_pre", "opensta")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    # Extract worst slack
    wns = None
    m = re.search(r'worst slack\s+([-\d.]+)', text, re.IGNORECASE)
    if m:
        wns = float(m.group(1))

    tns = None
    m = re.search(r'tns\s+([-\d.]+)', text, re.IGNORECASE)
    if m:
        tns = float(m.group(1))

    # Count violating paths
    violations = len(re.findall(r'VIOLATED', text))

    report["metrics"] = {
        "wns": wns if wns is not None else 0,
        "tns": tns if tns is not None else 0,
        "violating_paths": violations
    }
    report["pass"] = (wns is None or wns >= 0) and violations == 0
    wns_str = f"{wns:.3f}" if wns is not None else "N/A"
    tns_str = f"{tns:.3f}" if tns is not None else "N/A"
    report["summary"] = f"WNS={wns_str} TNS={tns_str} violations={violations}"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── LEC parsers ──────────────────────────────────────────────

def parse_lec_yosys(log_path: str) -> dict:
    """Parse Yosys equivalence checking output."""
    report = _base_report("lec", "yosys")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    equiv = "Equivalence successfully proven" in text or "equiv_status" in text.lower()
    errors = len(re.findall(r'ERROR', text))

    report["metrics"] = {"equivalent": equiv, "errors": errors}
    report["pass"] = equiv and errors == 0
    report["summary"] = "EQUIVALENT" if equiv else "NOT EQUIVALENT"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── PnR parsers ──────────────────────────────────────────────

def parse_pnr_openroad(log_path: str) -> dict:
    """Parse OpenROAD PnR output."""
    report = _base_report("pnr", "openroad")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    # Extract utilization
    util = 0.0
    m = re.search(r'Design area\s+\d+\s*/\s*\d+\s*=\s*([\d.]+)%', text)
    if m:
        util = float(m.group(1))

    # DRV count
    drvs = 0
    m = re.search(r'Number of DRC violations:\s*(\d+)', text)
    if m:
        drvs = int(m.group(1))

    errors = len(re.findall(r'\[ERROR', text))

    report["metrics"] = {"utilization_pct": util, "drv_count": drvs, "errors": errors}
    report["pass"] = errors == 0
    report["summary"] = f"util={util:.1f}%, DRVs={drvs}, errors={errors}"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── Power parsers ────────────────────────────────────────────

def parse_power_openroad(log_path: str) -> dict:
    """Parse OpenROAD power analysis output."""
    report = _base_report("power", "openroad")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    total_power = 0.0
    m = re.search(r'Total\s+Power.*?:\s*([\d.eE+-]+)', text)
    if m:
        total_power = float(m.group(1))

    report["metrics"] = {"total_power_mw": total_power}
    report["pass"] = True  # Power is informational unless budget is set
    report["summary"] = f"total_power={total_power}mW"
    report["exit_code"] = 0
    return report


# ── DRC parsers ──────────────────────────────────────────────

def parse_drc_klayout(log_path: str) -> dict:
    """Parse KLayout DRC output."""
    report = _base_report("drc", "klayout")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    violations = 0
    # KLayout XML report format
    violations = len(re.findall(r'<item>', text))
    # Also check for text-based count
    m = re.search(r'(\d+)\s+DRC violations', text)
    if m:
        violations = int(m.group(1))

    report["metrics"] = {"violations": violations}
    report["pass"] = violations == 0
    report["summary"] = f"{violations} DRC violations"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── LVS parsers ──────────────────────────────────────────────

def parse_lvs_klayout(log_path: str) -> dict:
    """Parse KLayout LVS output."""
    report = _base_report("lvs", "klayout")
    report["raw_log"] = log_path
    text = Path(log_path).read_text() if Path(log_path).exists() else ""

    clean = "LVS clean" in text or "netlists match" in text.lower()
    errors = len(re.findall(r'ERROR|MISMATCH', text, re.IGNORECASE))

    report["metrics"] = {"clean": clean, "errors": errors}
    report["pass"] = clean and errors == 0
    report["summary"] = "LVS CLEAN" if clean else f"LVS ERRORS: {errors}"
    report["exit_code"] = 0 if report["pass"] else 1
    return report


# ── Parser registry ──────────────────────────────────────────

PARSERS = {
    ("lint", "verible"): parse_lint_verible,
    ("parse", "surelog"): parse_parse_surelog,
    ("sim", "verilator"): parse_sim_verilator,
    ("formal", "symbiyosys"): parse_formal_symbiyosys,
    ("cdc", "yosys"): parse_cdc_yosys,
    ("synth", "yosys"): parse_synth_yosys,
    ("sta_pre", "opensta"): parse_sta_opensta,
    ("sta_post", "opensta"): parse_sta_opensta,
    ("lec", "yosys"): parse_lec_yosys,
    ("pnr", "openroad"): parse_pnr_openroad,
    ("power", "openroad"): parse_power_openroad,
    ("drc", "klayout"): parse_drc_klayout,
    ("lvs", "klayout"): parse_lvs_klayout,
}


def parse_report(stage: str, tool: str, log_path: str) -> dict:
    """Look up and run the appropriate parser."""
    key = (stage, tool)
    parser = PARSERS.get(key)
    if parser:
        return parser(log_path)
    # Generic fallback
    report = _base_report(stage, tool)
    report["raw_log"] = log_path
    report["summary"] = "No parser available — check raw log"
    return report


# ── CLI ──────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 5:
        print(f"Usage: {sys.argv[0]} <stage> <tool> <log_path> <report_path>", file=sys.stderr)
        sys.exit(2)

    stage, tool, log_path, report_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    report = parse_report(stage, tool, log_path)

    Path(report_path).parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)

    print(f"Report: {report_path} — {report['summary']}")
    sys.exit(report["exit_code"])


if __name__ == "__main__":
    main()
