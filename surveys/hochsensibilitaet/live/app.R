# Live-Auswertung zum Einbinden in die Slides (iframe)
# URL-Parameter:
#   plot   = dims | EOE | LST | HSE | gesamt   (Default: gesamt)
#   adjust = Faktor für die Bandbreite des Kerndichteschätzers (Default: 1)
#   hist   = 1 blendet zusätzlich ein Histogramm ein (Default: 0)
#   norm   = 0 blendet den Mittelwert der Vergleichsstichprobe aus (Default: 1)
#   w      = Erhebungswelle (Default: heutiges Datum; "alle" = alle Wellen)
library(shiny)
library(ggplot2)

source("hsp.R", encoding = "UTF-8")

theme_set(theme_minimal(base_size = 20))

empty_plot <- function(n) {
  ggplot() +
    annotate("text", x = 0, y = 0, size = 9,
             label = sprintf("Bisher %d Antworten – Anzeige ab %d", n, MIN_N)) +
    theme_void()
}

read_data <- function() {
  if (!file.exists(DATA_FILE)) return(NULL)
  read.csv(DATA_FILE, colClasses = c(id = "character", welle = "character"))
}

# Rohpunkte je Dimension summieren; Gesamtscore = Summe der Dimensionsscores
scores <- function(d) {
  m <- as.matrix(d[hsp_vars])
  s <- sapply(hsp_dims, \(items) rowSums(m[, items, drop = FALSE]))
  s <- matrix(s, ncol = length(hsp_dims), dimnames = list(NULL, names(hsp_dims)))
  data.frame(s, Gesamtscore = rowSums(s), check.names = FALSE)
}

kde_layers <- function(adjust, hist) {
  list(
    if (hist) geom_histogram(aes(y = after_stat(density)), binwidth = 1,
                             fill = "grey85", colour = "white"),
    geom_density(adjust = adjust, linewidth = 1.2, fill = "grey60", alpha = 0.3),
    # leicht verwackelt, da viele Personen denselben ganzzahligen Wert haben
    geom_rug(aes(x = jitter(x, amount = 0.15)), alpha = 0.5, length = unit(0.04, "npc"))
  )
}

plot_one <- function(s, code, adjust, hist, norm) {
  nm <- hsp_norm[hsp_norm$code == code, ]
  x <- s[[nm$scale]]
  bw <- stats::bw.nrd0(x) * adjust
  step <- if (nm$max - nm$min > 12) 3 else 1
  ggplot(data.frame(x), aes(x = x)) +
    kde_layers(adjust, hist) +
    geom_vline(xintercept = mean(x), linewidth = 1) +
    (if (norm) geom_vline(xintercept = nm$M, linetype = "dashed", linewidth = 1)) +
    # Grenzen etwas weiter als der mögliche Wertebereich, damit die Ränder der
    # Dichte sichtbar bleiben (Kerndichteschätzer kennen keine Wertegrenzen)
    scale_x_continuous(limits = c(nm$min - 2, nm$max + 2),
                       breaks = seq(nm$min, nm$max, by = step)) +
    labs(
      title = nm$scale,
      x = sprintf("Summe der Rohpunkte (möglich: %d–%d)", nm$min, nm$max),
      y = "Dichte",
      subtitle = sprintf("n = %d · M = %.1f · SD = %.1f · Bandbreite = %.2f",
                         length(x), mean(x), sd(x), bw),
      caption = if (norm) sprintf(
        "Durchgezogen: unser Mittelwert · gestrichelt: M = %.2f (Vergleichsstichprobe, Satow 2022)", nm$M
      ) else "Durchgezogen: unser Mittelwert"
    )
}

plot_dims <- function(s, adjust, hist, norm) {
  long <- do.call(rbind, lapply(names(hsp_dims), \(nm) data.frame(dimension = nm, x = s[[nm]])))
  long$dimension <- factor(long$dimension, levels = names(hsp_dims))
  means <- aggregate(x ~ dimension, long, mean)
  ref <- data.frame(dimension = factor(names(hsp_dims), levels = names(hsp_dims)),
                    M = hsp_norm$M[seq_along(hsp_dims)])
  ggplot(long, aes(x = x)) +
    kde_layers(adjust, hist) +
    geom_vline(data = means, aes(xintercept = x), linewidth = 1) +
    (if (norm) geom_vline(data = ref, aes(xintercept = M), linetype = "dashed", linewidth = 1)) +
    facet_wrap(~dimension, nrow = 1, labeller = label_wrap_gen(22)) +
    scale_x_continuous(limits = c(1, 14), breaks = c(3, 6, 9, 12)) +
    labs(x = "Summe der Rohpunkte (möglich: 3–12)", y = "Dichte",
         subtitle = sprintf("n = %d", nrow(s)),
         caption = if (norm) "Durchgezogen: unser Mittelwert · gestrichelt: Vergleichsstichprobe (Satow 2022)"
                   else "Durchgezogen: unser Mittelwert")
}

ui <- fluidPage(
  tags$style(HTML("body { background: transparent; } .container-fluid { padding: 0; }")),
  plotOutput("plot", height = "560px")
)

server <- function(input, output, session) {
  raw <- reactiveFileReader(2000, session, DATA_FILE, \(f) read_data())

  params <- reactive(parseQueryString(session$clientData$url_search))

  dat <- reactive({
    d <- raw()
    w <- params()$w %||% default_welle()
    if (is.null(d)) return(NULL)
    if (w != "alle") d <- d[d$welle == w, , drop = FALSE]
    d[stats::complete.cases(d[hsp_vars]), , drop = FALSE]
  })

  output$plot <- renderPlot({
    d <- dat()
    n <- if (is.null(d)) 0 else nrow(d)
    if (n < MIN_N) return(empty_plot(n))
    p <- params()
    adjust <- suppressWarnings(as.numeric(p$adjust %||% 1))
    if (is.na(adjust) || adjust <= 0) adjust <- 1
    hist <- identical(p$hist, "1")
    norm <- !identical(p$norm, "0")
    s <- scores(d)
    plot <- p$plot %||% "gesamt"
    if (plot == "dims") return(plot_dims(s, adjust, hist, norm))
    if (!plot %in% hsp_norm$code) plot <- "gesamt"
    plot_one(s, plot, adjust, hist, norm)
  }, res = 96)
}

shinyApp(ui, server)
