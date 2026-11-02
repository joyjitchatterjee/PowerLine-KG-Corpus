# Knowledge graph guide

The KG is a Neo4j property graph expressed in [schema.cypher](../ontology/schema.cypher) and [seed_data.cypher](../ontology/seed_data.cypher). Its domain vocabulary comprises 18 component types, 5 defects, 4 severity levels, 8 failure modes, 6 risks, 3 environmental contexts, 7 standards, 8 maintenance actions, and 3 work-order templates. Templates are reusable domain structures, not generated work orders.

Severity is ordinal: 0 normal, 1 minor, 2 moderate, and 3 severe. No defect links to severity 0. Every supported defect/severity pair has exactly one `REQUIRES` relationship with a `when_severity` property. The 11 supported combinations are also available in [maintenance_rules.csv](../data/maintenance_rules.csv).

## Load the graph

Use Python 3.10 or later, Docker, and Neo4j 5:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
read -s -p 'Neo4j password: ' NEO4J_PASSWORD
export NEO4J_PASSWORD
docker run -d --name powerline-kg \
  -p 127.0.0.1:7474:7474 -p 127.0.0.1:7687:7687 \
  -e NEO4J_AUTH="neo4j/$NEO4J_PASSWORD" neo4j:5.26-community
```

Wait for http://localhost:7474, then run:

```bash
python ontology/load_ontology.py
python ontology/validate_graph.py --live
python ontology/load_annotations.py --dry-run
python ontology/load_annotations.py
python ontology/load_annotations.py --verify
```

The annotation loader adds 85 `Image` nodes and 85 `HumanAnnotation` nodes, with exact text, image paths, source labels and provenance. Images link to their component and corpus dataset. Rerunning the annotation loader is idempotent. It does not convert human text or source condition labels into severity or action edges.

The 255-record mixed-provenance companion is distributed separately as CSV/JSONL. This loader does not import it as human ground truth. The domain KG and workbook corpus are unchanged by that addition.

The seed loader rejects reseeding an existing graph. `--clear` deletes data from the selected database and should only be used for disposable instances. The supplied repair utility supports correction of existing domain graphs.

## Query examples

Get the action for a specific defect and severity:

```cypher
MATCH (d:DefectType {name: 'corrosion'})-[r:REQUIRES]->(a:MaintenanceAction)
WHERE r.when_severity = 2
RETURN d.name AS defect, r.when_severity AS severity, a.name AS action;
```

Expected action: `hardware_replacement`. Always filter `when_severity` when choosing an action.

Read human descriptions of a component:

```cypher
MATCH (c:ComponentType {name: 'stockbridge_damper'})<-[:HAS_COMPONENT]-(i:Image)
      -[:HAS_HUMAN_ANNOTATION]->(a:HumanAnnotation)
RETURN a.record_id, i.file_path, a.defect_present,
       a.expert_description, a.recommended_action, a.annotator_notes;
```

Trace domain causal links:

```cypher
MATCH (d:DefectType)-[:AFFECTS]->(c:ComponentType)
MATCH (d)-[:LEADS_TO]->(f:FailureMode)-[:IMPACTS]->(r:Risk)
RETURN c.name, d.name, f.name, r.name;
```

More domain query templates are in [queries.cypher](../ontology/queries.cypher). Structural validity establishes consistency of the encoded graph, not engineering correctness of every fact or recommendation.
