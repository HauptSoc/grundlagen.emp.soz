library(shiny)
library(bslib)

source("hsp.R", encoding = "UTF-8")

# Matrix-Layout: jede Tabellenzeile ist eine Shiny-Radiogruppe (id = Itemname),
# die Antwortlabels stehen einmal im (sticky) Tabellenkopf.
item_row <- function(i) {
  tags$tr(
    id = hsp_vars[i], class = "shiny-input-radiogroup",
    tags$td(class = "hsp-text", tags$b(paste0(i, ". ")), hsp_items[i]),
    lapply(seq_along(hsp_labels), \(k) {
      tags$td(
        class = "hsp-opt",
        tags$label(
          title = names(hsp_labels)[k],
          tags$input(
            type = "radio", name = hsp_vars[i], value = hsp_labels[[k]],
            `aria-label` = paste0(i, ": ", names(hsp_labels)[k])
          )
        )
      )
    })
  )
}

item_matrix <- function() {
  heads <- names(hsp_labels)
  tags$table(
    class = "hsp-matrix",
    tags$thead(tags$tr(
      tags$th(class = "hsp-text", "Aussage"),
      lapply(heads, \(h) tags$th(class = "hsp-opt", h))
    )),
    tags$tbody(lapply(seq_along(hsp_items), item_row))
  )
}

# Verhindert Mehrfachteilnahme pro Gerät und Welle (localStorage)
done_js <- "
$(document).on('shiny:connected', function() {
  var w = new URLSearchParams(window.location.search).get('w') || '';
  Shiny.setInputValue('done_before', localStorage.getItem('hsp_done_' + w) === '1');
});
Shiny.addCustomMessageHandler('mark_done', function(w) {
  localStorage.setItem('hsp_done_' + w, '1');
});
// fehlende Items markieren; Markierung verschwindet beim Beantworten
Shiny.addCustomMessageHandler('mark_missing', function(ids) {
  [].concat(ids).forEach(function(id) { $('#' + id).addClass('hsp-missing'); });
  if (ids.length) document.getElementById([].concat(ids)[0]).scrollIntoView({block: 'center'});
});
$(document).on('change', '.hsp-matrix input[type=radio]', function() {
  $(this).closest('tr').removeClass('hsp-missing');
});
"

ui <- page_fixed(
  title = "Hochsensibilität im Hörsaal",
  theme = bs_theme(version = 5, base_font = font_collection("system-ui", "sans-serif")),
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$script(HTML(done_js)),
    tags$style(HTML("
      .container { max-width: 760px; }
      .hsp-matrix { width: 100%; border-collapse: collapse; margin-top: 1rem; }
      .hsp-matrix th { position: sticky; top: 0; z-index: 2; background: #fff;
                       border-bottom: 2px solid #333; padding: .4rem .2rem;
                       font-size: .8rem; font-weight: 600; vertical-align: bottom; }
      .hsp-matrix td { border-bottom: 1px solid #e5e5e5; padding: .5rem .2rem; }
      .hsp-matrix tbody tr:nth-child(odd) { background: #f6f8fa; }
      .hsp-matrix .hsp-text { text-align: left; line-height: 1.3; }
      .hsp-matrix .hsp-opt { width: 4.4rem; text-align: center; hyphens: manual; }
      .hsp-matrix .hsp-opt label { display: flex; justify-content: center; align-items: center;
                                   width: 100%; min-height: 2.6rem; cursor: pointer; margin: 0; }
      .hsp-matrix input[type=radio] { width: 1.3rem; height: 1.3rem; cursor: pointer; }
      .hsp-matrix tr.hsp-missing td.hsp-text { color: #b02a37; font-weight: 600; }
      @media (max-width: 480px) {
        .container { padding-left: .4rem; padding-right: .4rem; }
        .hsp-matrix .hsp-text { font-size: .88rem; }
        .hsp-matrix .hsp-opt { width: 3.4rem; }
        .hsp-matrix th { font-size: .7rem; }
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
          "Hinweis: Die Kurzform dient hier der Lehre und ist keine Diagnose.")
      ))
    }
    tagList(
      card(
        card_header("Hochsensibilität im Hörsaal"),
        p("Die Befragung ist freiwillig und anonym. Es werden keine personenbezogenen ",
          "Daten (auch keine IP-Adressen) gespeichert. Die Ergebnisse werden nur ",
          "zusammengefasst in der Vorlesung gezeigt."),
        p(tags$b("Inwieweit treffen die folgenden Aussagen auf Sie zu? ",
                 "Antworten Sie möglichst offen und ehrlich. ",
                 "Es gibt keine richtigen oder falschen Antworten.")),
        p(class = "text-muted small",
          "HSP-Test für Hochsensibilität, Kurzform (Satow, 2022), CC BY-NC-ND 4.0.")
      ),
      item_matrix(),
      div(class = "my-3", uiOutput("missing_msg")),
      actionButton("submit", "Absenden", class = "btn-primary btn-lg w-100 mb-5")
    )
  })

  missing_items <- reactive({
    which(vapply(hsp_vars, \(v) is.null(input[[v]]), logical(1)))
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
      session$sendCustomMessage("mark_missing", as.list(hsp_vars[miss]))
      return()
    }
    row <- data.frame(
      id = paste(sample(c(letters, 0:9), 12, replace = TRUE), collapse = ""),
      zeit = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      welle = welle(),
      t(vapply(hsp_vars, \(v) as.integer(input[[v]]), integer(1)))
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
