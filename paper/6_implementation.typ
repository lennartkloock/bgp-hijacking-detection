= Implementierung

== Softwarearchitektur

Um das vorgestellte Konzept umzusetzen, wird das Projekt in mehrere Komponenten aufgeteilt.

=== Detection

=== Database

=== Message Queue

=== Evaluation

=== REST API

// - Implementierungsdetails
// - Probleme die aufgetreten sind
// - Libraries
// - Codebeispiele

// Architektur:
// 
// 1. Detection
//   - Globale Routing-Tabelle pflegen
//   - Live Announcements empfangen und Routing-Tabelle aktualisieren
//   - Live MOAS Präfixe erkennen und auf MQ (Redis?) schicken
// 2. Evaluation
//   - MOAS Präfixe von MQ empfangen
//   - MOAS Incident in Datenbank erstellen
//   - Shodan API: TLS Hosts im Präfix zu finden
//   - RIPE Atlas: Probes in den beiden Partitionen zu finden
//   - RIPE Atlas: TLS Verbindungen aufbauen und Zertifikate abrufen
//   - Ergebnisse der TLS-Anfragen in Datenbank speichern
//   - MOAS Incident updaten
// 3. REST API Server
//   - REST API um Incidents aus Datenbank abzufragen
// 4. Web-Frontend (optional)
//   - Nutzt API
//   - Ergebnisse darstellen

#pagebreak()
