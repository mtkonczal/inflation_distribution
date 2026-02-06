library(shiny)
library(bslib)
library(shinycssloaders)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(RColorBrewer)
library(scales)

# Load data once (shared by ui.R and server.R)
githubURL <- "https://github.com/mtkonczal/BLS-CPI-Inflation-Analysis/raw/main/data/shiny_density_test.rds"
dataset <- readRDS(url(githubURL))

# Date factor preprocessing
ordered_levels <- unique(format(sort(dataset$date, decreasing = TRUE), "%B, %Y"))
dataset$density_dateF <- factor(format(dataset$date, "%B, %Y"), levels = ordered_levels)
dataset$length_typeF <- factor(dataset$length_type, levels = c("1-month", "3-month", "6-month", "12-month"))

# Default date selections
maxdate <- format(max(dataset$date), "%B, %Y")
maxdate_1yr <- format(max(dataset$date) %m-% months(12), "%B, %Y")


# Per-inflation-type date vectors
get_inf_type_dates <- function(data, inflation_type_choice) {
  inf_data <- data %>% filter(inflation_type == inflation_type_choice)
  unique(format(sort(inf_data$date, decreasing = TRUE), "%B, %Y"))
}

cpi_dates <- get_inf_type_dates(dataset, "CPI")
pce_dates <- get_inf_type_dates(dataset, "PCE")

# Filter helper used by server
filter_inf_data <- function(dataset, input_date, length, chosen_inflation_type, lower_quantile, upper_quantile) {
  data_return <- dataset %>%
    filter(
      density_dateF == input_date,
      length_typeF == length,
      inflation_type == chosen_inflation_type
    ) %>%
    filter(
      between(
        Pvalues,
        quantile(Pvalues, lower_quantile, na.rm = TRUE),
        quantile(Pvalues, upper_quantile, na.rm = TRUE)
      )
    ) %>%
    mutate(name = paste0(input_date, ", ", length))
  return(data_return)
}

# Constants
brewer_colors <- c("Accent", "Dark2", "Paired", "Pastel1", "Pastel2", "Set1", "Set2", "Set3",
                   "BrBG", "PiYG", "PRGn", "PuOr", "RdBu", "RdGy", "RdYlBu", "RdYlGn", "Spectral")

kernel_choices <- c("Gaussian", "Epanechnikov", "Rectangular", "Triangular", "Biweight", "Cosine", "Optcosine")

# Last updated timestamp (updated by 1_shiny_data_update.R)
last_updated <- "February  5, 2026"
