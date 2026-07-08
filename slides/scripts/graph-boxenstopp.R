library(tidyverse)
library(ggplot2)

# 1. Daten vorbereiten
gender_diff_data <- freda_clean |>
  select(all_of(val13_items), sex) |>
  filter(!is.na(sex)) |>
  pivot_longer(
    cols = -sex,
    names_to = "item",
    values_to = "antwort_raw"
  ) |>
  mutate(
    antwort = as.factor(antwort_raw),
    sex = factor(sex, levels = c("Männlich", "Weiblich"))
  ) |>
  filter(!is.na(antwort))

# 2. Relative Häufigkeiten berechnen
gender_diff_plot_data <- gender_diff_data |>
  group_by(sex, item) |>
  mutate(n_total = n()) |>
  ungroup() |>
  group_by(sex, item, antwort) |>
  summarise(
    n = n(),
    pct = round(100 * n / first(n_total), 1)
  ) |>
  ungroup() |>
  mutate(
    item_label = case_when(
      item == "val13i1" ~ "Mutter-Kind Verhältnis (Vollzeit vs. nicht berufstätig)",
      item == "val13i2" ~ "Beste Arbeitsteilung (beide Eltern Vollzeit)",
      item == "val13i3" ~ "Kind leidet bei Berufstätigkeit (der Mutter)",
      item == "val13i4" ~ "Traditionelle Rollenverteilung",
      item == "val13i5" ~ "Gut für Kind, wenn Mutter berufstätig ist",
      item == "val13i6" ~ "Vater unzureichend für Kinderbetreuung",
      item == "val13i7" ~ "Hauptverantwortung bei der Frau",
      item == "val13i8" ~ "Vater-Kind Verhältnis (Vollzeit vs. nicht berufstätig)",
      item == "val13i9" ~ "Mann übernimmt Verantwortung (für Haushalt/Kinder)"
    )
  )

# 3. Plots erstellen (vertikal untereinander, gruppierte Balken)
plots <- gender_diff_plot_data |>
  group_by(item_label) |>
  group_split() |>
  map(~ {
    ggplot(.x, aes(
      x = antwort,  # Antwortkategorien (horizontal)
      y = pct,
      fill = sex
    )) +
      geom_col(
        position = position_dodge(width = 0.8),  # Gruppierte Balken
        width = 0.7,
        color = "black",
        alpha = 0.9
      ) +
      geom_text(
        aes(label = ifelse(pct >= 5, paste0(pct, "%"), "")),
        position = position_dodge(width = 0.8),
        vjust = -0.5,
        size = 3.5,
        color = "black",
        fontface = "bold"
      ) +
      labs(
        title = .x$item_label[1],
        x = "Antwortkategorie",
        y = "Relative Häufigkeit (%)",
        fill = "Geschlecht"
      ) +
      scale_fill_manual(values = c("Männlich" = "#1f77b4", "Weiblich" = "#ff7f0e")) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        plot.title = element_text(size = 12, face = "bold")
      )
  })

# 4. Plots anzeigen (oder speichern)
walk(plots, print)
