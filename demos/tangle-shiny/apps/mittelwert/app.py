import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from shiny import App, ui
from shinywidgets import output_widget, render_widget

from formeln import inputs_ui, mean_widget, style_tag, werte

app_ui = ui.page_fluid(
    style_tag(),
    inputs_ui(),
    ui.card(ui.card_header("Mittelwert"), output_widget("formel")),
)


def server(input, output, session):
    @render_widget
    def formel():
        return mean_widget(werte(input))


app = App(app_ui, server)
