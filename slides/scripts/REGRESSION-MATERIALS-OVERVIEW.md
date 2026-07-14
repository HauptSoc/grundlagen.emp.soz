# Umfassende Regressions-Lernmaterialien

## 📚 Erstellte Dokumente

### 1. **Quarto-Dokumente (für Vorlesungsfolien)**

#### `inference-regression-bivariate.qmd`
**Thema:** Bivariate Regression mit Fokus auf Standardfehler & KI

**Inhalte:**
- Überblick über 3 bivariate Modelle (sex, east, age)
- Detailliertes Beispiel: sat2 ~ age
  - Regressionsgleichung: sat2 = 5.49 + 0.0131 × age
  - Schritt-für-Schritt KI-Berechnung
  - Standardfehler-Berechnung von Hand
  - Kritischer t-Wert und Freiheitsgrade
- Visualisierung mit Konfidenzband
- Interpretation für Studierende

**Für wen:** Einführende Statistik, Regression 1

**Zeitumfang:** 30-45 Minuten Vorlesung

---

#### `inference-regression-multivariate.qmd`
**Thema:** Multivariate Regression mit Interaktion & Confounding

**Inhalte:**
- Das multivariate Modell: sat2 ~ sex*east + age + sin11_cat
- Regressionsergebnisse vollständig dokumentiert
- Fokus auf age-Koeffizient im multivariaten Kontext
  - Partielle Effekte erklärt
  - Warum SE größer ist (Multikollinearität)
  - KI-Berechnung (gleich wie bivariat, aber anderer SE)
- **Confounding-Analyse:** Warum bivariater ≠ multivariater Effekt?
  - 80% des Effekts war durch sin11_cat!
  - Mechanismus erklären
  - Praktische Implikationen
- Tabelle: Vergleich bivariat vs. multivariat
- Zusammenfassung wichtiger Lektionen

**Für wen:** Fortgeschrittene Statistik, Regression 2, Kausalität

**Zeitumfang:** 60-90 Minuten Vorlesung

---

### 2. **Cheat Sheet**

#### `regression-comparison-cheatsheet.md`
**Thema:** Schnelle Referenz für Regressions-Formeln

**Inhalte:**
- Schnelle Formelübersicht
- Standardfehler-Formeln (bivariate & multivariate)
- Konfidenzintervall-Formeln
- Kritische t-Werte (90%, 95%, 99%)
- Praktische Beispiele mit Zahlen
- Häufige Fehler und Lösungen
- R-Code Snippets
- Checklisten vor/nach Regression

**Für wen:** Schnelle Nachschlagwerk für alle

**Format:** Druckbar, A4 geeignet

---

### 3. **Andere erstellte Materialien**

- `inference-freundschaft-plus.qmd` — Odds Ratio Beispiel
- `inference-ttests.qmd` — Mittelwertdifferenzen
- `graph-boxenstopp.R` — Graphen mit Konfidenzintervallen
- `ttest-cheatsheet.md` — t-Test Referenz

---

## 🎯 Lernziele nach den Materialien

### Nach „Bivariate Regression":
✓ Regressionsgleichung interpretieren  
✓ Standardfehler verstehen (Formel, Bedeutung, Berechnung)  
✓ Konfidenzintervall von Hand berechnen  
✓ t-Werte und p-Werte interpretieren  
✓ Präzision vs. Unsicherheit verstehen  

### Nach „Multivariate Regression":
✓ Partielle Effekte vs. Roh-Effekte unterscheiden  
✓ Confounding erkennen und erklären  
✓ Warum SE in multivariaten Modellen unterschiedlich  
✓ Multikollinearität verstehen  
✓ Kausalität in Beobachtungsstudien kritisch bewerten  

---

## 📊 Numerische Ergebnisse (für Beispiele)

### Bivariate Regression: sat2 ~ age

```
Koeffizient:      β = 0.0131  (pro Lebensjahr)
Standardfehler:   SE = 0.0015
Freiheitsgrade:   df = 26,518
t-Statistik:      t = 8.54
p-Wert:           p < 0.001
R²:               0.0027

95%-KI:           [0.0101, 0.0161]

Interpretation:
  Für jedes zusätzliche Lebensjahr steigt die Zufriedenheit um
  0.01 bis 0.016 Punkte (mit 95% Konfidenz).
```

### Multivariate Regression: sat2 ~ sex*east + age + sin11_cat

```
Koeffizient:      β = 0.0027  (pro Lebensjahr, kontrolliert)
Standardfehler:   SE = 0.0018
Freiheitsgrade:   df = 17,317
t-Statistik:      t = 1.52
p-Wert:           p = 0.130
R²:               0.1637

95%-KI:           [-0.00079, 0.00615]

Interpretation:
  Nach Kontrolle für Geschlecht, Ost/West und Beziehungskategorie:
  Der age-Effekt ist klein, negativ oder null, und nicht signifikant.
  Die Daten sind kompatibel mit null Effekt.
```

### Confounding-Analyse

```
Bivariater Effekt:      0.0131
Multivariater Effekt:   0.0027
Confounding-Anteil:     0.0104  (79% des bivariaten Effekts!)

Fazit: 80% des scheinbaren age-Effekts war eigentlich
       ein Effekt unterschiedlicher Beziehungskategorien
       in verschiedenen Altersgruppen.
```

---

## 🔑 Schlüsselkonzepte

### 1. Standardfehler (SE)
- Misst Unsicherheit der Schätzung
- Wird durch große Stichproben kleiner
- Wird durch hohe Varianz größer
- Formel: SE = √(σ² / Varianz in X)

### 2. Konfidenzintervall (KI)
- Bereich mit 95% Wahrscheinlichkeit für wahren Parameter
- Formel: β ± t* × SE
- Enthält KI 0 → nicht signifikant
- Schmales KI → präzise Schätzung

### 3. Partielle Effekte
- Effekt kontrolliert für andere Variablen
- Näher an kausaler Interpretation
- Können stark vom bivariaten Effekt unterscheiden

### 4. Confounding
- Drittvariable Z beeinflusst sowohl X als auch Y
- Erzeugt spurious Assoziation
- Bivariater Effekt ≠ wahrer Effekt
- Lösung: Z kontrollieren im multivariaten Modell

### 5. Multikollinearität
- Wenn Prädiktoren untereinander korreliert sind
- Führt zu größerem SE (weniger Präzision)
- Koeffizienten können instabil sein
- Nicht ignorieren, aber akzeptabel mit theoretischer Begründung

---

## 🎓 Unterrichtsempfehlungen

### Sequenz:
1. **Woche 1-2:** t-Tests (Mittelwertdifferenzen)
2. **Woche 3-4:** Bivariate Regression
3. **Woche 5-6:** Multivariate Regression
4. **Woche 7-8:** Confounding & Kausalität

### Methode:
- Erst Theorie (Formeln, Konzepte)
- Dann praktische Berechnung (mit Daten)
- Dann Interpretation (Was bedeutet es?)
- Dann kritisches Denken (Wann gültig?)

### Mit Studierenden:
- SE mit verschiedenen n berechnen lassen
- Confounding-Beispiele brainstormen
- "Warum macht das Sinn?" Fragen
- Verschiedene Modelle vergleichen

---

## ✅ Checkliste für Lehrmaterial-Nutzung

- [ ] Alle Quarto-Dateien heruntergeladen
- [ ] In Vorlesung/Vortragsfolien eingebunden
- [ ] Zahlen-Beispiele verstanden
- [ ] Studentische Fragen antizipiert
- [ ] Zusatz-Übungen vorbereitet
- [ ] Cheat Sheets gedruckt/digital verfügbar

---

## 📞 Häufige Studierende-Fragen

**F: Warum wird der SE größer im multivariaten Modell?**  
A: Wegen Multikollinearität. Die andere Variable erklärt einen Teil von age, daher wird age weniger präzise geschätzt. Das ist ein Trade-off für Confounding-Kontrolle.

**F: Bedeutet ein KI, das 0 enthält, dass es keine Beziehung gibt?**  
A: Nein! Es bedeutet, dass wir mit 95% Konfidenz nicht zwischen 0 und dem geschätzten Wert unterscheiden können. Es könnte eine schwache Beziehung geben.

**F: Welche Variablen sollte ich kontrollieren?**  
A: Theoretisch begründete Confounder, die beide mit X und Y assoziiert sind. Nicht alles, was verfügbar ist!

**F: Was ist der Unterschied zwischen partiellen und standardisierten Koeffizenten?**  
A: Partiell = Effekt auf Originalskala (zB. Punkte pro Jahr). Standardisiert = beide Variablen in z-Scores, Effekt in SD-Einheiten.

---

## 📈 Visualisierungen in den Materialien

1. **Konfidenzband-Plot:** Zeigt Unsicherheit über Wertebereich
2. **KI-Vergleich-Plot:** Bivariat vs. Multivariat direkt vergleichen
3. **Boxplot der Confounder:** Visualisiert warum Confounding existiert
4. **Streuplot mit Regressionslinie:** Zeigt rohe Daten + Fit

---

## 🚀 Erweiterte Themen (für fortgeschrittene Kurse)

- Diagnostik: Residuenplots, Heteroskedastizität
- Interaktionen richtig interpretieren
- Dummy-Variablen: Referenzkategorien-Effekte
- Predicted Values und Marginal Effects
- Robustheit: Verschiedene Modellspezifikationen
- Causal Inference: DAGs und Confounding systematisch
- Machine Learning: Lasso, Ridge, Elastic Net für variable selection

---

## 📚 Weiterführende Ressourcen

- UCLA IDRE: Regression Diagnostics
- Andrew Gelman: Regression and other stories
- Judea Pearl: Causal Inference
- Kieran Healy: Data Visualization
