# Gemeinsame Definitionen für Befragungs- und Live-App
# KSE – Kölner Skala zur Messung von Einsamkeit (Stephan, Fäth & Lamm),
# dt. Adaption der revidierten UCLA Loneliness Scale (Russell et al., 1980)
# https://www.testarchiv.eu/de/test/9003017

DATA_DIR  <- Sys.getenv("KSE_DATA_DIR", "/var/lib/einsamkeit")
DATA_FILE <- file.path(DATA_DIR, "antworten.csv")

# Mindestanzahl an Antworten, bevor live etwas angezeigt wird (Anonymität)
MIN_N <- 5

kse_items <- c(
  "Ich fühle mich in Übereinstimmung mit den Menschen um mich herum.",
  "Ich habe nicht genügend Gesellschaft.",
  "Es gibt niemanden, zu dem ich mich hinwenden kann.",
  "Ich fühle mich nicht allein.",
  "Ich fühle mich als Mitglied einer Freundesgruppe.",
  "Ich habe viel gemeinsam mit den Menschen um mich herum.",
  "Ich bin mit niemandem mehr eng zusammen.",
  "Meine Interessen und Ideen werden von den Leuten um mich herum nicht geteilt.",
  "Ich bin eine kontaktfreudige Person.",
  "Es gibt Menschen, denen ich mich eng verbunden fühle.",
  "Ich fühle mich ausgeschlossen.",
  "Meine sozialen Beziehungen sind oberflächlich.",
  "Niemand kennt mich wirklich.",
  "Ich fühle mich von anderen isoliert.",
  "Ich kann Gesellschaft finden, wenn ich das wünsche.",
  "Es gibt Menschen, die mich wirklich verstehen.",
  "So zurückgezogen, wie ich bin, fühle ich mich unglücklich.",
  "Menschen sind zwar um mich herum, jedoch nicht bei mir.",
  "Es gibt Menschen, mit denen ich sprechen kann.",
  "Es gibt Menschen, zu denen ich mich hinwenden kann."
)

kse_vars <- sprintf("i%02d", seq_along(kse_items))

kse_labels <- c("Nie" = 1, "Selten" = 2, "Manchmal" = 3, "Oft" = 4)

# Positiv formulierte Items (vor Summenbildung umpolen: 5 - x).
# Testarchiv nennt nur "10 positiv, 10 negativ"; Zuordnung entspricht der
# Original-R-UCLA (Russell et al., 1980). Bitte mit Testdokumentation abgleichen.
kse_reverse <- c(1, 4, 5, 6, 9, 10, 15, 16, 19, 20)

# Dimensionen nach Hawkley, Browne & Cacioppo (2005): Isolation, relationale
# und kollektive Verbundenheit. Die KSE selbst ist eindimensional ausgewiesen;
# die Zuordnung hier ist inhaltlich und dient der Lehrdemo -> ggf. anpassen.
kse_dims <- list(
  "Isoliertheit"              = c(2, 3, 7, 8, 11, 12, 13, 14, 17, 18),
  "Relationale Verbundenheit" = c(10, 15, 16, 19, 20),
  "Kollektive Verbundenheit"  = c(1, 4, 5, 6, 9)
)

# Standard-Erhebungswelle: Datum (trennt Vorlesungstermine automatisch)
default_welle <- function() format(Sys.Date(), "%Y-%m-%d")
