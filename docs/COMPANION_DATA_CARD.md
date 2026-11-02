# Mixed-provenance companion data card

## Source and contents

The author supplied `final_dataset.csv` on 2 November 2026. It contains 255 unique images across 17 component groups, with 15 images per group. The release provides portable [CSV](../data/companion_descriptions.csv) and [JSONL](../data/companion_descriptions.jsonl) exports, with all original descriptions and recommended-action text preserved.

| Supplied description source | Records | Interpretation |
|---|---:|---|
| `human_annotator3` | 66 | Human attribution asserted by the supplied CSV |
| `human_annotator2` | 4 | Human attribution asserted by the supplied CSV |
| `auto_generated` | 185 | Exact matches to the original label-and-ontology template text |

Human attribution and adjudication status for the 70 human-labelled rows have not been independently verified. Annotator numbers are source identifiers, not identified people. All 185 automatic descriptions match the original `knowledge_grounded_label_template_v1` target text byte-for-byte before export. They should not be described as GPT-generated or expert ground truth.

Recommended actions are populated for the 70 human-labelled rows and missing for the 185 template-generated rows. Missing fields remain empty; no actions are filled from another source or extracted from description text. All 255 supplied severity values match the original bootstrap inventory. They are retained as source metadata, not represented as independently assessed expert severity.

## Relationship to the workbook corpus

The separate [85-record human corpus](DATA_CARD.md) remains unchanged. All its image IDs appear in the companion. The companion labels 70 of those images as human and 15 as auto-generated. None of its 70 human-labelled descriptions matches the workbook description for the same image, even after trimming surrounding whitespace.

These are separate annotation versions with different provenance, not 340 independent images. Across the two files there are 340 description records for 255 unique images. No source is automatically adjudicated as authoritative over the other. Use the workbook corpus for descriptions directly traceable to the completed labelled workbook; retain the companion's source labels when using that file.

## Fields and transformations

| Field | Meaning |
|---|---|
| `record_id` | Canonical string ID, restored from the original inventory where needed |
| `source_record_id`, `source_row` | Original supplied ID and CSV row number, including the header as row 1 |
| `image_path` | Portable path to the included JPEG, replacing a machine-specific Drive path |
| `source_image`, `image_sha256` | Original InsPLAD dataset path and image-byte hash |
| `component`, `component_canonical` | Supplied component text and inventory-backed graph vocabulary name |
| `condition`, `is_defective`, `severity` | Supplied source labels; defect presence is a JSON boolean |
| `description` | Supplied description, preserving wording and whitespace |
| `description_source` | Original `human_annotator2`, `human_annotator3`, or `auto_generated` label |
| `description_kind` | `human_labelled` or `template_generated`, for explicit filtering |
| `recommended_action` | Supplied action text, or an empty string when missing |

Two source IDs had been converted to scientific notation. They were recovered using unique exact image-filename matches after Unicode normalization, with component, condition, severity and defect-presence agreement checked as well:

| Source row | Supplied ID | Restored ID |
|---|---|---|
| 77 | `3.96865E+11` | `396864540077` |
| 190 | `4.23E+208` | `42330097e201` |

The original strings remain in `source_record_id`. Import IDs as strings; JSONL avoids spreadsheet applications automatically converting IDs. All 255 image paths resolve to included, unchanged JPEG bytes. No IDs were guessed from rounded numeric values.

The source CSV hash, reference inventory commit/hash, corrections and derived counts are in [companion_provenance.json](../data/companion_provenance.json). The export replaces U+2014 with ASCII hyphens if present; none occurred in the supplied CSV.

## Research use

Condition counts are good 139, rust 86, missingcap 10, torned-up 10, nest 6, and peeling-paint 4. This is a curated sample, not a prevalence estimate. No project training or evaluation split is published. Avoid placing descriptions of the same image in different splits when combining the two sources. Template descriptions embed graph knowledge, so agreement with the same KG is not independent evidence of correctness.

The companion is a description resource, not an evaluation-results file. Predictions, model scores, comparison tables and simulation outputs remain excluded. The Neo4j human-annotation loader imports the 85 workbook records only.

The corpus is CC BY-NC 3.0. Please cite the accompanying paper and InsPLAD, preserve source labels, and identify modifications. See [LICENSE](../LICENSE) and [CITATION.cff](../CITATION.cff).
