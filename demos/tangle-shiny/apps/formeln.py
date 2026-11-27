"""Gemeinsame Eingaben und Formeln für die Karten zu Mittelwert, Varianz und Standardabweichung."""

import numpy as np
from shiny import req, ui
from wigglystuff import TangleLatex

N = 6
START = [2, 4, 4, 5, 7, 8]

# Eine Farbe je Konzept: gleiche Symbole haben in allen Karten dieselbe Farbe.
COL = {
    "mean": "#246bce",  # x̄ und Mittelwert
    "xi": "#b45b1b",    # einzelner Wert x_i
    "n": "#147a68",     # Anzahl n bzw. n - 1
    "one": "#6f5cbd",   # Gewichte 1/n und 1/(n-1)
    "sum": "#a23b78",   # Summenzeichen
    "var": "#7a5c00",   # Varianz s²
    "sd": "#c0392b",    # Standardabweichung s
}

STYLE = """
/* Genug Platz oben für mehrzeilige Erläuterungen, sonst werden sie abgeschnitten. */
.latex-tangle__stage {
  padding-top: 130px !important;
}
.latex-tangle__label {
  max-width: min(300px, 70%);
  font-size: 1.05rem;
  padding: 5px 9px;
}
.latex-tangle.latex-tangle .latex-tangle__label:not(.is-hovered),
.latex-tangle.latex-tangle .latex-tangle__arrow:not(.is-hovered),
.latex-tangle.latex-tangle .latex-tangle__tint:not(.is-hovered) {
  opacity: 0;
}
.latex-tangle.latex-tangle .latex-tangle__label.is-hovered,
.latex-tangle.latex-tangle .latex-tangle__arrow.is-hovered,
.latex-tangle.latex-tangle .latex-tangle__tint.is-hovered {
  opacity: 1;
}
"""


def style_tag():
    return ui.tags.style(STYLE)


def inputs_ui():
    return ui.layout_columns(
        *[
            ui.input_numeric(f"x{i}", f"Wert {i}", value=START[i - 1], step=1)
            for i in range(1, N + 1)
        ],
        col_widths=[2] * N,
    )


def werte(input):
    vals = [input[f"x{i}"]() for i in range(1, N + 1)]
    req(all(v is not None for v in vals))
    return np.array(vals, dtype=float)


def num(v):
    s = f"{v:.4g}"
    return f"({s})" if v < 0 else s


def lock(v, color):
    # Das Widget kennt keinen Nur-Lese-Modus: ein minimaler Bereich um den Ergebniswert.
    v = float(v)
    return {
        "value": v,
        "min_value": v - 0.001,
        "max_value": v + 0.001,
        "step": 0.001,
        "digits": 2,
        "color": color,
    }


def note(text, color):
    return {"text": text, "color": color}


def mean_widget(xs):
    m = xs.mean()
    terms = " + ".join(num(v) for v in xs)
    latex = (
        r"\note{mean}{\bar{x}} = \frac{\note{one}{1}}{\note{n}{6}}"
        r" \note{sum}{\sum_{i=1}^{6}} \note{xi}{x_i}"
        + rf" = \frac{{{terms}}}{{6}} = \note{{res}}{{\tangle{{mean}}}}"
    )
    notes = {
        "mean": note(r"**Mittelwert** $\bar{x}$: der Durchschnitt aller Werte", COL["mean"]),
        "one": note(r"Gewicht $\frac{1}{n}$: jeder Wert zählt gleich viel", COL["one"]),
        "n": note("Anzahl der Werte, hier $n = 6$", COL["n"]),
        "sum": note(r"Summenzeichen: addiert alle Werte von $i = 1$ bis $6$", COL["sum"]),
        "xi": note(r"der einzelne Wert $x_i$ mit der Nummer $i$", COL["xi"]),
        "res": note("Ergebnis: der Mittelwert der aktuellen Werte", COL["mean"]),
    }
    return TangleLatex(
        latex=latex,
        parameters={"mean": lock(m, COL["mean"])},
        notes=notes,
        reveal_all_on_drag=False,
        theme="light",
    )


def var_widget(xs):
    m = xs.mean()
    v = xs.var(ddof=1)
    n1 = len(xs) - 1
    devs = " + ".join(f"({num(x)} - {num(m)})^{{2}}" for x in xs)
    latex = (
        r"\begin{aligned}"
        r"\note{var}{s^2} &= \frac{\note{gewicht}{1}}{\note{nm1}{n-1}}"
        r" \sum_{i=1}^{6} (\note{xi}{x_i} - \note{xbar}{\bar{x}})^{2} \\"
        + rf" &= \frac{{{devs}}}{{{n1}}} \\"
        + r" &= \note{res}{\tangle{var}}"
        r"\end{aligned}"
    )
    notes = {
        "var": note(r"**Varianz** $s^2$: mittlere quadrierte Abweichung vom Mittelwert", COL["var"]),
        "gewicht": note(r"Gewicht $\frac{1}{n-1}$: Stichprobenvarianz mit $n-1$ im Nenner", COL["one"]),
        "nm1": note(
            f"Freiheitsgrade: $n - 1 = {n1}$, weil der Mittelwert aus den Daten geschätzt wird",
            COL["n"],
        ),
        "xi": note(r"der einzelne Wert $x_i$ mit der Nummer $i$", COL["xi"]),
        "xbar": note(r"der Mittelwert $\bar{x}$ aller sechs Werte, berechnet in der ersten Formel", COL["mean"]),
        "res": note("Ergebnis: die Varianz der aktuellen Werte", COL["var"]),
    }
    return TangleLatex(
        latex=latex,
        parameters={"var": lock(v, COL["var"])},
        notes=notes,
        reveal_all_on_drag=False,
        theme="light",
    )


def sd_widget(xs):
    v = xs.var(ddof=1)
    s = np.sqrt(v)
    latex = (
        r"\note{sdname}{s} = \sqrt{\note{var}{\tangle{var}}}"
        r" = \note{res}{\tangle{sd}}"
    )
    notes = {
        "sdname": note(
            r"**Standardabweichung** $s$: Wurzel aus der Varianz, in derselben Einheit wie die Daten",
            COL["sd"],
        ),
        "var": note(r"**Varianz** $s^2$: Ergebnis der Varianz-Formel", COL["var"]),
        "res": note("Ergebnis: die Standardabweichung der aktuellen Werte", COL["sd"]),
    }
    return TangleLatex(
        latex=latex,
        parameters={"var": lock(v, COL["var"]), "sd": lock(s, COL["sd"])},
        notes=notes,
        reveal_all_on_drag=False,
        theme="light",
    )


def abweichungen_ui(xs):
    m = xs.mean()
    body = []
    for i, x in enumerate(xs, start=1):
        body.append(
            f"<tr><td>{i}</td><td>{x:g}</td><td>{x - m:.3g}</td><td>{(x - m) ** 2:.3g}</td></tr>"
        )
    body.append(
        f"<tr><td>Summe</td><td>{xs.sum():g}</td>"
        f"<td>{np.sum(xs - m):.3g}</td><td>{np.sum((xs - m) ** 2):.3g}</td></tr>"
    )
    head = (
        f'<tr><th>Nr</th><th style="color:{COL["xi"]}">Wert x<sub>i</sub></th>'
        f'<th style="color:{COL["mean"]}">Abweichung x<sub>i</sub> − x̄</th>'
        f'<th style="color:{COL["var"]}">quadriert</th></tr>'
    )
    return ui.HTML(
        '<table class="table table-sm"><thead>' + head + "</thead><tbody>"
        + "".join(body) + "</tbody></table>"
    )
