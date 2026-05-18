# JOSS submission files

This directory contains the JOSS paper draft for `evacpath`.

- `paper.md`: manuscript in JOSS Markdown format.
- `paper.bib`: BibTeX references cited by the paper.

Before submission, review and edit:

- ORCID
- Any additional co-authors and affiliations
- Funding and acknowledgements
- Repository/archive DOI after release, if available

To preview the paper with the Open Journals toolchain:

```sh
docker run --rm \
  --volume "$PWD/paper:/data" \
  --user "$(id -u):$(id -g)" \
  --env JOURNAL=joss \
  openjournals/inara
```
