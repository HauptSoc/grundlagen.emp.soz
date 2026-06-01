library(shiny)
library(tidyverse)

ui <- fluidPage(
  titlePanel("Lineare Regression: Interaktive Grundlage"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("beta0", "Intercept (beta_0)", min = -1, max = 2, value = 0.9, step = 0.05),
      sliderInput("beta1", "Steigung (beta_1)", min = -2, max = 2, value = 0.65, step = 0.05),
      sliderInput("sigma", "Streuung (sigma)", min = 0.05, max = 1.5, value = 0.55, step = 0.05),
      radioButtons(
        "display_mode",
        "Darstellung",
        choices = c(
          "Nur Datenpunkte" = "points",
          "Nur Verteilungen" = "densities",
          "Beides übereinander" = "both"
        ),
        selected = "both"
      )
    ),
    mainPanel(
      plotOutput("reg_plot", height = "650px")
    )
  )
)