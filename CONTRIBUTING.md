# Contributing

We welcome evidence-backed corrections and extensions to the knowledge graph and human annotation corpus.

For annotations, include the release version, record ID, original field, proposed correction and supporting evidence. Preserve original human wording and provenance; do not overwrite it with generated text. New adjudications should be represented explicitly.

For graph rules, identify the component, defect, severity and relationship. Cite supporting sources without reproducing restricted engineering standards.

```bash
python3 scripts/validate_release.py
python3 ontology/validate_graph.py
python3 -m unittest discover -s tests
```

Update statistics and provenance when changing data. After reviewing intended changes, regenerate hashes with `python3 scripts/checksums.py --write`.

Keep this repository focused on reusable knowledge and annotations. Do not add experiment predictions, scores, model-comparison outputs, private workbooks, credentials or personal annotator information. Use ASCII hyphens; U+2014 is prohibited in tracked text.

Contributions follow the license for the affected files, as described in LICENSE.
