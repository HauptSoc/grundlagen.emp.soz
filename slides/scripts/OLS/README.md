# OLS Shiny App

Diese App demonstriert lineare Regression interaktiv.

## Inhalte
- manuelle Regressionsgerade über Slider für Intercept und Steigung
- OLS-Gerade auf Basis des aktuellen Samples
- Auswahl von Punkten zur Residuen-Darstellung
- Zufallsdaten mit variierenden Modellparametern
- optionale Anzeige der wahren Parameter

## Lokaler Start

```r
shiny::runApp("c:/GIT/Grundlagen EmpSoz/slides/scripts/OLS")
```

## Shiny Server

Den kompletten Ordner `slides/scripts/OLS` als App-Verzeichnis auf den Shiny Server kopieren. Die App benötigt nur die Dateien im Verzeichnis und keine externen Daten.

## Abhängigkeiten

- shiny
- dplyr
- plotly
- tibble
