###############################################################################
# Datensimulation: Vignettendesign "Er/Sie ist eine 10/10, aber..."
# Für eine Vorlesung zur Verdeutlichung komplexer Vignettendesigns
###############################################################################

# ---------------------------------------------------------------------------
# 0) Setup
# ---------------------------------------------------------------------------
set.seed(2024)
library(dplyr)
library(tidyr)

# ---- Zentrale Stellschrauben für die Skalierung der Bewertung ---------------
# Diese Parameter steuern nur die VERTEILUNGSFORM (Lage/Streuung),
# nicht die inhaltlichen Effekt-Koeffizienten aus den Gleichungen.
INTERCEPT   <- 5.9   # Grundniveau, zentriert die Verteilung um die Skalenmitte
SD_PERS_F   <- 1.0   # SD des Random Intercepts (Frauen streuen stärker)
SD_PERS_M   <- 0.9   # SD des Random Intercepts (Männer)
SD_ERROR    <- 1.0   # Residual-Standardabweichung

# ---------------------------------------------------------------------------
# 1) Personen anlegen
# ---------------------------------------------------------------------------
n_frauen  <- 250
n_maenner <- 173
n_total   <- n_frauen + n_maenner

personen <- tibble(
  ID_P       = 1:n_total,
  Geschlecht = c(rep("Frau", n_frauen), rep("Mann", n_maenner))
)

# ---------------------------------------------------------------------------
# 2) Personenspezifische Zufallseffekte (Random Intercepts)
# ---------------------------------------------------------------------------
# Frauen bewerten im Mittel -2.5 Punkte niedriger; diese Mittelwertdifferenz
# ist selbst unsicher (SE = 0.5) und wird einmalig gezogen.
frauen_offset <- rnorm(1, mean = -2.5, sd = 0.5)

personen <- personen %>%
  mutate(
    sd_person        = ifelse(Geschlecht == "Frau", SD_PERS_F, SD_PERS_M),
    u_person         = rnorm(n(), mean = 0, sd = sd_person),
    geschlecht_shift = ifelse(Geschlecht == "Frau", frauen_offset, 0)
  )

# ---------------------------------------------------------------------------
# 3) Anzahl gezogener Karten pro Person  [ÄNDERUNG 3]
# ---------------------------------------------------------------------------
# Symmetrische Verteilung mit Masse in der Mitte (~5), Bereich 1..10.
# Umsetzung: n_karten = 1 + Binomial(9, p). Mit p = 0.47 ergibt sich ein
# glockenförmiges Profil, das um 5 herum am dichtesten ist.
personen <- personen %>%
  mutate(
    n_karten = 1L + rbinom(n(), size = 9, prob = 0.47)
  )

# ---------------------------------------------------------------------------
# 4) Karten-Level-Datensatz aufbauen (eine Zeile pro Karte)  [ÄNDERUNG 2]
# ---------------------------------------------------------------------------
# Zuerst die Zeilenstruktur (ID_P x ID_C) erzeugen ...
karten <- personen %>%
  rowwise() %>%
  mutate(ID_C = list(1:n_karten)) %>%
  unnest(ID_C) %>%
  ungroup()

n_karten_total <- nrow(karten)

# Faktorstufen
diff_levels  <- c(-10, -5, 0, 5, 10)
musik_levels <- c("Metal", "HippHopp", "Schlager", "Electro")
bez_levels   <- c("sehr schlecht", "schlecht", "halb/halb", "gut", "sehr gut")

# ... dann ALLE Kovariaten vollständig (ohne Missings) anlegen.
# Diff_cm, Musik, Beziehung sind designbedingt GLEICHVERTEILT.
# Wir ziehen jede Stufe exakt gleich häufig (balanciertes Design) und mischen
# anschließend, damit deskriptive Statistiken sauber gleichverteilt sind.
gleichverteilt <- function(levels, n) {
  reps  <- ceiling(n / length(levels))
  pool  <- rep(levels, times = reps)[1:n]
  sample(pool)                       # zufällige Reihenfolge, exakt balanciert
}

karten <- karten %>%
  mutate(
    Diff_cm   = as.numeric(gleichverteilt(diff_levels,  n_karten_total)),
    Musik     = gleichverteilt(musik_levels, n_karten_total),
    Beziehung = gleichverteilt(bez_levels,   n_karten_total),
    # Karten-Geschlecht abhängig vom Personengeschlecht:
    #   Männer: 90% Frauenstapel / 10% Männerstapel
    #   Frauen: 30% Frauenstapel / 70% Männerstapel
    p_frau_karte = ifelse(Geschlecht == "Mann", 0.90, 0.30),
    Geschlecht_C = ifelse(runif(n_karten_total) < p_frau_karte, "Frau", "Mann"),
    Geschlecht_D = as.integer(Geschlecht == Geschlecht_C)
  )

# Kurzcheck: keine Missings in den Kovariaten
stopifnot(!anyNA(karten[c("Diff_cm", "Musik", "Beziehung",
                          "Geschlecht", "Geschlecht_C", "Geschlecht_D")]))

# ---------------------------------------------------------------------------
# 5) Dummy-Kodierung der Effekt-Terme
# ---------------------------------------------------------------------------
# Musik-Referenz = HippHopp; Beziehungs-Referenz = halb/halb
karten <- karten %>%
  mutate(
    d_Metal        = as.integer(Musik == "Metal"),
    d_Schlager     = as.integer(Musik == "Schlager"),
    d_Electro      = as.integer(Musik == "Electro"),
    d_sehrschlecht = as.integer(Beziehung == "sehr schlecht"),
    d_schlecht     = as.integer(Beziehung == "schlecht"),
    d_gut          = as.integer(Beziehung == "gut"),
    d_sehrgut      = as.integer(Beziehung == "sehr gut")
  )

# ---------------------------------------------------------------------------
# 6) "Frauen bewerten Frauen zuerst" -> Bonus bei späterer Männerbewertung
# ---------------------------------------------------------------------------
karten <- karten %>%
  arrange(ID_P, ID_C) %>%
  group_by(ID_P) %>%
  mutate(
    frau_karte_vorher = cumsum(Geschlecht_C == "Frau") - (Geschlecht_C == "Frau"),
    hatte_frau_vorher = as.integer(frau_karte_vorher > 0),
    reihenfolge_bonus = ifelse(
      Geschlecht == "Frau" & Geschlecht_C == "Mann" & hatte_frau_vorher == 1,
      0.5, 0
    )
  ) %>%
  ungroup()

# ---------------------------------------------------------------------------
# 7) Lineare Prädiktoren gemäß der Gleichungen  [ÄNDERUNG 1]
# ---------------------------------------------------------------------------
# NEU: expliziter INTERCEPT als Grundniveau -> zentriert die Verteilung,
# verhindert die starke Klumpung auf 0. Streuungen über die Stellschrauben
# oben moderat gehalten, damit die Skala [0,10] nicht "gesprengt" wird.
karten <- karten %>%
  mutate(
    lin_gemeinsam =
      2 * d_Metal - 6 * d_Schlager + 1 * d_Electro +
      (-1) * d_sehrschlecht + 0.2 * d_schlecht + 0.3 * d_gut + 0.8 * d_sehrgut,

    lin_geschlecht = ifelse(
      Geschlecht == "Mann",
      -0.5 * Diff_cm + 3 * Geschlecht_D,   # Männer
       2.0 * Diff_cm - 2 * Geschlecht_D    # Frauen
    ),

    error = rnorm(n(), mean = 0, sd = SD_ERROR),

    Bewertung_latent =
      INTERCEPT +
      lin_gemeinsam +
      lin_geschlecht +
      u_person +
      geschlecht_shift +
      0.2 * ID_C +
      reihenfolge_bonus +
      error,

    Bewertung = round(pmin(10, pmax(0, Bewertung_latent)))
  )

# ---------------------------------------------------------------------------
# 8) Finalen Analysedatensatz auswählen
# ---------------------------------------------------------------------------
daten <- karten %>%
  select(
    ID_P, ID_C, Bewertung,
    Diff_cm, Musik, Beziehung,
    Geschlecht, Geschlecht_C, Geschlecht_D
  ) %>%
  arrange(ID_P, ID_C)

# ---------------------------------------------------------------------------
# 9) Plausibilitätschecks
# ---------------------------------------------------------------------------
cat("Anzahl Personen:      ", n_distinct(daten$ID_P), "\n")
cat("Anzahl Karten gesamt: ", nrow(daten), "\n")
cat("Karten je Person (Mittel): ", round(mean(personen$n_karten), 2), "\n\n")

cat("Verteilung Anzahl Karten pro Person:\n")
print(table(personen$n_karten))

cat("\nVerteilung der Bewertungen (Anteile):\n")
print(round(prop.table(table(daten$Bewertung)), 3))
cat("Mittelwert Bewertung:", round(mean(daten$Bewertung), 2),
    "| SD:", round(sd(daten$Bewertung), 2), "\n")

cat("\nGleichverteilung der Kovariaten (Kontrolle):\n")
print(prop.table(table(daten$Diff_cm)))
print(prop.table(table(daten$Musik)))
print(prop.table(table(daten$Beziehung)))

cat("\nAnteil Frauen-Karten je Personengeschlecht (Erwartung: Mann 0.90 / Frau 0.30):\n")
daten %>% group_by(Geschlecht) %>%
  summarise(anteil_frauen_karten = mean(Geschlecht_C == "Frau"), .groups = "drop")

# write.csv(daten, "vignetten_simulation.csv", row.names = FALSE)