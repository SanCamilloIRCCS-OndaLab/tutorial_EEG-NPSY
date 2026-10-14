# Generated from CaseStudy_1.ipynb - edit the notebook, not this file.
# Same code as the notebook, as a plain script (no Jupyter required).

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
# > All code is defined directly here for transparency and
# > reproducibility. Each step is explained as we go.

# ## 0. Setup
#
# Import the libraries we will use throughout the analysis.

library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)  # combine ggplot panels into one figure
library(car)         # variance inflation factor
library(psych)        # skewness / kurtosis, common in psych/neuropsych stats
library(openxlsx)      # Excel export

theme_set(theme_minimal())

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

npsy <- read.csv(NPSY_CSV)
eeg  <- read.csv(EEG_CSV)
cat(sprintf("NPSY: %d x %d  columns: %s\n", nrow(npsy), ncol(npsy), paste(colnames(npsy), collapse = ", ")))
cat(sprintf("EEG:  %d x %d  columns: %s\n", nrow(eeg), ncol(eeg), paste(colnames(eeg), collapse = ", ")))

# Let's inspect the datasets looking at the first rows: each row stores the NPSY/EEG data of a single subject.

cat("NPSY\n"); print(head(npsy))
cat("EEG\n"); print(head(eeg))

# To create a single dataset we need to merge on `subject_id` the data collected for each subject

df <- inner_join(npsy, eeg, by = "subject_id")
cat(sprintf("Merged: %d subjects x %d variables\n", nrow(df), ncol(df)))
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

cat(sprintf("Shape: %d rows x %d columns\n\n", nrow(df), ncol(df)))
cat("First 5 rows:\n"); print(head(df))
cat("\nDescriptive statistics:\n")
summary(df)

# From the automatic R summary we see that all parameters are within the expected ranges.
#
# However looking at each variable is not the most suitable way to validate data: we can perform a simple automatic check on the allowed ranges.

# Range check - flag values outside expected physiological limits
ranges <- list(
  age      = c(18, 100),
  criq     = c(70, 130),
  n400_amp = c(0.5, 8),
  n400_lat = c(300, 550),
  p300_amp = c(3, 25),
  p300_lat = c(250, 550),
  apacs    = c(0, 1),
  att_matr = c(0, 60),
  moca     = c(0, 30)
)

cat("Range checks:\n")
any_warn <- FALSE
for (col in names(ranges)) {
  if (!(col %in% colnames(df))) next
  lo <- ranges[[col]][1]; hi <- ranges[[col]][2]
  vals <- df[[col]][!is.na(df[[col]])]
  below <- sum(vals < lo); above <- sum(vals > hi)
  if (below > 0) { cat(sprintf("  ⚠ %s: %d values below %s\n", col, below, lo)); any_warn <- TRUE }
  if (above > 0) { cat(sprintf("  ⚠ %s: %d values above %s\n", col, above, hi)); any_warn <- TRUE }
}
if (!any_warn) cat("  All values within expected ranges.\n")

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

if (sum(is.na(df)) == 0) {
  fig_missing <- ggplot() +
    annotate("text", x = 0, y = 0, label = "No missing data", size = 6) +
    theme_void() + ggtitle("Missing data matrix")
} else {
  miss_long <- df %>%
    mutate(row = row_number()) %>%
    pivot_longer(-row, names_to = "variable", values_to = "value") %>%
    mutate(missing = is.na(value))
  fig_missing <- ggplot(miss_long, aes(variable, row, fill = missing)) +
    geom_tile() +
    scale_fill_manual(values = c(`FALSE` = "grey90", `TRUE` = "firebrick")) +
    theme(axis.text.y = element_blank(), axis.text.x = element_text(angle = 45, hjust = 1)) +
    ggtitle("Missing data matrix")
}
print(fig_missing)

cat(sprintf("%-25s %8s %8s\n", "Variable", "Missing", "Rate"))
cat(strrep("-", 43), "\n")
for (col in colnames(df)) {
  n_miss <- sum(is.na(df[[col]]))
  cat(sprintf("%-25s %8d %7.1f%%\n", col, n_miss, n_miss / nrow(df) * 100))
}

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

make_hist <- function(col) {
  v <- df[[col]]; v <- v[!is.na(v)]
  ggplot(data.frame(v = v), aes(v)) +
    geom_histogram(bins = 15, fill = "grey70", color = "white") +
    geom_vline(xintercept = mean(v), color = "firebrick", linetype = "dashed") +
    geom_vline(xintercept = median(v), color = "darkgreen", linetype = "dotted") +
    labs(title = sprintf("%s (n=%d)", col, length(v)), x = col, y = "Frequency") +
    theme_minimal(base_size = 9)
}

make_qq <- function(col) {
  v <- df[[col]]; v <- v[!is.na(v)]
  ggplot(data.frame(v = v), aes(sample = v)) +
    stat_qq(size = 1) + stat_qq_line(color = "firebrick") +
    labs(title = "Q-Q plot", x = "Theoretical", y = "Sample") +
    theme_minimal(base_size = 9)
}

hists <- lapply(vars, make_hist)
qqs   <- lapply(vars, make_qq)

# 4-row x 5-col layout: hist(1-5), qq(1-5), hist(6-10), qq(6-10)
fig_dist <- wrap_plots(c(hists[1:5], qqs[1:5], hists[6:10], qqs[6:10]), ncol = 5)
print(fig_dist)

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

cat("Normality tests (Shapiro-Wilk):\n")
for (col in vars) {
  v <- df[[col]][!is.na(df[[col]])]
  if (length(v) < 3) next
  st <- shapiro.test(v)
  cat(sprintf("  %s: n=%d, mean=%.2f, SD=%.2f, W=%.4f, p=%.4f, skew=%.3f, kurt=%.3f\n",
              col, length(v), mean(v), sd(v), st$statistic, st$p.value,
              skew(v, type = 2), kurtosi(v, type = 2)))
}

# **Interpretation:** all Shapiro-Wilk tests are non-significant (p > 0.05) and skewness values are well below |0.6|, so the variables are approximately normal. Minor scatter in the Q-Q plots is expected with n = 40 and does not indicate a problem.

# ### 1.5 Outlier detection
#
# Flag values beyond ±3 standard deviations. We inspect flagged cases and note
# whether they are data-entry errors or genuine extremes.

out_mask <- as.data.frame(matrix(FALSE, nrow = nrow(df), ncol = length(vars),
                                  dimnames = list(NULL, vars)))
for (col in vars) {
  v <- df[[col]]
  valid_idx <- which(!is.na(v))
  vv <- v[valid_idx]
  if (length(vv) < 3) next
  z <- abs(scale(vv)[, 1])
  out_mask[valid_idx[z > 3], col] <- TRUE
}

cat("Outliers (±3 SD):\n")
found <- FALSE
for (col in vars) {
  flagged <- which(out_mask[[col]])
  if (length(flagged) > 0) {
    found <- TRUE
    cat(sprintf("  %s: rows %s\n", col, paste(flagged, collapse = ", ")))
    for (idx in flagged) cat(sprintf("    row %d: %s = %s\n", idx, col, df[[col]][idx]))
  }
}
if (!found) cat("  None detected.\n")

# **Decision rule:** If clinically suspicious outliers exist, we run the
# analysis with and without them as a sensitivity check and report both.

# ---
# ## 2. Analysis

# ### 2.1 Descriptive statistics (Table 1)
#
# We describe each variable by looking at its mean, standard deviation, and range of values

table1 <- bind_rows(lapply(vars, function(col) {
  v <- df[[col]][!is.na(df[[col]])]
  data.frame(Variable = col, n = length(v),
             Value = sprintf("%.2f ± %.2f", mean(v), sd(v)),
             Range = sprintf("[%.2f, %.2f]", min(v), max(v)))
}))
table1

# ### 2.2 Bivariate correlations (ERP × NPSY)
#
# We compute Pearson correlations between all the variables, but the interesting values are the ones between the ERP features and the
# neuropsychological outcomes. The heatmap shows r values with significance
# stars (* p<0.05, ** p<0.01, *** p<0.001).

n_vars <- length(vars)
valid <- df[vars] %>% drop_na()

corr_mat <- matrix(1, n_vars, n_vars, dimnames = list(vars, vars))
p_mat    <- matrix(1, n_vars, n_vars, dimnames = list(vars, vars))
for (i in 1:n_vars) {
  for (j in 1:n_vars) {
    if (i == j) next
    ct <- cor.test(valid[[vars[i]]], valid[[vars[j]]])
    corr_mat[i, j] <- unname(ct$estimate)
    p_mat[i, j] <- ct$p.value
  }
}

# long format, lower triangle + diagonal only
heat_rows <- list()
for (i in 1:n_vars) {
  for (j in 1:n_vars) {
    if (j > i) next
    star <- if (p_mat[i, j] < 0.001) "***" else if (p_mat[i, j] < 0.01) "**" else if (p_mat[i, j] < 0.05) "*" else ""
    heat_rows[[length(heat_rows) + 1]] <- data.frame(
      Var1 = vars[i], Var2 = vars[j], r = corr_mat[i, j],
      label = sprintf("%.3f\n%s", corr_mat[i, j], star))
  }
}
heat_df <- bind_rows(heat_rows) %>%
  mutate(Var1 = factor(Var1, levels = vars), Var2 = factor(Var2, levels = rev(vars)))

fig_corr <- ggplot(heat_df, aes(Var1, Var2, fill = r)) +
  geom_tile(color = "white") +
  geom_text(aes(label = label), size = 2.6, lineheight = 0.85) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", midpoint = 0, limits = c(-1, 1)) +
  coord_fixed() +
  labs(title = "Pearson correlations  (* p<0.05, ** p<0.01, *** p<0.001)", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
print(fig_corr)

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

pairs_list <- list(c("p300_amp", "att_matr"), c("n400_lat", "apacs"))

make_scatter <- function(xvar, yvar) {
  v <- df[c(xvar, yvar)] %>% drop_na()
  ct <- cor.test(v[[xvar]], v[[yvar]])
  ggplot(v, aes(.data[[xvar]], .data[[yvar]])) +
    geom_point(alpha = 0.6, color = "steelblue") +
    geom_smooth(method = "lm", color = "#00796B", fill = "#00796B", alpha = 0.15, formula = y ~ x) +
    labs(title = sprintf("%s vs %s   r=%.3f, p=%.4f", xvar, yvar, ct$estimate, ct$p.value),
         x = xvar, y = yvar)
}

fig_scatter <- wrap_plots(lapply(pairs_list, function(p) make_scatter(p[1], p[2])), ncol = 2)
print(fig_scatter)

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
fitted_vals <- fitted(mod)
resid_vals  <- residuals(mod, type = "response")
n <- nobs(mod)

p_resid <- ggplot(data.frame(fitted = fitted_vals, resid = resid_vals), aes(fitted, resid)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals")

p_qq <- ggplot(data.frame(r = resid_vals), aes(sample = r)) +
  stat_qq() + stat_qq_line(color = "firebrick") +
  labs(title = "Q-Q plot (residuals)")

cooks <- cooks.distance(mod)
p_cooks <- ggplot(data.frame(i = seq_along(cooks), cooks = cooks), aes(i, cooks)) +
  geom_segment(aes(xend = i, yend = 0), color = "steelblue") +
  geom_point(color = "steelblue") +
  geom_hline(yintercept = 4 / n, color = "firebrick", linetype = "dashed") +
  labs(title = "Cook's Distance", x = "Participant (row index)", y = "Cook's distance",
       subtitle = sprintf("4/n = %.3f", 4 / n))

vif_vals <- car::vif(mod)
vif_table <- data.frame(Predictor = names(vif_vals), VIF = as.numeric(vif_vals))

p_vif <- ggplot(vif_table, aes(VIF, reorder(Predictor, VIF))) +
  geom_col(fill = "steelblue") +
  geom_vline(xintercept = 5, color = "orange", linetype = "dashed") +
  geom_vline(xintercept = 10, color = "firebrick", linetype = "dashed") +
  labs(title = "Variance Inflation Factor", x = "VIF", y = NULL)

fig_diag <- (p_resid + p_qq) / (p_cooks + p_vif)
print(fig_diag)

print(vif_table)
n_influential <- sum(cooks > 4 / n)
cat(sprintf("\nParticipants above the 4/n Cook's distance threshold: %d (max Cook's D = %.3f)\n",
            n_influential, max(cooks)))

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

figures_to_save <- list(
  "A_missingness.png"                     = list(fig = fig_missing, w = 10, h = 3),
  "B_distributions.png"                   = list(fig = fig_dist,    w = 20, h = 16),
  "C_correlations.png"                    = list(fig = fig_corr,    w = 9,  h = 7),
  "D_key_associations.png"                = list(fig = fig_scatter, w = 12, h = 5),
  "E_diagnostics_attentive_matrices.png"  = list(fig = fig_diag,    w = 11, h = 9)
)

for (filename in names(figures_to_save)) {
  spec <- figures_to_save[[filename]]
  path <- file.path(FIGS, filename)
  ggsave(path, plot = spec$fig, width = spec$w, height = spec$h, dpi = 150, bg = "white")
  cat(sprintf("Saved: %s\n", path))
}

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
corr_rows <- list()
for (i in 1:n_vars) {
  for (j in 1:n_vars) {
    if (j <= i) next
    corr_rows[[length(corr_rows) + 1]] <- data.frame(
      `Variable 1` = vars[i], `Variable 2` = vars[j],
      r = corr_mat[i, j], `p-value` = p_mat[i, j],
      `Significant (p<0.05)` = p_mat[i, j] < 0.05,
      check.names = FALSE)
  }
}
table2_correlations <- bind_rows(corr_rows)
head(table2_correlations)

# Table 3 - regression coefficients for all three fitted models
model_to_table <- function(model, outcome_label) {
  co <- summary(model)$coefficients
  ci <- confint.default(model)   # Wald CI
  data.frame(
    Outcome = outcome_label,
    Predictor = rownames(co),
    Estimate = co[, "Estimate"],
    `Std. Error` = co[, "Std. Error"],
    `p-value` = co[, 4],
    CI_lower = ci[, 1],
    CI_upper = ci[, 2],
    `Significant (p<0.05)` = co[, 4] < 0.05,
    row.names = NULL, check.names = FALSE
  )
}

table3_regression <- bind_rows(
  model_to_table(mod_apacs, "APACS (theory-driven)"),
  model_to_table(mod_att_matr_full, "Attentive Matrices (kitchen-sink)"),
  model_to_table(mod_att_matr_pars, "Attentive Matrices (parsimonious)")
)
table3_regression

# Table 4 - VIF table computed in Section 2.4 (Attentive Matrices, parsimonious model)
table4_vif <- vif_table
table4_vif

tables_to_save <- list(
  "table1_descriptives.csv" = table1,
  "table2_correlations.csv" = table2_correlations,
  "table3_regression.csv"   = table3_regression,
  "table4_vif.csv"          = table4_vif
)

for (filename in names(tables_to_save)) {
  path <- file.path(RESULTS, filename)
  write.csv(tables_to_save[[filename]], path, row.names = FALSE)
  cat(sprintf("Saved: %s\n", path))
}

wb <- createWorkbook()
addWorksheet(wb, "Descriptives"); writeData(wb, "Descriptives", table1)
addWorksheet(wb, "Correlations"); writeData(wb, "Correlations", table2_correlations)
addWorksheet(wb, "Regression");   writeData(wb, "Regression", table3_regression)
addWorksheet(wb, "VIF");          writeData(wb, "VIF", table4_vif)
xlsx_path <- file.path(RESULTS, "CaseStudy_1_results.xlsx")
saveWorkbook(wb, xlsx_path, overwrite = TRUE)
cat(sprintf("Saved: %s\n", xlsx_path))

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
