library(shiny)
library(tidyverse)

server <- function(input, output, session) {
  output$main_plot <- renderPlot({
    make_plot(
      beta_0 = input$beta_0,
      beta_1 = input$beta_1,
      sigma = input$sigma,
      display_mode = input$display_mode
    )
  })
}