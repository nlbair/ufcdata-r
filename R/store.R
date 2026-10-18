ufc_set_data_dir <- function(path = NULL) {
  if (is.null(path)) {
    .ufc$data_dir <- NULL
    return(invisible(NULL))
  }
  if (!dir.exists(path)) {
    stop("The folder does not exist: ", path, call. = FALSE)
  }
  .ufc$data_dir <- normalizePath(path)
  invisible(.ufc$data_dir)
}

ufc_use_version <- function(version) {
  version <- sub("^v", "", trimws(as.character(version)))
  .ufc$version <- version
  .ufc$sums <- NULL
  invisible(version)
}

.ufc_ref <- function() {
  if (identical(.ufc$version, "latest")) "main" else paste0("v", .ufc$version)
}

.ufc_base_url <- function() {
  sub("/+$", "", Sys.getenv("UFCDATA_BASE_URL", unset = ufc_config$base_url))
}

.ufc_cache_root <- function() {
  custom <- Sys.getenv("UFCDATA_CACHE", unset = "")
  if (nzchar(custom)) custom else tools::R_user_dir("ufcdata", which = "cache")
}

.ufc_cache_dir <- function() {
  file.path(.ufc_cache_root(), .ufc_ref())
}

.ufc_local_root <- function() {
  if (!is.null(.ufc$data_dir)) {
    return(.ufc$data_dir)
  }
  custom <- Sys.getenv("UFCDATA_DIR", unset = "")
  if (nzchar(custom)) custom else NULL
}

.ufc_download <- function(url, destination) {
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  partial <- paste0(destination, ".part")
  result <- tryCatch(
    suppressWarnings(utils::download.file(url, partial, mode = "wb", quiet = TRUE)),
    error = function(e) e
  )
  failed <- inherits(result, "error") || !identical(as.integer(result), 0L) || !file.exists(partial)
  if (failed) {
    if (file.exists(partial)) unlink(partial)
    detail <- if (inherits(result, "error")) conditionMessage(result) else "the download did not finish"
    stop(
      "Could not download ", url, " (", detail, "). Check the data version with ufc_use_version(), ",
      "check your internet connection, or download the dataset from https://doi.org/", ufc_config$data_doi,
      " and call ufc_set_data_dir() with the folder.",
      call. = FALSE
    )
  }
  file.rename(partial, destination)
  invisible(destination)
}

.ufc_checksums <- function() {
  if (!is.null(.ufc$sums)) {
    return(.ufc$sums)
  }
  path <- file.path(.ufc_cache_dir(), "data", "SHA256SUMS.txt")
  if (!file.exists(path)) {
    url <- paste0(.ufc_base_url(), "/", .ufc_ref(), "/data/SHA256SUMS.txt")
    got <- tryCatch(.ufc_download(url, path), error = function(e) NULL)
    if (is.null(got)) {
      return(character())
    }
  }
  lines <- trimws(readLines(path, warn = FALSE))
  parts <- strsplit(lines[nzchar(lines)], "[[:space:]]+")
  parts <- parts[vapply(parts, length, integer(1)) == 2L]
  sums <- vapply(parts, function(p) tolower(p[1]), character(1))
  names(sums) <- vapply(parts, function(p) sub("^\\*", "", p[2]), character(1))
  .ufc$sums <- sums
  sums
}

.ufc_find_local <- function(root, subfolder, filename) {
  candidates <- c(file.path(root, subfolder, filename), file.path(root, filename))
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) hit[1] else NULL
}

.ufc_locate <- function(subfolder, filename, required = TRUE) {
  root <- .ufc_local_root()
  if (!is.null(root)) {
    found <- .ufc_find_local(root, subfolder, filename)
    if (!is.null(found)) {
      return(found)
    }
    if (required) {
      stop(filename, " was not found in ", root, call. = FALSE)
    }
    return(NULL)
  }
  destination <- file.path(.ufc_cache_dir(), subfolder, filename)
  if (file.exists(destination)) {
    return(destination)
  }
  url <- paste0(.ufc_base_url(), "/", .ufc_ref(), "/", subfolder, "/", filename)
  message("downloading ", filename, " (first time only) from ", url)
  downloaded <- tryCatch(.ufc_download(url, destination), error = function(e) e)
  if (inherits(downloaded, "error")) {
    if (required) stop(downloaded)
    return(NULL)
  }
  if (identical(subfolder, "data")) {
    expected <- .ufc_checksums()[filename]
    if (length(expected) == 1L && !is.na(expected)) {
      actual <- digest::digest(destination, algo = "sha256", file = TRUE)
      if (!identical(unname(tolower(actual)), unname(expected))) {
        unlink(destination)
        stop(
          filename, " did not match its published checksum, so it was discarded. ",
          "Try again, and if it keeps happening, please report it.",
          call. = FALSE
        )
      }
    }
  }
  destination
}

ufc_clear_cache <- function(all_versions = FALSE) {
  target <- if (all_versions) .ufc_cache_root() else .ufc_cache_dir()
  if (dir.exists(target)) {
    unlink(target, recursive = TRUE)
  }
  .ufc$sums <- NULL
  invisible(target)
}

ufc_info <- function() {
  root <- .ufc_local_root()
  cat("ufcdata ", ufc_config$package_version, "; data version ", .ufc$version, " (git ref ", .ufc_ref(), ")\n", sep = "")
  cat("dataset: https://doi.org/", ufc_config$data_doi, "\n", sep = "")
  if (!is.null(root)) {
    cat("reading from your local folder: ", root, "\n", sep = "")
  } else {
    cat("download source: ", .ufc_base_url(), "\n", sep = "")
    cat("cache folder: ", .ufc_cache_dir(), "\n", sep = "")
    folder <- .ufc_cache_dir()
    files <- if (dir.exists(folder)) list.files(folder, recursive = TRUE) else character()
    if (length(files)) {
      for (f in files) {
        cat("  cached: ", gsub("\\\\", "/", f), " (", round(file.size(file.path(folder, f)) / 1024), " KB)\n", sep = "")
      }
    } else {
      cat("  nothing cached yet\n")
    }
  }
  invisible(NULL)
}
