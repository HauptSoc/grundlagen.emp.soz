# Multivariate Regressionen: Animation von bivariaten zu bereinigten Effekten

Eine interaktive Shiny-App zur Visualisierung der Isolation von Effekten in Regressionsmodellen mit vier verschiedenen DAG-Szenarien.

## Beschreibung

Diese App zeigt, wie sich Regressionskoeffizienten und Korrelationen ändern, wenn wir von **bivariaten** (rohen) zu **multivariaten** (bereinigten) Modellen übergehen. Die Animation visualisiert, wie der Scatterplot von beobachteten Y-Werten zu residualen (bereinigten) Y-Werten gleitet.

### Die vier DAG-Szenarien

1. **Konfundierung (Confounder)**
   - Struktur: Z → X, Z → Y, direkter Effekt X → Y
   - **Bivariate Perspektive**: X und Y erscheinen korreliert (teilweise wegen Z)
   - **Partielle Perspektive**: Nach Kontrolle für Z wird die echte X-Y Beziehung sichtbar
   - Verwendet zur Causal Inference: **Controlling**

2. **Mediation (Vermittlung)**
   - Struktur: X → Z → Y
   - **Bivariate Perspektive**: Gesamteffekt (direkt + indirekt)
   - **Partielle Perspektive**: Nach Kontrolle für Z wird nur direkter Effekt sichtbar
   - Verwendet zur Causal Inference: **Stratification/Mediation Analysis**

3. **Scheinkorrelation (Spurious)**
   - Struktur: Z → X und Z → Y, aber kein direkter X-Y Effekt
   - **Bivariate Perspektive**: X und Y scheinen korreliert (wegen Z)
   - **Partielle Perspektive**: Nach Kontrolle für Z verschwindet Korrelation
   - Verwendet zur Causal Inference: **Blocking the Backdoor Path**

4. **Interaktion (Moderation)**
   - Struktur: Effekt von X auf Y hängt von Z ab
   - **Bivariate Perspektive**: Durchschnittlicher Effekt über alle Z-Werte
   - **Partielle Perspektive**: Durchschnittlicher X-Effekt (nicht stratifiziert)
   - Verwendet zur Causal Inference: **Effect Modification Detection**

## Features

- ✅ **Vier verschiedene DAG-Szenarien** mit klarer kausaltheoretischer Logik
- ✅ **Bivariate vs. Partielle Regression** nebeneinander sichtbar
- ✅ **Animation** zwischen rohen und bereinigten Werten (per Checkbox)
- ✅ **Metriken-Tabelle** mit Korrelationen und Regressionskoeffizienten
- ✅ **Farbcodierung** für Z-Gruppen (blau/orange)
- ✅ **Hover-Informationen** für Datenexploration
- ✅ **Fehlerbehandlung** für robuste Stabilität

## Installation & Nutzung

### Lokal starten (R-Session)

```r
shiny::runApp("c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi")
```

### Im Browser öffnen

Die App öffnet sich automatisch in `http://127.0.0.1:xxxx` (je nach Port).

## Dateien

| Datei | Beschreibung |
|-------|-----------|
| `app.R` | Haupteinsprungspunkt (lädt UI und Server) |
| `ui.R` | Benutzeroberfläche (Seitenleiste + Hauptbereich) |
| `server.R` | Backend-Logik (Daten, Modelle, Plots, Metriken) |
| `daten_generieren.R` | DAG-basierte Datengenerierungsfunktionen |
| `README.md` | Diese Datei |

## Code-Struktur

### Daten generieren
```r
# Vier Funktionen für verschiedene DAG-Szenarien
simulate_confounding_binary(n = 150)
simulate_mediation_binary(n = 150)
simulate_spurious_binary(n = 150)
simulate_interaction_binary(n = 150)
```

### Bivariate Regression
```r
lm(Y ~ X, data = df)
```

### Partielle Regression (mit Residuen)
```r
lm(Y ~ X + Z, data = df)
# oder
model_z_on_x <- lm(X ~ Z, data = df)
model_z_on_y <- lm(Y ~ Z, data = df)
residuals_X <- residuals(model_z_on_x)
residuals_Y <- residuals(model_z_on_y)
lm(residuals_Y ~ residuals_X)
```

## Pädagogischer Wert

Diese App unterstützt das Verständnis von:
- **Causal Inference**: Wie man Confounding, Mediation und Spurious Korrelationen erkennt
- **Multivariate Regression**: Warum zusätzliche Variablen in ein Modell aufnehmen sinnvoll ist
- **Residuelle Analyse**: Wie man "bereinigte" Zusammenhänge interpretiert
- **DAGs (Directed Acyclic Graphs)**: Visuelle Darstellung von Kausalstrukturen

## Technologie

- **Shiny**: Interaktive Web-App
- **Plotly**: Interaktive Visualisierungen
- **tidyverse**: Datenmanipulation
- **R base**: Regression (lm)

## Mögliche Erweiterungen

- [ ] Echte Plotly-Animation mit Frames (statt Checkbox)
- [ ] Confidence Intervals um Regressionslinien
- [ ] Multivariate Plots (3D Scatterplot mit X, Z, Y)
- [ ] Automatische Generierung von DAG-Diagrammen
- [ ] Export von Plots und Tabellen
- [ ] Verschiedene Datengrößen (n variabel)

## Kontakt & Feedback

Bei Fragen oder Verbesserungsvorschlägen: [Your Contact Info]

---

**Erstellt**: Juni 2026  
**Lizenz**: [Your License]
