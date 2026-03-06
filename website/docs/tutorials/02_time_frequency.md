# 02 · Time-Frequency Analysis

Time-frequency analysis allows you to examine how the spectral content of the EEG signal changes over time.
In this tutorial we compute time-frequency representations (TFR) using **Morlet wavelets** and the **Short-Time Fourier Transform (STFT)**.

---

## Prerequisites

Make sure you have completed [Tutorial 01 · Preprocessing](01_preprocessing.md) and have the cleaned epochs available.

---

## 1. Load Preprocessed Epochs

=== ":lang-python: Python"

    ```python
    import mne
    import numpy as np
    import matplotlib.pyplot as plt

    # Load preprocessed epochs
    epochs = mne.read_epochs('outputs/results/epochs_clean.fif', preload=True)
    print(epochs)
    ```

=== ":lang-r: R"

    ```r
    library(eegUtils)
    library(tidyverse)

    # Load preprocessed epochs
    epochs <- readRDS("outputs/results/epochs_clean.rds")
    print(epochs)
    ```

=== ":lang-matlab: Matlab"

    ```matlab
    % Load preprocessed epochs (FieldTrip format)
    load('outputs/results/epochs_clean.mat', 'data');
    disp(data);
    ```

---

## 2. Morlet Wavelet Transform

=== ":lang-python: Python"

    ```python
    from mne.time_frequency import tfr_morlet

    # Define frequencies of interest
    freqs = np.arange(4, 50, 1)  # 4–50 Hz
    n_cycles = freqs / 2.        # bandwidth: half the frequency

    # Compute TFR
    power = tfr_morlet(
        epochs,
        freqs=freqs,
        n_cycles=n_cycles,
        return_itc=False,
        average=True
    )

    # Plot
    power.plot(['Oz'], baseline=(-0.5, 0), mode='logratio', title='Wavelet TFR - Oz')
    ```

=== ":lang-r: R"

    ```r
    # Using eegUtils + custom wavelet function
    # (see r/code/utils_tfr.R for helper functions)
    source("code/utils_tfr.R")

    tfr <- compute_morlet_tfr(
      epochs,
      freqs    = seq(4, 50, by = 1),
      n_cycles = seq(4, 50, by = 1) / 2
    )

    plot_tfr(tfr, channel = "Oz", baseline = c(-0.5, 0))
    ```

=== ":lang-matlab: Matlab"

    ```matlab
    % FieldTrip wavelet analysis
    cfg            = [];
    cfg.method     = 'wavelet';
    cfg.foi        = 4:1:50;     % frequencies of interest
    cfg.width      = cfg.foi/2;  % number of cycles
    cfg.output     = 'pow';
    cfg.toi        = -0.5:0.05:1.5;
    cfg.channel    = 'Oz';
    cfg.keeptrials = 'no';

    TFR = ft_freqanalysis(cfg, data);
    ft_singleplotTFR([], TFR);
    ```

---

## 3. Short-Time Fourier Transform (STFT)

=== ":lang-python: Python"

    ```python
    from mne.time_frequency import tfr_multitaper

    power_mt = tfr_multitaper(
        epochs,
        freqs=freqs,
        n_cycles=n_cycles,
        time_bandwidth=4.0,
        return_itc=False,
        average=True
    )
    power_mt.plot(['Oz'], baseline=(-0.5, 0), mode='logratio', title='Multitaper TFR - Oz')
    ```

=== ":lang-r: R"

    ```r
    tfr_stft <- compute_stft_tfr(
      epochs,
      window_size = 0.5,   # seconds
      step        = 0.05
    )
    plot_tfr(tfr_stft, channel = "Oz")
    ```

=== ":lang-matlab: Matlab"

    ```matlab
    cfg        = [];
    cfg.method = 'mtmconvol';
    cfg.foi    = 4:1:50;
    cfg.t_ftimwin = ones(length(cfg.foi), 1) * 0.5;
    cfg.tapsmofrq = 2 * ones(length(cfg.foi), 1);
    cfg.toi    = -0.5:0.05:1.5;
    cfg.output = 'pow';
    cfg.keeptrials = 'no';

    TFR = ft_freqanalysis(cfg, data);
    ft_singleplotTFR([], TFR);
    ```

---

## 4. Save Results

=== ":lang-python: Python"

    ```python
    power.save('outputs/results/tfr_morlet-tfr.h5', overwrite=True)
    power.plot_topo(baseline=(-0.5, 0), mode='logratio')
    plt.savefig('outputs/figures/tfr_topo.png', dpi=150)
    ```

=== ":lang-r: R"

    ```r
    saveRDS(tfr, "outputs/results/tfr_morlet.rds")
    ggsave("outputs/figures/tfr_topo.png", plot_tfr_topo(tfr), dpi = 150)
    ```

=== ":lang-matlab: Matlab"

    ```matlab
    save('outputs/results/tfr_morlet.mat', 'TFR');
    saveas(gcf, 'outputs/figures/tfr_topo.png');
    ```

---

!!! note "Next step"
    Continue to [Tutorial 03 · ERSP](03_ersp.md) to compute Event-Related Spectral Perturbation from the TFR results.
