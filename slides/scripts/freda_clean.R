
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
library(broom)
library(labelled)
library(lavaanPlot)
library(gridExtra)
library(grid)
library(lattice)

# 2️⃣ Setze Variablen-Labels für spätere Verarbeitung mit kableExtra
# Dies muss erfolgen, bevor die Daten manipuliert werden
#attr(freda$val10i1, "label") <- "Politische Führung"
#attr(freda$val10i2, "label") <- "Uni ist wichtiger"
#attr(freda$val10i3, "label") <- "Arbeit ist wichtiger"
#attr(freda$val10i4, "label") <- "Haushalt/Kinder sind wichtiger"
#attr(freda$val10i5, "label") <- "Besser Kinderbetreuung"

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
  ) %>% 
 mutate(
    voctrain_f = factor(
      voctrain,
      levels = c(1, 2, 3, 4, 5, 6, 7, 8, 9),  # Alle Levels setzen
      labels = c(
        "1" = "Kein Abschluss",
        "2" = "Beruflich-betriebliche Ausbildung (Referenz)",  # Referenzkategorie
        "3" = "Beruflich-schulische Ausbildung",
        "4" = "Fach-, Meister-, Technikerschule",
        "5" = "Beamtenausbildung",
        "6" = "Fachhochschule, Berufsakademie",
        "7" = "Universität",
        "8" = "Promotion",
        "9" = "Anderer beruflicher Abschluss"
      )
    )
  )

# 4️⃣ Wandle die val13-Item-Batterie ("Werte Eltern") in geordnete Faktoren um
val13_items <- c("val13i1", "val13i2", "val13i6", "val13i8",
                 "val13i3", "val13i4", "val13i5", "val13i7", "val13i9")

# Bestehende Variablenlabels sichern, da factor() sie sonst verwerfen würde
val13_labels <- var_label(freda_clean[val13_items])

freda_clean <- freda_clean %>%
  mutate(
    across(
      all_of(val13_items),
      ~ factor(
        as.integer(.x),
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
  )

# Variablenlabels wiederherstellen
var_label(freda_clean[val13_items]) <- val13_labels

