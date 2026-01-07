= Konzept <concept>

In diesem Kapitel wird ein Konzept zur Erkennung von Prefix-Hijacking-Angriffen in Echtzeit mithilfe von TLS-Zertifikaten vorgestellt.

== Vorgehensweise

Zuerst werden MOAS-Konflikte identifiziert, unabhängig davon ob sie gutartig oder bösartig sind, damit anschließend für jeden dieser potenziellen Prefix-Hijacking-Angriffe Daten zur weiteren Einordnung gesammelt werden können.
Dafür werden echte BGP-Daten verarbeitet, die kontinuierlich in Echtzeit von _RIPE RIS_ (siehe @ripe-ris) empfangen werden.
Mithilfe dieser Daten wird eine Tabelle gepflegt, die für jeden Präfix alle zugehörigen Origin-AS speichert, die diesen Präfix aktuell verkünden.
Wenn eine neue BGP-UPDATE-Nachricht empfangen wird, wird die Tabelle entsprechend aktualisiert.
Sobald ein Präfix von mindestens zwei verschiedenen Origin-AS verkündet wird oder ein Präfix sich in einem anderen Präfix befindet, welcher ein abweichendes Origin-AS hat, wird dieser Präfix als MOAS-Konflikt in einer separaten Tabelle gespeichert.

Im nächsten Schritt muss für alle potenziellen Prefix-Hijacking-Angriffe, die so identifiziert wurden ein TLS-Dienst im betroffenen Präfix gefunden werden.
Das kann durch Scannen jeder IP-Adresse des Präfixes umgesetzt werden.
Die Suche wird jedoch durch schon bestehende Netzwerkdatenbanken wie _Shodan_ (siehe @shodan) vereinfacht, die solche Scans regelmäßig durchführen.
Über _Shodan_ lässt sich ein TLS-Dienst in einem bestimmten IP-Präfix durch eine einfache Suchanfrage finden.
Diese kann auch durch die _Shodan_-API automatisiert werden.

Wenn ein TLS-Dienst gefunden wurde, wird versucht zwei _RIPE Atlas_ (siehe @ripe-atlas) _Probes_ zu finden, die sich in den beiden unterschiedlichen Partitionen des MOAS-Konflikts befinden.
Da die AS-Pfade der beiden konkurrierenden Routen bekannt sind, kann nach _Probes_ in den dort gelisteten ASNs gesucht werden.
Dazu wird von hinten (vom jeweiligen Origin-AS) mit der Suche begonnen um sicherzustellen, dass sich die ausgewählten _Probes_ möglichst nah an dem jeweiligen Origin-AS befinden.

Wenn zwei solcher _Probes_ gefunden wurden, wird von beiden _Probes_ aus eine Verbindung zu dem TLS-Dienst aufgebaut und das TLS-Zertifikat abgefragt.
Anschließend können die beiden Zertifikate verglichen werden um festzustellen, ob sie identisch sind oder falls nicht, welches der beiden Zertifikate nicht auf den betroffenen Präfix ausgestellt wurde.
Falls die Zertifikate unterschiedlich sind oder der Dienst aus einer der Partitionen gar nicht erreichbar ist, ist das ein starkes Zeichen dafür, dass es sich tatsächlich um einen Prefix-Hijacking-Angriff handelt.
Falls die Zertifikate jedoch identisch sind, handelt es sich höchstwahrscheinlich um einen legitimen Anwendungsfall eines MOAS-Konflikts, wie zum Beispiel bei _Multihoming_.

In diesem Prozess durchläuft ein Präfix $p$ mehrere Zustände:

- _Unrecognized_: Es wurde noch keine Nachricht empfangen, die $p$ betrifft. $p$ ist nicht in der lokalen Tabelle enthalten.
- _Single Origin_: $p$ wird mit genau einem Origin-AS assoziiert.
- _Potential Hijack_: Es wurde ein MOAS-Konflikt für $p$ identifiziert.
- _Likely Hijack_: Die vorgestellte TLS-Methode hat ergeben, dass $p$ von einem Prefix-Hijacking-Angriff betroffen ist.
- _Safe MOAS_: Die vorgestellte TLS-Methode hat ergeben, dass $p$ ein legitimer MOAS-Konflikt ist.

In den folgenden Kapiteln gilt es herauszufinden, ob und wie zuverlässig diese Methode in der Praxis funktioniert um falsch positive Ergebnisse zu minimieren.

== Einschränkungen

Das vorgestellte Konzept hat einige Einschränkungen, die im Folgenden erläutert werden.

Der hier vorgestellte Ansatz erkennt nicht alle Arten von BGP-Hijackings, wie zum Beispiel Path-Spoofing-Angriffe.
Es werden nur Prefix-Hijacking-Angriffe erkannt.

Voraussetzung für den Erfolg dieser Methode ist außerdem, dass ein TLS-Dienst im betroffenen Präfix betrieben und gefunden wird.
Falls kein solcher Dienst existiert, können keine TLS-Zertifikate abgefragt werden.

Es ist außerdem notwendig, dass sich in beiden Partitionen des MOAS-Konflikts mindestens eine _RIPE Atlas_ _Probe_ befindet.

Davon abgesehen ist es möglich, dass ein Angreifer Zugriff auf das TLS-Zertifikat des Opfers hat und dieses auf einem Server im Angreifer-AS verwendet.
In diesem Fall erkennt die vorgestellte Methode den Prefix-Hijacking-Angriff nicht und es kommt zu einem falsch negativen Ergebnis.

// - Erkennt keine BGP-Hijackings, die nicht Prefix-Hijackings sind
// - Erkennt keine MOAS-Präfixe, die keinen TLS-Dienst haben

// - Eigene Gedanken
// - Terminus festlegen
//   - Für eine Arbeit entscheiden
// - Darstellung möglicher Lösungsansätze
// - Bewertung der Lösungsansätze

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

#pagebreak()
