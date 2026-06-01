library(shiny)
library(tidyverse)

make_plot <- function(beta_0 = 0.9, beta_1 = 0.65, sigma = 0.55,
                      x_knots = seq(1.0, 6.0, length.out = 6), n_cond = 4000,
                      dens_width = 0.55, seg_width = 0.85,
                      display_mode = "both") {
  yhat_fun <- function(x) beta_0 + beta_1 * x

  make_conditional_density <- function(x0, n = 4000, sigma = 0.55, width = 0.55) {
    y <- rnorm(n, mean = yhat_fun(x0), sd = sigma)
    d <- density(y, n = 300)

    tibble(
      x0 = x0,
      y = d$x,
      dens = d$y
    ) |>
      mutate(
        dens_scaled = dens / max(dens) * width,
        x_curve = x0 + dens_scaled
      )
  }

  dens_df <- map_dfr(x_knots, make_conditional_density, n = n_cond, sigma = sigma, width = dens_width)

  points_df <- tibble(
    x = x_knots,
    y = yhat_fun(x_knots),
    y_label = paste0("hat(Y)*'|'*X[", seq_along(x_knots), "]")
  )

  line_df <- tibble(
    x = seq(min(x_knots) - 1.0, max(x_knots) + 1.0, length.out = 200),
    y = yhat_fun(x)
  )

  scatter_df <- tibble(
    x = runif(1600, min(x_knots) - 0.3, max(x_knots) + 0.3),
    y = yhat_fun(x) + rnorm(1600, sd = sigma)
  )

  p <- ggplot() +
    geom_line(
      data = line_df,
      aes(x, y),
      linetype = "dashed",
      linewidth = 0.7,
      color = "black"
    )

  # Nur Datenpunkte = klassischer Scatterplot
  if (display_mode %in% c("points", "both")) {
    p <- p +
      geom_point(
        data = scatter_df,
        aes(x, y),
        color = "#1f2fbf",
        alpha = 0.35,
        size = 1.0
      )
  }

  # Verteilungen + konditionale Mittelwerte nur für densities/both
  if (display_mode %in% c("densities", "both")) {
    p <- p +
      geom_path(
        data = dens_df,
        aes(x = x_curve, y = y, group = x0),
        color = "#2B8CBE",
        linewidth = 0.8,
        alpha = 0.95
      ) +
      geom_point(
        data = points_df,
        aes(x, y),
        color = "#C0003B",
        size = 2.4
      ) +
      geom_text(
        data = points_df,
        aes(x = x + 0.08, y = y - 0.18, label = y_label),
        parse = TRUE,
        hjust = 0,
        vjust = 0.5,
        family = "serif",
        size = 5
      )
  }

  p +
    scale_x_continuous(
      breaks = x_knots,
      labels = parse(text = paste0("X[", seq_along(x_knots), "]")),
      expand = expansion(mult = c(0.05, 0.08))
    ) +
    labs(x = "X", y = "Y") +
    coord_cartesian(clip = "off") +
    theme_minimal(base_family = "serif", base_size = 13) +
    theme(
      panel.grid = element_blank(),
      axis.line = element_line(color = "black", linewidth = 0.7),
      axis.ticks = element_line(color = "black", linewidth = 0.7),
      axis.ticks.length = unit(0.22, "cm"),
      axis.title = element_text(size = 14),
      axis.text = element_text(size = 12),
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA)
    )
}
