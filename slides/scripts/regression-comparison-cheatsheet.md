# Regressionskoeffizenten: Bivariate vs. Multivariate

## Schnelle Formelübersicht

### 1. Standardfehler des Koeffizients

#### Bivariate Regression
$$\text{SE}(\beta) = \sqrt{\frac{\sigma^2}{\sum(x_i - \bar{x})^2}}$$

Dabei:
- $\sigma^2 = \frac{\text{RSS}}{n-k}$ (Fehler-Varianz)
- RSS = Residual Sum of Squares
- n = Stichprobengröße
- k = Anzahl der Parameter

#### Multivariate Regression
$$\text{SE}(\beta_1) = \sqrt{\frac{\sigma^2_{\text{multi}}}{\sum(x_i - \bar{x})^2 \times (1 - R^2_{1|others})}}$$

Extra-Faktor:
- $R^2_{1|others}$ = Wie gut wird x₁ durch die anderen Variablen erklärt?
- Multikollinearität → größerer SE

---

## 2. Konfidenzintervalle für Koeffizenten

### Allgemeine Formel (beide Modelle)
$$\text{CI} = \hat{\beta} \pm t_{\text{crit}} \times \text{SE}(\hat{\beta})$$

### Kritische t-Werte
| KI | α | df | t (große df) |
|----|---|----|----|
| 90% | 0.10 | df = n-k | ≈ 1.645 |
| 95% | 0.05 | df = n-k | ≈ 1.96 |
| 99% | 0.01 | df = n-k | ≈ 2.576 |

---

## 3. Praktisches Beispiel: age → sat2

### BIVARIATE: sat2 ~ age

```
Daten:
  n = 26,520
  β = 0.0131  (pro Lebensjahr)
  SE = 0.0015

Berechnung:
  df = 26,520 - 2 = 26,518
  t_crit = 1.9601 (für df = 26,518)
  
  Untere Grenze = 0.0131 - 1.9601 × 0.0015 = 0.0101
  Obere Grenze  = 0.0131 + 1.9601 × 0.0015 = 0.0161
  
  95%-KI: [0.0101, 0.0161]
  
Interpretation:
  ✓ KI enthält nicht 0
  ✓ Signifikant auf 5%-Niveau
  ✓ Mit 95% Konfidenz: Für jedes Lebensjahr +0.01 bis +0.016 Zufriedenheit
```

### MULTIVARIATE: sat2 ~ sex*east + age + sin11_cat

```
Daten:
  n = 17,327
  β = 0.0027  (pro Lebensjahr, kontrolliert)
  SE = 0.0018

Berechnung:
  df = 17,327 - 10 = 17,317
  t_crit = 1.9601 (für df = 17,317)
  
  Untere Grenze = 0.0027 - 1.9601 × 0.0018 = -0.0008
  Obere Grenze  = 0.0027 + 1.9601 × 0.0018 = 0.0062
  
  95%-KI: [-0.0008, 0.0062]
  
Interpretation:
  ✗ KI enthält 0
  ✗ NICHT signifikant nach Kontrolle
  ✗ Mit 95% Konfidenz: Effekt könnte null oder negativ sein
  ✗ Oder positiv, aber sehr schwach
```

---

## 4. Wichtigste Unterschiede

| Aspekt | Bivariate | Multivariate |
|--------|-----------|--------------|
| **Effekt-Typ** | Roh-Effekt (confounded?) | Partieller Effekt (kontrolliert) |
| **Confounder** | Alle enthalten | Für andere Variablen kontrolliert |
| **Interpretation** | "Wie viel ändert sich y, wenn x sich um 1 ändert" | "Wie viel ändert sich y, wenn x sich um 1 ändert **und alle anderen konstant bleiben**" |
| **Gültiger SE** | ✓ | ✓ (aber größer wegen Multikollinearität) |
| **R²** | Klein (nur x erklärt) | Größer (mehrere Variablen erklären) |
| **Kausalität** | Fraglich (viele Confounder) | Besser (aber immer noch nicht garantiert) |

---

## 5. Warum könnte ein bivariater Effekt verschwinden?

### Szenario 1: Confounding
```
       Confounder Z
       /          \
      ↙            ↘
    X  ────────→  Y (bivariat signifikant)
       ↘          ↙
    Indirekt-Effekt (via Z)

Nach Kontrolle für Z:
→ Direkter Effekt könnte null oder viel kleiner sein
```

### Szenario 2: Collider
```
       X
       ↘
    Z ← ↙  Y
   (kontrolliert)
   
Nach Kontrolle für Z:
→ Kann künstliche Assoziation schaffen (auch wenn X ⊥ Y)
→ NICHT EMPFOHLEN, Z zu kontrollieren
```

### Szenario 3: Multikollinearität
```
X₁ und X₂ sind hochkorreliert

Bivariat: X₁ signifikant
Multivariat: Beide SE werden groß
→ Beide könnten nicht signifikant werden
```

---

## 6. Schritt-für-Schritt Checkliste

### Vor der Regression
- [ ] Abhängige Variable definiert (Y)?
- [ ] Unabhängige Variablen identifiziert (X)?
- [ ] Potenzielle Confounder überlegt?
- [ ] Kategorische Variablen als factors?
- [ ] Fehlende Werte gehandhabt?

### Nach der Regression (Bivariate)
- [ ] Koeffizient β interpretiert?
- [ ] SE berechnet oder aus Output genommen?
- [ ] KI berechnet [β ± t × SE]?
- [ ] KI enthält 0? (→ nicht signifikant)
- [ ] R² angeschaut (Modellgüte)?
- [ ] Residuen überprüft (Annahmen)?

### Nach der Regression (Multivariate)
- [ ] Alle obigen Punkte
- [ ] Partielle Effekte interpretiert?
- [ ] Confounding überprüft (Effekte ändern sich)?
- [ ] Multikollinearität überprüft (VIF)?
- [ ] Interpretation war "kontrolliert für..."?
- [ ] Interaktionen sinnvoll?

---

## 7. Häufige Fehler

| Fehler | Problem | Lösung |
|--------|---------|--------|
| SE verwechselt mit SD | SE ist für Koeffizent, SD für Rohdaten | Prüfen: $\text{SE} = \frac{\text{SD}}{\sqrt{n}}$ |
| z statt t verwendet | t-Vert. ist konservativer (richtig) | Immer t-Vert. bei Regression |
| df vergessen | Falsche kritische Werte | df = n - k |
| Koeff. ohne SE interpretiert | Keine Unsicherheit berücksichtigt | Immer KI angeben |
| Confounding ignoriert | Biased estimates | Multivariat mit wichtigen Controllern |
| Alle Variablen kontrolliert | "Kitchen sink" Regression | Theoretisch begründet auswählen |

---

## 8. Formeln für R

### Standardfehler manuell berechnen

```r
# Bivariate
rss <- sum(residuals(model)^2)
n <- nobs(model)
k <- 2
sigma_sq <- rss / (n - k)
sum_sq_x <- sum((x - mean(x))^2)
se_manual <- sqrt(sigma_sq / sum_sq_x)

# Aus lm-Output
se_from_tidy <- tidy(model)$std.error[2]
```

### Konfidenzintervalle

```r
# Manuell
coef_val <- coef(model)[2]
se_val <- tidy(model)$std.error[2]
df <- nobs(model) - 2
t_crit <- qt(0.975, df)

ci_lower <- coef_val - t_crit * se_val
ci_upper <- coef_val + t_crit * se_val

# Mit confint()
confint(model, level = 0.95)[2,]
```

### Vergleich bivariat vs. multivariat

```r
# Extraktion
coef_biv <- coef(model_biv)["x"]
coef_multi <- coef(model_multi)["x"]

# Confounding-Effekt
confounding <- coef_biv - coef_multi
```
