library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(haven)

hours <- readRDS("hours.rds")

hours_clean <- hours |>
  mutate(
    sex_c = case_when(
      as.numeric(sex_c) %in% c(1, 2) ~ as.numeric(sex_c),
      TRUE ~ NA_real_
    ),
    sex_c = factor(sex_c, levels = c(1, 2), labels = c("Male", "Female"))
  )

ui <- page_sidebar(
  theme = bs_theme(),
  title = "Arbeitsstunden in Erwerbsarbeit ",
  sidebar = sidebar(
    sliderInput(
      inputId = "smooth",
      label = "Smoothing (Bandbreitenfaktor)",
      min = 0.2,
      max = 3,
      value = 1,
      step = 0.1
    ),
    checkboxInput(
      inputId = "by_sex",
      label = "Getrennt nach Geschlecht",
      value = FALSE
    ),
    conditionalPanel(
      condition = "!input.by_sex",
      checkboxInput(
        inputId = "show_hist",
        label = "Histogramm",
        value = FALSE
      ),
      conditionalPanel(
        condition = "!input.by_sex && input.show_hist",
        sliderInput(
          inputId = "hist_bins",
          label = "Anzahl Klassen (Histogramm)",
          min = 5,
          max = 60,
          value = 30,
          step = 1
        )
      )
    )
  ),
  plotOutput("density_plot", height = "600px")
)

server <- function(input, output, session) {
  observeEvent(input$by_sex, {
    if (isTRUE(input$by_sex)) {
      updateCheckboxInput(session, "show_hist", value = FALSE)
    }
  })

  output$density_plot <- renderPlot({
    base_dat <- hours_clean |>
      filter(!is.na(job56))

    if (isTRUE(input$by_sex)) {
      dat <- base_dat |>
        filter(!is.na(sex_c))

      ggplot(dat, aes(x = job56, color = sex_c, fill = sex_c)) +
        geom_density(alpha = 0.25, adjust = input$smooth) +
        coord_cartesian(xlim = c(0, 70)) +
        labs(
          x = "job56",
          y = "Dichte",
          color = "Geschlecht",
          fill = "Geschlecht"
        )
    } else {
      p <- ggplot(base_dat, aes(x = job56))

      if (isTRUE(input$show_hist)) {
        p <- p +
          geom_histogram(
            aes(y = after_stat(density)),
            bins = input$hist_bins,
            fill = "grey70",
            color = "white",
            alpha = 0.6
          )
      }

      p +
        geom_density(fill = "#4C78A8", alpha = 0.35, adjust = input$smooth) +
        coord_cartesian(xlim = c(0, 70)) +
        labs(
          x = "Arbeitsstunden",
          y = "Dichte"
        )
    }
  })
}

shinyApp(ui, server)