#import "util.typ": display_number, display_percent
#import "7_evaluation.typ": bgp_updates_total, moas_total, moas_4, moas_origins_2, at_least_one_host

= Fazit <conclusion>

// - Erkenntnisse zusammenfassen
// - Muss ohne Lesen des Hauptteils verständlich sein
// - Eigene Meinung möglich
// - Future Work
//   - Ingest optimieren
//     - möglicherweise mit Routing-Tabelle im RAM
//   - Verschiedene RRCs verwenden
//   - RPKI Abdeckung miteinbeziehen
//   - Scan zmap from multiple view points
//   - SSH Keys vergleichen
//   - Andere BGP-Quellen hinzufügen, z.B. RouteViews
//   - Protokoll, um eigene Dateneinspeisung zu ermöglichen
//   - Alerting System

Ziel dieser Arbeit war es, eine zuverlässige Methode zur Echtzeiterkennung von Prefix-Hijacking-Angriffen mithilfe
öffentlich zugänglicher Datenquellen zu entwickeln und zu evaluieren.
Dazu wurde ein System implementiert, das kontinuierlich BGP-Daten von _RIPE RIS_ verarbeitet, MOAS-Konflikte identifiziert
und anschließend TLS-Zertifikate aus der _Data-Plane_ zur weiteren Einordnung heranzieht.

Die Evaluation zeigt, dass MOAS-Konflikte ein häufig auftretendes Phänomen im globalen BGP-Routing sind.
Im betrachteten Zeitraum wurden über 347 Millionen BGP-Updates verarbeitet, aus denen zum Messzeitpunkt
#display_number(moas_total) aktive MOAS-Konflikte hervorgingen, davon #display_number(moas_4) IPv4-Präfixe.
Die überwiegende Mehrheit dieser Konflikte (#display_percent(moas_origins_2 / moas_total)) weist genau zwei konkurrierende Origin-AS auf.
Die entwickelte TLS-basierte Methode bietet gegenüber reinen _Control-Plane_-Ansätzen den wesentlichen Vorteil, dass
TLS-Zertifikate statt statistische Wahrscheinlichkeiten zur Identitätsüberprüfung genutzt werden.
TLS-Zertifikate sind kryptografisch abgesichert und gelten als vertrauenswürdige Bestätigung der Identität.
In #display_percent(at_least_one_host / moas_4) der untersuchten IPv4-MOAS-Präfixe wurde mindestens ein TLS-Dienst auf
TCP-Port 443 gefunden, sodass eine Zertifikatsanalyse grundsätzlich möglich wäre.
Die manuelle Untersuchung eines konkreten Falls mithilfe von _RIPE Atlas_ verlief erfolgreich und bestätigte die prinzipielle
Funktionsfähigkeit des Verfahrens.

Gleichzeitig hebt die Arbeit auch die Grenzen des Ansatzes hervor.
In ca. #display_percent(calc.round((1 - (at_least_one_host / moas_4)) * 100) / 100) der IPv4-MOAS-Fälle ist kein erreichbarer TLS-Dienst vorhanden, was eine Analyse von vornherein ausschließt.
Außerdem setzt die Methode voraus, dass in beiden Partitionen des MOAS-Konflikts geeignete _RIPE Atlas Probes_ verfügbar sind,
was aufgrund der ungleichmäßigen Verteilung der _Probes_ nicht immer gegeben ist.
In einem Angriffsszenario, bei dem der Angreifer Zugriff auf das originale TLS-Zertifikat hat, liefert die Methode zudem ein falsch negatives Ergebnis.
Schließlich war eine vollständige Automatisierung der _RIPE Atlas_ Analyse aufgrund der hohen Fallzahl nicht praktikabel.
Insgesamt lässt sich festhalten, dass TLS-Zertifikate ein vielversprechendes, kryptografisch fundiertes Hilfsmittel zur Erkennung von Prefix-Hijacking-Angriffen darstellen, die bestehende Methoden sinnvoll ergänzen können.
Eine zuverlässige, vollautomatische Erkennung setzt jedoch weitere Optimierungen voraus.

== Ausblick

Für zukünftige Arbeiten bieten sich mehrere Ansatzpunkte an.
Die Performance des Ingest-Systems lässt sich durch das Speichern der Routing-Tabelle im Arbeitsspeicher anstatt in einer relationalen Datenbank deutlich steigern, was die Verarbeitung von BGP-Updates aller _RIPE RIS RRCs_ parallel ermöglichen würde.
Zusätzlich könnten weitere BGP-Datenquellen wie _RouteViews_ genutzt werden um die Abdeckung zu verbessern und blinde Flecken zu reduzieren.
Durch die Einbeziehung des RPKI-Abdeckungsstatus eines Präfixes würde sich die Priorisierung verdächtiger Fälle weiter verfeinern lassen.
Die _zmap_-Scans könnten von mehreren geografisch verteilten Standpunkten aus durchgeführt werden, um Verfügbarkeitsunterschiede zwischen den Partitionen eines MOAS-Konflikts direkter sichtbar zu machen.
Ergänzend zu dem hier vorgestellten Verfahren wäre auch der Vergleich von SSH-Host-Keys möglich.
Abschließend würde ein integriertes Alerting-System sowie ein offenes Protokoll zur externen Dateneinspeisung die praktische Nutzbarkeit der Plattform erheblich erweitern.

#pagebreak()
