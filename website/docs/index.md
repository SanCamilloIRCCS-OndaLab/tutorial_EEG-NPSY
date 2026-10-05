# EEG NPSY Tutorial

<div class="onda-credit" markdown>
![ONDA Lab](assets/onda_logo.png)
A tutorial by the [**ONDA Lab**](https://sancamilloirccs-ondalab.github.io/), San Camillo IRCCS
</div>

!!! warning "Bozza"
    La maggior parte del sito è ancora una bozza con contenuti generati
    quasi totalmente da Claude. [Case Study 1](case_studies/case_study_1.md)
    e [Case Study 2](case_studies/case_study_2.md) sono invece completi e
    pronti all'uso.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![R](https://img.shields.io/badge/R-4.0%2B-276DC3.svg)](https://www.r-project.org/)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%2B-orange.svg)](https://www.mathworks.com/)

A multi-language tutorial relating **EEG/ERP measures** to **neuropsychological
performance**, with worked case studies and code available in **Python**, **R**,
and **Matlab**.

---

## Overview

This tutorial provides two complete, worked case studies on a common clinical
research question: how do EEG/ERP measures relate to neuropsychological
performance? Each one follows a full pipeline — data wrangling, descriptive
statistics, association analysis, modelling and diagnostics, export — with
plain-language explanations aimed at readers with no statistics background.

<div class="grid cards" markdown>

-   :material-chart-bell-curve:{ .lg .middle } **Case Study 1**

    ---

    A hypothesis-driven approach: two well-characterised ERP components
    (N400, P300) reduced to four scalar features and related to
    neuropsychological scores via linear regression. Complete and
    ready-to-run, written for readers with no statistics background.

    [:octicons-arrow-right-24: Case Study 1](case_studies/case_study_1.md)

-   :material-view-grid-outline:{ .lg .middle } **Case Study 2**

    ---

    A more exploratory approach: real, whole-scalp EEG spectra analysed
    with cluster-based permutation testing — no a priori restriction to a
    single band or region.

    [:octicons-arrow-right-24: Case Study 2](case_studies/case_study_2.md)

-   :material-clock-fast:{ .lg .middle } **Quick Start**

    ---

    Get up and running in minutes. Install dependencies and see where the
    data comes from.

    [:octicons-arrow-right-24: Installation](getting_started/installation.md)

</div>

---

## How to Use This Tutorial

1. Start with the [Installation](getting_started/installation.md) page to set up your environment
2. Read about the [data](getting_started/data.md) — what's synthetic and what's real
3. Work through [Case Study 1](case_studies/case_study_1.md) and [Case Study 2](case_studies/case_study_2.md), each with a plain-language write-up and the full notebook
4. Case Study 1 also has a working **R** port, alongside the original Python notebook

---

## Citation

If you use this tutorial in your work, please cite:

```
Author (2025). EEG NPSY Tutorial: A multi-language guide to EEG analysis.
GitHub: https://github.com/SanCamilloIRCCS-OndaLab/tutorial_EEG-NPSY
```

See the full [citation page](about/citation.md) for details.
