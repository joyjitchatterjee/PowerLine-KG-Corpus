"""
Repair an already-loaded PowerLine O&M knowledge graph in place.

Fixes the known decision-rule integrity issues on a live Neo4j instance
WITHOUT requiring a full re-load (safe to run on a graph that already carries
the 49k-image inventory, VLM evidence, and simulation layers):

 1. Remove ``(DefectType)-[:HAS_SEVERITY]->(Severity {level: 0})`` edges -
    level 0 ('normal') is reserved for defect-free evidence, never for a
    defect's severity grading.
 2. Deduplicate parallel core-ontology relationships (the artifact of
    re-running ``load_ontology.py`` on an already-seeded graph before the
    duplicate guard existed).
 3. Reconcile the ``REQUIRES`` decision rules with the canonical
    severity-conditioned rule table parsed from ``seed_data.cypher``:
    exactly one action per (defect, when_severity), no unkeyed edges,
    no divergent actions. This is what guarantees a single maintenance
    action per (defect, severity) pair.
 4. Create the Severity ordinal chain 0 -ESCALATES_TO-> 1 -> 2 -> 3.
 5. Align Severity node properties (label, description, risk_weight) with
    the seed values.

The canonical rule table is parsed from ``seed_data.cypher`` at runtime, so
this script never drifts from the ontology source of truth.

Usage:
    python ontology/repair_graph.py --dry-run   # report, change nothing
    python ontology/repair_graph.py             # apply the fixes
    python ontology/validate_graph.py --live    # verify afterwards
"""

from __future__ import annotations

import argparse
import os
import sys

from validate_graph import EXPECTED_COUNTS, parse_seed

CANONICAL_SEVERITY_ROWS = [
    {
        "level": 0,
        "label": "normal",
        "description": "No defect indicated. Used for negative-control images and healthy simulation runs.",
        "risk_weight": 0.0,
    },
    {
        "level": 1,
        "label": "minor",
        "description": "Cosmetic or early-stage degradation. No immediate impact on mechanical or electrical function. Example: light surface oxidation, minor paint fading.",
        "risk_weight": 0.2,
    },
    {
        "level": 2,
        "label": "moderate",
        "description": "Noticeable degradation that warrants scheduled maintenance. Structural integrity or insulation margin is measurably reduced. Example: significant corrosion around bolt holes, single missing insulator cap.",
        "risk_weight": 0.5,
    },
    {
        "level": 3,
        "label": "severe",
        "description": "Condition poses safety risk or imminent failure. Immediate or priority intervention required. Example: extensive corrosion with material loss, multiple missing discs, large bird nest bridging clearance.",
        "risk_weight": 1.0,
    },
]

CORE_LABELS = list(EXPECTED_COUNTS) + [
    "Asset", "Condition", "AgentRole", "Dataset", "SimulationModel",
]


def fix_defect_severity_zero(session, apply: bool) -> int:
    rows = session.run(
        """
        MATCH (d:DefectType)-[r:HAS_SEVERITY]->(s:Severity {level: 0})
        RETURN d.name AS defect, elementId(r) AS rid
        """
    ).data()
    for row in rows:
        print(f"  - remove HAS_SEVERITY level 0 from defect '{row['defect']}'")
    if apply and rows:
        session.run(
            """
            MATCH (d:DefectType)-[r:HAS_SEVERITY]->(s:Severity {level: 0})
            DELETE r
            """
        )
    return len(rows)


def fix_duplicate_relationships(session, apply: bool) -> int:
    groups = session.run(
        """
        MATCH (a)-[r]->(b)
        WHERE any(l IN labels(a) WHERE l IN $core)
          AND any(l IN labels(b) WHERE l IN $core)
        WITH elementId(a) AS aid, labels(a)[0] AS albl,
             coalesce(a.name, a.risk_id, a.template_id, a.environment_id,
                      a.label, a.asset_id, a.dataset_id, a.model_id,
                      toString(a.level)) AS aname,
             elementId(b) AS bid,
             coalesce(b.name, b.risk_id, b.template_id, b.environment_id,
                      b.label, b.asset_id, b.dataset_id, b.model_id,
                      toString(b.level)) AS bname,
             type(r) AS t, r.when_severity AS ws,
             collect(elementId(r)) AS rids
        WHERE size(rids) > 1
        RETURN albl, aname, t, ws, bname, rids
        """,
        {"core": CORE_LABELS},
    ).data()
    surplus: list[str] = []
    for g in groups:
        extras = g["rids"][1:]
        surplus.extend(extras)
        ws = f" when_severity={g['ws']}" if g["ws"] is not None else ""
        print(
            f"  - deduplicate ({g['albl']} '{g['aname']}')-[:{g['t']}{ws}]->"
            f"('{g['bname']}'): {len(g['rids'])} copies -> 1"
        )
    if apply and surplus:
        session.run(
            "MATCH ()-[r]->() WHERE elementId(r) IN $ids DELETE r",
            {"ids": surplus},
        )
    return len(surplus)


def fix_requires_rules(session, rules, apply: bool) -> int:
    """Make live REQUIRES edges exactly match the canonical seed rule table."""
    changes = 0
    existing = session.run(
        """
        MATCH (d:DefectType)-[r:REQUIRES]->(m:MaintenanceAction)
        RETURN elementId(r) AS rid, d.name AS defect,
               r.when_severity AS ws, m.name AS action
        """
    ).data()

    stale: list[str] = []
    for row in existing:
        key = (row["defect"], int(row["ws"])) if row["ws"] is not None else None
        canonical = rules.get(key) if key else None
        if canonical is None or canonical["action"] != row["action"]:
            stale.append(row["rid"])
            reason = (
                "missing when_severity" if row["ws"] is None
                else "not in canonical rule table"
                if key not in rules
                else f"canonical action is '{rules[key]['action']}'"
            )
            print(
                f"  - remove REQUIRES {row['defect']} (severity {row['ws']}) "
                f"-> {row['action']} [{reason}]"
            )
    if apply and stale:
        session.run(
            "MATCH ()-[r:REQUIRES]->() WHERE elementId(r) IN $ids DELETE r",
            {"ids": stale},
        )
    changes += len(stale)

    present = {
        (row["defect"], int(row["ws"])): row["action"]
        for row in existing
        if row["ws"] is not None and row["rid"] not in set(stale)
    }
    for (defect, level), rule in sorted(rules.items()):
        if present.get((defect, level)) == rule["action"]:
            continue
        print(
            f"  - ensure REQUIRES {defect} (severity {level}) -> {rule['action']}"
        )
        changes += 1
        if apply:
            session.run(
                """
                MATCH (d:DefectType {name: $defect}),
                      (m:MaintenanceAction {name: $action})
                MERGE (d)-[r:REQUIRES {when_severity: $level}]->(m)
                SET r.rationale = $rationale
                """,
                {
                    "defect": defect,
                    "action": rule["action"],
                    "level": level,
                    "rationale": rule["rationale"],
                },
            )
    return changes


def fix_severity_nodes(session, apply: bool) -> int:
    current = {
        int(r["level"]): (r["label"], r["risk_weight"])
        for r in session.run(
            "MATCH (s:Severity) RETURN s.level AS level, s.label AS label, "
            "s.risk_weight AS risk_weight"
        ).data()
    }
    drift = [
        row for row in CANONICAL_SEVERITY_ROWS
        if current.get(row["level"]) != (row["label"], row["risk_weight"])
    ]
    for row in drift:
        print(
            f"  - align Severity level {row['level']} "
            f"(label '{row['label']}', risk_weight {row['risk_weight']})"
        )
    if apply:
        session.run(
            """
            UNWIND $rows AS row
            MERGE (s:Severity {level: row.level})
            SET s.label = row.label,
                s.description = row.description,
                s.risk_weight = row.risk_weight
            """,
            {"rows": CANONICAL_SEVERITY_ROWS},
        )
    return len(drift)


def fix_escalation_chain(session, apply: bool) -> int:
    have = session.run(
        """
        MATCH (a:Severity)-[:ESCALATES_TO]->(b:Severity)
        RETURN a.level AS a, b.level AS b
        """
    ).data()
    have_pairs = {(int(r["a"]), int(r["b"])) for r in have}
    missing = [(lv, lv + 1) for lv in (0, 1, 2) if (lv, lv + 1) not in have_pairs]
    for a, b in missing:
        print(f"  - add Severity ESCALATES_TO {a} -> {b}")
    if apply and missing:
        session.run(
            """
            MATCH (sa:Severity), (sb:Severity)
            WHERE sb.level = sa.level + 1
            MERGE (sa)-[:ESCALATES_TO]->(sb)
            """
        )
    return len(missing)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Repair the PowerLine O&M knowledge graph in place"
    )
    parser.add_argument("--uri", default="bolt://localhost:7687")
    parser.add_argument("--user", default="neo4j")
    parser.add_argument("--password", default=os.environ.get("NEO4J_PASSWORD"))
    parser.add_argument("--dry-run", action="store_true",
                        help="report what would change without changing it")
    args = parser.parse_args()

    try:
        from neo4j import GraphDatabase
    except ImportError:
        print("neo4j driver not installed. Run: pip install neo4j")
        sys.exit(1)

    seed = parse_seed()
    apply = not args.dry_run
    mode = "APPLY" if apply else "DRY RUN"

    driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
    try:
        driver.verify_connectivity()
        with driver.session() as session:
            print(f"[{mode}] 1. Defect links to severity level 0")
            n1 = fix_defect_severity_zero(session, apply)
            print(f"[{mode}] 2. Duplicate core relationships")
            n2 = fix_duplicate_relationships(session, apply)
            print(f"[{mode}] 3. REQUIRES decision rules vs canonical table "
                  f"({len(seed['rules'])} rules)")
            n3 = fix_requires_rules(session, seed["rules"], apply)
            print(f"[{mode}] 4. Severity ESCALATES_TO ordinal chain")
            n4 = fix_escalation_chain(session, apply)
            print(f"[{mode}] 5. Severity node properties")
            n5 = fix_severity_nodes(session, apply)
    finally:
        driver.close()

    total = n1 + n2 + n3 + n4 + n5
    if total == 0:
        print("\nGraph already satisfies all decision-rule invariants.")
    elif apply:
        print(f"\nApplied {total} fixes. Verify with:")
        print("  python ontology/validate_graph.py --live")
    else:
        print(f"\n{total} fixes pending. Apply with:")
        print("  python ontology/repair_graph.py")


if __name__ == "__main__":
    main()
