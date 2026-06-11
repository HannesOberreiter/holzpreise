# Shared download helpers for fetch scripts.

download_file_with_retries <- function(url, destfile, attempts = 3, timeout_seconds = 300) {
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(timeout_seconds, old_timeout))

  last_error <- NULL

  for (attempt in seq_len(attempts)) {
    message("Downloading ", url, " (attempt ", attempt, "/", attempts, ")")

    last_error <- tryCatch(
      {
        utils::download.file(url, destfile, mode = "wb", quiet = TRUE)
        NULL
      },
      error = identity
    )

    if (is.null(last_error) && file.exists(destfile) && file.info(destfile)$size > 0) {
      return(invisible(destfile))
    }

    if (file.exists(destfile)) {
      unlink(destfile)
    }

    Sys.sleep(5 * attempt)
  }

  stop("Failed to download ", url, ": ", conditionMessage(last_error), call. = FALSE)
}
