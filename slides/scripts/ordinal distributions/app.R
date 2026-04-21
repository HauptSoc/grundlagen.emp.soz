library(shiny)
library(ggplot2)
library(dplyr)


# ---- Latente Verteilungen ------------------------------------------------

skew_normal_density <- function(x, location = 0, scale = 1, shape = 0) {
  z <- (x - location) / scale
  2 / scale * dnorm(z) * pnorm(shape * z)
}

distribution_shape <- function(dist_name) {
  switch(
    dist_name,
    "Normalverteilung" = 0,
    "Rechtsschief" = 6,
    "Linksschief" = -6,
    0
  )
}

interval_probabilities <- function(cuts, location = 0, scale = 1, shape = 0) {
  bounds <- c(-Inf, sort(cuts), Inf)

  probs <- vapply(
    seq_len(length(bounds) - 1),
    function(i) {
      integrate(
        f = function(x) {
          skew_normal_density(
            x = x,
            location = location,
            scale = scale,
            shape = shape
          )
        },
        lower = bounds[i],
        upper = bounds[i + 1]
      )$value
    },
    numeric(1)
  )

  probs / sum(probs)
}

latent_plot_data <- function(cuts, location = 0, scale = 1, shape = 0,
                             x_min = -5, x_max = 5, step = 0.01) {
  x <- seq(x_min, x_max, by = step)
  y <- skew_normal_density(x, location = location, scale = scale, shape = shape)

  cuts_sorted <- sort(unique(cuts))
  bounds <- c(-Inf, cuts_sorted, Inf)

  groups <- cut(
    x,
    breaks = bounds,
    labels = seq_len(length(bounds) - 1),
    include.lowest = TRUE,
    right = TRUE
  )

  data.frame(
    x = x,
    y = y,
    response = factor(groups, levels = seq_len(length(bounds) - 1))
  )
}

make_density_plot <- function(cuts, location = 0, scale = 1, shape = 0) {
  df <- latent_plot_data(
    cuts = cuts,
    location = location,
    scale = scale,
    shape = shape
  )

  k <- length(sort(unique(cuts))) + 1
  cols <- c("#440154", "#3B528B", "#21918C", "#5DC863", "#FDE725")[seq_len(k)]

  ggplot(df, aes(x = x, y = y, fill = response, group = response)) +
    geom_area(alpha = 0.95) +
    geom_vline(
      xintercept = sort(unique(cuts)),
      linetype = "dashed",
      linewidth = 0.7,
      color = "grey20"
    ) +
    labs(
      title = "Latente Verteilung",
      x = "Latente Werte",
      y = "Dichte",
      fill = "Antwort"
    ) +
    scale_fill_manual(values = cols) +
    coord_cartesian(xlim = c(-5, 5)) +
    theme_minimal(base_size = 16) +
    theme(legend.position = "none")
}

make_bar_plot <- function(cuts, location = 0, scale = 1, shape = 0) {
  probs <- interval_probabilities(
    cuts = cuts,
    location = location,
    scale = scale,
    shape = shape
  )

  df <- data.frame(
    response = factor(seq_along(probs), levels = seq_along(probs)),
    prob = probs
  )

  cols <- c("#440154", "#3B528B", "#21918C", "#5DC863", "#FDE725")[seq_len(nrow(df))]

  ggplot(df, aes(x = response, y = 100 * prob, fill = response)) +
    geom_col(width = 0.9) +
    geom_text(
      aes(label = sprintf("%.1f%%", 100 * prob)),
      vjust = -0.3,
      size = 7
    ) +
    scale_fill_manual(values = cols) +
    labs(
      title = "Beobachtete Verteilung",
      x = "Likert Response",
      y = "% Responses"
    ) +
    expand_limits(y = max(100 * df$prob) + 8) +
    theme_minimal(base_size = 16) +
    theme(legend.position = "none")
}

# ---- UI ------------------------------------------------------------------

ui <- fluidPage(
  titlePanel("Latente und beobachtete Werte"),

  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "dist",
        label = "Latente Verteilung",
        choices = c("Normalverteilung", "Rechtsschief", "Linksschief"),
        selected = "Normalverteilung"
      ),

      sliderInput(
        inputId = "location",
        label = "Lage (Mittelpunkt)",
        min = -2,
        max = 2,
        value = 0,
        step = 0.1
      ),

      sliderInput(
        inputId = "scale",
        label = "Skalierung",
        min = 0.5,
        max = 2.5,
        value = 1,
        step = 0.1
      ),

      tags$hr(),

      h4("Cutpoints"),

      checkboxInput(
        inputId = "equidist",
        label = "Äquidistante Cutpoints",
        value = FALSE
      ),

      # Äquidistante Steuerung (nur sichtbar wenn equidist = TRUE)
      conditionalPanel(
        condition = "input.equidist == true",
        sliderInput(
          inputId = "eq_start",
          label = "Erster Cutpoint",
          min = -4,
          max = 2,
          value = -2,
          step = 0.1
        ),
        sliderInput(
          inputId = "eq_spacing",
          label = "Abstand zwischen Cutpoints",
          min = 0.2,
          max = 3,
          value = 1,
          step = 0.1
        )
      ),

      # Individuelle Slider (nur sichtbar wenn equidist = FALSE)
      conditionalPanel(
        condition = "input.equidist == false",
        sliderInput("cut1", "Cutpoint 1", min = -4, max = 4, value = -2.5, step = 0.1),
        sliderInput("cut2", "Cutpoint 2", min = -4, max = 4, value = -0.5, step = 0.1),
        sliderInput("cut3", "Cutpoint 3", min = -4, max = 4, value =  0.8, step = 0.1),
        sliderInput("cut4", "Cutpoint 4", min = -4, max = 4, value =  2.0, step = 0.1)
      ),

      helpText("Die vier Cutpoints werden intern sortiert.")
    ),

    mainPanel(
      plotOutput("density_plot", height = "360px"),
      plotOutput("bar_plot", height = "320px")
    )
  )
)

# ---- Server --------------------------------------------------------------

server <- function(input, output, session) {

  current_cuts <- reactive({
    if (isTRUE(input$equidist)) {
      # Äquidistante Cutpoints: Start + 3 weitere im gleichen Abstand
      start   <- input$eq_start
      spacing <- input$eq_spacing
      start + (0:3) * spacing
    } else {
      sort(c(input$cut1, input$cut2, input$cut3, input$cut4))
    }
  })

  current_shape <- reactive({
    distribution_shape(input$dist)
  })

  output$density_plot <- renderPlot({
    make_density_plot(
      cuts = current_cuts(),
      location = input$location,
      scale = input$scale,
      shape = current_shape()
    )
  })

  output$bar_plot <- renderPlot({
    make_bar_plot(
      cuts = current_cuts(),
      location = input$location,
      scale = input$scale,
      shape = current_shape()
    )
  })
}

shinyApp(ui, server)