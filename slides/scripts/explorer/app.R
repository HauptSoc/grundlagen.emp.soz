
# r
# Own the Libs
library(shiny)
library(dplyr)
library(ggplot2)
library(haven)
library(labelled)
library(scales)
library(rlang)
library(stringr)
library(conflicted)
library(ggridges)
library(summarytools)
library(here)
library(viridis)

conflicts_prefer(dplyr::filter)


## Ein ppar makros und funktionen für die Schönheit
.base_size <- 16            # base text size (ca. 2x default)

# diskrete, farbenblinde Palette für fills und colours
scale_fill_cb <- function(...) {
  viridis::scale_fill_viridis(..., discrete = TRUE, option = "D", begin = 0.15, end = 0.95)
}
scale_color_cb <- function(...) {
  viridis::scale_colour_viridis(..., discrete = TRUE, option = "D", begin = 0.15, end = 0.95)
}
scale_colour_cb <- scale_color_cb  # Alias, falls code 'colour' verwendet

apply_cb_palette <- function(p) {
  p + scale_fill_cb() + scale_color_cb()
}

# -------------------------
# apply value labels ONLY when present in the parsed labels_map (file)
# -------------------------

load("explore.Rdata")

# 1) Welche Variablen als "metrisch" behandeln
metrisch_present <- names(raw_df)   # oder: names(raw_df)[vapply(raw_df, is.numeric, logical(1))]

# 2) Sichere Numeric-Konversion (für labelled / factor / char)
to_numeric_safe <- function(x) {
  if (inherits(x, "labelled") || inherits(x, "haven_labelled")) return(as.numeric(x))
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  suppressWarnings(as.numeric(x))
}

# 3) Tagged / special missings und NaN zu konsistenten NA normalisieren
normalize_missings <- function(df) {
  for (nm in names(df)) {
    x <- df[[nm]]
    if (inherits(x, "labelled") || inherits(x, "haven_labelled")) {
      nums <- suppressWarnings(as.numeric(x))
      nums[is.nan(nums)] <- NA_real_
      df[[nm]] <- nums
    } else if (is.numeric(x)) {
      x[is.nan(x)] <- NA_real_
      df[[nm]] <- x
    }
  }
  df
}
raw_df <- normalize_missings(raw_df)

# optional: falls du bereits make_negatives_missing hast, rufe es danach auf
# raw_df <- make_negatives_missing(raw_df) 

# -------------------------
# 3. Value labels (allbus-labels.txt) parsen und anwenden (hier()-Pfad)
#    Erwartetes Format (Abschnitte): VARNAME:  <newline> CODE <whitespace> LABEL
# -------------------------
val_lab_candidates <- c(
  here("slides", "scripts", "explorer", "allbus-labels.txt"),
  here("explorer", "allbus-labels.txt"),
  here("data", "allbus-labels.txt"),
  here("allbus-labels.txt")
)
labels_map <- list()
lbl_path <- val_lab_candidates[file.exists(val_lab_candidates)][1]
if (!is.na(lbl_path) && nzchar(lbl_path)) {
  lines <- readLines(lbl_path, warn = FALSE)
  cur <- NULL
  for (ln in lines) {
    ln_trim <- str_trim(ln)
    if (ln_trim == "") next
    # Abschnittsheader: VARNAME:
    if (grepl("^[A-Za-z0-9_]+:$", ln_trim)) {
      cur <- sub(":$", "", ln_trim)
      labels_map[[cur]] <- numeric()   # numeric vector, names = label text
      next
    }
    if (is.null(cur)) next
    # Code + Label (nur numerische Codes)
    m <- str_match(ln_trim, "^([\\-]?[0-9]+)\\s+(.*\\S)\\s*$")
    if (!is.na(m[1,1])) {
      code <- as.numeric(m[1,2])
      lbl  <- m[1,3]
      # store as named numeric: value = code, name = label text
      labels_map[[cur]][lbl] <- code
    }
  }
}

# -------------------------
# 4. Variable‑Labels (allbus-varlabels.txt) parsen (hier()-Pfad)
#    Erwartetes Format: VARNAME <whitespace> LABELTEXT
# -------------------------
varlabel_candidates <- c(
  here("slides", "scripts", "explorer", "allbus-varlabels.txt"),
  here("explorer", "allbus-varlabels.txt"),
  here("data", "allbus-varlabels.txt"),
  here("allbus-varlabels.txt")
)
var_labels <- character()
lbl_path2 <- varlabel_candidates[file.exists(varlabel_candidates)][1]
if (!is.na(lbl_path2) && nzchar(lbl_path2)) {
  lns <- readLines(lbl_path2, warn = FALSE)
  for (ln in lns) {
    ln2 <- str_trim(ln)
    if (ln2 == "") next
    parts <- regmatches(ln2, regexec("^([A-Za-z0-9_]+)\\s+(.*\\S)\\s*$", ln2))[[1]]
    if (length(parts) == 3) var_labels[parts[2]] <- parts[3]
  }
}

# -------------------------
# 5. Arbeite weiter mit raw_df: metrisch numeric, übrige als factor (labelled->as_factor),
#    wende value labels und variable labels an
# -------------------------
raw_df <- raw_df %>%
  mutate(across(all_of(metrisch_present), ~ to_numeric_safe(.x)))

# apply value labels only for labels present in labels_map and only for codes actually present;
# drop negative codes (typische Missing-Codes) so missings bleiben NA
for (v in intersect(names(labels_map), names(raw_df))) {
  lbls_num <- labels_map[[v]]                # named numeric: names = label text, values = codes
  if (length(lbls_num) == 0) next
  vec <- raw_df[[v]]

  # try to get numeric codes present in data (after prior normalization)
  vec_nums <- suppressWarnings(as.numeric(vec))
  present_codes <- unique(na.omit(vec_nums))

  # keep only label entries whose code is present and non-negative
  keep_idx <- as.numeric(lbls_num) %in% present_codes & as.numeric(lbls_num) >= 0
  if (!any(keep_idx)) next
  labs_filtered <- lbls_num[keep_idx]

  # labelled() expects a numeric vector with names = labels and values = codes
  # ensure correct type and apply
  if (inherits(vec, "labelled") || is.numeric(vec)) {
    raw_df[[v]] <- labelled(as.numeric(vec), labels = labs_filtered)
  } else if (is.factor(vec) || is.character(vec)) {
    vec_num <- suppressWarnings(as.numeric(as.character(vec)))
    if (!all(is.na(vec_num))) raw_df[[v]] <- labelled(vec_num, labels = labs_filtered)
    # sonst: freie Texte -> leave as-is
  }
}

# convert remaining non-metric vars to factor (preserve labelled -> as_factor)
for (v in setdiff(names(raw_df), metrisch_present)) {
  if (!is.numeric(raw_df[[v]])) {
    if (inherits(raw_df[[v]], "labelled")) raw_df[[v]] <- as_factor(raw_df[[v]])
    else raw_df[[v]] <- as.factor(raw_df[[v]])
  }
}

# apply variable labels (attr 'label')
for (v in intersect(names(var_labels), names(raw_df))) {
  attr(raw_df[[v]], "label") <- var_labels[[v]]
}

# helper for UI choices
not_numeric_names <- names(raw_df)[!vapply(raw_df, is.numeric, logical(1))]

# erzeugt named-choice-Vektor: names = Variable-Label (oder Name), values = Variablenname
var_names <- names(raw_df)
get_display_label <- function(v) {
  # zuerst aus var_labels (falls geparst), sonst aus attr 'label', sonst der Variablenname
  lbl1 <- if (!is.null(var_labels[v]) && nzchar(var_labels[v])) var_labels[v]
  lbl2 <- if (is.null(lbl1) || !nzchar(lbl1)) {
    al <- attr(raw_df[[v]], "label")
    if (!is.null(al) && nzchar(as.character(al))) as.character(al) else v
  } else lbl1
  as.character(lbl2)
}
display_labels <- vapply(var_names, get_display_label, FUN.VALUE = character(1), USE.NAMES = FALSE)
# Replace NA or empty labels with the variable name to avoid NA names in inputs
missing_label_idx <- which(is.na(display_labels) | display_labels == "")
if (length(missing_label_idx) > 0) {
  display_labels[missing_label_idx] <- var_names[missing_label_idx]
}
choices_named <- setNames(var_names, display_labels)

# für Y mit "None"-Option
choices_y <- c("None" = "None", choices_named)

if (!exists("var_labels")) var_labels <- character()

# liefert lesbares Variable‑Label (falls vorhanden), sonst Variablenname
get_var_label <- function(v) {
  if (!is.null(var_labels) && v %in% names(var_labels) && nzchar(var_labels[[v]])) {
    return(as.character(var_labels[[v]]))
  }
  al <- attr(raw_df[[v]], "label")
  if (!is.null(al) && nzchar(as.character(al))) return(as.character(al))
  v
}

# -------------------------
# 6. Shiny UI
# -------------------------
ui <- fluidPage(
  titlePanel("Allbus Explorer"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("sampleType", "Plot sample type",
                   choices = list("random n" = "random", "all n" = "all"),
                   selected = "all"),
      conditionalPanel(
        condition = "input.sampleType == 'random'",
        sliderInput("sampleSize", "Plot sample size (n)",
                    min = 1, max = nrow(raw_df),
                    value = min(1000, nrow(raw_df)),
                    step = max(1, floor(nrow(raw_df)/50))),
        actionButton("drawAgain", "draw again")
      ),
      radioButtons("analysis_type", "Analyse-Typ",
                   choices = c("Univariat" = "univar", "Bivariat" = "bivar"),
                   selected = "univar"),
      conditionalPanel(
        condition = "input.analysis_type == 'univar'",
        selectInput("y_uni", "Merkmal", choices = choices_y, selected = "None"),
        selectInput("univar_type", "Univariate Darstellung",
                    choices = c("Kerndichte" = "dens", "Balken (relative)" = "bar"),
                    selected = "bar"),
        checkboxInput("show_missings", "Show missings", value = FALSE)
      ),
      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("y", "Outcome", choices = choices_y, selected = "None"),
        selectInput("x", "Beinflussendes Merkmal", choices = choices_y, selected = "None"),
        selectInput("bivar_type", "Bivariate Darstellung",
                    choices = c("Scatterplot" = "scatter",
                                "Gruppierte Balkendiagramme" = "group_bar",
                                "Boxplots" = "box",
                                "Kerndichte über Gruppen" = "ridgeline"),
                    selected = "scatter"),
        conditionalPanel(condition = "input.bivar_type == 'scatter'",
                         checkboxInput("jitter", "Jitter", value = FALSE),
                         checkboxInput("smooth", "Smooth", value = FALSE)
        ),
        conditionalPanel(
          condition = "input.bivar_type == 'group_bar'",
          checkboxInput("show_missings_bivar", "Show missings", value = FALSE)
        )
      )
    ),
    mainPanel(
tabsetPanel(type = "tabs",
                  tabPanel("Plot", plotOutput("plot", height = "600px")),
                  tabPanel("Summary", htmlOutput("summary")),
                  tabPanel("Data Snippet", verbatimTextOutput("snippet"))
    )
  )
)
)

# -------------------------
# 7. Shiny Server
# -------------------------
server <- function(input, output, session) {

# Deskriptive Tabelle 

output$summary <- renderUI(
  print(dfSummary(raw_df, 
                varnumbers   = FALSE,
                valid.col    = FALSE,
                graph.magnif = 0.75, 
                style = "grid", 
                na.col = TRUE, 
               plain.ascii = FALSE), 
      max.tbl.height = 800,
      method = "render", 
      headings = FALSE,
      bootstrap.css = FALSE)
)
  
output$snippet <- renderPrint({
  vars <- switch(input$analysis_type,
                 "univar" = input$y_uni,
                 "bivar"  = c(input$x,
                              if (!is.null(input$y) && input$y != "None") input$y else NULL))
  vars <- unique(Filter(function(v) !is.null(v) && v != "None" && v %in% names(sampled_df()), vars))
  if (length(vars) == 0) head(sampled_df(), 15) else head(sampled_df()[, vars, drop = FALSE], 15)
})

  # reactive seed that changes when drawAgain is clicked
  seed_rv <- reactiveVal(sample.int(.Machine$integer.max, 1))
  observeEvent(input$drawAgain, {
    seed_rv(sample.int(.Machine$integer.max, 1))
  })

  sampled_df <- reactive({
    if (is.null(input$sampleType) || input$sampleType == "all") return(raw_df)
    # random sample
    n <- req(input$sampleSize)
    set.seed(seed_rv())
    raw_df[sample(nrow(raw_df), size = min(n, nrow(raw_df))), , drop = FALSE]
  })

  # Unified plotting logic in a single renderPlot to avoid multiple assignments
  output$plot <- renderPlot({
    df <- sampled_df()

    if (is.null(input$analysis_type) || input$analysis_type == "univar") {
      var <- req(input$y_uni)
      if (is.null(var) || var == "None") return(ggplot() + theme_void())
      utype <- input$univar_type
      if (is.null(utype)) utype <- ifelse(is.numeric(raw_df[[var]]), "dens", "bar")

      title_text <- get_var_label(var)

      if (utype == "dens") {
        validate(need(is.numeric(raw_df[[var]]), "Kerndichte benötigt eine metrische Variable."))
        p <- ggplot(df, aes(x = .data[[var]])) +
          geom_density(fill = "#2c7fb8", alpha = 0.5, na.rm = TRUE) +
          labs(x = get_var_label(var), y = "Dichte", title = title_text)

      } else {
        # bar
        if (isFALSE(input$show_missings)) df <- df %>% filter(!is.na(.data[[var]]))

        temp <- df %>%
          mutate(.code = as.character(.data[[var]]),
                 .label = as.character(haven::as_factor(.data[[var]]))) %>%
          count(.code, .label, name = "n") %>%
          mutate(code_num = suppressWarnings(as.numeric(.code))) %>%
          arrange(code_num)

        temp <- temp %>%
          group_by(.label) %>%
          mutate(display = ifelse(n() > 1, paste0(.label, " (", .code, ")"), .label)) %>%
          ungroup() %>%
          mutate(prop = n / sum(n),
                 display = forcats::fct_inorder(display))

        p <- ggplot(temp, aes(x = display, y = prop)) +
          geom_col(fill = "#2c7fb8", alpha = 0.85, width = 0.4) +
          geom_text(aes(label = scales::percent(prop, accuracy = 0.1)),
                    vjust = -0.25, size = 3) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                             expand = expansion(mult = c(0, 0.08))) +
          labs(x = title_text, y = "Relative Häufigkeit",
               title = paste("Relative Häufigkeiten von", title_text)) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }

    } else {
      # Bivariate
      # require valid selections
      if (is.null(input$x) || input$x == "None" || is.null(input$y) || input$y == "None") return(ggplot() + theme_void())
      # optional: remove missings
      if (isFALSE(input$show_missings_bivar)) {
        df <- df %>% filter(!is.na(.data[[input$x]]) & !is.na(.data[[input$y]]))
      }

      bivar_type <- input$bivar_type %||% "scatter"

      x_label <- get_var_label(input$x)
      y_label <- get_var_label(input$y)

      # decide numeric/categorical
      x_is_num <- is.numeric(raw_df[[input$x]])
      y_is_num <- is.numeric(raw_df[[input$y]])

      if (bivar_type == "scatter") {
        # fallback to scatter when both numeric
        if (!(x_is_num && y_is_num)) {
          # try to coerce and still plot using numeric coercion
        }
        p <- ggplot(df, aes(x = .data[[input$x]], y = .data[[input$y]]))
        if (isTRUE(input$jitter)) p <- p + geom_jitter(alpha = 0.6)
        else p <- p + geom_point(alpha = 0.6)
        if (isTRUE(input$smooth)) p <- p + geom_smooth(se = TRUE)
        p <- p + labs(x = x_label, y = y_label)

      } else if (bivar_type == "group_bar") {
        # two categorical expected: compute proportions of Y within each X
        temp <- df %>%
          mutate(.X = forcats::as_factor(.data[[input$x]]),
                 .Y = forcats::as_factor(.data[[input$y]])) %>%
          count(.X, .Y, name = "n") %>%
          group_by(.X) %>%
          mutate(prop_within = n / sum(n)) %>%
          ungroup() %>%
          mutate(label_pct = scales::percent(prop_within, accuracy = 0.1))

        if (nrow(temp) == 0) return(ggplot() + annotate("text", x = 1, y = 1, label = "Keine Daten für die Auswahl") + theme_void())

        dodge <- position_dodge(width = 0.9)
        p <- ggplot(temp, aes(x = .X, y = prop_within, fill = .Y)) +
          geom_col(position = dodge, width = 0.7, alpha = 0.9) +
          geom_text(aes(label = label_pct), position = dodge, vjust = -0.25, size = 3) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 0.1),
                             expand = expansion(mult = c(0, 0.08))) +
          scale_fill_cb() +
          labs(x = x_label, y = "Relative Häufigkeit (innerhalb X)", fill = y_label,
               title = paste(y_label, "nach", x_label)) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))

      } else if (bivar_type == "box") {
        # Boxplots: Y must be numeric; X grouping variable
        # If user supplied numeric as x and categorical as y, swap
        if (x_is_num && !y_is_num) {
          num_var <- input$x; cat_var <- input$y
        } else {
          num_var <- input$y; cat_var <- input$x
        }
        # try numeric conversion if needed
        df2 <- df %>% mutate(.Ynum = to_numeric_safe(.data[[num_var]]), .Xfact = forcats::as_factor(.data[[cat_var]]))
        validate(need(!all(is.na(df2$.Ynum)), paste("Variable", get_var_label(num_var), "ist nicht numerisch oder enthält keine Werte")))

        p <- ggplot(df2, aes(x = .Xfact, y = .Ynum, fill = .Xfact)) +
          geom_boxplot(alpha = 0.9, width = 0.7, outlier.size = 1, na.rm = TRUE) +
          scale_fill_cb() +
          labs(x = get_var_label(cat_var), y = get_var_label(num_var), fill = get_var_label(cat_var),
               title = paste("Boxplot von", get_var_label(num_var), "nach", get_var_label(cat_var))) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))

      } else if (bivar_type == "ridgeline") {
        # Ridgeline: kernel densities of Y per X
        df2 <- df %>% mutate(.Ynum = to_numeric_safe(.data[[input$y]]), .Xfact = forcats::as_factor(.data[[input$x]]))
        validate(need(!all(is.na(df2$.Ynum)), paste("Variable", get_var_label(input$y), "ist nicht numerisch oder enthält keine Werte")))
        df2 <- df2 %>% mutate(.Xfact = forcats::fct_rev(.Xfact))

        p <- ggplot(df2, aes(x = .Ynum, y = .Xfact, fill = .Xfact)) +
          ggridges::geom_density_ridges(scale = 1.0, rel_min_height = 0.01, alpha = 0.85, size = 0.25, color = "grey30", na.rm = TRUE) +
          scale_fill_cb() +
          labs(x = get_var_label(input$y), y = get_var_label(input$x), fill = get_var_label(input$x),
               title = paste("Kerndichte von", get_var_label(input$y), "nach", get_var_label(input$x))) +
          theme(axis.text.y = element_text(size = rel(0.9)))

      } else {
        # fallback: heatmap for two categoricals
        temp <- df %>% count(.data[[input$x]], .data[[input$y]], name = "n")
        p <- ggplot(temp, aes(x = .data[[input$x]], y = .data[[input$y]], fill = n)) +
          geom_tile() +
          scale_fill_gradient(low = "#e7e7fd", high = "#1111dd") +
          labs(x = x_label, y = y_label, fill = "Count")
      }
    }

    if (!exists("p") || is.null(p)) return(ggplot() + theme_void())
    p + theme_bw(base_size = .base_size) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"),
            axis.title = element_text(size = .base_size * 1.1))

  }, height = 600)

}

# -------------------------
# 8. App starten
shinyApp(ui = ui, server = server)
