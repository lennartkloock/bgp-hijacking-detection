= Implementierung

== Softwarearchitektur

Um das vorgestellte Konzept umzusetzen, wird das Projekt in mehrere Komponenten aufgeteilt.

=== Ingest

- Globale Routing-Tabelle pflegen
- Seeding mit bviews und updates von RIPE RIS
- Danach: Live Announcements empfangen und Routing-Tabelle aktualisieren
- Updates weiterleiten an Clickhouse DB
- PostgreSQL speichert aktuelle Routing-Tabelle
- Clickhouse DB speichert alle BGP-UPDATE-Nachrichten zur späteren Analyse
- Warum nicht alle RIS RRCs?

=== Analysis

- MOAS Präfixe erkennen
- Port 443 mit zmap @zmap scannen
- Warum nicht Shodan?

== Umsetzung mit Rust

- Libraries
- Codebeispiele
- Implementierungsdetails

// - Probleme die aufgetreten sind

#pagebreak()
