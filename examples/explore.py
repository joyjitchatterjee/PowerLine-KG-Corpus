"""Explore the released corpus and look up a severity-conditioned graph rule."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def lookup_action(defect, severity):
    with (ROOT / 'data/maintenance_rules.csv').open(newline='') as f:
        matches = [r for r in csv.DictReader(f)
                   if r['defect'] == defect and int(r['severity_level']) == severity]
    if len(matches) != 1:
        raise ValueError(f'No unique supported rule for {defect!r}, severity {severity}.')
    return matches[0]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--defect')
    parser.add_argument('--severity', type=int, choices=range(4))
    args = parser.parse_args()
    if (args.defect is None) != (args.severity is None):
        parser.error('Supply --defect and --severity together.')
    if args.defect is not None:
        try:
            print(json.dumps(lookup_action(args.defect, args.severity), indent=2))
        except ValueError as error:
            parser.error(str(error))
    else:
        stats = json.loads((ROOT / 'data/statistics.json').read_text())
        print(json.dumps(stats, indent=2))
        print('See data/annotations.jsonl for the human descriptions and docs/DATA_CARD.md for provenance.')
