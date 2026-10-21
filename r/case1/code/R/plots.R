# Plotting helpers used in Case Study 1. Each one returns a ggplot (or a
# patchwork of ggplots), so it can be printed, tweaked with `+`, or saved
# with ggsave().
#
# Written for this tutorial and kept deliberately short, so they are easy to
# read - not extensively tested beyond the data used here.

#' Missing-data matrix: one row per participant, one column per variable
#'
#' @param df A data frame.
#' @return A ggplot; missing cells are highlighted in red.
plot_missingness <- function(df) {
  df %>%
    mutate(across(everything(), is.na), .row = row_number()) %>%
    pivot_longer(-.row, names_to = "variable", values_to = "missing") %>%
    mutate(variable = factor(variable, levels = names(df))) %>%
    ggplot(aes(variable, .row, fill = missing)) +
    geom_tile() +
    scale_fill_manual(values = c(`FALSE` = "grey90", `TRUE` = "firebrick")) +
    labs(title = "Missing data matrix", x = NULL, y = "Participant") +
    theme(axis.text.y = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1))
}

#' Histogram + Q-Q plot for each variable
#'
#' Histograms show the mean (red, dashed) and median (green, dotted). Panels
#' are laid out in blocks of `ncol` variables: a row of histograms followed
#' by a row with the matching Q-Q plots.
#'
#' @param df A data frame.
#' @param vars Names of the numeric columns to plot.
#' @param ncol Number of variables per row.
#' @return A patchwork object.
plot_distributions <- function(df, vars, ncol = 5) {
  hist_panel <- function(var) {
    v <- tibble(value = df[[var]]) %>% drop_na()
    ggplot(v, aes(value)) +
      geom_histogram(bins = 15, fill = "grey70", color = "white") +
      geom_vline(xintercept = mean(v$value), color = "firebrick", linetype = "dashed") +
      geom_vline(xintercept = median(v$value), color = "darkgreen", linetype = "dotted") +
      labs(title = str_glue("{var} (n={nrow(v)})"), x = var, y = "Frequency") +
      theme_minimal(base_size = 9)
  }

  qq_panel <- function(var) {
    v <- tibble(value = df[[var]]) %>% drop_na()
    ggplot(v, aes(sample = value)) +
      stat_qq(size = 1) +
      stat_qq_line(color = "firebrick") +
      labs(title = "Q-Q plot", x = "Theoretical", y = "Sample") +
      theme_minimal(base_size = 9)
  }

  panels <- split(vars, ceiling(seq_along(vars) / ncol)) %>%
    map(~ c(map(.x, hist_panel), map(.x, qq_panel))) %>%
    list_flatten()

  wrap_plots(panels, ncol = ncol)
}

#' Lower-triangle correlation heatmap with significance stars
#'
#' @param cor_tbl Output of `cor_pairs()`: columns `var1`, `var2`, `r`, `p`.
#' @param vars Variable order for the axes.
#' @return A ggplot.
plot_cor_heatmap <- function(cor_tbl, vars) {
  diagonal <- tibble(var1 = vars, var2 = vars, r = 1, p = 1)

  bind_rows(cor_tbl, diagonal) %>%
    mutate(
      stars = case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ ""),
      label = str_c(formatC(r, format = "f", digits = 3), "\n", stars),
      x     = factor(var2, levels = vars),
      y     = factor(var1, levels = rev(vars))
    ) %>%
    ggplot(aes(x, y, fill = r)) +
    geom_tile(color = "white") +
    geom_text(aes(label = label), size = 2.6, lineheight = 0.85) +
    scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                         midpoint = 0, limits = c(-1, 1)) +
    coord_fixed() +
    labs(title = "Pearson correlations  (* p<0.05, ** p<0.01, *** p<0.001)", x = NULL, y = NULL) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

#' Scatter plot with a linear fit and its 95% confidence band
#'
#' @param df A data frame.
#' @param x,y Column names (strings) for the two axes.
#' @return A ggplot, titled with Pearson's r and its p-value.
plot_scatter_lm <- function(df, x, y) {
  v <- df %>% select(all_of(c(x, y))) %>% drop_na()
  ct <- tidy(cor.test(v[[x]], v[[y]]))
  r <- formatC(ct$estimate, format = "f", digits = 3)
  p <- formatC(ct$p.value, format = "f", digits = 4)

  ggplot(v, aes(.data[[x]], .data[[y]])) +
    geom_point(alpha = 0.6, color = "steelblue") +
    geom_smooth(method = "lm", formula = y ~ x,
                color = "#00796B", fill = "#00796B", alpha = 0.15) +
    labs(title = str_glue("{x} vs {y}   r={r}, p={p}"), x = x, y = y)
}

#' Four standard post-hoc diagnostics for a linear model
#'
#' Residuals vs fitted, Q-Q plot of the residuals, Cook's distance (with the
#' 4/n rule-of-thumb line) and the Variance Inflation Factor of each predictor
#' (with the usual 5 and 10 caution lines).
#'
#' @param model A fitted `glm`/`lm` model with at least two predictors.
#' @return A 2 x 2 patchwork object.
plot_model_diagnostics <- function(model) {
  aug <- augment(model) %>% mutate(.index = row_number())
  n <- nobs(model)
  vif_tbl <- car::vif(model) %>% enframe(name = "Predictor", value = "VIF")

  p_resid <- ggplot(aug, aes(.fitted, .resid)) +
    geom_point(alpha = 0.6, color = "steelblue") +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals")

  p_qq <- ggplot(aug, aes(sample = .resid)) +
    stat_qq() +
    stat_qq_line(color = "firebrick") +
    labs(title = "Q-Q plot (residuals)")

  p_cooks <- ggplot(aug, aes(.index, .cooksd)) +
    geom_segment(aes(xend = .index, yend = 0), color = "steelblue") +
    geom_point(color = "steelblue") +
    geom_hline(yintercept = 4 / n, color = "firebrick", linetype = "dashed") +
    labs(title = "Cook's Distance", x = "Participant (row index)", y = "Cook's distance",
         subtitle = str_c("4/n = ", formatC(4 / n, format = "f", digits = 3)))

  p_vif <- ggplot(vif_tbl, aes(VIF, reorder(Predictor, VIF))) +
    geom_col(fill = "steelblue") +
    geom_vline(xintercept = 5, color = "orange", linetype = "dashed") +
    geom_vline(xintercept = 10, color = "firebrick", linetype = "dashed") +
    labs(title = "Variance Inflation Factor", x = "VIF", y = NULL)

  (p_resid + p_qq) / (p_cooks + p_vif)
}
