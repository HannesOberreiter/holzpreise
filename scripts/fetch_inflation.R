#!/usr/bin/env Rscript

# Fetch Austria annual CPI for inflation adjustment.
# Source: Statistik Austria Open Data, Verbraucherpreisindex Basis 1976.

source(file.path("scripts", "helper.R"))

raw_dir <- file.path("data", "raw")
processed_dir <- file.path("data", "processed")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

url <- "https://data.statistik.gv.at/data/OGD_vpi76_VPI_1976_1.csv"
raw_path <- file.path(raw_dir, "statistik_austria_vpi_1976.csv")
download_file_with_retries(url, raw_path)

vpi_raw <- utils::read.csv2(raw_path, stringsAsFactors = FALSE, check.names = FALSE)

cpi <- vpi_raw |>
  subset(`C-VPI1-0` == "VPI-0") |>
  transform(
    jahr = as.integer(sub("^VPIZR-", "", `C-VPIZR-0`)),
    cpi = as.numeric(`F-VPIMZBM`),
    quelle = "Statistik Austria Open Data, Verbraucherpreisindex Basis 1976"
  ) |>
  subset(!is.na(jahr) & !is.na(cpi) & grepl("^VPIZR-[0-9]{4}$", `C-VPIZR-0`)) |>
  subset(select = c(jahr, cpi, quelle))

cpi <- cpi[order(cpi$jahr), ]

out <- file.path(processed_dir, "inflation_austria_cpi.csv")
utils::write.csv(cpi, out, row.names = FALSE)
message("Wrote CPI: ", out)
