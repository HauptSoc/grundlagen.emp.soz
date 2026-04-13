library(shiny)

ui <- fluidPage(
  titlePanel("Bild' dir deine (stetige) Verteilung!"),
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        tabPanel("Verteilung A",
                 h4("Verteilung A"),
                 sliderInput("mu1",  "Mittelwert μ",    min = -3, max = 3,  value = 0,  step = 0.5),
                 sliderInput("var1", "Varianz σ²",     min = 1, max = 7, value = 1,  step = 0.5),
                 sliderInput("skew1","Schiefe γ1",     min = -1,  max = 1,   value = 0,  step = 0.1),
                 sliderInput("kurt1","Kurtosis γ2",    min = 1, max = 10, value = 5,  step = 1)
        ),
        tabPanel("Verteilung B",
                 h4("Verteilung B"),
                 sliderInput("mu2",  "Mittelwert μ",    min = -3, max = 3,  value = 0,  step = 0.5),
                 sliderInput("var2", "Varianz σ²",     min = 1, max = 7, value = 1,  step = 0.5),
                 sliderInput("skew2","Schiefe γ1",     min = -1,  max = 1,   value = 0,  step = 0.1),
                 sliderInput("kurt2","Kurtosis γ2",    min = 1, max = 10, value = 5,  step = 1)
        )
      ),
      hr(),
      actionButton("draw", "Neu berechnen"),
      helpText("Mathematisch nicht mögliche Kombinationen führen zu einer Fehlermeldung.")
    ),
    mainPanel(
      plotOutput("overlayPlot", height = "600px")
    )
  )
)