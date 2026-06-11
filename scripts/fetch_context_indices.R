#!/usr/bin/env Rscript

# Fetch context indices that help interpret timber prices:
# - consumer energy price indices from Statistik Austria VPI 2020 COICOP18
# - wood/wood-product producer and wholesale indices from Statistik Austria

library(tidyverse)

raw_dir <- file.path("data", "raw")
processed_dir <- file.path("data", "processed")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

download_csv <- function(url, path) {
  utils::download.file(url, path, mode = "wb", quiet = TRUE)
  path
}

parse_year_month <- function(code, prefix) {
  value <- str_remove(code, str_c("^", prefix, "-"))
  tibble(
    jahr = as.integer(str_sub(value, 1, 4)),
    monat = as.integer(str_sub(value, 5, 6))
  )
}

# VPI energy components -------------------------------------------------------

vpi_url <- "https://data.statistik.gv.at/data/OGD_vpi20c18_VPI_2020COICOP18_1.csv"
vpi_raw_path <- file.path(raw_dir, "statistik_austria_vpi_2020_coicop18.csv")
download_csv(vpi_url, vpi_raw_path)

vpi_raw <- read_csv2(vpi_raw_path, show_col_types = FALSE)

energy_codes <- tribble(
  ~code, ~reihe,
  "VPICOICOP18-SE000", "Energie gesamt",
  "VPICOICOP18-04510", "Strom",
  "VPICOICOP18-04521", "Gas",
  "VPICOICOP18-04530", "Flüssige Brennstoffe",
  "VPICOICOP18-04542", "Brennholz inkl. Pellets und Briketts"
)

energy_indices_monthly <- vpi_raw |>
  filter(`C-VPICOICOP18_5-0` %in% energy_codes$code) |>
  mutate(
    vpizr = str_remove(`C-VPIZR-0`, "^VPIZR-"),
    jahr = as.integer(str_sub(vpizr, 1, 4)),
    monat = as.integer(str_sub(vpizr, 5, 6))
  ) |>
  transmute(
    jahr,
    monat,
    code = `C-VPICOICOP18_5-0`,
    index = as.numeric(`F-VPIMZBM`),
    quelle = "Statistik Austria VPI 2020 COICOP18"
  ) |>
  left_join(energy_codes, by = "code") |>
  select(jahr, monat, reihe, index, quelle)

energy_indices_annual <- energy_indices_monthly |>
  filter(!is.na(monat)) |>
  summarise(
    index = mean(index, na.rm = TRUE),
    monate = n_distinct(monat),
    vollstaendiges_jahr = monate == 12,
    .by = c(jahr, reihe, quelle)
  ) |>
  arrange(reihe, jahr)

write_csv(energy_indices_monthly, file.path(processed_dir, "energy_price_indices_monthly.csv"))
write_csv(energy_indices_annual, file.path(processed_dir, "energy_price_indices_annual.csv"))

# Producer price index: wood products ----------------------------------------

epi_url <- "https://data.statistik.gv.at/data/OGD_epi2021cpa15_EPI_2021_OECPA_1.csv"
epi_raw_path <- file.path(raw_dir, "statistik_austria_epi_2021_oecpa.csv")
download_csv(epi_url, epi_raw_path)

epi_raw <- read_csv2(epi_raw_path, show_col_types = FALSE)

epi_wood <- epi_raw |>
  mutate(
    epia10 = str_remove(`C-EPIA10-0`, "^EPIA10-"),
    jahr = as.integer(str_sub(epia10, 1, 4)),
    monat = as.integer(str_sub(epia10, 5, 6))
  ) |>
  transmute(
    jahr,
    monat,
    reihe = "Erzeugerpreisindex: Holz, Holz- und Korkwaren",
    index = as.numeric(`F-CPAPRP-12`),
    quelle = "Statistik Austria Erzeugerpreisindex 2021 ÖCPA"
  ) |>
  filter(!is.na(index))

# Wholesale price index: raw wood and semi-finished wood ----------------------

ghpi_url <- "https://data.statistik.gv.at/data/OGD_pregpi003_GHPI_20_1.csv"
ghpi_raw_path <- file.path(raw_dir, "statistik_austria_ghpi_2020.csv")
download_csv(ghpi_url, ghpi_raw_path)

ghpi_raw <- read_csv2(ghpi_raw_path, show_col_types = FALSE)

ghpi_wood <- ghpi_raw |>
  filter(`C-SDB_CPA20-0` == "SDB_CPA20-467311") |>
  mutate(
    a10 = str_remove(`C-A10-0`, "^A10-"),
    jahr = as.integer(str_sub(a10, 1, 4)),
    monat = as.integer(str_sub(a10, 5, 6))
  ) |>
  transmute(
    jahr,
    monat,
    reihe = "Großhandelspreisindex: Rohholz und Holzhalbwaren",
    index = as.numeric(`F-GPI20`),
    quelle = "Statistik Austria Großhandelspreisindex 2020"
  ) |>
  filter(!is.na(index))

wood_product_indices_monthly <- bind_rows(epi_wood, ghpi_wood) |>
  arrange(reihe, jahr, monat)

wood_product_indices_annual <- wood_product_indices_monthly |>
  filter(!is.na(monat)) |>
  summarise(
    index = mean(index, na.rm = TRUE),
    monate = n_distinct(monat),
    vollstaendiges_jahr = monate == 12,
    .by = c(jahr, reihe, quelle)
  ) |>
  arrange(reihe, jahr)

write_csv(wood_product_indices_monthly, file.path(processed_dir, "wood_product_indices_monthly.csv"))
write_csv(wood_product_indices_annual, file.path(processed_dir, "wood_product_indices_annual.csv"))

message("Wrote context indices to data/processed/.")
