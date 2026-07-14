# Interaktive Visualisierung: Stichprobenvariabilität und Konfidenzintervalle
#
# DIDAKTISCHES ZIEL: Studierenden verdeutlichen, woher Konfidenzintervall-Grenzen kommen.
# Für jeden Parameter wird die KORREKTE Wahrscheinlichkeitsverteilung gezeigt, in die der
# Standardfehler skaliert ist. Die (1-α)-Fläche unter der Verteilung wird visuell abgegrenzt,
# zusammen mit den Werten, die als CI-Grenzen entstehen.
#
# Parameter:
#  - Mittelwert (μ): t-Verteilung, df = n-1
#  - Wahrscheinlichkeit (p): Normalverteilung
#  - Odds: Normalverteilung (auf logit-Skala)
#  - Odds Ratio: Normalverteilung (auf log-Skala)
#  - Varianz (σ²): Chi-Quadrat-Verteilung, df = n-1
#  - Varianzverhältnis (σ₁²/σ₂²): F-Verteilung, df1 = df2 = n-1
#  - Mittelwertdifferenz: t-Verteilung, df = n-1 (vereinfacht)
#  - Wahrscheinlichkeitsdifferenz: Normalverteilung
#  - Regressionskoeffizient: t-Verteilung, df = n-2

library(shiny)
library(bslib)
library(ggplot2)

MAX_SAMPLES <- 100
COL_REFERENZ <- "#FF744E"
COL_WEITERE <- "#75AADB"

# =============================================================================
# SAMPLING FUNCTIONS (alle geben auch SE und kritische Werte zurück)
# =============================================================================

draw_mean_samples <- function(ids, mu, sigma, n, alpha) {
  if (sigma <= 0) sigma <- 0.01
  tcrit <- qt(1 - alpha/2, df = n - 1)
  do.call(rbind, lapply(ids, function(id) {
    x <- rnorm(n, mean = mu, sd = sigma)
    est <- mean(x)
    se <- sd(x) / sqrt(n)
    data.frame(
      sample_id = id, estimate = est, se = se,
      lower = est - tcrit * se, upper = est + tcrit * se,
      dist_type = "t", df1 = n - 1, df2 = NA_real_
    )
  }))
}

draw_probability_samples <- function(ids, p, n, alpha) {
  if (p < 0.001) p <- 0.001
  if (p > 0.999) p <- 0.999
  zcrit <- qnorm(1 - alpha/2)
  do.call(rbind, lapply(ids, function(id) {
    x <- rbinom(n, 1, p)
    phat <- mean(x)
    if (phat == 0) phat <- 0.5 / n
    if (phat == 1) phat <- (n - 0.5) / n
    se <- sqrt(phat * (1 - phat) / n)
    data.frame(
      sample_id = id, estimate = phat, se = se,
      lower = phat - zcrit * se, upper = phat + zcrit * se,
      dist_type = "normal", df1 = NA_real_, df2 = NA_real_
    )
  }))
}

draw_odds_samples <- function(ids, p, n, alpha) {
  if (p < 0.001) p <- 0.001
  if (p > 0.999) p <- 0.999
  zcrit <- qnorm(1 - alpha/2)
  do.call(rbind, lapply(ids, function(id) {
    x <- rbinom(n, 1, p)
    phat <- mean(x)
    if (phat == 0) phat <- 0.5 / n
    if (phat == 1) phat <- (n - 0.5) / n
    logit_hat <- log(phat / (1 - phat))
    se_logit <- sqrt(1 / (n * phat * (1 - phat)))
    ci <- exp(logit_hat + c(-1, 1) * zcrit * se_logit)
    data.frame(
      sample_id = id, estimate = phat / (1 - phat), se = se_logit,
      lower = ci[1], upper = ci[2],
      dist_type = "normal_logit", df1 = NA_real_, df2 = NA_real_
    )
  }))
}

draw_odds_ratio_samples <- function(ids, p1, p2, n1, n2, alpha) {
  if (p1 < 0.001) p1 <- 0.001
  if (p1 > 0.999) p1 <- 0.999
  if (p2 < 0.001) p2 <- 0.001
  if (p2 > 0.999) p2 <- 0.999
  zcrit <- qnorm(1 - alpha/2)
  do.call(rbind, lapply(ids, function(id) {
    x1 <- rbinom(n1, 1, p1)
    x2 <- rbinom(n2, 1, p2)
    a <- sum(x1)
    b <- n1 - a
    c <- sum(x2)
    d <- n2 - c
    if (any(c(a, b, c, d) == 0)) { a <- a + 0.5; b <- b + 0.5; c <- c + 0.5; d <- d + 0.5 }
    log_or <- log((a * d) / (b * c))
    se_log_or <- sqrt(1/a + 1/b + 1/c + 1/d)
    ci <- exp(log_or + c(-1, 1) * zcrit * se_log_or)
    data.frame(
      sample_id = id, estimate = (a*d)/(b*c), se = se_log_or,
      lower = ci[1], upper = ci[2],
      dist_type = "normal_log", df1 = NA_real_, df2 = NA_real_
    )
  }))
}

draw_variance_samples <- function(ids, sigma2, n, alpha) {
  if (sigma2 <= 0) sigma2 <- 0.1
  do.call(rbind, lapply(ids, function(id) {
    x <- rnorm(n, mean = 0, sd = sqrt(sigma2))
    s2 <- var(x)
    df <- n - 1
    ci <- c(df * s2 / qchisq(1 - alpha/2, df), df * s2 / qchisq(alpha/2, df))
    data.frame(
      sample_id = id, estimate = s2, se = NA_real_,
      lower = ci[1], upper = ci[2],
      dist_type = "chisq", df1 = df, df2 = NA_real_
    )
  }))
}

draw_variance_ratio_samples <- function(ids, sigma2_1, sigma2_2, n1, n2, alpha) {
  if (sigma2_1 <= 0) sigma2_1 <- 0.1
  if (sigma2_2 <= 0) sigma2_2 <- 0.1
  do.call(rbind, lapply(ids, function(id) {
    x1 <- rnorm(n1, mean = 0, sd = sqrt(sigma2_1))
    x2 <- rnorm(n2, mean = 0, sd = sqrt(sigma2_2))
    s2_1 <- var(x1)
    s2_2 <- var(x2)
    f_ratio <- s2_1 / s2_2
    df1 <- n1 - 1
    df2 <- n2 - 1
    fcrit_lower <- qf(alpha/2, df1, df2)
    fcrit_upper <- qf(1 - alpha/2, df1, df2)
    data.frame(
      sample_id = id, estimate = f_ratio, se = NA_real_,
      lower = f_ratio / fcrit_upper, upper = f_ratio / fcrit_lower,
      dist_type = "f", df1 = df1, df2 = df2
    )
  }))
}

draw_mean_diff_samples <- function(ids, mu1, mu2, sigma, n1, n2, alpha) {
  if (sigma <= 0) sigma <- 0.01
  # Conservative df: use minimum of (n1-1) and (n2-1)
  df <- min(n1 - 1, n2 - 1)
  tcrit <- qt(1 - alpha/2, df = df)
  do.call(rbind, lapply(ids, function(id) {
    x1 <- rnorm(n1, mu1, sigma)
    x2 <- rnorm(n2, mu2, sigma)
    diff <- mean(x1) - mean(x2)
    se <- sqrt(var(x1)/n1 + var(x2)/n2)
    ci <- diff + c(-1, 1) * tcrit * se
    data.frame(
      sample_id = id, estimate = diff, se = se,
      lower = ci[1], upper = ci[2],
      dist_type = "t", df1 = df, df2 = NA_real_
    )
  }))
}

draw_prob_diff_samples <- function(ids, p1, p2, n1, n2, alpha) {
  if (p1 < 0.001) p1 <- 0.001
  if (p1 > 0.999) p1 <- 0.999
  if (p2 < 0.001) p2 <- 0.001
  if (p2 > 0.999) p2 <- 0.999
  zcrit <- qnorm(1 - alpha/2)
  do.call(rbind, lapply(ids, function(id) {
    x1 <- rbinom(n1, 1, p1)
    x2 <- rbinom(n2, 1, p2)
    ph1 <- mean(x1)
    ph2 <- mean(x2)
    diff <- ph1 - ph2
    se <- sqrt(ph1*(1-ph1)/n1 + ph2*(1-ph2)/n2)
    if (se == 0) se <- 1e-6
    ci <- diff + c(-1, 1) * zcrit * se
    data.frame(
      sample_id = id, estimate = diff, se = se,
      lower = ci[1], upper = ci[2],
      dist_type = "normal", df1 = NA_real_, df2 = NA_real_
    )
  }))
}

draw_regression_coef_samples <- function(ids, beta1, sigma, n, alpha) {
  if (sigma <= 0) sigma <- 0.01
  do.call(rbind, lapply(ids, function(id) {
    x <- rnorm(n, 0, 1)
    y <- beta1 * x + rnorm(n, 0, sigma)
    fit <- lm(y ~ x)
    ci <- confint(fit, level = 1 - alpha)["x", ]
    se <- (ci[2] - coef(fit)["x"]) / qt(1 - alpha/2, df = n - 2)
    data.frame(
      sample_id = id, estimate = coef(fit)["x"], se = se,
      lower = ci[1], upper = ci[2],
      dist_type = "t", df1 = n - 2, df2 = NA_real_
    )
  }))
}

# =============================================================================
# DISTRIBUTION PLOTTING FUNCTIONS
# =============================================================================

plot_distribution <- function(data, parameter_type, alpha) {
  if (is.null(data) || nrow(data) == 0) return(NULL)

  ref_row <- data[1, ]
  est <- ref_row$estimate
  se <- ref_row$se
  dist_type <- ref_row$dist_type
  df1 <- ref_row$df1
  df2 <- ref_row$df2

  # Berechne Kurvenbereich und kritische Werte
  x_vals <- NULL
  y_vals <- NULL
  lower_crit <- NULL
  upper_crit <- NULL
  label_text <- ""
  x_range <- NULL

  if (dist_type == "t") {
    df <- df1
    z_crit <- qt(1 - alpha/2, df)
    x_range <- c(est - 4*se, est + 4*se)
    x_vals <- seq(x_range[1], x_range[2], length.out = 200)
    y_vals <- dt((x_vals - est) / se, df) / se
    lower_crit <- est - z_crit * se
    upper_crit <- est + z_crit * se
    label_text <- paste0("t-Verteilung (df=", df, ")\nSE = ", round(se, 4))

  } else if (dist_type == "normal") {
    z_crit <- qnorm(1 - alpha/2)
    x_range <- c(est - 4*se, est + 4*se)
    x_vals <- seq(x_range[1], x_range[2], length.out = 200)
    y_vals <- dnorm((x_vals - est) / se) / se
    lower_crit <- est - z_crit * se
    upper_crit <- est + z_crit * se
    label_text <- paste0("Normalverteilung\nSE = ", round(se, 4))

  } else if (dist_type == "normal_logit") {
    z_crit <- qnorm(1 - alpha/2)
    x_range <- c(est * 0.2, est * 5)
    log_x_vals <- seq(log(x_range[1]), log(x_range[2]), length.out = 200)
    x_vals <- exp(log_x_vals)
    log_odds_vals <- seq(log(x_range[1]), log(x_range[2]), length.out = 200)
    y_vals <- dnorm(log_odds_vals, mean = log(est), sd = se) / x_vals
    lower_crit <- est / exp(z_crit * se)
    upper_crit <- est * exp(z_crit * se)
    label_text <- paste0("Normalverteilung (log-Skala)\nSE (logit) = ", round(se, 4))

  } else if (dist_type == "normal_log") {
    z_crit <- qnorm(1 - alpha/2)
    x_range <- c(est * 0.2, est * 5)
    log_x_vals <- seq(log(x_range[1]), log(x_range[2]), length.out = 200)
    x_vals <- exp(log_x_vals)
    y_vals <- dnorm(log_x_vals, mean = log(est), sd = se) / x_vals
    lower_crit <- est / exp(z_crit * se)
    upper_crit <- est * exp(z_crit * se)
    label_text <- paste0("Normalverteilung (log-Skala)\nSE (log) = ", round(se, 4))

  } else if (dist_type == "chisq") {
    df <- df1
    x_range <- c(max(0.1, df * 0.3), df * 2.5)
    x_vals <- seq(x_range[1], x_range[2], length.out = 200)
    y_vals <- dchisq(x_vals, df)
    lower_crit <- df * est / qchisq(1 - alpha/2, df)
    upper_crit <- df * est / qchisq(alpha/2, df)
    label_text <- paste0("Chi-Quadrat (df=", df, ")")

  } else if (dist_type == "f") {
    df1_val <- df1
    df2_val <- df2
    x_range <- c(0.1, qf(0.99, df1_val, df2_val) * est)
    x_vals <- seq(x_range[1], x_range[2], length.out = 200)
    y_vals <- df(x_vals / est, df1_val, df2_val) / est
    lower_crit <- est / qf(1 - alpha/2, df1_val, df2_val)
    upper_crit <- est / qf(alpha/2, df1_val, df2_val)
    label_text <- paste0("F-Verteilung (df1=", df1_val, ", df2=", df2_val, ")")
  }

  if (is.null(x_vals)) return(NULL)

  # Erzeuge Kurvenbereich für Einfärbung der (1-α)-Fläche
  x_fill <- x_vals[x_vals >= lower_crit & x_vals <= upper_crit]
  y_fill <- y_vals[x_vals >= lower_crit & x_vals <= upper_crit]

  p <- ggplot() +
    geom_line(aes(x = x_vals, y = y_vals), color = "#555", linewidth = 1) +
    geom_area(aes(x = x_fill, y = y_fill), fill = COL_WEITERE, alpha = 0.3) +
    geom_vline(xintercept = lower_crit, linetype = "dashed", color = "black", linewidth = 0.8) +
    geom_vline(xintercept = upper_crit, linetype = "dashed", color = "black", linewidth = 0.8) +
    labs(
      x = "Parameter",
      y = "Dichte",
      title = "Wahrscheinlichkeitsverteilung der Schätzung",
      subtitle = label_text
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(size = 11, face = "bold"))

  p
}

# Erstelle eine schöne Tabelle für die Grenzen
bounds_table <- function(data, alpha) {
  if (is.null(data) || nrow(data) == 0) return(NULL)
  
  ref_row <- data[1, ]
  lower <- ref_row$lower
  upper <- ref_row$upper
  
  tab <- data.frame(
    Komponente = c("Untere Grenze", "Obere Grenze"),
    Wert = c(round(lower, 4), round(upper, 4))
  )
  
  knitr::kable(tab, format = "html", table.attr = 'style="width: auto; margin-left: auto; margin-right: auto; font-size: 14px;"')
}

# =============================================================================
# UI
# =============================================================================

ui <- page_sidebar(
  title = "Stichprobenvariabilität: Konfidenzintervalle für verschiedene Parameter",
  theme = bs_theme(version = 5, primary = "#75AADB"),
  sidebar = sidebar(
    selectInput(
      "parameter",
      "Parameter:",
      choices = c(
        "Mittelwert (μ)" = "mean",
        "Wahrscheinlichkeit (p)" = "probability",
        "Odds" = "odds",
        "Odds Ratio" = "odds_ratio",
        "Varianz (σ²)" = "variance",
        "Varianzverhältnis (σ₁²/σ₂²)" = "variance_ratio",
        "Mittelwertdifferenz (μ₁ - μ₂)" = "mean_diff",
        "Wahrscheinlichkeitsdifferenz (p₁ - p₂)" = "prob_diff",
        "Regressionskoeffizient (β)" = "regression_coef"
      ),
      selected = "mean"
    ),

    sliderInput("alpha", "Irrtumswahrscheinlichkeit (α)", min = 0.01, max = 0.20, value = 0.05, step = 0.01,
                post = "%", sep = ""),

    uiOutput("param_inputs"),

    actionButton("resample", "Neue Referenzstichprobe ziehen", icon = icon("shuffle")),
    sliderInput("n_samples", "Anzahl weiterer Stichproben:", min = 0, max = MAX_SAMPLES - 1, value = 0, step = 1),
    input_switch("show_true_param", "Wahren Parameter als Linie anzeigen", value = FALSE)
  ),

  layout_columns(
    col_widths = c(8, 4),
    card(
      full_screen = TRUE,
      card_header("Geschätzte Parameter über wiederholte Zufallsstichproben"),
      plotOutput("ci_plot", height = "500px")
    ),
    navset_card_underline(
      nav_panel(
        "Verteilung",
        plotOutput("dist_plot", height = "280px"),
        htmlOutput("bounds_table_output"),
        br(),
        plotOutput("hist_plot", height = "280px")
      ),
      nav_panel(
        "Coverage",
        value_box(
          title = "Intervalle, die den wahren Parameter enthalten",
          value = textOutput("coverage_text"),
          theme = "info"
        )
      )
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================

server <- function(input, output, session) {

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
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
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
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
        )
      },
      "mean_diff" = {
        tagList(
          numericInput("param1", "Mittelwert Gruppe 1 (μ₁)", value = 10),
          numericInput("param2", "Mittelwert Gruppe 2 (μ₂)", value = 8),
          numericInput("param3", "Standardabweichung (σ)", value = 3, min = 0.01),
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
        )
      },
      "prob_diff" = {
        tagList(
          sliderInput("param1", "Wahrscheinlichkeit Gruppe 1 (p₁)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),
          sliderInput("param2", "Wahrscheinlichkeit Gruppe 2 (p₂)", min = 0.01, max = 0.99, value = 0.3, step = 0.01),
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
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

  cache <- reactiveVal(NULL)

  full_regenerate <- function() {
    req(input$parameter, input$n, input$alpha)
    target <- input$n_samples + 1
    alpha <- input$alpha / 100

    samples <- switch(input$parameter,
      "mean" = {
        req(input$param1, input$param2)
        draw_mean_samples(seq_len(target), mu = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
      },
      "probability" = {
        req(input$param1)
        draw_probability_samples(seq_len(target), p = input$param1, n = input$n, alpha = alpha)
      },
      "odds" = {
        req(input$param1)
        draw_odds_samples(seq_len(target), p = input$param1, n = input$n, alpha = alpha)
      },
      "odds_ratio" = {
        req(input$param1, input$param2, input$n1, input$n2)
        draw_odds_ratio_samples(seq_len(target), p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
      },
      "variance" = {
        req(input$param1)
        draw_variance_samples(seq_len(target), sigma2 = input$param1, n = input$n, alpha = alpha)
      },
      "variance_ratio" = {
        req(input$param1, input$param2, input$n1, input$n2)
        draw_variance_ratio_samples(seq_len(target), sigma2_1 = input$param1, sigma2_2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
      },
      "mean_diff" = {
        req(input$param1, input$param2, input$param3, input$n1, input$n2)
        draw_mean_diff_samples(seq_len(target), mu1 = input$param1, mu2 = input$param2, sigma = input$param3, n1 = input$n1, n2 = input$n2, alpha = alpha)
      },
      "prob_diff" = {
        req(input$param1, input$param2, input$n1, input$n2)
        draw_prob_diff_samples(seq_len(target), p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
      },
      "regression_coef" = {
        req(input$param1, input$param2)
        draw_regression_coef_samples(seq_len(target), beta1 = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
      }
    )
    cache(samples)
  }

  grow_cache <- function() {
    current <- cache()
    if (is.null(current)) return(invisible(NULL))
    target <- min(input$n_samples + 1, MAX_SAMPLES)
    if (nrow(current) < target) {
      new_ids <- (nrow(current) + 1):target
      alpha <- input$alpha / 100
      new_rows <- switch(input$parameter,
        "mean" = {
          req(input$param1, input$param2)
          draw_mean_samples(new_ids, mu = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
        },
        "probability" = {
          req(input$param1)
          draw_probability_samples(new_ids, p = input$param1, n = input$n, alpha = alpha)
        },
        "odds" = {
          req(input$param1)
          draw_odds_samples(new_ids, p = input$param1, n = input$n, alpha = alpha)
        },
        "odds_ratio" = {
          req(input$param1, input$param2, input$n1, input$n2)
          draw_odds_ratio_samples(new_ids, p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
        },
        "variance" = {
          req(input$param1)
          draw_variance_samples(new_ids, sigma2 = input$param1, n = input$n, alpha = alpha)
        },
        "variance_ratio" = {
          req(input$param1, input$param2, input$n1, input$n2)
          draw_variance_ratio_samples(new_ids, sigma2_1 = input$param1, sigma2_2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
        },
        "mean_diff" = {
          req(input$param1, input$param2, input$param3, input$n1, input$n2)
          draw_mean_diff_samples(new_ids, mu1 = input$param1, mu2 = input$param2, sigma = input$param3, n1 = input$n1, n2 = input$n2, alpha = alpha)
        },
        "prob_diff" = {
          req(input$param1, input$param2, input$n1, input$n2)
          draw_prob_diff_samples(new_ids, p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
        },
        "regression_coef" = {
          req(input$param1, input$param2)
          draw_regression_coef_samples(new_ids, beta1 = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
        }
      )
      cache(rbind(current, new_rows))
    }
  }

  observeEvent(list(input$parameter, input$param1, input$param2, input$param3, input$n, input$n1, input$n2, input$alpha), full_regenerate(), ignoreInit = FALSE)
  observeEvent(input$resample, full_regenerate())
  observeEvent(input$n_samples, grow_cache())

  plot_data <- reactive({
    df <- cache()
    req(df, nrow(df) > 0)
    keep <- min(input$n_samples + 1, MAX_SAMPLES, nrow(df))
    df[seq_len(keep), ]
  })

  true_param <- reactive({
    switch(input$parameter,
      "mean" = input$param1,
      "probability" = input$param1,
      "odds" = input$param1 / (1 - input$param1),
      "odds_ratio" = (input$param1 / (1 - input$param1)) / (input$param2 / (1 - input$param2)),
      "variance" = input$param1,
      "variance_ratio" = input$param1 / input$param2,
      "mean_diff" = input$param1 - input$param2,
      "prob_diff" = input$param1 - input$param2,
      "regression_coef" = input$param1
    )
  })

  coverage_rate <- reactive({
    df <- plot_data()
    req(df, nrow(df) > 0)
    true_val <- true_param()
    covered <- sum(df$lower <= true_val & true_val <= df$upper)
    total <- nrow(df)
    paste0(covered, "/", total, " (", round(100 * covered / total, 1), "%)")
  })

  output$coverage_text <- renderText(coverage_rate())

  # Berechne gemeinsamen X-Bereich für beide Plots
  x_range_shared <- reactive({
    df <- plot_data()
    req(df, nrow(df) > 0)
    
    # Nutze den Bereich der Rohdaten (alle Schätzungen)
    x_min <- min(df$lower, na.rm = TRUE)
    x_max <- max(df$upper, na.rm = TRUE)
    margin <- (x_max - x_min) * 0.1
    
    list(min = x_min - margin, max = x_max + margin)
  })

  output$dist_plot <- renderPlot({
    p <- plot_distribution(plot_data(), input$parameter, input$alpha / 100)
    if (!is.null(p)) {
      x_range <- x_range_shared()
      p <- p + coord_cartesian(xlim = c(x_range$min, x_range$max))
    }
    p
  })

  output$bounds_table_output <- renderUI({
    df <- plot_data()
    req(df, nrow(df) > 0)
    
    ref_row <- df[1, ]
    lower <- round(ref_row$lower, 4)
    upper <- round(ref_row$upper, 4)
    
    # Erstelle HTML-Tabelle mit besserer Formatierung
    html_table <- paste0(
      "<table style='width: 100%; text-align: center; font-size: 14px; margin: 10px 0;'>",
      "<tr style='background-color: #f0f0f0;'>",
      "<td style='padding: 8px; border: 1px solid #ccc; font-weight: bold;'>Untere Grenze</td>",
      "<td style='padding: 8px; border: 1px solid #ccc; font-weight: bold;'>Obere Grenze</td>",
      "</tr>",
      "<tr>",
      "<td style='padding: 8px; border: 1px solid #ccc;'>", lower, "</td>",
      "<td style='padding: 8px; border: 1px solid #ccc;'>", upper, "</td>",
      "</tr>",
      "</table>"
    )
    
    HTML(html_table)
  })

  output$hist_plot <- renderPlot({
    df <- plot_data()
    req(df, nrow(df) > 0)
    
    x_range <- x_range_shared()

    ggplot(df, aes(x = estimate)) +
      geom_histogram(bins = 15, fill = "#75AADB", color = "white", alpha = 0.8) +
      geom_vline(xintercept = true_param(), linetype = "dashed", color = "#FF744E", linewidth = 1) +
      coord_cartesian(xlim = c(x_range$min, x_range$max)) +
      labs(
        x = "Geschätzte Parameterwerte",
        y = "Häufigkeit",
        title = "Verteilung der Stichproben-Schätzungen"
      ) +
      theme_minimal(base_size = 11) +
      theme(plot.title = element_text(size = 11, face = "bold"))
  })

  output$ci_plot <- renderPlot({
    df <- plot_data()
    df$typ <- ifelse(df$sample_id == 1, "Referenzstichprobe", "Weitere Stichprobe")

    p <- ggplot(df, aes(x = sample_id, y = estimate, color = typ)) +
      geom_pointrange(aes(ymin = lower, ymax = upper), size = 0.8) +
      scale_color_manual(
        values = c("Referenzstichprobe" = COL_REFERENZ, "Weitere Stichprobe" = COL_WEITERE),
        breaks = c("Referenzstichprobe", "Weitere Stichprobe")
      ) +
      labs(
        x = "Stichprobe",
        y = "Geschätzter Parameter (95%-Konfidenzintervall)",
        color = NULL
      ) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "top")

    if (input$show_true_param) {
      p <- p + geom_hline(yintercept = true_param(), linetype = "dashed", color = "black", linewidth = 1)
    }

    p
  })
}

shinyApp(ui, server)
