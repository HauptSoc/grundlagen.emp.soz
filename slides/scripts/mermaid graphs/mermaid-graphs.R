```{mermaid}
flowchart LR

 subgraph sg1["Studienfrage"]
        SF["Werden Jungen in der Grundschule in geringerem Maße als Mädchen entsprechend ihrer Bedürfnisse gefördert und haben daher geringere Übergangswahrscheinlichkeiten zum Gymnasium?"]
  end

 subgraph sg2["Theoretische Population"]
        TP["Grundschüler:innen in Deutschland."]
  end

 subgraph sg3["Theorie-Empirie Link"]
    direction TD
        G["Geschlecht"]
        U["Übergang zum Gymnasium"]
        F["Förderung"]
        L["Leistungen"]
        K["Kompetenzen"]
        I[" "]
        I@{ shape: sm-circ}
  end

 subgraph sg4["Schätzung"]
        R1["Schritt 1: Lineare Regression mit Förderungsintensität als abhängige Variable mit Geschlecht und Kompetenzen als Kontrollvariablen und Interaktion zwischen Geschlecht und Kompetenzen."]
        R2["Schritt 2: Logistische Regression mit der Übergangswahrscheinlichkeit auf das Gymnasium als abängige Variable unter Kontrolle der Förderungsintensität und Leistung."]
  end

subgraph sg5["Beobachtungsgrundlage"]
B1["Stichprobenziehung aus der Population"]
B2["Erfassung von Geschlecht, Kompetenzen, Förderung & Leistung zu t1"]
B3["Zusätzliche Erfassung des Übergangs nach Klasse 4/6 zu t2"]
B1 ~~~ B2 ~~~ B3
end

    G --> K
    K --- I
    I --> F
    G ---> I
    F --> L
    L --> U
    sg1 --> sg2
    sg2 --> sg3
    sg3 --> sg5
    sg5 --> sg4

```