library(tidyverse)

set.seed(42)
n <- 10000

# 1) Single-Status
single <- rbinom(n, 1, 0.35)

# 2) Einsamkeit (abhängig von Single)
p_einsam <- plogis(-1.1 + 1.0 * single)
einsam <- rbinom(n, 1, p_einsam)

# 3) Katzenbesitz (Single + Einsamkeit) — stärkere Konfundierung
p_katze <- plogis(-1.2 + 0.8 * single + 2.5 * einsam)
katze <- rbinom(n, 1, p_katze)

# 4) Zufriedenheit: DAG-Effekt Katze fix +3, Einsamkeit -4.0
zufriedenheit_base <- rnorm(n, mean = 6.4, sd = 1.0)
zufriedenheit <- zufriedenheit_base + 3 * katze - 4.0 * einsam + rnorm(n, 0, 0.7)

dat <- tibble(single, katze, einsam, zufriedenheit) |>
  mutate(
    single = factor(single, 0:1, c("Nein", "Ja")),
    katze  = factor(katze,  0:1, c("Nein", "Ja")),
    einsam = factor(einsam, 0:1, c("Nein", "Ja"))
  )
