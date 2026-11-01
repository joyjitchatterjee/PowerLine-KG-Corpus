"""Load human descriptions into Neo4j without inferring severity or actions."""
import argparse
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATASET_ID = 'INSPLAD-HUMAN-DESCRIPTIONS-85'


def read_records():
    return [json.loads(line) for line in (ROOT / 'data/annotations.jsonl').read_text().splitlines()]


def load(tx, records):
    names = {r['component_canonical'] for r in records}
    available = {r['name'] for r in tx.run('MATCH (c:ComponentType) RETURN c.name AS name')}
    if not names <= available:
        raise ValueError('Load the domain ontology first; required components are missing.')
    tx.run('MERGE (d:Dataset {dataset_id: $id}) SET d.name = $name, d.record_count = $count',
           id=DATASET_ID, name='Human-annotated InsPLAD descriptions', count=len(records)).consume()
    tx.run('''
        UNWIND $rows AS row
        MATCH (c:ComponentType {name: row.component_canonical})
        MATCH (d:Dataset {dataset_id: $dataset})
        MERGE (i:Image {image_id: row.record_id})
        SET i.file_path = row.image_path, i.source_image = row.source_image,
            i.source_condition_label = row.dataset_condition_label,
            i.image_sha256 = row.image_sha256
        MERGE (a:HumanAnnotation {record_id: row.record_id})
        SET a += row
        MERGE (i)-[:HAS_COMPONENT]->(c)
        MERGE (i)-[:IN_DATASET]->(d)
        MERGE (i)-[:HAS_HUMAN_ANNOTATION]->(a)
    ''', rows=records, dataset=DATASET_ID).consume()


def verify(driver, records):
    with driver.session() as session:
        rows = session.run('''
            MATCH (d:Dataset {dataset_id: $dataset})<-[:IN_DATASET]-(i:Image)
                  -[:HAS_HUMAN_ANNOTATION]->(a:HumanAnnotation)
            MATCH (i)-[:HAS_COMPONENT]->(c:ComponentType)
            RETURN properties(a) AS annotation, i.file_path AS image_path,
                   c.name AS component
        ''', dataset=DATASET_ID).data()
    expected = {r['record_id']: r for r in records}
    if len(rows) != len(expected) or {r['annotation']['record_id'] for r in rows} != set(expected):
        raise ValueError('Annotation coverage or graph relationship cardinality differs.')
    for row in rows:
        original = expected[row['annotation']['record_id']]
        if row['annotation'] != original or row['image_path'] != original['image_path'] or row['component'] != original['component_canonical']:
            raise ValueError(f'Graph annotation differs: {original["record_id"]}')
    print(f'Verified {len(rows)} human annotations, exact text and image/component links.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--uri', default='bolt://localhost:7687')
    parser.add_argument('--user', default='neo4j')
    parser.add_argument('--password', default=os.environ.get('NEO4J_PASSWORD'))
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--verify', action='store_true', help='Check existing graph without writing')
    args = parser.parse_args()
    records = read_records()
    if args.dry_run:
        print(f'{len(records)} human annotations ready to load. No database connection opened.')
    else:
        if not args.password:
            parser.error('Set NEO4J_PASSWORD or supply --password.')
        from neo4j import GraphDatabase
        with GraphDatabase.driver(args.uri, auth=(args.user, args.password)) as driver:
            driver.verify_connectivity()
            if not args.verify:
                with driver.session() as session:
                    session.execute_write(load, records)
            verify(driver, records)
