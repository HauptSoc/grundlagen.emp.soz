# Live-Auswertung zum Einbinden in die Slides (iframe)
# URL-Parameter:
#   plot = items | dims | score   (Default: score)
#   w    = Erhebungswelle (Default: heutiges Datum; "alle" = alle Wellen)
library(shiny)
library(ggplot2)

source("kse.R", encoding = "UTF-8")

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

plot_items <- function(d) {
  long <- do.call(rbind, lapply(seq_along(kse_vars), \(i) {
    data.frame(item = i, antwort = d[[kse_vars[i]]])
  }))
  item_dim <- stack(kse_dims)
  long$dimension <- item_dim$ind[match(long$item, item_dim$values)]
  long$label <- paste0(
    long$item, ". ", strtrim(kse_items[long$item], 45),
    ifelse(nchar(kse_items[long$item]) > 45, "…", "")
  )
  long$label <- reorder(long$label, -long$item)
  long$antwort <- factor(long$antwort, levels = 4:1, labels = rev(names(kse_labels)))

  ggplot(long, aes(y = label, fill = antwort)) +
    geom_bar(position = "fill") +
    facet_grid(dimension ~ ., scales = "free_y", space = "free_y",
               labeller = label_wrap_gen(14)) +
    scale_x_continuous(labels = scales::percent) +
    scale_fill_brewer(palette = "RdBu", direction = 1) +
    guides(fill = guide_legend(reverse = TRUE)) +
    labs(x = NULL, y = NULL, fill = NULL,
         subtitle = sprintf("n = %d", nrow(d))) +
    theme(legend.position = "top", axis.text.y = element_text(size = 13),
          strip.text.y = element_text(angle = 0, face = "bold"))
}

score_matrix <- function(d) {
  m <- as.matrix(d[kse_vars])
  m[, kse_reverse] <- 5 - m[, kse_reverse]
  m
}

plot_dims <- function(d) {
  m <- score_matrix(d)
  sc <- do.call(rbind, lapply(names(kse_dims), \(nm) {
    data.frame(dimension = nm, wert = rowMeans(m[, kse_dims[[nm]], drop = FALSE]))
  }))
  sc$dimension <- factor(sc$dimension, levels = names(kse_dims))
  ggplot(sc, aes(x = wert)) +
    geom_histogram(binwidth = 0.25, boundary = 1) +
    facet_wrap(~dimension, nrow = 1, labeller = label_wrap_gen(20)) +
    scale_x_continuous(limits = c(1, 4), breaks = 1:4) +
    labs(x = "Mittelwert der Items (1 = gar nicht einsam, 4 = sehr einsam)",
         y = "Anzahl", subtitle = sprintf("n = %d", nrow(d)))
}

plot_score <- function(d) {
  s <- rowSums(score_matrix(d))
  ggplot(data.frame(s), aes(x = s)) +
    geom_histogram(binwidth = 2, boundary = 20) +
    geom_vline(xintercept = mean(s), linewidth = 1) +
    geom_vline(xintercept = 33.36, linetype = "dashed") +
    scale_x_continuous(limits = c(20, 80), breaks = seq(20, 80, 10)) +
    labs(x = "Einsamkeitsscore (Summe, 20–80)", y = "Anzahl",
         subtitle = sprintf("n = %d · M = %.1f · SD = %.1f", length(s), mean(s), sd(s)),
         caption = "Durchgezogen: unser Mittelwert · gestrichelt: M = 33.4 (Studierendenstichprobe der KSE)")
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
    d[stats::complete.cases(d[kse_vars]), , drop = FALSE]
  })

  output$plot <- renderPlot({
    d <- dat()
    n <- if (is.null(d)) 0 else nrow(d)
    if (n < MIN_N) return(empty_plot(n))
    switch(params()$plot %||% "score",
           items = plot_items(d),
           dims  = plot_dims(d),
           plot_score(d))
  }, res = 96)
}

shinyApp(ui, server)
