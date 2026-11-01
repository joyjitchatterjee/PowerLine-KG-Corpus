"""
Integrity validation for the PowerLine O&M knowledge graph decision rules.

This validator checks the decision-support invariants of the graph itself - the properties the Reasoner Agent and the
paper rely on:

 1. The maintenance action is a function of the (defect, severity) pair:
    exactly ONE ``REQUIRES`` edge per (DefectType, when_severity), and every
    ``REQUIRES`` edge carries a ``when_severity`` in {1, 2, 3}.
 2. Per defect, the set of ``HAS_SEVERITY`` levels equals the set of
    ``when_severity`` values on its ``REQUIRES`` edges (every plausible
    severity has exactly one action, and no action targets an impossible
    severity).
 3. Severity level 0 ('normal') is reserved for defect-free evidence: no
    DefectType links to it.
 4. The four Severity nodes form the explicit ordinal chain
    0 -ESCALATES_TO-> 1 -> 2 -> 3.
 5. Node counts match the published ontology (18 components, 5 defects,
    4 severities, 8 failure modes, 6 risks, 3 environments, 7 standards,
    8 maintenance actions, 3 work-order templates).
Static mode (default) needs no database - it parses ``seed_data.cypher`` only. Live mode (``--live``) runs the same invariants against a
running Neo4j instance and additionally detects duplicate parallel
relationships (the artifact of re-running the seed loader on a seeded graph).

Usage:
    python ontology/validate_graph.py            # static, no Neo4j required
    python ontology/validate_graph.py --live     # validate the live graph
"""

from __future__ import annotations

import argparse
import os
import csv
import re
import sys
from pathlib import Path

from load_ontology import parse_cypher_file

REPO_ROOT = Path(__file__).resolve().parents[1]
ONTOLOGY_DIR = REPO_ROOT / "ontology"
SEED_FILE = ONTOLOGY_DIR / "seed_data.cypher"
REPORT_FILE = REPO_ROOT / "outputs" / "research_readiness" / "kg_integrity_report.md"

ALL_LEVELS = {0, 1, 2, 3}
DEFECT_LEVELS = {1, 2, 3}
SEVERITY_LABEL_TO_LEVEL = {"normal": 0, "minor": 1, "moderate": 2, "severe": 3}

# Canonical Severity node properties (mirrors seed_data.cypher section 7).
CANONICAL_SEVERITIES = {0: 0.0, 1: 0.2, 2: 0.5, 3: 1.0}

# Published ontology counts (paper Section 5 / ontology README).
EXPECTED_COUNTS = {
    "ComponentType": 18,
    "DefectType": 5,
    "Severity": 4,
    "FailureMode": 8,
    "Risk": 6,
    "Environment": 3,
    "Standard": 7,
    "MaintenanceAction": 8,
    "WorkOrderTemplate": 3,
}


# ---------------------------------------------------------------------------
# Seed parsing (canonical rule table)
# ---------------------------------------------------------------------------

def _created_node_count(label: str, statements: list[str]) -> int:
    pattern = re.compile(rf"CREATE\s*\([A-Za-z0-9_]+:{label}\s*\{{")
    return sum(len(pattern.findall(stmt)) for stmt in statements)


def parse_requires_rules(statements: list[str]) -> dict[tuple[str, int], dict]:
    """Parse the canonical (defect, when_severity) -> action rule table."""
    rules: dict[tuple[str, int], dict] = {}
    for stmt in statements:
        if "[:REQUIRES" not in stmt or "when_severity" not in stmt:
            continue
        defect = re.search(r"DefectType\s*\{name:\s*'([^']+)'\}", stmt)
        action = re.search(r"MaintenanceAction\s*\{name:\s*'([^']+)'\}", stmt)
        severity = re.search(r"when_severity:\s*(\d+)", stmt)
        rationale = re.search(r"rationale:\s*'((?:[^'\\]|\\.)*)'", stmt)
        if not (defect and action and severity):
            continue
        key = (defect.group(1), int(severity.group(1)))
        if key in rules:
            raise ValueError(
                f"seed_data.cypher defines more than one REQUIRES rule for {key}"
            )
        rules[key] = {
            "action": action.group(1),
            "rationale": rationale.group(1) if rationale else "",
        }
    return rules


def parse_has_severity(statements: list[str]) -> dict[str, set[int]]:
    """Parse the severity levels each defect is mapped to via HAS_SEVERITY."""
    mapping: dict[str, set[int]] = {}
    for stmt in statements:
        if "[:HAS_SEVERITY" not in stmt or "DefectType" not in stmt:
            continue
        defect = re.search(r"DefectType\s*\{name:\s*'([^']+)'\}", stmt)
        if not defect:
            continue
        levels = set(ALL_LEVELS)
        for op, value in re.findall(r"s\.level\s*(>=|<=|=)\s*(\d+)", stmt):
            value = int(value)
            if op == ">=":
                levels = {lv for lv in levels if lv >= value}
            elif op == "<=":
                levels = {lv for lv in levels if lv <= value}
            else:
                levels = {value}
        mapping.setdefault(defect.group(1), set()).update(levels)
    return mapping


def parse_seed() -> dict:
    statements = parse_cypher_file(SEED_FILE)
    return {
        "statements": statements,
        "rules": parse_requires_rules(statements),
        "has_severity": parse_has_severity(statements),
        "counts": {
            label: _created_node_count(label, statements)
            for label in EXPECTED_COUNTS
        },
        "has_escalates": any("ESCALATES_TO" in stmt for stmt in statements),
    }


# ---------------------------------------------------------------------------
# Shared invariant checks over a rule table
# ---------------------------------------------------------------------------

def rule_invariant_checks(
    rules: dict[tuple[str, int], dict],
    has_severity: dict[str, set[int]],
    checks: dict[str, bool],
    problems: list[str],
    prefix: str = "",
) -> None:
    bad_levels = sorted(k for k in rules if k[1] not in DEFECT_LEVELS)
    checks[f"{prefix}requires_when_severity_in_1_to_3"] = not bad_levels
    for key in bad_levels:
        problems.append(f"REQUIRES rule {key} uses a severity outside 1-3")

    level_zero = sorted(d for d, lv in has_severity.items() if 0 in lv)
    checks[f"{prefix}no_defect_mapped_to_severity_0"] = not level_zero
    for defect in level_zero:
        problems.append(
            f"DefectType '{defect}' has HAS_SEVERITY to level 0 ('normal'); "
            "level 0 is reserved for defect-free evidence"
        )

    mismatches: list[str] = []
    for defect, levels in sorted(has_severity.items()):
        rule_levels = {sv for (d, sv) in rules if d == defect}
        expected = {lv for lv in levels if lv in DEFECT_LEVELS}
        if rule_levels != expected:
            mismatches.append(
                f"'{defect}': HAS_SEVERITY levels {sorted(expected)} vs "
                f"REQUIRES severities {sorted(rule_levels)}"
            )
    checks[f"{prefix}severity_levels_match_action_rules"] = not mismatches
    for m in mismatches:
        problems.append(f"Severity/action rule mismatch for {m}")


# ---------------------------------------------------------------------------
# Static checks (seed file + evidence artifacts)
# ---------------------------------------------------------------------------

def static_checks(seed: dict) -> tuple[dict[str, bool], list[str]]:
    checks: dict[str, bool] = {}
    problems: list[str] = []

    for label, expected in EXPECTED_COUNTS.items():
        actual = seed["counts"][label]
        checks[f"seed_{label}_count_{expected}"] = actual == expected
        if actual != expected:
            problems.append(f"{label}: seed defines {actual}, expected {expected}")

    checks["seed_severity_escalation_chain_defined"] = seed["has_escalates"]
    if not seed["has_escalates"]:
        problems.append("Severity ESCALATES_TO ordinal chain missing from seed")

    rule_invariant_checks(seed["rules"], seed["has_severity"], checks, problems)

    return checks, problems


# ---------------------------------------------------------------------------
# Live checks (running Neo4j)
# ---------------------------------------------------------------------------

def live_checks(uri: str, user: str, password: str) -> tuple[dict[str, bool], list[str]]:
    from neo4j import GraphDatabase

    checks: dict[str, bool] = {}
    problems: list[str] = []
    core_labels = list(EXPECTED_COUNTS) + [
        "Asset", "Condition", "AgentRole", "Dataset", "SimulationModel",
    ]

    driver = GraphDatabase.driver(uri, auth=(user, password))
    try:
        driver.verify_connectivity()
        with driver.session() as session:
            for label, expected in EXPECTED_COUNTS.items():
                actual = session.run(
                    f"MATCH (n:{label}) RETURN count(n) AS c"
                ).single()["c"]
                checks[f"live_{label}_count_{expected}"] = actual == expected
                if actual != expected:
                    problems.append(f"{label}: graph has {actual}, expected {expected}")

            rows = session.run(
                """
                MATCH (d:DefectType)-[r:REQUIRES]->(m:MaintenanceAction)
                RETURN d.name AS defect, r.when_severity AS severity,
                       collect(m.name) AS actions
                """
            ).data()
            rules: dict[tuple[str, int], dict] = {}
            unique_ok, missing_severity = True, False
            for row in rows:
                if row["severity"] is None:
                    missing_severity = True
                    problems.append(
                        f"REQUIRES edge without when_severity: "
                        f"{row['defect']} -> {row['actions']}"
                    )
                    continue
                key = (row["defect"], int(row["severity"]))
                if len(row["actions"]) > 1:
                    unique_ok = False
                    problems.append(
                        f"Multiple maintenance actions for {key}: {row['actions']}"
                    )
                rules[key] = {"action": row["actions"][0]}
            checks["live_requires_edges_have_when_severity"] = not missing_severity
            checks["live_one_action_per_defect_severity"] = unique_ok

            has_severity: dict[str, set[int]] = {}
            for row in session.run(
                """
                MATCH (d:DefectType)-[:HAS_SEVERITY]->(s:Severity)
                RETURN d.name AS defect, collect(s.level) AS levels
                """
            ).data():
                has_severity[row["defect"]] = {int(lv) for lv in row["levels"]}
            rule_invariant_checks(rules, has_severity, checks, problems, prefix="live_")

            chain = session.run(
                """
                MATCH (a:Severity)-[:ESCALATES_TO]->(b:Severity)
                RETURN a.level AS a, b.level AS b ORDER BY a
                """
            ).data()
            expected_chain = [{"a": 0, "b": 1}, {"a": 1, "b": 2}, {"a": 2, "b": 3}]
            checks["live_severity_escalation_chain"] = chain == expected_chain
            if chain != expected_chain:
                problems.append(
                    f"Severity ESCALATES_TO chain is {chain}, expected 0->1->2->3 "
                    "(run ontology/repair_graph.py)"
                )

            weights = {
                int(r["level"]): r["risk_weight"]
                for r in session.run(
                    "MATCH (s:Severity) RETURN s.level AS level, "
                    "s.risk_weight AS risk_weight"
                ).data()
            }
            checks["live_severity_risk_weights_canonical"] = (
                weights == CANONICAL_SEVERITIES
            )
            if weights != CANONICAL_SEVERITIES:
                problems.append(
                    f"Severity risk_weights {weights} differ from seed values "
                    f"{CANONICAL_SEVERITIES} (run ontology/repair_graph.py)"
                )

            duplicates = session.run(
                """
                MATCH (a)-[r]->(b)
                WHERE any(l IN labels(a) WHERE l IN $core)
                  AND any(l IN labels(b) WHERE l IN $core)
                WITH a, b, type(r) AS t, r.when_severity AS ws, count(r) AS n
                WHERE n > 1
                RETURN labels(a)[0] AS from_label,
                       coalesce(a.name, a.risk_id, a.template_id,
                                a.environment_id, a.label, a.asset_id,
                                a.dataset_id, a.model_id,
                                toString(a.level)) AS from_name,
                       t AS rel,
                       coalesce(b.name, b.risk_id, b.template_id,
                                b.environment_id, b.label, b.asset_id,
                                b.dataset_id, b.model_id,
                                toString(b.level)) AS to_name,
                       n AS copies
                """,
                {"core": core_labels},
            ).data()
            checks["live_no_duplicate_core_relationships"] = not duplicates
            for dup in duplicates:
                problems.append(
                    f"Duplicate relationship x{dup['copies']}: "
                    f"({dup['from_label']} '{dup['from_name']}')-"
                    f"[:{dup['rel']}]->('{dup['to_name']}') "
                    "(run ontology/repair_graph.py)"
                )

    finally:
        driver.close()

    return checks, problems


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def write_report(mode: str, checks: dict[str, bool], problems: list[str],
                 rules: dict[tuple[str, int], dict]) -> None:
    lines = [
        "# Knowledge Graph Integrity Report",
        "",
        f"Generated by `ontology/validate_graph.py` ({mode} mode).",
        "",
        "## Invariant Checks",
        "",
    ]
    lines += [f"- {'PASS' if ok else 'FAIL'}: `{name}`" for name, ok in checks.items()]
    lines += ["", "## Severity-Conditioned Decision Rules", ""]
    lines.append("| Defect | Severity | Required action |")
    lines.append("|---|---|---|")
    for (defect, level), rule in sorted(rules.items()):
        lines.append(f"| {defect} | {level} | {rule['action']} |")
    lines += ["", "## Problems", ""]
    lines += [f"- {p}" for p in problems] if problems else ["- None found."]
    REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)
    REPORT_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nWrote {REPORT_FILE}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate the PowerLine O&M knowledge graph decision rules"
    )
    parser.add_argument("--live", action="store_true",
                        help="validate a running Neo4j instance as well")
    parser.add_argument("--uri", default="bolt://localhost:7687")
    parser.add_argument("--user", default="neo4j")
    parser.add_argument("--password", default=os.environ.get("NEO4J_PASSWORD"))
    args = parser.parse_args()

    seed = parse_seed()
    checks, problems = static_checks(seed)
    mode = "static"
    if args.live:
        mode = "static+live"
        live_c, live_p = live_checks(args.uri, args.user, args.password)
        checks.update(live_c)
        problems.extend(live_p)

    for name, ok in checks.items():
        print(f"{'PASS' if ok else 'FAIL'}: {name}")
    if problems:
        print("\nProblems:")
        for p in problems:
            print(f"  - {p}")

    write_report(mode, checks, problems, seed["rules"])

    if not all(checks.values()):
        sys.exit(1)
    print("\nAll knowledge-graph integrity checks passed.")


if __name__ == "__main__":
    main()
