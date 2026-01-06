= Datenquellen

In diesem Kapitel werden die Datenquellen beschrieben, die zur Umsetzung des Konzepts in @concept dienen.

== RIPE RIS

_RIPE Routing Information Service_ (kurz: _RIPE RIS_) ist ein Dienst der von _RIPE NCC_ bereitgestellt wird.
_RIPE NCC_ ist die regionale Internet-Registrierungstelle (kurz: RIR) für Europa.
_RIPE RIS_ sammelt weltweit BGP-Daten von sogenannten _Vantage Points_ und stellt diese öffentlich zur Verfügung.
_Vantage Points_ sind Router, die BGP-Daten freiwillig mit _RIPE RIS_ teilen um die Forschung und das Verständnis des Internets zu fördern.
Die Daten werden sowohl als historische Archive als auch in Echtzeit über einen Live-Feed bereitgestellt.
@ripe-ris-docs

_RIPE RIS_ hat 780 _Vantage Points_ für IPv4 und 651 für IPv6 (Stand: Januar 2026). @ripe-ris-peer-count
Das bedeutet, dass nicht alle BGP-Routen des Internets erfasst werden, was zu blinden Flecken führen kann.

== Shodan

_Shodan_ ist eine öffentliche Datenbank, die Informationen über öffentlich erreichbare Geräte im Internet sammelt.
Dazu werden regelmäßig Scans durchgeführt, die verschiedene Dienste und deren Eigenschaften erfassen.
_Shodan_ bietet eine Suchmaschine an mit der gezielt nach bestimmten Geräten und Diensten gesucht werden kann.
@shodan

Die Aktualität und Vollständigkeit der Daten in _Shodan_ ist nicht garantiert, da die Scans nicht in Echtzeit durchgeführt werden.
Es kann also vorkommen, dass unerreichbare Dienste in _Shodan_ als erreichbar gelistet sind.

== RIPE Atlas

_RIPE Atlas_ ist ein weiterer Dienst von _RIPE NCC_ und besteht aus einem globalen Netzwerk von sogenannten _Probes_.
Ähnlich wie bei _Vantage Points_ werden auch _Probes_ weltweit von Freiwilligen betrieben.
_RIPE Atlas_ erlaubt es Nutzenden beliebige _Probes_ für Messungen zu verwenden.

_RIPE Atlas_ hat 14469 aktive _Probes_ in 183 verschiedenen Ländern (Stand: Januar 2026). @ripe-atlas-stats
Es gibt für ca. 6% aller ASs mindestens eine _Probe_. @ripe-atlas-stats

// - Grund truth
//   - RIPE RIS Live
//     - Vantage Points
//     - Wie viele VPs?
//   - RIPE Atlas
//     - Probes
//     - Wie viele Probes?
//   - Shodan
// - Mögliche Probleme der Quelle
// - Stealthy attacks

#pagebreak()
