library(shiny)
library(dplyr)
library(plotly)
library(tibble)

make_data <- function(n = sample(80:160, 1)) {
  alpha <- runif(1, -5, 15)
  beta <- runif(1, -1.5, 3.5)
  sigma <- runif(1, 3, 12)

  x <- runif(n, 0, 20)
  y <- alpha + beta * x + rnorm(n, sd = sigma)

  list(
    data = tibble(
      id = seq_len(n),
      x = x,
      y = y
    ),
    alpha = alpha,
    beta = beta,
    sigma = sigma
  )
}

ui <- fluidPage(
  titlePanel('Lineare Regression interaktiv verstehen'),
  fluidRow(
    column(
      width = 3,
      checkboxInput('show_ols', 'OLS-Gerade anzeigen', value = FALSE),
      sliderInput('beta0', 'Intercept (β0)', min = -10, max = 10, value = 0, step = 0.1),
      sliderInput('beta1', 'Steigung (β1)', min = -2, max = 2, value = 0, step = 0.01),
      checkboxInput('show_truth', 'Wahre Parameter anzeigen', value = FALSE),
      actionButton('new_data', 'Neue Zufallsdaten'),
      actionButton('reset_ols', 'Auf OLS zurücksetzen'),
      tags$hr(),
      conditionalPanel(
        condition = 'input.show_truth',
        wellPanel(
          style = 'margin-bottom: 0;',
          strong('Wahre Parameter'),
          verbatimTextOutput('truth_params')
        )
      ),
      tags$hr(),
      tags$p('Punkte anklicken: Residuen zur OLS-Gerade ein- oder ausblenden.'),
      tags$p('Die manuelle Gerade wird über die Slider gesteuert.'),
      tags$hr(),
      tags$strong('Farben'),
      tags$ul(
        tags$li('Blau: manuelle Gerade'),
        tags$li('Grün gestrichelt: OLS-Gerade'),
        tags$li('Orange: ausgewählte Punkte und ihre Residuen zur OLS-Gerade')
      ),
      tags$hr(),
      tableOutput('metrics')
    ),
    column(
      width = 9,
      plotlyOutput('scatter', height = 620)
    )
  )
)

server <- function(input, output, session) {
  initial_sample <- make_data()
  rv <- reactiveValues(sample = initial_sample)

  current_data <- reactive(rv$sample$data)

  current_ols <- reactive({
    lm(y ~ x, data = current_data())
  })

  state <- reactiveValues(
    selected = integer(0)
  )

  make_slider_limits <- function(sample) {
    d <- sample$data
    x_span <- max(diff(range(d$x, na.rm = TRUE)), 1e-6)
    y_span <- max(diff(range(d$y, na.rm = TRUE)), 1e-6)

    alpha <- sample$alpha
    beta <- sample$beta
    slope_scale <- max(abs(beta), y_span / x_span, 0.5)

    list(
      beta0 = list(
        min = alpha - runif(1, 0.35, 0.8) * y_span,
        max = alpha + runif(1, 1.0, 1.8) * y_span
      ),
      beta1 = list(
        min = beta - runif(1, 0.25, 0.7) * slope_scale,
        max = beta + runif(1, 0.9, 1.8) * slope_scale
      )
    )
  }

  clamp_value <- function(value, lower, upper) {
    if (is.null(value) || length(value) == 0 || is.na(value)) {
      return((lower + upper) / 2)
    }

    max(lower, min(upper, value))
  }

  observeEvent(current_data(), {
    sample <- rv$sample
    limits <- make_slider_limits(sample)

    b0_min <- limits$beta0$min
    b0_max <- limits$beta0$max
    b1_min <- limits$beta1$min
    b1_max <- limits$beta1$max

    b0_value <- clamp_value(input$beta0, b0_min, b0_max)
    b1_value <- clamp_value(input$beta1, b1_min, b1_max)

    updateSliderInput(
      session,
      'beta0',
      min = round(b0_min, 2),
      max = round(b0_max, 2),
      value = round(b0_value, 2),
      step = 0.1
    )

    updateSliderInput(
      session,
      'beta1',
      min = round(b1_min, 3),
      max = round(b1_max, 3),
      value = round(b1_value, 3),
      step = 0.01
    )
  }, ignoreInit = FALSE)

  observeEvent(input$new_data, {
    rv$sample <- make_data()
    state$selected <- integer(0)
  })

  observeEvent(input$reset_ols, {
    cf <- coef(current_ols())
    updateSliderInput(session, 'beta0', value = unname(cf[1]))
    updateSliderInput(session, 'beta1', value = unname(cf[2]))
    state$selected <- integer(0)
  })

  observeEvent(event_data('plotly_click', source = 'reg'), {
    click <- event_data('plotly_click', source = 'reg')
    if (is.null(click) || is.null(click$key)) {
      return()
    }

    id_clicked <- as.integer(click$key)
    if (is.na(id_clicked)) {
      return()
    }

    if (id_clicked %in% state$selected) {
      state$selected <- setdiff(state$selected, id_clicked)
    } else {
      state$selected <- c(state$selected, id_clicked)
    }
  })

  output$truth_params <- renderText({
    req(isTRUE(input$show_truth))
    s <- rv$sample
    sprintf(
      'alpha = %.2f\nbeta  = %.2f\nsigma = %.2f',
      s$alpha,
      s$beta,
      s$sigma
    )
  })

  output$scatter <- renderPlotly({
    d <- current_data() |>
      mutate(selected = id %in% state$selected)

    cf <- coef(current_ols())
    b0_ols <- unname(cf[1])
    b1_ols <- unname(cf[2])

    d <- d |>
      mutate(yhat_ols = b0_ols + b1_ols * x)

    p <- plot_ly(
      data = d,
      x = ~x,
      y = ~y,
      key = ~id,
      source = 'reg',
      type = 'scatter',
      mode = 'markers',
      marker = list(size = 8, opacity = 0.75, color = 'gray35'),
      hovertemplate = 'x = %{x:.2f}<br>y = %{y:.2f}<extra></extra>',
      name = 'Daten'
    )

    if (isTRUE(input$show_ols)) {
      d_sel <- d |>
        filter(selected)

      if (nrow(d_sel) > 0) {
        p <- p |>
          add_segments(
            data = d_sel,
            x = ~x,
            xend = ~x,
            y = ~y,
            yend = ~yhat_ols,
            inherit = FALSE,
            line = list(color = '#D55E00', width = 2),
            hoverinfo = 'skip',
            showlegend = FALSE
          ) |>
          add_trace(
            data = d_sel,
            x = ~x,
            y = ~y,
            type = 'scatter',
            mode = 'markers',
            inherit = FALSE,
            marker = list(size = 9, color = '#D55E00', opacity = 0.95),
            hoverinfo = 'skip',
            showlegend = FALSE
          )
      }

      p <- p |>
        add_trace(
          x = d$x,
          y = b0_ols + b1_ols * d$x,
          type = 'scatter',
          mode = 'lines',
          inherit = FALSE,
          line = list(color = '#009E73', dash = 'dash', width = 2),
          name = 'OLS'
        )
    }

    p |>
      add_trace(
        x = d$x,
        y = input$beta0 + input$beta1 * d$x,
        type = 'scatter',
        mode = 'lines',
        inherit = FALSE,
        line = list(color = '#0072B2', width = 2),
        name = 'Manuell'
      ) |>
      layout(
        dragmode = 'zoom',
        xaxis = list(title = 'x'),
        yaxis = list(title = 'y'),
        title = list(text = 'Blau = manuelle Gerade | Grün gestrichelt = OLS')
      ) |>
      config(displayModeBar = TRUE) |>
      event_register('plotly_click')
  })

  output$metrics <- renderTable({
    d <- current_data()
    cf <- coef(current_ols())
    b0_ols <- unname(cf[1])
    b1_ols <- unname(cf[2])

    yhat_manual <- input$beta0 + input$beta1 * d$x
    yhat_ols <- b0_ols + b1_ols * d$x

    sse_manual <- sum((d$y - yhat_manual)^2)
    sse_ols <- sum((d$y - yhat_ols)^2)

    tibble(
      Kennzahl = c(
        'β0 (manuell)',
        'β1 (manuell)',
        'SSE (manuell)',
        'SSE (OLS)',
        'Differenz SSE'
      ),
      Wert = c(
        input$beta0,
        input$beta1,
        sse_manual,
        sse_ols,
        sse_manual - sse_ols
      )
    ) |>
      mutate(Wert = round(Wert, 3))
  })
}

shinyApp(ui, server)
