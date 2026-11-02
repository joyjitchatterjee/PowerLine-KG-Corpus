"""Check the human corpus, images, domain graph, and public release scope."""
import collections
import csv
import hashlib
import json
import re
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'ontology'))
from validate_graph import parse_seed, static_checks
from checksums import verify

FIELDS = {'record_id', 'review_id', 'component', 'component_canonical',
          'defect_present', 'expert_description', 'recommended_action', 'annotator_notes',
          'annotation_source', 'source_sheet', 'source_row', 'dataset_condition_label',
          'source_image', 'image_path', 'image_sha256'}
COMPANION_FIELDS = {'record_id', 'source_record_id', 'source_row', 'image_path',
                    'source_image', 'image_sha256', 'component', 'component_canonical',
                    'condition', 'is_defective', 'severity', 'description',
                    'description_source', 'description_kind', 'recommended_action'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate():
    count = verify()
    rows = [json.loads(line) for line in (ROOT / 'data/annotations.jsonl').read_text().splitlines()]
    require(len(rows) == len({r['record_id'] for r in rows}) == 85, 'Expected 85 unique human records')
    require({r['review_id'] for r in rows} == {f'{i:03}' for i in range(1, 86)}, 'Review ID coverage differs')
    require({r['source_row'] for r in rows} == set(range(2, 87)), 'Source workbook row coverage differs')
    git_files = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z']).decode().split('\0')
    tracked = {p for p in git_files if p}
    image_paths = set()
    for row in rows:
        require(set(row) == FIELDS, 'Unexpected annotation fields')
        require(row['annotation_source'] == 'human_labelled_workbook', 'Unexpected annotation source')
        require(row['source_sheet'] == 'Blind_Image_Annotation', 'Unexpected source sheet')
        require(isinstance(row['defect_present'], bool), 'Defect presence must be boolean')
        for field in ('expert_description', 'recommended_action', 'annotator_notes'):
            require(isinstance(row[field], str) and row[field].strip(), f'Missing human field: {field}')
        path = (ROOT / row['image_path']).resolve()
        require(path.is_relative_to(ROOT / 'data/images') and path.is_file(), 'Missing or unsafe image path')
        require(row['image_path'] in tracked, 'Image filename differs from Git path')
        raw = path.read_bytes()
        require(raw.startswith(b'\xff\xd8') and hashlib.sha256(raw).hexdigest() == row['image_sha256'], 'Image format or hash differs')
        image_paths.add(row['image_path'])
    with (ROOT / 'data/annotations.csv').open(newline='') as file:
        csv_rows = list(csv.DictReader(file))
    require(len(csv_rows) == 85, 'CSV row count differs')
    for json_row, csv_row in zip(rows, csv_rows):
        require(csv_row == {k: str(v) for k, v in json_row.items()}, 'CSV and JSONL differ')
    companion = [json.loads(line) for line in (ROOT / 'data/companion_descriptions.jsonl').read_text().splitlines()]
    companion_ids = {r['record_id'] for r in companion}
    require(len(companion) == len(companion_ids) == 255, 'Expected 255 unique companion IDs')
    require({r['record_id'] for r in rows} <= companion_ids, 'Workbook images missing from companion')
    require({r['source_row'] for r in companion} == set(range(2, 257)), 'Companion source rows differ')
    for row in companion:
        require(set(row) == COMPANION_FIELDS, 'Unexpected companion fields')
        require(re.fullmatch(r'[a-f0-9]{12}', row['record_id']), 'Invalid canonical ID')
        require(row['image_path'] == f'data/images/{row["record_id"]}.jpg', 'Noncanonical image path')
        require(row['image_path'] in tracked, 'Missing tracked companion image')
        raw = (ROOT / row['image_path']).read_bytes()
        require(raw.startswith(b'\xff\xd8') and hashlib.sha256(raw).hexdigest() == row['image_sha256'], 'Companion image hash differs')
        require(isinstance(row['is_defective'], bool), 'Companion defect flag must be boolean')
        require(row['description'].strip(), 'Missing companion description')
        source = row['description_source']
        require(source in {'human_annotator2', 'human_annotator3', 'auto_generated'}, 'Unexpected companion source')
        expected_kind = 'template_generated' if source == 'auto_generated' else 'human_labelled'
        require(row['description_kind'] == expected_kind, 'Companion provenance conflated')
        require(bool(row['recommended_action'].strip()) == (expected_kind == 'human_labelled'), 'Action coverage differs')
        image_paths.add(row['image_path'])
    require(len(image_paths) == 255 and image_paths == {p for p in tracked if p.startswith('data/images/')}, 'Unexpected or missing image files')
    with (ROOT / 'data/companion_descriptions.csv').open(newline='') as file:
        companion_csv = list(csv.DictReader(file))
    require(len(companion_csv) == 255, 'Companion CSV row count differs')
    for json_row, csv_row in zip(companion, companion_csv):
        require(csv_row == {k: str(v) for k, v in json_row.items()}, 'Companion CSV/JSONL differ')
    provenance = json.loads((ROOT / 'data/companion_provenance.json').read_text())
    actual_repairs = {(r['source_row'], r['source_record_id'], r['record_id']) for r in companion if r['source_record_id'] != r['record_id']}
    recorded_repairs = {(r['source_row'], r['source_record_id'], r['record_id']) for r in provenance['record_id_corrections']}
    require(actual_repairs == recorded_repairs and len(actual_repairs) == 2, 'ID corrections differ from provenance')
    seed = parse_seed()
    checks, problems = static_checks(seed)
    require(all(checks.values()), f'Graph checks failed: {problems}')
    with (ROOT / 'data/maintenance_rules.csv').open(newline='') as file:
        rules = list(csv.DictReader(file))
    actual = {(r['defect'], int(r['severity_level'])): {'action': r['action'], 'rationale': r['rationale']} for r in rules}
    require(len(rules) == len(actual) == 11 and actual == seed['rules'], 'Rule export differs from graph seed')
    stats = json.loads((ROOT / 'data/statistics.json').read_text())
    components = dict(sorted(collections.Counter(r['component_canonical'] for r in rows).items()))
    require(len(components) == 17 and set(components.values()) == {5}, 'Component coverage differs')
    require(stats['human_annotations'] == stats['human_corpus_images'] == 85 and stats['images'] == 255 and stats['components'] == 17, 'Stale counts')
    require(stats['component_counts'] == components, 'Stale component counts')
    require(stats['human_defect_present'] == dict(collections.Counter(str(r['defect_present']).lower() for r in rows)), 'Stale defect counts')
    require(stats['source_condition_counts'] == dict(collections.Counter(r['dataset_condition_label'] for r in rows)), 'Stale source condition counts')
    companion_stats = stats['companion']
    require(companion_stats == provenance['statistics'], 'Companion statistics disagree')
    require(companion_stats['description_sources'] == dict(collections.Counter(r['description_source'] for r in companion)) == {'human_annotator3': 66, 'human_annotator2': 4, 'auto_generated': 185}, 'Companion source counts differ')
    require(companion_stats['description_kinds'] == dict(collections.Counter(r['description_kind'] for r in companion)), 'Stale description-kind counts')
    require(companion_stats['component_counts'] == dict(collections.Counter(r['component_canonical'] for r in companion)), 'Stale companion component counts')
    require(set(companion_stats['component_counts'].values()) == {15}, 'Companion component coverage differs')
    require(companion_stats['condition_counts'] == dict(collections.Counter(r['condition'] for r in companion)), 'Stale companion condition counts')
    require(companion_stats['severity_counts'] == dict(collections.Counter(r['severity'] for r in companion)), 'Stale companion severity counts')
    require(stats['total_description_records'] == len(rows) + len(companion) == 340, 'Stale total description count')
    human_by_id = {r['record_id']: r for r in rows}
    human_companion = [r for r in companion if r['description_kind'] == 'human_labelled']
    require(all(r['record_id'] in human_by_id for r in human_companion), 'Human-labelled overlap differs')
    require(not any(r['description'].strip() == human_by_id[r['record_id']]['expert_description'].strip() for r in human_companion), 'Source disagreement summary needs review')
    allowed_data = {'data/annotations.csv', 'data/annotations.jsonl', 'data/maintenance_rules.csv', 'data/statistics.json', 'data/provenance.json',
                    'data/companion_descriptions.csv', 'data/companion_descriptions.jsonl', 'data/companion_provenance.json'} | image_paths
    require({p for p in tracked if p.startswith('data/')} == allowed_data, 'Unexpected data assets')
    for name in tracked:
        require(not name.startswith(('outputs/', 'simulink/')) and not name.endswith(('.xlsx', '.xls', '.bundle')), f'Out-of-scope artifact: {name}')
        raw = (ROOT / name).read_bytes()
        try:
            text = raw.decode('utf-8')
        except UnicodeDecodeError:
            continue
        require(chr(0x2014) not in text and ('\\u' + '2014') not in text.lower(), f'Prohibited punctuation: {name}')
    print(f'PASS: {count} artifact hashes; 85 workbook records; 255 companion records and images; CSV/JSONL equivalence.')
    print('PASS: provenance separation, ID repairs, 17 components, graph invariants, 11 rules, release scope and punctuation.')


if __name__ == '__main__':
    validate()
