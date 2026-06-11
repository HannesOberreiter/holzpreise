# Shared helpers for fetch scripts.
#
# Some public data endpoints, especially Statistik Austria OGD, can be slow or
# flaky from GitHub Actions. R's default download.file() may hang until timeout
# there. Prefer curl CLI with IPv4, explicit timeouts, redirect handling, and a
# simple User-Agent; fall back to R/libcurl only if curl CLI fails.

has_non_empty_file <- function(path) {
  file.exists(path) && file.info(path)$size > 0
}

download_with_curl_cli <- function(url, destfile, timeout_seconds) {
  if (Sys.which("curl") == "") {
    stop("curl command not available", call. = FALSE)
  }

  args <- c(
    "--fail",
    "--location",
    "--silent",
    "--show-error",
    "--ipv4",
    "--connect-timeout", "30",
    "--max-time", as.character(timeout_seconds),
    "--user-agent", "holzpreise.at-data-fetch",
    "--output", destfile,
    url
  )

  status <- system2("curl", args = args)
  if (!identical(status, 0L)) {
    stop("curl failed with exit status ", status, call. = FALSE)
  }
}

download_with_r <- function(url, destfile, timeout_seconds) {
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(timeout_seconds, old_timeout))

  utils::download.file(
    url,
    destfile,
    mode = "wb",
    quiet = TRUE,
    method = "libcurl",
    headers = c("User-Agent" = "holzpreise.at-data-fetch")
  )
}

download_file_with_retries <- function(url, destfile, attempts = 3, timeout_seconds = 300) {
  last_error <- NULL

  for (attempt in seq_len(attempts)) {
    message("Downloading ", url, " (attempt ", attempt, "/", attempts, ")")

    last_error <- tryCatch(
      {
        download_with_curl_cli(url, destfile, timeout_seconds)
        NULL
      },
      error = function(curl_error) {
        tryCatch(
          {
            download_with_r(url, destfile, timeout_seconds)
            NULL
          },
          error = function(r_error) {
            structure(
              list(message = paste(conditionMessage(curl_error), conditionMessage(r_error), sep = "; ")),
              class = c("download_error", "error", "condition")
            )
          }
        )
      }
    )

    if (is.null(last_error) && has_non_empty_file(destfile)) {
      return(invisible(destfile))
    }

    if (file.exists(destfile)) {
      unlink(destfile)
    }

    Sys.sleep(5 * attempt)
  }

  stop("Failed to download ", url, ": ", conditionMessage(last_error), call. = FALSE)
}
