# Generated from CaseStudy_1.ipynb - edit the notebook, not this file.
# Same code as the notebook, as a plain script (no Jupyter required).
# Run it from this folder, so the helper functions in R/ are found.

# # Case Study 1 — Analytical strategy based on reduced EEG features (R)
#
# This is the **R implementation** of Case Study 1. It implements the
# analysis described in Section 4.1 of the companion paper. The same
# analysis is also available as
# [Python code](../../../python/CaseStudy_1/CaseStudy_1.ipynb).
#
# The research question is:
#
# > *Are the amplitude and latency of specific ERP components associated with neuropsychological performance and demographic characteristics in post-stroke patients?*
#
# Two well-characterised ERP components are used:
# - **N400** — a negative deflection ~400 ms post-stimulus, indexing semantic
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
# ## Pipeline
#
# 1. **Data Wrangling** — load, inspect, check ranges, missing data, distributions,
#    outliers
# 2. **Analysis** — descriptive stats, bivariate correlations, multiple regression,
#    post-hoc diagnostics
# 3. **Export** — save tables and figures
#
# ## How this code is built
#
# Like almost any real analysis, this notebook combines two things:
#
# 1. **Functions from established packages** - the
#    [tidyverse](https://www.tidyverse.org/) (`readr`, `dplyr`, `tidyr`,
#    `purrr`, `stringr`, `ggplot2`) to read, reshape and plot the data,
#    `broom` to turn models into tables, `car` and `psych` for specific
#    statistics (VIF, skewness/kurtosis), `patchwork` to combine plots,
#    `openxlsx` for Excel export and `cli` for readable messages. Whatever a
#    well-tested package already does, we don't rewrite.
# 2. **A few custom functions** for the steps no package does exactly the way
#    we need (a range check against our clinical limits, a correlation
#    heatmap with significance stars, a report-ready regression table, ...).
#    They live in the [`R/`](https://github.com/SanCamilloIRCCS-OndaLab/tutorial_EEG-NPSY/tree/main/r/case1/code/R) folder next to this notebook and are loaded
#    in Setup, just as you would load a small package of your own - so the
#    notebook itself reads as the analysis, step by step.
#
# The custom functions are hidden by default, but they are not a black box:
# wherever one is first used, a collapsed cell lets you print its source code
# (or simply open the file in `R/`).
#
# > ⚠️ **Caution** - the custom functions in `R/` were written for this
# > tutorial and are not extensively tested beyond the data used here.

# ## 0. Setup
#
# Load the packages we use throughout the analysis, then our own helper
# functions from the `R/` folder.

suppressPackageStartupMessages({
  library(tidyverse)  # readr, dplyr, tidyr, purrr, stringr, ggplot2, ...
  library(broom)      # model results as tidy tibbles
  library(patchwork)  # combine ggplot panels into one figure
  library(cli)        # readable status messages
})
# car (VIF), psych (skewness/kurtosis) and openxlsx (Excel export) are only
# needed for one function each, so we call them as pkg::fun() instead of
# attaching them - that also makes it obvious where each function comes from.

theme_set(theme_minimal())

# Our own helper functions, one file per topic in the R/ folder next to this
# notebook - loaded the way you would load a small package of your own
list.files("R", pattern = "\\.R$", full.names = TRUE) %>%
  walk(~ source(.x, keep.source = TRUE))  # keep.source: printing a helper keeps its comments

# Define input/output folders

# Input
DATA_DIR <- "../../../data"
NPSY_CSV <- file.path(DATA_DIR, "dataset_NPSY.csv")
EEG_CSV  <- file.path(DATA_DIR, "dataset_ERP.csv")

# Output
OUTPUTS <- "../outputs"
FIGS    <- file.path(OUTPUTS, "figures")
RESULTS <- file.path(OUTPUTS, "results")
dir.create(FIGS, recursive = TRUE, showWarnings = FALSE)
dir.create(RESULTS, recursive = TRUE, showWarnings = FALSE)

# ---
# ## 1. Data Wrangling

# ### 1.1 Load data
#
# The datasets are stored as separate CSV files linked by `subject_id`.

npsy <- read_csv(NPSY_CSV, show_col_types = FALSE)
eeg  <- read_csv(EEG_CSV, show_col_types = FALSE)

glimpse(npsy)
glimpse(eeg)

# Let's inspect the datasets looking at the first rows: each row stores the NPSY/EEG data of a single subject.

head(npsy)
head(eeg)

# To create a single dataset we need to merge on `subject_id` the data collected for each subject

df <- inner_join(npsy, eeg, by = "subject_id")
cli_alert_info("Merged: {nrow(df)} subjects x {ncol(df)} variables")
head(df)

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

summary(df)

# From the automatic R summary we see that all parameters are within the expected ranges.
#
# However looking at each variable is not the most suitable way to validate data: we can perform a simple automatic check on the allowed ranges.

# Expected physiological/clinical limits for each variable
ranges <- tribble(
  ~variable,  ~min, ~max,
  "age",        18,  100,
  "criq",       70,  130,
  "n400_amp",  0.5,    8,
  "n400_lat",  300,  550,
  "p300_amp",    3,   25,
  "p300_lat",  250,  550,
  "apacs",       0,    1,
  "att_matr",    0,   60,
  "moca",        0,   30
)

range_check <- check_ranges(df, ranges)
range_check

if (all(range_check$ok)) {
  cli_alert_success("All values within expected ranges.")
} else {
  cli_alert_warning("Values outside the expected range in: {.val {range_check$variable[!range_check$ok]}}")
}

# Want to see how it works? Printing a function shows its source code.
# print(check_ranges)

# ### 1.3 Missing data
#
# Missing data are common in clinical neuropsychological datasets — they can
# arise from fatigue, incomplete testing, or participant dropout. Strategies
# include:
#
# - **Listwise deletion** (exclude participants with any missing value) —
#   simple, but reduces sample size and may bias estimates if data are not
#   missing completely at random (MCAR).
# - **Multiple imputation** (e.g., MICE, see the `mice` package) — preserves
#   sample size and is valid under the weaker assumption of missing at
#   random (MAR). Generally preferred in clinical samples.
#
# Our synthetic dataset has complete data for all 40 participants, so no
# imputation is needed here. The code below would work with either scenario.
#
# Visual inspection of missing data patterns:

fig_missing <- plot_missingness(df)
fig_missing

# Want to see how it works? Printing a function shows its source code.
# print(plot_missingness)

df %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  mutate(rate = scales::percent(n_missing / nrow(df), accuracy = 0.1))

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

vars <- c("age", "sex", "criq", "apacs", "att_matr", "moca", "n400_amp", "n400_lat", "p300_amp", "p300_lat")

fig_dist <- plot_distributions(df, vars)
fig_dist

# Want to see how it works? Printing a function shows its source code.
# print(plot_distributions)

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

# Shapiro-Wilk normality test, plus skewness and kurtosis, for every variable
df %>%
  select(all_of(vars)) %>%
  pivot_longer(everything(), names_to = "variable") %>%
  drop_na(value) %>%
  mutate(variable = factor(variable, levels = vars)) %>%
  group_by(variable) %>%
  summarise(
    n    = n(),
    mean = mean(value),
    sd   = sd(value),
    W    = shapiro.test(value)$statistic,
    p    = shapiro.test(value)$p.value,
    skew = psych::skew(value, type = 2),
    kurt = psych::kurtosi(value, type = 2)
  )

# **Interpretation:** all Shapiro-Wilk tests are non-significant (p > 0.05) and skewness values are well below |0.6|, so the variables are approximately normal. Minor scatter in the Q-Q plots is expected with n = 40 and does not indicate a problem.

# ### 1.5 Outlier detection
#
# Flag values beyond ±3 standard deviations. We inspect flagged cases and note
# whether they are data-entry errors or genuine extremes.

outliers <- flag_outliers_z(df, vars, threshold = 3)
outliers

# Want to see how it works? Printing a function shows its source code.
# print(flag_outliers_z)

# **Decision rule:** If clinically suspicious outliers exist, we run the
# analysis with and without them as a sensitivity check and report both.

# ### 1.6 Cleaning dataset
#
# Let's remove the missing data and the outliers.
#
# There are three outliers that are not plausible data: Age 150, N400
# Amplitude 25 uV, P300 latency 900ms. We will remove these subjects.
#
# However the value of 3 for attentive matrices is very low but it is also
# very plausible in a patient dataset, therefore we will keep this
# outlier.

# Outliers: exclude only the implausible ones found in Section 1.5 - keep
# the att_matr outlier, since it is a plausible (if low) clinical value
implausible <- outliers %>%
  filter(variable %in% c("age", "n400_amp", "p300_lat")) %>%
  pull(subject_id)

# Participants to exclude: any missing value, or an implausible outlier
excluded <- df %>%
  filter(if_any(all_of(vars), is.na) | subject_id %in% implausible)
excluded %>% select(subject_id, all_of(vars))

df <- df %>% anti_join(excluded, by = "subject_id")
cli_alert_info("Excluded {nrow(excluded)} participants - {nrow(df)} remaining.")

# ---
# ## 2. Analysis

# ### 2.1 Descriptive statistics (Table 1)
#
# We describe each variable by looking at its mean, standard deviation, and range of values

num2 <- function(x) formatC(x, format = "f", digits = 2)  # 2 decimals, e.g. "65.30"

table1 <- df %>%
  select(all_of(vars)) %>%
  pivot_longer(everything(), names_to = "Variable") %>%
  drop_na(value) %>%
  mutate(Variable = factor(Variable, levels = vars)) %>%
  group_by(Variable) %>%
  summarise(
    n     = n(),
    Value = str_c(num2(mean(value)), " ± ", num2(sd(value))),
    Range = str_c("[", num2(min(value)), ", ", num2(max(value)), "]")
  ) %>%
  mutate(Variable = as.character(Variable))
table1

# ### 2.2 Bivariate correlations (ERP × NPSY)
#
# We compute Pearson correlations between all the variables, but the interesting values are the ones between the ERP features and the
# neuropsychological outcomes. The heatmap shows r values with significance
# stars (* p<0.05, ** p<0.01, *** p<0.001).

cor_tbl <- cor_pairs(df, vars)   # one row per pair: var1, var2, r, p

fig_corr <- plot_cor_heatmap(cor_tbl, vars)
fig_corr

# Want to see how it works? Printing a function shows its source code.
# print(cor_pairs)
# print(plot_cor_heatmap)

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

fig_scatter <- plot_scatter_lm(df, "p300_amp", "att_matr") +
  plot_scatter_lm(df, "n400_lat", "apacs")
fig_scatter

# Want to see how it works? Printing a function shows its source code.
# print(plot_scatter_lm)

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

mod_apacs <- glm(apacs ~ n400_lat + n400_amp + age, data = df, family = gaussian())
summary(mod_apacs)

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

mod_att_matr_full <- glm(att_matr ~ p300_lat + p300_amp + n400_lat + n400_amp + age + sex + criq,
                          data = df, family = gaussian())
summary(mod_att_matr_full)

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

mod_att_matr_pars <- glm(att_matr ~ p300_amp + age + criq, data = df, family = gaussian())
summary(mod_att_matr_pars)

# This theory-guided model has fewer predictors, and — as a consequence, not
# as the reason we chose them — all of them are significant and the model is
# more stable. Because the selection was made a priori rather than by
# trimming non-significant terms, the improved fit (a lower AIC, despite — in fact because of — fewer parameters) can be read as genuine evidence in favour of
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
# > well (a lower AIC, all coefficients significant, and a simpler,
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
#   predictors. VIF > 5 is a moderate concern, VIF > 10 is severe. Unlike a
#   manual VIF calculation, R's `car::vif()` never includes the intercept in
#   the first place, so there is nothing to exclude here.

mod <- mod_att_matr_pars

fig_diag <- plot_model_diagnostics(mod)
fig_diag

vif_table <- car::vif(mod) %>% enframe(name = "Predictor", value = "VIF")
vif_table

cooks <- augment(mod)$.cooksd
cli_alert_info(
  "Participants above the 4/n Cook's distance threshold: {sum(cooks > 4 / nobs(mod))} (max Cook's D = {round(max(cooks), 3)})"
)

# Want to see how it works? Printing a function shows its source code.
# print(plot_model_diagnostics)

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

figures <- tibble(
  filename = c("A_missingness.png", "B_distributions.png", "C_correlations.png",
               "D_key_associations.png", "E_diagnostics_attentive_matrices.png"),
  plot     = list(fig_missing, fig_dist, fig_corr, fig_scatter, fig_diag),
  width    = c(10, 20, 9, 12, 11),
  height   = c(3, 16, 7, 5, 9)
)

pwalk(figures, function(filename, plot, width, height) {
  path <- file.path(FIGS, filename)
  ggsave(path, plot, width = width, height = height, dpi = 150, bg = "white")
  cli_alert_success("Saved {.file {path}}")
})

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

# Table 2 - bivariate correlations, one row per unique pair of variables
table2_correlations <- cor_tbl %>%
  transmute(
    `Variable 1` = var1,
    `Variable 2` = var2,
    r,
    `p-value` = p,
    `Significant (p<0.05)` = p < 0.05
  )
head(table2_correlations)

# Table 3 - regression coefficients for all three fitted models
table3_regression <- bind_rows(
  tidy_glm_wald(mod_apacs, "APACS (theory-driven)"),
  tidy_glm_wald(mod_att_matr_full, "Attentive Matrices (kitchen-sink)"),
  tidy_glm_wald(mod_att_matr_pars, "Attentive Matrices (parsimonious)")
)
table3_regression

# Want to see how it works? Printing a function shows its source code.
# print(tidy_glm_wald)

# Table 4 - VIF table computed in Section 2.4 (Attentive Matrices, parsimonious model)
table4_vif <- vif_table
table4_vif

tables <- list(
  "table1_descriptives.csv" = table1,
  "table2_correlations.csv" = table2_correlations,
  "table3_regression.csv"   = table3_regression,
  "table4_vif.csv"          = table4_vif
)

iwalk(tables, function(table, filename) {
  path <- file.path(RESULTS, filename)
  write_csv(table, path)
  cli_alert_success("Saved {.file {path}}")
})

# The same four tables in one Excel workbook, one sheet each
xlsx_path <- file.path(RESULTS, "CaseStudy_1_results.xlsx")
openxlsx::write.xlsx(
  list(Descriptives = table1, Correlations = table2_correlations,
       Regression = table3_regression, VIF = table4_vif),
  xlsx_path, overwrite = TRUE
)
cli_alert_success("Saved {.file {xlsx_path}}")

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
# *Generated for the EEG-NPSY tutorial. The analysis uses standard R
# packages plus a few helper functions in the `R/` folder next to this
# notebook - all of it open for inspection.*
