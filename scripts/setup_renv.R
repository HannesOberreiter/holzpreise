#!/usr/bin/env Rscript

# Bootstrap project dependencies with renv.

cran_repo <- "https://cloud.r-project.org"
options(repos = c(CRAN = cran_repo))

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
} else {
  deps <- renv::dependencies("DESCRIPTION", progress = FALSE)
  packages <- unique(deps$Package)
  packages <- packages[packages != "R"]

  renv::install(packages, prompt = FALSE, type = "binary")
  renv::snapshot(prompt = FALSE)
}
