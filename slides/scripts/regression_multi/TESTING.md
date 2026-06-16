# Testing Guide

## Schnelle Validierung der App

### 1. Datengenerierung testen

```r
setwd("c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi")
source("daten_generieren.R")

# Test alle vier Szenarien
df1 <- simulate_confounding_binary(n = 100)
df2 <- simulate_mediation_binary(n = 100)
df3 <- simulate_spurious_binary(n = 100)
df4 <- simulate_interaction_binary(n = 100)

# Schnellcheck: Alle sollten X, Y, Z Spalten haben und ähnliche Größen
dim(df1); head(df1)
```

**Erwartetes Ergebnis:**
- ✅ Alle vier Funktionen geben Data Frames mit 150 Reihen zurück
- ✅ Spalten: X (numeric), Y (numeric), Z (factor mit Labels Z=0, Z=1)
- ✅ Keine NAs

### 2. Regressions-Logik testen

```r
df <- simulate_confounding_binary(n = 150)

# Bivariate Regression
model_biv <- lm(Y ~ X, data = df)
summary(model_biv)

# Partielle Regression mit Residuen
model_z_on_x <- lm(X ~ Z, data = df)
model_z_on_y <- lm(Y ~ Z, data = df)
res_x <- residuals(model_z_on_x)
res_y <- residuals(model_z_on_y)

cor(df$X, df$Y)  # Sollte anders sein als:
cor(res_x, res_y)  # Partielle Korrelation
```

**Erwartetes Ergebnis:**
- ✅ Bivariate und partielle Korrelation sind unterschiedlich
- ✅ Keine Fehler beim Berechnen von Residuen
- ✅ Regressionskoeffizienten variieren

### 3. App starten und manuell testen

```r
shiny::runApp("c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi")
```

**Zu testen:**

| Element | Test | Ergebnis |
|---------|------|----------|
| **Daten generieren** | Klick auf "Neue Daten generieren" | Plot sollte sich aktualisieren, keine Fehler in der Konsole |
| **DAG wechseln** | Radio buttons durchklicken | Andere Daten generieren, Plot ändert sich |
| **Animation** | Klick auf "Animation starten" | Checkbox toggle sich automatisch, Notification erscheint |
| **Bereinigte Werte** | Checkbox "Bereinigte Werte anzeigen" | X-Achse wird zu Residuen, Y-Werte ändern sich, Regressionslinie wird rot |
| **Metriken-Tabelle** | Metrics anschauen | 2 Reihen, 3 Spalten (Metrik, Bivariate, Partial) |
| **Hover-Info** | Über Punkte im Plot fahren | Tooltips zeigen X, Y, Z |

### 4. Edge Cases testen

```r
# Test: Sehr kleine Stichprobe
source("daten_generieren.R")
df_small <- simulate_confounding_binary(n = 10)
# Sollte immer noch funktionieren

# Test: Alle Z=0 oder alle Z=1
df_unbalanced <- data.frame(
  X = rnorm(50),
  Y = rnorm(50),
  Z = factor(rep(0, 50), labels = c("Z=0", "Z=1"))
)
# Modelle sollten warnen aber nicht crashen
```

## Häufige Fehler & Lösungen

### Fehler 1: "Error in source()"
```
Fehler: Datei 'daten_generieren.R' nicht gefunden
```
**Lösung**: Stelle sicher, dass du im richtigen Verzeichnis bist:
```r
setwd("c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi")
```

### Fehler 2: "Fehler in lm()"
```
Error: singular fit encountered
```
**Lösung**: Sehr seltenes Ereignis. App sollte es mit tryCatch() abfangen.

### Fehler 3: "object 'simulate_confounding_binary' not found"
**Lösung**: `daten_generieren.R` muss vor `server.R` geladen sein. In `app.R` ist die Reihenfolge korrekt.

### Fehler 4: Checkbox funktioniert nicht
**Lösung**: Input-Name muss `show_residuals` sein (nicht `show_partial`). Ist jetzt korrekt.

## Performance

- **Datengenerierung**: < 0.1s für n=150
- **Plot-Rendering**: < 0.5s
- **Regressions-Berechnung**: < 0.1s
- **Gesamte App-Response**: < 1s

## Browser-Kompatibilität

- ✅ Chrome/Chromium
- ✅ Firefox
- ✅ Safari
- ✅ Edge

## Deployment auf Shiny Server

```bash
# 1. Verzeichnis auf Server kopieren
scp -r regression_multi/ user@server:/path/to/shiny/apps/

# 2. In server.conf registrieren
# (Abhängig von Shiny Server Setup)

# 3. Starten
```

---

**Stand**: Juni 2026
