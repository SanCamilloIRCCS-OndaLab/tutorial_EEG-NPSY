# EEG NPSI Tutorial

!!! warning "Bozza"
    Tutto il sito è una bozza e con contenuti random, generati quasi totalmente da Claude

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![R](https://img.shields.io/badge/R-4.0%2B-276DC3.svg)](https://www.r-project.org/)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%2B-orange.svg)](https://www.mathworks.com/)

A comprehensive, multi-language tutorial for EEG data analysis, covering **Time-Frequency Analysis**, **ERSP**, **Connectivity**, and **Source Analysis** — with code available in **Python**, **R**, and **Matlab**.

---

## Overview

This tutorial provides a step-by-step guide to analyzing EEG data using standard pipelines reproducible across three programming languages.
Each analysis step is presented with parallel code in Python, R, and Matlab so you can follow along in whichever environment you prefer.

<div class="grid cards" markdown>

-   :material-clock-fast:{ .lg .middle } **Quick Start**

    ---

    Get up and running in minutes. Install dependencies and load the example dataset.

    [:octicons-arrow-right-24: Installation](getting_started/installation.md)

-   :material-chart-line:{ .lg .middle } **Time-Frequency Analysis**

    ---

    Compute and visualize time-frequency representations using wavelets and short-time Fourier transforms.

    [:octicons-arrow-right-24: Tutorial 02](tutorials/02_time_frequency.md)

-   :material-brain:{ .lg .middle } **Connectivity**

    ---

    Estimate functional and effective connectivity between EEG channels and regions of interest.

    [:octicons-arrow-right-24: Tutorial 04](tutorials/04_connectivity.md)

-   :material-map-marker-radius:{ .lg .middle } **Source Analysis**

    ---

    Reconstruct the cortical sources of scalp EEG signals using inverse methods.

    [:octicons-arrow-right-24: Tutorial 05](tutorials/05_source_analysis.md)

</div>

---

## Languages

All tutorial code is available in three languages. Use the tabs throughout the site to switch between them.

=== ":lang-python: Python"

    ```python
    # Example: load EEG data with MNE
    import mne
    raw = mne.io.read_raw_fif('data/sample_eeg.fif', preload=True)
    raw.filter(1., 40.)
    raw.plot()
    ```

=== ":lang-r: R"

    ```r
    # Example: load EEG data with eegUtils
    library(eegUtils)
    raw <- import_raw("data/sample_eeg.bdf")
    raw <- eeg_filter(raw, low_freq = 1, high_freq = 40)
    plot(raw)
    ```

=== ":lang-matlab: Matlab"

    ```matlab
    % Example: load EEG data with EEGLAB
    [ALLEEG EEG CURRENTSET] = eeglab;
    EEG = pop_biosig('data/sample_eeg.bdf');
    EEG = pop_eegfiltnew(EEG, 1, 40);
    eegplot(EEG.data);
    ```

---

## How to Use This Tutorial

1. Start with the [Installation](getting_started/installation.md) page to set up your environment
2. Download the [example dataset](getting_started/data.md)
3. Follow the tutorials in order, or jump directly to the analysis you need
4. Each tutorial page shows the same analysis in all three languages using tabs

---

## Citation

If you use this tutorial in your work, please cite:

```
Author (2025). EEG NPSI Tutorial: A multi-language guide to EEG analysis.
GitHub: https://github.com/GITHUBNICKNAME/EEG_NPSI_tutorial
```

See the full [citation page](about/citation.md) for details.
