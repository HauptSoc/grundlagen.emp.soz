library(shiny)

ui <- fluidPage(
  titlePanel("Regression-Visualisierung"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("beta_0", "beta_0", min = -2, max = 3, value = 0.9, step = 0.05),
      sliderInput("beta_1", "beta_1", min = -2, max = 2, value = 0.65, step = 0.05),
      sliderInput("sigma", "sigma", min = 0.05, max = 2, value = 0.55, step = 0.05),
      selectInput(
        "display_mode",
        "Anzeige",
        choices = c("both", "densities", "points"),
        selected = "both"
      )
    ),
    mainPanel(
      plotOutput("main_plot", height = "600px")
    )
  )
)