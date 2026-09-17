# Case Study 2 · Spectral features and mass-univariate statistics

!!! warning "Coming soon"
    This case study is not implemented yet — this page describes the
    planned scope. In the meantime, see
    [Case Study 1](case_study_1.md) for a complete, ready-to-run example.

## Research question

Where [Case Study 1](case_study_1.md) reduces the EEG signal to four
theory-driven scalar features, Case Study 2 takes the opposite,
**exploratory** approach: it keeps the full spectral resolution of the
signal (power at every electrode and every frequency bin) and asks broadly
where, across electrodes and frequencies, EEG power relates to
neuropsychological performance — without committing in advance to a
specific band or region.

## Planned pipeline

1. **Data wrangling** — power spectral density (PSD) per participant,
   electrode and frequency bin (e.g. 256 electrodes × 78 frequency bins,
   1–40 Hz), merged with the same neuropsychological/demographic variables
   as Case Study 1
2. **Mass-univariate analysis** — one statistical test per
   electrode/frequency point relating EEG power to each neuropsychological
   outcome
3. **Cluster-based correction** — non-parametric, cluster-based permutation
   testing to control the false-positive rate that mass-univariate testing
   would otherwise inflate
4. **Visualisation** — topographic/spectral maps of the resulting clusters,
   to make an inherently harder-to-interpret result communicable

## Why this approach, and its trade-offs

Keeping the full spatial and spectral resolution of the signal means an
effect is far less likely to be missed simply because it falls outside a
predefined time window or electrode set — the opposite risk from Case
Study 1. The cost is interpretability: results take the form of statistical
maps rather than a handful of named coefficients, and the number of
simultaneous tests requires careful correction (Section 5.1 of the
companion paper) to avoid spurious findings.
