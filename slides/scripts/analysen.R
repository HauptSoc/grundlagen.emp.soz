
library(haven)
library(dplyr)
library(forcats)
library(knitr)
library(kableExtra)

freda <- read_dta("C:/Daten/FReDA Campus Use File v.1.0.0/Data/freda_long.dta")

data <- freda |>
  select(pa27, pa22ri9, age, sat3, sex_c) |>
  filter(!is.na(pa27), !is.na(pa22ri9), !is.na(age), !is.na(sat3), !is.na(sex_c)) |>
  mutate(sex_c_num = if_else(as_factor(sex_c) == "Male", 1L, 0L)) |>
  mutate(pa27 = if_else(pa27 == 2, 0, 1)) |>
  mutate(pa22ri9 = fct_drop(as_factor(pa22ri9)))


df <- as.data.frame(prop.table(table(data$sat3)) * 100)
names(df) <- c("sat3", "rel_Hfg")

ggplot(df, aes(x = sat3, y = rel_Hfg)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = sprintf("%.1f%%", rel_Hfg)), 
            vjust = -0.5, size = 4) +
  ylim(0, max(df$rel_Hfg) * 1.15) +
  labs(title = "Zufriedenheit mit der Beziehung",
       x = "Zufriedenheit auf 11er-Skala", y = "Relative Häufigkeit (%)") +
  theme_minimal()



df2 <- as.data.frame(prop.table(table(data$pa22ri9)) * 100)
names(df2) <- c("pa22ri9", "rel_Hfg2")

ggplot(df2, aes(x = pa22ri9, y = rel_Hfg2)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = sprintf("%.1f%%", rel_Hfg2)), 
            vjust = -0.5, size = 4) +
  ylim(0, max(df2$rel_Hfg2) * 1.15) +
  labs(title = "Streit in der Beziehung",
       x = "Konflikte enden im Streit", y = "Relative Häufigkeit (%)") +
  theme_minimal()



library(patchwork)

# --- Graph 1: pa27 overall ---
df1 <- as.data.frame(prop.table(table(data$pa27)) * 100)
names(df1) <- c("pa27", "rel_Hfg")
df1$pa27 <- droplevels(df1$pa27)

g1 <- ggplot(df1, aes(x = pa27, y = rel_Hfg)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  geom_text(aes(label = sprintf("%.1f%%", rel_Hfg)), 
            vjust = -0.5, size = 4) +
  ylim(0, max(df1$rel_Hfg) * 1.2) +
  scale_x_discrete(labels = c("0" = "Nein", "1" = "Ja")) +
  labs(title = "pa27 (Gesamt)",
       x = "pa27", y = "Relative Häufigkeit (%)") +
  theme_minimal()

# --- Graph 2: pa27 nach sex_c (Anteile innerhalb jeder Gruppe) ---
df2 <- data |>
  group_by(sex_c) |>
  summarise(Anteil = mean(pa27) * 100, .groups = "drop") |>
  mutate(sex_c = fct_drop(as_factor(sex_c)))

g2 <- ggplot(df2, aes(x = sex_c, y = Anteil)) +
  geom_bar(stat = "identity", fill = "coral") +
  geom_text(aes(label = sprintf("%.1f%%", Anteil)), 
            vjust = -0.5, size = 4) +
  ylim(0, max(df2$Anteil) * 1.2) +
  labs(title = "pa27 nach Geschlecht",
       x = "sex_c", y = "Relative Häufigkeit (%)") +
  theme_minimal()

# --- Panel ---
g1 | g2