# Plan: Verbesserungen der Shiny App für Konfidenzintervalle

## Übersicht
Die App `slides/scripts/inference/app.R` soll um drei Verbesserungen erweitert werden:
1. Berechnung der Grenzen visualisieren
2. Tab "Verteilungen" strukturiert unterteilen
3. "Signifikanztest"-Modus hinzufügen

---

## 1. Berechnung des Konfidenzintervalls anzeigen

### Anforderung
Im Tab "Verteilungen" soll zwischen dem Distributions-Plot und der Grenzen-Tabelle eine Berechnung angezeigt werden, die zeigt, wie die Grenzen entstehen. Besonder Fokus auf kritische Werte.

### Implementierung
- **Neue Funktion**: `calculation_text()` erstellen, die für jeden Parameter-Typ eine Formeldisplay generiert
- **Inhalte je Parameter-Typ**:
  - **Mittelwert (t-Verteilung)**: 
    - Formel: `CI = Schätzung ± t_crit(α, df) × SE`
    - Anzeige: Konkrete Werte für t_crit, Schätzung, SE
  - **Wahrscheinlichkeit (Normal)**:
    - Formel: `CI = p̂ ± z_crit(α) × SE`
  - **Varianz (Chi-Quadrat)**:
    - Formel mit Chi²-Quantilen
  - **F-Verteilung, etc.**: entsprechend adaptiert
- **Format**: HTML-Box mit Formel + konkrete Werte
- **Platzierung**: Im UI nach `dist_plot` und vor `bounds_table_output`

---

## 2. Tab "Verteilungen" in Abschnitte unterteilen

### Anforderung
Der Tab soll strukturiert sein in:
- **A) Berechnung des Konfidenzintervalls für die Referenzstichprobe**
  - Enthält: dist_plot + calculation_text + bounds_table
- **B) Verteilung der Parameter aus den gezogenen Stichproben**
  - Enthält: hist_plot (Histogramm der Schätzwerte)

### Implementierung
- **Layout**: Einsatz von `layout_columns()` oder `navset_card_*` mit zwei Unterpanels
- **Abschnitt A**: 
  - Überschrift "A) Berechnung des Konfidenzintervalls für die Referenzstichprobe"
  - dist_plot
  - calculation_text (neue Ausgabe)
  - bounds_table
- **Abschnitt B**:
  - Überschrift "B) Verteilung der Parameter aus den gezogenen Stichproben"
  - hist_plot

---

## 3. Signifikanztest-Modus

### Anforderung
- **Neuer Schalter** im linken Sidebar: `input_switch("significance_test", "Signifikanztest", value = FALSE)`
- **Modus-Umschaltung**:
  - Ist der Schalter **AUS** (default): Aktuelles Verhalten (Konfidenzintervall-Modus)
  - Ist der Schalter **AN**: 
    - Parameter-Eingaben bleiben (z.B. "wahre" Parameterwerte)
    - **Zusätzliche neue Eingaben**:
      - `empirischer_parameterwert`: numerischer Input (z.B. "Empirischer Parameterwert")
      - `empirischer_standardfehler`: numerischer Input (z.B. "Empirischer Standardfehler")
    - **Keine Stichproben**: Kein Resampling nötig, nur eine Berechnung
    - **Visualisierung**: 
      - Die Referenz-Verteilung (dist_plot) wird mit dem empirischen Wert markiert
      - Der empirische Wert wird als vertikale Linie eingezeichnet
      - Der **p-value** wird als Fläche außerhalb der Linie verdeutlicht
    - **Tabellen-Output**: Zeigt p-value statt Konfidenzintervall-Grenzen
    - **Histogram-Output**: Entfällt oder zeigt nur den empirischen Wert

### Technische Details

#### Neue Eingabe-Logik
```r
# Im param_inputs Reactive
if (input$significance_test) {
  # Zeige Parameter (aber inaktiv/schreibgeschützt falls gewünscht)
  # + empirischer_parameterwert
  # + empirischer_standardfehler
} else {
  # Aktuelles System (Parameter + Stichprobengrößen)
}
```

#### p-value Berechnung
- Für jeden Distributions-Typ p-value berechnen:
  - **t-Verteilung**: `p = 2 * (1 - pt(abs(t_stat), df))`
  - **Normal**: `p = 2 * (1 - pnorm(abs(z_stat)))`
  - **Chi², F**: entsprechende quantile functions
- `t_stat = (empirischer_parameterwert - geschätzter_wert) / empirischer_standardfehler`

#### Visualisierungs-Änderung
- `plot_distribution()` um `significance_test`-Parameter erweitern
- Wenn `significance_test = TRUE`:
  - Empirischen Wert mit **dicke rote Linie** einzeichnen
  - Flächen außerhalb des empirischen Wertes farbig markieren (α/2 Flächen)
  - p-value als Text anzeigen
- Wenn `significance_test = FALSE`: Aktuelles Verhalten (CI-Grenzen)

#### Bounds-Tabelle für Signifikanztest
- Statt `Untere Grenze | Obere Grenze`
- Zeige: `p-value | test_statistic`

---

## Implementierungs-Schritte

1. **Neue Hilfsfunktion `calculation_text()`** schreiben
   - Parameter-Type-basierte Formel-Generierung
   - HTML-Output für Display

2. **UI-Struktur ändern**:
   - Sidebar um `input_switch("significance_test")` erweitern
   - `param_inputs` conditional rendern (basierend auf `significance_test`)
   - Tab "Verteilungen" in zwei Unterbereiche teilen
   - calculation_text Output einbauen

3. **`plot_distribution()` erweitern**:
   - `significance_test`-Parameter hinzufügen
   - p-value Berechnung
   - Visualisierung anpassen

4. **Server-Logik anpassen**:
   - Neue Reactive-Werte für empirische Parameterwerte
   - `bounds_table_output` sollte `significance_test` berücksichtigen
   - `hist_plot` bei Signifikanztest ggf. ausblenden oder anders gestalten

5. **Testen** bei verschiedenen Parametern

---

## Offene Fragen zur Klärung
1. **Abschnitt B (Histogram)**: Soll das Histogram auch im Signifikanztest-Modus angezeigt werden? Wenn ja, was soll es zeigen?
2. **Parameter-Eingaben im Sig-Test**: Sollen die ursprünglichen Parameter abgedimmt/deaktiviert sein oder vollständig versteckt?
3. **Kritische Werte**: Sollen diese auch im Signifikanztest-Tab angezeigt werden (zu Vergleichszwecken)?
