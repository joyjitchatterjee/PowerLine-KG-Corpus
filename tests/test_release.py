import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts'), str(ROOT / 'examples')]
from checksums import verify
from explore import lookup_action


class ReleaseTests(unittest.TestCase):
    def test_severity_changes_corrosion_action(self):
        self.assertEqual(lookup_action('corrosion', 2)['action'], 'hardware_replacement')
        self.assertNotEqual(lookup_action('corrosion', 1)['action'], lookup_action('corrosion', 3)['action'])

    def test_defect_free_severity_cannot_select_defect_action(self):
        with self.assertRaises(ValueError):
            lookup_action('corrosion', 0)
        with self.assertRaises(ValueError):
            lookup_action('unknown', 2)

    def test_checksum_detects_modified_and_unlisted_data(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'data').mkdir()
            data = root / 'data/example.json'
            data.write_text('{}')
            (root / 'SHA256SUMS').write_text(hashlib.sha256(b'{}').hexdigest() + '  data/example.json\n')
            self.assertEqual(verify(root), 1)
            data.write_text('{"changed": true}')
            with self.assertRaises(ValueError):
                verify(root)
            data.write_text('{}')
            (root / 'data/new.json').write_text('{}')
            with self.assertRaises(ValueError):
                verify(root)


if __name__ == '__main__':
    unittest.main()
