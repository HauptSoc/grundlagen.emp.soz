library(shiny)
library(tidyverse)
library(ggiraph)

set.seed(123)

simulate_counts <- function(n, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Wahre Wahrscheinlichkeiten (Simulation)
  p_bin <- c("0" = 0.58, "1" = 0.42)
  p_nom <- set_names(rep(1 / 9, 9), paste0("Kat_", 1:9))
  p_ord <- c(
    "Sehr niedrig" = 0.12,
    "Niedrig" = 0.20,
    "Mittel" = 0.34,
    "Hoch" = 0.22,
    "Sehr hoch" = 0.12
  )

  # Simulieren
  df_bin <- tibble(
    kategorie = sample(names(p_bin), size = n, replace = TRUE, prob = p_bin)
  )

  df_nom <- tibble(
    kategorie = sample(names(p_nom), size = n, replace = TRUE, prob = p_nom)
  )

  df_ord <- tibble(
    kategorie = sample(names(p_ord), size = n, replace = TRUE, prob = p_ord)
  )

  # Relative Häufigkeiten + wahrer Wert pro Kategorie
  bin_counts <- df_bin |>
    count(kategorie, name = "n") |>
    complete(kategorie = names(p_bin), fill = list(n = 0)) |>
    mutate(
      kategorie = factor(kategorie, levels = names(p_bin)),
      rel = n / sum(n),
      true_p = unname(p_bin[as.character(kategorie)]),
      diff = rel - true_p,
      tooltip = paste0(
        "Kategorie: ", kategorie, "\n",
        "Relative Häufigkeit: ", scales::percent(rel, accuracy = 0.1), "\n",
        "Wahrer Wert: ", scales::percent(true_p, accuracy = 0.1), "\n",
        "Differenz (beobachtet - wahr): ", scales::percent(diff, accuracy = 0.1)
      )
    )

  nom_counts <- df_nom |>
    count(kategorie, name = "n") |>
    complete(kategorie = names(p_nom), fill = list(n = 0)) |>
    mutate(
      kategorie = factor(kategorie, levels = names(p_nom)),
      rel = n / sum(n),
      true_p = unname(p_nom[as.character(kategorie)]),
      diff = rel - true_p,
      tooltip = paste0(
        "Kategorie: ", kategorie, "\n",
        "Relative Häufigkeit: ", scales::percent(rel, accuracy = 0.1), "\n",
        "Wahrer Wert: ", scales::percent(true_p, accuracy = 0.1), "\n",
        "Differenz (beobachtet - wahr): ", scales::percent(diff, accuracy = 0.1)
      )
    )

  ord_counts <- df_ord |>
    count(kategorie, name = "n") |>
    complete(kategorie = names(p_ord), fill = list(n = 0)) |>
    mutate(
      kategorie = factor(kategorie, levels = names(p_ord), ordered = TRUE),
      rel = n / sum(n),
      true_p = unname(p_ord[as.character(kategorie)]),
      diff = rel - true_p,
      tooltip = paste0(
        "Kategorie: ", kategorie, "\n",
        "Relative Häufigkeit: ", scales::percent(rel, accuracy = 0.1), "\n",
        "Wahrer Wert: ", scales::percent(true_p, accuracy = 0.1), "\n",
        "Differenz (beobachtet - wahr): ", scales::percent(diff, accuracy = 0.1)
      )
    )

  list(bin = bin_counts, nom = nom_counts, ord = ord_counts)
}

plot_panel <- function(d, x_title, y_max) {
  ggplot(d, aes(x = kategorie, y = rel)) +
    ggiraph::geom_col_interactive(
      aes(
        tooltip = tooltip,
        data_id = kategorie
      ),
      fill = "#4472C4",
      width = 0.75
    ) +
    geom_segment(
      aes(
        x = as.numeric(kategorie) - 0.32,
        xend = as.numeric(kategorie) + 0.32,
        y = true_p,
        yend = true_p
      ),
      color = "#C00000",
      linewidth = 1.1
    ) +
    scale_y_continuous(
      labels = scales::label_percent(accuracy = 1),
      limits = c(0, y_max),
      expand = expansion(mult = c(0, 0.02))
    ) +
    labs(x = x_title, y = "Relative Häufigkeit") +
    theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 25, hjust = 1))
}

ui <- fluidPage(
  titlePanel("Simulierte diskrete Verteilungen"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("n", "Stichprobengröße (n)", min = 50, max = 5000, value = 600, step = 50),
      actionButton("resim", "Neu simulieren")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Binär", ggiraph::girafeOutput("plot_bin", height = "460px")),
        tabPanel("Nominal (9)", ggiraph::girafeOutput("plot_nom", height = "460px")),
        tabPanel("Ordinal (5)", ggiraph::girafeOutput("plot_ord", height = "460px"))
      )
    )
  )
)

server <- function(input, output, session) {
  sim_data <- eventReactive(
    input$resim,
    simulate_counts(n = input$n, seed = sample.int(1e6, 1)),
    ignoreNULL = FALSE
  )

  output$plot_bin <- ggiraph::renderGirafe({
    ggiraph::girafe(
      ggobj = plot_panel(sim_data()$bin, "Kategorie", y_max = 0.75),
      options = list(ggiraph::opts_tooltip(css = "background:#fff;padding:8px;border:1px solid #ccc;"))
    )
  })

  output$plot_nom <- ggiraph::renderGirafe({
    ggiraph::girafe(
      ggobj = plot_panel(sim_data()$nom, "Kategorie", y_max = 0.25),
      options = list(ggiraph::opts_tooltip(css = "background:#fff;padding:8px;border:1px solid #ccc;"))
    )
  })

  output$plot_ord <- ggiraph::renderGirafe({
    ggiraph::girafe(
      ggobj = plot_panel(sim_data()$ord, "Ordinale Kategorie", y_max = 0.50),
      options = list(ggiraph::opts_tooltip(css = "background:#fff;padding:8px;border:1px solid #ccc;"))
    )
  })
}

shinyApp(ui, server)