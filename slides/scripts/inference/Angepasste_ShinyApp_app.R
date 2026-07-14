
# 0. LIBRARIES UND GLOBALE EINSTELLUNGEN

#******************************************************************************  
library(shiny)  
library(ggplot2)  
library(DT)  
library(shinydashboard)  
library(shinyWidgets)
MAX_SAMPLES <- 100 # Maximale Anzahl zusätzlicher Stichproben
#******************************************************************************

# 1. UI

#******************************************************************************  
ui <- page_fillable(  
theme = shinytheme("cerulean"), # KIT-freundliches Design  
title = "Interaktive Konfidenzintervalle",

# Sidebar mit Parametern und Steuerungselementen

sidebar = sidebar(  
width = 300,  
selectInput(  
"parameter",  
"Zu schätzender Parameter:",  
choices = c(  
"Mittelwert (μ)" = "mean",  
"Wahrscheinlichkeit (p)" = "probability",  
"Odds" = "odds",  
"Odds-Ratio" = "odds_ratio",  
"Varianzverhältnis" = "variance_ratio",  
"Mittelwertdifferenz (μ₁ - μ₂)" = "mean_diff",  
"Wahrscheinlichkeitsdifferenz (p₁ - p₂)" = "prob_diff",  
"Regressionskoeffizient (β₁)" = "regression_coef"  
)  
),

# Dynamische Parameter-Eingaben basierend auf Auswahl
uiOutput("param_inputs"),

# Steuerungselemente
actionButton("resample", "Neue Referenzstichprobe ziehen", icon = icon("shuffle")),
sliderInput(
  "n_samples",
  "Anzahl weiterer Stichproben:",
  min = 0,
  max = MAX_SAMPLES - 1,
  value = 0,
  step = 1
),
sliderInput(
  "alpha",
  "Irrtumswahrscheinlichkeit (α)",
  min = 0.01,
  max = 0.20,
  value = 0.05,
  step = 0.01,
  post = "%",
  sep = ""
),
checkboxInput(
  "show_true_param",
  "Wahren Parameter als Linie anzeigen",
  value = FALSE
)
),

# Hauptinhalt: Visualisierungen

main = layout_columns(  
col_widths = c(8, 4),

# Hauptplot: Konfidenzintervalle
card(
  full_screen = TRUE,
  card_header("Geschätzte Parameter über wiederholte Zufallsstichproben"),
  plotOutput("ci_plot", height = "500px")
),

# Zusätzliche Informationen und Navigation
navset_card_underline(
  nav_panel(
    "Histogram",
    plotOutput("hist_plot", height = "300px")
  ),
  nav_panel(
    "Coverage",
    value_box(
      title = "Intervalle, die den wahren Parameter enthalten",
      value = textOutput("coverage_text"),
      theme = "info"
    )
  ),
  nav_panel(
    "Wahrscheinlichkeitsverteilung",
    plotOutput("distribution_plot", height = "300px")
  )
)
)  
)
#******************************************************************************

# 2. SERVER-LOGIK

#******************************************************************************  
server <- function(input, output, session) {
#---------- 2.1 Zufallsstichproben generieren ----------  
generate_sample <- reactive({  
param_type <- input$parameter

# Parameterabhängige Generierung
if (param_type == "mean") {
  mu <- input$param1
  sigma <- input$param2
  rnorm(input$n, mean = mu, sd = sigma)
} else if (param_type == "probability") {
  p <- input$param1
  rbinom(input$n, size = 1, prob = p)
} else if (param_type == "odds") {
  p <- input$param1
  rbinom(input$n, size = 1, prob = p)
} else if (param_type == "odds_ratio") {
  p1 <- input$param1
  p2 <- input$param2
  c(rbinom(input$n, size = 1, prob = p1), rbinom(input$n, size = 1, prob = p2))
} else if (param_type == "variance_ratio") {
  sigma1_sq <- input$param1
  sigma2_sq <- input$param2
  c(rnorm(input$n, mean = 0, sd = sqrt(sigma1_sq)), rnorm(input$n, mean = 0, sd = sqrt(sigma2_sq)))
} else if (param_type == "mean_diff") {
  mu1 <- input$param1
  mu2 <- input$param2
  sigma <- input$param3
  c(rnorm(input$n, mean = mu1, sd = sigma), rnorm(input$n, mean = mu2, sd = sigma))
} else if (param_type == "prob_diff") {
  p1 <- input$param1
  p2 <- input$param2
  c(rbinom(input$n, size = 1, prob = p1), rbinom(input$n, size = 1, prob = p2))
} else if (param_type == "variance") {
  sigma_sq <- input$param1
  rnorm(input$n, mean = 0, sd = sqrt(sigma_sq))
} else if (param_type == "regression_coef") {
  beta1 <- input$param1
  sigma <- input$param2
  X <- seq(0, 1, length.out = input$n)
  beta0 <- 0  # Annahme: Intercept = 0
  beta0 + beta1 * X + rnorm(input$n, mean = 0, sd = sigma)
}
})
#---------- 2.2 Berechnung des wahren Parameters ----------  
true_param <- reactive({  
param_type <- input$parameter  
if (param_type == "mean") {  
input$param1  
} else if (param_type == "probability") {  
input$param1  
} else if (param_type == "odds") {  
input$param1 / (1 - input$param1)  
} else if (param_type == "odds_ratio") {  
(input$param1 / (1 - input$param1)) / (input$param2 / (1 - input$param2))  
} else if (param_type == "variance_ratio") {  
input$param1 / input$param2  
} else if (param_type == "mean_diff") {  
input$param1 - input$param2  
} else if (param_type == "prob_diff") {  
input$param1 - input$param2  
} else if (param_type == "variance") {  
input$param1  
} else if (param_type == "regression_coef") {  
input$param1  
}  
})
#---------- 2.3 Daten für Plots vorbereiten ----------  
plot_data <- reactive({  
samples <- isolate(generate_sample())  
param_type <- input$parameter

# Parameter schätzen
if (param_type %in% c("mean", "variance", "variance_ratio")) {
  mean(samples)
} else if (param_type %in% c("probability", "prob_diff", "odds", "odds_ratio")) {
  mean(samples)
} else if (param_type == "mean_diff") {
  mean(samples[1:input$n]) - mean(samples[(input$n + 1):(2 * input$n)])
} else if (param_type == "regression_coef") {
  # Einfacher Ansatz: OLS-Schätzung für beta1
  X <- seq(0, 1, length.out = input$n)
  y <- samples
  cov(X, y) / var(X)
}
})

#---------- 2.4 Dynamische UI-Eingaben basierend auf dem Parameter ----------  
output$param_inputs <- renderUI({  
switch(input$parameter,  
"mean" = {  
tagList(  
numericInput("param1", "Mittelwert der Grundgesamtheit (μ)", value = 100),  
numericInput("param2", "Standardabweichung (σ)", value = 15, min = 0.01),  
sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5)  
)  
},  
"probability" = {  
tagList(  
sliderInput("param1", "Wahrscheinlichkeit (p)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),  
sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5)  
)  
},  
"odds" = {  
tagList(  
sliderInput("param1", "Wahrscheinlichkeit (p)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),  
sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5)  
)  
},  
"odds_ratio" = {  
tagList(  
sliderInput("param1", "Wahrscheinlichkeit Gruppe 1 (p₁)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),  
sliderInput("param2", "Wahrscheinlichkeit Gruppe 2 (p₂)", min = 0.01, max = 0.99, value = 0.3, step = 0.01),  
sliderInput("n", "Stichprobengröße pro Gruppe (n)", min = 5, max = 500, value = 50, step = 5)  
)  
},  
"variance" = {  
tagList(  
numericInput("param1", "Varianz der Grundgesamtheit (σ²)", value = 25, min = 0.1),  
sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5)  
)  
},  
"variance_ratio" = {  
tagList(  
numericInput("param1", "Varianz Gruppe 1 (σ₁²)", value = 25, min = 0.1),  
numericInput("param2", "Varianz Gruppe 2 (σ₂²)", value = 15, min = 0.1),  
sliderInput("n", "Stichprobengröße pro Gruppe (n)", min = 5, max = 500, value = 30, step = 5)  
)  
},  
"mean_diff" = {  
tagList(  
numericInput("param1", "Mittelwert Gruppe 1 (μ₁)", value = 10),  
numericInput("param2", "Mittelwert Gruppe 2 (μ₂)", value = 8),  
numericInput("param3", "Standardabweichung (σ)", value = 3, min = 0.01),  
sliderInput("n", "Stichprobengröße pro Gruppe (n)", min = 5, max = 500, value = 30, step = 5)  
)  
},  
"prob_diff" = {  
tagList(  
sliderInput("param1", "Wahrscheinlichkeit Gruppe 1 (p₁)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),  
sliderInput("param2", "Wahrscheinlichkeit Gruppe 2 (p₂)", min = 0.01, max = 0.99, value = 0.3, step = 0.01),  
sliderInput("n", "Stichprobengröße pro Gruppe (n)", min = 5, max = 500, value = 50, step = 5)  
)  
},  
"regression_coef" = {  
tagList(  
numericInput("param1", "Regressionskoeffizient (β₁)", value = 2),  
numericInput("param2", "Residualstandardabweichung (σ)", value = 5, min = 0.01),  
sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 40, step = 5)  
)  
}  
)  
})

#---------- 2.5 Konfidenzintervall-Plot ----------  
output$ci_plot <- renderPlot({  
req(plot_data())  
samples <- isolate(generate_sample())  
param_type <- input$parameter  
n_samples <- input$n_samples


# Liste zum Speichern der Schätzungen
estimates <- c()
lower_bounds <- c()
upper_bounds <- c()

# Referenzstichprobe (erste Stichprobe)
ref_sample <- samples
if (param_type == "mean_diff") {
  ref_estimate <- mean(ref_sample[1:input$n]) - mean(ref_sample[(input$n + 1):(2 * input$n)])
} else {
  ref_estimate <- mean(ref_sample)
}

estimates <- c(estimates, ref_estimate)

# Zusätzliche Stichproben
for (i in 1:n_samples) {
  sim_sample <- generate_sample()
  if (param_type == "mean_diff") {
    sim_estimate <- mean(sim_sample[1:input$n]) - mean(sim_sample[(input$n + 1):(2 * input$n)])
  } else {
    sim_estimate <- mean(sim_sample)
  }
  estimates <- c(estimates, sim_estimate)
}

# Konfidenzintervalle berechnen
alpha <- input$alpha
se <- sd(estimates) / sqrt(length(estimates))
t_crit <- qt(1 - alpha/2, df = length(estimates) - 1)
ci_lower <- mean(estimates) - t_crit * se
ci_upper <- mean(estimates) + t_crit * se

# Plot der Intervalle
ci_df <- data.frame(
  Index = 1:length(estimates),
  Untere_Grenze = estimates - t_crit * se,
  Obere_Grenze = estimates + t_crit * se,
  Schätzung = estimates,
  Parameter = param_type
)

ggplot(ci_df, aes(x = Index)) +
  geom_point(aes(y = Schätzung), color = "#75AADB", size = 2) +
  geom_errorbar(aes(ymin = Untere_Grenze, ymax = Obere_Grenze), width = 0.2, color = "#333333") +
  geom_hline(yintercept = true_param(), linetype = "dashed", color = "red", linewidth = 1) +
  labs(
    x = "Stichprobe",
    y = "Parameter-Schätzung",
    title = "Konfidenzintervalle für wiederholte Stichproben"
  ) +
  theme_minimal(base_size = 12)

})


#---------- 2.6 Histogramm der Schätzungen ----------  
output$hist_plot <- renderPlot({  
req(plot_data())  
n_samples <- input$n_samples  
estimates <- sapply(1:(n_samples + 1), function(x) {  
sim <- generate_sample()  
if (input$parameter == "mean_diff") {  
mean(sim[1:input$n]) - mean(sim[(input$n + 1):(2 * input$n)])  
} else {  
mean(sim)  
}  
})


# Histogramm
ggplot(data.frame(estimates), aes(x = estimates)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "#75AADB", color = "white") +
  geom_vline(xintercept = true_param(), linetype = "dashed", color = "red", linewidth = 1) +
  labs(
    x = "Schätzwerte",
    y = "Dichte",
    title = "Verteilung der Stichprobenmittelwerte"
  ) +
  theme_minimal(base_size = 12)

})

#---------- 2.7 Coverage-Wert ----------  
output$coverage_text <- renderText({  
req(plot_data())  
n_samples <- input$n_samples  
alpha <- input$alpha

# Überprüfen, ob das wahre Parameter-intervall abgedeckt wird
ci_lower <- mean(sapply(1:(n_samples + 1), function(x) {
  sim <- generate_sample()
  if (input$parameter == "mean_diff") {
    mean(sim[1:input$n]) - mean(sim[(input$n + 1):(2 * input$n)])
  } else {
    mean(sim)
  }
})) - qt(1 - alpha/2, df = n_samples) * sd(sapply(1:(n_samples + 1), function(x) {
  sim <- generate_sample()
  if (input$parameter == "mean_diff") {
    mean(sim[1:input$n]) - mean(sim[(input$n + 1):(2 * input$n)])
  } else {
    mean(sim)
  }
}))

ci_upper <- mean(sapply(1:(n_samples + 1), function(x) {
  sim <- generate_sample()
  if (input$parameter == "mean_diff") {
    mean(sim[1:input$n]) - mean(sim[(input$n + 1):(2 * input$n)])
  } else {
    mean(sim)
  }
})) + qt(1 - alpha/2, df = n_samples) * sd(sapply(1:(n_samples + 1), function(x) {
  sim <- generate_sample()
  if (input$parameter == "mean_diff") {
    mean(sim[1:input$n]) - mean(sim[(input$n + 1):(2 * input$n)])
  } else {
    mean(sim)
  }
}))

coverage <- if (true_param() >= ci_lower && true_param() <= ci_upper) "Ja" else "Nein"
paste("Überdeckt das Intervall den wahren Wert?", coverage)

})


#---------- 2.8 Wahrscheinlichkeitsverteilung (NEU) ----------

# Funktion zur Bestimmung der Verteilung und Freiheitsgrade basierend auf dem Parameter

get_distribution_params <- function(param_type) {  
true_val <- true_param()  
n <- if (input$parameter == "mean_diff") input$n * 2 else input$n

switch(
  param_type,
  "Mittelwert (μ)" = {
    list(
      dist = "t",
      df = n - 1,
      mean = true_val,
      se = NA  # Wird extern berechnet
    )
  },
  "Mittelwertdifferenz (μ₁ - μ₂)" = {
    list(
      dist = "t",
      df = n - 2,
      mean = true_val,
      se = NA
    )
  },
  "Varianzverhältnis" = {
    list(
      dist = "f",
      df1 = n - 1,
      df2 = n - 1,
      ncp = true_val
    )
  },
  "Wahrscheinlichkeit (p)" = {
    list(
      dist = "beta",
      shape1 = true_val * 10,
      shape2 = (1 - true_val) * 10
    )
  },
  "Wahrscheinlichkeitsdifferenz (p₁ - p₂)" = {
    list(
      dist = "normal",
      mean = true_val,
      sd = 0.1  # Beispielwert, wird überschrieben
    )
  },
  "Odds-Ratio" = {
    list(
      dist = "lognormal",
      meanlog = log(true_val),
      sdlog = 0.1  # Beispielwert, wird überschrieben
    )
  },
  # Standardfall: Normalverteilung
  list(
    dist = "normal",
    mean = true_val,
    sd = 0.1  # Wird überschrieben
  )
)

}

# Funktion zur Berechnung der Grenzen des Konfidenzintervalls

calculate_ci_bounds <- function(dist_params, alpha = 0.05) {  
if (dist_params$dist == "t") {  
lower <- qt(alpha/2, df = dist_params$df) * dist_params$sd + dist_params$mean  
upper <- qt(1 - alpha/2, df = dist_params$df) * dist_params$sd + dist_params$mean  
} else if (dist_params$dist == "f") {  
lower <- qf(alpha/2, df1 = dist_params$df1, df2 = dist_params$df2) * dist_params$ncp  
upper <- qf(1 - alpha/2, df1 = dist_params$df1, df2 = dist_params$df2) * dist_params$ncp  
} else if (dist_params$dist == "beta") {  
lower <- qbeta(alpha/2, shape1 = dist_params$shape1, shape2 = dist_params$shape2)  
upper <- qbeta(1 - alpha/2, shape1 = dist_params$shape1, shape2 = dist_params$shape2)  
} else if (dist_params$dist == "lognormal") {  
lower <- exp(qnorm(alpha/2, meanlog = dist_params$meanlog, sdlog = dist_params$sdlog))  
upper <- exp(qnorm(1 - alpha/2, meanlog = dist_params$meanlog, sdlog = dist_params$sdlog))  
} else {  
# Normalverteilung oder Standardfall  
lower <- qnorm(alpha/2, mean = dist_params$mean, sd = dist_params$sd)  
upper <- qnorm(1 - alpha/2, mean = dist_params$mean, sd = dist_params$sd)  
}  
return(c(lower, upper))  
}

# Plot der Verteilung

output$distribution_plot <- renderPlot({  
req(plot_data())  
param_type <- input$parameter  
alpha <- input$alpha


# Parameter und Standardfehler berechnen
true_val <- true_param()
n <- if (input$parameter == "mean_diff") input$n * 2 else input$n

# Standardfehler basierend auf der Stichprobengröße schätzen
# Annahme: Standardfehler ist proportional zu 1/sqrt(n)
if (param_type == "mean") {
  se_estimate <- input$param2 / sqrt(input$n)
} else if (param_type == "probability") {
  se_estimate <- sqrt(input$param1 * (1 - input$param1)) / sqrt(input$n)
} else if (param_type == "odds") {
  p <- input$param1
  se_estimate <- sqrt(p / (1 - p)^2) / sqrt(input$n)
} else if (param_type == "odds_ratio") {
  p1 <- input$param1
  p2 <- input$param2
  se_estimate <- sqrt(
    (1 / (p1 * (1 - p1))) + (1 / (p2 * (1 - p2))
  ) / sqrt(input$n)
} else if (param_type == "variance_ratio") {
  # Annahme: F-Verteilung, Standardfehler schwer zu berechnen, daher vereinfacht
  se_estimate <- 0.5
} else if (param_type == "mean_diff") {
  se_estimate <- input$param3 * sqrt(2 / input$n)
} else if (param_type == "prob_diff") {
  se_estimate <- sqrt(
    (input$param1 * (1 - input$param1) + input$param2 * (1 - input$param2))
  ) / sqrt(input$n)
} else if (param_type == "variance") {
  se_estimate <- 2 * input$param1 / sqrt(input$n)
} else if (param_type == "regression_coef") {
  se_estimate <- input$param2 / sqrt(input$n)
}

# Verteilung und Freiheitsgrade bestimmen
dist_params <- get_distribution_params(param_type)
dist_params$mean <- true_val
dist_params$sd <- se_estimate

# Grenzen des Konfidenzintervalls berechnen
ci_bounds <- calculate_ci_bounds(dist_params, alpha)
lower_bound <- ci_bounds[1]
upper_bound <- ci_bounds[2]

# Bereich für die x-Achse basierend auf der Verteilung
if (dist_params$dist == "t") {
  x_seq <- seq(
    qt(0.001, df = dist_params$df) * se_estimate + true_val,
    qt(0.999, df = dist_params$df) * se_estimate + true_val,
    length.out = 1000
  )
  y_vals <- dt((x_seq - true_val) / se_estimate, df = dist_params$df) / se_estimate

} else if (dist_params$dist == "f") {
  x_seq <- seq(0, qf(0.999, df1 = dist_params$df1, df2 = dist_params$df2), length.out = 1000)
  y_vals <- df(x_seq, df1 = dist_params$df1, df2 = dist_params$df2)

} else if (dist_params$dist == "beta") {
  x_seq <- seq(0, 1, length.out = 1000)
  y_vals <- dbeta(x_seq, shape1 = dist_params$shape1, shape2 = dist_params$shape2)

} else if (dist_params$dist == "lognormal") {
  x_seq <- seq(0, exp(qnorm(0.999, meanlog = dist_params$meanlog, sdlog = dist_params$sdlog)), length.out = 1000)
  y_vals <- dlnorm(x_seq, meanlog = dist_params$meanlog, sdlog = dist_params$sdlog)

} else {
  # Normalverteilung oder Standardfall
  x_seq <- seq(true_val - 4 * se_estimate, true_val + 4 * se_estimate, length.out = 1000)
  y_vals <- dnorm(x_seq, mean = true_val, sd = se_estimate)
}

# Plot der Verteilung
ggplot(data.frame(x = x_seq, y = y_vals), aes(x = x, y = y)) +
  geom_line(color = "#75AADB", linewidth = 1) +
  geom_ribbon(
    data = data.frame(
      x = x_seq,
      ymin = ifelse(x_seq >= lower_bound & x_seq <= upper_bound, 0, y_vals),
      ymax = y_vals
    ),
    aes(x = x, ymin = ymin, ymax = ymax),
    fill = "#FF744E",
    alpha = 0.3
  ) +
  geom_vline(xintercept = lower_bound, linetype = "dashed", color = "#FF744E", linewidth = 1) +
  geom_vline(xintercept = upper_bound, linetype = "dashed", color = "#FF744E", linewidth = 1) +
  geom_text(
    aes(x = lower_bound, y = max(y_vals), label = round(lower_bound, 3)),
    vjust = -0.5,
    color = "#FF744E"
  ) +
  geom_text(
    aes(x = upper_bound, y = max(y_vals), label = round(upper_bound, 3)),
    vjust = -0.5,
    color = "#FF744E"
  ) +
  labs(
    x = "Parameterwerte",
    y = "Dichte",
    title = paste("Verteilung für:", param_type)
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(size = 12, face = "bold"))

})  
}

#******************************************************************************

# 3. APP STARTEN

#******************************************************************************

# shinyApp(ui, server)
