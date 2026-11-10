# Erzeugt die Baumdiagramme für 02-Unterscheiden_Grundlagen.qmd als statische SVGs
# (ersetzt die früheren Mermaid-Blöcke). Stil wie images/familien-differenzierung.svg.

out_dir <- "slides/images"

# Knoten: list(label = "Zeile 1\nZeile 2", grp = "in"/"out"/NULL, children = list(...))
nd <- function(label, ..., grp = NULL) list(label = label, grp = grp, children = list(...))

fills <- list(
  root = c(fill = "#e9edf2", stroke = "#5b7a99"),
  `in` = c(fill = "#fde9d3", stroke = "#d98a3d"),
  out  = c(fill = "#eef3f8", stroke = "#5b7a99")
)

esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

render_tree <- function(tree, file, box_w = 260, gap_x = 28, gap_y = 70,
                        font = 22, line_h = 27, pad = 20, margin = 20) {
  n_lines <- function(n) length(strsplit(n$label, "\n", fixed = TRUE)[[1]])

  # Tiefe und Zeilen pro Ebene bestimmen
  depth_lines <- integer()
  walk <- function(n, d) {
    depth_lines[d] <<- max(depth_lines[d], n_lines(n), na.rm = TRUE)
    for (ch in n$children) walk(ch, d + 1)
  }
  walk(tree, 1)
  level_h <- depth_lines * line_h + 2 * pad
  level_y <- margin + c(0, cumsum(level_h + gap_y))[seq_along(level_h)]

  # x-Positionen: Blätter von links nach rechts, Eltern mittig über Kindern
  next_x <- margin
  place <- function(n, d, grp) {
    n$depth <- d
    n$grp <- if (is.null(n$grp)) grp else n$grp
    if (length(n$children) == 0) {
      n$x <- next_x
      next_x <<- next_x + box_w + gap_x
    } else {
      n$children <- lapply(n$children, place, d = d + 1, grp = n$grp)
      xs <- vapply(n$children, `[[`, numeric(1), "x")
      n$x <- mean(range(xs))
    }
    n
  }
  tree$grp <- "root"
  tree <- place(tree, 1, "root")

  width  <- next_x - gap_x + margin
  height <- max(level_y + level_h) + margin
  svg <- character()
  add <- function(...) svg <<- c(svg, paste0(...))

  draw <- function(n) {
    d <- n$depth
    y <- level_y[d]
    h <- level_h[d]
    cx <- n$x + box_w / 2
    col <- fills[[n$grp]]
    bold <- if (d == 1) ' font-weight="bold"' else ""
    add(sprintf('<rect x="%.1f" y="%.1f" width="%d" height="%d" rx="8" fill="%s" stroke="%s" stroke-width="2"/>',
                n$x, y, box_w, h, col[["fill"]], col[["stroke"]]))
    lines <- strsplit(n$label, "\n", fixed = TRUE)[[1]]
    y0 <- y + h / 2 - (length(lines) - 1) * line_h / 2
    for (i in seq_along(lines)) {
      add(sprintf('<text x="%.1f" y="%.1f" text-anchor="middle" dominant-baseline="central" font-size="%d"%s>%s</text>',
                  cx, y0 + (i - 1) * line_h, font, bold, esc(lines[i])))
    }
    if (length(n$children) > 0) {
      y_bot <- y + h
      y_mid <- y_bot + gap_y / 2
      for (ch in n$children) {
        ccx <- ch$x + box_w / 2
        add(sprintf('<path d="M%.1f,%.1f V%.1f H%.1f V%.1f" fill="none" stroke="#444" stroke-width="2.5" marker-end="url(#a)"/>',
                    cx, y_bot, y_mid, ccx, level_y[d + 1] - 2))
        draw(ch)
      }
    }
  }

  add(sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" width="%.0f" height="%.0f" font-family="Arial, Helvetica, sans-serif">',
              width, height, width, height))
  add('<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#444"/></marker></defs>')
  add('<rect width="100%" height="100%" fill="white"/>')
  draw(tree)
  add("</svg>")
  writeLines(svg, file.path(out_dir, file), useBytes = TRUE)
  invisible(c(width = width, height = height))
}

# 1) Überblick über die Definitionen ------------------------------------------
render_tree(
  nd("Definitionen von\nIn-Group/Out-Group",
     nd("Externe\nKlassifizierung",
        nd("V1: Staatsangehörigkeit\n(Person oder mind.\nein Elternteil)"),
        nd("V2: Migrations-\ngeschichte (Eingewan-\nderte + Kinder)"),
        nd("V3: Einwanderungs-\ngeschichte (Person o.\nbeide Eltern ab 1950)"),
        nd("V4: Geburtsort\n(im Ausland\ngeboren)")),
     nd("Subjektive\nKlassifizierung",
        nd("V5: Selbst-\npositionierung"))),
  "mh-definitionen-ueberblick.svg", box_w = 248, gap_x = 22
)

# 2) Version 1: Staatsangehörigkeit -------------------------------------------
render_tree(
  nd("Alle Personen\nin Deutschland",
     nd("Mit Migrations-\nhintergrund", grp = "in",
        nd("Person selbst nicht mit\ndt. Staatsangehörig-\nkeit geboren"),
        nd("Mind. ein Elternteil\nnicht mit dt. Staats-\nangehörigkeit geboren")),
     nd("Ohne Migrations-\nhintergrund", grp = "out",
        nd("Person und beide\nEltern mit dt. Staats-\nangehörigkeit geboren"))),
  "mh-v1-staatsangehoerigkeit.svg", box_w = 300, gap_x = 40, gap_y = 50
)

# 3) Version 2: Migrationsgeschichte ------------------------------------------
render_tree(
  nd("Bevölkerung",
     nd("Eingewanderte und\nihre Kinder", grp = "in",
        nd("Selbst\neingewandert"),
        nd("Kinder von\nEingewanderten")),
     nd("Ohne Migrations-\ngeschichte", grp = "out",
        nd("Enkel von Einge-\nwanderten (3. Gen.)\nund später"),
        nd("Keine Einwan-\nderung in der\nFamilie"))),
  "mh-v2-migrationsgeschichte.svg", box_w = 270, gap_x = 36
)

# 4) Version 3: Einwanderungsgeschichte ---------------------------------------
render_tree(
  nd("Bevölkerung",
     nd("Mit Einwanderungs-\ngeschichte", grp = "in",
        nd("Selbst seit 1950\neingewandert"),
        nd("Beide Elternteile\nseit 1950\neingewandert")),
     nd("Ohne Einwanderungs-\ngeschichte", grp = "out",
        nd("Nur ein Elternteil\nseit 1950\neingewandert"),
        nd("Weder Person noch\nEltern seit 1950\neingewandert"))),
  "mh-v3-einwanderungsgeschichte.svg", box_w = 270, gap_x = 36
)

# 5) Version 4: Geburtsort ----------------------------------------------------
render_tree(
  nd("Bevölkerung",
     nd("Im Ausland geboren\n(eingewandert)", grp = "in"),
     nd("Im heutigen Bundes-\ngebiet geboren", grp = "out")),
  "mh-v4-geburtsort.svg", box_w = 300, gap_x = 80
)

# 6) Version 5: Subjektive Einordnung -----------------------------------------
render_tree(
  nd("Bevölkerung",
     nd("Minderheits-\nidentifikation", grp = "in",
        nd("„Afrikanisch“"),
        nd("„Schwarz“"),
        nd("„Muslimisch“"),
        nd("Andere\nKategorien")),
     nd("Mehrheits-\nidentifikation", grp = "out")),
  "mh-v5-subjektiv.svg", box_w = 220, gap_x = 30
)
