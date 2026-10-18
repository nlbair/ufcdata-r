ufc_american_to_prob <- function(odds) {
  odds <- as.numeric(odds)
  ifelse(is.na(odds), NA_real_, ifelse(odds > 0, 100 / (odds + 100), -odds / (-odds + 100)))
}

ufc_prob_to_american <- function(prob, rounded = TRUE) {
  prob <- as.numeric(prob)
  odds <- ifelse(is.na(prob), NA_real_, ifelse(prob > 0.5, -100 * prob / (1 - prob), 100 * (1 - prob) / prob))
  if (rounded) round(odds) else odds
}

ufc_overround <- function(odds_1, odds_2) {
  ufc_american_to_prob(odds_1) + ufc_american_to_prob(odds_2)
}

ufc_remove_margin <- function(odds_1, odds_2) {
  p1 <- ufc_american_to_prob(odds_1)
  p2 <- ufc_american_to_prob(odds_2)
  total <- p1 + p2
  list(p1 = p1 / total, p2 = p2 / total)
}

.ufc_diff_columns <- c(
  "age_diff", "reach_diff_cm", "height_diff_cm", "open_prob_diff", "sig_str_landed_diff",
  "total_str_landed_diff", "td_landed_diff", "kd_diff", "ctrl_sec_diff", "head_landed_diff"
)

.ufc_rename <- function(columns, slot) {
  own <- paste0("f", slot)
  opp <- paste0("f", 3 - slot)
  out <- gsub(paste0("(^|_)", own, "(?=_|$)"), "\\1ownTMP", columns, perl = TRUE)
  out <- gsub(paste0("(^|_)", opp, "(?=_|$)"), "\\1oppTMP", out, perl = TRUE)
  out <- gsub("ownTMP", "own", out, fixed = TRUE)
  gsub("oppTMP", "opp", out, fixed = TRUE)
}

ufc_fighter_rows <- function(fights) {
  columns <- names(fights)
  judge_cols <- columns[grepl("^(j[123]_|ufc_j|ded_|judges_)", columns) | columns %in% c("n_judge_cards", "has_round_scores", "n_deductions", "n_deductions_unmapped")]
  side_cols <- setdiff(columns[grepl("(^|_)f[12](_|$)", columns)], judge_cols)
  diff_cols <- intersect(.ufc_diff_columns, columns)
  coded <- intersect(c("winner", "favorite_open"), columns)
  shared <- setdiff(columns, c(side_cols, diff_cols, coded, judge_cols))
  frames <- list()
  for (slot in 1:2) {
    part <- fights[, shared, drop = FALSE]
    for (col in side_cols) {
      part[[.ufc_rename(col, slot)]] <- fights[[col]]
    }
    for (col in diff_cols) {
      part[[col]] <- as.numeric(fights[[col]]) * (if (slot == 1) 1 else -1)
    }
    if ("winner" %in% coded) {
      w <- suppressWarnings(as.numeric(fights$winner))
      part$won <- ifelse(is.na(w), NA_real_, ifelse(w == slot, 1, ifelse(w %in% c(1, 2), 0, NA_real_)))
    }
    if ("favorite_open" %in% coded) {
      f <- suppressWarnings(as.numeric(fights$favorite_open))
      part$is_favorite <- ifelse(is.na(f), NA_real_, as.numeric(f == slot))
    }
    part$slot <- slot
    frames[[slot]] <- part
  }
  out <- do.call(rbind, frames)
  first <- intersect(c("fight_id", "slot"), names(out))
  out <- out[, c(first, setdiff(names(out), first)), drop = FALSE]
  keys <- intersect(c("event_date", "fight_id", "slot"), names(out))
  out <- out[do.call(order, unname(as.list(out[keys]))), , drop = FALSE]
  rownames(out) <- NULL
  out
}

ufc_add_fight_columns <- function(rounds, fights, columns) {
  wanted <- unique(c("fight_id", columns))
  lookup <- fights[!duplicated(fights$fight_id), wanted, drop = FALSE]
  position <- match(rounds$fight_id, lookup$fight_id)
  for (col in setdiff(wanted, "fight_id")) {
    rounds[[col]] <- lookup[[col]][position]
  }
  rounds
}
