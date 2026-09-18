# Case Studies

The case studies are worked examples of a common clinical research question:
**how do EEG/ERP measures relate to neuropsychological performance and
demographic characteristics?** Each one follows a full pipeline — data
wrangling, descriptive statistics, association analysis, modelling and
diagnostics, export. Case Study 1 runs entirely on a synthetic (mock)
dataset; Case Study 2 combines real, anonymised EEG recordings with a
synthetic neuropsychological table (each case study page discloses
exactly what is real and what is not) — either way, you can run every
step yourself without needing your own patient data.

They are written for **clinicians and researchers with little to no prior
experience in statistical analysis**: every plot and every model is
accompanied by a plain-language explanation of what to look for and why it
matters, not just the code that produces it.

<div class="grid cards" markdown>

-   :material-chart-bell-curve:{ .lg .middle } **Case Study 1 · ERP & Neuropsychology**

    ---

    A hypothesis-driven approach: two well-characterised ERP components
    (N400, P300) are reduced to four scalar features per participant and
    related to neuropsychological scores via linear regression.

    [:octicons-arrow-right-24: Read the case study](case_study_1.md)

-   :material-view-grid-outline:{ .lg .middle } **Case Study 2 · Spectral Features**

    ---

    A more exploratory approach: mass-univariate and cluster-based
    statistics applied to real, whole-scalp spectral EEG data, trading
    interpretability for sensitivity to distributed or atypical effects.

    [:octicons-arrow-right-24: Read the case study](case_study_2.md)

</div>

---

## Which approach should I use?

The two case studies illustrate opposite ends of the same trade-off:

| | Case Study 1 | Case Study 2 |
|---|---|---|
| **Strategy** | Reduce the EEG signal to a handful of theory-driven features | Keep (most of) the signal's dimensionality and test broadly |
| **Best when** | You have a specific, literature-backed hypothesis | You don't know where/when an effect might be, or want to check broadly |
| **Strengths** | Easy to interpret and communicate; well-established models | Can detect effects the a-priori features would miss |
| **Risks** | Misses effects outside the chosen time windows/electrodes | Harder to interpret; needs careful multiple-comparison control |

Both are legitimate — the right choice depends on your research question,
not on which one is "more advanced".
