library(dplyr)
library(ggplot2)
library(patchwork)

make_plot_with_ann <- function(data, xvar, yvar, xlab, ylab, jitter_x = FALSE, binary_x = FALSE) {
  df <- data |>
    select(x = all_of(xvar), y = all_of(yvar)) |>
    filter(!is.na(x), !is.na(y))

  fit <- lm(y ~ x, data = df)
  b0 <- coef(fit)[1]
  b1 <- coef(fit)[2]

  x0 <- 0
  xmax <- max(df$x, na.rm = TRUE)

  y0 <- b0 + b1 * x0
  ymax <- b0 + b1 * xmax

  xmid <- (x0 + xmax) / 2
  ymid <- b0 + b1 * xmid

  p <- ggplot(df, aes(x = x, y = y)) +
    {if (jitter_x) geom_jitter(width = 0.08, height = 0, alpha = 0.8) else geom_point(alpha = 0.8)} +
    geom_smooth(method = "lm", se = FALSE) +
    annotate("point", x = x0, y = y0, size = 2.5) +
    annotate("text", x = x0, y = y0, label = paste0(round(y0, 2)),
             hjust = -0.1, vjust = -0.8, size = 5) +
    annotate("point", x = xmax, y = ymax, size = 2.5) +
    annotate("text", x = xmax, y = ymax, label = paste0(round(ymax, 2)),
             hjust = 1.1, vjust = -0.8, size = 5) +
    annotate("text", x = xmid, y = ymid, label = paste0(round(b1, 2)),
             vjust = -1.0, size = 5.5, fontface = "bold") +
    labs(x = xlab, y = ylab) +
    theme_minimal() +
    theme(
      text = element_text(size = 20),
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 14)
    )

  if (binary_x) {
    p <- p + scale_x_continuous(
      breaks = c(0, 1),
      labels = c("0", "1"),
      limits = c(-0.2, 1.2)
    )
  }

  p
}

p1 <- make_plot_with_ann(
  tab_data, "sex1i3", "rtr51",
  xlab = "Alter erster GV - 17",
  ylab = "Anzahl bisheriger Beziehungen",
  jitter_x = FALSE,
  binary_x = FALSE
)

p2 <- make_plot_with_ann(
  tab_data, "sex_c_num", "rtr51",
  xlab = "Geschlecht (0 = Frauen, 1 = Männer)",
  ylab = "Anzahl bisheriger Beziehungen",
  jitter_x = TRUE,
  binary_x = TRUE
)

p3 <- make_plot_with_ann(
  tab_data, "sex_c_num", "sex1i3",
  xlab = "Geschlecht (0 = Frauen, 1 = Männer)",
  ylab = "Alter erster GV - 17",
  jitter_x = TRUE,
  binary_x = TRUE
)

panel <- p1 + p2 + p3 + plot_layout(ncol = 3)
panel