.ufc <- new.env(parent = emptyenv())
.ufc$version <- "0.1.1"
.ufc$data_dir <- NULL
.ufc$sums <- NULL

ufc_config <- list(
  package_version = "0.1.1",
  data_doi = "10.5281/zenodo.23458636",
  base_url = "https://raw.githubusercontent.com/nlbair/ufc-data",
  title = "UFC Data: scorecards, round statistics, and betting odds, 2013 to 2026",
  author = "Bair, N.",
  year = 2026,
  disclaimer = "This project is independent. It is not affiliated with, endorsed by, or sponsored by the UFC."
)

.ufc_tables <- list(
  fights = list(stem = "ufc_all_fights_wide", parquet = TRUE),
  judge_rounds = list(stem = "ufc_judge_rounds", parquet = TRUE),
  crosswalk = list(stem = "id_crosswalk_all", parquet = FALSE),
  judges = list(stem = "judge_names", parquet = FALSE),
  jurisdictions = list(stem = "jurisdiction_lookup", parquet = FALSE)
)

.ufc_codebooks <- c(
  fights = "codebook_fights_wide.csv",
  judge_rounds = "codebook_judge_rounds.csv",
  other = "codebook_other_files.csv"
)
