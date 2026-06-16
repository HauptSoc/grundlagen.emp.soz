# Regressionsgeraden Ein-/Ausblenden Feature

## Übersicht

Neue Checkboxes ermöglichen es Nutzern, die Regressionsgeraden unabhängig voneinander ein- oder auszublenden.

## Features

### UI-Elemente

```
┌─────────────────────────────────────┐
│  Regressionsgeraden                 │ (gelber Hintergrund)
├─────────────────────────────────────┤
│ ☐ Bivariate Gerade anzeigen ...     │
│ ☐ Partielle Gerade anzeigen ...     │
│ Hinweis: Standardmäßig sind ...     │
└─────────────────────────────────────┘
```

### Standard-Zustand

- **Bivariate Gerade**: AUSGEBLENDET (value = FALSE)
- **Partielle Gerade**: AUSGEBLENDET (value = FALSE)
- **Punkte**: IMMER SICHTBAR
- **Mittelwerte**: IMMER SICHTBAR

### Nutzer-Kontrolle

Jede Checkbox kann unabhängig aktiviert/deaktiviert werden:

| State | Bivariate | Partial | Effekt |
|-------|-----------|---------|--------|
| Standard | ☐ | ☐ | Nur Punkte & Mittelwerte sichtbar |
| Nur Bivariate | ☑ | ☐ | Blau-Linie sichtbar |
| Nur Partial | ☐ | ☑ | Rot-Linie sichtbar |
| Beide | ☑ | ☑ | Beide Linien sichtbar (zum Vergleich) |

## Implementierung

### UI-Code

```r
div(
  class = "line-controls",
  h4("Regressionsgeraden"),
  checkboxInput(
    "show_bivariate_line",
    "Bivariate Gerade anzeigen (Y ~ X, blau)",
    value = FALSE  # Standard: ausgeblendet
  ),
  checkboxInput(
    "show_partial_line",
    "Partielle Gerade anzeigen (Y ~ X | Z, rot)",
    value = FALSE  # Standard: ausgeblendet
  )
)
```

### Server-Code

```r
# TRACE 2: Bivariate Regressionslinie (NUR wenn aktiviert)
if (isTRUE(input$show_bivariate_line)) {
  p <- p %>%
    add_trace(
      x = x_seq,
      y = pred_biv,
      type = "scatter",
      mode = "lines",
      line = list(color = "blue", width = 3),
      name = "Bivariate Regression (Y ~ X)"
    )
}

# TRACE 3: Partielle Regressionslinie (NUR wenn aktiviert)
if (isTRUE(input$show_partial_line)) {
  p <- p %>%
    add_trace(
      x = x_seq,
      y = pred_part,
      type = "scatter",
      mode = "lines",
      line = list(color = "red", width = 3),
      name = "Partielle Regression (Y ~ X | Z)"
    )
}
```

## Pädagogischer Wert

### Für Anfänger
- **Standard (keine Linien)**: Fokus auf die Punkte-Bewegung
- **Nur Punkte**: Einfacher, nicht überladen
- **Schrittweise Komplexität**: Erst Punkte, dann Linien hinzufügen

### Für Vergleiche
- **Nur Bivariate**: Rohe Beziehung sehen
- **Nur Partial**: Bereinigte Beziehung sehen
- **Beide zusammen**: Direkter Vergleich, sichtbarer Unterschied

### Für verschiedene Szenarien

**Konfundierung:**
- Bivariate Linie stärker als Partial → Z ist ein Confounder
- Difference deutlich sichtbar

**Mediation:**
- Bivariate Linie stärker als Partial → Z vermittelt Effekt
- Effekt wird durch Kontrolle für Z schwächer

**Scheinkorrelation:**
- Bivariate Linie vorhanden
- Partial Linie verschwindet → Spurious!
- Dramatischer Unterschied

**Interaktion:**
- Linien unterscheiden sich kaum
- Stattdessen: Gepunktete Linien für Z-Gruppen nutzen

## Interaktive Workflows

### Workflow 1: Verstehen der Punkte
```
1. Daten generieren
2. Nur Slider nutzen (keine Linien)
3. Beobachte: Wie bewegen sich Punkte?
4. Beobachte: Wie nähern sich Mittelwerte an?
```

### Workflow 2: Mit Linien vergleichen
```
1. Daten generieren
2. Aktiviere: Bivariate Gerade
3. Beobachte: Welche Steigung hat die Linie?
4. Aktiviere auch: Partielle Gerade
5. Vergleiche: Wie unterscheiden sich die Linien?
```

### Workflow 3: Animation mit Vergleich
```
1. Aktiviere beide Geraden
2. Starte Animation
3. Beobachte: Wie ändern sich die beiden Linien?
4. Eine Linie bleibt stabil, andere ändert sich? → Mediation
5. Beide ändern sich? → Confounder
6. Eine verschwindet? → Spurious
```

## Reaktivität

- ✅ Checkboxes sind reaktiv
- ✅ Plot aktualisiert sich sofort bei Änderung
- ✅ Keine Neugenerierung von Daten nötig
- ✅ Flüssig und responsiv
- ✅ Funktioniert während Animation

## Vorher/Nachher

### Vorher (v4.0)
- Beide Linien IMMER sichtbar
- Keine Kontrolle für Nutzer
- Manchmal überladen
- Schwer, Unterschiede zu sehen

### Nachher (v5.0)
- Beide Linien DEFAULT ausgeblendet
- Nutzer entscheidet selbst
- Minimalistisch beim Start
- Klare, fokussierte Anzeige
- Einfach zu vergleichen

## Browser-Kompatibilität

✅ Alle Browser (reine HTML-Checkboxes)  
✅ Mobile Geräte  
✅ Accessibility (Standard Shiny checkboxes)

## Performance

- ✅ Keine Performance-Auswirkung
- ✅ Nur bedingte Traces (wenn aktiviert)
- ✅ Schnelles Rendern
- ✅ Geringe CPU-Last

---

**Feature**: Regression Line Toggle  
**Version**: 1.0  
**Status**: ✅ Implementiert und getestet  
**Effekt**: Bessere Kontrolle und pädagogischer Fokus
