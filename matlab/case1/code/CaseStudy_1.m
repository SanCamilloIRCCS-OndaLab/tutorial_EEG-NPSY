% Case Study 1 - Analytical strategy based on reduced EEG features (MATLAB)
%
% This is the MATLAB implementation of Case Study 1 - same data, same
% models, same explanations as the Python and R versions. It implements
% the analysis described in Section 4.1 of the companion paper. Written
% using MATLAB's own table/model classes (readtable, fitlm, histogram,
% exportgraphics) rather than hand-rolled equivalents - see
% matlab/README_matlab.md for requirements.
%
% The research question is:
%   Are the amplitude and latency of specific ERP components associated
%   with neuropsychological performance and demographic characteristics
%   in post-stroke patients?
%
% Two well-characterised ERP components are used:
%   - N400 - a negative deflection ~400 ms post-stimulus, indexing
%     semantic processing (Kutas & Federmeier, 2011)
%   - P300 - a positive deflection ~300 ms post-target, indexing
%     attentional resource allocation (Polich, 2007)
%
% From each component we consider amplitude (mean uV within a predefined
% time window) and latency (ms of peak amplitude), yielding four
% participant-level neural predictors.
%
% Pipeline:
%   1. Data Wrangling  - load, inspect, check ranges, missing data,
%      distributions, outliers
%   2. Analysis        - descriptive stats, bivariate correlations,
%      three regression models, post-hoc assumption checking
%   3. Export          - save tables and figures
%
% All code is defined directly here for transparency and reproducibility.

%% 0. Setup

set(0, "DefaultFigureVisible", "off");  % headless: save figures, never pop up windows

%% Input/output folders

DATA_DIR = fullfile("..", "..", "..", "data");
NPSY_CSV = fullfile(DATA_DIR, "dataset_NPSY.csv");
EEG_CSV  = fullfile(DATA_DIR, "dataset_ERP.csv");

OUTPUTS = fullfile("..", "outputs");
FIGS    = fullfile(OUTPUTS, "figures");
RESULTS = fullfile(OUTPUTS, "results");
if ~exist(FIGS, "dir");    mkdir(FIGS);    end
if ~exist(RESULTS, "dir"); mkdir(RESULTS); end

%% 1. Data Wrangling
%% 1.1 Load data
% The datasets are stored as separate CSV files linked by subject_id.

npsy = readtable(NPSY_CSV);
eeg  = readtable(EEG_CSV);
fprintf("NPSY: %d x %d\n", height(npsy), width(npsy));
fprintf("EEG:  %d x %d\n", height(eeg), width(eeg));

% Both files are generated together and already row-aligned by
% subject_id (see data/generate_datasets.ipynb); we still verify this
% explicitly rather than assuming it, same as the Python/R versions.
assert(isequal(npsy.subject_id, eeg.subject_id), ...
       "NPSY and EEG tables must be row-aligned by subject_id");

df = [npsy, eeg(:, {'n400_amp', 'n400_lat', 'p300_amp', 'p300_lat'})];
n_subj = height(df);
fprintf("Merged: %d subjects x %d variables\n", n_subj, width(df) - 1);

%% 1.2 Initial inspection
% Expected clinical ranges: age 18-100y, CRIq 70-130, N400 amp 1-6uV,
% N400 lat 350-500ms, P300 amp 5-20uV, P300 lat 300-500ms, APACS 0-1,
% Attentive Matrices 0-60, MoCA 0-30.

range_vars = {"age", "criq", "n400_amp", "n400_lat", "p300_amp", "p300_lat", "apacs", "att_matr", "moca"};
range_lo   = [18,     70,     0.5,        300,        3,          250,        0,       0,          0];
range_hi   = [100,    130,    8,          550,        25,         550,        1,       60,         30];

fprintf("Range checks:\n");
any_warn = false;
for i = 1:numel(range_vars)
  col = range_vars{i};
  v = df.(col);
  below = sum(v < range_lo(i));
  above = sum(v > range_hi(i));
  if below > 0
    fprintf("  ! %s: %d values below %g\n", col, below, range_lo(i)); any_warn = true;
  end
  if above > 0
    fprintf("  ! %s: %d values above %g\n", col, above, range_hi(i)); any_warn = true;
  end
end
if ~any_warn
  fprintf("  All values within expected ranges.\n");
end

%% 1.3 Missing data
% Missing data are common in clinical neuropsychological datasets - they
% can arise from fatigue, incomplete testing, or participant dropout.
% Listwise deletion is simple but reduces sample size and may bias
% estimates if data are not missing completely at random (MCAR);
% multiple imputation preserves sample size and is valid under the
% weaker missing-at-random (MAR) assumption, and is generally preferred
% in clinical samples. Our synthetic dataset has complete data for all
% 40 participants, so no imputation is needed here.

vars = {'age', 'sex', 'criq', 'apacs', 'att_matr', 'moca', ...
        'n400_amp', 'n400_lat', 'p300_amp', 'p300_lat'};

miss_mat = ismissing(df(:, vars));
total_missing = sum(miss_mat, "all");

fig_missing = figure("Position", [0 0 900 250]);
if total_missing == 0
  text(0.5, 0.5, "No missing data", "HorizontalAlignment", "center", "FontSize", 14);
  axis off;
else
  imagesc(miss_mat'); colormap(gca, [0.85 0.85 0.85; 0.2 0.2 0.6]);
  set(gca, "YTick", 1:numel(vars), "YTickLabel", vars, "TickLabelInterpreter", "none");
end
title("Missing data matrix");

fprintf("%-25s %8s %8s\n", "Variable", "Missing", "Rate");
fprintf("%s\n", repmat('-', 1, 43));
for i = 1:numel(vars)
  n_miss = sum(miss_mat(:, i));
  fprintf("%-25s %8d %7.1f%%\n", vars{i}, n_miss, n_miss / n_subj * 100);
end

% What do we see in the plot?
%   Each row is a participant, each column a variable; a highlighted
%   cell would mark a missing value. Here the matrix is empty and the
%   per-column rates above all read 0% - this synthetic dataset has no
%   missing data by construction, so there's nothing to impute or
%   exclude. In a real dataset, scattered missingness would support
%   listwise deletion; missingness concentrated in specific participants
%   or variables would be a reason to consider imputation instead.

%% 1.4 Distribution check
% A quality check beyond simple plots: Q-Q plots and the Shapiro-Wilk
% normality test, to guide later decisions about transformations and
% correlation methods. MATLAB has no built-in Shapiro-Wilk test (neither
% base nor the Statistics Toolbox ship one), so swtest.m (Ben Saida,
% 2009/2014, MATLAB File Exchange #13964) is used - it implements
% Royston's AS R94 approximation, matching scipy.stats.shapiro/R's
% shapiro.test to machine precision, EXCEPT that for leptokurtic
% variables (kurtosis > 3) it automatically substitutes the
% Shapiro-Francia test instead (Royston's own recommendation - see the
% function's help text), which Python/R's calls never do. In this
% dataset that affects att_matr, p300_amp and p300_lat - the W/p values
% printed for those three will differ from the Python/R notebooks (same
% conclusion, different exact numbers); all other variables match
% exactly.

fig_dist = figure("Position", [0 0 1600 1100]);
for i = 1:numel(vars)
  col = vars{i};
  v = df.(col);
  row = floor((i - 1) / 5) * 2;

  subplot(4, 5, row * 5 + mod(i - 1, 5) + 1);
  histogram(v, 10);
  hold on;
  yl = ylim();
  plot([mean(v, "omitnan") mean(v, "omitnan")], yl, "r--", "LineWidth", 1.2);
  plot([median(v, "omitnan") median(v, "omitnan")], yl, "g:", "LineWidth", 1.2);
  title(sprintf("%s (n=%d)", col, numel(v)), "Interpreter", "none");
  xlabel(col, "Interpreter", "none"); ylabel("Frequency");

  subplot(4, 5, (row + 1) * 5 + mod(i - 1, 5) + 1);
  qqplot(v);
  title("Q-Q plot");
end

fprintf("Normality tests (Shapiro-Wilk, Shapiro-Francia if leptokurtic):\n");
for i = 1:numel(vars)
  col = vars{i};
  v = df.(col);
  [~, p, W] = swtest(v);
  test_used = "Shapiro-Wilk";
  if kurtosis(v) > 3; test_used = "Shapiro-Francia"; end
  fprintf("  %-10s: n=%d, mean=%.2f, SD=%.2f, W=%.4f, p=%.4f, skew=%.3f, kurt=%.3f (%s)\n", ...
          col, numel(v), mean(v, "omitnan"), std(v, "omitnan"), W, p, skewness(v), kurtosis(v) - 3, test_used);
end

% What do we see in the plot?
%   Histogram - a roughly symmetric, bell-shaped curve suggests
%   normality. Strong skewness or a U-shape would be a warning sign.
%   Q-Q plot - points should fall along the diagonal line if the data
%   are normally distributed.
%
% Interpretation: all Shapiro-Wilk tests are non-significant (p > 0.05)
% and skewness values are well below |0.6|, so the variables are
% approximately normal. Minor scatter in the Q-Q plots is expected with
% n = 40 and does not indicate a problem.

%% 1.5 Outlier detection
% Flag values beyond +-3 standard deviations.

out_mask = false(n_subj, numel(vars));
fprintf("Outliers (+-3 SD):\n");
found_any = false;
for i = 1:numel(vars)
  col = vars{i};
  v = df.(col);
  z = (v - mean(v, "omitnan")) / std(v, "omitnan");
  flagged = find(abs(z) > 3);
  out_mask(flagged, i) = true;
  if ~isempty(flagged)
    found_any = true;
    fprintf("  %s: rows %s\n", col, mat2str(flagged'));
    for r = flagged'
      fprintf("    row %d: %s = %g\n", r, col, v(r));
    end
  end
end
if ~found_any
  fprintf("  None detected.\n");
end

%% 1.6 Cleaning dataset
% Let's remove the missing data and the outliers.
%
% There are three outliers that are not plausible data: Age 150, N400
% Amplitude 25 uV, P300 latency 900ms. We will remove these subjects.
%
% However the value of 3 for attentive matrices is very low but it is
% also very plausible in a patient dataset, therefore we will keep this
% outlier.

missing_mask = any(miss_mat, 2);

% Outliers: exclude only the implausible ones found in Section 1.5 - keep
% the att_matr outlier, since it is a plausible (if low) clinical value
implausible_cols = {'age', 'n400_amp', 'p300_lat'};
[~, implausible_idx] = ismember(implausible_cols, vars);
outlier_mask = any(out_mask(:, implausible_idx), 2);

exclude_mask = missing_mask | outlier_mask;
fprintf("Excluding %d participants:\n", sum(exclude_mask));
disp(df(exclude_mask, [{'subject_id'}, vars]));

df = df(~exclude_mask, :);
n_subj = height(df);
fprintf("\nRemaining: %d participants\n", n_subj);

%% 2. Analysis
%% 2.1 Descriptive statistics (Table 1)

table1_names = vars';
table1_n = zeros(numel(vars), 1);
table1_value = strings(numel(vars), 1);
table1_range = strings(numel(vars), 1);
for i = 1:numel(vars)
  v = df.(vars{i});
  table1_n(i) = numel(v);
  table1_value(i) = sprintf("%.2f +/- %.2f", mean(v), std(v));
  table1_range(i) = sprintf("[%.2f, %.2f]", min(v), max(v));
end
table1 = table(table1_names, table1_n, table1_value, table1_range, ...
  'VariableNames', {'Variable', 'n', 'Value', 'Range'});
disp("Table 1 - Descriptive statistics:");
disp(table1);

%% 2.2 Bivariate correlations (ERP x NPSY)
% Pearson correlations between all variables, with significance stars
% (* p<0.05, ** p<0.01, *** p<0.001).

n_vars = numel(vars);
corr_mat = eye(n_vars);
p_mat = ones(n_vars);
for i = 1:n_vars
  for j = 1:n_vars
    if i == j; continue; end
    x = df.(vars{i}); y = df.(vars{j});
    [r, p] = corr(x, y);
    corr_mat(i, j) = r;
    p_mat(i, j) = p;
  end
end

fig_corr = figure("Position", [0 0 800 700]);
mask = triu(true(n_vars), 1);  % upper triangle, matching the Python/R plot
imagesc(corr_mat, "AlphaData", ~mask);
set(gca, "Color", [1 1 1]);  % masked cells show through as white
clim([-1 1]);
colormap(redblue_colormap());
colorbar();
set(gca, "XTick", 1:n_vars, "XTickLabel", vars, "XTickLabelRotation", 45, ...
         "YTick", 1:n_vars, "YTickLabel", vars, "TickLabelInterpreter", "none");
axis square;
for i = 1:n_vars
  for j = 1:n_vars
    if mask(i, j); continue; end
    r = corr_mat(i, j); p = p_mat(i, j);
    star = "";
    if p < 0.001; star = "***"; elseif p < 0.01; star = "**"; elseif p < 0.05; star = "*"; end
    text(j, i, sprintf("%.3f\n%s", r, star), "HorizontalAlignment", "center", "FontSize", 7);
  end
end
title("Pearson correlations  (* p<0.05, ** p<0.01, *** p<0.001)");

% What do we see in the plot?
%   Each cell shows the Pearson correlation coefficient (r) between a
%   pair of variables. Colours indicate direction: red = positive,
%   blue = negative. Stars indicate significance: * p<0.05, ** p<0.01,
%   *** p<0.001.

%% Key hypothesised associations
% Based on the literature, we focus on two key pairs and plot scatter
% plots with regression lines and 95% confidence bands.

pair_x = {"p300_amp", "n400_lat"};
pair_y = {"att_matr", "apacs"};

fig_scatter = figure("Position", [0 0 1100 450]);
for i = 1:2
  subplot(1, 2, i);
  x = df.(pair_x{i}); y = df.(pair_y{i});
  scatter(x, y, 30, [0.3 0.5 0.8], "filled", "MarkerFaceAlpha", 0.6);
  hold on;

  mdl = fitlm(x, y);
  xg = linspace(min(x), max(x), 100)';
  [yhat, yci] = predict(mdl, xg);
  fill([xg; flipud(xg)], [yci(:, 1); flipud(yci(:, 2))], ...
       [0 0.47 0.42], "FaceAlpha", 0.15, "EdgeColor", "none");
  plot(xg, yhat, "Color", [0 0.47 0.42], "LineWidth", 1.5);

  [r, p] = corr(x, y);
  title(sprintf("%s vs %s   r=%.3f, p=%.4f", pair_x{i}, pair_y{i}, r, p), "Interpreter", "none");
  xlabel(pair_x{i}, "Interpreter", "none"); ylabel(pair_y{i}, "Interpreter", "none");
end

% What do we see in the plot?
%   Each dot is one participant. The regression line shows the best-fit
%   linear relationship; the shaded band is the 95% confidence interval.
%   r quantifies strength (-1 to +1); p tests whether it is
%   significantly different from zero.

%% 2.3 General linear models
% Three models, mirroring the Python/R versions:
%   - APACS (theory-driven): apacs ~ n400_lat + n400_amp + age
%   - Attentive Matrices (kitchen-sink, no a priori knowledge): all
%     covariates thrown in, to illustrate the cost of ignoring theory
%   - Attentive Matrices (parsimonious, theory-guided):
%     att_matr ~ p300_amp + age + criq, with predictors chosen a priori
%     from theory and the Section 2.2 correlations, not by trimming
%     non-significant terms from the kitchen-sink model (that would be
%     post-hoc pruning, a form of circular reasoning).

mod_apacs = fitlm(df, "apacs ~ n400_lat + n400_amp + age");
disp("APACS (theory-driven):"); disp(mod_apacs);

mod_att_matr_full = fitlm(df, "att_matr ~ p300_lat + p300_amp + n400_lat + n400_amp + age + sex + criq");
disp("Attentive Matrices (kitchen-sink):"); disp(mod_att_matr_full);

mod_att_matr_pars = fitlm(df, "att_matr ~ p300_amp + age + criq");
disp("Attentive Matrices (parsimonious):"); disp(mod_att_matr_pars);

% Takeaway: more variables does not mean a better model. The predictors
% in the parsimonious model were chosen a priori, from theory and from
% the Section 2.2 correlations, before looking at any p-value from the
% kitchen-sink model - the kitchen-sink model exists only to illustrate
% the cost of ignoring theory (inflated standard errors, an unstable
% intercept), not to guide which variables to keep.

%% 2.4 Assumption checking (post-hoc)
% Checked here for the final, parsimonious Attentive Matrices model.

mod = mod_att_matr_pars;
fitted = mod.Fitted; resid = mod.Residuals.Raw; n = mod.NumObservations;
cooks = mod.Diagnostics.CooksDistance;

fig_diag = figure("Position", [0 0 1000 800]);

subplot(2, 2, 1);
scatter(fitted, resid, 25, [0.3 0.5 0.8], "filled");
hold on; plot(xlim(), [0 0], "k--");
xlabel("Fitted values"); ylabel("Residuals"); title("Residuals vs Fitted");

subplot(2, 2, 2);
qqplot(resid);
title("Q-Q plot (residuals)");

subplot(2, 2, 3);
stem(1:n, cooks, "filled", "MarkerSize", 3);
hold on;
thresh = 4 / n;
h_thresh = plot(xlim(), [thresh thresh], "r--");
xlabel("Participant (row index)"); ylabel("Cook's distance");
title("Cook's Distance");
legend(h_thresh, sprintf("4/n = %.3f", thresh), "Location", "best");

subplot(2, 2, 4);
% Classic VIF formula: diagonal of the inverse correlation matrix of the
% predictors (equivalent to 1 / (1 - R^2) from the auxiliary regressions).
vif_names = {"p300_amp", "age", "criq"};
X = [df.p300_amp, df.age, df.criq];
vifs = diag(inv(corrcoef(X)));
barh(1:3, vifs, "FaceColor", [0.27 0.51 0.71]);
set(gca, "YTick", 1:3, "YTickLabel", vif_names, "TickLabelInterpreter", "none");
hold on;
h_vif5 = plot([5 5], ylim(), "Color", [1 0.55 0], "LineStyle", "--");
h_vif10 = plot([10 10], ylim(), "r--");
xlabel("VIF"); title("Variance Inflation Factor");
legend([h_vif5, h_vif10], {"VIF=5", "VIF=10"}, "Location", "best");

fprintf("\n  predictor      VIF\n");
for i = 1:3
  fprintf("  %-10s %.6f\n", vif_names{i}, vifs(i));
end
n_influential = sum(cooks > 4 / n);
fprintf("\nParticipants above the 4/n Cook's distance threshold: %d (max Cook's D = %.3f)\n", ...
        n_influential, max(cooks));

% What do we see in the plot?
%   Residuals vs Fitted - no funnel shape or curve should be visible.
%   Q-Q plot (residuals) - points should lie close to the diagonal.
%   Cook's distance - a handful of points above the 4/n line is not
%   unusual with n = 40 and is not, on its own, a red flag.
%   VIF - values close to 1 mean each predictor carries mostly
%   independent information; all three sit well below VIF = 5.
%
% Interpretation: diagnostics are reassuring for the parsimonious
% Attentive Matrices model - residuals show no obvious pattern, the Q-Q
% plot is close to the diagonal, no participant has a disproportionately
% large Cook's distance, and VIF values are low.

%% 3. Export
%% 3.1 Figures

figures_to_save = struct( ...
  "A_missingness", fig_missing, ...
  "B_distributions", fig_dist, ...
  "C_correlations", fig_corr, ...
  "D_key_associations", fig_scatter, ...
  "E_diagnostics_attentive_matrices", fig_diag);
fn = fieldnames(figures_to_save);
for i = 1:numel(fn)
  path = fullfile(FIGS, [fn{i} '.png']);
  exportgraphics(figures_to_save.(fn{i}), path, 'Resolution', 150);
  fprintf("Saved: %s\n", path);
end

%% 3.2 Tables

writetable(table1, fullfile(RESULTS, "table1_descriptives.csv"));

% Table 2 - bivariate correlations, one row per unique pair
t2_v1 = strings(0, 1); t2_v2 = strings(0, 1); t2_r = []; t2_p = []; t2_sig = logical([]);
for i = 1:n_vars
  for j = (i+1):n_vars
    t2_v1(end+1, 1) = vars{i};
    t2_v2(end+1, 1) = vars{j};
    t2_r(end+1, 1) = corr_mat(i, j);
    t2_p(end+1, 1) = p_mat(i, j);
    t2_sig(end+1, 1) = p_mat(i, j) < 0.05;
  end
end
table2 = table(t2_v1, t2_v2, t2_r, t2_p, t2_sig, ...
  'VariableNames', {'Variable_1', 'Variable_2', 'r', 'p_value', 'Significant_p_05'});
writetable(table2, fullfile(RESULTS, "table2_correlations.csv"));

% Table 3 - regression coefficients for all three fitted models
t3_outcome = strings(0, 1); t3_pred = strings(0, 1);
t3_est = []; t3_se = []; t3_p = []; t3_lo = []; t3_hi = []; t3_sig = logical([]);
models = {mod_apacs, mod_att_matr_full, mod_att_matr_pars};
labels = {"APACS (theory-driven)", "Attentive Matrices (kitchen-sink)", "Attentive Matrices (parsimonious)"};
for m = 1:3
  fit = models{m};
  ci = coefCI(fit);
  coef_names = fit.CoefficientNames;
  for i = 1:numel(coef_names)
    t3_outcome(end+1, 1) = labels{m};
    t3_pred(end+1, 1) = coef_names{i};
    t3_est(end+1, 1) = fit.Coefficients.Estimate(i);
    t3_se(end+1, 1) = fit.Coefficients.SE(i);
    t3_p(end+1, 1) = fit.Coefficients.pValue(i);
    t3_lo(end+1, 1) = ci(i, 1);
    t3_hi(end+1, 1) = ci(i, 2);
    t3_sig(end+1, 1) = fit.Coefficients.pValue(i) < 0.05;
  end
end
table3 = table(t3_outcome, t3_pred, t3_est, t3_se, t3_p, t3_lo, t3_hi, t3_sig, ...
  'VariableNames', {'Outcome', 'Predictor', 'Estimate', 'Std_Error', 'p_value', 'CI_lower', 'CI_upper', 'Significant_p_05'});
writetable(table3, fullfile(RESULTS, "table3_regression.csv"));

% Table 4 - VIF (Attentive Matrices, parsimonious model)
table4 = table(vif_names', vifs, 'VariableNames', {'Predictor', 'VIF'});
writetable(table4, fullfile(RESULTS, "table4_vif.csv"));

fprintf("Saved 4 result tables to %s\n", RESULTS);

% Also export everything to a single Excel workbook, one sheet per table -
% writetable infers the format from the extension, no extra toolbox needed.
xlsx_path = fullfile(RESULTS, "CaseStudy_1_results.xlsx");
writetable(table1, xlsx_path, "Sheet", "descriptives");
writetable(table2, xlsx_path, "Sheet", "correlations");
writetable(table3, xlsx_path, "Sheet", "regression");
writetable(table4, xlsx_path, "Sheet", "vif");
fprintf("Saved: %s\n", xlsx_path);

%% 4. Strengths and limitations of this approach (Section 4.2.3)
%
% Strengths:
%   - Reduces high-dimensional EEG to 4 interpretable scalar features
%     per participant - theoretically grounded, easy to communicate
%   - Uses well-established statistical models (OLS regression) familiar
%     to clinical researchers
%   - The N400 and P300 have decades of validation across neurological
%     populations (Kutas & Federmeier, 2011; Polich, 2007)
%
% Limitations:
%   - Strong a priori decisions about time windows and electrode sets
%     may miss atypical or distributed neural patterns
%   - Trial-to-trial variability is discarded (only mean amplitude and
%     peak latency are kept), which may itself carry clinically relevant
%     information
%   - The hypothesis-driven nature of the approach means it will not
%     detect effects outside the predefined features - for broader
%     exploration, see Case Study 2 (spectral analysis)
%
% For a full discussion, see Section 4.2 of the companion paper.
%
% Generated for the EEG-NPSY tutorial. All code is self-contained for
% transparency and reproducibility.
