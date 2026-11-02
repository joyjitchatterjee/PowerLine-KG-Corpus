# Changelog

## 1.1.0 - 2026-11-02

- Preserve the original 85-row human workbook corpus without modification.
- Add a separate 255-record companion from the author's final_dataset.csv: 70 human-labelled and 185 template-generated descriptions.
- Expand image coverage to 255 unique InsPLAD crops across 17 components.
- Restore two damaged IDs through unique filename matches and replace machine-specific paths with portable image links.
- Document source disagreements, missing actions, provenance and template-derived severity metadata.
- Keep evaluation predictions, scores, model comparisons and simulation outputs excluded.

## 1.0.0 - 2026-11-01

- Release 85 complete human annotations and corresponding InsPLAD images across 17 components.
- Preserve exact source wording and attach record-level image and workbook provenance.
- Publish the reusable domain KG and 11 severity-conditioned maintenance rules.
- Add idempotent Neo4j loading with exact annotation and image-link verification.
- Provide citation metadata, scoped licensing, checksums, examples and automated checks.
- Establish a clean public history scoped to KG and annotated descriptions.
