
# 1️⃣ Lade notwendige Bibliotheken
library(dplyr)
library(ggplot2)
library(forcats)
library(haven)
library(tidyverse)
library(labelled)
library(tidyr)
library(knitr)
library(kableExtra)
library(ggExtra)
library(GGally)
library(purrr)
library(lavaan)


freda <-  read_dta("C:/Daten/FReDA v6.0.0/R-Data/fredav6.dta", 
        col_select = c("welle", "id", "pid", "sample", "sex", "age", "east", "sat3", "sat6", "pstat", "sin3i1", "sin3i2", 
                        "reldur", "voctrain", "hlt32", "pa18i2", 
        "val13i1", "val13i2", "val13i6",  "val13i8",  "val13i3", "val13i4", "val13i5", "val13i7", "val13i9", "val10i1", "val10i2", "val10i3", "val10i4", "val10i5" 
                        )
                        ) 

# 2️⃣ Setze Variablen-Labels für spätere Verarbeitung mit kableExtra
# Dies muss erfolgen, bevor die Daten manipuliert werden
attr(freda$val10i1, "label") <- "Politische Führung"
attr(freda$val10i2, "label") <- "Uni ist wichtiger"
attr(freda$val10i3, "label") <- "Arbeit ist wichtiger"
attr(freda$val10i4, "label") <- "Haushalt/Kinder sind wichtiger"
attr(freda$val10i5, "label") <- "Besser Kinderbetreuung"

# 3️⃣ Bereite den Datensatz 'freda_clean' vor
freda_clean <- freda %>%
  # Filtere NA-Werte und negative Werte (behandle sie als NA)
  mutate(
    sex = case_when(
      sex %in% c(1, 2) ~ sex,
      TRUE ~ NA_integer_
    ),
    sin3i1 = case_when(
      sin3i1 %in% 1:5 ~ sin3i1,
      TRUE ~ NA_integer_
    ),
    sin3i2 = case_when(
      sin3i2 %in% 1:5 ~ sin3i2,
      TRUE ~ NA_integer_
    )
  ) %>%
  filter(sex %in% c(1, 2)) %>%
  # Konvertiere die Variablen in Faktoren mit den korrekten Labels
  # pstat: "Keine Partnerschaft" (0) und "In Partnerschaft" (1)
  mutate(
    pstat = factor(
      as.integer(pstat),
      levels = c(0, 1),
      labels = c("Keine Partnerschaft", "In Partnerschaft")
    ),

    # sex: "Männlich" (1), "Weiblich" (2)
    sex = factor(
      sex,
      levels = c(1, 2),
      labels = c("Männlich", "Weiblich")
    ),

    # sin3i1: Wertelabels
    sin3i1 = factor(
      sin3i1,
      levels = 1:5,
      labels = c(
        "Stimme überhaupt nicht zu",
        "Stimme eher nicht zu",
        "Weder noch",
        "Stimme eher zu",
        "Stimme voll zu"
      ),
      ordered = TRUE
    ),

    # sin3i2: Wertelabels
    sin3i2 = factor(
      sin3i2,
      levels = 1:5,
      labels = c(
        "Stimme überhaupt nicht zu",
        "Stimme eher nicht zu",
        "Weder noch",
        "Stimme eher zu",
        "Stimme voll zu"
      ),
      ordered = TRUE
    )
  )

