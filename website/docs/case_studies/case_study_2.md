# Case Study 2 · Whole-scalp spectral analysis of resting-state EEG

!!! info "Who this is for"
    Same audience as [Case Study 1](case_study_1.md) — no prior statistics
    background assumed. This case study uses a more advanced technique
    (cluster-based permutation testing), so the plain-language explanation
    boxes do more work here; read them before the code.

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

1. **Data wrangling** — load & strictly align the PSD array with the
   neuropsychological table, inspect the spectrum for data-quality red
   flags, missing data, log-power distribution check
2. **Analysis** — a naive Case-Study-1-style baseline model (for
   contrast), mass-univariate partial correlation at every channel ×
   frequency point, cluster-based permutation testing (a **primary**
   whole-spectrum test and a pre-registered **secondary/confirmatory**
   test), topographic visualisation, and an exploratory breakdown by
   canonical frequency band
3. **Export** — figures and tables (CSV + Excel)

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
    breakdown by individual frequency band (Section 2.7 of the notebook)
    makes the trade-off concrete: none of the five canonical bands
    survives correction on its own, which is exactly why the secondary
    test pools delta and theta together.

## Explore it yourself

[:octicons-arrow-right-24: Open the full notebook](case_study_2_notebook.ipynb){ .md-button .md-button--primary }
[:material-download: Download the notebook](case_study_2_notebook/case_study_2_notebook.ipynb){ .md-button }

Exported results, ready to open in Excel or re-use elsewhere:

- [:material-file-excel: All tables — one workbook, one sheet each](outputs_cs2/results/CaseStudy_2_results.xlsx)
- [Descriptive statistics (CSV)](outputs_cs2/results/table1_descriptives.csv)
- [Cluster results — primary & secondary (CSV)](outputs_cs2/results/table2_clusters.csv)
- [Baseline model (CSV)](outputs_cs2/results/table3_baseline_model.csv)
- [Per-band breakdown, exploratory (CSV)](outputs_cs2/results/table4_band_breakdown.csv)

The notebook and raw data also live in the
[GitHub repository](https://github.com/SanCamilloIRCCS-OndaLab/EEG_NPSI_tutorial/tree/main/python),
under `python/CaseStudy_2/CaseStudy_2.ipynb` and `data/`.

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
