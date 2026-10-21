# Mass-univariate partial correlation and cluster-based permutation test,
# used in Case Study 2 (Sections 2.3-2.7).
#
# CAUTION: these functions are a minimal, didactic implementation, written
# only so this tutorial runs in R without extra dependencies. They are NOT
# extensively tested and are NOT a validated or published implementation of
# cluster-based permutation testing. For real analyses use established,
# peer-reviewed tools: MNE-Python (`mne.stats`), FieldTrip, or - in R -
# packages such as `permuco`.

#' Partial-correlation t-map
#'
#' At every channel x frequency point, the partial correlation between
#' log-power and `y`, controlling for `covariates`, converted to a t-value.
#'
#' @param log_power Array [subjects x channels x frequencies].
#' @param y Outcome, one value per subject.
#' @param covariates Data frame (or matrix) of covariates, one row per subject.
#' @return A flat vector, channel-major (index = (ch - 1) * n_freq + freq), the
#'   same ordering as `combine_adjacency()`. Use `flat_to_map()` to reshape.
partial_corr_tmap <- function(log_power, y, covariates) {
  n <- length(y)
  Z <- cbind(1, as.matrix(covariates))
  Z_pinv <- MASS::ginv(Z)
  resid_y <- y - Z %*% (Z_pinv %*% y)
  Y <- matrix(aperm(log_power, c(1, 3, 2)), nrow = n)
  resid_power <- Y - Z %*% (Z_pinv %*% Y)
  num <- as.vector(t(resid_y) %*% resid_power)
  den <- sqrt(sum(resid_y^2)) * sqrt(colSums(resid_power^2))
  r <- pmax(pmin(num / den, 0.999999), -0.999999)
  df <- n - ncol(Z) - 1   # n - intercept - covariates - y
  r * sqrt(df / (1 - r^2))
}

#' Reshape a flat channel-major vector into a [channels x frequencies] matrix
flat_to_map <- function(flat, n_ch, n_freq) t(matrix(flat, nrow = n_freq, ncol = n_ch))

#' Find clusters of neighbouring suprathreshold points
#'
#' Positive and negative clusters are found separately.
#'
#' @param t_flat Flat t-map (from `partial_corr_tmap()`).
#' @param t_thresh Cluster-forming threshold (absolute t-value).
#' @param adjacency Sparse adjacency over the same points (from `combine_adjacency()`).
#' @return A list of clusters, each a list with `members` (indices into
#'   `t_flat`) and `mass` (sum of their t-values).
find_clusters <- function(t_flat, t_thresh, adjacency) {
  clusters <- list()
  for (sign in c(1, -1)) {
    supra <- which((t_flat * sign) > t_thresh)
    if (length(supra) == 0) next
    # build the suprathreshold subgraph straight from the sparse
    # adjacency's own (i, j) triplets, without ever densifying it
    sub_adj <- as(adjacency[supra, supra], "TsparseMatrix")
    el <- cbind(sub_adj@i + 1L, sub_adj@j + 1L)
    el <- el[el[, 1] < el[, 2], , drop = FALSE]
    g <- igraph::make_empty_graph(n = length(supra), directed = FALSE)
    if (nrow(el) > 0) g <- igraph::add_edges(g, as.vector(t(el)))
    comp <- igraph::components(g)
    for (k in seq_len(comp$no)) {
      members <- supra[comp$membership == k]
      clusters[[length(clusters) + 1]] <- list(members = members, mass = sum(t_flat[members]))
    }
  }
  clusters
}

#' Cluster-based permutation test (cluster mass, max-statistic)
#'
#' Shuffles `y` across subjects `n_perm` times; each time, records the
#' largest absolute cluster mass. A cluster's p-value is the fraction of
#' shuffles whose largest cluster was at least as extreme.
#'
#' @param log_power Array [subjects x channels x frequencies].
#' @param y Outcome, one value per subject.
#' @param covariates Data frame of covariates, one row per subject.
#' @param adjacency Sparse adjacency over the (channel x frequency) grid.
#' @param t_thresh Cluster-forming threshold (absolute t-value).
#' @param n_perm Number of permutations.
#' @param seed Random seed, for reproducibility.
#' @return A list: `clusters` (the 5 largest observed clusters, each with
#'   `members`, `mass` and `p_cluster`) and `t_obs` (the observed t-map,
#'   channels x frequencies).
cluster_permutation_test <- function(log_power, y, covariates, adjacency,
                                     t_thresh = 2.028, n_perm = 2000, seed = 1) {
  n_ch <- dim(log_power)[2]
  n_freq <- dim(log_power)[3]
  set.seed(seed)
  t_obs <- partial_corr_tmap(log_power, y, covariates)
  obs_clusters <- find_clusters(t_obs, t_thresh, adjacency)
  obs_clusters <- obs_clusters[order(-abs(sapply(obs_clusters, function(c) c$mass)))]
  n <- length(y)
  null_max <- numeric(n_perm)
  for (i in seq_len(n_perm)) {
    shuffled <- sample(n)
    t_perm <- partial_corr_tmap(log_power, y[shuffled], covariates)
    cl <- find_clusters(t_perm, t_thresh, adjacency)
    null_max[i] <- if (length(cl) == 0) 0 else max(abs(sapply(cl, function(c) c$mass)))
  }
  results <- list()
  top <- obs_clusters[seq_len(min(5, length(obs_clusters)))]
  for (c in top) {
    p <- mean(null_max >= abs(c$mass))
    results[[length(results) + 1]] <- list(members = c$members, mass = c$mass, p_cluster = p)
  }
  list(clusters = results, t_obs = flat_to_map(t_obs, n_ch, n_freq))
}

#' Summarise clusters as a tibble, one row per cluster
#'
#' @param clusters The `clusters` element returned by `cluster_permutation_test()`.
#' @param freqs Frequency axis of the tested data (Hz).
#' @param w_right Right-hemisphere weight of every channel (full montage).
#' @param ch_index_map For each tested channel, its index in the full montage.
#' @param label Name of the analysis, stored in the `Analysis` column.
#' @return A tibble with the cluster's rank, mass, size, frequency range,
#'   mean right-hemisphere weight and p-value.
clusters_to_table <- function(clusters, freqs, w_right, ch_index_map, label) {
  clusters %>%
    imap(function(cl, rank) {
      idx <- arrayInd(cl$members, .dim = c(length(freqs), length(ch_index_map)))
      fi <- idx[, 1]
      ci <- idx[, 2]
      tibble(
        Analysis        = label,
        `Cluster rank`  = rank,
        `Cluster mass`  = cl$mass,
        `N points`      = length(cl$members),
        `Freq min (Hz)` = min(freqs[fi]),
        `Freq max (Hz)` = max(freqs[fi]),
        `Mean w_right`  = mean(w_right[ch_index_map[unique(ci)]]),
        p_cluster       = cl$p_cluster
      )
    }) %>%
    list_rbind()
}
