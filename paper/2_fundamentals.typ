= Grundlagen

Im Folgenden werden die Grundlagen zum Thema Inter-AS-Routing und BGP-Hijacking dargestellt.

Was umgangssprachlich "das Internet" genannt wird ist ein dezentrales Netzwerk von tausenden autonomen Systemen (AS) und Routern, die Daten untereinander austauschen.
Damit ein Datenpaket zuverlässig von A nach B kommt muss es meistens mehrere Router passieren um schließlich sein Ziel zu erreichen.
Dabei muss an jeder Stelle an der das Paket vorbeikommt, klar sein wohin es als nächstes geschickt werden soll um möglichst effizient sein Ziel zu erreichen.
#figure(caption: "Beispielnetzwerk")[
  #image(width: 30em, "images/example_network.drawio.pdf")
]

// #v(1fr)
// #line(length: 100%)

// - Grundlagen/Fakten darstellen
// - Vorstellung der Grundlagen
//   - "Das Internet" besteht aus tausenden autonomen Systemen (ASs) und Routern, die Daten untereinander austauschen
//   - Um Daten erfolgreich austauschen zu können muss ein Router immer wissen wo ein Datenpaket als nächstes hingeschickt werden muss um sein Ziel zu erreichen
//   - Verbindungen zwischen ASs (Topologie) ändern sich dauernd
//   - BGP de-facto Standard um Änderungen der Netzwerktopologie zwischen ASs zu kommunizieren
//   - Grafik mit Beispiel BGP-Session
//   - BGP ist unverschlüsselt und basiert auf gegenseitigem Vertrauen
//   - BGP-Hijacking und MOAS-Konflikte
//   - Welche Auswirkungen hat BGP-Hijacking?
//     - Übernahme von IP-Addressbereichen
//     - Illegale Aktivitäten: Spamming/Scamming (z.B. Phishing)

@rfc1654

#pagebreak()
