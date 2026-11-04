# Erzeugt einen lokalen Bildpool zufälliger LEGO-Teile für exercises/lego/index.html.
# Metadaten und Bilder: Rebrickable (Downloads ohne API-Key).
# Einmalig ausführen (Arbeitsverzeichnis = Projektwurzel). Ergebnis: img/*.jpg + pool.js

library(jsonlite)

out_dir <- "exercises/lego"
img_dir <- file.path(out_dir, "img")
dir.create(img_dir, recursive = TRUE, showWarnings = FALSE)

n_per_category <- 12
set.seed(5817)

read_rb <- function(name) {
  tf <- tempfile(fileext = ".csv.gz")
  download.file(sprintf("https://cdn.rebrickable.com/media/downloads/%s.csv.gz", name),
                tf, mode = "wb", quiet = TRUE)
  read.csv(tf)
}

elements   <- read_rb("elements")
parts      <- read_rb("parts")
categories <- read_rb("part_categories")
colors     <- read_rb("colors")

# Systemfremde bzw. für die Übung unpassende Kategorien (Duplo, Sticker, Modulex, ...)
excluded_cats <- c(4, 13, 41, 42, 43, 48, 50, 57, 58, 62, 63, 64, 66, 77, 78)

pool <- elements |>
  merge(parts, by = "part_num") |>
  subset(part_material == "Plastic" &
           !part_cat_id %in% excluded_cats &
           # bedruckte/gemusterte Varianten weglassen: Fokus auf Form
           !grepl("pr|pat", part_num))

# Pro Teil nur ein Element (neueste Element-ID), damit 30 *verschiedene* Teile gezogen werden
pool <- pool[order(pool$part_num, -pool$element_id), ]
pool <- pool[!duplicated(pool$part_num), ]

# Geschichtet ziehen, damit seltene Kategorien vertreten sind
pool <- do.call(rbind, lapply(split(pool, pool$part_cat_id), \(d) {
  d[sample(nrow(d), min(nrow(d), n_per_category * 2)), ]
}))

download_img <- function(id) {
  dest <- file.path(img_dir, paste0(id, ".jpg"))
  if (file.exists(dest)) return(TRUE)
  ok <- tryCatch({
    download.file(sprintf("https://cdn.rebrickable.com/media/parts/elements/%s.jpg", id),
                  dest, mode = "wb", quiet = TRUE)
    file.size(dest) > 2000
  }, error = \(e) FALSE, warning = \(w) FALSE)
  if (!ok && file.exists(dest)) file.remove(dest)
  ok
}

# Kandidaten herunterladen, bis pro Kategorie n_per_category Bilder vorliegen
pool <- do.call(rbind, lapply(split(pool, pool$part_cat_id), \(d) {
  keep <- logical(nrow(d))
  for (i in seq_len(nrow(d))) {
    if (sum(keep) >= n_per_category) break
    keep[i] <- download_img(d$element_id[i])
    Sys.sleep(0.2)
  }
  d[keep, ]
}))

pool <- pool |>
  merge(setNames(categories, c("part_cat_id", "category")), by = "part_cat_id") |>
  merge(setNames(colors[, c("id", "name")], c("color_id", "color")), by = "color_id")

meta <- data.frame(
  element_id = pool$element_id,
  part_num   = pool$part_num,
  name       = pool$name,
  category   = pool$category,
  color      = pool$color
)

# Als JS statt JSON, damit index.html auch per Doppelklick (file://) funktioniert
writeLines(paste0("window.LEGO_POOL = ", toJSON(meta, auto_unbox = TRUE), ";"),
           file.path(out_dir, "pool.js"))

# Verwaiste Bilder aus früheren Läufen entfernen
stale <- setdiff(list.files(img_dir), paste0(meta$element_id, ".jpg"))
file.remove(file.path(img_dir, stale))

message(nrow(meta), " Teile in ", length(unique(meta$category)), " Kategorien")
