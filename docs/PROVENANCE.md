# Provenance

Version 1.0.0 was prepared on 1 November 2026 as a focused release of domain knowledge and human-annotated image descriptions.

## Annotations and images

The annotation source is `human_annotation_workbook_blind_only_labelled.xlsx`, supplied by the paper's author. The `Blind_Image_Annotation` sheet contains 85 complete records. The example and instruction sheets are not corpus records. Hidden IDs and source labels are used only as explicit provenance and join keys.

All 85 IDs match the source image inventory and all source condition labels agree. Original image bytes are retained, with portable filenames based on record IDs. Human descriptions, actions and notes preserve their source wording, spelling and whitespace, apart from the repository-wide punctuation normalization. See [data/provenance.json](../data/provenance.json) for the source workbook SHA-256 and exact transformations.

Image source: [InsPLAD version 1](https://data.mendeley.com/datasets/5n3fjgvfyz/1), DOI 10.17632/5n3fjgvfyz.1, CC BY-NC 3.0.

## Knowledge graph

The graph originates from `joyjitchatterjee/PowerLine-AgenticAI`, branch `develop`, commit `61912dfc0d46103934b68c66145f30bcd91a23ca`. The release retains the domain vocabulary, severity-conditioned action rules, and duplicate-free standards links. Experiment-specific artifact metadata and ingestion dependencies were removed. A corpus dataset node and a separate human annotation loader were added.

No human severity values or expert identities are inferred. Free-text maintenance recommendations remain separate from graph action rules.

## Citation and versions

The [GLOW @ ISWC 2026 programme](https://glow-workshop.github.io/iswc2026/) confirms the paper title and author order. The [paper PDF](https://joyjitchatterjee.github.io/assets/papers/glow-2026-power-line-om.pdf) is available on Joyjit Chatterjee's website and is linked in the citation metadata. Citation metadata also follows the author-supplied paper and slides. No unverified DOI or proceedings volume is introduced.

Cite the paper and the release tag or commit. This version is a clean public history containing only the intended reusable resources. Checksums in [SHA256SUMS](../SHA256SUMS) cover corpus and graph artifacts.
