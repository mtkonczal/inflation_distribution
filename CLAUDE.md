# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R Shiny web application that visualizes inflation distribution density plots across CPI and PCE price indices. Users can compare how price changes are distributed across product categories for up to 3 time periods simultaneously. Deployed at https://mtkonczal.shinyapps.io/inflation_distribution/.

## Running the App

```r
shiny::runApp()
```

## Updating Data

```r
source("1_shiny_data_update.R")
```

This downloads fresh CPI data from BLS (via `tidyusmacro` package) and PCE data from BEA NIPA tables, then exports to `data/shiny_density_test.rds`.

## Architecture

**Shiny App (global.R / ui.R / server.R):**
- `global.R`: Loads data once from a remote GitHub URL (`https://github.com/mtkonczal/BLS-CPI-Inflation-Analysis/raw/main/data/shiny_density_test.rds`), preprocesses date factors, defines shared helpers (`get_inf_type_dates()`, `filter_inf_data()`), and sets constants (color palettes, kernel choices).
- `ui.R`: Uses `bslib::page_sidebar()` layout — sidebar with inflation type selector, 3 series controls (Series 2/3 toggled via checkbox + conditionalPanel), percentile trimming slider, and advanced options (kernel, palette) in a collapsed accordion. Main area shows the density plot with a loading spinner.
- `server.R`: Separate `reactive()` per series for efficient recomputation, debounced percentile slider, deduplication of identical series, and `observeEvent` to update date selectors when switching CPI/PCE.

**Data Pipeline (1_shiny_data_update.R → scripts/):**
- `scripts/01_download_cpi_data.R`: Downloads CPI series from BLS, merges weights from `weights/most_prices.csv`.
- `scripts/02_general_graphic_scripts.R`: Utility functions — `create_cpi_changes()` calculates weighted percentage changes at multiple intervals; `calculate_trend()` computes annualized trends.
- `1_shiny_data_update.R`: Orchestrates the full pipeline — runs CPI download, processes PCE from BEA, combines both into final dataset.

**Data flow:** BLS/BEA APIs → download scripts → `1_shiny_data_update.R` → `data/shiny_density_test.rds` → `global.R` loads from GitHub URL → filtered by UI inputs in `server.R` → ggplot2 density plot.

## Key Dependencies

- `tidyusmacro`: Custom package for BLS/BEA data access (required for data pipeline)
- `shiny`, `bslib`, `shinycssloaders`, `ggplot2`, `dplyr`, `RColorBrewer`, `scales`: Shiny app runtime
- `tidyverse`, `lubridate`, `janitor`: Data pipeline

## Bug Fixes (2026-02)

- **PCE lag calculations**: Fixed `Pchange6a` (was using `lag(value,3)` instead of `lag(value,6)`) and `Pchange12` (was using `lag(value,3)` instead of `lag(value,12)`) in `1_shiny_data_update.R`.
- **Series 3 dedup**: Fixed crossed-pair comparison — was checking `length3==length2` when comparing against Series 1; now correctly checks `length3==length1`.
- **Redundant write_csv**: Removed duplicate unrounded CSV export that was immediately overwritten.

## Deployment

Deployed to shinyapps.io via the `rsconnect` package. Config lives in `rsconnect/`.
