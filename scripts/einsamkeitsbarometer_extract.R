# Extrahiert Tabellen nach Geschlecht aus dem statistischen Anhang
# des Einsamkeitsbarometers 2024 und speichert sie als CSV.
library(pdftools)

pdf <- "resources/einsamkeitsbarometer-2024-statistischer-anhang-data.pdf"
txt <- pdf_text(pdf)

rowre <- paste0(
  "^(.*?)\\s*(\\d{4}) (Männlich|Weiblich) ",
  "([0-9,]+) ([0-9,]+) ([0-9,]+) ([0-9,]+) ([0-9,]+) ([0-9.]+)\\s*(.*)$"
)

num <- function(x) as.numeric(gsub(",", ".", gsub("\\.", "", x)))

parse_pages <- function(pages, indikator) {
  l <- unlist(lapply(txt[pages], \(p) strsplit(p, "\n")[[1]]))
  l <- trimws(gsub("\\s+", " ", l))
  l <- l[l != ""]
  idx <- grep(rowre, l)
  m <- regmatches(l[idx], regexec(rowre, l[idx]))
  # Kontext (Vor-/Folgezeile + Präfix), um Instrument/Unterindikator zu bestimmen
  ctx <- vapply(seq_along(idx), \(i) {
    paste(l[idx[i] - 1], m[[i]][2], m[[i]][11], l[idx[i] + 1])
  }, character(1))
  data.frame(
    indikator = indikator,
    kontext = ctx,
    prefix = vapply(m, `[`, "", 2),
    jahr = as.integer(vapply(m, `[`, "", 3)),
    geschlecht = vapply(m, `[`, "", 4),
    anteil = num(vapply(m, `[`, "", 5)),
    ki_oben = num(vapply(m, `[`, "", 6)),
    ki_unten = num(vapply(m, `[`, "", 7)),
    se = num(vapply(m, `[`, "", 8)),
    deff = num(vapply(m, `[`, "", 9)),
    n = num(vapply(m, `[`, "", 10))
  )
}

einsam <- parse_pages(16, "Erhöhte Einsamkeitsbelastung")
einsam$instrument <- ifelse(
  grepl("^1-Item", einsam$prefix), "1-Item",
  ifelse(grepl("COV2", einsam$kontext), "UCLA (COV2-Studie)", "UCLA")
)

zufr <- parse_pages(46:47, "Hohe Zufriedenheit")
zufr$instrument <- NA_character_
zufr$indikator <- ifelse(
  grepl("Freun", zufr$kontext),
  "Hohe Zufriedenheit mit Freundeskreis",
  "Hohe Zufriedenheit mit Familie"
)

rest <- rbind(
  parse_pages(54:55, "Ehrenamt (mind. 1x/Monat)"),
  parse_pages(60:61, "Kirchgang (mind. 1x/Monat)"),
  parse_pages(63:64, "Aktiver Sport (mind. 1x/Monat)"),
  parse_pages(68:69, "Popkulturelle Events (mind. 1x/Monat)"),
  parse_pages(73, "Künstlerische Aktivität (mind. 1x/Monat)")
)
rest$instrument <- NA_character_

# COV2-Studie (nur 2020) ausschließen
einsam <- einsam[einsam$instrument != "UCLA (COV2-Studie)", ]

out <- rbind(einsam, zufr, rest)
out$indikator <- ifelse(
  out$indikator == "Erhöhte Einsamkeitsbelastung",
  paste0("Erhöhte Einsamkeitsbelastung (", out$instrument, ")"),
  out$indikator
)
out <- out[, c("indikator", "jahr", "geschlecht", "anteil",
               "ki_unten", "ki_oben", "se", "deff", "n")]

write.csv(out, "data/einsamkeitsbarometer_geschlecht.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
