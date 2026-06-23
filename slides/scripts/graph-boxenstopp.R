# 1️⃣ Datenvorbereitung
dat_plot_sat6 <- freda_clean %>%
  filter(!is.na(pstat)) %>%  # Filtere nur NA-Werte
  filter(pstat == 0 | pstat == 1) %>%  # Sicherstellen, dass nur 0/1 enthalten sind
  mutate(
    sex_clean = case_when(
      tolower(trimws(as.character(sex))) %in% c(1, "m", "männlich", "mann") ~ "Männlich",
      tolower(trimws(as.character(sex))) %in% c(2, "w", "weiblich", "frau") ~ "Weiblich",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(sex_clean)) %>%  # Filtern auf gültige Werte
  select(sex_clean, sat6, pstat = pstat)

# 2️⃣ Berechne relative Anteile wenn Daten vorhanden sind
if (nrow(dat_plot_sat6) > 0) {
  häufigkeiten <- dat_plot_sat6 %>%
    group_by(sex_clean) %>%
    summarise(
      gesamt = n(),
      in_partnerschaft = sum(pstat == 1),
      anteil = in_partnerschaft / gesamt * 100
    )

  # 3️⃗ Plot erstellen mit angepassten X-Labels
  p <- ggplot(dat_plot_sat6, aes(x = factor(pstat), y = sat6, fill = sex_clean)) +
    geom_boxplot() +
    labs(
      title = "Zufriedenheit mit dem Leben nach Geschlecht & Partnerschaftsstatus",
      x = "Beziehungsstatus",
      y = "Zufriedenheit mit dem Leben (Skala)",
      fill = "Geschlecht",
      caption = "0 = Single, 1 = Paarbeziehung"
    ) +
    scale_fill_manual(values = c("Männlich" = "#1f77b4", "Weiblich" = "#ff7f0e")) +
    scale_x_discrete(
      labels = c("0" = "Single", "1" = "Paarbeziehung")
    ) +
    theme_minimal() +
    theme(axis.title.x = element_text(size = 12)) +
    annotate(
      "text",
      x = 1.5,
      y = max(dat_plot_sat6$sat6, na.rm = TRUE),
      label = if (nrow(häufigkeiten) > 0) {
        paste(
          "Anteil in Partnerschaft:\n",
          "Männer: ", round(häufigkeiten$anteil[häufigkeiten$sex_clean == "Männlich"], 1), "%\n",
          "Frauen: ", round(häufigkeiten$anteil[häufigkeiten$sex_clean == "Weiblich"], 1), "%",
          sep = ""
        )
      } else {
        "Keine gültigen Daten vorhanden"
      },
      hjust = 0,
      vjust = -1,
      color = "black",
      size = 3.5
    )

  # 4️⃗ Plot anzeigen
  print(p)
} else {
  message("Keine gültigen Daten für den Plot vorhanden")
}