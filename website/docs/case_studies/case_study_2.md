---
hide:
  - toc
---

# Case Study 2 · Whole-scalp spectral analysis of resting-state EEG

<div class="case-study-hero" markdown>

<div class="case-study-hero__body" markdown>

An **exploratory**, whole-scalp look at resting-state EEG spectra and
global cognition — no a priori restriction to a single frequency band or
region, analysed with cluster-based permutation testing.

[:octicons-arrow-right-24: See the code](case_study_2/python.ipynb){ .md-button .md-button--primary }

<span class="meta-badge">204 channels &times; 159 freqs</span>
<span class="meta-badge">Cluster permutation</span>
<span class="meta-badge">Real EEG spectra</span>

</div>

<div class="case-study-hero__image">
<img src="../outputs_cs2/figures/D_cluster_topography.png" alt="Significant right-hemisphere cluster topography in Case Study 2">
</div>

</div>

## Research question

> Does the spectral profile of resting-state EEG relate to global
> cognitive functioning, without restricting the analysis in advance to a
> specific frequency band or region?

Where [Case Study 1](case_study_1.md) reduces the EEG signal to four
theory-driven scalar features, this case study keeps the **full power
spectral density** (PSD, 1–40 Hz, every channel) and asks broadly *where*
— across the whole scalp and spectrum — resting EEG power relates to
global cognition (MoCA). It is motivated by a well-established clinical
observation: right-hemisphere stroke is frequently accompanied by
pathological EEG slowing (more delta/theta power over the affected
region) that tracks the severity of impairment (Finnigan & Van Putten,
2013).

## Data — and an important disclosure

- The EEG spectra are **real, anonymised recordings** from the PATHS
  study (Welch's method, 1–40 Hz), authorised for publication here.
- The neuropsychological table (age, sex, CRIq, MoCA) is **synthetic**,
  as in Case Study 1.
- Because the two do not come from the same assessment, the `moca`
  column was deliberately linked to a real, montage-based property of
  each EEG recording (see `data/generate_datasets.ipynb` for the full,
  explicit disclosure). **The resulting brain–behaviour association
  should not be read as a real clinical finding** — it exists so this
  case study has a real spectrum to analyse and something genuine to
  recover.

## Pipeline

<div class="pipeline">

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M3 3h18v18H3V3zm2 2v6h6V5H5zm8 0v6h6V5h-6zM5 13v6h6v-6H5zm8 0v6h6v-6h-6z"/></svg></span>
<h4>1. Data Wrangling</h4>
<ul>
<li>Strictly align PSD array with neuropsychological table</li>
<li>Spectrum data-quality checks</li>
<li>Log-power distribution check</li>
</ul>
</div>

<div class="pipeline__arrow"><svg viewBox="0 0 24 24"><path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6z"/></svg></div>

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M4 20h2V10H4v10zm5 0h2V4H9v16zm5 0h2v-7h-2v7zm5 0h2v-13h-2v13z"/></svg></span>
<h4>2. Analysis</h4>
<ul>
<li>Baseline model (Case-Study-1-style, for contrast)</li>
<li>Mass-univariate partial correlation</li>
<li>Cluster-based permutation (primary + secondary)</li>
<li>Exploratory per-band breakdown</li>
</ul>
</div>

<div class="pipeline__arrow"><svg viewBox="0 0 24 24"><path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6z"/></svg></div>

<div class="pipeline__step">
<span class="pipeline__badge"><svg viewBox="0 0 24 24"><path d="M12 16.5l-5.5-5.5 1.41-1.41L11 12.67V4h2v8.67l3.09-3.08L17.5 11z"/><path d="M5 18h14v2H5z"/></svg></span>
<h4>3. Export</h4>
<ul>
<li>Figures (PNG)</li>
<li>Tables (CSV + Excel)</li>
</ul>
</div>

</div>

## A taste of the results

<div class="grid cards" markdown>

-   ![Grand-average spectrum](outputs_cs2/figures/A_grand_average_psd.png)

    The real grand-average EEG spectrum: a 1/f-like decay with a visible
    alpha bump — a first sanity check that the recordings look like EEG.

-   ![Cluster topography](outputs_cs2/figures/D_cluster_topography.png)

    Where the significant effect is: a right-lateralised, low-frequency
    cluster (marked channels), shown against real data on both
    hemispheres.

</div>

!!! tip "Key takeaway"
    The **primary**, whole-spectrum test does not survive correction at
    n=40 — an honest illustration of the paper's own caveat that
    cluster-based permutation is relatively underpowered at this sample
    size. A **secondary**, pre-registered test restricted to the
    hypothesised region (right hemisphere, delta/theta) does recover a
    significant cluster. Reporting both, rather than only the one that
    "worked", is what keeps the secondary result meaningful — the same
    a-priori-vs-post-hoc logic Case Study 1 teaches for choosing
    predictors, applied here to choosing *where to look*. An exploratory
    breakdown by individual frequency band (Section 2.7 of the code)
    makes the trade-off concrete: none of the five canonical bands
    survives correction on its own, which is exactly why the secondary
    test pools delta and theta together.

[:octicons-arrow-right-24: See the code](case_study_2/python.ipynb){ .md-button .md-button--primary }

Exported results, ready to open in Excel or re-use elsewhere:

- [:material-file-excel: All tables — one workbook, one sheet each](outputs_cs2/results/CaseStudy_2_results.xlsx)
- [Descriptive statistics (CSV)](outputs_cs2/results/table1_descriptives.csv)
- [Cluster results — primary & secondary (CSV)](outputs_cs2/results/table2_clusters.csv)
- [Baseline model (CSV)](outputs_cs2/results/table3_baseline_model.csv)
- [Per-band breakdown, exploratory (CSV)](outputs_cs2/results/table4_band_breakdown.csv)

The code and raw data also live in the [REDACTED] repository, under
`python/CaseStudy_2/`, `r/case2/`, and `data/`.

## Strengths and limitations

**Strengths** — no a priori commitment to a specific band or region,
able to recover a distributed, low-frequency, right-hemisphere pattern
that no single ERP feature (Case Study 1) would capture; respects the
real spatial and spectral dependency structure of the signal.

**Limitations** — computationally heavier than the GLM-based approach of
Case Study 1; statistically demanding, since cluster-based permutation
is relatively underpowered at a sample size like this one, so only
fairly marked associations are likely to survive; a significant
secondary result is only meaningful because the restricted region was
pre-registered *before* looking at the data — restricting only after
seeing what "worked" would be the same circular reasoning
[Case Study 1](case_study_1.md) warns against, just at the level of
search space instead of predictor selection.
