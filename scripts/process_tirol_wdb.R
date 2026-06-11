#!/usr/bin/env Rscript

# Process public Tirol Walddatenbank index tables from raw HTML.
# Raw files are downloaded by scripts/fetch_raw.sh.

raw_dir <- file.path("data", "raw")
processed_dir <- file.path("data", "processed")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

parse_number <- function(x) {
  x <- gsub("\u00a0", "", x, fixed = TRUE)
  x <- gsub(" ", "", x, fixed = TRUE)
  x <- gsub(".", "", x, fixed = TRUE)
  x <- gsub(",", ".", x, fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

strip_tags <- function(x) {
  x <- gsub("<[^>]+>", " ", x)
  x <- gsub("&nbsp;", " ", x, fixed = TRUE)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&auml;", "ä", x, fixed = TRUE)
  x <- gsub("&Auml;", "Ä", x, fixed = TRUE)
  x <- gsub("&ouml;", "ö", x, fixed = TRUE)
  x <- gsub("&Ouml;", "Ö", x, fixed = TRUE)
  x <- gsub("&uuml;", "ü", x, fixed = TRUE)
  x <- gsub("&Uuml;", "Ü", x, fixed = TRUE)
  x <- gsub("&szlig;", "ß", x, fixed = TRUE)
  trimws(gsub("\\s+", " ", x))
}

extract_table <- function(path, source_id, index_name, frequency) {
  html <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  header_match <- regmatches(html, regexpr("<thead[\\s\\S]*?</thead>", html, perl = TRUE))
  body_match <- regmatches(html, regexpr("<tbody[^>]*class=\"ui-datatable-data[\\s\\S]*?</tbody>", html, perl = TRUE))

  if (!length(header_match) || !length(body_match)) {
    return(data.frame())
  }

  headers <- regmatches(header_match, gregexpr("<span class=\"ui-column-title\">[\\s\\S]*?</span>", header_match, perl = TRUE))[[1]]
  headers <- vapply(headers, strip_tags, character(1))

  rows <- regmatches(body_match, gregexpr("<tr[\\s\\S]*?</tr>", body_match, perl = TRUE))[[1]]
  parsed <- lapply(rows, function(row) {
    cells <- regmatches(row, gregexpr("<td[\\s\\S]*?</td>", row, perl = TRUE))[[1]]
    vapply(cells, strip_tags, character(1))
  })

  parsed <- parsed[vapply(parsed, length, integer(1)) == length(headers)]
  if (!length(parsed)) {
    return(data.frame())
  }

  table <- as.data.frame(do.call(rbind, parsed), stringsAsFactors = FALSE)
  names(table) <- headers

  periode <- if ("Quartal" %in% names(table)) {
    table$Quartal
  } else if ("Monat" %in% names(table)) {
    table$Monat
  } else {
    rep(NA_character_, nrow(table))
  }

  out <- data.frame(
    quelle = source_id,
    index = index_name,
    frequenz = frequency,
    jahr = as.integer(table$Jahr),
    periode = periode,
    index_prozent = parse_number(table[["Index [%]"]]),
    durchschnitt_eur_fm = parse_number(table[["Durchschnitt [Euro/fm]"]]),
    menge_fm = parse_number(table[["Menge [fm]"]]),
    partien = parse_number(table$Partien),
    aenderung_prozent = if ("Änderung [%]" %in% names(table)) parse_number(table[["Änderung [%]"]]) else NA_real_,
    stringsAsFactors = FALSE
  )

  out[order(out$jahr, out$periode), ]
}

sources <- list(
  list(file = "tirol_wdb_rupi_quartal.html", source = "Tirol Walddatenbank RUPI Quartal", index = "RUPI-Tirol", frequency = "Quartal"),
  list(file = "tirol_wdb_rupi_monat.html", source = "Tirol Walddatenbank RUPI Monat", index = "RUPI-Tirol", frequency = "Monat"),
  list(file = "tirol_wdb_bhi_quartal.html", source = "Tirol Walddatenbank BHI Quartal", index = "BHI-Tirol", frequency = "Quartal"),
  list(file = "tirol_wdb_bhi_jahr.html", source = "Tirol Walddatenbank BHI Jahr", index = "BHI-Tirol", frequency = "Jahr")
)

required_files <- file.path(raw_dir, vapply(sources, `[[`, character(1), "file"))
missing_files <- required_files[!file.exists(required_files) | file.info(required_files)$size == 0]

if (length(missing_files) > 0) {
  stop(
    "Missing raw Tirol files: ",
    paste(missing_files, collapse = ", "),
    ". Run: scripts/fetch_raw.sh",
    call. = FALSE
  )
}

rows <- lapply(sources, function(source) {
  path <- file.path(raw_dir, source$file)
  extract_table(path, source$source, source$index, source$frequency)
})

indices <- do.call(rbind, rows)

out <- file.path(processed_dir, "tirol_wdb_indices.csv")
utils::write.csv(indices, out, row.names = FALSE)
message("Wrote Tirol WDB indices: ", out)
