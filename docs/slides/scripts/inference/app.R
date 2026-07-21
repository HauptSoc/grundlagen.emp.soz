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
    x_range <- c(est - 6*se, est + 6*se)
    x_vals <- seq(x_range[1], x_range[2], length.out = 200)
    y_vals <- dt((x_vals - est) / se, df) / se
    lower_crit <- est - z_crit * se
    upper_crit <- est + z_crit * se
    label_text <- paste0("t-Verteilung (df=", df, ")\nSE = ", round(se, 4))

  } else if (dist_type == "normal") {
    z_crit <- qnorm(1 - alpha/2)
    x_range <- c(est - 6*se, est + 6*se)
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

  # Konfidenzintervall: Fläche zwischen den Grenzen
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
      title = "Verteilung zur KI-Berechnung (Referenzstichprobe)",
      subtitle = label_text
    ) +
    theme_minimal(base_size = 10) +
    theme(
      plot.title = element_text(size = 10, face = "bold"),
      plot.margin = margin(2, 5, 2, 5)
    )

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

# Visualisiere Hypothesentest-Verteilungen (NICHT gesampelt, sondern theoretisch)
plot_distribution_for_hypothesis_test <- function(empirical_param, empirical_se, parameter_type, alpha, df1 = NULL, df2 = NULL) {
  if (is.null(empirical_param) || is.null(empirical_se) || empirical_se <= 0) {
    return(NULL)
  }

  # Basis-Teststatistik: Parameterwert / Standardfehler
  test_stat_raw <- empirical_param / empirical_se

  x_vals <- NULL
  y_vals <- NULL
  pvalue <- NA
  label_text <- ""
  crit_val_lower <- NULL
  crit_val_upper <- NULL
  plot_test_stat <- test_stat_raw  # Wert, der als Punkt dargestellt wird

  # ── t-Verteilung: Mittelwert, Mittelwertdifferenz, Regression ──
  if (parameter_type %in% c("mean", "mean_diff", "regression_coef")) {
    df <- if (!is.null(df1)) df1 else 30
    x_range <- c(-6, 6)
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- dt(x_vals, df)
    pvalue <- 2 * (1 - pt(abs(test_stat_raw), df))
    label_text <- paste0("t-Verteilung (df = ", df, ")")
    crit_val_upper <- qt(1 - alpha/2, df)
    crit_val_lower <- -crit_val_upper

  # ── Normalverteilung (z-Test): Wahrscheinlichkeit, Differenz ──
  } else if (parameter_type %in% c("probability", "prob_diff")) {
    x_range <- c(-6, 6)
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- dnorm(x_vals)
    pvalue <- 2 * (1 - pnorm(abs(test_stat_raw)))
    label_text <- "Normalverteilung (z-Test)"
    crit_val_upper <- qnorm(1 - alpha/2)
    crit_val_lower <- -crit_val_upper

  # ── Normalverteilung auf logit-Skala: Odds ──
  } else if (parameter_type == "odds") {
    x_range <- c(-6, 6)
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- dnorm(x_vals)
    pvalue <- 2 * (1 - pnorm(abs(test_stat_raw)))
    label_text <- "Normalverteilung (z-Test, logit-Skala)"
    crit_val_upper <- qnorm(1 - alpha/2)
    crit_val_lower <- -crit_val_upper

  # ── Normalverteilung auf log-Skala: Odds Ratio ──
  } else if (parameter_type == "odds_ratio") {
    x_range <- c(-6, 6)
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- dnorm(x_vals)
    pvalue <- 2 * (1 - pnorm(abs(test_stat_raw)))
    label_text <- "Normalverteilung (z-Test, log-Skala)"
    crit_val_upper <- qnorm(1 - alpha/2)
    crit_val_lower <- -crit_val_upper

  # ── Chi-Quadrat-Verteilung: Varianz ──
  } else if (parameter_type == "variance") {
    df <- if (!is.null(df1)) df1 else 30
    # Teststatistik: χ² = df × (Parameterwert / SE)
    chi_stat <- df * test_stat_raw
    plot_test_stat <- chi_stat
    x_range <- c(max(0.01, qchisq(0.001, df)), qchisq(0.999, df))
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- dchisq(x_vals, df)
    # Zweiseitiger p-Wert
    pvalue <- 2 * min(pchisq(chi_stat, df), 1 - pchisq(chi_stat, df))
    label_text <- paste0("Chi-Quadrat-Verteilung (df = ", df, ")")
    crit_val_lower <- qchisq(alpha/2, df)
    crit_val_upper <- qchisq(1 - alpha/2, df)

  # ── F-Verteilung: Varianzverhältnis ──
  } else if (parameter_type == "variance_ratio") {
    df1_v <- if (!is.null(df1)) df1 else 30
    df2_v <- if (!is.null(df2)) df2 else 30
    # Teststatistik: F = Parameterwert / SE (= s₁²/s₂²)
    f_stat <- test_stat_raw
    if (f_stat <= 0) f_stat <- 0.01
    plot_test_stat <- f_stat
    x_range <- c(max(0.01, qf(0.001, df1_v, df2_v)), qf(0.999, df1_v, df2_v))
    x_vals <- seq(x_range[1], x_range[2], length.out = 300)
    y_vals <- df(x_vals, df1_v, df2_v)
    # Zweiseitiger p-Wert
    pvalue <- 2 * min(pf(f_stat, df1_v, df2_v), 1 - pf(f_stat, df1_v, df2_v))
    label_text <- paste0("F-Verteilung (df1 = ", df1_v, ", df2 = ", df2_v, ")")
    crit_val_lower <- qf(alpha/2, df1_v, df2_v)
    crit_val_upper <- qf(1 - alpha/2, df1_v, df2_v)
  }

  if (is.null(x_vals)) return(NULL)

  # Ablehnungsbereiche basierend auf kritischen Werten (zweiseitig)
  x_fill_left <- x_vals[x_vals <= crit_val_lower]
  y_fill_left <- y_vals[x_vals <= crit_val_lower]
  x_fill_right <- x_vals[x_vals >= crit_val_upper]
  y_fill_right <- y_vals[x_vals >= crit_val_upper]

  p <- ggplot() +
    geom_line(aes(x = x_vals, y = y_vals), color = "#555", linewidth = 1) +
    geom_area(aes(x = x_fill_left, y = y_fill_left), fill = "#FF744E", alpha = 0.2) +
    geom_area(aes(x = x_fill_right, y = y_fill_right), fill = "#FF744E", alpha = 0.2) +
    geom_vline(xintercept = crit_val_lower, linetype = "dashed", color = "#FF744E", linewidth = 0.9) +
    geom_vline(xintercept = crit_val_upper, linetype = "dashed", color = "#FF744E", linewidth = 0.9) +
    # Empirischer Test-Wert als Punkt auf der x-Achse
    geom_point(aes(x = plot_test_stat, y = 0), size = 4, color = COL_WEITERE, shape = 16)

  crit_label <- paste0("Krit. Werte: ", round(crit_val_lower, 3), " / ", round(crit_val_upper, 3))

  p <- p +
    labs(
      x = "Test-Statistik",
      y = "Dichte",
      title = "Hypothesentest: Verteilung unter der Nullhypothese",
      subtitle = paste0(
        label_text,
        " | Test-Wert = ", round(plot_test_stat, 4),
        " | p = ", if (is.na(pvalue)) "N/A" else round(pvalue, 4),
        "\n", crit_label
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(size = 11, face = "bold"))

  p
}

# Berechne und zeige die Formeln zur Berechnung der CI-Grenzen
calculation_display <- function(data, alpha, parameter_type) {
  if (is.null(data) || nrow(data) == 0) return(NULL)
  
  ref_row <- data[1, ]
  est <- ref_row$estimate
  se <- ref_row$se
  dist_type <- ref_row$dist_type
  df1 <- ref_row$df1
  df2 <- ref_row$df2
  
  html_content <- ""
  
  if (dist_type == "t") {
    df <- df1
    z_crit <- qt(1 - alpha/2, df)
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls:</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "CI = Schätzung ± t<sub>krit</sub>(α, df) × SE<br>",
      "CI = ", round(est, 4), " ± ", round(z_crit, 4), " × ", round(se, 4), "<br>",
      "CI = ", round(est, 4), " ± ", round(z_crit * se, 4),
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritischer Wert:</strong> t<sub>krit</sub> = ", round(z_crit, 4), 
      " (α = ", round(alpha, 4), ", df = ", df, ")",
      "</p>",
      "</div>"
    )
  } else if (dist_type == "normal") {
    z_crit <- qnorm(1 - alpha/2)
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls:</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "CI = Schätzung ± z<sub>krit</sub>(α) × SE<br>",
      "CI = ", round(est, 4), " ± ", round(z_crit, 4), " × ", round(se, 4), "<br>",
      "CI = ", round(est, 4), " ± ", round(z_crit * se, 4),
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritischer Wert:</strong> z<sub>krit</sub> = ", round(z_crit, 4), 
      " (α = ", round(alpha, 4), ")",
      "</p>",
      "</div>"
    )
  } else if (dist_type == "normal_logit") {
    z_crit <- qnorm(1 - alpha/2)
    logit_est <- log(est / (1 - est))
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls (auf logit-Skala):</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "logit(CI) = logit(p̂) ± z<sub>krit</sub> × SE(logit)<br>",
      "logit(CI) = ", round(logit_est, 4), " ± ", round(z_crit, 4), " × ", round(se, 4), "<br>",
      "CI = exp(logit(CI)) / (1 + exp(logit(CI)))",
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritischer Wert:</strong> z<sub>krit</sub> = ", round(z_crit, 4), 
      " (α = ", round(alpha, 4), ")",
      "</p>",
      "</div>"
    )
  } else if (dist_type == "normal_log") {
    z_crit <- qnorm(1 - alpha/2)
    log_est <- log(est)
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls (auf log-Skala):</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "log(CI) = log(Est) ± z<sub>krit</sub> × SE(log)<br>",
      "log(CI) = ", round(log_est, 4), " ± ", round(z_crit, 4), " × ", round(se, 4), "<br>",
      "CI = exp(log(CI))",
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritischer Wert:</strong> z<sub>krit</sub> = ", round(z_crit, 4), 
      " (α = ", round(alpha, 4), ")",
      "</p>",
      "</div>"
    )
  } else if (dist_type == "chisq") {
    df <- df1
    lower_crit <- qchisq(1 - alpha/2, df)
    upper_crit <- qchisq(alpha/2, df)
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls (Chi-Quadrat):</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "Untere Grenze = (df × s²) / χ²<sub>upper</sub><br>",
      "Obere Grenze = (df × s²) / χ²<sub>lower</sub><br>",
      "mit df = ", df, ", s² = ", round(est, 4),
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritische Werte:</strong> χ²<sub>lower</sub> = ", round(lower_crit, 4), 
      ", χ²<sub>upper</sub> = ", round(upper_crit, 4), " (α = ", round(alpha, 4), ")",
      "</p>",
      "</div>"
    )
  } else if (dist_type == "f") {
    df1_val <- df1
    df2_val <- df2
    lower_crit <- qf(alpha/2, df1_val, df2_val)
    upper_crit <- qf(1 - alpha/2, df1_val, df2_val)
    html_content <- paste0(
      "<div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #75AADB; margin: 15px 0; font-size: 13px;'>",
      "<p style='margin: 0 0 10px 0;'><strong>Berechnung des Konfidenzintervalls (F-Verteilung):</strong></p>",
      "<p style='margin: 5px 0; font-family: monospace;'>",
      "Untere Grenze = F / F<sub>upper</sub><br>",
      "Obere Grenze = F / F<sub>lower</sub><br>",
      "mit F = ", round(est, 4),
      "</p>",
      "<p style='margin: 10px 0 0 0; font-size: 12px; color: #555;'>",
      "<strong>Kritische Werte:</strong> F<sub>lower</sub> = ", round(lower_crit, 4), 
      ", F<sub>upper</sub> = ", round(upper_crit, 4), 
      " (df1 = ", df1_val, ", df2 = ", df2_val, ", α = ", round(alpha, 4), ")",
      "</p>",
      "</div>"
    )
  } else {
    html_content <- "<div style='background-color: #f8f9fa; padding: 15px; margin: 15px 0;'><p>Berechnung nicht verfügbar für diesen Parametertyp.</p></div>"
  }
  
  HTML(html_content)
}

# =============================================================================
# HELPER: p-Wert-Berechnung für Signifikanztests
# =============================================================================

compute_sig_pvalue <- function(test_stat, param_type, df1 = NULL, df2 = NULL) {
  switch(param_type,
    # t-Verteilung
    "mean" = 2 * (1 - pt(abs(test_stat), if (!is.null(df1)) df1 else 30)),
    "mean_diff" = 2 * (1 - pt(abs(test_stat), if (!is.null(df1)) df1 else 30)),
    "regression_coef" = 2 * (1 - pt(abs(test_stat), if (!is.null(df1)) df1 else 30)),
    # Normalverteilung (z-Test)
    "probability" = 2 * (1 - pnorm(abs(test_stat))),
    "prob_diff" = 2 * (1 - pnorm(abs(test_stat))),
    "odds" = 2 * (1 - pnorm(abs(test_stat))),
    "odds_ratio" = 2 * (1 - pnorm(abs(test_stat))),
    # Chi-Quadrat: Teststatistik = df * (param/SE)
    "variance" = {
      df <- if (!is.null(df1)) df1 else 30
      chi_stat <- df * test_stat
      2 * min(pchisq(chi_stat, df), 1 - pchisq(chi_stat, df))
    },
    # F-Verteilung: Teststatistik = param/SE
    "variance_ratio" = {
      df1_v <- if (!is.null(df1)) df1 else 30
      df2_v <- if (!is.null(df2)) df2 else 30
      f_stat <- test_stat
      2 * min(pf(f_stat, df1_v, df2_v), 1 - pf(f_stat, df1_v, df2_v))
    },
    NA
  )
}

# =============================================================================
# UI
# =============================================================================

ui <- page_sidebar(
  title = "Stichprobenvariabilität: Konfidenzintervalle für verschiedene Parameter",
  theme = bs_theme(version = 5, primary = "#75AADB"),
  sidebar = sidebar(
    input_switch("significance_test", "Signifikanztest", value = FALSE),

    selectInput(
      "parameter", "Parameter:",
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

    sliderInput("alpha", "Irrtumswahrscheinlichkeit (α)",
                min = 0.01, max = 0.20, value = 0.05, step = 0.01, sep = ""),

    uiOutput("param_inputs"),

    conditionalPanel(
      "!input.significance_test",
      actionButton("resample", "Neue Referenzstichprobe ziehen", icon = icon("shuffle")),
      sliderInput("n_samples", "Anzahl weiterer Stichproben:",
                  min = 0, max = MAX_SAMPLES - 1, value = 0, step = 1),
      input_switch("show_true_param", "Wahren Parameter als Linie anzeigen", value = FALSE)
    )
  ),

  # ── CSS und JS für verschiebbare Split-Panels ──
  tags$head(tags$style(HTML("
    .split-container {
      display: flex;
      width: 100%;
      min-height: 700px;
      gap: 0;
    }
    .split-left {
      flex: 1 1 50%;
      min-width: 200px;
      overflow: auto;
    }
    .split-right {
      flex: 1 1 50%;
      min-width: 200px;
      overflow: auto;
    }
    .split-handle {
      width: 8px;
      cursor: col-resize;
      background: #dee2e6;
      border-radius: 4px;
      flex-shrink: 0;
      transition: background 0.15s;
      position: relative;
    }
    .split-handle:hover, .split-handle.active {
      background: #75AADB;
    }
    .split-handle::after {
      content: '⋮';
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: #888;
      font-size: 14px;
    }
    .split-handle:hover::after, .split-handle.active::after {
      color: white;
    }
  "))),
  tags$head(tags$script(HTML("
    $(document).ready(function() {
      var handle = document.getElementById('split-handle');
      var container = document.getElementById('split-container');
      var left = document.getElementById('split-left');
      var right = document.getElementById('split-right');
      if (!handle || !container) return;

      var dragging = false;

      handle.addEventListener('mousedown', function(e) {
        e.preventDefault();
        dragging = true;
        handle.classList.add('active');
        document.body.style.cursor = 'col-resize';
        document.body.style.userSelect = 'none';
      });

      document.addEventListener('mousemove', function(e) {
        if (!dragging) return;
        var rect = container.getBoundingClientRect();
        var offset = e.clientX - rect.left;
        var pct = (offset / rect.width) * 100;
        pct = Math.max(15, Math.min(85, pct));
        left.style.flex = '0 0 ' + pct + '%';
        right.style.flex = '0 0 ' + (100 - pct - 1) + '%';
        // Trigger Shiny recalc for plot sizing
        $(window).trigger('resize');
      });

      document.addEventListener('mouseup', function() {
        if (dragging) {
          dragging = false;
          handle.classList.remove('active');
          document.body.style.cursor = '';
          document.body.style.userSelect = '';
          $(window).trigger('resize');
        }
      });
    });
  "))),

  # ── HAUPTBEREICH ──
  # KI-Modus: 2 Spalten mit verschiebbarem Divider
  # Signifikanztest-Modus: nur eine Spalte (volle Breite)
  conditionalPanel(
    "!input.significance_test",
    div(
      id = "split-container", class = "split-container",

      # SPALTE 1 (MITTE): KI-Plot
      div(
        id = "split-left", class = "split-left",
        card(
          full_screen = TRUE,
          card_header("Geschätzte Parameter über wiederholte Zufallsstichproben"),
          plotOutput("ci_plot", height = "650px")
        )
      ),

      # Draggable Handle
      div(id = "split-handle", class = "split-handle"),

      # SPALTE 2 (RECHTS): Tabs
      div(
        id = "split-right", class = "split-right",
        navset_card_underline(
          title = NULL,
          nav_panel(
            "Verteilungen",
            h6("A) Berechnung des Konfidenzintervalls für die Referenzstichprobe",
               style = "margin-top: 10px; margin-bottom: 5px;"),
            plotOutput("dist_plot", height = "280px"),
            htmlOutput("calculation_output"),
            htmlOutput("bounds_table_output"),
            h6("B) Verteilung der Parameter aus den gezogenen Stichproben",
               style = "margin-top: 15px; margin-bottom: 5px;"),
            plotOutput("hist_plot", height = "250px")
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
  ),
  conditionalPanel(
    "input.significance_test",
    card(
      full_screen = TRUE,
      card_header("Signifikanztest"),
      plotOutput("dist_plot_sig", height = "650px")
    )
  )
)

# =============================================================================
# SERVER
# =============================================================================

server <- function(input, output, session) {

  # ── Parameter-Eingaben ──
  output$param_inputs <- renderUI({
    if (isTRUE(input$significance_test)) {
      # Stichprobengröße(n) für korrekte df-Berechnung
      size_inputs <- switch(input$parameter,
        "mean" = sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5),
        "probability" = sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5),
        "odds" = sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5),
        "odds_ratio" = tagList(
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
        ),
        "variance" = sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5),
        "variance_ratio" = tagList(
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
        ),
        "mean_diff" = tagList(
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
        ),
        "prob_diff" = tagList(
          sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
          sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
        ),
        "regression_coef" = sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 40, step = 5)
      )
      return(tagList(
        numericInput("empirical_param", "Empirischer Parameterwert", value = 2),
        numericInput("empirical_se", "Empirischer Standardfehler", value = 1, min = 0.001),
        size_inputs
      ))
    }

    switch(input$parameter,
      "mean" = tagList(
        numericInput("param1", "Mittelwert der Grundgesamtheit (μ)", value = 100),
        numericInput("param2", "Standardabweichung (σ)", value = 15, min = 0.01),
        sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5)
      ),
      "probability" = tagList(
        sliderInput("param1", "Wahrscheinlichkeit (p)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),
        sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5)
      ),
      "odds" = tagList(
        sliderInput("param1", "Wahrscheinlichkeit (p)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),
        sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 50, step = 5)
      ),
      "odds_ratio" = tagList(
        sliderInput("param1", "Wahrscheinlichkeit Gruppe 1 (p₁)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),
        sliderInput("param2", "Wahrscheinlichkeit Gruppe 2 (p₂)", min = 0.01, max = 0.99, value = 0.3, step = 0.01),
        sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
        sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
      ),
      "variance" = tagList(
        numericInput("param1", "Varianz der Grundgesamtheit (σ²)", value = 25, min = 0.1),
        sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 30, step = 5)
      ),
      "variance_ratio" = tagList(
        numericInput("param1", "Varianz Gruppe 1 (σ₁²)", value = 25, min = 0.1),
        numericInput("param2", "Varianz Gruppe 2 (σ₂²)", value = 15, min = 0.1),
        sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
        sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
      ),
      "mean_diff" = tagList(
        numericInput("param1", "Mittelwert Gruppe 1 (μ₁)", value = 10),
        numericInput("param2", "Mittelwert Gruppe 2 (μ₂)", value = 8),
        numericInput("param3", "Standardabweichung (σ)", value = 3, min = 0.01),
        sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 30, step = 5),
        sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 30, step = 5)
      ),
      "prob_diff" = tagList(
        sliderInput("param1", "Wahrscheinlichkeit Gruppe 1 (p₁)", min = 0.01, max = 0.99, value = 0.5, step = 0.01),
        sliderInput("param2", "Wahrscheinlichkeit Gruppe 2 (p₂)", min = 0.01, max = 0.99, value = 0.3, step = 0.01),
        sliderInput("n1", "Stichprobengröße Gruppe 1 (n₁)", min = 5, max = 500, value = 50, step = 5),
        sliderInput("n2", "Stichprobengröße Gruppe 2 (n₂)", min = 5, max = 500, value = 50, step = 5)
      ),
      "regression_coef" = tagList(
        numericInput("param1", "Regressionskoeffizient (β₁)", value = 2),
        numericInput("param2", "Residualstandardabweichung (σ)", value = 5, min = 0.01),
        sliderInput("n", "Stichprobengröße (n)", min = 5, max = 500, value = 40, step = 5)
      )
    )
  })

  # ── Cache und Sampling ──
  cache <- reactiveVal(NULL)

  full_regenerate <- function() {
    req(input$parameter, input$alpha)
    alpha <- input$alpha

    if (isTRUE(input$significance_test)) {
      # Im Sig-Test: Erstelle Dummy-Cache (keine Sampling nötig)
      req(input$empirical_param, input$empirical_se)
      param_type <- input$parameter

      # df-Werte aus Stichprobengröße berechnen
      df1_val <- switch(param_type,
        "mean" = { req(input$n); input$n - 1 },
        "regression_coef" = { req(input$n); input$n - 2 },
        "variance" = { req(input$n); input$n - 1 },
        "mean_diff" = { req(input$n1, input$n2); min(input$n1 - 1, input$n2 - 1) },
        "variance_ratio" = { req(input$n1); input$n1 - 1 },
        "odds_ratio" = { req(input$n1); input$n1 - 1 },
        "prob_diff" = { req(input$n1); input$n1 - 1 },
        "probability" = { req(input$n); input$n - 1 },
        "odds" = { req(input$n); input$n - 1 },
        29
      )
      df2_val <- switch(param_type,
        "variance_ratio" = { req(input$n2); input$n2 - 1 },
        "odds_ratio" = { req(input$n2); input$n2 - 1 },
        "mean_diff" = { req(input$n2); input$n2 - 1 },
        "prob_diff" = { req(input$n2); input$n2 - 1 },
        NA_real_
      )

      dummy_data <- data.frame(
        sample_id = 1,
        estimate = input$empirical_param,
        se = input$empirical_se,
        lower = NA_real_,
        upper = NA_real_,
        dist_type = switch(param_type,
          "mean" = "t", "probability" = "normal", "odds" = "normal",
          "odds_ratio" = "f", "variance" = "chisq", "variance_ratio" = "f",
          "mean_diff" = "t", "prob_diff" = "normal", "regression_coef" = "t",
          "normal"
        ),
        df1 = df1_val,
        df2 = df2_val
      )
      cache(dummy_data)
      return(invisible(NULL))
    }

    # Im KI-Modus
    target <- if (!is.null(input$n_samples)) input$n_samples + 1 else 1

    samples <- switch(input$parameter,
      "mean" = {
        req(input$param1, input$param2, input$n)
        draw_mean_samples(seq_len(target), mu = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
      },
      "probability" = {
        req(input$param1, input$n)
        draw_probability_samples(seq_len(target), p = input$param1, n = input$n, alpha = alpha)
      },
      "odds" = {
        req(input$param1, input$n)
        draw_odds_samples(seq_len(target), p = input$param1, n = input$n, alpha = alpha)
      },
      "odds_ratio" = {
        req(input$param1, input$param2, input$n1, input$n2)
        draw_odds_ratio_samples(seq_len(target), p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha)
      },
      "variance" = {
        req(input$param1, input$n)
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
        req(input$param1, input$param2, input$n)
        draw_regression_coef_samples(seq_len(target), beta1 = input$param1, sigma = input$param2, n = input$n, alpha = alpha)
      }
    )
    cache(samples)
  }

  grow_cache <- function() {
    if (isTRUE(input$significance_test)) return(invisible(NULL))
    current <- cache()
    if (is.null(current)) return(invisible(NULL))
    target <- min(input$n_samples + 1, MAX_SAMPLES)
    if (nrow(current) >= target) return(invisible(NULL))

    new_ids <- (nrow(current) + 1):target
    alpha <- input$alpha
    new_rows <- switch(input$parameter,
      "mean"             = { req(input$param1, input$param2, input$n);            draw_mean_samples(new_ids, mu = input$param1, sigma = input$param2, n = input$n, alpha = alpha) },
      "probability"      = { req(input$param1, input$n);                          draw_probability_samples(new_ids, p = input$param1, n = input$n, alpha = alpha) },
      "odds"             = { req(input$param1, input$n);                          draw_odds_samples(new_ids, p = input$param1, n = input$n, alpha = alpha) },
      "odds_ratio"       = { req(input$param1, input$param2, input$n1, input$n2); draw_odds_ratio_samples(new_ids, p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha) },
      "variance"         = { req(input$param1, input$n);                          draw_variance_samples(new_ids, sigma2 = input$param1, n = input$n, alpha = alpha) },
      "variance_ratio"   = { req(input$param1, input$param2, input$n1, input$n2); draw_variance_ratio_samples(new_ids, sigma2_1 = input$param1, sigma2_2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha) },
      "mean_diff"        = { req(input$param1, input$param2, input$param3, input$n1, input$n2); draw_mean_diff_samples(new_ids, mu1 = input$param1, mu2 = input$param2, sigma = input$param3, n1 = input$n1, n2 = input$n2, alpha = alpha) },
      "prob_diff"        = { req(input$param1, input$param2, input$n1, input$n2); draw_prob_diff_samples(new_ids, p1 = input$param1, p2 = input$param2, n1 = input$n1, n2 = input$n2, alpha = alpha) },
      "regression_coef"  = { req(input$param1, input$param2, input$n);            draw_regression_coef_samples(new_ids, beta1 = input$param1, sigma = input$param2, n = input$n, alpha = alpha) }
    )
    cache(rbind(current, new_rows))
  }

  observeEvent(
    list(input$parameter, input$param1, input$param2, input$param3,
         input$n, input$n1, input$n2, input$alpha,
         input$significance_test, input$empirical_param, input$empirical_se),
    full_regenerate(), ignoreInit = FALSE
  )
  observeEvent(input$resample, full_regenerate())
  observeEvent(input$n_samples, grow_cache())

  # ── Reactive helpers ──
  plot_data <- reactive({
    df <- cache()
    req(df, nrow(df) > 0)
    if (isTRUE(input$significance_test)) return(df)
    n_show <- if (!is.null(input$n_samples)) input$n_samples + 1 else 1
    keep <- min(n_show, MAX_SAMPLES, nrow(df))
    df[seq_len(keep), ]
  })

  true_param <- reactive({
    switch(input$parameter,
      "mean" = input$param1, "probability" = input$param1,
      "odds" = input$param1 / (1 - input$param1),
      "odds_ratio" = (input$param1 / (1 - input$param1)) / (input$param2 / (1 - input$param2)),
      "variance" = input$param1, "variance_ratio" = input$param1 / input$param2,
      "mean_diff" = input$param1 - input$param2, "prob_diff" = input$param1 - input$param2,
      "regression_coef" = input$param1
    )
  })

  coverage_rate <- reactive({
    req(!isTRUE(input$significance_test))
    df <- plot_data()
    req(df, nrow(df) > 0)
    true_val <- true_param()
    req(true_val)
    covered <- sum(df$lower <= true_val & true_val <= df$upper, na.rm = TRUE)
    total <- nrow(df)
    paste0(covered, "/", total, " (", round(100 * covered / total, 1), "%)")
  })

  output$coverage_text <- renderText(coverage_rate())

  x_range_shared <- reactive({
    df <- plot_data()
    req(df, nrow(df) > 0)
    lwr <- df$lower[is.finite(df$lower)]
    upr <- df$upper[is.finite(df$upper)]
    req(length(lwr) > 0, length(upr) > 0)
    x_min <- min(lwr); x_max <- max(upr)
    margin <- (x_max - x_min) * 0.1
    list(min = x_min - margin, max = x_max + margin)
  })

  # ── Outputs ──
  output$ci_plot <- renderPlot({
    req(!isTRUE(input$significance_test))
    df <- plot_data()
    req(df, nrow(df) > 0)
    df$typ <- ifelse(df$sample_id == 1, "Referenzstichprobe", "Weitere Stichprobe")
    p <- ggplot(df, aes(x = sample_id, y = estimate, color = typ)) +
      geom_pointrange(aes(ymin = lower, ymax = upper), size = 0.8) +
      scale_color_manual(
        values = c("Referenzstichprobe" = COL_REFERENZ, "Weitere Stichprobe" = COL_WEITERE),
        breaks = c("Referenzstichprobe", "Weitere Stichprobe")
      ) +
      labs(x = "Stichprobe", y = "Geschätzter Parameter (95%-KI)", color = NULL) +
      theme_minimal(base_size = 14) + theme(legend.position = "top")
    if (isTRUE(input$show_true_param)) {
      p <- p + geom_hline(yintercept = true_param(), linetype = "dashed", color = "black", linewidth = 1)
    }
    p
  })

  output$dist_plot_sig <- renderPlot({
    req(isTRUE(input$significance_test), input$empirical_param, input$empirical_se)
    df_vals <- plot_data()
    req(df_vals, nrow(df_vals) > 0)
    ref <- df_vals[1, ]
    plot_distribution_for_hypothesis_test(
      empirical_param = input$empirical_param,
      empirical_se    = input$empirical_se,
      parameter_type  = input$parameter,
      alpha           = input$alpha,
      df1             = ref$df1,
      df2             = ref$df2
    )
  })

  output$dist_plot <- renderPlot({
    req(!isTRUE(input$significance_test))
    df <- plot_data()
    req(df, nrow(df) > 0)
    p <- plot_distribution(df, input$parameter, input$alpha)
    if (!is.null(p)) {
      xr <- x_range_shared()
      p <- p + coord_cartesian(xlim = c(xr$min, xr$max))
    }
    p
  })

  output$hist_plot <- renderPlot({
    req(!isTRUE(input$significance_test))
    df <- plot_data()
    req(df, nrow(df) > 0)
    xr <- x_range_shared()
    ggplot(df, aes(x = estimate)) +
      geom_histogram(bins = 15, fill = "#75AADB", color = "white", alpha = 0.8) +
      geom_vline(xintercept = true_param(), linetype = "dashed", color = "#FF744E", linewidth = 1) +
      coord_cartesian(xlim = c(xr$min, xr$max)) +
      labs(x = "Geschätzte Parameterwerte", y = "Häufigkeit",
           title = "Verteilung der Stichproben-Schätzungen") +
      theme_minimal(base_size = 11) +
      theme(plot.title = element_text(size = 11, face = "bold"))
  })

  output$calculation_output <- renderUI({
    req(!isTRUE(input$significance_test))
    df <- plot_data()
    req(df, nrow(df) > 0)
    calculation_display(df, input$alpha, input$parameter)
  })

  output$bounds_table_output <- renderUI({
    df <- plot_data()
    req(df, nrow(df) > 0)
    ref_row <- df[1, ]

    if (isTRUE(input$significance_test)) {
      req(input$empirical_param, input$empirical_se)
      param_type <- input$parameter
      test_stat <- input$empirical_param / input$empirical_se
      pval <- compute_sig_pvalue(test_stat, param_type, ref_row$df1, ref_row$df2)
      HTML(paste0(
        "<table style='width:100%;text-align:center;font-size:14px;margin:10px 0;'>",
        "<tr style='background:#f0f0f0;'>",
        "<td style='padding:8px;border:1px solid #ccc;font-weight:bold;'>p-value</td>",
        "<td style='padding:8px;border:1px solid #ccc;font-weight:bold;'>Signifikanz</td></tr>",
        "<tr><td style='padding:8px;border:1px solid #ccc;'>",
        if(is.na(pval)) "N/A" else format(pval, scientific=TRUE, digits=4),
        "</td><td style='padding:8px;border:1px solid #ccc;'>",
        if(is.na(pval)) "N/A" else if(pval < input$alpha) "Signifikant" else "Nicht signifikant",
        "</td></tr></table>"))
    } else {
      HTML(paste0(
        "<table style='width:100%;text-align:center;font-size:14px;margin:10px 0;'>",
        "<tr style='background:#f0f0f0;'>",
        "<td style='padding:8px;border:1px solid #ccc;font-weight:bold;'>Untere Grenze</td>",
        "<td style='padding:8px;border:1px solid #ccc;font-weight:bold;'>Obere Grenze</td></tr>",
        "<tr><td style='padding:8px;border:1px solid #ccc;'>", round(ref_row$lower,4),
        "</td><td style='padding:8px;border:1px solid #ccc;'>", round(ref_row$upper,4),
        "</td></tr></table>"))
    }
  })

  output$sig_test_summary <- renderUI({
    req(isTRUE(input$significance_test), input$empirical_param, input$empirical_se)
    df <- plot_data()
    req(df, nrow(df) > 0)
    ref_row <- df[1, ]
    param_type <- input$parameter
    test_stat <- input$empirical_param / input$empirical_se
    pval <- compute_sig_pvalue(test_stat, param_type, ref_row$df1, ref_row$df2)
    HTML(paste0(
      "<div style='background:#f8f9fa;padding:15px;border-radius:5px;margin:15px 0;'>",
      "<p style='margin:0 0 10px 0;'><strong>Signifikanztest-Zusammenfassung:</strong></p>",
      "<p style='margin:5px 0;'><strong>Empirischer Parameterwert:</strong> ", round(input$empirical_param,4), "</p>",
      "<p style='margin:5px 0;'><strong>Empirischer Standardfehler:</strong> ", round(input$empirical_se,4), "</p>",
      "<p style='margin:5px 0;'><strong>Test-Statistik:</strong> ", round(test_stat,4), "</p>",
      if(!is.na(pval)) paste0(
        "<p style='margin:10px 0 0 0;font-weight:bold;color:",
        if(pval < input$alpha) "#FF744E" else "#555",
        ";'>p-value = ", format(pval, scientific=TRUE, digits=4),
        " → ", if(pval < input$alpha) "Signifikant" else "Nicht signifikant",
        " (α=", round(input$alpha,4), ")</p>"
      ) else "<p>p-value konnte nicht berechnet werden.</p>",
      "</div>"))
  })
}

shinyApp(ui, server)
