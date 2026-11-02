# Contributing

Thank you for helping improve SynthVisCom. Reports of errors in the documentation, new teaching exercises and proposals for future versions of the generator are welcome.

## Checking the dataset

```
Rscript code/check.R
```

The script verifies the checksums in `MD5SUMS`, that the generator reproduces the published files exactly, and the structure and keys of every table. It runs on every change and every week.

## Small changes (welcome as pull requests)

- The website, the READMEs, the examples and the changelog.

## Changes to discuss in an issue first

- `data/`, `metadata/`, `images/`, `code/`, `MD5SUMS` and `DATA_DESCRIPTOR.md`. Any change to the data is a new version of the dataset with its own DOI.
- Workflows and this file.

All data are synthetic and must never be presented as evidence about real people.
