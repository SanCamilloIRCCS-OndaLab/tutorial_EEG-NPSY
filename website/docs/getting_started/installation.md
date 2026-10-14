---
hide:
  - toc
---

# Installation

Pick a language below — Case Study 1 and 2 run independently in each one,
so you only need to set up the one you plan to use.

Each case study's code page offers both a Jupyter notebook (handy for
developing and debugging interactively) and a plain script with the same
code, for running without Jupyter at all. The Jupyter kernel steps below
are only needed for the notebook form.

=== ":lang-python: Python"

    Covers Case Study 1 and 2:

    ```bash title="terminal"
    conda create -n eegnpsi python=3.11
    conda activate eegnpsi
    pip install -r python/requirements.txt
    ```

    This installs pandas, numpy, scipy, statsmodels, matplotlib, seaborn,
    `mne` (Case Study 2's montage/cluster-permutation analysis), and
    `openpyxl` (Excel export).

    Both case studies expect a Jupyter kernel named **`eegnpsi`**:

    ```bash title="terminal"
    python -m ipykernel install --user --name eegnpsi --display-name "Python (eegnpsi)"
    ```

=== ":lang-r: R"

    Covers Case Study 1 and 2. You'll need R ≥ 4.4:

    ```bash title="terminal"
    Rscript r/requirements.R
    ```

    `r/requirements.R` is the R equivalent of `python/requirements.txt` — a
    plain package list, see the file itself for what each one is for.

    Then register the Jupyter kernel (one-time setup, not a package):

    ```r title="R console"
    IRkernel::installspec(name = "ir_eegnpsi", displayname = "R (eegnpsi)")
    ```

    See [Case Study 1's](../case_studies/case_study_1/r.ipynb) and
    [Case Study 2's](../case_studies/case_study_2/r.ipynb) R
    code for working examples.

=== ":lang-matlab: Matlab"

    Not implemented yet — see [Contributing](../about/contributing.md) if
    you'd like to help bring Case Study 1 or 2 to Matlab.

## Documentation site (local preview)

Only needed if you're editing this website itself, not for running the
case studies:

```bash title="terminal"
pip install -r website/docs/requirements.txt
cd website && mkdocs serve
```
