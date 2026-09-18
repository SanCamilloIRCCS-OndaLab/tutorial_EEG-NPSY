# CASE STUDY 2 — FULL PIPELINE

## 0. IMPORT

```
import libraries:
    - data handling:        pandas, numpy
    - EEG / spectral:       mne (Python), fieldtrip (MATLAB),
                            eeglab (MATLAB)
    - statistics:           scipy, mne.stats, permuco (R)
    - visualisation:        matplotlib, seaborn, mne.viz
    - R (alternative):      tidyverse, ggplot2, permuco

eeg_data  = load_dataset(eeg_data_path)
    # expected format: participants × electrodes × frequency_bins
    # shape: [n_participants, n_electrodes, n_freqs]
    # frequency resolution: e.g. 0.5 Hz bins from 1 to 40 Hz → 78 bins

npsy_data = load_dataset(npsy_data_path)
    # same as Case Study 1
    # columns: subject_id,
    #          age, sex, education, handedness,
    #          lesion_site, stroke_aetiology, time_onset,
    #          MoCA, CRIq, APACS,
    #          matrici_attentive, OCS

# note: EEG data here are already in PSD format
# (computed during preprocessing, e.g. via Welch's method)
# no further spectral decomposition needed at this stage
```

## 1. DATA WRANGLING

### 1.1 INITIAL INSPECTION

```
print(eeg_data.shape)
    # expected: [n_participants, n_electrodes, n_freqs]
    # e.g.    : [45, 256, 78]

print(npsy_data.shape)
    # expected: [n_participants, n_variables]

# check electrode labels match expected montage
assert electrode_labels == expected_montage_labels

# check frequency axis
print(freq_axis)            # e.g. [1.0, 1.5, 2.0, ..., 40.0]
print(freq_resolution)      # e.g. 0.5 Hz

# check for participants with flat or implausible PSD
for each participant:
    plot PSD averaged across electrodes
    flag if: total power < lower_bound OR > upper_bound
             OR power at 50 Hz spike > threshold  # line noise
             OR flat spectrum (variance < epsilon)
```

### 1.2 MISSING DATA (NEUROPSYCHOLOGICAL SCORES)

```
# same procedure as Case Study 1 (Section 1.3 above)
# additionally: check if any participant has EEG data but missing npsy scores
#               or vice versa

missing_eeg  = participants in npsy_data but not in eeg_data
missing_npsy = participants in eeg_data but not in npsy_data

print("Participants with EEG but no npsy data:", missing_npsy)
print("Participants with npsy but no EEG data:", missing_eeg)
```

### 1.3 DISTRIBUTION CHECK (NEUROPSYCHOLOGICAL SCORES)

```
# same procedure as Case Study 1 (Section 1.4 above)
# additionally: inspect PSD distributions at selected frequencies

for each frequency_bin in [representative sample, e.g. 1,4,8,13,20,30 Hz]:
    for each electrode in [representative sample, e.g. Fz, Cz, Pz, Oz]:
        plot histogram(eeg_data_log[:, electrode, freq_bin])
        shapiro_wilk_test(eeg_data_log[:, electrode, freq_bin])
        # note: formal normality testing not required for permutation tests
        #       (which are non-parametric) but useful for diagnostics
```

### 1.4 COVARIATE PREPARATION

```
# same as Case Study 1 (Section 1.2):
# dummy-code categorical variables
# check for collinearity among covariates

# additionally: decide which covariates to include in mass-univariate models
# options:
#   a) regress out covariates from PSD before permutation testing
#      (residualisation approach)
#   b) include covariates directly in the permutation test statistic
#      (if software supports GLM-based permutation)

IF residualisation approach:
    for each electrode, for each frequency_bin:
        residuals[:,electrode,freq] = linear_regression(
            eeg_data_log[:,electrode,freq] ~ age + sex + education + time_onset
        ).residuals
    eeg_data_residualised = residuals
    # shape unchanged: [n_participants, n_electrodes, n_freqs]
```

### 1.5 FINAL DATASET CHECK

```
print("Final N:", n_complete)
print("EEG data shape:", eeg_data_log.shape)
    # or eeg_data_residualised.shape if residualisation applied
print("Neuropsychological variables:", list(npsy_vars))
print("Missing values (npsy):", npsy_data.isnull().sum())

save_dataset(eeg_data_log,    "CS2_eeg_log_psd.npy / .mat")
save_dataset(npsy_data_clean, "CS2_npsy_clean.csv")
```

## 2. ANALYSIS

### 2.1 DESCRIPTIVE STATISTICS

```
# same as Case Study 1 (Section 2.1)
```

### 2.2 MASS-UNIVARIATE CORRELATION

```
# for each neuropsychological outcome:
# compute correlation between npsy_score and log-PSD
# at every electrode × frequency bin combination

for each outcome in [MoCA, CRIq, APACS, matrici_attentive, OCS]:

    # compute test statistic at each point
    for each electrode (i = 1 to n_electrodes):
        for each frequency_bin (j = 1 to n_freqs):
            r[i,j], p[i,j] = spearman_correlation(
                                eeg_data_log[:,i,j],
                                npsy_scores[:,outcome])
            # or pearson if both variables are normally distributed
            # result: r_map and p_map of shape [n_electrodes, n_freqs]

    # visualise uncorrected results
    plot_topomap_per_freq(r_map)    # one topomap per frequency bin
    plot_electrode_x_freq(r_map)    # 2D map: electrodes × frequencies
```

### 2.3 CLUSTER-BASED PERMUTATION TEST

```
# rationale: correct for multiple comparisons across electrode × frequency space
#            while respecting the spatial and spectral dependency structure

for each outcome in [MoCA, CRIq, APACS, matrici_attentive, OCS]:

    # Step 1: compute observed test statistic map (from 2.2)
    observed_r_map = r_map[outcome]         # shape: [n_electrodes, n_freqs]

    # Step 2: threshold at uncorrected p < 0.05 (or p < 0.01)
    threshold_mask = abs(observed_r_map) > critical_value(alpha=0.05)

    # Step 3: identify clusters of contiguous suprathreshold points
    clusters = find_connected_components(threshold_mask,
                                         adjacency=electrode_adjacency_matrix)
        # electrode adjacency: two electrodes are adjacent if they are
        # neighbouring on the scalp (based on 3D positions)
        # frequency adjacency: consecutive frequency bins are always adjacent

    # Step 4: compute cluster-level statistic
    for each cluster:
        cluster_stat = sum(observed_r_map[cluster])   # sum of r values in cluster

    # Step 5: build null distribution via permutation
    null_distribution = []
    for i in range(n_permutations):     # e.g. 5000 permutations
        permuted_scores = shuffle(npsy_scores[:,outcome])
        permuted_r_map  = compute_r_map(eeg_data_log, permuted_scores)
        permuted_clusters = find_connected_components(
                                abs(permuted_r_map) > critical_value(alpha=0.05),
                                adjacency=electrode_adjacency_matrix)
        if permuted_clusters is not empty:
            null_distribution.append(max(cluster_stat for permuted_clusters))
        else:
            null_distribution.append(0)

    # Step 6: compute cluster-level p-value
    for each observed cluster:
        p_cluster = mean(null_distribution >= cluster_stat[cluster])
        # significant if p_cluster < 0.05

    # Step 7: report significant clusters
    significant_clusters = [c for c in clusters if p_cluster[c] < 0.05]
    print("Significant clusters for", outcome, ":", significant_clusters)
```

## 3. PLOT AND EXPORT

### 3.1 PLOTS

```
# Figure A: grand average PSD curves at representative electrodes
#           mean ± SD across participants
# Figure B: topographic maps of mean log-power at canonical frequency bands
#           (delta, theta, alpha, beta)
# Figure C: electrode × frequency r-maps (uncorrected) for each npsy outcome
#           2D heatmap: x = frequency, y = electrode
#           colour = r value, contour = p < 0.05
# Figure D: topographic maps of significant clusters
#           for each significant cluster: topomap of r values,
#           cluster outline overlaid, frequency range annotated
# Figure E: PSD curves split by high vs low neuropsychological score
#           (median split for illustration only — not the primary analysis)
#           at electrodes within significant clusters
```

### 3.2 EXPORT

```
save_table(descriptive_stats,       "table1_descriptives.csv")
save_table(cluster_results,         "table2_clusters.csv")
    # columns: outcome, cluster_id, frequency_range,
    #          electrode_set, cluster_stat, p_cluster

save_figure(grand_avg_psd,          "figA_grand_avg_psd.pdf")
save_figure(topomap_power,          "figB_topomap_power.pdf")
save_figure(r_maps,                 "figC_r_maps.pdf")
save_figure(significant_clusters,   "figD_clusters.pdf")
save_figure(psd_by_score,           "figE_psd_by_score.pdf")

save_dataset(eeg_data_log,          "CS2_eeg_log_psd.npy / .mat")
save_dataset(npsy_data_clean,       "CS2_npsy_clean.csv")
save_script(this_script,            "CS2_analysis.py / .R / .m")
```
