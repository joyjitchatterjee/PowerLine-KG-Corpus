"""
PowerLine Inspection Ontology - Neo4j Loader
=============================================

Loads the schema and seed data into a Neo4j instance.

Setup
-----
1. Install Neo4j (pick ONE):

   Option A - Docker (recommended, nothing to install on host):
       docker run -d --name neo4j-powerline \
           -p 7474:7474 -p 7687:7687 \
           -e NEO4J_AUTH=neo4j/${NEO4J_PASSWORD} \
           -e NEO4J_PLUGINS='["apoc"]' \
           neo4j:5

   Option B - Neo4j Desktop (GUI):
       Download from https://neo4j.com/download/
       Create a new project and local DBMS, set password.

   Option C - Homebrew:
       brew install neo4j
       neo4j start

2. Install the Python driver:
       pip install neo4j

3. Run this script:
       python load_ontology.py

   Or with custom credentials:
       python load_ontology.py --uri bolt://localhost:7687 --user neo4j --password yourpassword

4. Open Neo4j Browser at http://localhost:7474 to explore the graph.
"""

import argparse
import os
import sys
from pathlib import Path

ONTOLOGY_DIR = Path(__file__).parent

# Schema and seed files in load order
CYPHER_FILES = [
    ONTOLOGY_DIR / "schema.cypher",
    ONTOLOGY_DIR / "seed_data.cypher",
]


def parse_cypher_file(filepath: Path) -> list[str]:
    """Parse a .cypher file into individual statements.

    Splits on statement-terminating semicolons while respecting string
    literals and comments, so a ``;`` or ``//`` inside a quoted value (e.g.
    "normal/good examples; test folders ...") does not break the statement.
    Strips ``//`` line comments and ``/* */`` block comments that sit outside
    strings, and returns non-empty statements.
    """
    text = filepath.read_text(encoding="utf-8")

    statements: list[str] = []
    buf: list[str] = []
    quote: str | None = None  # active string delimiter, ' or ", else None
    i, n = 0, len(text)

    while i < n:
        ch = text[i]

        if quote is not None:
            # Inside a string literal: copy verbatim until the matching quote.
            buf.append(ch)
            if ch == "\\" and i + 1 < n:  # keep escaped char (e.g. \')
                buf.append(text[i + 1])
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue

        # Not inside a string.
        if ch in ("'", '"'):
            quote = ch
            buf.append(ch)
        elif ch == "/" and i + 1 < n and text[i + 1] == "/":
            nl = text.find("\n", i)  # line comment: skip to end of line
            i = n if nl == -1 else nl
            continue
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            end = text.find("*/", i + 2)  # block comment: skip to close
            i = n if end == -1 else end + 2
            continue
        elif ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
        else:
            buf.append(ch)
        i += 1

    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)

    return [s for s in statements if len(s) > 5]  # skip trivial fragments


def load_file(driver, filepath: Path, verbose: bool = True):
    """Load all statements from a single Cypher file."""
    statements = parse_cypher_file(filepath)
    print(f"\n{'='*60}")
    print(f"Loading: {filepath.name} ({len(statements)} statements)")
    print(f"{'='*60}")

    success = 0
    errors = 0

    with driver.session() as session:
        for i, stmt in enumerate(statements, 1):
            # Show first 80 chars of statement
            preview = stmt.replace("\n", " ")[:80]
            try:
                session.run(stmt)
                success += 1
                if verbose:
                    print(f"  [{i}/{len(statements)}] OK: {preview}...")
            except Exception as e:
                errors += 1
                error_msg = str(e).split("\n")[0][:100]
                print(f"  [{i}/{len(statements)}] ERROR: {preview}...")
                print(f"           {error_msg}")

    print(f"\n  Results: {success} succeeded, {errors} failed")
    return success, errors


def verify_graph(driver):
    """Print summary statistics of the loaded graph."""
    print(f"\n{'='*60}")
    print("Graph Summary")
    print(f"{'='*60}")

    queries = [
        ("Node counts by label", """
            CALL db.labels() YIELD label
            CALL apoc.cypher.run('MATCH (n:`' + label + '`) RETURN count(n) AS count', {})
            YIELD value
            RETURN label, value.count AS count
            ORDER BY count DESC
        """),
        ("Relationship counts by type", """
            CALL db.relationshipTypes() YIELD relationshipType AS type
            CALL apoc.cypher.run(
                'MATCH ()-[r:`' + type + '`]->() RETURN count(r) AS count', {}
            ) YIELD value
            RETURN type, value.count AS count
            ORDER BY count DESC
        """),
    ]

    # Fallback queries if APOC is not installed
    fallback_queries = [
        ("Total nodes", "MATCH (n) RETURN count(n) AS total_nodes"),
        ("Total relationships", "MATCH ()-[r]->() RETURN count(r) AS total_relationships"),
        ("ComponentType nodes", "MATCH (n:ComponentType) RETURN count(n) AS count"),
        ("DefectType nodes", "MATCH (n:DefectType) RETURN count(n) AS count"),
        ("FailureMode nodes", "MATCH (n:FailureMode) RETURN count(n) AS count"),
        ("Risk nodes", "MATCH (n:Risk) RETURN count(n) AS count"),
        ("Severity nodes", "MATCH (n:Severity) RETURN count(n) AS count"),
        ("MaintenanceAction nodes", "MATCH (n:MaintenanceAction) RETURN count(n) AS count"),
        ("Standard nodes", "MATCH (n:Standard) RETURN count(n) AS count"),
        ("Environment nodes", "MATCH (n:Environment) RETURN count(n) AS count"),
    ]

    with driver.session() as session:
        apoc_available = True
        for label, query in queries:
            try:
                result = session.run(query)
                records = list(result)
                print(f"\n  {label}:")
                for record in records:
                    print(f"    {dict(record)}")
            except Exception:
                apoc_available = False
                break

        if not apoc_available:
            print("\n  (APOC not available, using fallback counts)\n")
            for label, query in fallback_queries:
                try:
                    result = session.run(query)
                    record = result.single()
                    if record:
                        val = list(record.values())[0]
                        print(f"    {label}: {val}")
                except Exception as e:
                    print(f"    {label}: error - {e}")


def clear_database(driver):
    """Remove all nodes and relationships (fresh start)."""
    with driver.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    print("Database cleared.")


def already_seeded(driver) -> bool:
    """True if the ontology seed is already present in the graph.

    Re-running the seed on a seeded graph is unsafe: node CREATEs fail on the
    uniqueness constraints, but every MATCH...CREATE relationship statement
    succeeds again and silently duplicates AFFECTS / HAS_SEVERITY / REQUIRES /
    LEADS_TO edges - which corrupts decision-support queries (e.g. multiple
    maintenance actions for the same defect and severity).
    """
    with driver.session() as session:
        record = session.run(
            "MATCH (c:ComponentType) RETURN count(c) AS c"
        ).single()
    return bool(record and record["c"] > 0)


def main():
    parser = argparse.ArgumentParser(
        description="Load PowerLine Inspection Ontology into Neo4j"
    )
    parser.add_argument(
        "--uri", default="bolt://localhost:7687",
        help="Neo4j bolt URI (default: bolt://localhost:7687)"
    )
    parser.add_argument(
        "--user", default="neo4j",
        help="Neo4j username (default: neo4j)"
    )
    parser.add_argument(
        "--password", default=os.environ.get("NEO4J_PASSWORD"),
        help="Neo4j password (or NEO4J_PASSWORD)"
    )
    parser.add_argument(
        "--clear", action="store_true",
        help="Clear the database before loading"
    )
    parser.add_argument(
        "--quiet", action="store_true",
        help="Suppress per-statement output"
    )
    args = parser.parse_args()

    try:
        from neo4j import GraphDatabase
    except ImportError:
        print("neo4j driver not installed. Run:  pip install neo4j")
        sys.exit(1)

    print("Connecting to Neo4j...")
    print(f"  URI:  {args.uri}")
    print(f"  User: {args.user}")

    try:
        driver = GraphDatabase.driver(args.uri, auth=(args.user, args.password))
        driver.verify_connectivity()
        print("  Connected successfully.\n")
    except Exception as e:
        print(f"\n  Connection failed: {e}")
        print("\n  Make sure Neo4j is running. Quick start with Docker:")
        print("    docker run -d --name neo4j-powerline \\")
        print("      -p 7474:7474 -p 7687:7687 \\")
        print("      -e NEO4J_AUTH=neo4j/${NEO4J_PASSWORD} \\")
        print("      -e NEO4J_PLUGINS='[\"apoc\"]' \\")
        print("      neo4j:5")
        sys.exit(1)

    if args.clear:
        clear_database(driver)
    elif already_seeded(driver):
        print("ERROR: the graph already contains the ontology seed.")
        print("Re-seeding would duplicate relationships (AFFECTS, HAS_SEVERITY,")
        print("REQUIRES, ...) and corrupt decision-support queries.")
        print("Re-run with --clear for a fresh load, or use")
        print("ontology/repair_graph.py to fix an existing graph in place.")
        driver.close()
        sys.exit(1)

    total_success = 0
    total_errors = 0

    for cypher_file in CYPHER_FILES:
        if not cypher_file.exists():
            print(f"WARNING: {cypher_file} not found, skipping.")
            continue
        s, e = load_file(driver, cypher_file, verbose=not args.quiet)
        total_success += s
        total_errors += e

    print(f"\n{'='*60}")
    print(f"Loading complete: {total_success} statements succeeded, {total_errors} failed")
    print(f"{'='*60}")

    if total_errors:
        driver.close()
        sys.exit(1)

    verify_graph(driver)

    driver.close()
    print("\nDone. Open http://localhost:7474 to explore the graph.")
    print("Try this query in the Neo4j Browser:\n")
    print("  MATCH (d:DefectType)-[:LEADS_TO]->(fm:FailureMode)-[:IMPACTS]->(r:Risk)")
    print("  RETURN d, fm, r")


if __name__ == "__main__":
    main()
