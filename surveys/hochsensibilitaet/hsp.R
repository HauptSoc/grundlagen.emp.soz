# Gemeinsame Definitionen für Befragungs- und Live-App
# HSP-Test für Hochsensibilität, Kurzform (Satow, 2022), 9 Items
# https://www.testarchiv.eu/de/test/9008351 (CC BY-NC-ND 4.0: Items nicht verändern)

DATA_DIR  <- Sys.getenv("HSP_DATA_DIR", "/var/lib/hochsensibilitaet")
DATA_FILE <- file.path(DATA_DIR, "antworten.csv")

# Mindestanzahl an Antworten, bevor live etwas angezeigt wird (Anonymität)
MIN_N <- 5

# Reihenfolge wie im Originalfragebogen (Kurzform)
hsp_items <- c(
  "Es passiert häufig, dass ich der Erste bin, der etwas wahrnimmt, beispielsweise riecht oder hört.",
  "Ich rege mich oft zu schnell auf.",
  "Meine eigenen Gefühle nehme ich sehr genau wahr.",
  "Ich rieche unangenehme Dinge deutlicher als andere.",
  "Kleinigkeiten bringen mich sehr schnell aus der Ruhe.",
  "Ich beschäftige mich sehr viel mit meinen eigenen Gefühlen und Gedanken.",
  "Ich versuche immer genau zu wissen, was in mir vorgeht.",
  "Ich bin leicht erregbar.",
  "Störende Geräusche (tiefes Brummen, hohes Pfeifen) nehme ich intensiver wahr als andere."
)

hsp_vars <- sprintf("i%02d", seq_along(hsp_items))

hsp_labels <- c(
  "trifft gar nicht zu"  = 1,
  "trifft eher nicht zu" = 2,
  "trifft eher zu"       = 3,
  "trifft genau zu"      = 4
)

# Kurzform enthält keine negativ gepolten Items -> keine Umpolung nötig
hsp_dims <- list(
  "Leichte Erregbarkeit (EOE)"          = c(2, 5, 8),
  "Niedrige Wahrnehmungsschwelle (LST)" = c(1, 4, 9),
  "Hohe Empfindsamkeit (HSE)"           = c(3, 6, 7)
)
hsp_dim_codes <- c(EOE = 1, LST = 2, HSE = 3)

# Kennwerte der Kurzform (Satow, 2022, Tab. 9; n = 65 280)
hsp_norm <- data.frame(
  scale = c(names(hsp_dims), "Gesamtscore"),
  code  = c(names(hsp_dim_codes), "gesamt"),
  M     = c(9.40, 9.37, 10.07, 28.84),
  SD    = c(2.12, 2.02, 1.82, 4.05),
  min   = c(3, 3, 3, 9),
  max   = c(12, 12, 12, 36)
)

# Standard-Erhebungswelle: Datum (trennt Vorlesungstermine automatisch)
default_welle <- function() format(Sys.Date(), "%Y-%m-%d")
