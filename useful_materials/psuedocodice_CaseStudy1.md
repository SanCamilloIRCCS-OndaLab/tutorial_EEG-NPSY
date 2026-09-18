# CASE STUDY 1 — FULL PIPELINE

## 0. IMPORT

```
import libraries:
    - data handling:        pandas, numpy
    - statistics:           scipy, statsmodels, pingouin
    - visualisation:        matplotlib, seaborn
    - missing data:         missingno, sklearn.impute
    - R (alternative):      tidyverse, mice, car, ggplot2
    - MATLAB (alternative): Statistics Toolbox

eeg_data  = load_dataset(eeg_data_path)
    # expected format: participants × features
    # columns: subject_id,
    #          N400_amplitude, N400_latency,
    #          P300_amplitude, P300_latency

npsy_data = load_dataset(npsy_data_path)
    # expected format: participants × variables
    # columns: subject_id,
    #          age, sex, education, handedness,
    #          lesion_site, stroke_aetiology, time_onset,
    #          MoCA, CRIq, APACS,
    #          matrici_attentive, OCS

data = merge(eeg_data, npsy_data, on="subject_id")
    # inner join by default
    # check: n_rows should equal n_participants
```

## 1. DATA WRANGLING

### 1.1 INITIAL INSPECTION

```
print(data.shape)           # n participants × n variables
print(data.dtypes)          # check variable types
print(data.head())          # visual spot-check
print(data.describe())      # min, max, mean, std for all numeric vars

# flag unexpected values
for each numeric variable:
    check min/max against expected clinical range
        e.g. MoCA must be in [0, 30]
             age must be > 18
             time_onset must be > 0
    flag and inspect outliers (values beyond ±3 SD)
```

### 1.2 VARIABLE TYPE ASSIGNMENT

```
# Continuous variables (will enter models as numeric):
continuous_vars = [age, education, time_onset,
                   CRIq, APACS,
                   N400_amplitude, N400_latency,
                   P300_amplitude, P300_latency]

# Ordinal variables (check distribution before treating as continuous):
ordinal_vars = [MoCA, matrici_attentive, OCS]

# Categorical variables (encode as dummy/factor):
categorical_vars = [sex, handedness, lesion_site, stroke_aetiology]

# dummy-code categorical variables
    e.g. sex:             0 = female, 1 = male
         handedness:      0 = left,   1 = right
         lesion_site:     one-hot encoding (left, right, bilateral)
         stroke_aetiology: one-hot encoding (ischaemic, haemorrhagic, ...)
```

### 1.3 MISSING DATA

```
# visualise missingness pattern
plot_missingness_matrix(data)
    # heatmap of missing values across participants and variables
    # note any systematic patterns (e.g. OCS missing for mild patients)

# compute per-variable missingness rate
for each variable:
    missing_rate = n_missing / n_total * 100
    print(variable, missing_rate)
```

### 1.4 DISTRIBUTION CHECK (CONTINUOUS VARIABLES)

```
for each continuous variable in [continuous_vars + ordinal_vars]:

    # visual inspection
    plot histogram(variable)
    plot Q-Q plot(variable)

    # formal normality tests
    shapiro_wilk_test(variable)         # recommended for n < 50
    kolmogorov_smirnov_test(variable)   # for larger samples

    # descriptive stats
    compute: mean, median, SD, skewness, kurtosis

    # decision tree:
    IF normal distribution:
        → use as-is in linear model
    IF skewed (|skewness| > 1):
        → apply log transformation (if strictly positive)
           or sqrt transformation
           or consider non-parametric alternative
    IF ordinal with few levels (e.g. MoCA subdomains, OCS subtests):
        → consider ordinal logistic regression or
          Spearman correlation instead of Pearson
```

### 1.5 OUTLIER HANDLING

```
for each continuous variable:
    flag participants with values beyond ±3 SD
    inspect flagged cases individually:
        - data entry error? → correct or remove
        - genuine extreme value? → keep, note as sensitivity analysis

# run primary analysis with and without outliers
# report both results, discuss any discrepancies
```

### 1.6 MULTICOLLINEARITY CHECK

```
# compute correlation matrix among all predictors
corr_matrix = pearson_correlation(continuous_predictors)
    # or spearman if non-normal

plot_heatmap(corr_matrix)
    # flag pairs with |r| > 0.7 as potentially collinear

# after fitting regression models (see Section 2):
compute VIF (variance inflation factor) for each predictor
    VIF > 5    → moderate concern
    VIF > 10   → severe multicollinearity → consider removing predictor
                 or combining collinear predictors into composite score
```

### 1.7 FINAL DATASET CHECK

```
print("Final N:", n_participants)
print("Variables in model:", list_of_predictors)
print("Missing values remaining:", data.isnull().sum())
print("Variable ranges after wrangling:", data.describe())

# save clean dataset
save_dataset(data_clean, output_path)
```

## 2. ANALYSIS

### 2.1 DESCRIPTIVE STATISTICS TABLE

```
# Table 1 (demographic and neuropsychological summary)
for each variable:
    IF continuous: report mean ± SD, range
    IF ordinal:    report median [IQR], range
    IF categorical: report n (%)

# group comparisons if relevant (e.g. left vs right lesion):
    t-test or Mann-Whitney U for continuous vars
    chi-square for categorical vars
```

### 2.2 BIVARIATE ASSOCIATIONS (PRELIMINARY)

```
# pairwise correlations between ERP features and neuropsychological scores
for each pair (ERP_feature, npsy_score):
    IF both normal:    pearson_correlation + scatter plot
    IF non-normal:     spearman_correlation + scatter plot
    report: r, p-value, confidence interval, effect size

plot_correlation_matrix(ERP_features, npsy_scores)
    # annotated heatmap with r values and significance stars
```

### 2.3 REGRESSION MODELS

```
# one model per neuropsychological outcome
# general structure:
#   outcome ~ ERP_features + covariates

for each outcome in [MoCA, CRIq, APACS, matrici_attentive, OCS]:

    IF outcome is continuous (CRIq, APACS):
        model = linear_regression(
                    outcome ~ N400_amplitude + N400_latency +
                              P300_amplitude + P300_latency +
                              age + sex + education + time_onset,
                    data = data_clean)

    IF outcome is ordinal (MoCA, OCS, matrici_attentive):
        model = ordinal_logistic_regression(
                    outcome ~ N400_amplitude + N400_latency +
                              P300_amplitude + P300_latency +
                              age + sex + education + time_onset,
                    data = data_clean)
        # alternative: treat as continuous if distribution is
        #              approximately normal and range is wide

    print(model.summary())
        # coefficients, SE, t/z, p-values, CI
        # R² or pseudo-R² (Nagelkerke) for model fit
        # AIC for model comparison
```

### 2.4 ASSUMPTION CHECKING (POST-HOC)

```
for each fitted linear model:
    plot residuals vs fitted values    # check homoscedasticity
    plot Q-Q plot of residuals         # check normality of residuals
    compute VIF for all predictors     # check multicollinearity
    compute Cook's distance            # identify influential observations
        flag participants with Cook's D > 4/n
```

### 2.5 MULTIPLE COMPARISON CORRECTION

```
# collect p-values across all models
p_values = [p1, p2, p3, p4, p5]   # one per outcome

# apply correction
p_adjusted_bonferroni = bonferroni_correction(p_values)
p_adjusted_fdr        = fdr_bh_correction(p_values)    # Benjamini-Hochberg

# report both corrected and uncorrected p-values
# interpret results primarily based on corrected values
```

## 3. PLOT AND EXPORT

### 3.1 PLOTS

```
# Figure A: missingness heatmap (pre-wrangling)
# Figure B: distribution plots (histograms + Q-Q) for all key variables
# Figure C: correlation heatmap (ERP features × npsy scores)
# Figure D: scatter plots with regression lines for significant associations
#           e.g. P300_amplitude vs MoCA, N400_amplitude vs APACS
#           include: data points, regression line, 95% CI band,
#                    r and p-value annotation
# Figure E: coefficient plot (forest plot) for regression models
#           one panel per outcome, predictors on y-axis, beta ± CI on x-axis
```

### 3.2 EXPORT

```
save_table(descriptive_stats,   "table1_descriptives.csv")
save_table(correlation_matrix,  "table2_correlations.csv")
save_table(regression_results,  "table3_regressions.csv")
save_table(p_values_corrected,  "table4_multiple_comparisons.csv")

save_figure(missingness_plot,   "figA_missingness.pdf")
save_figure(distribution_plots, "figB_distributions.pdf")
save_figure(correlation_heatmap,"figC_correlations.pdf")
save_figure(scatter_plots,      "figD_scatter.pdf")
save_figure(coefficient_plot,   "figE_coefficients.pdf")

save_dataset(data_clean,        "CS1_clean_dataset.csv")
save_script(this_script,        "CS1_analysis.py / .R / .m")
```
