# Case Study 1 · ERP correlates of neuropsychological performance

!!! info "Who this is for"
    This case study assumes **no prior background in statistics**. Every
    figure is followed by a short "What do we see in the plot?" box, and
    every modelling choice is explained in plain language before the code
    that implements it.

## Research question

> Are the amplitude and latency of specific ERP components associated with
> neuropsychological performance and demographic characteristics in
> post-stroke patients?

This is a **hypothesis-driven** question: rather than exploring the full
spectral or spatiotemporal structure of the EEG signal (see
[Case Study 2](case_study_2.md)), it targets two specific, well-characterised
ERP components:

- **N400** — a negative deflection ~400 ms post-stimulus, indexing semantic
  processing and language comprehension (Kutas & Federmeier, 2011)
- **P300** — a positive deflection ~300 ms post-target, indexing attentional
  resource allocation (Polich, 2007)

For each component we consider **amplitude** (mean µV in a predefined
window) and **latency** (ms of peak amplitude) — four participant-level
neural predictors in total.

## Data

The notebook uses a **synthetic (mock) dataset** of 40 simulated post-stroke
patients, so it can be run end to end without access to real clinical data:

- `dataset_NPSY.csv` — demographics (age, sex) and neuropsychological
  scores (CRIq, APACS, Attentive Matrices, MoCA)
- `dataset_ERP.csv` — the four ERP features (N400/P300 amplitude and
  latency), linked by `subject_id`

## Pipeline

1. **Data wrangling** — load & merge, range checks, missing data, normality
   checks, outlier detection
2. **Analysis** — descriptive statistics, bivariate correlations, three
   regression models (APACS; Attentive Matrices, kitchen-sink vs.
   theory-guided), post-hoc assumption checking (residuals, Q-Q, Cook's
   distance, VIF)
3. **Export** — figures and tables (CSV + Excel), ready to reuse in a
   report or a slide

## A taste of the results

<div class="grid cards" markdown>

-   ![Correlation heatmap](outputs/figures/C_correlations.png)

    Pearson correlations between all ERP and neuropsychological variables,
    annotated with significance stars.

-   ![Key associations](outputs/figures/D_key_associations.png)

    The two hypothesised associations (P300 amplitude ↔ Attentive Matrices;
    N400 latency ↔ APACS), with regression line and 95% CI band.

</div>

!!! tip "Key takeaway"
    More predictors do not make a better model — and *how* you decide which
    ones to drop matters as much as the decision itself. Choosing predictors
    **a priori**, from theory, avoids the circular reasoning of dropping
    whatever happens to be non-significant in a bigger model. See the full
    reasoning in the notebook, Section 2.3.

## Explore it yourself

[:octicons-arrow-right-24: Open the full notebook](case_study_1_notebook.ipynb){ .md-button .md-button--primary }
[:material-download: Download the notebook](case_study_1_notebook/case_study_1_notebook.ipynb){ .md-button }

Exported results, ready to open in Excel or re-use elsewhere:

- [:material-file-excel: All tables — one workbook, one sheet each](outputs/results/CaseStudy_1_results.xlsx)
- [Descriptive statistics (CSV)](outputs/results/table1_descriptives.csv)
- [Bivariate correlations (CSV)](outputs/results/table2_correlations.csv)
- [Regression results (CSV)](outputs/results/table3_regression.csv)
- [Multicollinearity check — VIF (CSV)](outputs/results/table4_vif.csv)

The notebook and raw data also live in the
[GitHub repository](https://github.com/SanCamilloIRCCS-OndaLab/EEG_NPSI_tutorial/tree/main/python),
under `python/CaseStudy_1/CaseStudy_1.ipynb` and `data/`.

## Strengths and limitations

**Strengths** — reduces high-dimensional EEG to four interpretable scalar
features; uses regression models that are familiar to clinical researchers;
N400 and P300 rest on decades of validation in neurological populations.

**Limitations** — the predefined time windows and electrode sets may miss
effects that are delayed, spatially atypical, or otherwise deviate from the
normative pattern the features were designed to capture — a particular risk
in a clinical population such as stroke patients. When the question is
broader or more exploratory, see [Case Study 2](case_study_2.md).
