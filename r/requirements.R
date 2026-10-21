# R package requirements for the R case studies.
# Install with: Rscript r/requirements.R

options(repos = c(CRAN = "https://cloud.r-project.org"))  # install.packages()
                                                            # has no default
                                                            # mirror in a
                                                            # non-interactive
                                                            # Rscript session

install.packages(c(
  "dplyr",      # data wrangling (joins, filtering, ...)
  "tidyr",      # pivot_longer, drop_na
  "ggplot2",    # all plots
  "patchwork",  # combine ggplot2 panels into one figure
  "car",        # Variance Inflation Factor (car::vif) - Case Study 1
  "psych",      # skewness / kurtosis (psych::skew, psych::kurtosi) - Case Study 1
  "openxlsx",   # Excel export
  "igraph",     # cluster-finding via connected components - Case Study 2
  "IRkernel"    # lets Jupyter (and this site) run R notebooks at all
))

# Matrix and MASS (sparse adjacency matrices, MASS::ginv - Case Study 2) are
# not installed above because they are "recommended" packages that ship
# with every R installation already.
