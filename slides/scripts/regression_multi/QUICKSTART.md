# Quickstart Guide: Multivariate Regression Animation

## ⚡ Sofort Starten

```r
# In R-Konsole eingeben:
shiny::runApp('c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi')
```

Die App öffnet sich automatisch im Browser.

---

## 🎯 Die 5 Schritte zum Verständnis

### 1. **Daten generieren**
   - Klick: `Neue Daten generieren`
   - Sehen Sie einen Scatterplot mit:
     - Kleine blaue/orange Punkte (Beobachtungen)
     - Blaue Linie (Bivariate Regression)
     - Große Diamanten (Mittelwerte der Z-Gruppen)

### 2. **DAG-Szenario auswählen**
   - Wählen Sie eines der 4 Szenarien:
     - **a) Konfundierung**: Z verursacht X und Y
     - **b) Mediation**: X → Z → Y (Z vermittelt)
     - **c) Scheinkorrelation**: Z verursacht X und Y, aber nicht direkt X → Y
     - **d) Interaktion**: Effekt von X hängt von Z ab
   - Neue Daten generieren (klick oben)

### 3. **Animation starten**
   - Klick: `Animation starten`
   - Sie sehen:
     - **Play-Button** unten links
     - **Slider** zum manuellen Durchschrollen
   - Klick Play oder Slider bewegen → **Sanfte Animation**

### 4. **Während Animation beobachten:**
   - 📍 **Punkte**: Gleiten von (X, Y) zu (X|Z, Y|Z)
   - 📍 **Mittelwerte**: Diamanten bewegen sich, Z-Gruppen nähern sich an
   - 📍 **Linie**: Wechselt Farbe: Blau (bivariate) → Rot (partielle)

### 5. **Metriken interpretieren**
   - Tabelle unten zeigt:
     - **Korrelation (X, Y)**: Veränderung durch Kontrolle von Z
     - **Regressionskoeffizient (X)**: Ändert sich beim Übergang

---

## 🎨 Was bedeuten die Farben?

| Element | Farbe | Bedeutung |
|---------|-------|-----------|
| Z=0 Punkte | Blau (#1f77b4) | Erste Gruppe |
| Z=1 Punkte | Orange (#ff7f0e) | Zweite Gruppe |
| Bivariate Linie | Blau | Y ~ X (roh) |
| Partielle Linie | Rot | Y ~ X \| Z (bereinigt) |
| Mittelwert Z=0 | Blau Diamant | M(X\|Z=0), M(Y\|Z=0) |
| Mittelwert Z=1 | Orange Diamant | M(X\|Z=1), M(Y\|Z=1) |

---

## 💡 Was ist die Animation?

### Der Prozess:
Die Animation zeigt mathematisch, wie wir aus **rohen Daten** zu **bereinigten Daten** übergehen:

```
ANFANG (t=0):        MITTE (t=0.5):      ENDE (t=1):
Y vs X               Übergang            Y|Z vs X|Z
Roh-Korrelation      (interpoliert)      Partielle Korrelation
Mittelwerte getrennt Mittelwerte nähern  Mittelwerte zusammen
                     sich an
```

### Die Interpolation:
```r
# Für jeden Frame t von 0 bis 1:
Y_animiert = (1 - t) * Y_roh + t * Y_residual
X_animiert = (1 - t) * X_roh + t * X_residual
```

- Bei t=0: Sie sehen die **rohen Daten** (bivariate Regression)
- Bei t=1: Sie sehen die **bereinigten Daten** (partielle Regression)

---

## 📊 Die 4 DAG-Szenarien Erklärt

### a) **Konfundierung (Confounder)**
```
        Z
       / \
      v   v
      X → Y
```
- **Bivariate**: X und Y korreliert (wegen Z!)
- **Partielle**: Nach Kontrolle für Z, echter X-Effekt sichtbar
- **Mittelwerte**: Nähern sich an, weil Z die Gruppe trennt

**Beispiel**: Alter (Z) → Arbeitserfahrung (X) und Gehalt (Y)

### b) **Mediation (Vermittlung)**
```
      X → Z → Y
        (schwach direkt)
```
- **Bivariate**: Großer X-Y Effekt (direkt + indirekt via Z)
- **Partielle**: Nach Kontrolle für Z, nur direkter Effekt bleibt
- **Effekt wird kleiner**: Der indirekte Weg ist blockiert

**Beispiel**: Training (X) → Kompetenz (Z) → Gehalt (Y)

### c) **Scheinkorrelation (Spurious)**
```
      Z
     / \
    v   v
    X   Y
    (kein direkter Link)
```
- **Bivariate**: X und Y scheinen korreliert
- **Partielle**: Nach Kontrolle für Z, Korrelation verschwindet!
- **Wichtig**: Backdoor-Pfad wird geschlossen

**Beispiel**: Alter (Z) → Erfahrung (X) und Gehalt (Y), aber nicht direkt (X → Y)

### d) **Interaktion (Moderation)**
```
      X → Y
      Z → Y
      X*Z → Y (Effekt hängt von Z ab)
```
- **Bivariate**: Durchschnittlicher X-Effekt
- **Partielle**: Durchschnittlicher X-Effekt (aber mit Z kontrolliert)
- **Unterschied**: Zeigt Durchschnitt über Z-Gruppen

**Beispiel**: Trainingsintensität (X), Erfahrungslevel (Z), Effekt hängt von Z ab

---

## 🔍 Interaktive Erkundung

### Versuchen Sie dies:

1. **Konfundierung + Animation**
   - Schauen Sie, wie die Mittelwerte (Diamanten) zusammenkommen
   - Die X-Effektgröße wird kleiner (Z wird kontrolliert)

2. **Scheinkorrelation + Animation**
   - Die Korrelation wird nahe Null!
   - Die scheinbare Beziehung war nur durch Z

3. **Mediation + Animation**
   - Der Effekt wird kleiner (Z vermittelt den Effekt)
   - Aber nicht auf Null (noch direkter Effekt)

4. **Interaktion + Animation**
   - Der Effekt ändert sich kaum (Z modifiziert, blockiert nicht)
   - Die Punkte bleiben unterschiedlich geordnet

---

## 🎓 Pädagogische Insights

### Was Sie lernen:

1. **Causal Inference Basics**
   - Confounding vs. Mediation vs. Spurious
   - Warum Kontrollen wichtig sind

2. **Multiple Regression**
   - Warum zusätzliche Variablen den Effekt ändern
   - Bivariate ≠ Multivariate

3. **Residuen-Konzept**
   - Was bedeutet "controlling for Z"?
   - Mathematisch: X|Z und Y|Z sind die Residuen

4. **DAG-Denken**
   - Visuelle Kausalmodelle
   - Backdoor- vs. Frontdoor-Pfade

---

## ⚙️ Technische Details

### Frame-Rate
- **50 Frames** für glatte Animation
- **100ms** pro Frame = **~5 Sekunden** für volle Animation
- Spielen Sie den Slider manuell für mehr Kontrolle

### Daten-Größe
- **n = 150** Beobachtungen (standard)
- Größe: 2 Variablen (X, Y) + 1 Gruppierungsvariable (Z)

### Browser
- ✅ Funktioniert in allen modernen Browsern
- Nutzt **Plotly.js** für Interaktivität

---

## 🆘 Troubleshooting

### App startet nicht
```r
# Stellen Sie sicher, dass Sie im richtigen Verzeichnis sind:
setwd('c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi')

# Oder absoluten Pfad verwenden:
shiny::runApp('c:/GIT/Grundlagen EmpSoz/slides/scripts/regression_multi')
```

### Animation läuft nicht
- Klick: `Animation starten`
- Dann: Play-Button unten links im Plot
- Oder: Slider manuell verschieben

### Fehler in der Konsole
- Müssen Sie die App mit `Escape` beenden?
- In R: `Ctrl+C` drücken
- Browser Tab schließen und neu laden

---

## 📚 Weitere Ressourcen

- `README.md` - Ausführliche Dokumentation
- `CHANGES.md` - Was neu ist
- `TESTING.md` - Testing-Anleitung
- `daten_generieren.R` - Datengenerierungs-Code

---

**Viel Spaß beim Erkunden! 🚀**
