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
// ...existing code...variat" = "univar", "Bivariat" = "bivar"),
                   selected = "univar"),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("x", "X", choices = choices_named, selected = var_names[1]),
        selectInput("y", "Y", choices = choices_y, selected = "None")
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'univar'",
        selectInput("y_uni", "Variable (univariat)", choices = choices_named, selected = var_names[1])
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("color", "Color", choices = choices_color, selected = "None"),
        checkboxInput("jitter", "Jitter", value = FALSE),
        checkboxInput("smooth", "Smooth", value = FALSE)
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'univar'",
        selectInput("univar_type", "Univariate Darstellung",
                    choices = c("Auto (Kategorie/Metrisch)" = "auto", "Kern\u00addichte" = "dens", "Balken (relative)" = "bar"),
                    selected = "bar"),
        checkboxInput("show_missings", "Show missings", value = FALSE)
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("bivar_type", "Bivariate Darstellung",
                    choices = c("Scatterplot" = "scatter",
                                "Gruppierte Balkendiagramme" = "group_bar"),
                    selected = "scatter"),
        conditionalPanel(
          condition = "input.bivar_type == 'group_bar'",
          checkboxInput("show_missings_bivar", "Show missings", value = FALSE)
        )
      )
// ...existing code...
eben.")





ui <- fluidPage(
  titlePanel("Allbus Explorer"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("sampleSize", "Plot sample size (n)",
                  min = 1, max = nrow(allbus),
                  value = min(1000, nrow(allbus)),
                  step = max(1, floor(nrow(allbus)/50))),
      radioButtons("sampleType", "Plot sample type",
                   choices = list("Random n" = "random", "First n" = "first")),
      numericInput("sampleSeed", "Sample seed", value = 1, min = 1, step = 1),

      radioButtons("analysis_type", "Analyse-Typ",
                   choices = c("Bivariat" = "bivar", "Univariat" = "univar"),
                   selected = "univar"),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("x", "X", choices = choices_named, selected = var_names[1]),
        selectInput("y", "Y", choices = choices_y, selected = "None")
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'univar'",
        selectInput("y_uni", "Variable (univariat)", choices = choices_named, selected = var_names[1])
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("color", "Color", choices = choices_color, selected = "None"),
        checkboxInput("jitter", "Jitter", value = FALSE),
        checkboxInput("smooth", "Smooth", value = FALSE)
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'univar'",
        selectInput("univar_type", "Univariate Darstellung",
                    choices = c("Auto (Kategorie/Metrisch)" = "auto", "Kern­dichte" = "dens", "Balken (relative)" = "bar"),
                    selected = "auto")
      ),

      conditionalPanel(
        condition = "input.analysis_type == 'bivar'",
        selectInput("bivar_type", "Bivariate Darstellung",
                    choices = c("Scatterplot" = "scatter",
                                "Gruppierte Balkendiagramme" = "group_bar"),
                    selected = "scatter")
      )
    ),
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Plot", plotOutput("plot")),
                  tabPanel("Data Snippet", verbatimTextOutput("snippet")),
                  tabPanel("Summary", verbatimTextOutput("summary")),
                  tabPanel("str() Output", verbatimTextOutput("str"))
      )
    )
  )
)

# -------------------------
# 7. Shiny Server
# -------------------------
server <- function(input, output, session) {

  output$summary <- renderPrint(summary(allbus))
  output$str <- renderPrint(str(allbus))

  sampled_df <- reactive({
    n <- req(input$sampleSize)
    if (input$sampleType == "first") {
      allbus[seq_len(min(n, nrow(allbus))), , drop = FALSE]
    } else {
      set.seed(input$sampleSeed)
      allbus[sample(nrow(allbus), size = min(n, nrow(allbus))), , drop = FALSE]
    }
  })

  output$snippet <- renderPrint(head(sampled_df(), n = 15))

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
      if (input$jitter) p <- p + geom_jitter(alpha = 0.6)
      else p <- p + geom_point(alpha = 0.6)
      if (input$smooth) p <- p + geom_smooth(se = TRUE)
      if (!is.null(input$color) && input$color != "None") p <- p + aes(color = .data[[input$color]])
      p <- p + labs(x = input$x, y = input$y)

    } else if (plot_type() == 1) {
      # one numeric, one categorical -> boxplot
      req(input$x, input$y)
      if (is.numeric(allbus[[input$x]])) {
        num <- input$x; catv <- input$y
      } else {
        num <- input$y; catv <- input$x
      }
      p <- ggplot(sampled_df(), aes(x = .data[[catv]], y = .data[[num]])) + geom_boxplot()
      if (!is.null(input$color) && input$color != "None") p <- p + aes(fill = .data[[input$color]])
      p <- p + labs(x = catv, y = num)

    } else if (plot_type() == 0) {
      # two categorical -> heatmap of counts
      req(input$x, input$y)
      temp <- sampled_df() %>% count(.data[[input$x]], .data[[input$y]], name = "n")
      p <- ggplot(temp, aes(x = .data[[input$x]], y = .data[[input$y]], fill = n)) +
        geom_tile() +
        scale_fill_gradient(low = "#e7e7fd", high = "#1111dd") +
        labs(x = input$x, y = input$y, fill = "Count")

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
          labs(x = var, y = "Dichte", title = title_text)
      } else if (utype == "bar") {
        # sichere Erzeugung der x-Achse als Beschriftungstext: as_factor() liefert Wertelabels für labelled/factor
        temp <- sampled_df() %>%
          mutate(.xlab = as.character(haven::as_factor(.data[[var]]))) %>%
          count(.xlab, name = "n") %>%
          mutate(prop = n / sum(n)) %>%
          arrange(desc(prop)) %>%
          mutate(.xlab = forcats::fct_reorder(.xlab, prop, .desc = TRUE))

        p <- ggplot(temp, aes(x = .xlab, y = prop)) +
          geom_col(fill = "#4daf4a", alpha = 0.85) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
          labs(x = title_text, y = "Relative Häufigkeit",
               title = paste("Relative Häufigkeiten von", title_text)) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }

    if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  }, height = 600)

  observe({
    req(input$x, input$y)
    if (input$analysis_type == "bivar" && plot_type() == 0) {
      // ...existing code...
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
      # two-categorical -> grouped bar (proportion within X)
      req(input$x, input$y)

      x_label <- if (exists("get_var_label")) get_var_label(input$x) else (attr(allbus[[input$x]], "label") %||% input$x)
      y_label <- if (exists("get_var_label")) get_var_label(input$y) else (attr(allbus[[input$y]], "label") %||% input$y)

      temp <- sampled_df() %>%
        mutate(.x = as.character(haven::as_factor(.data[[input$x]])),
               .y = as.character(haven::as_factor(.data[[input$y]]))) %>%
        count(.x, .y, name = "n") %>%
        group_by(.x) %>%
        mutate(prop = n / sum(n)) %>%
        ungroup()

      p <- ggplot(temp, aes(x = .x, y = prop, fill = .y)) +
        geom_col(position = position_dodge(width = 0.9), width = 0.8, alpha = 0.9) +
        scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
        labs(x = x_label, y = "Relative Häufigkeit (innerhalb X)", fill = y_label,
             title = paste(y_label, "nach", x_label)) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))

      output$plot <- renderPlot({
        if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
      }, height = 600)
    }
  })

  # R
  # assume sampled_df(), allbus, get_var_label() exist
  observe({
    req(input$analysis_type)
    if (input$analysis_type == "bivar") {
      bt <- input$bivar_type %||% "scatter"

      if (bt == "scatter") {
        # scatter: nur sinnvoll bei zwei metrischen Variablen
        req(input$x, input$y)
        validate(need(is.numeric(allbus[[input$x]]) && is.numeric(allbus[[input$y]]),
                      "Scatterplot benötigt zwei metrische Variablen."))
        p <- ggplot(sampled_df(), aes(x = .data[[input$x]], y = .data[[input$y]]))
        if (input$jitter) p <- p + geom_jitter(alpha = 0.6)
        else p <- p + geom_point(alpha = 0.6)
        if (input$smooth) p <- p + geom_smooth(se = TRUE)
        if (!is.null(input$color) && input$color != "None") p <- p + aes(color = .data[[input$color]])
        p <- p + labs(x = get_var_label(input$x), y = get_var_label(input$y),
                      title = paste(get_var_label(input$y), "vs.", get_var_label(input$x)))

      } else if (bt == "group_density") {
        # group-specific density: needs one numeric + one grouping (color or the other var)
        req(input$x, input$y)
        # determine numeric and group
        if (is.numeric(allbus[[input$x]]) && (input$color != "None" || !is.numeric(allbus[[input$y]]))) {
          num <- input$x
          grp <- if (input$color != "None") input$color else input$y
        } else if (is.numeric(allbus[[input$y]]) && (input$color != "None" || !is.numeric(allbus[[input$x]]))) {
          num <- input$y
          grp <- if (input$color != "None") input$color else input$x
        } else {
          stop("Gruppenspezifische Kerndichte benötigt mindestens eine metrische Variable und eine kategoriale Gruppierungsvariable.")
        }
        validate(need(is.numeric(allbus[[num]]), "Numerische Variable benötigt."))
        validate(need(!is.numeric(allbus[[grp]]), "Gruppierungsvariable muss kategorial sein (als Faktor)."))
        temp <- sampled_df() %>%
          mutate(.group = as.character(haven::as_factor(.data[[grp]])))
        p <- ggplot(temp, aes(x = .data[[num]], fill = .group, color = .group)) +
          geom_density(alpha = 0.35, na.rm = TRUE) +
          labs(x = get_var_label(num), y = "Dichte", fill = get_var_label(grp), color = get_var_label(grp),
               title = paste(get_var_label(num), "nach", get_var_label(grp)))

      } else if (bt == "group_bar") {
        # grouped bar: bevorzugt zwei kategoriale Variablen -> proportion innerhalb X
        req(input$x, input$y)

        # grouped bar: prop innerhalb X, X-Kategorien nach Gesamtanzahl absteigend sortiert
        temp <- sampled_df() %>%
          mutate(.x = as.character(haven::as_factor(.data[[input$x]])),
                 .y = as.character(haven::as_factor(.data[[input$y]]))) %>%
          count(.x, .y, name = "n") %>%
          group_by(.x) %>%
          mutate(prop_within = n / sum(n)) %>%
          ungroup() %>%
          group_by(.x) %>%
          mutate(total_n = sum(n)) %>%
          ungroup() %>%
          arrange(desc(total_n)) %>%
          mutate(.x = forcats::fct_reorder(.x, total_n, .desc = TRUE))

        p <- ggplot(temp, aes(x = .x, y = prop_within, fill = .y)) +
          geom_col(position = position_dodge(width = 0.9), width = 0.8) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
          labs(x = get_var_label(input$x),
               y = "Relative Häufigkeit (innerhalb X)",
               fill = get_var_label(input$y),
               title = paste(get_var_label(input$y), "nach", get_var_label(input$x))) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }
  })

  observeEvent(list(input$x, input$y, input$analysis_type), {
    req(input$analysis_type == "bivar")
    # Basisauswahl
    choices <- c("Scatterplot" = "scatter",
                 "Gruppierte Balkendiagramme" = "group_bar")
    # allow group_density only if x categorical and y numeric
    allow_group_density <- FALSE
    if (!is.null(input$x) && !is.null(input$y) && input$y != "None") {
      allow_group_density <- is.numeric(allbus[[input$y]]) && !is.numeric(allbus[[input$x]])
    }
    if (allow_group_density) {
      choices <- c(choices[1], "Gruppenspezifische Kerndichte" = "group_density", choices[2])
    }
    # keep current selection if still valid, otherwise pick first
    sel <- if (!is.null(input$bivar_type) && input$bivar_type %in% choices) input$bivar_type else names(choices)[1]
    updateSelectInput(session, "bivar_type", choices = choices, selected = sel)
  }, ignoreNULL = TRUE, ignoreInit = TRUE)

  # R
  # assume sampled_df(), allbus, get_var_label() exist
  observe({
    req(input$analysis_type)
    if (input$analysis_type == "bivar") {
      bt <- input$bivar_type %||% "scatter"

      if (bt == "scatter") {
        # scatter: nur sinnvoll bei zwei metrischen Variablen
        req(input$x, input$y)
        validate(need(is.numeric(allbus[[input$x]]) && is.numeric(allbus[[input$y]]),
                      "Scatterplot benötigt zwei metrische Variablen."))
        p <- ggplot(sampled_df(), aes(x = .data[[input$x]], y = .data[[input$y]]))
        if (input$jitter) p <- p + geom_jitter(alpha = 0.6)
        else p <- p + geom_point(alpha = 0.6)
        if (input$smooth) p <- p + geom_smooth(se = TRUE)
        if (!is.null(input$color) && input$color != "None") p <- p + aes(color = .data[[input$color]])
        p <- p + labs(x = get_var_label(input$x), y = get_var_label(input$y),
                      title = paste(get_var_label(input$y), "vs.", get_var_label(input$x)))

      } else if (bt == "group_density") {
        # group-specific density: needs one numeric + one grouping (color or the other var)
        req(input$x, input$y)
        # determine numeric and group
        if (is.numeric(allbus[[input$x]]) && (input$color != "None" || !is.numeric(allbus[[input$y]]))) {
          num <- input$x
          grp <- if (input$color != "None") input$color else input$y
        } else if (is.numeric(allbus[[input$y]]) && (input$color != "None" || !is.numeric(allbus[[input$x]]))) {
          num <- input$y
          grp <- if (input$color != "None") input$color else input$x
        } else {
          stop("Gruppenspezifische Kerndichte benötigt mindestens eine metrische Variable und eine kategoriale Gruppierungsvariable.")
        }
        validate(need(is.numeric(allbus[[num]]), "Numerische Variable benötigt."))
        validate(need(!is.numeric(allbus[[grp]]), "Gruppierungsvariable muss kategorial sein (als Faktor)."))
        temp <- sampled_df() %>%
          mutate(.group = as.character(haven::as_factor(.data[[grp]])))
        p <- ggplot(temp, aes(x = .data[[num]], fill = .group, color = .group)) +
          geom_density(alpha = 0.35, na.rm = TRUE) +
          labs(x = get_var_label(num), y = "Dichte", fill = get_var_label(grp), color = get_var_label(grp),
               title = paste(get_var_label(num), "nach", get_var_label(grp)))

      } else if (bt == "group_bar") {
        # grouped bar: bevorzugt zwei kategoriale Variablen -> proportion innerhalb X
        req(input$x, input$y)

        # grouped bar: prop innerhalb X, X-Kategorien nach Gesamtanzahl absteigend sortiert
        temp <- sampled_df() %>%
          mutate(.x = as.character(haven::as_factor(.data[[input$x]])),
                 .y = as.character(haven::as_factor(.data[[input$y]]))) %>%
          count(.x, .y, name = "n") %>%
          group_by(.x) %>%
          mutate(prop_within = n / sum(n)) %>%
          ungroup() %>%
          group_by(.x) %>%
          mutate(total_n = sum(n)) %>%
          ungroup() %>%
          arrange(desc(total_n)) %>%
          mutate(.x = forcats::fct_reorder(.x, total_n, .desc = TRUE))

        p <- ggplot(temp, aes(x = .x, y = prop_within, fill = .y)) +
          geom_col(position = position_dodge(width = 0.9), width = 0.8) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
          labs(x = get_var_label(input$x),
               y = "Relative Häufigkeit (innerhalb X)",
               fill = get_var_label(input$y),
               title = paste(get_var_label(input$y), "nach", get_var_label(input$x))) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }
  })
}


# -------------------------
# 8. App starten
shinyApp(ui = ui, server = server)

# R
library(shiny)
library(dplyr)
library(ggplot2)
library(haven)
library(labelled)
library(scales)
library(rlang)
library(stringr)
library(conflicted)
conflicts_prefer(dplyr::filter)

# -------------------------
# 0. Helper: sichere Pfadwahl
# -------------------------
find_file <- function(candidates, prompt = "Wähle Datei") {
  if (length(candidates) == 0) stop("Keine Kandidaten übergeben.")
  existings <- candidates[file.exists(candidates)]
  if (length(existings)) return(normalizePath(existings[1], winslash = "/"))
  if (interactive()) {
    chosen <- tryCatch(file.choose(), error = function(e) NA_character_)
    if (!is.na(chosen) && file.exists(chosen)) return(normalizePath(chosen, winslash = "/"))
  }
  basenames <- tolower(unique(basename(candidates)))
  roots <- unique(c(getwd(), file.path(getwd(), "data"), file.path(getwd(), "explorer"), dirname(getwd())))
  for (root in roots) {
    if (!dir.exists(root)) next
    files <- list.files(root, recursive = TRUE, full.names = TRUE)
    if (length(files) == 0) next
    matches <- files[tolower(basename(files)) %in% basenames]
    if (length(matches)) return(normalizePath(matches[1], winslash = "/"))
  }
  stop("Datei nicht gefunden.")
}

# -------------------------
# 1. Daten einlesen
# -------------------------
data_candidates <- c(
  "allbus.dta",
  file.path("data", "allbus.dta"),
  file.path("explorer", "allbus.dta"),
  file.path(getwd(), "allbus.dta")
)
data_path <- find_file(data_candidates)
raw_df <- haven::read_dta(data_path)

# -------------------------
# 2. Coercions
# -------------------------
metrisch_present <- names(raw_df)

to_numeric_safe <- function(x) {
  if (inherits(x, "labelled")) as.numeric(x)
  else if (is.factor(x)) suppressWarnings(as.numeric(as.character(x)))
  else suppressWarnings(as.numeric(x))
}

# -------------------------
# 3. Parse value/var labels if present
# -------------------------
val_lab_candidates <- c("allbus-labels.txt", file.path("explorer", "allbus-labels.txt"), file.path("data", "allbus-labels.txt"), file.path(getwd(), "allbus-labels.txt"))
labels_map <- list()
lbl_path <- val_lab_candidates[file.exists(val_lab_candidates)][1]
if (!is.na(lbl_path)) {
  lines <- readLines(lbl_path, warn = FALSE)
  cur <- NULL
  for (ln in lines) {
    ln_trim <- str_trim(ln)
    if (ln_trim == "") next
    if (grepl("^[A-Za-z0-9_]+:$", ln_trim)) {
      cur <- sub(":$", "", ln_trim)
      labels_map[[cur]] <- character()
      next
    }
    if (is.null(cur)) next
    m <- str_match(ln_trim, "^([\\-]?[0-9]+)\\s+(.*\\S)\\s*$")
    if (!is.na(m[1,1])) {
      code <- as.numeric(m[1,2]); lbl <- m[1,3]
      labels_map[[cur]][as.character(code)] <- lbl
    }
  }
}

varlabel_candidates <- c("allbus-varlabels.txt", file.path("explorer", "allbus-varlabels.txt"), file.path("data", "allbus-varlabels.txt"), file.path(getwd(), "allbus-varlabels.txt"))
var_labels <- character()
lbl_path2 <- varlabel_candidates[file.exists(varlabel_candidates)][1]
if (!is.na(lbl_path2)) {
  lns <- readLines(lbl_path2, warn = FALSE)
  for (ln in lns) {
    ln2 <- str_trim(ln)
    if (ln2 == "") next
    mm <- regexec("^([A-Za-z0-9_]+)\\s+(.*\\S)\\s$", ln2)
    parts <- regmatches(ln2, mm)[[1]]
    if (length(parts) == 3) var_labels[parts[2]] <- parts[3]
  }
}

# -------------------------
# 4. Prepare allbus dataset
# -------------------------
allbus <- raw_df %>% mutate(across(all_of(metrisch_present), ~ to_numeric_safe(.x)))

for (v in intersect(names(labels_map), names(allbus))) {
  lbls_char <- labels_map[[v]]
  if (length(lbls_char) == 0) next
  codes <- as.numeric(names(lbls_char)); labs_text <- unname(lbls_char)
  labs_named <- setNames(codes, labs_text)
  vec <- allbus[[v]]
  if (inherits(vec, "labelled")) allbus[[v]] <- labelled(as.numeric(vec), labels = labs_named)
  else if (is.numeric(vec)) allbus[[v]] <- labelled(vec, labels = labs_named)
  else if (is.factor(vec) || is.character(vec)) {
    vec_num <- suppressWarnings(as.numeric(as.character(vec)))
    if (!all(is.na(vec_num))) allbus[[v]] <- labelled(vec_num, labels = labs_named)
  }
}

for (v in setdiff(names(allbus), metrisch_present)) {
  if (!is.numeric(allbus[[v]])) {
    if (inherits(allbus[[v]], "labelled")) allbus[[v]] <- as_factor(allbus[[v]])
    else allbus[[v]] <- as.factor(allbus[[v]])
  }
}

for (v in intersect(names(var_labels), names(allbus))) attr(allbus[[v]], "label") <- var_labels[[v]]

var_names <- names(allbus)
get_display_label <- function(v) {
  lbl1 <- if (!is.null(var_labels[v]) && nzchar(var_labels[v])) var_labels[v]
  lbl2 <- if (is.null(lbl1) || !nzchar(lbl1)) {
    al <- attr(allbus[[v]], "label")
    if (!is.null(al) && nzchar(as.character(al))) as.character(al) else v
  } else lbl1
  as.character(lbl2)
}
display_labels <- vapply(var_names, get_display_label, FUN.VALUE = character(1), USE.NAMES = FALSE)
missing_label_idx <- which(is.na(display_labels) | display_labels == "")
if (length(missing_label_idx) > 0) display_labels[missing_label_idx] <- var_names[missing_label_idx]
choices_named <- setNames(var_names, display_labels)
choices_y <- c("None" = "None", choices_named)
choices_color <- c("None" = "None", choices_named)
if (!exists("var_labels")) var_labels <- character()
get_var_label <- function(v) {
  if (!is.null(var_labels) && v %in% names(var_labels) && nzchar(var_labels[[v]])) return(as.character(var_labels[[v]]))
  al <- attr(allbus[[v]], "label")
  if (!is.null(al) && nzchar(as.character(al))) return(as.character(al))
  v
}

# -------------------------
# 5. Shiny UI
# -------------------------
ui <- fluidPage(
  titlePanel("Allbus Explorer"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("sampleType", "Plot sample type", choices = list("random n" = "random", "all n" = "all"), selected = "all"),
      conditionalPanel(condition = "input.sampleType == 'random'",
                       sliderInput("sampleSize", "Plot sample size (n)", min = 1, max = nrow(allbus), value = min(1000, nrow(allbus)), step = max(1, floor(nrow(allbus)/50))),
                       actionButton("drawAgain", "draw again")
      ),

      radioButtons("analysis_type", "Analyse-Typ", choices = c("Univariat" = "univar", "Bivariat" = "bivar"), selected = "univar"),

      conditionalPanel(condition = "input.analysis_type == 'univar'",
                       selectInput("y_uni", "Variable (univariat)", choices = choices_named, selected = var_names[1]),
                       selectInput("univar_type", "Univariate Darstellung", choices = c("Auto (Kategorie/Metrisch)" = "auto", "Kerndichte" = "dens", "Balken (relative)" = "bar"), selected = "bar"),
                       checkboxInput("show_missings", "Show missings", value = FALSE)
      ),

      conditionalPanel(condition = "input.analysis_type == 'bivar'",
                       selectInput("x", "X", choices = choices_named, selected = var_names[1]),
                       selectInput("y", "Y", choices = choices_y, selected = "None"),
                       selectInput("color", "Color", choices = choices_color, selected = "None"),
                       checkboxInput("jitter", "Jitter", value = FALSE),
                       checkboxInput("smooth", "Smooth", value = FALSE),
                       selectInput("bivar_type", "Bivariate Darstellung", choices = c("Scatterplot" = "scatter", "Gruppierte Balkendiagramme" = "group_bar"), selected = "scatter"),
                       conditionalPanel(condition = "input.bivar_type == 'group_bar'", checkboxInput("show_missings_bivar", "Show missings", value = FALSE))
      )
    ),
    mainPanel(
      tabsetPanel(type = "tabs", tabPanel("Plot", plotOutput("plot")), tabPanel("Data Snippet", verbatimTextOutput("snippet")), tabPanel("Summary", verbatimTextOutput("summary")), tabPanel("str() Output", verbatimTextOutput("str")))
    )
  )
)

# -------------------------
# 6. Shiny Server
# -------------------------
server <- function(input, output, session) {
  output$summary <- renderPrint(summary(allbus))
  output$str <- renderPrint(str(allbus))

  seed_rv <- reactiveVal(sample.int(.Machine$integer.max, 1))
  observeEvent(input$drawAgain, { seed_rv(sample.int(.Machine$integer.max, 1)) })

  sampled_df <- reactive({
    if (is.null(input$sampleType) || input$sampleType == "all") return(allbus)
    n <- req(input$sampleSize)
    set.seed(seed_rv())
    allbus[sample(nrow(allbus), size = min(n, nrow(allbus))), , drop = FALSE]
  })

  output$snippet <- renderPrint(head(sampled_df(), n = 15))

  plot_type <- reactive({
    if (input$analysis_type == "univar") return(-1)
    req(input$x, input$y)
    if (input$y == "None") return(-1)
    is.numeric(allbus[[input$x]]) + is.numeric(allbus[[input$y]])
  })

  output$plot <- renderPlot({
    p <- NULL
    if (plot_type() == 2) {
      req(input$x, input$y)
      p <- ggplot(sampled_df(), aes(x = .data[[input$x]], y = .data[[input$y]]))
      if (input$jitter) p <- p + geom_jitter(alpha = 0.6) else p <- p + geom_point(alpha = 0.6)
      if (input$smooth) p <- p + geom_smooth(se = TRUE)
      if (!is.null(input$color) && input$color != "None") p <- p + aes(color = .data[[input$color]])
      p <- p + labs(x = get_var_label(input$x), y = get_var_label(input$y))

    } else if (plot_type() == 1) {
      req(input$x, input$y)
      if (is.numeric(allbus[[input$x]])) { num <- input$x; catv <- input$y } else { num <- input$y; catv <- input$x }
      p <- ggplot(sampled_df(), aes(x = .data[[catv]], y = .data[[num]])) + geom_boxplot()
      if (!is.null(input$color) && input$color != "None") p <- p + aes(fill = .data[[input$color]])
      p <- p + labs(x = get_var_label(catv), y = get_var_label(num))

    } else if (plot_type() == 0) {
      req(input$x, input$y)
      temp <- sampled_df() %>% count(.data[[input$x]], .data[[input$y]], name = "n")
      p <- ggplot(temp, aes(x = .data[[input$x]], y = .data[[input$y]], fill = n)) + geom_tile() + scale_fill_gradient(low = "#e7e7fd", high = "#1111dd") + labs(x = get_var_label(input$x), y = get_var_label(input$y), fill = "Count")

    } else {
      var <- if (input$analysis_type == "univar") input$y_uni else input$x
      req(var)
      utype <- input$univar_type
      if (is.null(utype)) utype <- "auto"
      if (utype == "auto" && is.numeric(allbus[[var]])) utype <- "dens"
      if (utype == "auto" && !is.numeric(allbus[[var]])) utype <- "bar"
      title_text <- get_var_label(var)

      if (utype == "dens") {
        validate(need(is.numeric(allbus[[var]]), "Kerndichte benötigt eine metrische Variable."))
        p <- ggplot(sampled_df(), aes(x = .data[[var]])) + geom_density(fill = "#2c7fb8", alpha = 0.5, na.rm = TRUE) + labs(x = get_var_label(var), y = "Dichte", title = title_text)

      } else if (utype == "bar") {
        df <- sampled_df()
        if (isFALSE(input$show_missings)) df <- df %>% filter(!is.na(.data[[var]]))
        temp <- df %>% mutate(.code = as.character(.data[[var]]), .label = as.character(haven::as_factor(.data[[var]]))) %>% count(.code, .label, name = "n") %>% mutate(code_num = suppressWarnings(as.numeric(.code))) %>% arrange(code_num)
        temp <- temp %>% group_by(.label) %>% mutate(display = ifelse(n() > 1, paste0(.label, " (", .code, ")"), .label)) %>% ungroup() %>% mutate(prop = n / sum(n), display = forcats::fct_inorder(display))
        p <- ggplot(temp, aes(x = display, y = prop)) + geom_col(fill = "#4daf4a", alpha = 0.85) + geom_text(aes(label = scales::percent(prop, accuracy = 0.1)), vjust = -0.25, size = 3) + scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) + labs(x = title_text, y = "Relative Häufigkeit", title = paste("Relative Häufigkeiten von", title_text)) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }
    if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  }, height = 600)

  observe({
    req(input$x, input$y)
    if (input$analysis_type == "bivar" && input$bivar_type == "group_bar") {
      x_label <- get_var_label(input$x); y_label <- get_var_label(input$y)
      df <- sampled_df()
      if (isFALSE(input$show_missings_bivar)) df <- df %>% filter(!is.na(.data[[input$x]]), !is.na(.data[[input$y]]))
      temp <- df %>% mutate(.x_code = as.character(.data[[input$x]]), .y_code = as.character(.data[[input$y]]), .x_lab = as.character(haven::as_factor(.data[[input$x]])), .y_lab = as.character(haven::as_factor(.data[[input$y]]))) %>% count(.x_code, .x_lab, .y_code, .y_lab, name = "n") %>% group_by(.x_code, .x_lab) %>% mutate(prop_within = n / sum(n)) %>% ungroup() %>% group_by(.x_code) %>% mutate(total_n = sum(n)) %>% ungroup() %>% arrange(as.numeric(.x_code)) %>% mutate(.x_disp = ifelse(duplicated(.x_lab) | duplicated(.x_lab, fromLast = TRUE), paste0(.x_lab, " (", .x_code, ")"), .x_lab), .y_disp = ifelse(duplicated(.y_lab) | duplicated(.y_lab, fromLast = TRUE), paste0(.y_lab, " (", .y_code, ")"), .y_lab), .x_disp = forcats::fct_inorder(.x_disp))
      p <- ggplot(temp, aes(x = .x_disp, y = prop_within, fill = .y_disp)) + geom_col(position = position_dodge(width = 0.9), width = 0.8, alpha = 0.9) + geom_text(aes(label = scales::percent(prop_within, accuracy = 0.1)), position = position_dodge(width = 0.9), vjust = -0.25, size = 3) + scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) + labs(x = x_label, y = "Relative Häufigkeit (innerhalb X)", fill = y_label, title = paste(y_label, "nach", x_label)) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
      output$plot <- renderPlot({ if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold")) }, height = 600)
    }
  })

}

shinyApp(ui = ui, server = server)
# R
library(shiny)
library(dplyr)
library(ggplot2)
library(haven)
library(labelled)
library(scales)
library(stringr)
conflicts_prefer(dplyr::filter)

# Helper: sichere Pfadwahl
find_file <- function(candidates) {
  existings <- candidates[file.exists(candidates)]
  if (length(existings)) return(normalizePath(existings[1], winslash = "/"))
  stop("Datei nicht gefunden. Bitte allbus.dta in einem der Kandidatenpfade ablegen.")
}

data_candidates <- c("allbus.dta", file.path("data", "allbus.dta"), file.path("explorer", "allbus.dta"), file.path(getwd(), "allbus.dta"))
data_path <- find_file(data_candidates)
raw_df <- haven::read_dta(data_path)

# safe numeric coercion
to_numeric_safe <- function(x) {
  if (inherits(x, "labelled")) as.numeric(x)
  else if (is.factor(x)) suppressWarnings(as.numeric(as.character(x)))
  else suppressWarnings(as.numeric(x))
}

# prepare dataset: coerce all vars to numeric where possible
metrisch_present <- names(raw_df)
allbus <- raw_df %>% mutate(across(all_of(metrisch_present), ~ to_numeric_safe(.x)))

# variable labels helper
get_var_label <- function(v) {
  al <- attr(allbus[[v]], "label")
  if (!is.null(al) && nzchar(as.character(al))) return(as.character(al))
  v
}

# UI choices
var_names <- names(allbus)
display_labels <- vapply(var_names, function(v) { lbl <- attr(allbus[[v]], "label"); if (is.null(lbl) || !nzchar(as.character(lbl))) v else as.character(lbl) }, FUN.VALUE = "")
missing_label_idx <- which(is.na(display_labels) | display_labels == "")
if (length(missing_label_idx)) display_labels[missing_label_idx] <- var_names[missing_label_idx]
choices_named <- setNames(var_names, display_labels)
choices_y <- c("None" = "None", choices_named)
choices_color <- c("None" = "None", choices_named)

ui <- fluidPage(
  titlePanel("Allbus Explorer"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("sampleType", "Plot sample type", choices = list("random n" = "random", "all n" = "all"), selected = "all"),
      conditionalPanel(condition = "input.sampleType == 'random'",
                       sliderInput("sampleSize", "Plot sample size (n)", min = 1, max = nrow(allbus), value = min(1000, nrow(allbus)), step = max(1, floor(nrow(allbus)/50))),
                       actionButton("drawAgain", "draw again")
      ),

      radioButtons("analysis_type", "Analyse-Typ", choices = c("Univariat" = "univar", "Bivariat" = "bivar"), selected = "univar"),

      conditionalPanel(condition = "input.analysis_type == 'univar'",
                       selectInput("y_uni", "Variable (univariat)", choices = choices_named, selected = var_names[1]),
                       selectInput("univar_type", "Univariate Darstellung", choices = c("Auto (Kategorie/Metrisch)" = "auto", "Kerndichte" = "dens", "Balken (relative)" = "bar"), selected = "bar"),
                       checkboxInput("show_missings", "Show missings", value = FALSE)
      ),

      conditionalPanel(condition = "input.analysis_type == 'bivar'",
                       selectInput("x", "X", choices = choices_named, selected = var_names[1]),
                       selectInput("y", "Y", choices = choices_y, selected = "None"),
                       selectInput("color", "Color", choices = choices_color, selected = "None"),
                       checkboxInput("jitter", "Jitter", value = FALSE),
                       checkboxInput("smooth", "Smooth", value = FALSE),
                       selectInput("bivar_type", "Bivariate Darstellung", choices = c("Scatterplot" = "scatter", "Gruppierte Balkendiagramme" = "group_bar"), selected = "scatter"),
                       conditionalPanel(condition = "input.bivar_type == 'group_bar'", checkboxInput("show_missings_bivar", "Show missings", value = FALSE))
      )
    ),
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Plot", plotOutput("plot", height = "600px")),
                  tabPanel("Data Snippet", verbatimTextOutput("snippet")),
                  tabPanel("Summary", verbatimTextOutput("summary")),
                  tabPanel("str() Output", verbatimTextOutput("str"))
      )
    )
  )
)

server <- function(input, output, session) {
  output$summary <- renderPrint(summary(allbus))
  output$str <- renderPrint(str(allbus))

  # reactive seed for drawAgain
  seed_rv <- reactiveVal(sample.int(.Machine$integer.max, 1))
  observeEvent(input$drawAgain, seed_rv(sample.int(.Machine$integer.max, 1)))

  sampled_df <- reactive({
    if (is.null(input$sampleType) || input$sampleType == "all") return(allbus)
    n <- req(input$sampleSize)
    set.seed(seed_rv())
    allbus[sample(nrow(allbus), size = min(n, nrow(allbus))), , drop = FALSE]
  })

  output$snippet <- renderPrint(head(sampled_df(), n = 15))

  plot_type <- reactive({
    if (input$analysis_type == "univar") return(-1)
    req(input$x, input$y)
    if (input$y == "None") return(-1)
    is.numeric(allbus[[input$x]]) + is.numeric(allbus[[input$y]])
  })

  output$plot <- renderPlot({
    p <- NULL

    if (plot_type() == 2) {
      req(input$x, input$y)
      p <- ggplot(sampled_df(), aes(x = .data[[input$x]], y = .data[[input$y]]))
      if (input$jitter) p <- p + geom_jitter(alpha = 0.6) else p <- p + geom_point(alpha = 0.6)
      if (input$smooth) p <- p + geom_smooth(se = TRUE)
      if (!is.null(input$color) && input$color != "None") p <- p + aes(color = .data[[input$color]])
      p <- p + labs(x = get_var_label(input$x), y = get_var_label(input$y))

    } else if (plot_type() == 1) {
      req(input$x, input$y)
      if (is.numeric(allbus[[input$x]])) { num <- input$x; catv <- input$y } else { num <- input$y; catv <- input$x }
      p <- ggplot(sampled_df(), aes(x = .data[[catv]], y = .data[[num]])) + geom_boxplot()
      if (!is.null(input$color) && input$color != "None") p <- p + aes(fill = .data[[input$color]])
      p <- p + labs(x = get_var_label(catv), y = get_var_label(num))

    } else if (plot_type() == 0) {
      req(input$x, input$y)
      temp <- sampled_df() %>% count(.data[[input$x]], .data[[input$y]], name = "n")
      p <- ggplot(temp, aes(x = .data[[input$x]], y = .data[[input$y]], fill = n)) + geom_tile() + scale_fill_gradient(low = "#e7e7fd", high = "#1111dd") + labs(x = get_var_label(input$x), y = get_var_label(input$y), fill = "Count")

    } else {
      var <- if (input$analysis_type == "univar") input$y_uni else input$x
      req(var)
      utype <- input$univar_type
      if (is.null(utype)) utype <- "auto"
      if (utype == "auto" && is.numeric(allbus[[var]])) utype <- "dens"
      if (utype == "auto" && !is.numeric(allbus[[var]])) utype <- "bar"

      title_text <- get_var_label(var)

      if (utype == "dens") {
        validate(need(is.numeric(allbus[[var]]), "Kerndichte benötigt eine metrische Variable."))
        p <- ggplot(sampled_df(), aes(x = .data[[var]])) + geom_density(fill = "#2c7fb8", alpha = 0.5, na.rm = TRUE) + labs(x = get_var_label(var), y = "Dichte", title = title_text)

      } else if (utype == "bar") {
        df <- sampled_df()
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
          mutate(prop = n / sum(n), display = forcats::fct_inorder(display))

        p <- ggplot(temp, aes(x = display, y = prop)) +
          geom_col(fill = "#4daf4a", alpha = 0.85) +
          geom_text(aes(label = scales::percent(prop, accuracy = 0.1)), vjust = -0.25, size = 3) +
          scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) +
          labs(x = title_text, y = "Relative Häufigkeit", title = paste("Relative Häufigkeiten von", title_text)) +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }

    if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })

  # grouped bivar bars when selected
  observe({
    req(input$x, input$y)
    if (input$analysis_type == "bivar" && input$bivar_type == "group_bar") {
      x_label <- get_var_label(input$x); y_label <- get_var_label(input$y)
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
        geom_text(aes(label = scales::percent(prop_within, accuracy = 0.1)), position = position_dodge(width = 0.9), vjust = -0.25, size = 3) +
        scale_y_continuous(labels = scales::percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.08))) +
        labs(x = x_label, y = "Relative Häufigkeit (innerhalb X)", fill = y_label, title = paste(y_label, "nach", x_label)) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))

      output$plot <- renderPlot({ if (!is.null(p)) p + theme_bw() + theme(plot.title = element_text(hjust = 0.5, face = "bold")) }, height = 600)
    }
  })
}

shinyApp(ui = ui, server = server)



