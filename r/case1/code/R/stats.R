# Small statistical helpers used in Case Study 1 (Sections 2.2 and 3.2).
#
# Written for this tutorial and kept deliberately short, so they are easy to
# read - not extensively tested beyond the data used here.

#' Pearson correlation for every pair of variables
#'
#' Only participants with no missing value in any of `vars` are used, so all
#' pairs are computed on the same sample.
#'
#' @param df A data frame.
#' @param vars Names of the numeric columns to correlate.
#' @return A tibble with one row per unique pair (`var1` comes before `var2`
#'   in `vars`), the correlation `r` and its p-value `p`.
cor_pairs <- function(df, vars) {
  complete <- df %>%
    select(all_of(vars)) %>%
    drop_na()

  expand_grid(i = seq_along(vars), j = seq_along(vars)) %>%
    filter(i < j) %>%
    mutate(
      var1 = vars[i],
      var2 = vars[j],
      test = map2(var1, var2, ~ tidy(cor.test(complete[[.x]], complete[[.y]])))
    ) %>%
    unnest(test) %>%
    select(var1, var2, r = estimate, p = p.value)
}

#' Regression coefficients as a report-ready table
#'
#' Same as `broom::tidy()`, plus 95% Wald confidence intervals (estimate
#' +/- 1.96 SE, i.e. what `confint.default()` returns) and a significance flag,
#' with column names matching the tables exported by the Python and Matlab
#' versions of this case study.
#'
#' @param model A fitted `glm` (or `lm`) model.
#' @param outcome A label for the model, stored in the `Outcome` column.
#' @return A tibble with one row per coefficient.
tidy_glm_wald <- function(model, outcome) {
  z <- qnorm(0.975)
  tidy(model) %>%
    transmute(
      Outcome                = outcome,
      Predictor              = term,
      Estimate               = estimate,
      `Std. Error`           = std.error,
      `p-value`              = p.value,
      CI_lower               = estimate - z * std.error,
      CI_upper               = estimate + z * std.error,
      `Significant (p<0.05)` = p.value < 0.05
    )
}
