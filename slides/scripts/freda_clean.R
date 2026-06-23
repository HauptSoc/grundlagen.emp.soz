# 1️⃣ Lade notwendige Bibliotheken
library(dplyr)
library(labelled)  # Zum Umgang mit labeled/unlabeled Daten (falls nötig)

# 2️⃣ Bereite den Datensatz 'freda_clean' vor
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
      as.integer(pstat),  # Konvertiere zu numerisch, falls nötig
      levels = c(0, 1),
      labels = c("Keine Partnerschaft", "In Partnerschaft")
    ),

    # sex: "Männlich" (1), "Weiblich" (2), "Divers" (3) – hier nur "Männlich" und "Weiblich"
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