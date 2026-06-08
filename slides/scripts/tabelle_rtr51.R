library(haven)
library(dplyr)
library(forcats)
library(knitr)
library(kableExtra)

freda <- read_dta("C:/Daten/FReDA Campus Use File v.1.0.0/Data/freda_long.dta")

tab_data <- freda |>
  select(rtr51, sex1i3, sex_c) |>
  filter(!is.na(rtr51), !is.na(sex1i3), !is.na(sex_c)) |>
  mutate(sex_c_num = if_else(as_factor(sex_c) == "Male", 1L, 0L)) |>
  select(rtr51, sex1i3, sex_c_num) |>
  slice_head(n = 10)

means_row <- tab_data |>
  summarise(across(everything(), mean)) |>
  mutate(across(everything(), \(x) round(x, 2)))

tab_data |>
  bind_rows(means_row) |>
  mutate(across(everything(), as.character)) |>
  mutate(
    rtr51     = if_else(row_number() == 11, paste0("Ø ", rtr51), rtr51),
    sex1i3    = if_else(row_number() == 11, paste0("Ø ", sex1i3), sex1i3),
    sex_c_num = if_else(row_number() == 11, paste0("Ø ", sex_c_num), sex_c_num)
  ) |>
  kable(
    col.names = c("Anz. Partnerschaften", "Alter erster GV", "Geschlecht (0=F, 1=M)"),
    align = "c"
  ) |>
  kable_styling(full_width = FALSE) |>
  row_spec(10, extra_css = "border-bottom: 2px solid black;") |>
  row_spec(11, bold = TRUE, background = "#f5f5f5")
