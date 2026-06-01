library(tidyverse)
library(patchwork)

set.seed(123)

n <- 1200

make_linear_noisy <- function(target_r, n = 1200) {
  x <- rnorm(n)
  if (abs(target_r) == 1) {
    y <- target_r * x
  } else {
    y <- target_r * x + sqrt(1 - target_r^2) * rnorm(n)
  }
  tibble(x = x, y = y)
}

make_affine <- function(slope, intercept = 0, n = 1200, noise_sd = 0) {
  x <- seq(-2, 2, length.out = n)
  y <- intercept + slope * x + rnorm(n, sd = noise_sd)
  tibble(x = x, y = y)
}

make_poly_rdd <- function(degree, jump = 0.8, n = 1200, noise_sd = 0.15) {
  x <- runif(n, -2, 2)
  poly_mat <- poly(x, degree, raw = TRUE)
  coeffs <- rnorm(ncol(poly_mat))  # Korrekte Anzahl Koeffizienten
  y <- c(poly_mat %*% coeffs)
  y <- y + if_else(x >= 0, jump, 0) + rnorm(n, sd = noise_sd)
  tibble(x = x, y = y)
}

# Row 1: Linear mit verschiedenen r
row1_targets <- c(1, 0.8, 0.4, 0, -0.4, -0.8, -1)
row1 <- map_dfr(seq_along(row1_targets), \(i) {
  make_linear_noisy(row1_targets[i], n) |>
    mutate(row = 1, col = i)
})

# Row 2: Perfekte positive Korrelationen mit unterschiedlichen Steigungen + r = 0 in Spalte 4
row2_col1 <- make_affine(slope = 0.4, intercept = -0.2, n = n, noise_sd = 0) |>
  mutate(row = 2, col = 1)

row2_col4 <- make_linear_noisy(0, n) |>
  mutate(row = 2, col = 4)

row2_specs <- tribble(
  ~col, ~slope, ~intercept, ~noise_sd,
  2,  2.0,  0.8, 0,
  3,  1.0, -0.6, 0,
  5, -0.4,  0.2, 0,
  6, -1.0, -0.6, 0,
  7, -2.0,  0.8, 0
)

row2_rest <- pmap_dfr(row2_specs, \(col, slope, intercept, noise_sd) {
  make_affine(slope, intercept, n, noise_sd) |>
    mutate(row = 2, col = col)
})

row2 <- bind_rows(row2_col1, row2_rest, row2_col4)

# Row 3: Gewünschte Funktionen und Diskontinuitäten
row3 <- map_dfr(1:7, \(i) {
  df <- switch(
    as.character(i),
    `1` = {
      x <- seq(-2, 2, length.out = n)
      tibble(x = x, y = 1 + x^2 + rnorm(n, sd = 0.15))
    },
    `2` = {
      x <- seq(-2, 2, length.out = n)
      tibble(x = x, y = 1 - x^2 + rnorm(n, sd = 0.15))
    },
    `3` = {
      x <- seq(-2, 2, length.out = n)
      x <- if_else(abs(x) < 0.08, 0.08 * sign(x + 0.1), x)
      tibble(x = x, y = 1 / (x^2) + rnorm(n, sd = 0.15))
    },
    `4` = {
      x <- seq(0.05, 2, length.out = n)
      tibble(x = x, y = 1 + log(x) + rnorm(n, sd = 0.15))
    },
    `5` = {
      x <- seq(-2, 2, length.out = n)
      tibble(x = x, y = 1 + exp(x) + rnorm(n, sd = 0.15))
    },
    `6` = {
      x <- seq(-2, 2, length.out = n)
      y <- if_else(x <= 0, x + 1, 2)
      tibble(x = x, y = y + rnorm(n, sd = 0.08))
    },
    `7` = {
      x <- seq(-2, 2, length.out = n)
      y <- if_else(x <= 0, 2 - x, x^2 + x^3)
      tibble(x = x, y = y + rnorm(n, sd = 0.08))
    }
  )

  df |>
    mutate(row = 3, col = i)
})

plot_df <- bind_rows(row1, row2, row3) |>
  group_by(row, col) |>
  mutate(r = cor(x, y)) |>
  ungroup() |>
  mutate(
    panel_id = (row - 1) * 7 + col,
    panel = factor(panel_id, levels = 1:21),
    r_label = sprintf("%.2f", r)
  )

label_map <- plot_df |>
  distinct(panel, r_label) |>
  arrange(as.integer(panel)) |>
  deframe()

# Hilfsfunktion für eine Zeile
make_row_plot <- function(df, free_y = TRUE, add_vline = FALSE) {
  lbl <- df |>
    distinct(col, r_label) |>
    arrange(col) |>
    mutate(col_f = factor(col, levels = 1:7),
           lab = r_label)

  df2 <- df |>
    mutate(col_f = factor(col, levels = 1:7))

  p <- ggplot(df2, aes(x, y)) +
    geom_point(color = "#1f2fbf", size = 0.25, alpha = 0.9) +
    facet_wrap(
      ~ col_f,
      nrow = 1,
      scales = if (free_y) "free_y" else "fixed",
      labeller = as_labeller(setNames(lbl$lab, lbl$col_f))
    ) +
    theme_void(base_size = 11) +
    theme(
      strip.text = element_text(
        size = 11,        # größer
        face = "bold",    # fett
        margin = margin(b = 2)
      ),
      strip.background = element_blank(),
      panel.spacing = unit(0.4, "lines"),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )

  if (add_vline) {
    p <- p + geom_vline(
      data = df2 |> filter(col %in% c(6, 7)),
      mapping = aes(xintercept = 0),
      inherit.aes = FALSE,
      linetype = "dashed",
      color = "grey45",
      linewidth = 0.3
    )
  }

  p
}

p1 <- make_row_plot(plot_df |> filter(row == 1), free_y = TRUE)
p2 <- make_row_plot(plot_df |> filter(row == 2), free_y = FALSE)  # gemeinsame y-Achse
p3 <- make_row_plot(plot_df |> filter(row == 3), free_y = TRUE, add_vline = TRUE)

p <- p1 / p2 / p3
p