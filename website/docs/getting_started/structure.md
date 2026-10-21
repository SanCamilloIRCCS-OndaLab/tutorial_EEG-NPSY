---
hide:
  - toc
---

# Repository Structure

One top-level folder per language, each with the same shape: a code file
next to the `outputs/` it produces.

```text title="Repository layout"
data/                   CSV datasets + the data-generation code
  EEG/PSD/              real EEG spectra (PATHS study) + the code that computed them
  generate_datasets.ipynb   single source of truth for all three CSVs

python/                 Python case studies
  CaseStudy_1/           code + outputs/{figures,results}
  CaseStudy_2/           code + outputs/{figures,results}

r/                      R case studies
  case1/code/            CaseStudy_1.ipynb + outputs/
    R/                   the notebook's helper functions, loaded like a small package
  case2/code/            CaseStudy_2.ipynb + outputs/
    R/                   the notebook's helper functions, loaded like a small package

matlab/                 not started yet

website/                this documentation site (MkDocs Material)

useful_materials/       exploratory code and pseudocode that preceded
                        the main pipeline — not part of it, may be out of sync
```

!!! tip "Nothing is hand-copied"
    Each case study's code and its `outputs/` folder live together, so
    the figures and tables you see on each case study's page are generated
    by the code right next to them.
