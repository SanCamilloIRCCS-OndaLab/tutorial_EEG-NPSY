# Reader for NumPy's .npy files, used in Case Study 2 (Section 1.1).
#
# CAUTION: a minimal reader written for this tutorial, covering only the
# files used here - not extensively tested. In your own projects prefer an
# established route, e.g. `reticulate` + numpy, or exporting the data from
# Python to a format R reads natively.

#' Read a NumPy .npy file into an R vector/array
#'
#' Supports only the subset of the format this tutorial needs: format
#' version 1.0/2.0, C (row-major) order, little-endian float32/float64.
#'
#' @param path Path to the .npy file.
#' @return A numeric vector (1-D files) or an array with the same shape and
#'   index order as in NumPy.
read_npy <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  magic <- readBin(con, "raw", n = 6)
  stopifnot(rawToChar(magic[2:6]) == "NUMPY")
  major <- readBin(con, "integer", n = 1, size = 1, signed = FALSE)
  readBin(con, "integer", n = 1, size = 1, signed = FALSE)  # minor version, unused
  header_len <- if (major == 1) {
    readBin(con, "integer", n = 1, size = 2, signed = FALSE, endian = "little")
  } else {
    readBin(con, "integer", n = 1, size = 4, endian = "little")
  }
  header <- rawToChar(readBin(con, "raw", n = header_len))
  stopifnot(!grepl("'fortran_order':\\s*True", header))  # we only handle C order

  shape_str <- regmatches(header, regexpr("(?<=\'shape\':\\s\\()[^)]*", header, perl = TRUE))
  shape <- as.integer(trimws(strsplit(shape_str, ",")[[1]]))
  shape <- shape[!is.na(shape)]
  descr <- regmatches(header, regexpr("(?<=\'descr\':\\s\')[^\']+", header, perl = TRUE))
  size <- if (grepl("f8", descr)) 8 else 4

  vals <- readBin(con, "double", n = prod(shape), size = size, endian = "little")
  if (length(shape) == 1) return(vals)
  # row-major data into a column-major R array: fill with reversed
  # dims, then transpose the axis order back
  aperm(array(vals, dim = rev(shape)), rev(seq_along(shape)))
}
