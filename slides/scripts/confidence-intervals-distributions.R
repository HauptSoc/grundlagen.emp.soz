library(ggplot2)
library(gridExtra)

# ============================================================================
# PANEL 1: t-Verteilungen (10 df vs 40 df)
# ============================================================================

# Berechne kritische Werte
t_90_10 <- qt(0.95, df = 10)
t_95_10 <- qt(0.975, df = 10)
t_90_40 <- qt(0.95, df = 40)
t_95_40 <- qt(0.975, df = 40)

# Plot t-Verteilung 10 df
p_t_10 <- ggplot(data.frame(x = c(-4, 4)), aes(x = x)) +
  annotate("rect", xmin = -t_90_10, xmax = t_90_10, ymin = 0, ymax = Inf,
           alpha = 0.15, fill = "green") +
  annotate("rect", xmin = -t_95_10, xmax = t_95_10, ymin = 0, ymax = Inf,
           alpha = 0.08, fill = "orange") +
  stat_function(fun = dt, args = list(df = 10), color = "#FF744E", linewidth = 1.2) +
  geom_vline(xintercept = c(-t_90_10, t_90_10), color = "darkgreen", linewidth = 0.8, linetype = "dotted") +
  geom_vline(xintercept = c(-t_95_10, t_95_10), color = "darkorange", linewidth = 0.8, linetype = "dashed") +
  # Annotationen versetzt übereinander
  annotate("text", x = 0, y = dt(0, 10) * 0.90, 
           label = paste0("90%: ±", round(t_90_10, 2)),
           size = 3.5, hjust = 0.5, vjust = 0,
           color = "darkgreen", fontface = "bold") +
  annotate("text", x = 0, y = dt(0, 10) * 0.75, 
           label = paste0("95%: ±", round(t_95_10, 2)),
           size = 3.5, hjust = 0.5, vjust = 0,
           color = "darkorange", fontface = "bold") +
  labs(x = "t-Wert", y = "Dichte", title = "t-Verteilung (df = 10)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        panel.grid.major = element_line(color = "lightgray", linewidth = 0.2),
        axis.text = element_text(size = 10))

# Plot t-Verteilung 40 df
p_t_40 <- ggplot(data.frame(x = c(-4, 4)), aes(x = x)) +
  annotate("rect", xmin = -t_90_40, xmax = t_90_40, ymin = 0, ymax = Inf,
           alpha = 0.15, fill = "green") +
  annotate("rect", xmin = -t_95_40, xmax = t_95_40, ymin = 0, ymax = Inf,
           alpha = 0.08, fill = "orange") +
  stat_function(fun = dt, args = list(df = 40), color = "#75AADB", linewidth = 1.2) +
  geom_vline(xintercept = c(-t_90_40, t_90_40), color = "darkgreen", linewidth = 0.8, linetype = "dotted") +
  geom_vline(xintercept = c(-t_95_40, t_95_40), color = "darkorange", linewidth = 0.8, linetype = "dashed") +
  # Annotationen versetzt übereinander
  annotate("text", x = 0, y = dt(0, 40) * 0.90, 
           label = paste0("90%: ±", round(t_90_40, 2)),
           size = 3.5, hjust = 0.5, vjust = 0,
           color = "darkgreen", fontface = "bold") +
  annotate("text", x = 0, y = dt(0, 40) * 0.75, 
           label = paste0("95%: ±", round(t_95_40, 2)),
           size = 3.5, hjust = 0.5, vjust = 0,
           color = "darkorange", fontface = "bold") +
  labs(x = "t-Wert", y = "Dichte", title = "t-Verteilung (df = 40)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        panel.grid.major = element_line(color = "lightgray", linewidth = 0.2),
        axis.text = element_text(size = 10))

# Kombiniere t-Verteilungs-Plots
panel_t <- grid.arrange(p_t_10, p_t_40, ncol = 2, 
                        top = "t-Verteilungen: 90% und 95% Konfidenzintervalle")

# ============================================================================
# PANEL 2: F-Verteilungen (3/10 df vs 45/100 df)
# ============================================================================

# Berechne kritische Werte für F-Verteilung
f_90_3_10 <- qf(0.90, df1 = 3, df2 = 10)
f_95_3_10 <- qf(0.95, df1 = 3, df2 = 10)
f_90_45_100 <- qf(0.90, df1 = 45, df2 = 100)
f_95_45_100 <- qf(0.95, df1 = 45, df2 = 100)

# Berechne maximale Dichte für Annotationen
max_y_3_10 <- df(f_90_3_10, 3, 10)
max_y_45_100 <- df(f_90_45_100, 45, 100)

# Erstelle F-Verteilungs-Plot 3/10 df
p_f_3_10 <- ggplot(data.frame(x = c(0, 10)), aes(x = x)) +
  annotate("rect", xmin = 0, xmax = f_90_3_10, ymin = 0, ymax = Inf,
           alpha = 0.15, fill = "green") +
  annotate("rect", xmin = 0, xmax = f_95_3_10, ymin = 0, ymax = Inf,
           alpha = 0.08, fill = "orange") +
  stat_function(fun = df, args = list(df1 = 3, df2 = 10),
                color = "#FF744E", linewidth = 1.2) +
  geom_vline(xintercept = f_90_3_10, color = "darkgreen", linewidth = 0.8, linetype = "dotted") +
  geom_vline(xintercept = f_95_3_10, color = "darkorange", linewidth = 0.8, linetype = "dashed") +
  # Annotationen versetzt untereinander
  annotate("text", x = f_90_3_10 + 0.5, y = max_y_3_10 * 0.90,
           label = paste0("90%: ", round(f_90_3_10, 2)),
           size = 3.5, hjust = 0, vjust = 0.5,
           color = "darkgreen", fontface = "bold") +
  annotate("text", x = f_95_3_10 + 0.5, y = max_y_3_10 * 0.70,
           label = paste0("95%: ", round(f_95_3_10, 2)),
           size = 3.5, hjust = 0, vjust = 0.5,
           color = "darkorange", fontface = "bold") +
  labs(x = "F-Wert", y = "Dichte", title = "F-Verteilung (df = 3/10)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        panel.grid.major = element_line(color = "lightgray", linewidth = 0.2),
        axis.text = element_text(size = 10))

# Erstelle F-Verteilungs-Plot 45/100 df
p_f_45_100 <- ggplot(data.frame(x = c(0, 3)), aes(x = x)) +
  annotate("rect", xmin = 0, xmax = f_90_45_100, ymin = 0, ymax = Inf,
           alpha = 0.15, fill = "green") +
  annotate("rect", xmin = 0, xmax = f_95_45_100, ymin = 0, ymax = Inf,
           alpha = 0.08, fill = "orange") +
  stat_function(fun = df, args = list(df1 = 45, df2 = 100),
                color = "#75AADB", linewidth = 1.2) +
  geom_vline(xintercept = f_90_45_100, color = "darkgreen", linewidth = 0.8, linetype = "dotted") +
  geom_vline(xintercept = f_95_45_100, color = "darkorange", linewidth = 0.8, linetype = "dashed") +
  # Annotationen versetzt untereinander
  annotate("text", x = f_90_45_100 + 0.15, y = max_y_45_100 * 0.90,
           label = paste0("90%: ", round(f_90_45_100, 2)),
           size = 3.5, hjust = 0, vjust = 0.5,
           color = "darkgreen", fontface = "bold") +
  annotate("text", x = f_95_45_100 + 0.15, y = max_y_45_100 * 0.70,
           label = paste0("95%: ", round(f_95_45_100, 2)),
           size = 3.5, hjust = 0, vjust = 0.5,
           color = "darkorange", fontface = "bold") +
  labs(x = "F-Wert", y = "Dichte", title = "F-Verteilung (df = 45/100)") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 12),
        panel.grid.major = element_line(color = "lightgray", linewidth = 0.2),
        axis.text = element_text(size = 10))

# Kombiniere F-Verteilungs-Plots
panel_f <- grid.arrange(p_f_3_10, p_f_45_100, ncol = 2, 
                        top = "F-Verteilungen: 90% und 95% Konfidenzintervalle")

# ============================================================================
# DISPLAY BOTH PANELS
# ============================================================================

print(panel_t)
print(panel_f)

# ============================================================================
# PRINT SUMMARY TABLE
# ============================================================================

cat("================================================================================\n")
cat("KRITISCHE WERTE FÜR KONFIDENZINTERVALLE\n")
cat("================================================================================\n\n")

cat("t-VERTEILUNGEN:\n")
cat("──────────────────────────────────────────────────────────────────────────────\n")
cat("df = 10:\n")
cat("  90% CI: t ± ", round(t_90_10, 4), "\n")
cat("  95% CI: t ± ", round(t_95_10, 4), "\n\n")
cat("df = 40:\n")
cat("  90% CI: t ± ", round(t_90_40, 4), "\n")
cat("  95% CI: t ± ", round(t_95_40, 4), "\n\n")

cat("F-VERTEILUNGEN:\n")
cat("──────────────────────────────────────────────────────────────────────────────\n")
cat("df = 3/10:\n")
cat("  90% Grenze: F = ", round(f_90_3_10, 4), "\n")
cat("  95% Grenze: F = ", round(f_95_3_10, 4), "\n\n")
cat("df = 45/100:\n")
cat("  90% Grenze: F = ", round(f_90_45_100, 4), "\n")
cat("  95% Grenze: F = ", round(f_95_45_100, 4), "\n\n")

cat("================================================================================\n")
