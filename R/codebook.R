.ufc_codebook_both <- function() {
  parts <- list()
  for (w in c("fights", "judge_rounds")) {
    book <- ufc_load_codebook(w)
    if (!"source" %in% names(book)) {
      book$source <- NA_character_
    }
    book$file <- w
    parts[[w]] <- book[, c("file", "column", "group", "meaning", "source", "type", "share_missing", "example")]
  }
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}

ufc_describe <- function(column) {
  book <- .ufc_codebook_both()
  hits <- book[book$column == column, , drop = FALSE]
  if (nrow(hits) == 0L) {
    partial <- book$column[grepl(tolower(column), tolower(book$column), fixed = TRUE)]
    near <- book$column[agrep(column, book$column, max.distance = 0.2)]
    close <- unique(c(partial, near))
    hint <- if (length(close)) paste0(" Similar columns: ", paste(utils::head(close, 8), collapse = ", "), ".") else ""
    stop(column, " is not in the codebook.", hint, call. = FALSE)
  }
  for (i in seq_len(nrow(hits))) {
    row <- hits[i, ]
    source_text <- if (!is.na(row$source) && nzchar(row$source)) paste0("; source: ", row$source) else ""
    cat(sprintf("%s (%s file, %s): %s%s; %s; %.1f%% missing\n", row$column, row$file, row$group, row$meaning, source_text, row$type, 100 * row$share_missing))
  }
  invisible(hits)
}

ufc_search <- function(text) {
  book <- .ufc_codebook_both()
  needle <- tolower(text)
  keep <- grepl(needle, tolower(book$column), fixed = TRUE) | grepl(needle, tolower(book$meaning), fixed = TRUE)
  out <- book[keep, , drop = FALSE]
  rownames(out) <- NULL
  out
}
