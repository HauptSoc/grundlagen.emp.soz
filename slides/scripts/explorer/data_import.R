library(shiny)
library(dplyr)
library(ggplot2)
library(haven)
library(labelled)
library(scales)
library(rlang)
library(stringr)
library(conflicted)
library(ggridges)
library(summarytools)
library(here)
library(viridis)

conflicts_prefer(dplyr::filter)

# -------------------------
# apply value labels ONLY when present in the parsed labels_map (file)
# -------------------------

raw_df <- haven::read_dta(here("slides", "scripts", "explorer", "allbus.dta"))

save(raw_df, file="slides/scripts/explore.Rdata")

