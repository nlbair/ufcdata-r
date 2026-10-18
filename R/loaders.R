.ufc_check_fmt <- function(fmt) {
  if (!fmt %in% c("auto", "csv", "parquet")) {
    stop("fmt must be auto, csv, or parquet", call. = FALSE)
  }
}

.ufc_read_csv <- function(path) {
  if (requireNamespace("readr", quietly = TRUE)) {
    return(as.data.frame(readr::read_csv(path, show_col_types = FALSE, progress = FALSE, guess_max = 100000)))
  }
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

.ufc_read_table <- function(key, fmt) {
  .ufc_check_fmt(fmt)
  spec <- .ufc_tables[[key]]
  want_parquet <- spec$parquet && (identical(fmt, "parquet") || (identical(fmt, "auto") && requireNamespace("arrow", quietly = TRUE)))
  if (want_parquet) {
    path <- .ufc_locate("data", paste0(spec$stem, ".parquet"), required = identical(fmt, "parquet"))
    if (!is.null(path)) {
      return(as.data.frame(arrow::read_parquet(path)))
    }
  }
  .ufc_read_csv(.ufc_locate("data", paste0(spec$stem, ".csv")))
}

.ufc_dates <- function(frame, parse_dates) {
  if (parse_dates && "event_date" %in% names(frame)) {
    frame$event_date <- as.Date(frame$event_date)
  }
  frame
}

ufc_load_fights <- function(decisions_only = FALSE, fmt = "auto", parse_dates = TRUE) {
  frame <- .ufc_dates(.ufc_read_table("fights", fmt), parse_dates)
  if (decisions_only) {
    frame <- frame[frame$is_decision %in% c(TRUE, "True", "TRUE"), , drop = FALSE]
    rownames(frame) <- NULL
  }
  frame
}

ufc_load_judge_rounds <- function(fmt = "auto", parse_dates = TRUE) {
  .ufc_dates(.ufc_read_table("judge_rounds", fmt), parse_dates)
}

ufc_load_crosswalk <- function() {
  .ufc_read_table("crosswalk", "csv")
}

ufc_load_judges <- function() {
  .ufc_read_table("judges", "csv")
}

ufc_load_jurisdictions <- function() {
  .ufc_read_table("jurisdictions", "csv")
}

ufc_load_codebook <- function(which = "fights") {
  if (!which %in% names(.ufc_codebooks)) {
    stop("which must be fights, judge_rounds, or other", call. = FALSE)
  }
  path <- .ufc_locate("codebook", .ufc_codebooks[[which]])
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}
