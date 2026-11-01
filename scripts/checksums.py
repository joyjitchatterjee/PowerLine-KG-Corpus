"""Write or verify SHA-256 hashes for published data and graph artifacts."""
import argparse
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def artifact_paths(root=ROOT):
    for directory in ('data', 'ontology'):
        for path in sorted((root / directory).rglob('*')):
            if (path.is_file() and '__pycache__' not in path.parts
                    and 'timeseries' not in path.parts and 'InsPLAD' not in path.parts
                    and path.suffix not in {'.pyc', '.slx', '.slxc'}):
                yield path


def verify(root=ROOT):
    expected = {}
    for line in (root / 'SHA256SUMS').read_text().splitlines():
        digest, path = line.split('  ', 1)
        if path in expected:
            raise ValueError(f'Duplicate checksum path: {path}')
        expected[path] = digest
    actual_paths = {str(p.relative_to(root)) for p in artifact_paths(root)}
    if actual_paths != set(expected):
        raise ValueError(f'Checksum inventory differs: {actual_paths ^ set(expected)}')
    for rel, digest in expected.items():
        if hashlib.sha256((root / rel).read_bytes()).hexdigest() != digest:
            raise ValueError(f'Checksum mismatch: {rel}')
    return len(expected)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='Update after reviewing changes')
    args = parser.parse_args()
    if args.write:
        lines = [f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(ROOT)}'
                 for p in artifact_paths()]
        (ROOT / 'SHA256SUMS').write_text('\n'.join(lines) + '\n')
    print(f'Verified {verify()} artifact checksums.')
