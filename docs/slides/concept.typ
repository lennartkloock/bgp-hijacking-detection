#import "@preview/typslides:1.3.2": *

#let concept_example(image_path, content) = cols(columns: (1fr, auto))[
  #box(height: 14em)[
    #set align(top)
    #content
  ]
][
  #image(image_path)
]

#slide(title: "Konzept")[
  #concept_example("images/concept_0.drawio.pdf")[]
]

#slide(title: "Konzept")[
  #concept_example("images/concept_1.drawio.pdf")[
    1. #stress[MOAS-Präfixe identifizieren]
  ]
]

#slide(title: "Konzept")[
  #concept_example("images/concept_2.drawio.pdf")[
    1. MOAS-Präfixe identifizieren
    2. #stress[TLS-Dienst im betroffenen Präfix finden]
  ]
]

#slide(title: "Konzept")[
  #concept_example("images/concept_3.drawio.pdf")[
    1. MOAS-Präfixe identifizieren
    2. TLS-Dienst im betroffenen Präfix finden
    3. #stress[Zwei RIPE Atlas Probes in den beiden Partitionen des MOAS-Konflikts finden]
  ]
]

#slide(title: "Konzept")[
  #concept_example("images/concept_4.drawio.pdf")[
    1. MOAS-Präfixe identifizieren
    2. TLS-Dienst im betroffenen Präfix finden
    3. Zwei RIPE Atlas Probes in den beiden Partitionen des MOAS-Konflikts finden
    4. #stress[Von beiden Probes aus Verbindung zum TLS-Dienst aufbauen und TLS-Zertifikat abfragen]
  ]
]

#slide(title: "Konzept")[
  #concept_example("images/concept_5.drawio.pdf")[
    1. MOAS-Präfixe identifizieren
    2. TLS-Dienst im betroffenen Präfix finden
    3. Zwei RIPE Atlas Probes in den beiden Partitionen des MOAS-Konflikts finden
    4. Von beiden Probes aus Verbindung zum TLS-Dienst aufbauen und TLS-Zertifikat abfragen
    5. #stress[Zertifikate vergleichen]
  ]
]

// 1. MOAS Präfixe live identifizieren mithilfe RIPE RIS Live (https://ris-live.ripe.net/)
//   - Globale Routing-Tabelle aufbauen
//   - Letzten Monat an Announcement Archiven herunterladen und Datenbank füllen um einen Startpunkt für die globale Routing-Tabelle zu haben
//   - Live Announcements abgleichen und hinzufügen
// 2. TLS Hosts (z.B. HTTPS, SMTP, IMAP, DNS, LDAP, Datenbanken, SSH Host Keys?) im Prefix finden
//   - Einfach alle Adressen auf bestimmten Ports scannen?
//   - Legal?
//   - Könnte möglicherweise sehr lange dauern
//   - Shodan
// 3. Zwei RIPE Atlas Probes in den beiden Partitionen finden
//   - Wie können wir uns sicher sein, dass wir uns tatsächlich in einer bestimmten Partition befinden?
// 4. Von beiden Verbindung aufbauen und TLS Zertifikat abfragen
// 5. Ergebnisse vergleichen
