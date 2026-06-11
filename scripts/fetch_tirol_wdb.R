#!/usr/bin/env Rscript

# Fetch Tirol Walddatenbank public pages.
# These pages contain machine-readable HTML tables for RUPI/BHI indices.

raw_dir <- file.path("data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

now_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

sources <- data.frame(
  source_id = c(
    "tirol_holzpreise_info",
    "tirol_wdb_holzpreistabelle_params",
    "tirol_wdb_rupi_quartal",
    "tirol_wdb_rupi_monat",
    "tirol_wdb_bhi_quartal",
    "tirol_wdb_bhi_jahr"
  ),
  title = c(
    "Land Tirol Holzmarktbericht, Preistabellen und Holzpreisindex",
    "Tirol Walddatenbank Holzpreistabelle Parameter",
    "Tirol Walddatenbank RUPI Quartal",
    "Tirol Walddatenbank RUPI Monat",
    "Tirol Walddatenbank BHI Quartal",
    "Tirol Walddatenbank BHI Jahr"
  ),
  url = c(
    "https://www.tirol.gv.at/umwelt/wald/holzmarkt/holzpreise/",
    "https://wdb.tirol.gv.at/public/holzPreisBerichtParams.xhtml",
    "https://wdb.tirol.gv.at/public/rupiQuartal.xhtml",
    "https://wdb.tirol.gv.at/public/rupiMonat.xhtml",
    "https://wdb.tirol.gv.at/public/bhiQuartal.xhtml",
    "https://wdb.tirol.gv.at/public/bhiJahr.xhtml"
  ),
  local_file = c(
    "tirol_holzpreise_info.html",
    "tirol_wdb_holzpreistabelle_params.html",
    "tirol_wdb_rupi_quartal.html",
    "tirol_wdb_rupi_monat.html",
    "tirol_wdb_bhi_quartal.html",
    "tirol_wdb_bhi_jahr.html"
  ),
  fetched_at_utc = now_utc,
  status = NA_character_,
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(sources))) {
  target <- file.path(raw_dir, sources$local_file[[i]])
  sources$status[[i]] <- tryCatch({
    utils::download.file(sources$url[[i]], target, mode = "wb", quiet = TRUE)
    "downloaded"
  }, error = function(e) {
    paste("failed:", conditionMessage(e))
  })
}

out <- file.path(raw_dir, "tirol_wdb_manifest.csv")
utils::write.csv(sources, out, row.names = FALSE)
message("Wrote Tirol WDB manifest: ", out)
