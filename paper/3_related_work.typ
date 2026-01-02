= Verwandte Arbeiten

Im diesem Kapitel werden Arbeiten betrachtet, die sich mit der Erkennung von Prefix-Hijacking-Angriffen beschäftigen.

// - Diskussion von Arbeiten
// - Zahlen darstellen
// - Quellen vergleichen
// - Andere Erkennungssysteme
//   - https://github.com/nttgin/BGPalerter, ARTEMIS
//     - Nur um eigenes Netzwerk zu monitoren, nicht global anwendbar
//     - Keine globale Erkennung ohne Vorwissen
//   - PHAS
//     - 2006
//     - Ohne Data Plane
//     - Nur sinnvoll bei eigenem Netzwerk
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
//   - A first step towards checking BGP routes in the dataplane
//     - 2022
//     - Vorschlag Routersoftware anzupassen, sodass Routen mithilfe von TLS und speziellen Validation Servern überprüft werden,
//       bevor sie in die Routing Tables eingefügt werden.
//     - Aufwändig einzuführen, da Software auf Routern angepasst/gepatcht werden muss
// 
//   - Quentin Jacquemart: Towards Uncovering BGP Hijacking Attacks
//     - Nicht fokussiert auf Live-Erkennung mit Realtime-Datenquellen, sondern auf Analyse von historischen Daten und BGP-Hijacking als Phänomen im Allgemeinen
// 
//    - BGPWatch

#pagebreak()
