library(shiny)
library(bslib)

source("kse.R", encoding = "UTF-8")

# Matrix-Layout: jede Tabellenzeile ist eine Shiny-Radiogruppe (id = Itemname),
# die Antwortlabels stehen einmal im (sticky) Tabellenkopf.
item_row <- function(i) {
  tags$tr(
    id = kse_vars[i], class = "shiny-input-radiogroup",
    tags$td(class = "kse-text", tags$b(paste0(i, ". ")), kse_items[i]),
    lapply(seq_along(kse_labels), \(k) {
      tags$td(
        class = "kse-opt",
        tags$label(
          title = names(kse_labels)[k],
          tags$input(
            type = "radio", name = kse_vars[i], value = kse_labels[[k]],
            `aria-label` = paste0(i, ": ", names(kse_labels)[k])
          )
        )
      )
    })
  )
}

item_matrix <- function() {
  # weiches Trennzeichen, damit "Manchmal" auf schmalen Displays umbrechen kann
  heads <- sub("Manchmal", "Manch\u00ADmal", names(kse_labels))
  tags$table(
    class = "kse-matrix",
    tags$thead(tags$tr(
      tags$th(class = "kse-text", "Aussage"),
      lapply(heads, \(h) tags$th(class = "kse-opt", h))
    )),
    tags$tbody(lapply(seq_along(kse_items), item_row))
  )
}

# Verhindert Mehrfachteilnahme pro Gerät und Welle (localStorage)
done_js <- "
$(document).on('shiny:connected', function() {
  var w = new URLSearchParams(window.location.search).get('w') || '';
  Shiny.setInputValue('done_before', localStorage.getItem('kse_done_' + w) === '1');
});
Shiny.addCustomMessageHandler('mark_done', function(w) {
  localStorage.setItem('kse_done_' + w, '1');
});
// fehlende Items markieren; Markierung verschwindet beim Beantworten
Shiny.addCustomMessageHandler('mark_missing', function(ids) {
  [].concat(ids).forEach(function(id) { $('#' + id).addClass('kse-missing'); });
  if (ids.length) document.getElementById([].concat(ids)[0]).scrollIntoView({block: 'center'});
});
$(document).on('change', '.kse-matrix input[type=radio]', function() {
  $(this).closest('tr').removeClass('kse-missing');
});
"

ui <- page_fixed(
  title = "Einsamkeit im Hörsaal",
  theme = bs_theme(version = 5, base_font = font_collection("system-ui", "sans-serif")),
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$script(HTML(done_js)),
    tags$style(HTML("
      .container { max-width: 760px; }
      .kse-matrix { width: 100%; border-collapse: collapse; margin-top: 1rem; }
      .kse-matrix th { position: sticky; top: 0; z-index: 2; background: #fff;
                       border-bottom: 2px solid #333; padding: .4rem .2rem;
                       font-size: .8rem; font-weight: 600; vertical-align: bottom; }
      .kse-matrix td { border-bottom: 1px solid #e5e5e5; padding: .5rem .2rem; }
      .kse-matrix tbody tr:nth-child(odd) { background: #f6f8fa; }
      .kse-matrix .kse-text { text-align: left; line-height: 1.3; }
      .kse-matrix .kse-opt { width: 3.6rem; text-align: center; hyphens: manual; }
      .kse-matrix .kse-opt label { display: flex; justify-content: center; align-items: center;
                                   width: 100%; min-height: 2.6rem; cursor: pointer; margin: 0; }
      .kse-matrix input[type=radio] { width: 1.3rem; height: 1.3rem; cursor: pointer; }
      .kse-matrix tr.kse-missing td.kse-text { color: #b02a37; font-weight: 600; }
      @media (max-width: 480px) {
        .container { padding-left: .4rem; padding-right: .4rem; }
        .kse-matrix .kse-text { font-size: .88rem; }
        .kse-matrix .kse-opt { width: 2.9rem; }
        .kse-matrix th { font-size: .7rem; }
      }
    "))
  ),
  uiOutput("main")
)

server <- function(input, output, session) {
  submitted <- reactiveVal(FALSE)

  welle <- reactive({
    w <- parseQueryString(session$clientData$url_search)$w
    if (is.null(w) || !nzchar(w)) default_welle() else gsub("[^A-Za-z0-9_-]", "", w)
  })

  output$main <- renderUI({
    req(!is.null(input$done_before))
    if (submitted() || isTRUE(input$done_before)) {
      return(card(
        card_header("Vielen Dank!"),
        p("Ihre Antworten wurden gespeichert. Die Ergebnisse sehen Sie gleich auf den Folien."),
        p(class = "text-muted small",
          "Falls Sie sich häufig einsam fühlen und darüber sprechen möchten: ",
          "Die Psychosoziale Beratung des Studierendenwerks und die TelefonSeelsorge ",
          "(0800 111 0 111, rund um die Uhr, anonym) sind für Sie da.")
      ))
    }
    tagList(
      card(
        card_header("Einsamkeit im Hörsaal"),
        p("Die Befragung ist freiwillig und anonym. Es werden keine personenbezogenen ",
          "Daten (auch keine IP-Adressen) gespeichert. Die Ergebnisse werden nur ",
          "zusammengefasst in der Vorlesung gezeigt."),
        p(tags$b("Bitte geben Sie an, wie oft Sie sich so fühlen, wie in den ",
                 "nachfolgenden Aussagen beschrieben."))
      ),
      item_matrix(),
      div(class = "my-3", uiOutput("missing_msg")),
      actionButton("submit", "Absenden", class = "btn-primary btn-lg w-100 mb-5")
    )
  })

  missing_items <- reactive({
    which(vapply(kse_vars, \(v) is.null(input[[v]]), logical(1)))
  })

  output$missing_msg <- renderUI(NULL)

  observeEvent(input$submit, {
    miss <- missing_items()
    if (length(miss) > 0) {
      output$missing_msg <- renderUI(div(
        class = "alert alert-warning",
        "Bitte beantworten Sie noch die rot markierte(n) Aussage(n): ",
        paste(miss, collapse = ", ")
      ))
      session$sendCustomMessage("mark_missing", as.list(kse_vars[miss]))
      return()
    }
    row <- data.frame(
      id = paste(sample(c(letters, 0:9), 12, replace = TRUE), collapse = ""),
      zeit = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      welle = welle(),
      t(vapply(kse_vars, \(v) as.integer(input[[v]]), integer(1)))
    )
    write.table(
      row, DATA_FILE, sep = ",", row.names = FALSE,
      col.names = !file.exists(DATA_FILE), append = file.exists(DATA_FILE)
    )
    session$sendCustomMessage("mark_done", parseQueryString(session$clientData$url_search)$w %||% "")
    submitted(TRUE)
  })
}

shinyApp(ui, server)
