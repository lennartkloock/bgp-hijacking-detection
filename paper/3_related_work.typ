= Verwandte Arbeiten

In diesem Kapitel werden Arbeiten betrachtet, die sich mit der Erkennung von Prefix-Hijacking-Angriffen beschäftigen.

== Control-Plane Ansätze

Ein früher Ansatz zur Erkennung von Prefix-Hijacking-Angriffen ist das _Prefix Hijacking Alert System_ (kurz: _PHAS_) aus dem Jahr 2006. @phas
Das _PHAS_ arbeitet nur mit Daten aus der Control-Plane, also nur BGP-Daten die direkt von Routern gesammelt werden.
_PHAS_' Ziel ist es, Netzwerkadministratoren zu benachrichtigen, wenn ein Prefix-Hijacking-Angriff auf eines ihrer eigenen AS erkannt wird.
Das Ziel ist also nicht ein globales Erkennungssystem, sondern ein System, das nur das eigene Netzwerk überwacht.

Ähnlich wie _PHAS_ funktionieren auch die beiden Systeme _ARTEMIS_ @artemis und _BGPalerter_ @bgpalerter.
Die beiden Systeme sind ebenfalls darauf ausgelegt eigene Präfixe zu überwachen und Netzwerkadministratoren zu benachrichtigen, wenn ein Hijacking-Angriff erkannt wird.
Auch diese Systeme benötigen Vorwissen über das eigene Netzwerk um sie korrekt zu konfigurieren und sind nicht auf eine globale Erkennung alle Vorfälle ausgelegt.

== Data-Plane Ansätze

Im Folgenden werden Ansätze vorgestellt, die zusätzlich zu Daten aus der Control-Plane auch Daten aus der Data-Plane nutzen um Angriffe zu analysieren.
So können mehr Informationen gesammelt werden um potenzielle Angriffe besser einordnen zu können und falsch positive Treffer auszuschließen.
Ein Nachteil bei der Nutzung der Data-Plane ist jedoch, dass die Daten in Echtzeit gesammelt werden müssen, da sie nicht aus den BGP-Daten von Routern hervorgehen, sondern durch aktive und gezielte Messungen gewonnen werden müssen.
Das bedeutet, dass historische Ereignisse nicht im Nachhinein analysiert werden können.

In @hu-et-al @shi-et-al werden Ansätze entwickelt, die einfache ICMP-Pings und Netzwerkscans mit z.B. _nmap_ nutzen um Netzwerkgeräte zu fingerprinten.
Fingerprinting ist das Identifizieren von Geräten anhand bestimmter Merkmale, die das Gerät eindeutig kennzeichnen.
Die Zuverlässigkeit dieses Ansatzes ist jedoch fraglich, da Netzwerkscans und ICMP-Nachrichten von Firewalls blockiert werden können.

// Kein Ansatz zur Überwachung:
// Eine weitere Methode um Prefix-Hijacking-Angriffe zu verhindern, die 2022 in @wirtgen vorgeschlagen wird, ist die Überprüfung von Routen durch die Router selbst.
// Hierzu kommunizieren die Router mit extra dafür eingerichteten Validierungsservern noch bevor eine empfangene Route in die Routing-Tabelle aufgenommen wird.
// Diese Methode hat jedoch den Nachteil, dass die Router-Software angepasst werden muss und neue Infrastruktur benötigt wird.
// Das ist in der Praxis nur schwer umzusetzen, wie an dem langsamen Fortschritt bei der Verbreitung von _RPKI_ zu sehen ist.

Eine weitere Methode liefert das Open-Source-Projekt _BGPwatch_, welches BGP-Daten in Echtzeit analysiert.
Dazu werden potenzielle Hijacking-Angriffe identifiziert und mithilfe von vordefinierten Regeln gefiltert.
Anschließend werden alle Vorfälle mit KI-Modellen auf Basis von historischen BGP-Daten, IRR-Daten und RPKI-Daten bewertet um die Wahrscheinlichkeit eines echten Angriffs zu bestimmen.
Das Projekt wurde von _APNIC_ und der chinesischen Regierung unterstützt.
@bgpwatch

Alle vorgestellten Lösungen bieten damit also keine vollständige Genauigkeit, sondern nur eine Abschätzung der Wahrscheinlichkeit eines echten Angriffs.

// - Diskussion von Arbeiten
// - Zahlen darstellen
// - Quellen vergleichen
// - Andere Erkennungssysteme
//   - PHAS
//     - 2006
//     - Ohne Data Plane
//     - Nur sinnvoll bei eigenem Netzwerk
//   - https://github.com/nttgin/BGPalerter, ARTEMIS
//     - Nur um eigenes Netzwerk zu monitoren, nicht global anwendbar
//     - Keine globale Erkennung ohne Vorwissen
//   - Hu et al: Accurate real-time identification of IP prefix hijacking
//     - 2007
//     - ICMP pings und nmap Scans können von Firewalls blockiert werden
//   - Hong et al: IP prefix hijacking detection using idle scan
//     - 2009
//     - Benutzt spoofed TCP-Pakete für Fingerprinting
//     - Kann durch Firewalls verhindert werden
//     - Nicht 100% zuverlässig, wegen IP ID fingerprinting
//     - Nur IPv4, wegen IP ID
//     - Spoofing kann als Angriff gewertet werden
//   - Shi et al: Detecting prefix hijackings in the internet with Argus
//     - 2012
//     - ICMP pings
//     - Kann durch ICMP-Filter verhindert werden
//     - Keine kryptografisch sichere Methode um Hosts zu identifizieren
//
//   - Wirtgen: A first step towards checking BGP routes in the dataplane
//     - 2022
//     - Vorschlag Routersoftware anzupassen, sodass Routen mithilfe von TLS und speziellen Validation Servern überprüft werden,
//       bevor sie in die Routing Tables eingefügt werden.
//     - Aufwändig einzuführen, da Software auf Routern angepasst/gepatcht werden muss
// 
//   - Quentin Jacquemart: Towards Uncovering BGP Hijacking Attacks
//     - Nicht fokussiert auf Live-Erkennung mit Realtime-Datenquellen, sondern auf Analyse von historischen Daten und BGP-Hijacking als Phänomen im Allgemeinen
// 
//   - BGPWatch
//     - Erst logische Regel-basierte Filter
//     - Dann Bewertung mit KI-Methoden auf Datenbasis von historischen BGP-Daten, IRR-Daten und RPKI-Daten
//     - https://blog.apnic.net/2024/02/07/bgpwatch-a-comprehensive-platform-for-detecting-and-diagnosing-hijacking-incidents/
//     - Keine kryptografisch sichere Methode um Hosts zu identifizieren, basiert auf Vorhersagemodellen (keine 100% Sicherheit)

#pagebreak()
