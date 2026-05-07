#import "@preview/typslides:1.3.2": *

#title-slide[Konzept]

#slide(title: "Konzept")[
  #box(height: 13em)[
    #set align(top)
    - #stress[Ziel: Echtzeiterkennung von Prefix-Hijacking-Angriffen weltweit ohne Vorwissen über den Aufbau einzelner AS]
  ]
]

#slide(title: "Konzept")[
  #box(height: 13em)[
    #set align(top)
    - Ziel: Echtzeiterkennung von Prefix-Hijacking-Angriffen weltweit ohne Vorwissen über den Aufbau einzelner AS
    - #stress[Bestehende Ansätze:]
      - PHAS (2006) @phas
      - ARTEMIS (2018 – 2022) @artemis
      - BGPalerter (2019 – jetzt) @bgpalerter
      - BGPwatch (2021) @bgpwatch
        - Nutzung von KI-Modellen zur Bewertung von Vorfällen
  ]
]

#slide(title: "Konzept")[
  #box(height: 13em)[
    #set align(top)
    - Ziel: Echtzeiterkennung von Prefix-Hijacking-Angriffen weltweit ohne Vorwissen über den Aufbau einzelner AS
    - Bestehende Ansätze:
      - PHAS (2006) @phas
      - ARTEMIS (2018 – 2022) @artemis
      - BGPalerter (2019 – jetzt) @bgpalerter
      - BGPwatch (2021) @bgpwatch
        - Nutzung von KI-Modellen zur Bewertung von Vorfällen
    - #stress[Idee: Nutzung von TLS-Zertifikaten]
      - TLS-Zertifikate können zuverlässig eine Identität bestätigen
  ]
]

#include "../concept.typ"
