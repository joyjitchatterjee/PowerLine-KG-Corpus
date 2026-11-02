# Human annotation data card

This card describes the unchanged 85-record workbook corpus. The separately supplied 255-record mixed-provenance collection has its own [companion data card](COMPANION_DATA_CARD.md). All 85 workbook images are included among those 255 images; source descriptions are kept separate.

## Composition and origin

The corpus contains 85 human-annotated image records across 17 power-line component types, with five images per component. Every record has a defect-presence label, description, recommended action, and annotator note. The human labels contain 53 yes and 32 no values, exported as booleans.

Annotations were supplied by the author in `human_annotation_workbook_blind_only_labelled.xlsx`, sheet `Blind_Image_Annotation`, rows 2 through 86. Workbook IDs match the original image manifest exactly. Descriptions are taken from the populated human annotation fields, not model-generated substitutes. The paper describes expert annotation by a power-line inspection specialist; the workbook does not supply an annotator identity or per-record annotation date, and neither is inferred.

Source dataset conditions are good (32), rust (38), missingcap (4), torned-up (4), peeling-paint (4), and nest (3). These are the original dataset labels, kept separately from the human defect-presence labels. Summary counts can be read from [statistics.json](../data/statistics.json).

## Fields

| Field | Meaning |
|---|---|
| `record_id` | Stable identifier joining each annotation to its image |
| `review_id` | Original three-digit workbook review identifier |
| `component` | Workbook component text |
| `component_canonical` | Corresponding KG component name from the source image inventory |
| `defect_present` | Human yes/no label, represented as a JSON boolean |
| `expert_description` | Human description, retaining original spelling and whitespace |
| `recommended_action` | Human free-text maintenance recommendation |
| `annotator_notes` | Human observations, caveats, and uncertainty |
| `annotation_source` | `human_labelled_workbook` |
| `source_sheet`, `source_row` | Source workbook location for verification |
| `dataset_condition_label` | Original InsPLAD label, not a human severity annotation |
| `source_image` | Original source dataset path |
| `image_path` | Portable relative path to the included JPEG |
| `image_sha256` | SHA-256 digest of the included image bytes |

[JSONL](../data/annotations.jsonl) preserves booleans and integer row numbers. [CSV](../data/annotations.csv) stores booleans as `True`/`False`; use a CSV parser because text can contain commas or line breaks.

## Processing

The extraction joins rows to source images by exact `record_id`, verifies the dataset condition label, and copies the original JPEG bytes. Images are named by record ID for portable paths. Source filenames remain available in `source_image`.

Human wording is not corrected, paraphrased, or adjudicated. U+2014 is replaced with an ASCII hyphen where present, as required by repository policy. Exact source hashes and transformations are recorded in [provenance.json](../data/provenance.json); [SHA256SUMS](../SHA256SUMS) verifies released artifacts. The source workbook is not bundled, avoiding hidden workbook content and unnecessary duplicate image storage.

## Scope and limitations

This resource is the 85-record human annotation subset. It does not claim to reconstruct the paper's larger mixed human/model corpus. The 17 source component groups are preserved rather than silently relabelled to match the paper's later experimental grouping. No training or held-out split is assigned.

Sampling prioritised defects while keeping normal controls. This is a curated collection, not an estimate of defect prevalence. Images derive from InsPLAD, a transmission-line inspection dataset from northeast Brazil. Related source scenes and crop similarities should be considered when users design their own splits.

The expert text includes uncertainty and may recommend actions that differ from the KG's severity-conditioned rules. No numeric severity was supplied in the workbook, so none is inferred. The graph loader keeps human annotation nodes separate and preserves these differences for research. Assess engineering claims independently before operational use.

## Reuse

The image-and-description collection is distributed under CC BY-NC 3.0. Attribute this work and InsPLAD, preserve provenance, and identify modifications. See [LICENSE](../LICENSE), [CITATION.cff](../CITATION.cff), and [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
