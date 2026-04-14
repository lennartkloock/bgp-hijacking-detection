#import "util.typ": display_number, display_percent

= Evaluation <evaluation>

Folgendes Kapitel beschäftigt sich mit der Auswertung und Interpretation der gesammelten Daten.

#let bgp_updates_total = 347833140
#let bgp_announcements = 329703193
#let bgp_withdrawals = 18486327

#figure(caption: "BGP-Updates im Zeitraum 1. April 2026, 18:00 Uhr bis zum 6. April 2026, 21:00 Uhr (UTC)")[
  #table(
    columns: 3,
    align: left,
    table.header[*Wert*][*absolut*][*relativ*],
    [Anzahl BGP-Updates], display_number(bgp_updates_total), display_percent(1),
    "    davon Announcements",
    display_number(bgp_announcements),
    display_percent(bgp_announcements / bgp_updates_total),

    "    davon Withdrawals", display_number(bgp_withdrawals), display_percent(bgp_withdrawals / bgp_updates_total),
  )
] <clickhouse-stats>

Wie @clickhouse-stats zu entnehmen ist, wurden im Zeitraum vom 1. April 2026, 18:00 Uhr bis zum 6. April 2026, 21:00 Uhr (Zeitzone: UTC)
ca. 347,8 Millionen BGP-Updates aufgezeichnet.
Ingest war in dem genannten Zeitraum so konfiguriert, dass lediglich BGP-Updates von _RIPE RIS_ RRC12 empfangen werden,
da die SQL-Abfrage aus @routes-upsert zu langsam ist, um BGP-Updates von allen _RRCs_ zu verarbeiten.
Durchschnittlich wurden in diesem Zeitraum also ca. 786 BGP-Updates pro Sekunde empfangen.

#figure(caption: "Empfangene BGP-Updates pro Sekunde im betrachteten Zeitraum")[
  #image("images/updates.png", width: 100%)
] <updates-per-second>

@updates-per-second zeigt wie viele BGP-Updates pro Sekunde im betrachteten Zeitraum verarbeitet wurden.
Für die rot markierten Abschnitte liegen keine Daten vor, da das Programm zwischenzeitlich beendet oder neugestartet wurde.
Dabei handelt es sich meistens um das bereits erwähnte Zeitfenster von 5 Minuten.

#let routes_total = 42534222;
#let routes_4 = 34339723;
#let routes_6 = 8194499;

#let moas_total = 6454;
#let moas_4 = 5378;
#let moas_6 = 1076;

#figure(caption: "Anzahl Routen und MOAS-Präfixe (Stand: 11. April 11:20:00 UTC)")[
  #table(
    columns: 3,
    align: left,
    table.header[*Wert*][*absolut*][*relativ*],
    [Anzahl Routen], display_number(routes_total), display_percent(1),
    "    davon IPv4", display_number(routes_4), display_percent(routes_4 / routes_total),
    "    davon IPv6", display_number(routes_6), display_percent(routes_6 / routes_total),
    [Anzahl MOAS-Präfixe], display_number(moas_total), display_percent(1),
    "    davon IPv4", display_number(moas_4), display_percent(moas_4 / moas_total),
    "    davon IPv6", display_number(moas_6), display_percent(moas_6 / moas_total),
  )
] <routes-and-moas>

Wie @routes-and-moas zu entnehmen ist, wurden zum Zeitpunkt der Messung insgesamt #display_number(routes_total) Routen in der lokalen Routing-Tabelle gespeichert.
Davon sind #display_percent(routes_4 / routes_total) IPv4- und #display_percent(routes_6 / routes_total) IPv6-Präfixe.
Von den insgesamt #display_number(moas_total) erkannten MOAS-Präfixen sind #display_number(moas_4) IPv4-Präfixe
(#display_percent(moas_4 / moas_total)) und #display_number(moas_6) IPv6-Präfixe (#display_percent(moas_6 / moas_total)).
Damit weisen IPv4-Präfixe im Verhältnis zur Gesamtanzahl eine höhere MOAS-Rate auf als IPv6-Präfixe.

#let moas_origins_2 = 6035
#let moas_origins_3 = 355
#let moas_origins_4 = 25
#let moas_origins_5 = 28
#let moas_origins_6 = 6
#let moas_origins_7_up = 4

#figure(caption: "Anzahl MOAS-Präfixe mit n Origins (Stand: 11. April 11:20:00 UTC)")[
  #table(
    columns: 3,
    align: left,
    table.header[*Origins*][*absolut*][*relativ*],
    [2], display_number(moas_origins_2), display_percent(moas_origins_2 / moas_total),
    [3], display_number(moas_origins_3), display_percent(moas_origins_3 / moas_total),
    [4], display_number(moas_origins_4), display_percent(moas_origins_4 / moas_total),
    [5], display_number(moas_origins_5), display_percent(moas_origins_5 / moas_total),
    [6], display_number(moas_origins_6), display_percent(moas_origins_6 / moas_total),
    [7+], display_number(moas_origins_7_up), display_percent(moas_origins_7_up / moas_total),
  )
] <moas-origins>

#let less_than = calc.ceil(((moas_origins_3 + moas_origins_4 + moas_origins_5 + moas_origins_6 + moas_origins_7_up) / moas_total) * 100) / 100

@moas-origins zeigt, dass die große Mehrheit der MOAS-Konflikte genau zwei Origins hat (#display_percent(moas_origins_2 / moas_total)).
Konflikte mit drei oder mehr Origins sind deutlich seltener und machen zusammen weniger als
#display_percent(less_than) der Fälle aus.
Das deckt sich mit der Erwartung, dass legitimes _Multihoming_ typischerweise nur zwei AS involviert.
Eine größere Anzahl von Origins deutet auf komplexere Infrastrukturen oder Fehlkonfigurationen hin.

Im nächsten Schritt wurden alle #display_number(moas_4) IPv4-MOAS-Präfixe mit _zmap_ auf Dienste auf TCP-Port 443 gescannt, um potenzielle TLS-Hosts zu identifizieren.
#let at_least_one_host = 2152
Dabei wurde in #display_number(at_least_one_host) IPv4-Präfixen mindestens ein Host gefunden, der auf TCP-Port 443 antwortet, was einem Anteil von #display_percent(at_least_one_host / moas_4) entspricht.
In den verbleibenden #display_number(moas_4 - at_least_one_host) IPv4-Präfixen konnte kein solcher Host gefunden werden, weshalb für diese Fälle keine TLS-Analyse möglich ist.
Die IPv6-MOAS-Präfixe wurden ebenfalls von der Analyse ausgeschlossen, da ein _zmap_-Scan aufgrund der großen Zahl von Adressen zu lange dauern würde.

Aufgrund der hohen Anzahl verbleibender Kandidaten wurde die weitergehende Analyse mit _RIPE Atlas_ nicht automatisiert durchgeführt.
Stattdessen wurde ein Fall manuell untersucht, um die Funktionsfähigkeit zu demonstrieren.

Wie aus den gesammelten Daten hervorgeht, wird der Präfix `41.221.216.0/24` von AS `31713`, sowie von AS `3491` bekanntgegeben.
AS `31713` ist unter dem Namen "Gateway Communications" und AS `3491` unter dem Namen "PCCW Global (HK) Ltd." registriert.
Der _zmap_-Scan ergibt, dass es nur die IP-Adresse `41.221.216.10` mit Dienst auf TCP-Port 443 in diesem Präfix gibt.
(Stand: 12. April 18:00:00 UTC)
Um die weitere Analyse mithilfe von _RIPE Atlas_ durchzuführen müssen zuerst zwei Probes identifiziert werden von denen aus
die TLS-Anfragen geschickt werden können.
_RIPE Atlas_ erlaubt es einem alle Probes nach deren AS-Nummern zu filtern.
Eine Suche nach den beiden AS-Nummern der beiden Origin-AS ergibt mehrere Probes, die für die Messung infrage kommen.
Die Ergebnisse der #link("https://atlas.ripe.net/measurements/163261121/overview")[Messung] zeigen, dass alle _Probes_ dasselbe Zertifikat empfangen.
Das weißt darauf hin das sie entweder alle denselben Server erreichen oder unterschiedliche, die jedoch dasselbe Zertifikat nutzen.
Letzteres würde bedeuten, dass beide Server authorisiert sind, da sie beide Zugriff auf den privaten Schlüssel des Zertifikats haben.
Damit handelt es sich in diesem Fall um einen _Safe MOAS_-Präfix.

Insgesamt zeigt die Evaluation, dass MOAS-Konflikte ein häufig auftretendes Phänomen im globalen BGP-Routing sind.
Die große Mehrheit der Konflikte hat genau zwei Origins, was sowohl auf legitimes _Multihoming_ als auch auf einfache Prefix-Hijacking-Angriffe zutrifft.

Die Ergebnisse zeigen, dass die hier vorgestellte Methode prinzipiell genutzt werden kann, um legitime MOAS-Konflikte von potenziellen Prefix-Hijacking-Angriffen zu unterscheiden.
Es wird jedoch vorrausgesetzt, dass im betroffenen Präfix ein TLS-Dienst betrieben wird, was die Menge von Präfixen für die diese Methode angewandt werden kann, deutlich einschränkt.
Damit kann die Methode lediglich ergänzend genutzt werden und nicht als alleinige Grundlage für eine zuverlässige Prefix-Hijacking-Erkennung dienen.

#pagebreak()
