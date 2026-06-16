# ============================================================================
# Shiny App: Multivariate Regression mit Animation
# ALLES IN EINER DATEI FÜR SHINY SERVER KOMPATIBILITÄT
# ============================================================================

library(shiny)
library(plotly)
library(tidyverse)

# ============================================================================
# DATENGENERIERUNGS-FUNKTIONEN
# ============================================================================

# 1. KONFUNDIERUNG
simulate_confounding_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- rbinom(n, size = 1, prob = 0.5)
  X <- 0.7 * Z + rnorm(n, mean = 0, sd = 0.7)
  Y <- 1.0 * X + 1.5 * Z + rnorm(n, mean = 0, sd = 0.8)
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 2. MEDIATION
simulate_mediation_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  X <- rnorm(n, mean = 0, sd = 1)
  Z <- rbinom(n, size = 1, prob = plogis(0.8 * X))
  Y <- 0.3 * X + 1.2 * Z + rnorm(n, mean = 0, sd = 0.8)
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 3. SCHEINKORRELATION
simulate_spurious_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  Z <- rbinom(n, size = 1, prob = 0.5)
  X <- 0.9 * Z + rnorm(n, mean = 0, sd = 0.6)
  Y <- 1.1 * Z + rnorm(n, mean = 0, sd = 0.7) + rnorm(n, mean = 0, sd = 0.3)
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 4. INTERAKTION
simulate_interaction_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  X <- rnorm(n, mean = 0, sd = 1)
  Z <- rbinom(n, size = 1, prob = 0.5)
  Y <- 0.4 * X + 0.8 * Z + 1.2 * X * Z + rnorm(n, mean = 0, sd = 0.8)
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# ============================================================================
# UI
# ============================================================================

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
      
      uiOutput("interaction_explanation"),
      br(),
      
      actionButton(
        "generate",
        "Neue Daten generieren",
        class = "btn btn-primary",
        width = "100%"
      ),
      
      br(), br(),
      
      div(
        class = "animation-controls",
        h4("Animation"),
        
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
        
        actionButton(
          "animate",
          "Automatisch abspielen",
          class = "btn btn-success",
          width = "100%"
        )
      ),
      
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
          "Hinweis: Standardmäßig sind beide aus.",
          style = "font-size: 11px; color: #666;"
        )
      ),
      
      div(
        id = "interaction_options",
        class = "interaction-options",
        h4("Interaktions-Optionen"),
        checkboxInput(
          "show_group_lines",
          "Gruppenspezifische Regressionsgeraden anzeigen",
          value = FALSE
        )
      ),
      
      hr(),
      
      p(
        tags$strong("Erklärung:"),
        br(),
        "Animation zeigt den Übergang von bivariaten zu partiellen Zusammenhängen.",
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

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {
  
  # Daten generieren
  data_reactive <- eventReactive(input$generate, {
    tryCatch({
      df <- switch(input$dag_type,
        "confounding" = simulate_confounding_binary(n = 150),
        "mediation" = simulate_mediation_binary(n = 150),
        "spurious" = simulate_spurious_binary(n = 150),
        "interaction" = simulate_interaction_binary(n = 150),
        NULL
      )
      
      if (is.null(df) || nrow(df) == 0) {
        showNotification("Fehler: Keine Daten generiert.", type = "error")
        return(NULL)
      }
      
      df
    }, error = function(e) {
      showNotification(
        paste("Fehler bei Datengenerierung:", e$message),
        type = "error"
      )
      NULL
    })
  }, ignoreNULL = FALSE)
  
  observe({
    if (is.null(data_reactive())) {
      # Versuche automatisch zu generieren
      tryCatch({
        shinyjs::runjs("document.getElementById('generate').click();")
      }, error = function(e) {
        NULL
      })
    }
  })
  
  # Interaction explanation
  output$interaction_explanation <- renderUI({
    if (input$dag_type == "interaction") {
      div(
        p(
          tags$strong("Hinweis:"),
          br(),
          "Der Effekt von X auf Y hängt von Z ab.",
          style = "font-size: 11px; color: #d9534f; background-color: #f2dede; padding: 10px; border-radius: 4px; margin: 10px 0;"
        )
      )
    } else {
      return(NULL)
    }
  })
  
  # Modelle
  model_bivariate <- reactive({
    df <- data_reactive()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    tryCatch(lm(Y ~ X, data = df), error = function(e) NULL)
  })
  
  model_partial <- reactive({
    df <- data_reactive()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    tryCatch(lm(Y ~ X + Z, data = df), error = function(e) NULL)
  })
  
  models_by_group <- reactive({
    df <- data_reactive()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    if (input$dag_type != "interaction") return(NULL)
    
    z_levels <- unique(df$Z)
    models <- list()
    for (level in z_levels) {
      df_subset <- df[df$Z == level, ]
      if (nrow(df_subset) > 1) {
        models[[as.character(level)]] <- lm(Y ~ X, data = df_subset)
      }
    }
    return(models)
  })
  
  # Helper Funktionen
  get_residuals <- function(df) {
    if (is.null(df) || nrow(df) == 0) return(NULL)
    model_z_on_x <- lm(X ~ Z, data = df)
    model_z_on_y <- lm(Y ~ Z, data = df)
    list(
      residuals_X = residuals(model_z_on_x),
      residuals_Y = residuals(model_z_on_y)
    )
  }
  
  get_z_means <- function(df, residuals_list = NULL) {
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    if (is.null(residuals_list)) {
      means <- df %>%
        group_by(Z) %>%
        summarise(
          mean_X = mean(X, na.rm = TRUE),
          mean_Y = mean(Y, na.rm = TRUE),
          .groups = "drop"
        )
    } else {
      z_levels <- unique(df$Z)
      means <- data.frame(
        Z = z_levels,
        mean_X = c(
          mean(residuals_list$residuals_X[df$Z == z_levels[1]]),
          mean(residuals_list$residuals_X[df$Z == z_levels[2]])
        ),
        mean_Y = c(
          mean(residuals_list$residuals_Y[df$Z == z_levels[1]]),
          mean(residuals_list$residuals_Y[df$Z == z_levels[2]])
        )
      )
    }
    return(means)
  }
  
  # Main Plot
  output$scatter_plot <- renderPlotly({
    tryCatch({
      df <- data_reactive()
      if (is.null(df) || nrow(df) == 0) {
        return(plot_ly() %>%
          layout(title = "Bitte zuerst 'Neue Daten generieren' klicken."))
      }
      
      model_biv <- model_bivariate()
      model_part <- model_partial()
      
      if (is.null(model_biv) || is.null(model_part)) {
        return(plot_ly() %>%
          layout(title = "Fehler beim Erstellen der Modelle."))
      }
      
      residuals_list <- get_residuals(df)
      residuals_X <- residuals_list$residuals_X
      residuals_Y <- residuals_list$residuals_Y
      
      z_means_biv <- get_z_means(df)
      z_means_part <- get_z_means(df, residuals_list)
      
      # Achsen
      x_range <- c(min(df$X, na.rm = TRUE) - 0.5,
                   max(df$X, na.rm = TRUE) + 0.5)
      y_range <- c(min(df$Y, na.rm = TRUE) - 0.5,
                   max(df$Y, na.rm = TRUE) + 0.5)
      x_seq <- seq(x_range[1], x_range[2], length.out = 100)
      
      # Animation
      animation_progress <- input$animate_slider
      if (is.null(animation_progress)) animation_progress <- 0
      
      t <- animation_progress
      
      X_anim <- (1 - t) * df$X + t * residuals_X
      Y_anim <- (1 - t) * df$Y + t * residuals_Y
      
      means_X_anim <- (1 - t) * z_means_biv$mean_X + t * z_means_part$mean_X
      means_Y_anim <- (1 - t) * z_means_biv$mean_Y + t * z_means_part$mean_Y
      
      # Regressionslinien
      pred_biv <- predict(model_biv, newdata = data.frame(X = x_seq))
      pred_part <- predict(
        lm(residuals_Y ~ residuals_X),
        newdata = data.frame(residuals_X = x_seq)
      )
      
      # Plot
      p <- plot_ly(height = 600) %>%
        add_trace(
          x = X_anim,
          y = Y_anim,
          color = df$Z,
          type = "scatter",
          mode = "markers",
          marker = list(size = 8, opacity = 0.7),
          colors = c("#1f77b4", "#ff7f0e"),
          name = "Beobachtungen",
          hoverinfo = "text",
          text = paste("X:", round(X_anim, 2), "<br>",
                       "Y:", round(Y_anim, 2), "<br>",
                       "Z:", df$Z),
          showlegend = TRUE
        )
      
      # Bivariate Linie
      if (isTRUE(input$show_bivariate_line)) {
        p <- p %>%
          add_trace(
            x = x_seq,
            y = pred_biv,
            type = "scatter",
            mode = "lines",
            line = list(color = "blue", width = 3),
            name = "Bivariate Regression (Y ~ X)",
            hoverinfo = "skip",
            showlegend = TRUE
          )
      }
      
      # Partielle Linie
      if (isTRUE(input$show_partial_line)) {
        p <- p %>%
          add_trace(
            x = x_seq,
            y = pred_part,
            type = "scatter",
            mode = "lines",
            line = list(color = "red", width = 3),
            name = "Partielle Regression (Y ~ X | Z)",
            hoverinfo = "skip",
            showlegend = TRUE
          )
      }
      
      # Mittelwerte
      p <- p %>%
        add_trace(
          x = means_X_anim[1],
          y = means_Y_anim[1],
          type = "scatter",
          mode = "markers",
          marker = list(size = 15, symbol = "diamond",
                       color = "#1f77b4",
                       line = list(color = "black", width = 2)),
          name = "Mittelwert Z=0",
          hoverinfo = "text",
          text = paste("M_X:", round(means_X_anim[1], 2),
                      "<br>M_Y:", round(means_Y_anim[1], 2)),
          showlegend = TRUE
        ) %>%
        add_trace(
          x = means_X_anim[2],
          y = means_Y_anim[2],
          type = "scatter",
          mode = "markers",
          marker = list(size = 15, symbol = "diamond",
                       color = "#ff7f0e",
                       line = list(color = "black", width = 2)),
          name = "Mittelwert Z=1",
          hoverinfo = "text",
          text = paste("M_X:", round(means_X_anim[2], 2),
                      "<br>M_Y:", round(means_Y_anim[2], 2)),
          showlegend = TRUE
        )
      
      # Gruppen-Regressionen (Interaktion)
      if (input$dag_type == "interaction" && isTRUE(input$show_group_lines)) {
        models_group <- models_by_group()
        
        if (!is.null(models_group)) {
          colors_group <- c("#1f77b4", "#ff7f0e")
          z_levels <- names(models_group)
          
          for (i in seq_along(z_levels)) {
            z_level <- z_levels[i]
            model_group <- models_group[[z_level]]
            pred_group <- predict(model_group, newdata = data.frame(X = x_seq))
            
            p <- p %>%
              add_trace(
                x = x_seq,
                y = pred_group,
                type = "scatter",
                mode = "lines",
                line = list(color = colors_group[i], width = 2, dash = "dot"),
                name = paste("Regression für", z_level),
                hoverinfo = "skip",
                showlegend = TRUE
              )
          }
        }
      }
      
      # Layout
      p <- p %>%
        layout(
          title = paste("Multivariate Regression (n =", nrow(df), ")"),
          xaxis = list(title = "X", zeroline = FALSE, range = x_range),
          yaxis = list(title = "Y", zeroline = FALSE, range = y_range),
          showlegend = TRUE,
          hovermode = "closest",
          plot_bgcolor = "rgba(240, 240, 240, 0.5)",
          paper_bgcolor = "white",
          margin = list(l = 70, r = 70, t = 100, b = 70),
          font = list(size = 12)
        )
      
      return(p)
      
    }, error = function(e) {
      plot_ly() %>%
        layout(title = paste("Fehler beim Plot:", e$message))
    })
  })
  
  # Animation
  animation_state <- reactiveValues(
    is_running = FALSE,
    current_progress = 0
  )
  
  observeEvent(input$animate, {
    tryCatch({
      df <- data_reactive()
      if (is.null(df) || nrow(df) == 0) {
        showNotification(
          "Keine Daten verfügbar. Bitte zuerst Daten generieren!",
          type = "warning"
        )
        return(NULL)
      }
      
      animation_state$is_running <- TRUE
      animation_state$current_progress <- 0
      
      showNotification(
        "Animation läuft...",
        type = "message"
      )
      
    }, error = function(e) {
      showNotification(
        paste("Fehler bei Animation:", e$message),
        type = "error"
      )
    })
  })
  
  observe({
    if (isTRUE(animation_state$is_running)) {
      invalidateLater(100, session)
      
      animation_state$current_progress <- animation_state$current_progress + 0.04
      
      updateSliderInput(session, "animate_slider", value = animation_state$current_progress)
      
      if (animation_state$current_progress >= 1) {
        animation_state$is_running <- FALSE
        showNotification("Animation fertig!", type = "message", duration = 2)
      }
    }
  })
  
  # Metrics
  output$metrics <- renderTable({
    tryCatch({
      df <- data_reactive()
      if (is.null(df) || nrow(df) == 0) {
        return(data.frame(
          Metrik = c("Korrelation (X, Y)", "Regressionskoeffizient (X)"),
          Bivariate = NA_real_,
          Partial = NA_real_
        ))
      }
      
      corr_biv <- cor(df$X, df$Y)
      coef_biv <- coef(model_bivariate())[2]
      
      residuals_list <- get_residuals(df)
      residuals_X <- residuals_list$residuals_X
      residuals_Y <- residuals_list$residuals_Y
      
      corr_part <- cor(residuals_X, residuals_Y)
      coef_part <- coef(lm(residuals_Y ~ residuals_X))[2]
      
      data.frame(
        Metrik = c("Korrelation (X, Y)", "Regressionskoeffizient (X)"),
        Bivariate = round(c(corr_biv, coef_biv), 3),
        Partial = round(c(corr_part, coef_part), 3),
        check.names = FALSE
      )
      
    }, error = function(e) {
      data.frame(
        Metrik = c("Fehler", "Fehler"),
        Bivariate = NA_real_,
        Partial = NA_real_
      )
    })
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
}

# ============================================================================
# STARTE APP
# ============================================================================

shinyApp(ui, server)
