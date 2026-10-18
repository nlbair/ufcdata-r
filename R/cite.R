ufc_citation <- function() {
  paste0(
    ufc_config$author, " (", ufc_config$year, "). ", ufc_config$title, " (Version ", .ufc$version,
    ") [Data set]. Zenodo. https://doi.org/", ufc_config$data_doi
  )
}

ufc_cite <- function() {
  text <- ufc_citation()
  cat(text, "\n", ufc_config$disclaimer, "\n", sep = "")
  invisible(text)
}
