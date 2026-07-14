# Konfidenzintervalle in verschiedenen Verteilungen

## Überblick

Diese Visualisierungen zeigen, wie sich Konfidenzintervall-Grenzen (90% und 95%) in verschiedenen statistischen Verteilungen unterscheiden.

---

## Panel 1: t-Verteilungen

### Warum t-Verteilungen?

Die t-Verteilung wird verwendet für:
- **Konfidenzintervalle um Mittelwerte** (wenn σ unbekannt)
- **Regressionskoeffizenten**
- **t-Tests**

### df = 10 (links)

**Kritische Werte:**
- 90% CI: t = ±1.81
- 95% CI: t = ±2.23

**Beobachtung:** Die t-Verteilung ist relativ **flach** → breitere Schwänze → größere kritische Werte

**Interpretation:** Mit weniger Freiheitsgraden ist unsere Schätzung **weniger präzise**, daher brauchen wir **weitere Grenzen** für das gleiche Konfidenzlevel.

### df = 40 (rechts)

**Kritische Werte:**
- 90% CI: t = ±1.68
- 95% CI: t = ±2.02

**Beobachtung:** Mit mehr df wird die Verteilung **spitzere** → näher an Normalverteilung

**Regel:** Je mehr df, desto näher kommen die t-Werte den z-Werten (1.645 und 1.96)

---

## Panel 2: F-Verteilungen

### Warum F-Verteilungen?

Die F-Verteilung wird verwendet für:
- **ANOVA** (Varianzanalyse)
- **Vergleich von Varianzen**
- **Multivariate Tests**

### Wichtige Eigenschaften

1. **Asymmetrisch:** F kann nur positive Werte annehmen (0 bis ∞)
2. **One-tailed:** Kritische Werte sind auf der rechten Seite
3. **Zwei Parameter:** df1 und df2

### df = 3/10 (links)

**Kritische Werte:**
- 90% Grenze: F = 2.73
- 95% Grenze: F = 3.71

**Beobachtung:** Flache Verteilung mit langem Schwanz nach rechts → höhere kritische Werte

**Interpretation:** Mit wenigen Freiheitsgraden ist es **schwerer, Unterschiede nachzuweisen**.

### df = 45/100 (rechts)

**Kritische Werte:**
- 90% Grenze: F = 1.37
- 95% Grenze: F = 1.49

**Beobachtung:** Viel spitzere Verteilung, näher an 1

**Interpretation:** Mit vielen Freiheitsgraden sind die kritischen Werte **nahe 1**, und **echte Effekte werden leichter signifikant**.

---

## Farbcodierung

| Farbe | Bedeutung |
|-------|-----------|
| **Grün** | 90% Konfidenzbereich |
| **Orange** | 95% Konfidenzbereich |
| **Gepunktet (grün)** | 90%-Grenzen |
| **Gestrichelt (orange)** | 95%-Grenzen |

---

## Praktische Implikationen

### Für t-Tests und Regressionen

```
Bericht eines Results:
"Der Koeffizient betrug 2.5 (95% CI: [1.8, 3.2], p < 0.05)"

Die 1.96 (oder 2.02 mit df=40) Multiplikatoren kommen aus der t-Verteilung!
```

### Für ANOVA und F-Tests

```
Bericht eines Results:
"Die ANOVA war signifikant (F(3,10) = 4.5, p < 0.05)"

Das bedeutet: F-Statistik (4.5) > kritischer Wert (3.71 für 95%)
```

---

## Vergleich: t-Verteilung vs. z-Verteilung

| Aspekt | t-Verteilung | z-Verteilung |
|--------|-------------|--------------|
| **Kritische Werte (90%)** | 1.645 (∞ df) | 1.645 (immer) |
| **Kritische Werte (95%)** | 1.960 (∞ df) | 1.960 (immer) |
| **Kleine df** | Größere Werte | N/A |
| **Verwendung** | Kleine Stichproben | Große Stichproben / bekanntes σ |

---

## Schlüssel-Erkenntnisse

✓ **Freiheitsgrade sind wichtig:** Mehr df → kleinere kritische Werte → leichter signifikant

✓ **t-Verteilung ist konservativ:** Größere kritische Werte schützen vor Type-I-Fehlern bei kleinen Stichproben

✓ **F-Verteilung ist asymmetrisch:** Einseitig, immer positive Werte

✓ **Beide konvergieren:** Mit ∞ df → t wird z, F wird χ²

---

## Für Studierende: Experiment

**Versucht diese Fragen zu beantworten:**

1. Wenn dein df = 100 statt 10 ist, werden deine KI breiter oder enger?
   - Antwort: **Enger** (t-Wert sinkt)

2. In welcher Situation braucht man die F-Verteilung?
   - Antwort: **Wenn man mehrere Gruppen vergleicht** (ANOVA)

3. Warum können F-Werte nicht negativ sein?
   - Antwort: **F ist ein Ratio von Varianzen**, und Varianzen sind immer ≥ 0

4. Wenn F = 1, was bedeutet das?
   - Antwort: **Keine Unterschiede zwischen Gruppen** (Varianzen sind gleich)

---

## Literatur & Weitere Ressourcen

- **t-Verteilung:** Oft in Statistik-Lehrbüchern, Kapitel "Inference about means"
- **F-Verteilung:** In Kapiteln über ANOVA und Varianzvergleiche
- **Online:** Visualisierungen mit Shiny oder ähnlichen Tools für interaktives Lernen
