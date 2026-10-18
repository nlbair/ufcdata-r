# ufcdata

An R package for loading [UFC Data](https://github.com/nlbair/ufc-data): every UFC fight from February 2013 through October 10, 2026, with judges' round-by-round scorecards, round statistics, betting odds, rankings at fight time, and fighter attributes.

> This project is independent. It is not affiliated with, endorsed by, or sponsored by the UFC.

The package downloads the published data the first time you use it, checks it against the published checksums, and keeps a copy on your computer. It does not include the code used to collect the data. A Python version is at https://github.com/nlbair/ufcdata-py.

## Install

```r
install.packages("remotes")
remotes::install_github("nlbair/ufcdata-r")
```

For faster loading, also install `readr`, and `arrow` for smaller downloads:

```r
install.packages(c("readr", "arrow"))
```

## Quick start

```r
library(ufcdata)

fights <- ufc_load_fights()
rounds <- ufc_load_judge_rounds()

ufc_describe("f1_open_prob_novig")
ufc_search("control time")

fighters <- ufc_fighter_rows(fights)
```

All functions start with `ufc_`, so they will not mask other packages.

## What you can load

| Function | Returns |
| --- | --- |
| `ufc_load_fights(decisions_only = FALSE)` | One row per fight, 495 columns |
| `ufc_load_judge_rounds()` | One row per judge per round, 69 columns |
| `ufc_load_crosswalk()` | Source IDs and match quality for each fight |
| `ufc_load_judges()` | Judges by MMA Decisions ID |
| `ufc_load_jurisdictions()` | Event location to jurisdiction table |
| `ufc_load_codebook("fights")` | What every column means (also `"judge_rounds"`, `"other"`) |

## Helpers

| Function | What it does |
| --- | --- |
| `ufc_describe(column)` | Prints what a column means, where it comes from, and how much is missing |
| `ufc_search(text)` | Finds columns by name or meaning |
| `ufc_fighter_rows(fights)` | One row per fighter per fight, with `own_` and `opp_` columns, `won`, and `is_favorite` |
| `ufc_add_fight_columns(rounds, fights, columns)` | Adds fight-level columns to the judge-round table |
| `ufc_american_to_prob(odds)` | Implied probability from an American moneyline |
| `ufc_prob_to_american(p)` | American moneyline from a probability |
| `ufc_remove_margin(odds_1, odds_2)` | List with win probabilities `p1` and `p2`, bookmaker margin removed |
| `ufc_overround(odds_1, odds_2)` | Sum of the two implied probabilities |
| `ufc_cite()` | Prints the citation for the dataset (`ufc_citation()` returns it as text) |
| `ufc_info()` | Shows the data version and where files are stored |
| `ufc_clear_cache()` | Deletes the downloaded copy |

`ufc_fighter_rows` leaves out the judge columns. Use the judge-round table for those.

## Data versions

By default the package uses version 0.1.0 of the data. Use `ufc_use_version("latest")` for the newest, or a version number to pin an analysis to a release.

## Working offline

Download the dataset from https://doi.org/10.5281/zenodo.23458636, unzip it, and point the package at the folder:

```r
ufc_set_data_dir("C:/path/to/ufc-data")
```

## Citing

Please cite the dataset, not just the package. `ufc_cite()` prints the citation. The data come from ufcstats.com, MMA Decisions, BestFightOdds, and public archives of the UFC rankings, and those sources should be credited too.

## License

The package is released under the MIT license. The data are released under CC BY 4.0.
