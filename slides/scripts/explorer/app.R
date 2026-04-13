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
conflicts_prefer(dplyr::filter)

# -------------------------
# apply value labels ONLY when present in the parsed labels_map (file)
# -------------------------

raw_df <- haven::read_dta(here("slides", "scripts", "explorer", "allbus.dta"))

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

# 3. Value labels (allbus-labels.txt) parsen und anwenden (hier()-Pfad)
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

# 4. Variable‑Labels (allbus-varlabels.txt) parsen (hier()-Pfad)
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

# 5. Erzeuge allbus (metrisch numeric, übrige als factor) und wende value labels an
allbus <- raw_df %>%
  mutate(across(all_of(metrisch_present), ~ to_numeric_safe(.x)))

# apply value labels only for labels present in labels_map and only for codes actually present;
# drop negative codes (typische Missing-Codes) so missings bleiben NA
for (v in intersect(names(labels_map), names(allbus))) {
  lbls_num <- labels_map[[v]]                # named numeric: names = label text, values = codes
  if (length(lbls_num) == 0) next
  vec <- allbus[[v]]

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
    allbus[[v]] <- labelled(as.numeric(vec), labels = labs_filtered)
  } else if (is.factor(vec) || is.character(vec)) {
    vec_num <- suppressWarnings(as.numeric(as.character(vec)))
    if (!all(is.na(vec_num))) allbus[[v]] <- labelled(vec_num, labels = labs_filtered)
    # sonst: freie Texte -> leave as-is
  }
}

# convert remaining non-metric vars to factor (preserve labelled -> as_factor)
for (v in setdiff(names(allbus), metrisch_present)) {
  if (!is.numeric(allbus[[v]])) {
    if (inherits(allbus[[v]], "labelled")) allbus[[v]] <- as_factor(allbus[[v]])
    else allbus[[v]] <- as.factor(allbus[[v]])
  }
}

# apply variable labels (attr 'label')
for (v in intersect(names(var_labels), names(allbus))) {
  attr(allbus[[v]], "label") <- var_labels[[v]]
}

# helper for UI choices
not_numeric_names <- names(allbus)[!vapply(allbus, is.numeric, logical(1))]

# erzeugt named-choice-Vektor: names = Variable-Label (oder Name), values = Variablenname
var_names <- names(allbus)
get_display_label <- function(v) {
  # zuerst aus var_labels (falls geparst), sonst aus attr 'label', sonst der Variablenname
  lbl1 <- if (!is.null(var_labels[v]) && nzchar(var_labels[v])) var_labels[v]
  lbl2 <- if (is.null(lbl1) || !nzchar(lbl1)) {
    al <- attr(allbus[[v]], "label")
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
  al <- attr(allbus[[v]], "label")
  if (!is.null(al) && nzchar(as.character(al))) return(as.character(al))
  v
}


# -------------------------
# 6. Shiny UI
# -------------------------
# R
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
                    min = 1, max = nrow(allbus),
                    value = min(1000, nrow(allbus)),
                    step = max(1, floor(nrow(allbus)/50))),
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
                    choices = c("Scatterplot" = "scatter", "Gruppierte Balkendiagramme" = "group_bar"),
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
    if (is.null(input$sampleType) || input$sampleType == "all") return(allbus)
    # random sample
    n <- req(input$sampleSize)
    set.seed(seed_rv())
    allbus[sample(nrow(allbus), size = min(n, nrow(allbus))), , drop = FALSE]
  })



  plot_type <- reactive({
    if (input$analysis_type == "univar") return(-1)
    req(input$x, input$y)
    if (input$y == "None") return(-1)
    is.numeric(allbus[[input$x]]) + is.numeric(allbus[[input$y]])
  })

  output$plot <- renderPlot({
    p <- NULL

    if (plot_type() == 2) {
      # both numeric: scatter
      req(input$x, input$y)

p <- ggplot(sampled_df(), aes(x = .data[[input$x]], y = .data[[input$y]]))
if (isTRUE(input$jitter)) p <- p + geom_jitter(alpha = 0.6)
else p <- p + geom_point(alpha = 0.6)
if (isTRUE(input$smooth)) p <- p + geom_smooth(se = TRUE)
p <- p + labs(x = get_var_label(input$x), y = get_var_label(input$y))

    } else if (plot_type() == 1) {
      # one numeric, one categorical -> boxplot
      req(input$x, input$y)
      if (is.numeric(allbus[[input$x]])) {
        num <- input$x; catv <- input$y
      } else {
        num <- input$y; catv <- input$x
      }
p <- ggplot(sampled_df(), aes(x = .data[[catv]], y = .data[[num]])) +
  geom_boxplot(na.rm = TRUE)
p <- p + labs(x = get_var_label(catv), y = get_var_label(num))

    } else if (plot_type() == 0) {
      # two categorical -> heatmap of counts
      req(input$x, input$y)
      temp <- sampled_df() %>% count(.data[[input$x]], .data[[input$y]], name = "n")
      p <- ggplot(temp, aes(x = .data[[input$x]], y = .data[[input$y]], fill = n)) +
        geom_tile() +
        scale_fill_gradient(low = "#e7e7fd", high = "#1111dd") +
        labs(x = get_var_label(input$x), y = get_var_label(input$y), fill = "Count")

    } else {
      # univariate branch
      var <- if (input$analysis_type == "univar") input$y_uni else input$x
      req(var)
      utype <- input$univar_type
      if (is.null(utype)) utype <- "auto"
      if (utype == "auto" && is.numeric(allbus[[var]])) utype <- "dens"
      if (utype == "auto" && !is.numeric(allbus[[var]])) utype <- "bar"

      title_text <- get_var_label(var)

      if (utype == "dens") {
        validate(need(is.numeric(allbus[[var]]), "Kerndichte benötigt eine metrische Variable."))
        p <- ggplot(sampled_df(), aes(x = .data[[var]])) +
          geom_density(fill = "#2c7fb8", alpha = 0.5, na.rm = TRUE) +
          labs(x = get_var_label(var), y = "Dichte", title = title_text)

      } else if (utype == "bar") {
        # construct bars based on underlying numeric codes, keep labels but disambiguate duplicates
        df <- sampled_df()
        if (isFALSE(input$show_missings)) df <- df %>% filter(!is.na(.data[[var]]))

        temp <- df %>%
          mutate(.code = as.character(.data[[var]]),
                 .label = as.character(haven::as_factor(.data[[var]]))) %>%
          count(.code, .label, name = "n") %>%
          mutate(code_num = suppressWarnings(as.numeric(.code))) %>%
          arrange(code_num)

        # make display label unique if labels duplicate
        temp <- temp %>%
          group_by(.label) %>%
          mutate(display = ifelse(n() > 1, paste0(.label, " (", .code, ")"), .label)) %>%
          ungroup() %>%
          mutate(prop = n / sum(n),
                 display = forcats::fct_inorder(display))

        p <- ggplot(temp, aes(x = display, y = prop)) +
          geom_col(fill = "#4daf4a", alpha = 0.85) +
          geom_text(aes(label = scales::percent(prop, accuracy = 0.1)),
                    vjust = -0.25, size = 3) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) +
          labs(x = title_text, y = "Relative Häufigkeit", title = paste("Relative Häufigkeiten von", title_text)) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }

    if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  }, height = 600)

  # grouped bivar plotting (proportions within X), respects show_missings_bivar
  observe({
    req(input$x, input$y)
    if (input$analysis_type == "bivar" && input$bivar_type == "group_bar") {
      x_label <- get_var_label(input$x)
      y_label <- get_var_label(input$y)

      df <- sampled_df()
      if (isFALSE(input$show_missings_bivar)) df <- df %>% filter(!is.na(.data[[input$x]]), !is.na(.data[[input$y]]))

      temp <- df %>%
        mutate(.x_code = as.character(.data[[input$x]]),
               .y_code = as.character(.data[[input$y]]),
               .x_lab = as.character(haven::as_factor(.data[[input$x]])),
               .y_lab = as.character(haven::as_factor(.data[[input$y]]))) %>%
        count(.x_code, .x_lab, .y_code, .y_lab, name = "n") %>%
        group_by(.x_code, .x_lab) %>%
        mutate(prop_within = n / sum(n)) %>%
        ungroup() %>%
        group_by(.x_code) %>%
        mutate(total_n = sum(n)) %>%
        ungroup() %>%
        arrange(as.numeric(.x_code)) %>%
        mutate(.x_disp = ifelse(duplicated(.x_lab) | duplicated(.x_lab, fromLast = TRUE), paste0(.x_lab, " (", .x_code, ")"), .x_lab),
               .y_disp = ifelse(duplicated(.y_lab) | duplicated(.y_lab, fromLast = TRUE), paste0(.y_lab, " (", .y_code, ")"), .y_lab),
               .x_disp = forcats::fct_inorder(.x_disp))

      p <- ggplot(temp, aes(x = .x_disp, y = prop_within, fill = .y_disp)) +
        geom_col(position = position_dodge(width = 0.9), width = 0.8, alpha = 0.9) +
        geom_text(aes(label = scales::percent(prop_within, accuracy = 0.1)),
                  position = position_dodge(width = 0.9), vjust = -0.25, size = 3) +
        scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) +
        labs(x = x_label, y = "Relative Häufigkeit (innerhalb X)", fill = y_label,
             title = paste(y_label, "nach", x_label)) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))

      output$plot <- renderPlot({
        if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
      }, height = 600)
    }
  })

}

# -------------------------
# 8. App starten
shinyApp(ui = ui, server = server)
