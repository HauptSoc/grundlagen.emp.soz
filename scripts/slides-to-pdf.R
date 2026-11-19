# Exportiert eine gerenderte reveal.js-Folie als PDF.
# Die Seitengröße entspricht der Designgröße der Folien (Reveal-Konfiguration),
# nicht dem Fenster oder den Druckeinstellungen des Browsers.

library(chromote)

# `html` kann ein lokaler Pfad oder eine http(s)-URL sein. Decks mit OJS-Zellen
# brauchen http (die OJS-Runtime blockiert unter file:// mit einem alert()),
# z. B. srv <- httpuv::startServer("127.0.0.1", 8765,
#   list(staticPaths = list("/" = httpuv::staticPath("docs"))))
# und html = "http://127.0.0.1:8765/slides/x.html" (danach srv$stop()).
slides_to_pdf <- function(html, pdf = sub("\\.html$", ".pdf", html), wait = 3, margin_cm = 1) {
  url <- if (grepl("^https?://", html)) {
    paste0(html, "?print-pdf")
  } else {
    paste0(
      "file:///", utils::URLencode(normalizePath(html, winslash = "/"), reserved = FALSE),
      "?print-pdf"
    )
  }
  b <- ChromoteSession$new()
  on.exit(b$close(), add = TRUE)

  b$Page$navigate(url, wait_ = TRUE)
  for (i in seq_len(60)) {
    ready <- b$Runtime$evaluate(
      "typeof Reveal !== 'undefined' && Reveal.isReady()",
      timeout_ = 180
    )$result$value
    if (isTRUE(ready)) break
    Sys.sleep(0.5)
  }
  # Zeit für Bilder, Mermaid-Diagramme und MathJax
  Sys.sleep(wait)

  # Designgröße in CSS-Pixeln (96 dpi)
  w <- b$Runtime$evaluate("Reveal.getConfig().width", timeout_ = 180)$result$value
  h <- b$Runtime$evaluate("Reveal.getConfig().height", timeout_ = 180)$result$value

  # Ränder in Zoll (Chrome erwartet Zoll); die Folie bleibt 1:1 im Inneren
  m <- margin_cm / 2.54
  res <- b$Page$printToPDF(
    printBackground = TRUE,
    preferCSSPageSize = FALSE,
    paperWidth = w / 96 + 2 * m, paperHeight = h / 96 + 2 * m,
    scale = 1,
    marginTop = m, marginBottom = m, marginLeft = m, marginRight = m,
    timeout_ = 180
  )
  writeBin(base64enc::base64decode(res$data), pdf)
  message("PDF geschrieben: ", normalizePath(pdf, winslash = "/"), " (", w, "x", h, " px)")
  invisible(pdf)
}
