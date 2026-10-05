# Installation

## Python (Case Study 1 and 2)

```bash
conda create -n eegnpsi python=3.11
conda activate eegnpsi
pip install -r python/requirements.txt
```

This installs pandas, numpy, scipy, statsmodels, matplotlib, seaborn, `mne`
(Case Study 2's montage/cluster-permutation analysis), and `openpyxl`
(Excel export).

Both case study notebooks expect a Jupyter kernel named **`eegnpsi`**:

```bash
python -m ipykernel install --user --name eegnpsi --display-name "Python (eegnpsi)"
```

## R (Case Study 1 only, for now)

Case Study 1 also has a working R port. You'll need R ≥ 4.4 with the
tidyverse, plus a few extras:

```r
install.packages(c("car", "patchwork", "openxlsx", "e1071", "IRkernel"))
IRkernel::installspec(name = "ir_eegnpsi", displayname = "R (eegnpsi)")
```

`car` provides the Variance Inflation Factor check, `patchwork` combines
the `ggplot2` panels into one figure, `openxlsx` handles the Excel export,
and `IRkernel` is what lets Jupyter (and this site) run R notebooks at
all — see [Case Study 1's R notebook](../case_studies/case_study_1_notebook.ipynb)
for a working example.

## Matlab

Not implemented yet.

## Documentation site (local preview)

```bash
pip install -r website/docs/requirements.txt
cd website && mkdocs serve
```
