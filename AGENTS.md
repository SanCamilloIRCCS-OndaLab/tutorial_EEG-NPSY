# AGENTS.md — EEG NPSI Tutorial

## What this is

Multi-language tutorial for EEG data analysis. **Python** code is functional; **R** and **Matlab** are scaffolds only (`.gitkeep` — no real code yet). Data is synthetic/mock.

## Repo structure

- `data/` — CSV datasets (`dataset_NPSY.csv`, `dataset_P300.csv`, `dataset_PSD.csv`); mock-data notebooks in `data/Code/`
- `python/` — actual analysis code
  - `utils.py` — all reusable functions (I/O, stats, plotting)
  - `_build_notebook.py` — **source of truth** for `CaseStudy_1.ipynb` (the `.ipynb` is generated, not hand-edited)
  - `CaseStudy_1.ipynb` — generated; edit `_build_notebook.py` and re-run to regenerate
  - `CaseStudy_1/` and `CaseStudy_2/` — output directories (figures, reports, results)
- `r/` and `matlab/` — empty scaffolds (code/ + outputs/ subdirs with `.gitkeep`)
- `website/` — MkDocs documentation source
- `useful_materials/` — supplementary notebooks and pseudocode (not part of main pipeline)

## Commands

### Python environment
```bash
pip install -r python/requirements.txt
```
Dependencies: pandas, numpy, scipy, statsmodels, matplotlib, seaborn.

### Regenerate the notebook
```bash
python python/_build_notebook.py
```
Produces `python/CaseStudy_1.ipynb`. If you change `utils.py` or the notebook logic, re-run this.

### Run the notebook
Open `python/CaseStudy_1.ipynb` and execute cells. It expects a kernel named **`eegnpsi`** (hardcoded in `_build_notebook.py` metadata). Change the kernel name in `_build_notebook.py` if yours differs.

### Docs site (local preview)
```bash
pip install mkdocs-material mkdocs-glightbox pymdown-extensions
cd website && mkdocs serve
```

### Docs deploy
Pushed to `main` → GitHub Actions auto-deploys to GitHub Pages via `website/mkdocs gh-deploy --force`. Also triggerable via `workflow_dispatch`.

## No tests, no lint, no typecheck

This repo has none. Don't look for them.

## Data conventions

- CSVs use auto-detected separator (`utils.load_dataset` tries tab → comma → whitespace)
- Key columns: `subject_id` (merge key), `P300_latency`, `APACS_tot`, `age`, `education`
- 40 subjects (41 rows including header)

## Notebook build details

- Uses `nbformat` to construct cells programmatically
- `md()` and `code()` helper functions in `_build_notebook.py` wrap `nbf.v4` calls
- Output paths are relative to the notebook: `CaseStudy_1/outputs/{figures,report,results}`
- `_build_notebook.py` references `"__file__"` string (not `__file__`) in `sys.path` — this is intentional for notebook execution context

## Useful materials

The `useful_materials/` directory contains standalone exploratory notebooks (correlations, regression, VIF checks) that preceded the main pipeline. They may be out of sync with `utils.py`.
