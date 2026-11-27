import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from shiny import App, render, ui

from formeln import abweichungen_ui, inputs_ui, style_tag, werte

app_ui = ui.page_fluid(
    inputs_ui(),
    ui.card(ui.card_header("Abweichungen"), ui.output_ui("tabelle")),
)


def server(input, output, session):
    @render.ui
    def tabelle():
        return abweichungen_ui(werte(input))


app = App(app_ui, server)
