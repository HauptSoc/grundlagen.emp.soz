library(shiny)

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
      .sidebar { background-color: #f5f5f5; }
      h3 { color: #333; margin-top: 20px; }
      .slider-container { margin: 15px 0; }
      .animation-controls { 
        background-color: #e8f4f8; 
        padding: 15px; 
        border-radius: 5px;
        margin: 15px 0;
      }
      .line-controls {
        background-color: #f8f8e8;
        padding: 15px;
        border-radius: 5px;
        margin: 15px 0;
      }
      .interaction-options {
        background-color: #f0e8f8;
        padding: 15px;
        border-radius: 5px;
        margin: 15px 0;
        display: none;
      }
      .interaction-options.show {
        display: block;
      }
    "))
  ),
  
  titlePanel("Multivariate Regression: Animation von bivariaten zu bereinigten Effekten"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Einstellungen"),
      
      radioButtons(
        "dag_type",
        label = "DAG-Szenario:",
        choices = c(
          "a) Konfundierung (Confounder)" = "confounding",
          "b) Mediation (Vermittlung)" = "mediation",
          "c) Scheinkorrelation (Spurious)" = "spurious",
          "d) Interaktion (Moderation)" = "interaction"
        ),
        selected = "confounding"
      ),
      
      # Bedingter Text für Interaktion
      uiOutput("interaction_explanation"),
      
      br(),
      
      actionButton(
        "generate",
        "Neue Daten generieren",
        class = "btn btn-primary",
        width = "100%"
      ),
      
      br(), br(),
      
      # Animation Controls
      div(
        class = "animation-controls",
        h4("Animation"),
        
        # Slider für manuelle Animation
        div(
          class = "slider-container",
          p("Ziehe den Slider von links (bivariate) nach rechts (partial):")
        ),
        
        sliderInput(
          "animate_slider",
          label = "Animationsprogress:",
          min = 0,
          max = 1,
          value = 0,
          step = 0.01,
          width = "100%"
        ),
        
        br(),
        
        # Button für automatische Animation
        actionButton(
          "animate",
          "Automatisch abspielen",
          class = "btn btn-success",
          width = "100%"
        )
      ),
      
      # Regressionsgerade-Optionen
      div(
        class = "line-controls",
        h4("Regressionsgeraden"),
        checkboxInput(
          "show_bivariate_line",
          "Bivariate Gerade anzeigen (Y ~ X, blau)",
          value = FALSE
        ),
        checkboxInput(
          "show_partial_line",
          "Partielle Gerade anzeigen (Y ~ X | Z, rot)",
          value = FALSE
        ),
        p(
          "Hinweis: Standardmäßig sind beide aus. Aktiviere sie um zu sehen, wie sich die Effekte unterscheiden.",
          style = "font-size: 11px; color: #666;"
        )
      ),
      
      # Interaktion-spezifische Optionen
      div(
        id = "interaction_options",
        class = "interaction-options",
        h4("Interaktions-Optionen"),
        checkboxInput(
          "show_group_lines",
          "Gruppenspezifische Regressionsgeraden anzeigen",
          value = FALSE
        ),
        p(
          "Zeigt separate Regressionslinien für Z=0 und Z=1 (gepunktete Linien)",
          style = "font-size: 11px; color: #666;"
        )
      ),
      
      hr(),
      
      p(
        tags$strong("Erklärung:"),
        br(),
        "Die Animation zeigt den Übergang von ",
        tags$em("bivariaten"),
        " Zusammenhängen (rohe Y-Werte)",
        " zu ",
        tags$em("partiellen"),
        " Zusammenhängen (residuale Y-Werte nach Kontrolle für Z).",
        br(), br(),
        tags$strong("Beobachte:"),
        br(),
        "• Wie Punkte von (X, Y) zu (X|Z, Y|Z) gleiten",
        br(),
        "• Wie Mittelwerte (Diamanten) zusammenkommen",
        br(),
        "• Wie sich die Effektgröße verändert",
        style = "font-size: 12px; color: #555;"
      )
    ),
    
    mainPanel(
      plotlyOutput("scatter_plot", height = "600px"),
      br(),
      h4("Effektgrößen und Korrelationen"),
      tableOutput("metrics")
    )
  ),
  
  # JavaScript für bedingte Anzeige (jQuery ist in Shiny enthalten)
  tags$script(HTML("
    $(document).ready(function() {
      function updateInteractionVisibility() {
        var dagType = $('input[name=\"dag_type\"]:checked').val();
        if (dagType === 'interaction') {
          $('#interaction_options').addClass('show');
        } else {
          $('#interaction_options').removeClass('show');
        }
      }
      
      $('input[name=\"dag_type\"]').change(updateInteractionVisibility);
      updateInteractionVisibility();
    });
  "))
)
