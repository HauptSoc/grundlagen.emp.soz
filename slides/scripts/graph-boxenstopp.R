library(knitr)
library(kableExtra)

# Daten mit \n für Zeilenumbrüche und Bulletpoints als "-"
data <- data.frame(
  Tier = c("**🔴 S**", "**🟠 A**", "**🟢 B**", "**🔵 C**", "**⚫ D**", "**🟣 E**", "**💙 F**"),
  Datenerhebung = c(
    "- Verstehen, wie alles mit allem zusammenhängt\n- Auge und Kopf für Details\n- Auffinden von Fehlern und Darlegung, wie man sie berichtigen kann\n- Anwendung des gesamten Wissens auf nerdige edge-cases",
    "- Verhältnis von \"Overconfidenz\", wissenschaftlichen Spielregeln und Inferenzstatistik\n- sinnvolle Erwägung, wann eine bestimmte Form der Skalierung anzuwenden ist\n- Verhältnis von Messfehlern zu einzelnen Formen der Skalierung latenter Eigenschaften\n- die Bedeutung von Gewichtung bei Teilnahmeselektion\n- Erläuterung von Teilnahme- und Antwortselektion und seiner Folgen\n- fundierte Kritik in Bezug auf die Reliabilität und Validität von Messungen aus wissenschaftlichen Publikationen\n- fundierte Kritik in Bezug auf die Stichprobenziehung wissenschaftlicher Studien",
    "- Verständnis von Reliabilität und Validität\n- Erläuterung von Thurstone, Likert und Guttman Skalierung\n- Nachvollziehen und Erläuterung von Typenbildung\n- Problematische Itemformulierungen erkennen und begründet beheben\n- Problematische Reaktionsformulierungen erkennen und begründet beheben",
    "- Relation von Indikatoren und (latenten) Eigenschaften\n- Operationalisierung und Konzeptspezifizierung von wissenschaftlichen Publikationen verstehen und widergeben können\n- Eigene Anwendung von Stichproben- und Untersuchungsdesigns auf ein neues Beispiel\n- Erläuterung unterschiedlicher Indexbildungen und wofür sie sinnvoll sind\n- Grundlagen der Frage- und Itemformulierung",
    "- Verständnis von Konzeptspezifikation\n- Verständnis von Operationalisierung\n- Verständnis der Dimensionalität latenter Eigenschaften\n- Verständnis von Selektion und Repräsentativität",
    "- Unterscheidung von Definitionen, Hypothesen und Beschreibungen\n- Skalentypen\n- Stichprobendesigns benennen und unterscheiden können\n- Untersuchungsdesigns benennen und unterscheiden können",
    "- Wer Kartoffelsalat mit Majo macht, ist raus."
  ),
  Datenanalyse = c(
    "",  # Leer für Tier S
    "- Interaktionen in multivariaten Regressionsmodellen berechnen und verstehen können\n- Interaktionseffekte aus wissenschaftlichen Publikationen verstehen können\n- Zusammenhang von Modellergebnissen und selektiven Stichproben",
    "- die Theorie zu p-Values und Signifikanz verstehen und wiedergeben können\n- sicherer Umgang mit publizierten Ergebnissen der Inferenzstatistik\n- Interpretation von multivariaten Regressionsmodellen -- auch mit ordinalen und nominalen erklärenden Variablen\n- z-Standardisierung verstehen und anwenden können",
    "- Informationen über einfache Resultate aus wissenschaftlichen Publikationen korrekt und sinnvoll interpretieren können\n- bivariate Regressionsmodelle berechnen und interpretieren können\n- Konzept von Residuen und Residualvarianz verstehen und berechnen können\n- Verständnis von Selektion ins Treatment, Mediation, Scheinkorrelation, Konfundierung\n- Konfidenzintervalle für beliebige Parameter berechnen und interpretieren können",
    "- Diversität, Chancenverhältnisse\n- Informationen aus Graphen von deskriptiven Verteilungen vergleichend benutzen können\n- Differenzen oder Verhältnisse zwischen Kennwerten sinnvoll nutzen können",
    "- Berechnung und Interpretation von: Modus, Median, Mittelwert, Varianz, Standardabweichung, relative Häufigkeiten, relative Risiken, Chancen\n- Interpretation von: Perzentilwerten\n- Verständnis von stetigen und diskreten Verteilungen und wie man/frau sie vergleichen kann\n- Interpretation von Boxplots, Balkendiagrammen und Histogrammen\n- sichere Interpretation von allen Kennwerten auch mit neuen Daten",
    ""  # Leer für Tier F
  )
)

# kable()-Tabelle mit Formatierung
kable(data, format = "pipe", align = c("l", "l", "l"), caption = "Tierlist-Ranking: Datenerhebung und Datenanalyse") %>%
  kableExtra::kable_styling(bootstrap_options = c("striped", "hover")) %>%
  kableExtra::column_spec(1, extra_css = "font-weight: bold;") %>%
  kableExtra::column_spec(2, extra_css = "white-space: pre-wrap;") %>%
  kableExtra::column_spec(3, extra_css = "white-space: pre-wrap;")