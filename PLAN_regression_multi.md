# Plan: Shiny-App für multivariate Regressionen mit Animation

## Identifizierte Probleme im bestehenden Code

1. **Falscher Input-Name**: `input$show_partial` existiert nicht → heißt `show_residuals`
2. **Animation fehlt vollständig**: Button "Animation starten" hat keine Funktion
3. **Z-Behandlung inkonsistent**: Sollte durchgehend als `factor(Z)` genutzt werden
4. **DAG-Szenarien nicht unterschiedlich**: Alle Funktionen haben dieselbe Logik
5. **Keine echte partielle Regression**: Nur Checkbox, kein Animation zwischen Zuständen
6. **fehlende Datengenerierung**: App lädt ohne initialisierte Daten

## Geplante Lösungen

### 1. **daten_generieren.R** überarbeiten
- **Konfundierung**: Z → X, Z → Y (direkter Effekt). Bereinigung sollte X-Y Effekt verstärken/schwächen
- **Mediation**: X → Z → Y. Direkter Effekt wird schwächer nach Kontrolle für Z
- **Scheinkorrelation (Spurious)**: Z → X und Z → Y, aber kein direkter X → Y Effekt. Nach Kontrolle für Z: Korrelation nahe 0
- **Interaktion**: Effekt von X hängt von Z ab. Partielle Regression zeigt durchschnittlichen Effekt

### 2. **app.R** strukturieren
- Alle Daten-Funktionen `source()` in app.R
- UI und Server inline in `shinyApp(ui, server)`
- Oder: ui.R/server.R mit korrekten Input-Namen

### 3. **Animation mit Plotly implementieren**
- `plotly`-Frames für sanfte Übergänge zwischen zwei Zuständen
- **Start-Frame**: Scatterplot (X, Y), Linie: `Y ~ X`
- **End-Frame**: Scatterplot (X, resid(Y|Z)), Linie: partielle Regression
- ~25 Frames für 1-2 Sekunden Animation
- Linear interpolierte Übergänge für Y-Werte

### 4. **Server-Logik**
- `eventReactive()` für "Neue Daten generieren"
- `eventReactive()` für "Animation starten"
- Metriken-Tabelle: Korrelationen und Regressionskoeffizienten vor/nach Kontrolle
- Fehlerbehandlung mit `tryCatch()`

### 5. **UI-Verbesserungen**
- Klare Eingaben: DAG-Typ, Buttons
- Plotly-Output für Animation
- Metriken-Tabelle
- Ggf. bslib für modernes Design (optional)

## Implementierungsschritte

1. ✓ Probleme analysieren
2. → `daten_generieren.R` überarbeiten
3. → `ui.R` korrigieren/vereinfachen  
4. → `server.R` neu schreiben mit Animation
5. → Testen und verifizieren

## Offene Fragen

- Automatische Datengenerierung beim App-Start? (Empfehlung: Ja, dann können Nutzer direkt animieren)
- Animation-Dauer: 1-2 Sekunden?
- Sollen beide Regressionslinien während Animation sichtbar sein, oder nur aktuelle?
