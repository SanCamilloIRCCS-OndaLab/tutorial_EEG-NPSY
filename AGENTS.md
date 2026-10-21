# AGENTS.md — EEG NPSI Tutorial

## What this is

Multi-language tutorial for EEG data analysis. **Python** and **R** are both functional for Case Study 1 (`python/CaseStudy_1/CaseStudy_1.ipynb`, `r/case1/code/CaseStudy_1.ipynb`) and Case Study 2 (`python/CaseStudy_2/CaseStudy_2.ipynb`, `r/case2/code/CaseStudy_2.ipynb`), treated as equal, independent implementations rather than one language being primary — R kernel `ir_eegnpsi` (points at the `eegnpsi` conda env's own R install). **Matlab** is functional for Case Study 1 (`matlab/case1/code/CaseStudy_1.m`, a plain script, no notebook format) but Case Study 2 is still a scaffold only (`matlab/case2/` — `.gitkeep`, no real code yet); more languages may be added over time. Data is synthetic/mock, except Case Study 2's EEG spectra (real, see `data/generate_datasets.ipynb`).

Case Study 2's R implementation has no MNE equivalent for electrode positions/adjacency/topomaps, so it reads three small pre-exported CSVs (`data/EEG/PSD/montage_ch_pos_3d.csv`, `montage_ch_pos_2d.csv`, `montage_adjacency_edges.csv`, `montage_outline.csv`) instead — generated from the real montage by `data/EEG/PSD/compute_montage_assets.ipynb`. Everything downstream (cluster-permutation stats, topomap interpolation) is plain R (`Matrix`, `igraph`, base `loess`) in the helper functions under `r/case2/code/R/`, no new heavy dependency.

## Repo structure

- `data/` — CSV datasets (`dataset_NPSY.csv`, `dataset_ERP.csv`, `dataset_PSD.csv`), all generated together by `data/generate_datasets.ipynb`. `dataset_NPSY.csv`/`dataset_ERP.csv` are entirely synthetic; the PSD arrays in `data/EEG/PSD/` (`psd_matrix.npy`, `psd_log_matrix.npy`) are real, anonymised EEG recordings computed by `data/EEG/PSD/compute_psd.ipynb` — `dataset_PSD.csv` is a band-power summary derived from them. See the notice at the top of `generate_datasets.ipynb` for how the (synthetic) `moca` column and the real spectra are linked.
- `python/` — actual analysis code
  - `utils.py` — all reusable functions (I/O, stats, plotting)
  - `CaseStudy_1/CaseStudy_1.ipynb`, `CaseStudy_2/CaseStudy_2.ipynb` — hand-maintained notebooks (no build script generates them)
  - `CaseStudy_1/CaseStudy_1.py`, `CaseStudy_2/CaseStudy_2.py` — plain-script mirrors of the notebooks, for running without Jupyter; **generated**, do not hand-edit (see "Regenerating the plain scripts" below)
  - `CaseStudy_1/outputs`, `CaseStudy_2/outputs` — output directories (figures, reports, results), next to their notebook
- `r/` — `case1/` and `case2/` are both functional (`code/CaseStudy_N.ipynb` + `code/CaseStudy_N.R` plain-script mirror, same generated/do-not-hand-edit rule as the Python ones + `outputs/{figures,results}`)
  - Written as idiomatic tidyverse R: `readr`/`dplyr`/`tidyr`/`purrr`/`ggplot2`, `broom` for model tables, `cli` for status messages, and tibbles/plots that auto-print. Don't use `cat(sprintf(...))` for output.
  - Generic helper functions live in `code/R/*.R` (one file per topic, roxygen-style headers), as if they came from a small package. Setup loads them with `list.files("R", ...) %>% walk(~ source(.x, keep.source = TRUE))`. Analysis-specific steps stay in the notebook.
  - Where a helper is first used, a code cell tagged `inspect` (cell metadata `"tags": ["inspect"]`, `"jupyter": {"outputs_hidden": true}`) prints its source with `print(fn)`; `print()` is needed because IRkernel's HTML repr of a function drops its comments. On the site, `website/docs/javascripts/inspect-cells.js` wraps every `.celltag_inspect` cell in a collapsed `<details>`.
  - The Case Study 2 helpers (`.npy` reader, cluster-based permutation, topomap) are minimal teaching implementations and must keep their "not extensively tested / not a validated implementation" caution, both in the code and on the site.
- `matlab/` — `case1/` is functional (`code/CaseStudy_1.m`, a hand-maintained plain script — no notebook, no generated-script step — plus `code/swtest.m`/`redblue_colormap.m` helpers and `outputs/{figures,results}`); `case2/` is still an empty scaffold (`code/` + `outputs/` subdirs with `.gitkeep`)
- `website/` — MkDocs documentation source. `docs/case_studies/case_study_N/{python,r}.ipynb` are symlinks to the real notebooks above; `docs/case_studies/scripts/case_study_N_{python,r}.{py,R}` are symlinks to the plain scripts. The `mkdocs-jupyter` plugin is configured to `ignore` that `scripts/` folder (see `mkdocs.yml`) so it copies those files verbatim instead of trying to render them as jupytext notebooks.
- `useful_materials/` — supplementary notebooks and pseudocode (not part of main pipeline)

## Regenerating the plain scripts

`python/CaseStudy_N/CaseStudy_N.py` and `r/caseN/code/CaseStudy_N.R` are generated from their notebooks (markdown cells become `#`-commented prose, code cells copied verbatim) - re-run this whenever a notebook changes:

```python
import nbformat, re

def notebook_to_script(nb_path, header_comment, headless_backend=False, wrap_display_lines=None):
    wrap_display_lines = wrap_display_lines or set()
    nb = nbformat.read(nb_path, as_version=4)
    lines = [header_comment]
    if headless_backend:
        lines += ["", "import matplotlib", 'matplotlib.use("Agg")']
    lines.append("")
    for cell in nb.cells:
        src = cell.source
        if not src.strip():
            continue
        if cell.cell_type == "markdown":
            lines += [("# " + l).rstrip() for l in src.split("\n")] + [""]
        elif "inspect" in cell.metadata.get("tags", []):
            # R "inspect" cells only print a helper's source: comment them
            # out, so a script run doesn't dump whole functions
            lines += [l if l.startswith("#") else ("# " + l).rstrip()
                      for l in src.rstrip("\n").split("\n")] + [""]
        else:
            for line in src.rstrip("\n").split("\n"):
                stripped = line.strip()
                indent = line[: len(line) - len(line.lstrip())]
                m = re.fullmatch(r"display\((.+)\)", stripped)
                if m:
                    lines.append(f"{indent}print({m.group(1)})")
                elif stripped in wrap_display_lines:
                    lines.append(f"{indent}print({stripped})")
                else:
                    lines.append(line)
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"
```

Two Python-only gotchas this handles, that R doesn't need (R auto-prints visible top-level values even under `Rscript`, Python doesn't run a plain `.py`):
- `display(x)` (Jupyter/IPython-only) → `print(x)`
- bare trailing expressions relying on Jupyter's implicit last-line display (e.g. a cell ending in just `table3_regression` with no `print`) → wrapped in `print(...)`. Check each notebook for these (a cell's last non-comment line that's a bare name/attribute access with no assignment) before regenerating - the current wrap lists are in the git history of this generation step, not persisted as a script in the repo.

For the R scripts, the header comment also says to run the script from its own folder (`r/caseN/code/`), so that `R/` and `../outputs` resolve. Restore the notebooks' `kernelspec` to `ir_eegnpsi` if you executed them with another kernel.

Also set `matplotlib.use("Agg")` before any `pyplot` import in Python scripts specifically - otherwise `plt.show()` can hang or pop up GUI windows when run headlessly outside Jupyter, depending on the environment's available display/backend.

Verify by actually running the regenerated script end to end (`python CaseStudy_N.py` / `Rscript CaseStudy_N.R`), not just checking it parses - both must complete and reproduce the same `outputs/` as the notebook.

## Commands

### Python environment
```bash
pip install -r python/requirements.txt
```
Dependencies: pandas, numpy, scipy, statsmodels, matplotlib, seaborn.

### Run a notebook
Open `python/CaseStudy_1/CaseStudy_1.ipynb` or `python/CaseStudy_2/CaseStudy_2.ipynb` and execute cells. Both expect a Jupyter kernel named **`eegnpsi`** (see Installation in the docs site, or `website/docs/getting_started/installation.md`).

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
- Key column: `subject_id` (merge key across all three CSVs)
- `dataset_NPSY.csv`: `age`, `sex`, `criq`, `apacs`, `att_matr`, `moca`
- `dataset_ERP.csv`: `n400_amp`, `n400_lat`, `p300_amp`, `p300_lat`
- `dataset_PSD.csv`: `mean_power`, `delta_power`, `theta_power`, `alpha_power`, `beta_power`, `gamma_power`
- 45 subjects (46 rows including header): 40 clean + 5 deliberately added with missing/implausible values (Section 8 of `generate_datasets.ipynb`), which each Case Study's Data Wrangling section detects and excludes, bringing the analysed N back to 40. `data/EEG/PSD/subject_id_mapping.csv` flags the 5 added rows with a `-dup` suffix on their `real_eeg_subject_id` (they are duplicated spectra, not independent recordings). Case Study 2 reads the matching 45-subject `psd_log_matrix_full.npy`/`psd_matrix_full.npy`/`subject_ids_full.txt`, not the original 40-subject `psd_log_matrix.npy`/`psd_matrix.npy`/`subject_ids.txt` (which `generate_datasets.ipynb` reads as input and never overwrites).

## Useful materials

The `useful_materials/` directory contains standalone exploratory notebooks (correlations, regression, VIF checks) that preceded the main pipeline. They may be out of sync with `utils.py`.
