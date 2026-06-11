#!/usr/bin/env Rscript

# Fetch wood price datasets from preise.agrarforschung.at.
# API-backed pages for Austria-wide wood price analytics.

library(tidyverse)
library(jsonlite)

raw_dir <- file.path("data", "raw", "agrarforschung")
processed_dir <- file.path("data", "processed")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

base_url <- "https://preise.agrarforschung.at/api/getcontent"

bundesland_labels <- c(
  saegerundholz_bgld = "Burgenland",
  saegerundholz_ktn = "Kärnten",
  saegerundholz_noe = "Niederösterreich",
  saegerundholz_ooe = "Oberösterreich",
  saegerundholz_sbg = "Salzburg",
  saegerundholz_stmk = "Steiermark",
  saegerundholz_t = "Tirol",
  saegerundholz_vbg = "Vorarlberg",
  industrierundholz_bgld = "Burgenland",
  industrierundholz_ktn = "Kärnten",
  industrierundholz_noe = "Niederösterreich",
  industrierundholz_ooe = "Oberösterreich",
  industrierundholz_sbg = "Salzburg",
  industrierundholz_stmk = "Steiermark",
  industrierundholz_t = "Tirol",
  industrierundholz_vbg = "Vorarlberg",
  brennholz_bgld = "Burgenland",
  brennholz_ktn = "Kärnten",
  brennholz_noe = "Niederösterreich",
  brennholz_ooe = "Oberösterreich",
  brennholz_sbg = "Salzburg",
  brennholz_stmk = "Steiermark",
  brennholz_t = "Tirol",
  brennholz_vbg = "Vorarlberg"
)

sources <- tribble(
  ~content_id, ~gruppe, ~seite,
  "saegeholz_monatl", "Inlandspreise Holz", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_monatl", "Inlandspreise Holz", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "brennholz_monatl", "Inlandspreise Energieholz", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "energieholzkodex", "Inlandspreise Energieholz", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "pellets", "Inlandspreise Pellets", "https://preise.agrarforschung.at/content/inlandspreise-fuer-pellets",
  "holzprodukte", "Exportpreise Holzprodukte", "https://preise.agrarforschung.at/content/exportpreise-fuer-holz-produkte",
  "schnittholz_chicago", "Internationale Schnittholzpreise", "https://preise.agrarforschung.at/content/internationale-preise-fuer-schnittholz",
  "schnittholz_schwedische_kiefer", "Internationale Schnittholzpreise", "https://preise.agrarforschung.at/content/internationale-preise-fuer-schnittholz",
  "diesel_woechentl", "Betriebsmittel Diesel", "https://preise.agrarforschung.at/content/diesel",
  "saegerundholz_bgld", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_ktn", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_noe", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_ooe", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_sbg", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_stmk", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_t", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "saegerundholz_vbg", "Sägerundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_bgld", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_ktn", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_noe", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_ooe", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_sbg", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_stmk", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_t", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "industrierundholz_vbg", "Industrierundholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-holz",
  "brennholz_bgld", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_ktn", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_noe", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_ooe", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_sbg", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_stmk", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_t", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz",
  "brennholz_vbg", "Brennholz und Energieholz Bundesländer", "https://preise.agrarforschung.at/content/inlandspreise-fuer-energieholz"
)

fetch_one <- function(content_id) {
  url <- str_c(base_url, "?contentId=", content_id)
  raw_path <- file.path(raw_dir, str_c(content_id, ".json"))
  download.file(url, raw_path, mode = "wb", quiet = TRUE)
  payload <- fromJSON(raw_path, flatten = TRUE)
  if (!is.null(payload$error)) {
    stop(str_c("API error for ", content_id, ": ", payload$error))
  }
  payload$data
}

clean_html_text <- function(x) {
  x |>
    str_replace_all("<[^>]+>", "") |>
    str_replace_all("\\s+", " ") |>
    str_trim()
}

parse_one <- function(content_id, gruppe, seite) {
  data <- fetch_one(content_id)
  records <- as_tibble(data$records)

  attrs <- enframe(data$attributes, name = "attr_code", value = "attr") |>
    mutate(sortiment = map_chr(attr, ~ .x$name %||% attr_code)) |>
    select(attr_code, sortiment)

  areas <- enframe(data$areas, name = "area_code", value = "area") |>
    mutate(region = map_chr(area, ~ .x$name %||% area_code)) |>
    select(area_code, region)

  records |>
    mutate(
      content_id = content_id,
      gruppe = gruppe,
      titel = data$title %||% content_id,
      untertitel = data$subtitle %||% NA_character_,
      quelle = clean_html_text(data$source %||% NA_character_),
      url = seite,
      datum = as.Date(ts_start),
      jahr = as.integer(format(datum, "%Y")),
      monat = as.integer(format(datum, "%m")),
      preis = as.numeric(value),
      attr_code_merge = if ("attr_code_merge" %in% names(records)) attr_code_merge else attr_code
    ) |>
    left_join(attrs, by = "attr_code") |>
    left_join(areas, by = "area_code") |>
    transmute(
      content_id,
      gruppe,
      titel,
      untertitel,
      datum,
      jahr,
      monat,
      region = coalesce(bundesland_labels[content_id], region, area_code),
      sortiment = coalesce(sortiment, attr_code),
      attr_code,
      attr_code_merge = coalesce(attr_code_merge, attr_code),
      area_code,
      preis,
      einheit = unit_name,
      quelle,
      url
    ) |>
    arrange(gruppe, titel, sortiment, region, datum)
}

prices <- pmap_dfr(sources, parse_one)

monthly_path <- file.path(processed_dir, "agrarforschung_prices_monthly.csv")
write_csv(prices, monthly_path)

annual <- prices |>
  summarise(
    preis = mean(preis, na.rm = TRUE),
    monate = n_distinct(monat),
    vollstaendiges_jahr = monate == 12,
    .by = c(content_id, gruppe, titel, region, sortiment, attr_code, attr_code_merge, area_code, einheit, quelle, url, jahr)
  ) |>
  arrange(gruppe, titel, sortiment, region, jahr)

annual_path <- file.path(processed_dir, "agrarforschung_prices_annual.csv")
write_csv(annual, annual_path)

manifest <- sources |>
  mutate(
    raw_file = file.path("data", "raw", "agrarforschung", str_c(content_id, ".json")),
    fetched_at = as.character(Sys.time())
  )
write_csv(manifest, file.path(raw_dir, "manifest.csv"))

message("Wrote ", nrow(prices), " monthly rows to ", monthly_path)
message("Wrote ", nrow(annual), " annual rows to ", annual_path)
