# Neighbourhood (adjacency) structure for the cluster-based permutation test
# in Case Study 2 (Section 2.4), as sparse matrices from the `Matrix` package.
#
# CAUTION: written for this tutorial and not extensively tested - see the
# note at the top of cluster_permutation.R.

#' Channel x channel adjacency from a list of neighbouring pairs
#'
#' @param edges A data frame with columns `ch1` and `ch2` (channel names),
#'   one row per pair of neighbouring channels.
#' @param ch_names All channel names, in the order used by the data.
#' @return A symmetric sparse matrix, 1 where two channels are neighbours.
adjacency_from_edges <- function(edges, ch_names) {
  ch_index <- set_names(seq_along(ch_names), ch_names)
  i1 <- ch_index[edges$ch1]
  i2 <- ch_index[edges$ch2]
  n <- length(ch_names)
  sparseMatrix(i = c(i1, i2), j = c(i2, i1), x = 1, dims = c(n, n))
}

#' Frequency x frequency adjacency: each bin neighbours the next one
#'
#' @param nf Number of frequency bins.
#' @return A sparse `nf` x `nf` matrix.
freq_chain_adjacency <- function(nf) {
  sparseMatrix(i = c(1:(nf - 1), 2:nf), j = c(2:nf, 1:(nf - 1)), x = 1, dims = c(nf, nf))
}

#' Adjacency over the whole (channel x frequency) grid
#'
#' Two points are neighbours if they are adjacent channels at the same
#' frequency, or the same channel at adjacent frequency bins - the R
#' equivalent of `mne.stats.combine_adjacency()`. Points are ordered
#' channel-major (all frequencies of channel 1, then channel 2, ...).
#'
#' @param spatial_adj Channel x channel adjacency (e.g. from `adjacency_from_edges()`).
#' @param n_freq Number of frequency bins.
#' @return A sparse (n_channels * n_freq) square matrix.
combine_adjacency <- function(spatial_adj, n_freq) {
  n_ch <- nrow(spatial_adj)
  kronecker(spatial_adj, Diagonal(n_freq)) + kronecker(Diagonal(n_ch), freq_chain_adjacency(n_freq))
}
