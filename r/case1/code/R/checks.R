# Data-quality checks used in Case Study 1 (Sections 1.2 and 1.5).
#
# Written for this tutorial and kept deliberately short, so they are easy to
# read - not extensively tested beyond the data used here.

#' Count values outside an expected range
#'
#' @param df A data frame.
#' @param ranges A tibble with columns `variable`, `min` and `max`.
#' @return The `ranges` tibble (restricted to variables present in `df`) with
#'   the number of values below `min` and above `max`, and an `ok` flag.
#'   Missing values are ignored.
check_ranges <- function(df, ranges) {
  ranges %>%
    filter(variable %in% names(df)) %>%
    mutate(
      n_below = map2_int(variable, min, ~ sum(df[[.x]] < .y, na.rm = TRUE)),
      n_above = map2_int(variable, max, ~ sum(df[[.x]] > .y, na.rm = TRUE)),
      ok      = n_below == 0 & n_above == 0
    )
}

#' Flag values more than `threshold` standard deviations from the mean
#'
#' @param df A data frame.
#' @param vars Names of the numeric columns to check.
#' @param threshold Absolute z-score above which a value is flagged.
#' @param id Name of the participant identifier column.
#' @return A long tibble with one row per flagged value: the participant id,
#'   the variable, its value and its z-score. Missing values are ignored when
#'   computing the mean and SD.
flag_outliers_z <- function(df, vars, threshold = 3, id = "subject_id") {
  df %>%
    select(all_of(c(id, vars))) %>%
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>%
    group_by(variable) %>%
    mutate(z = (value - mean(value, na.rm = TRUE)) / sd(value, na.rm = TRUE)) %>%
    ungroup() %>%
    filter(abs(z) > threshold) %>%
    arrange(factor(variable, levels = vars))
}
