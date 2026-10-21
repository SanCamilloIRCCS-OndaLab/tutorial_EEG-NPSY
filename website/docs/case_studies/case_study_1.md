---
hide:
  - toc
---

# Case Study 1 · ERP correlates of neuropsychological performance

<div class="case-study-hero" markdown>

<div class="case-study-hero__body" markdown>

A **hypothesis-driven** look at whether two classic ERP components — N400
and P300 — relate to neuropsychological performance in post-stroke
patients, using four scalar features and linear regression.

[:octicons-arrow-right-24: See the code](case_study_1/python.ipynb){ .md-button .md-button--primary }

<span class="meta-badge">4 ERP features</span>
<span class="meta-badge">Linear regression</span>
<span class="meta-badge">Synthetic data</span>

</div>

<div class="case-study-hero__image">
<img src="../outputs/figures/D_key_associations.png" alt="The two hypothesised associations in Case Study 1, with regression lines">
</div>

</div>

!!! info "How the code is built"
    Like almost any real analysis, this case study combines **functions
    from established packages** with **a few custom functions** of its own.
    Nearly everything comes from standard packages: data handling,
    correlations, regression models, diagnostics, plots and export. The
    packages are pandas, SciPy and statsmodels in Python; the tidyverse,
    broom, car and psych in R; and the Statistics and Machine Learning
    Toolbox in Matlab. The custom code only covers what is specific to this
    study:
    
    - checking values against our clinical ranges and flagging outliers
    - a correlation heatmap with significance stars
    - report-ready regression tables

    In the R version these custom functions live in `r/case1/code/R/`, as
    if they were a small package. Each is hidden by default in the notebook,
    and a collapsed cell lets you print its source code. They were written
    for this tutorial and are not extensively tested beyond the data used
    here.

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

The code uses a **synthetic (mock) dataset** of 40 simulated post-stroke
patients, so it can be run end to end without access to real clinical data:

- `dataset_NPSY.csv` — demographics (age, sex) and neuropsychological
  scores (CRIq, APACS, Attentive Matrices, MoCA)
- `dataset_ERP.csv` — the four ERP features (N400/P300 amplitude and
  latency), linked by `subject_id`

## Pipeline

<div class="pipeline">

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M3 3h18v18H3V3zm2 2v6h6V5H5zm8 0v6h6V5h-6zM5 13v6h6v-6H5zm8 0v6h6v-6h-6z"/></svg></span>
<h4>1. Data Wrangling</h4>
<ul>
<li>Load &amp; merge</li>
<li>Range &amp; missing-data checks</li>
<li>Normality &amp; outlier detection</li>
</ul>
</div>

<div class="pipeline__arrow"><svg viewBox="0 0 24 24"><path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6z"/></svg></div>

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M4 20h2V10H4v10zm5 0h2V4H9v16zm5 0h2v-7h-2v7zm5 0h2v-13h-2v13z"/></svg></span>
<h4>2. Analysis</h4>
<ul>
<li>Descriptive statistics</li>
<li>Bivariate correlations</li>
<li>Three regression models (APACS; Attentive Matrices, kitchen-sink vs. theory-guided)</li>
<li>Post-hoc diagnostics (Q-Q, Cook's distance, VIF)</li>
</ul>
</div>

<div class="pipeline__arrow"><svg viewBox="0 0 24 24"><path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6z"/></svg></div>

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M12 16.5l-5.5-5.5 1.41-1.41L11 12.67V4h2v8.67l3.09-3.08L17.5 11z"/><path d="M5 18h14v2H5z"/></svg></span>
<h4>3. Export</h4>
<ul>
<li>Figures (PNG)</li>
<li>Tables (CSV + Excel)</li>
<li>Ready to reuse in a report or a slide</li>
</ul>
</div>

</div>

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
    reasoning in the code, Section 2.3.

[:octicons-arrow-right-24: See the code](case_study_1/python.ipynb){ .md-button .md-button--primary }

## Strengths and limitations

**Strengths** — reduces high-dimensional EEG to four interpretable scalar
features; uses regression models that are familiar to clinical researchers;
N400 and P300 rest on decades of validation in neurological populations.

**Limitations** — the predefined time windows and electrode sets may miss
effects that are delayed, spatially atypical, or otherwise deviate from the
normative pattern the features were designed to capture — a particular risk
in a clinical population such as stroke patients. When the question is
broader or more exploratory, see [Case Study 2](case_study_2.md).
