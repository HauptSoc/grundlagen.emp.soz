# ─────────────────────────────────────────────────────────────────────────────
# t-Verteilung mit zweiseitigem Ablehnungsbereich und Signifikanzstern-Notation
#
# Lernziel: Studierende sollen verstehen, wie die Ablehnungsbereiche einer
# Testverteilung mit den Signifikanzsymbolen (* / ** / ***) in Ergebnis-
# tabellen zusammenhängen:
#   • Fällt der empirische t-Wert in den hellgrauen Bereich → p < 0.10 → *
#   • Fällt er in den mittelgrauen Bereich  → p < 0.05 → **
#   • Fällt er in den dunkelgrauen Bereich  → p < 0.01 → ***
#   • Je extremer der t-Wert, desto kleiner das p, desto mehr Sterne.
#
# Zweiseitiger Test: Ablehnungsbereiche liegen symmetrisch in BEIDEN Schwänzen.
# ─────────────────────────────────────────────────────────────────────────────

library(ggplot2)

# ── Parameter ────────────────────────────────────────────────────────────────
df_val <- 15   # Freiheitsgrade (hier: n - 1 = 6 - 1)

# Kritische Werte für zweiseitigen t-Test
# Formel: qt(1 - α/2, df)  →  |t| > cv  bedeutet  p < α
cv_10 <- qt(1 - 0.10 / 2, df_val)  # ≈ 2.02  (α = 10 %)
cv_05 <- qt(1 - 0.05 / 2, df_val)  # ≈ 2.57  (α =  5 %)
cv_01 <- qt(1 - 0.01 / 2, df_val)  # ≈ 4.03  (α =  1 %)

# Dichtefunktion der t-Verteilung
dt_fun <- function(x) dt(x, df = df_val)

# Farben: hell = weniger streng, dunkel = strenger
col_10 <- "#d9d9d9"
col_05 <- "#bdbdbd"
col_01 <- "#969696"

# ── Plot ──────────────────────────────────────────────────────────────────────
ggplot(data.frame(x = c(-5, 5)), aes(x)) +

  # Ablehnungsbereiche – rechte Seite
  stat_function(fun = dt_fun, geom = "area", xlim = c(cv_10, 5),  fill = col_10) +
  stat_function(fun = dt_fun, geom = "area", xlim = c(cv_05, 5),  fill = col_05) +
  stat_function(fun = dt_fun, geom = "area", xlim = c(cv_01, 5),  fill = col_01) +

  # Ablehnungsbereiche – linke Seite (zweiseitig, symmetrisch)
  stat_function(fun = dt_fun, geom = "area", xlim = c(-5, -cv_10), fill = col_10) +
  stat_function(fun = dt_fun, geom = "area", xlim = c(-5, -cv_05), fill = col_05) +
  stat_function(fun = dt_fun, geom = "area", xlim = c(-5, -cv_01), fill = col_01) +

  # Dichtefunktion der t-Verteilung
  stat_function(fun = dt_fun, color = "#2980b9", linewidth = 1.2) +

  # ── Beschriftungen & Pfeile (rechts) ──────────────────────────────────────
  # Text + Pfeil: beide zeigen, welcher Bereich welchem p-Wert entspricht.
  # Rechte Seite: Pfeil zeigt in den rechten Ablehnungsbereich →
  # Linke  Seite: Pfeil zeigt in den linken  Ablehnungsbereich ←

  # p < 0.10  →  *
  annotate("text", x = cv_10, y = 0.17,
           label = "p < 0.10 \u2261 *", hjust = 0, size = 3.5) +
  annotate("segment", x = cv_10, xend = 4.95, y = 0.15, yend = 0.15,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +

  # p < 0.05  →  **
  annotate("text", x = cv_05, y = 0.23,
           label = "p < 0.05 \u2261 **", hjust = 0, size = 3.5) +
  annotate("segment", x = cv_05, xend = 4.95, y = 0.21, yend = 0.21,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +

  # p < 0.01  →  ***
  annotate("text", x = cv_01, y = 0.29,
           label = "p < 0.01 \u2261 ***", hjust = 0, size = 3.5) +
  annotate("segment", x = cv_01, xend = 4.95, y = 0.27, yend = 0.27,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +

  # ── Pfeile links (symmetrisch, kein Doppel-Text) ──────────────────────────
  annotate("segment", x = -cv_10, xend = -4.95, y = 0.15, yend = 0.15,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +
  annotate("segment", x = -cv_05, xend = -4.95, y = 0.21, yend = 0.21,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +
  annotate("segment", x = -cv_01, xend = -4.95, y = 0.27, yend = 00.27,
           arrow = arrow(length = unit(0.18, "cm"), type = "closed")) +

  # ── Achsen & Labels ───────────────────────────────────────────────────────
  scale_x_continuous(breaks = -5:5, limits = c(-5, 5), expand = c(0.01, 0)) +
  scale_y_continuous(
    breaks = seq(0, 0.4, 0.1),
    labels = c("0", ".1", ".2", ".3", ".4"),
    limits = c(0, 0.43),
    expand = c(0, 0)
  ) +
  labs(
    title = paste0("t-Verteilung mit ", df_val, " df und zweiseitigem Ablehnungsbereich "),
    subtitle = paste0("f\u00fcr die oberen und unteren 10%, 5%, 1%"),
    x = "t",
    y = "f(t)"
  ) +
  theme_classic(base_size = 13) +
  theme( axis.title.y = element_text(angle = 0, vjust = 0.5, margin = margin(r = 8))
  )
