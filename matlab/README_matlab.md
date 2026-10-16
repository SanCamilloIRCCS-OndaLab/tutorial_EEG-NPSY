# Matlab

Case Study 1 (`case1/code/CaseStudy_1.m`) is a plain script - run it with
`matlab -batch "run('CaseStudy_1.m')"` from inside `case1/code/`, or open
it in the MATLAB editor and run it directly.

Requirements:

- **MATLAB R2020a or later** (for `exportgraphics`; double-quoted string
  literals need R2017a+, both comfortably covered by any current
  install).
- **Statistics and Machine Learning Toolbox** (for `fitlm`, `tcdf`,
  `tinv`, `norminv`, `qqplot`, `skewness`, `kurtosis`, `corr`).

The script uses MATLAB's own table and model classes throughout -
`readtable`/`writetable` for all CSV I/O (including the mixed
numeric/text `subject_id` column), `fitlm` for the regression models,
`histogram` for distribution plots, and `exportgraphics` for figure
export. `writetable` also writes the same four result tables to a
single `.xlsx` workbook (one sheet per table) with no extra toolbox.

## Two small functions that aren't built-in

Two pieces of this analysis have no MATLAB (or Statistics Toolbox)
built-in equivalent at all:

| Function | What it does | Source |
|---|---|---|
| `swtest.m` | Shapiro-Wilk (and, for leptokurtic samples, Shapiro-Francia) normality test | Ahmed Ben Saïda, MATLAB File Exchange #13964 (2009/2014), vendored as-is |
| `redblue_colormap.m` | A diverging blue-white-red colormap matching the Python/R correlation heatmaps (approximates matplotlib's `RdBu_r`) | Written for this project - MATLAB ships no diverging colormap with this exact look |

Neither base MATLAB nor the Statistics Toolbox ship a Shapiro-Wilk test
(only `kstest`/`lillietest`/`jbtest`/`adtest`), so `swtest.m` is used
instead of writing one from scratch. It implements Royston's AS R94
approximation and was checked against `scipy.stats.shapiro` (which
Python's notebook uses) on this project's data: **7 of the 10
variables match to machine precision**. The remaining three
(`att_matr`, `p300_amp`, `p300_lat`) have sample kurtosis just above 3
(leptokurtic), and `swtest.m` follows Royston's own recommendation to
substitute the Shapiro-Francia test in that case - something
`scipy.stats.shapiro`/R's `shapiro.test` never do. The script labels
which test ran for every variable in its printed output, and the
conclusion (normal vs. not, p > 0.05 in all cases here) is unaffected,
but the exact W/p numbers for those three variables will differ
slightly from the Python/R notebooks. This was a deliberate choice -
see the comment above the normality-test loop in `CaseStudy_1.m` -
rather than an oversight.

`fitlm`'s coefficients, standard errors, p-values (t-distribution,
df = n − k) and R² match the Python (`statsmodels`, fit with
`use_t=True`) and R (`glm(family=gaussian())`) notebooks exactly - all
three languages agree to many decimal places. VIF is computed with the
classic `diag(inv(corrcoef(X)))` formula on the predictor matrix,
algebraically identical to the usual auxiliary-regression definition
and checked against the same reference values.

`swft.m` (a different, unrelated File Exchange submission for the same
test, #88778) was tried first and discarded: it silently depends on
`sumsqr`, a Deep Learning Toolbox function, for a plain sum-of-squares,
which isn't mentioned anywhere on its File Exchange page.

## A couple of MATLAB-specific gotchas hit while writing this

- `table`/`writetable`/`exportgraphics` and other functions that match
  a *parameter name* (e.g. `'VariableNames'`, `'Resolution'`) require
  that name to be a plain char vector (`'VariableNames'`), not a
  double-quoted string (`"VariableNames"`) - the latter can silently be
  treated as positional data instead of a Name-Value pair. Code here
  uses single-quoted chars specifically for every parameter name for
  this reason (double-quoted strings elsewhere are fine, e.g. for plain
  text or as regular data).
- `[char_var ".ext"]` (bracket concatenation with a double-quoted
  string literal and no comma) does **not** concatenate the text - it
  builds a 2-element string array. Use `[char_var '.ext']` (both
  single-quoted) or `strcat`/`sprintf` instead.
