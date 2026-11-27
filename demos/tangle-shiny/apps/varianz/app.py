import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from shiny import App, ui
from shinywidgets import output_widget, render_widget

from formeln import inputs_ui, style_tag, var_widget, werte

# Gewicht und Freiheitsgrade oben rechts in der Karte; ihre Pfeile entfallen,
# das Hervorheben beim Überfahren der Formelteile bleibt erhalten.
VAR_CSS = """
.latex-tangle__label[data-annotation="gewicht"],
.latex-tangle__label[data-annotation="nm1"] {
  position: absolute !important;
  left: auto !important;
  right: 0 !important;
  top: 0 !important;
}
.latex-tangle__label[data-annotation="nm1"] {
  top: 5.5rem !important;
}
.latex-tangle__arrow[data-annotation="gewicht"],
.latex-tangle__arrow[data-annotation="nm1"] {
  display: none;
}
"""

app_ui = ui.page_fluid(
    style_tag(),
    ui.tags.style(VAR_CSS),
    inputs_ui(),
    ui.card(ui.card_header("Varianz"), output_widget("formel")),
)


def server(input, output, session):
    @render_widget
    def formel():
        return var_widget(werte(input))


app = App(app_ui, server)
