# Unabhängiger t-Test: Cheat Sheet für Studierende

## Formel: Konfidenzintervall einer Mittelwertdifferenz

$$\text{CI} = (\bar{x}_1 - \bar{x}_2) \pm z \times \text{SE}_{\text{Diff}}$$

### Komponenten:

| Komponente | Formel | Bedeutung |
|-----------|--------|-----------|
| **Mittelwertdifferenz** | $\bar{x}_1 - \bar{x}_2$ | Punkt-Schätzung des Unterschieds |
| **Standardfehler** | $\text{SE} = \sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}$ | Unsicherheit der Schätzung |
| **z-Wert (95% KI)** | $z = 1.96$ | Kritischer Wert der Normalverteilung |
| **z-Wert (90% KI)** | $z = 1.645$ | Für weniger restriktives KI |

---

## Schritt-für-Schritt Anleitung

### 1. **Daten beschreiben**
```
Gruppe 1 (Frauen):    n₁ = 1988,  MW = 8.02,  SD = 2.00
Gruppe 2 (Männer):    n₂ = 1202,  MW = 7.62,  SD = 2.10
```

### 2. **Mittelwertdifferenz**
```
Differenz = 8.02 - 7.62 = 0.395
```

### 3. **Varianzen berechnen**
```
Var₁ = SD₁² = 2.00² = 4.00
Var₂ = SD₂² = 2.10² = 4.41
```

### 4. **Standardfehler der Differenz**
```
SE = √(4.00/1988 + 4.41/1202)
   = √(0.00201 + 0.00367)
   = √0.00568
   = 0.0753
```

### 5. **z-Wert wählen**
```
95% KI  →  z = 1.96
90% KI  →  z = 1.645
```

### 6. **Konfidenzintervall**
```
Untere Grenze = 0.395 - 1.96 × 0.0753 = 0.247
Obere Grenze  = 0.395 + 1.96 × 0.0753 = 0.543
KI = [0.25, 0.54]
```

---

## Interpretation

| Szenario | Bedeutung | Signifikanz |
|----------|-----------|------------|
| **KI enthält nicht 0** | Unterschied ist echt | ✓ Signifikant |
| **KI enthält 0** | Unterschied könnte 0 sein | ✗ Nicht signifikant |
| **Ganzes KI > 0** | Gruppe 1 höher als Gruppe 2 | ✓ Signifikant (Gruppe 1) |
| **Ganzes KI < 0** | Gruppe 1 niedriger als Gruppe 2 | ✓ Signifikant (Gruppe 2) |

### Unser Beispiel: [0.25, 0.54]
- ✓ **Nicht 0 enthalten** → Signifikant
- ✓ **Ganz positiv** → Frauen signifikant zufriedener
- ✓ **Interpretation:** Mit 95% Konfidenz sind Frauen zwischen 0.25 und 0.54 Punkte zufriedener

---

## Warum Normalverteilung?

### Der Zentrale Grenzwertsatz (ZGS)

Die Differenz zweier Mittelwerte ist **asymptotisch normalverteilt**, weil:

1. **Wir addieren Varianzen:** $\text{SE} = \sqrt{\frac{\text{Var}_1}{n_1} + \frac{\text{Var}_2}{n_2}}$
2. **Summen sind normal:** Nach dem ZGS sind Summen von unabhängigen Zufallsvariablen asymptotisch normal
3. **Mit großen n:** Die Approximation ist sehr gut (ab n ≥ 30 pro Gruppe)

### Unsere Stichproben sind groß:
- Frauen: n = 1988 ✓
- Männer: n = 1202 ✓
- **Normalverteilung ist exzellente Approximation!**

---

## Häufige Fehler

| Fehler | Problem |
|--------|---------|
| **KI mit 0 schreiben** | KI [0.25, 0.54] enthält 0 nicht! (Punkt: 0 liegt nicht darin) |
| **Signifikanz mit α verwechseln** | α = 0.05 ist das Signifikanzniveau, nicht das KI |
| **Ohne Effektgröße berichten** | Immer auch MW-Differenz angeben, nicht nur p-Wert |
| **Varianzen addieren statt Summe aus Varianzen/n** | Formel: $\sqrt{s_1^2/n_1 + s_2^2/n_2}$ ist richtig |

---

## t-Test vs. z-Test

| Aspekt | z-Test | t-Test |
|--------|--------|--------|
| **Verwendet bei** | Großen Stichproben (n > 30) | Kleineren Stichproben |
| **Kritischer Wert (95%)** | 1.96 | ~2.0 (hängt von df ab) |
| **Verteilung** | Standard-Normal | t-Verteilung |
| **Praktisch** | Bei n > 1000 unterscheiden sich kaum | Bei kleineren n wichtig |

---

## Checkliste vor der Berechnung

- [ ] Sind die Gruppen unabhängig? (Nicht gepaart?)
- [ ] Wie groß sind die Stichproben? (n₁ und n₂)
- [ ] Sind die Varianzen ähnlich? (Ratio sollte nicht > 2:1 sein)
- [ ] Welches KI-Niveau? (90%, 95%, 99%)
- [ ] Ist die Annahme der Normalverteilung erfüllt? (Mit großem n weniger wichtig)

---

## Formelsammlung

### Standardfehler

**Einstichproben-Mittelwert:**
$$\text{SE}_{\bar{x}} = \frac{s}{\sqrt{n}}$$

**Differenz zweier Mittelwerte (Welch's):**
$$\text{SE}_{\text{Diff}} = \sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}$$

**Proportionen:**
$$\text{SE}_p = \sqrt{\frac{p(1-p)}{n}}$$

### Konfidenzintervalle

**Allgemeine Form:**
$$\text{Schätzung} \pm z \times \text{SE}$$

**Mit t-Verteilung:**
$$\text{Schätzung} \pm t_{\alpha/2, df} \times \text{SE}$$
wobei $df = n_1 + n_2 - 2$
