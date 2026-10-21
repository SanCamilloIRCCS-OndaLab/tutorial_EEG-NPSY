# Scalp topography plot used in Case Study 2 (Sections 2.5 and 2.7).
#
# CAUTION: a simple, didactic stand-in written for this tutorial (a loess
# smoother over the channel values, not a validated interpolation method) -
# not extensively tested. For real analyses use an established tool, e.g.
# `mne.viz.plot_topomap` in Python or the `eegUtils` package in R.

#' Topographic map of one value per channel
#'
#' @param values One value per channel, in the montage's channel order.
#' @param montage A list with `pos_2d` (data frame with columns `x2d`, `y2d`,
#'   one row per channel), `outline` (data frame with columns `x`, `y`,
#'   `part`) and `clip_radius` (head radius in the same units).
#' @param mask Optional logical vector, TRUE for channels to mark with a dot.
#' @param title Plot title.
#' @param vlim Colour limits; defaults to symmetric around 0.
#' @param grid_n Resolution of the interpolation grid.
#' @return A ggplot.
topomap_plot <- function(values, montage, mask = NULL, title = "", vlim = NULL, grid_n = 100) {
  r_max <- montage$clip_radius
  grid <- expand_grid(x2d = seq(-r_max, r_max, length.out = grid_n),
                      y2d = seq(-r_max, r_max, length.out = grid_n))
  fit <- loess(value ~ x2d * y2d,
               data = tibble(x2d = montage$pos_2d$x2d, y2d = montage$pos_2d$y2d, value = values),
               degree = 2, span = 0.35, control = loess.control(surface = "direct"))
  grid <- grid %>%
    mutate(pred = as.vector(predict(fit, newdata = grid))) %>%
    filter(sqrt(x2d^2 + y2d^2) <= r_max)   # keep only the inside of the head

  if (is.null(vlim)) {
    lim <- max(abs(values), na.rm = TRUE)
    vlim <- c(-lim, lim)
  }

  head_outline <- montage$outline %>%
    filter(part %in% c("head", "nose", "ear_left", "ear_right"))

  p <- ggplot() +
    geom_raster(data = grid, aes(x2d, y2d, fill = pred)) +
    scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", midpoint = 0,
                         limits = vlim, oob = scales::squish, na.value = NA, name = "t-value") +
    geom_path(data = head_outline, aes(x, y, group = part), color = "black", linewidth = 0.4) +
    coord_fixed() +
    theme_void() +
    ggtitle(title)

  if (!is.null(mask) && any(mask)) {
    p <- p + geom_point(data = montage$pos_2d[mask, ], aes(x2d, y2d),
                        shape = 16, size = 1.2, color = "black")
  }
  p
}
