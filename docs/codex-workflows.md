# SilicaFlow Codex Workflows

Use Codex on bounded SilicaFlow artifacts, not vague stages.

Good tasks:

- "Turn this draft PRD into requirement IDs, acceptance criteria, and a traceability starter table."
- "Compare two architecture options using these workload assumptions and update the PPA budget table."
- "Read `reports/sta/opensta.log` and cluster the top failing paths by endpoint, launch clock, and probable root cause."
- "Turn `specs/foo.md` into `design/rtl/foo.sv` and `design/formal/foo_properties.sv`, then run `make lint parse`."
- "Diff two QoR reports and explain which path groups regressed after the SDC change."
- "Review the package SI report and bump map revision, then identify the top integration risks."
- "Cluster post-silicon failures by probable logic, package, process, or tester cause."

Bad tasks:

- "Fix timing."
- "Do back-end."
- "Make this signoff clean."

For every task, require:

- exact input files
- exact output artifact
- validation command
- assumptions called out explicitly
