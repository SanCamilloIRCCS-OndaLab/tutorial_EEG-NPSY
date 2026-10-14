# Generated from CaseStudy_1.ipynb - edit the notebook, not this file.
# Same code as the notebook, as a plain script (no Jupyter required).

import matplotlib
matplotlib.use("Agg")  # run headlessly: save figures to disk instead of popping up windows

# # Case Study 1 — Analytical strategy based on reduced EEG features
#
# This case study implements the analysis described in Section 4.1 of the
# companion paper.
#
# The research question is:
#
# > *Are the amplitude and latency of specific ERP components associated with neuropsychological performance and demographic characteristics in post-stroke patients?*
#
# Two well-characterised ERP components are used:
# - **N400** — a negative deflection ~400 ms post-stimulus, indexing semantice
#   processing (Kutas & Federmeier, 2011)
# - **P300** — a positive deflection ~300 ms post-target, indexing attentional
#   resource allocation (Polich, 2007)
#
# From each component we consider **amplitude** (mean µV within a predefined
# time window) and **latency** (ms of peak amplitude), yielding four
# participant-level neural predictors.
#
# As it usually happens in real life, data are delivered in two different files: `dataset_NPSY.csv` and `dataset_ERP.csv`.
#
#
# ## Pipeline
#
# 1. **Data Wrangling** — load, inspect, check ranges, missing data, distributions,
#    outliers, multicollinearity
# 2. **Analysis** — descriptive stats, bivariate correlations, multiple regression,
#    diagnostics, multiple comparison correction
# 3. **Export** — save tables and figures
#
# > All code is defined directly here for transparency and
# > reproducibility. Each step is explained as we go.
#

# ## 0. Setup
#
# Import the libraries we will use throughout the analysis.

# System library
from pathlib import Path
# Standard numeric libraries
import numpy as np
import pandas as pd
# Statistical libraries
from scipy.stats import pearsonr, shapiro, zscore, chi2
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.stats.outliers_influence import variance_inflation_factor
from statsmodels.stats.multitest import multipletests
from statsmodels.tools.tools import add_constant
# Plot library
import seaborn as sns
import matplotlib.pyplot as plt

# Define input/output folders

# Input
DATA_DIR = Path("../../data")
NPSY_CSV = DATA_DIR / "dataset_NPSY.csv"
EEG_CSV = DATA_DIR / "dataset_ERP.csv"
# Output
OUTPUTS = Path("CaseStudy_1") / "outputs"
FIGS    = OUTPUTS / "figures"
RESULTS = OUTPUTS / "results"
# Create output folders if they do not exist
FIGS.mkdir(parents=True, exist_ok=True)
RESULTS.mkdir(parents=True, exist_ok=True)

# ---
# ## 1. Data Wrangling

# ### 1.1 Load data
#
# The datasets are stored as separate CSV files linked by `subject_id`.

npsy = pd.read_csv(NPSY_CSV)
eeg  = pd.read_csv(EEG_CSV)
print(f"NPSY: {npsy.shape}  columns: {list(npsy.columns)}")
print(f"EEG:  {eeg.shape}  columns: {list(eeg.columns)}")

# Let's inspect the datasets looking at the first rows: each row stores the NPSY/EEG data of a single subject.

print("NPSY")
print(npsy.head())
print("EEG")
print(eeg.head())

# To create a single dataset we need to merge on `subject_id` the data collected for each subject

df = pd.merge(npsy, eeg, on="subject_id", how="inner")
print(f"Merged: {df.shape[0]} subjects × {df.shape[1]} variables")
print(df.head())

# ### 1.2 Initial inspection
#
# We check dataset dimensions, column types, and basic descriptive statistics.
#
# **Expected clinical ranges:**
#
# | Variable           | Expected range  |
# |--------------------|-----------------|
# | Age                | 18–100 years    |
# | CRIq               | 70–130          |
# | N400 amplitude     | 1–6 µV          |
# | N400 latency       | 350–500 ms      |
# | P300 amplitude     | 5–20 µV         |
# | P300 latency       | 300–500 ms      |
# | APACS              | 0–1             |
# | Attentive Matrices | 0–60            |
# | MoCA               | 0–30            |
#

print(f"Shape: {df.shape[0]} rows × {df.shape[1]} columns\n")
print(f"\nFirst 5 rows:")
print(df.head().to_string())
print(f"\nDescriptive statistics:")
print(df.describe())

# From the automatic pandas description we see that all parameters are within the expected ranges.
#
# However looking at each variable is not the most suitable way to validate data: we can perform a simple automatic check on the allowed ranges.

# Range check — flag values outside expected physiological limits
ranges = {
    "age":      (18, 100),
    "criq":     (70, 130),
    "n400_amp": (0.5, 8),
    "n400_lat": (300, 550),
    "p300_amp": (3, 25),
    "p300_lat": (250, 550),
    "apacs":    (0, 1),
    "att_matr": (0, 60),
    "moca":     (0, 30),
}
print("Range checks:")
any_warn = False
# Loop over all the variables
for col, (lo, hi) in ranges.items():
    if col not in df.columns: continue
    # Check if there is any value outside the defined range
    below = (df[col].dropna() < lo).sum()
    above = (df[col].dropna() > hi).sum()
    if below: print(f"  ⚠ {col}: {below} values below {lo}"); any_warn = True
    if above: print(f"  ⚠ {col}: {above} values above {hi}"); any_warn = True
if not any_warn:
    print("  All values within expected ranges.")

# ### 1.3 Missing data
#
# Missing data are common in clinical neuropsychological datasets — they can
# arise from fatigue, incomplete testing, or participant dropout. Strategies
# include:
#
# - **Listwise deletion** (exclude participants with any missing value) —
#   simple, but reduces sample size and may bias estimates if data are not
#   missing completely at random (MCAR).
# - **Multiple imputation** (e.g., MICE) — preserves sample size and is
#   valid under the weaker assumption of missing at random (MAR). Generally
#   preferred in clinical samples.
#
# Our synthetic dataset has complete data for all 40 participants, so no
# imputation is needed here. The code below would work with either scenario.
#
# Visual inspection of missing data patterns:

fig_missing, ax = plt.subplots(figsize=(10, 3))
if df.isnull().sum().sum() == 0:
    ax.text(0.5, 0.5, "No missing data", ha="center", va="center",
            transform=ax.transAxes, fontsize=14)
else:
    sns.heatmap(df.isnull(), cbar=False, yticklabels=False, cmap="viridis", ax=ax)
ax.set_title("Missing data matrix")
plt.show()

print(f"{'Variable':<25} {'Missing':>8} {'Rate':>8}")
print("-" * 43)
for col in df.columns:
    n_miss = df[col].isnull().sum()
    print(f"{col:<25} {n_miss:>8} {n_miss/len(df)*100:>7.1f}%")

# > **What do we see in the plot?**
# >
# > Each row is a participant, each column a variable; a highlighted cell
# > would mark a missing value. Here the matrix is empty and the
# > per-column rates above all read 0% — this synthetic dataset has no
# > missing data by construction, so there's nothing to impute or
# > exclude. In a real dataset, scattered missingness would support
# > listwise deletion; missingness concentrated in specific participants
# > or variables would be a reason to consider imputation instead.

# ### 1.4 Distribution check
#
# More than just plotting the data we can already perform a quality check by looking at the Q-Q plots, and running the Shapiro-Wilk normality test. This guides later decisions about
# transformations and correlation methods.
#

vars = ["age", "sex", "criq", "apacs", "att_matr", "moca", "n400_amp", "n400_lat", "p300_amp", "p300_lat"]
fig_dist, axes = plt.subplots(2*2, 5, figsize=(20,16))

for i, col in enumerate(vars):
    v = df[col].dropna()
    # histogram
    ax = axes[int(i/5)*2, i%5]
    ax.hist(v, bins="auto", edgecolor="white", alpha=0.7)
    ax.axvline(v.mean(), color="C3", ls="--", label=f"Mean={v.mean():.2f}")
    ax.axvline(v.median(), color="C2", ls=":", label=f"Median={v.median():.2f}")
    ax.set_title(f"{col} (n={len(v)})")
    ax.set_xlabel(col); ax.set_ylabel("Frequency"); ax.legend(fontsize=10)
    # Q-Q
    ax = axes[int(i/5)*2+1, i%5]
    sm.qqplot(v, line="s", ax=ax)
    ax.set_title("Q-Q plot")
plt.tight_layout()
plt.show()

# > **What do we see in the plot?**
# >
# > ***Histogram*** — a roughly symmetric, bell-shaped curve suggests normality. Strong skewness (long tail to one side) or a U-shape would be a warning sign.
# >
# > ***Q-Q plot*** — points should fall along the diagonal line if the data are normally distributed. Key departures:
# >
# > *Both ends curve away from the line* → heavy tails (more extreme values than a normal distribution would predict)
# >
# > *S-shaped curve* → skewed distribution (left-skewed if the curve goes below then above the line; right-skewed if the reverse)
# >
# > *Points deviating in the middle only* → unusual peakedness (kurtosis)

print("Normality tests (Shapiro-Wilk):")
for col in vars:
    v = df[col].dropna()
    if len(v) < 3: continue
    s, p = shapiro(v)
    print(f"  {col}: n={len(v)}, mean={v.mean():.2f}, SD={v.std():.2f}, "
          f"W={s:.4f}, p={p:.4f}, skew={v.skew():.3f}, kurt={v.kurtosis():.3f}")

# **Interpretation:** all Shapiro-Wilk tests are non-significant (p > 0.05) and skewness values are well below |0.6|, so the variables are approximately normal. Minor scatter in the Q-Q plots is expected with n = 40 and does not indicate a problem.

# ### 1.5 Outlier detection
#
# Flag values beyond ±3 standard deviations. We inspect flagged cases and note
# whether they are data-entry errors or genuine extremes.

out_mask = pd.DataFrame(False, index=df.index, columns=vars)
for col in vars:
    if col not in df.columns: continue
    v = df[col].dropna()
    if len(v) < 3: continue
    outliers = np.abs(zscore(v, nan_policy="omit")) > 3
    out_mask.loc[v.index[outliers], col] = True

print("Outliers (±3 SD):")
found = False
for col in out_mask.columns:
    flagged = out_mask.index[out_mask[col]].tolist()
    if flagged:
        found = True
        print(f"  {col}: rows {flagged}")
        for idx in flagged:
            print(f"    row {idx}: {col} = {df.loc[idx, col]}")
if not found:
    print("  None detected.")

# **Decision rule:** If clinically suspicious outliers exist, we run the
# analysis with and without them as a sensitivity check and report both.

# ---
# ## 2. Analysis

# ### 2.1 Descriptive statistics (Table 1)
#
# We describe each variable by looking at its mean, standard deviation, and range of values

table1_rows = []
for col in vars:
    v = df[col].dropna()
    table1_rows.append({
        "Variable": col, "n": len(v),
        "Value": f"{v.mean():.2f} ± {v.std():.2f}",
        "Range": f"[{v.min():.2f}, {v.max():.2f}]",
    })

table1 = pd.DataFrame(table1_rows)
print(table1)

# ### 2.2 Bivariate correlations (ERP × NPSY)
#
# We compute Pearson correlations between all the variables, but the interesting values are the ones between the ERP features and the
# neuropsychological outcomes. The heatmap shows r values with significance
# stars (* p<0.05, ** p<0.01, *** p<0.001).

n_vars = len(vars)
valid = df[vars].dropna()

corr_mat = np.zeros((n_vars, n_vars))
p_mat    = np.ones((n_vars, n_vars))
for i, c1 in enumerate(vars):
    for j, c2 in enumerate(vars):
        if i == j:
            corr_mat[i, j] = 1.0
            p_mat[i, j] = 1.0
        else:
            r, p = pearsonr(valid[c1], valid[c2])
            corr_mat[i, j] = r
            p_mat[i, j] = p

star = np.full((n_vars, n_vars), "", dtype=object)
star[p_mat < 0.05]  = "*"
star[p_mat < 0.01]  = "**"
star[p_mat < 0.001] = "***"
annot = np.array([f"{corr_mat[i,j]:.3f}\n{star[i,j]}"
                  for i in range(n_vars) for j in range(n_vars)]).reshape(n_vars, n_vars)

fig_corr, ax = plt.subplots(figsize=(9, 7))
mask = np.triu(np.ones_like(corr_mat, dtype=bool), k=1)
sns.heatmap(corr_mat, mask=mask, annot=annot, fmt="", cmap="RdBu_r",
            vmin=-1, vmax=1, center=0, square=True, ax=ax,
            yticklabels=[v for v in vars],
            xticklabels=[v for v in vars],
            cbar_kws={"shrink": 0.8})
ax.set_title("Pearson correlations  (* p<0.05, ** p<0.01, *** p<0.001)")
plt.tight_layout()
plt.show()

# > **What do we see in the plot?**
# >
# > Each cell shows the Pearson correlation coefficient (*r*) between a pair of variables. Colours indicate direction: red = positive, blue = negative. Intensity reflects strength (closer to ±1 = stronger).
# >
# > ***Pearson correlation*** - Values range from −1 (perfect negative) to +1 (perfect positive). A value near 0 means no linear relationship.
# >
# > ***Significance*** - Stars indicate whether the correlation is statistically significant: * p<0.05, ** p<0.01, *** p<0.001. The lower the p-value, the stronger the evidence that the correlation is not due to chance.

# #### Key hypothesised associations
#
# Based on the literature, we focus on two key pairs and generate scatter plots
# with regression lines and 95 % confidence bands.

pairs = [("p300_amp", "att_matr"), ("n400_lat", "apacs")]

fig_scatter, axes = plt.subplots(1, 2, figsize=(12, 5))
if len(pairs) == 1:
    axes = [axes]
for ax, (x_name, y_name) in zip(axes, pairs):
    v = df[[x_name, y_name]].dropna()
    sns.regplot(data=v, x=x_name, y=y_name, ax=ax,
                scatter_kws={"alpha": 0.6, "edgecolor": "white"},
                line_kws={"color": "#00796B"})
    r, p = pearsonr(v[x_name], v[y_name])
    ax.set_title(f"{x_name} vs {y_name}   r={r:.3f}, p={p:.4f}")
    ax.set_xlabel(x_name)
    ax.set_ylabel(y_name)
plt.tight_layout()
plt.show()

# > **What do we see in the plot?**
# >
# > Each dot shows the values of one participant.
# >
# > The **regression line** shows the best-fit linear relationship — upward slope = positive association, flat = none.
# >
# > The **shaded band** is the 95 % confidence interval: narrower = more precise estimate, wider = more uncertainty (typically at the extremes). If the band includes a horizontal line, the slope may not be significant.
# >
# > The **r** value (Pearson correlation coefficient) quantifies strength (−1 to +1); **p** tests whether it is significantly different from zero.

# ### 2.3 General linear models
#
# We fit three models, each with a different structure. This reflects the
# reality of clinical research: sometimes we have a clear theoretical
# prediction, sometimes we explore, and sometimes we learn from our mistakes
# and simplify.
#
# ---

# #### APACS - A theory-driven model
#
# Descrizione di modello teorico per APACS
#
# *APACS ~ N400_lat + N400_amp + Age*
#

mod_apacs_formula = "apacs ~ n400_lat + n400_amp + age"

mod_apacs = smf.glm(formula=mod_apacs_formula, data=df, family=sm.families.Gaussian()).fit() 

print(mod_apacs.summary())

# #### Attentive Matrices - A model with no a priori knowledge
#
# Now we want to build a model for attentive matrices.
#
# As known by the theory, and also shown in the previous correlation plot, attentive matrices are correlated to P300, education (CRIq), and age.
#
# But our dataset includes much more variables, therefore one idea could be *bigger is better: let's put everything together*
#
# So we can try to fit a kitchen-sink model using all the data as covariates: *AttentiveMatrices ~ P300_lat + P300_amp + N400_lat + N400_amp + Age + Sex + CRIq*
#
# We fit this model only to see what happens when theory is ignored and every available variable is thrown in — not to use its p-values to decide afterwards which variables to keep (see below).

mod_att_matr_full_formula = "att_matr ~ p300_lat + p300_amp + n400_lat + n400_amp + age + sex + criq"

mod_att_matr_full = smf.glm(formula=mod_att_matr_full_formula, data=df, family=sm.families.Gaussian()).fit() 

print(mod_att_matr_full.summary())

# #### Attentive Matrices - A theory-guided, parsimonious model
#
# The kitchen-sink model above shows the cost of ignoring theory: several
# predictors are far from significant, and entering redundant or
# theoretically unmotivated variables inflates standard errors and
# destabilises the coefficients.
#
# Importantly, we do **not** decide which variables to keep by looking at
# *these* p-values — that would be post-hoc pruning, a form of circular
# reasoning: the same data would first be searched to select the model and
# then reused to test it, inflating the apparent evidence for whatever
# survives. Instead we go back to theory and to the earlier bivariate
# analysis (Section 2.2): P300 amplitude, age, and CRIq are the established
# covariates for attentional performance, so those are the predictors we
# keep *a priori*. N400 amplitude/latency and P300 latency are dropped
# because there is no theoretical reason to expect them to explain attentive
# matrices performance specifically, and `sex` is dropped on the same a
# priori grounds — not because it failed to reach significance above.
#
# *Attentive Matrices ~ P300_amp + Age + CRIq*

mod_att_matr_pars_formula = "att_matr ~ p300_amp + age + criq"

mod_att_matr_pars = smf.glm(formula=mod_att_matr_pars_formula, data=df, family=sm.families.Gaussian()).fit() 

print(mod_att_matr_pars.summary())

# This theory-guided model has fewer predictors, and — as a consequence, not
# as the reason we chose them — all of them are significant and the model is
# more stable. Because the selection was made a priori rather than by
# trimming non-significant terms, the improved fit (comparable or better R²
# with fewer parameters) can be read as genuine evidence in favour of
# parsimony, rather than as an artefact of having searched the data for
# whichever subset happens to look best.

# > **Takeaway**
# >
# > More variables does not mean a better model — and *how* you choose which
# > variables to drop matters just as much as the decision to drop them.
# > Selecting predictors *after* seeing that they are not significant in a
# > bigger model is a form of post hoc pruning, which is circular: the same
# > data end up being used both to choose the model and to test it, which
# > inflates the apparent evidence for whatever predictors remain.
# >
# > Here the predictors were instead chosen **a priori**, from theory and
# > from the earlier correlation analysis (Section 2.2), before looking at
# > any p-value from the kitchen-sink model. The kitchen-sink model was fit
# > only to *illustrate* the cost of ignoring theory — inflated standard
# > errors, an unstable intercept — not to guide which variables to keep.
# > That the resulting theory-driven model also turns out to fit at least as
# > well (higher pseudo R², all coefficients significant, and a simpler,
# > more interpretable structure) is a welcome confirmation, not the
# > justification for the choice.

# ### 2.4 Assumption checking (post-hoc)
#
# Fitting a model is not the last step: linear regression relies on a few
# assumptions, and good practice is to check them **after** fitting, before
# trusting the coefficients. We do this here for the final, parsimonious
# Attentive Matrices model (`att_matr ~ p300_amp + age + criq`).
#
# - **Linearity & homoscedasticity** — residuals plotted against fitted values
#   should scatter randomly around zero, with no funnel shape or curve.
# - **Normality of residuals** — a Q-Q plot of the residuals should follow the
#   diagonal (same logic as the Q-Q plots in Section 1.4, now applied to the
#   model's errors instead of the raw variables).
# - **Influential observations** — Cook's distance flags participants who, on
#   their own, pull the fitted model strongly in one direction. A common rule
#   of thumb is to inspect points above 4/n.
# - **Multicollinearity** — the Variance Inflation Factor (VIF) quantifies how
#   much a predictor's variance is inflated by correlation with the other
#   predictors. VIF > 5 is a moderate concern, VIF > 10 is severe (see
#   Section 1.6 of the pipeline). The intercept is excluded from the VIF
#   table/plot below, since its VIF is a statistical artefact with no
#   interpretation as a collinearity check.

mod = mod_att_matr_pars
predictors = ["p300_amp", "age", "criq"]

fitted = mod.fittedvalues
resid  = mod.resid_response
n      = int(mod.nobs)

fig_diag, axes = plt.subplots(2, 2, figsize=(11, 9))

# Residuals vs fitted
axes[0, 0].scatter(fitted, resid, alpha=0.6, edgecolor="white")
axes[0, 0].axhline(0, color="gray", ls="--")
axes[0, 0].set_xlabel("Fitted values")
axes[0, 0].set_ylabel("Residuals")
axes[0, 0].set_title("Residuals vs Fitted")

# Q-Q plot of residuals
sm.qqplot(resid, line="s", ax=axes[0, 1])
axes[0, 1].set_title("Q-Q plot (residuals)")

# Cook's distance
influence = mod.get_influence()
cooks = influence.cooks_distance[0]
axes[1, 0].stem(range(n), cooks, basefmt=" ")
axes[1, 0].axhline(4 / n, color="C3", ls="--", label=f"4/n = {4/n:.3f}")
axes[1, 0].set_xlabel("Participant (row index)")
axes[1, 0].set_ylabel("Cook's distance")
axes[1, 0].set_title("Cook's Distance")
axes[1, 0].legend()

# Variance Inflation Factor (intercept excluded: its VIF is not meaningful
# and is typically orders of magnitude larger than the predictors' values)
X_vif = add_constant(df[predictors])
vif_table = pd.DataFrame({
    "predictor": X_vif.columns,
    "VIF": [variance_inflation_factor(X_vif.values, i) for i in range(X_vif.shape[1])],
})
vif_table = vif_table[vif_table["predictor"] != "const"].reset_index(drop=True)
axes[1, 1].barh(vif_table["predictor"], vif_table["VIF"], color="steelblue")
axes[1, 1].axvline(5, color="orange", ls="--", label="VIF=5")
axes[1, 1].axvline(10, color="C3", ls="--", label="VIF=10")
axes[1, 1].set_xlabel("VIF")
axes[1, 1].set_title("Variance Inflation Factor")
axes[1, 1].legend()

plt.tight_layout()
plt.show()

print(vif_table.to_string(index=False))
n_influential = int((cooks > 4 / n).sum())
print(f"\nParticipants above the 4/n Cook's distance threshold: {n_influential} (max Cook's D = {cooks.max():.3f})")

# > **What do we see in the plot?**
# >
# > ***Residuals vs Fitted*** — no funnel shape or curve should be visible; a
# > random scatter around zero supports linearity and constant variance
# > (homoscedasticity).
# >
# > ***Q-Q plot (residuals)*** — points should lie close to the diagonal;
# > systematic curvature would suggest non-normal errors.
# >
# > ***Cook's distance*** — a handful of points above the 4/n line is not
# > unusual with n = 40 and, on its own, is not a red flag: what matters is
# > whether any point stands out with a much larger value than the rest (a
# > useful check is to refit the model without that participant and see
# > whether the coefficients change materially).
# >
# > ***VIF*** — values close to 1 mean each predictor carries mostly
# > independent information; here `p300_amp`, `age`, and `criq` all sit well
# > below the VIF = 5 caution threshold, so multicollinearity is not a
# > concern for this model.
#
# **Interpretation:** for the parsimonious Attentive Matrices model, the
# diagnostics are reassuring — residuals show no obvious pattern, the Q-Q
# plot is close to the diagonal, no participant has a disproportionately
# large Cook's distance, and VIF values are low. This supports treating the
# model's coefficients (Section 2.3) at face value.

# ---
# ## 3. Export
#
# We now save the results that matter most for a clinical audience: the key
# **figures** (as PNG images, ready to paste into a report or a slide) and
# the key **tables** (as both `.csv` — universal, opens anywhere — and
# `.xlsx` — a single Excel workbook with one sheet per table, easier to
# browse for those who are not used to statistical software).
#
# Nothing here is recomputed: we simply save the figures and tables already
# produced above.

# ### 3.1 Figures
#
# We save the figures produced earlier, one PNG per figure.

figures_to_save = {
    "A_missingness.png":               fig_missing,
    "B_distributions.png":             fig_dist,
    "C_correlations.png":              fig_corr,
    "D_key_associations.png":          fig_scatter,
    "E_diagnostics_attentive_matrices.png": fig_diag,
}

for filename, fig in figures_to_save.items():
    path = FIGS / filename
    fig.savefig(path, dpi=150, bbox_inches="tight")
    print(f"Saved: {path}")

# ### 3.2 Tables
#
# We export four tables:
#
# 1. **Descriptive statistics** (`table1`, already built in Section 2.1)
# 2. **Bivariate correlations** — every pair of variables, one row per pair
#    (long/tidy format, easier to filter and sort in Excel than a matrix)
# 3. **Regression results** — coefficients, standard errors, p-values and
#    95% CI for all three models (APACS, and both Attentive Matrices models)
# 4. **Multicollinearity check (VIF)** — for the parsimonious Attentive
#    Matrices model (Section 2.4)
#
# Each table gets a `Significant (p<0.05)` column so it is immediately clear,
# without reading p-values, which associations/predictors reach conventional
# significance.

# Table 2 — bivariate correlations, one row per unique pair of variables
corr_rows = []
for i in range(n_vars):
    for j in range(i + 1, n_vars):
        corr_rows.append({
            "Variable 1": vars[i],
            "Variable 2": vars[j],
            "r": corr_mat[i, j],
            "p-value": p_mat[i, j],
            "Significant (p<0.05)": p_mat[i, j] < 0.05,
        })
table2_correlations = pd.DataFrame(corr_rows)
print(table2_correlations.head())

# Table 3 — regression coefficients for all three fitted models
def model_to_table(model, outcome_label):
    ci = model.conf_int()
    ci.columns = ["CI_lower", "CI_upper"]
    out = pd.DataFrame({
        "Predictor":   model.params.index,
        "Estimate":    model.params.values,
        "Std. Error":  model.bse.values,
        "p-value":     model.pvalues.values,
    }).set_index("Predictor").join(ci)
    out.insert(0, "Outcome", outcome_label)
    out["Significant (p<0.05)"] = out["p-value"] < 0.05
    return out.reset_index()

table3_regression = pd.concat([
    model_to_table(mod_apacs, "APACS (theory-driven)"),
    model_to_table(mod_att_matr_full, "Attentive Matrices (kitchen-sink)"),
    model_to_table(mod_att_matr_pars, "Attentive Matrices (parsimonious)"),
], ignore_index=True)
print(table3_regression)

# Table 4 — VIF table computed in Section 2.4 (Attentive Matrices, parsimonious model)
table4_vif = vif_table.rename(columns={"predictor": "Predictor"})
print(table4_vif)

tables_to_save = {
    "table1_descriptives.csv":  table1,
    "table2_correlations.csv":  table2_correlations,
    "table3_regression.csv":    table3_regression,
    "table4_vif.csv":           table4_vif,
}

# Save each table as its own CSV ...
for filename, table in tables_to_save.items():
    path = RESULTS / filename
    table.to_csv(path, index=False)
    print(f"Saved: {path}")

# ... and all four together as a single Excel workbook, one sheet per table
xlsx_path = RESULTS / "CaseStudy_1_results.xlsx"
with pd.ExcelWriter(xlsx_path) as writer:
    table1.to_excel(writer, sheet_name="Descriptives", index=False)
    table2_correlations.to_excel(writer, sheet_name="Correlations", index=False)
    table3_regression.to_excel(writer, sheet_name="Regression", index=False)
    table4_vif.to_excel(writer, sheet_name="VIF", index=False)
print(f"Saved: {xlsx_path}")

# ---
# ## 4. Strengths and limitations of this approach (Section 4.2.3)
#
# **Strengths:**
# - Reduces high-dimensional EEG to **4 interpretable scalar features** per
#   participant — theoretically grounded, easy to communicate
# - Uses **well-established statistical models** (OLS regression) familiar to
#   clinical researchers
# - The N400 and P300 have **decades of validation** across neurological
#   populations (Kutas & Federmeier, 2011; Polich, 2007)
#
# **Limitations:**
# - Strong **a priori decisions** about time windows and electrode sets may
#   miss atypical or distributed neural patterns — especially relevant in
#   stroke patients whose ERP topography may differ from normative expectations
# - **Trial-to-trial variability** is discarded (only mean amplitude and peak
#   latency are kept), which may itself carry clinically relevant information
# - The **hypothesis-driven** nature of the approach means it will not detect
#   effects outside the predefined features — for broader exploration, see
#   Case Study 2 (spectral analysis)
#
# > For a full discussion, see Section 4.2 of the companion paper.
#
# ---
#
# *Generated for the EEG-NPSY tutorial. All code is self-contained
# for transparency and reproducibility.*
