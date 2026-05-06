#import "@preview/typslides:1.3.2": *

#let architecture_image(image_path, content) = cols(columns: (1fr, auto))[
  #box(height: 18.25em)[
    #set align(top)
    #content
  ]
][
  #image("../" + image_path)
]

#title-slide[Softwarearchitektur]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_1.drawio.pdf")[
    - #stress[RIPE RIS]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_2.drawio.pdf")[
    - RIPE RIS
    - #stress[Ingest]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_2.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - #stress[Verarbeitet BGP-Daten]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_3.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - #stress[ClickHouse]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_3.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - #stress[Spaltenorientierte Datenbank]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_3.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - #stress[Ausgelegt auf das Sammeln von großen Datenmengen]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_4.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - #stress[PostgreSQL]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_4.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - PostgreSQL
      - #stress[Klassische relationale SQL-Datenbank]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_5.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - PostgreSQL
      - Klassische relationale SQL-Datenbank
    - #stress[MOAS Analysis]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_5.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - PostgreSQL
      - Klassische relationale SQL-Datenbank
    - MOAS Analysis
      - #stress[MOAS Präfixe identifizieren]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_6.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - PostgreSQL
      - Klassische relationale SQL-Datenbank
    - MOAS Analysis
      - MOAS-Präfixe identifizieren
    - #stress[zmap]
  ]
]

#slide(title: "Softwarearchitektur")[
  #architecture_image("images/architecture_6.drawio.pdf")[
    - RIPE RIS
    - Ingest
      - Verarbeitet BGP-Daten
    - ClickHouse
      - Spaltenorientierte Datenbank
      - Ausgelegt auf das Sammeln von großen Datenmengen
    - PostgreSQL
      - Klassische relationale SQL-Datenbank
    - MOAS Analysis
      - MOAS-Präfixe identifizieren
    - zmap
      - #stress[MOAS-Präfixe scannen und TLS-Hosts finden]
  ]
]
