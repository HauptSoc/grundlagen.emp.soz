# Plan: App-Fehler beheben

## Problem 1: Layout - Tabs in Mitte, nicht im rechten Panel

### Diagnose
Das aktuelle Layout nutzt `layout_columns(col_widths = c(6, 6))`, aber die Tabs sind direkt nach dem ersten card definiert.
Das führt dazu, dass die Tabs trotz neuer Breiten nicht richtig positioniert sind.

### Lösung
- `layout_columns()` mit korrekter Struktur verwenden:
  ```
  layout_columns(
    col_widths = c(6, 6),
    # LINKE SPALTE (col 1-2)
    card(...),
    # RECHTE SPALTE (col 3-4)  ← Tabs hier
    navset_card_underline(...)
  )
  ```
- Sicherstellen, dass zuerst die Plotgrafiken der linken Spalte angezeigt werden, dann die Tabs
- Die 280px Höhe war ein Rendering-Fehler: Plots müssen mindestens 350-400px haben

---

## Problem 2: Signifikanztest-Logik ist konzeptuell falsch

### Aktuelle (falsche) Implementierung
- Samples werden gezogen (mit mu=0, p=0.5 für Nullhypothese)
- Das führt zu Zufallsvariabilität, die nicht beabsichtigt ist

### Korrekte Konzept
Im Signifikanztest-Modus:
1. **Keine Sampling-Funktionen aufrufen** - stattdessen:
   - Eine bekannte Verteilungsfunktion definieren (t, normal, chi², F)
   - Diese basiert auf Nullhypothese (Parameter = 0 oder Ratio = 1)
   
2. **Empirische Werte eingeben**:
   - Empirischer Parameterwert
   - Empirischer Standardfehler
   
3. **Berechnung des Test-Wertes**:
   - Test-Wert = (empirischer_param - nullwert) / empirischer_se
   - Für Mittelwert: `t = (empirischer_wert - 0) / empirischer_se`
   - Für Wahrscheinlichkeit: `z = (empirischer_wert - 0.5) / empirischer_se`
   - etc.

4. **Visualisierung**:
   - Zeichne die **bekannte Verteilung** (nicht gesampelt)
   - Zeige den Test-Wert als **vertikale Linie** in dieser Verteilung
   - Färbe die **Tail-Flächen** farbig (wo der Test-Wert liegt)
   - p-value = Fläche unter der Kurve jenseits des Test-Wertes

### Implementierung
- Neue Funktion: `plot_distribution_for_hypothesis_test()`
  - Inpute: empirischer_param, empirischer_se, parameter_type, alpha
  - Berechnet Test-Wert
  - Erstellt Verteilungskurve (nicht gesampelt!)
  - Markiert Test-Wert und p-value-Flächen
  
- `full_regenerate()` im Sig-Test-Modus:
  - Setzt einfach einen "dummy cache" Wert
  - Keine echten Samples nötig
  
- `plot_data()` Reactive bleiben für Cache-Verwaltung, aber im Sig-Test nur minimal genutzt

---

## Problem 3: Tail-Größe der Verteilungen

### Aktuelle Implementierung
Verteilungsplot zeigt nur ±4 SE von der Schätzung:
```r
x_range <- c(est - 4*se, est + 4*se)
```

### Problem
Für extreme p-values (z.B. p = 0.001) benötigen wir größere Tails.
Bei einem z-Wert von 3.5 wird die Kurve abgeschnitten.

### Lösung
Abhängig vom Parameter-Typ:
- **t-Verteilung, Normal**: ±5 oder ±6 SE (bei 95% KI sind ±2 SE korrekt, aber für Vis sollten Tails sichtbar sein)
- **Chi-Quadrat, F**: Anpassung der x_range für größere obere Grenzen
- Alternative: Tail-Größe vom α-Level abhängig machen

**Konkret**: 
```r
# Statt ±4 SE:
tail_multiplier <- 6  # oder abhängig von alpha
x_range <- c(est - tail_multiplier*se, est + tail_multiplier*se)
```

---

## Implementierungs-Schritte

### 1. Layout-Problem (schnell)
- `layout_columns()` mit zwei klaren Spalten schreiben
- Plots auf der Linken Seite
- Navset Tabs auf der Rechten Seite

### 2. Signifikanztest-Logik (komplex)
- Neue Funktion `plot_distribution_for_hypothesis_test()` schreiben
  - Parameter: empirical_param, empirical_se, parameter_type, alpha, df_values
  - Berechnet den Test-Wert je nach Typ
  - Erstellt Visualisierung ohne Sampling
  
- `full_regenerate()` anpassen:
  - Im Sig-Test: Nur einen Dummy-Cache Eintrag erstellen (brauchbar für die Renderierung)
  - Im KI-Modus: Normal samples generieren
  
- `dist_plot` Output in zwei Versionen splitten:
  - KI-Modus: `plot_distribution()` (bestehend)
  - Sig-Test-Modus: `plot_distribution_for_hypothesis_test()` (neu)

### 3. Tail-Größe
- Multiplikator in `plot_distribution()` erhöhen (von 4 zu 6)
- Optional: Abhängig vom α-Level

---

## Offene Fragen zur Klarheit

1. **Im Sig-Test-Tab "Verteilungen"**: Sollen die Grenzen noch angezeigt werden, oder nur der p-value?
   - Vorschlag: p-value in der Tabelle statt Grenzen ✓ (ist schon implementiert)

2. **Coverage-Tab**: Ist es richtig, dass dieser nur im KI-Modus verfügbar ist?
   - Ja, das macht Sinn - im Sig-Test gibt es keine "Coverage" im klassischen Sinne.

3. **Abschnitt B "Verteilung der Parameter"**: Was soll hier im Sig-Test angezeigt werden?
   - Aktuell: sig_test_summary (Zusammenfassung)
   - Das ist wahrscheinlich richtig.
