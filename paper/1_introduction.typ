#import "@preview/dashy-todo:0.1.3": todo

= Einleitung

BGP, als das de-facto Standardprotokoll für Inter-AS-Routing, basiert seit seiner Erfindung auf gegenseitigem Vertrauen.
Mit der Kommerzialisierung und dem Wachstum des Internets stellte sich das jedoch als immer größeres Problem heraus.
Dadurch, dass praktisch alle Beteiligten beliebige Routen bekannt geben können, ist das System anfällig für Angriffe und Konfigurationsfehler#todo[Besser "menschliche Fehler"?].
Das kann, wie die Vergangenheit gezeigt hat, zu schwerwiegenden Einschränkungen und Ausfällen des Internets führen.

In den letzten Jahrzehnten haben einige dieser Fälle international Aufsehen erregt und für Aufmerksamkeit#todo[Schlagzeilen?] gesorgt.
Einer der wohl bekanntesten Fälle trug sich im Februar 2008 zu als die Pakistanische Regierung den Zugang zu YouTube sperren ließ.
Die Zensurmaßnahme war für die Einwohner des eigenen Landes vorgesehen, wurde jedoch aufgrund eines Konfigurationsfehlers weltweit umgesetzt, was zu einem globalen Ausfall von YouTube führte, der mehrere Stunden andauerte.
@youtube-hijack
Auch in den letzten Jahren hat das Thema nicht an Relevanz verloren.
2022 wurden in einem organisierten BGP-Hijacking-Angriff ca. 234.000 \$ in Kryptowährung gestohlen.
@crypto-hijack
Diese und viele weitere Fälle zeigen, dass BGP-Hijacking weiterhin ein großes Problem des Internets darstellt.

Ziel dieser Arbeit ist es eine verlässliche Methode zu entwickeln um potenzielle BGP-Hijackings mithilfe von öffentlichen Datenquellen zu erkennen und in Echtzeit zu bewerten.
Dabei soll nicht nur die Kontrollebene#todo[Besser "control plane"?], sondern auch die Datenebene#todo[Besser "control plane"?] eingesetzt werden um Erkenntnisse über einen Angriff zu sammeln.
Es kann von Vorteil sein die Datenebene mit in die Analyse einzubeziehen, da dort möglicherweise Dienste betrieben werden, die Auskunft über den Betreiber dieser geben können.
Dienste, die TLS einsetzen, wie zum Beispiel Web-Server oder Email-Server, können dabei besonders hilfreich sein, da TLS kryptografische Zertifikate nutzt um die Authentizität eines Servers bestätigen zu können.
Diese Arbeit soll die Frage klären, ob das Abrufen von TLS-Zertifikaten als zuverlässige Methode genutzt werden kann um BGP-Hijackings zu erkennen.

Um dieses Ziel zu erreichen soll eine Software entwickelt werden, die die oben beschriebenen Methoden implementiert.

#v(1fr)
#line(length: 100%)

- Relevanz von BGP-Hijacking
  - BGP de-facto Standard für Routing zwischen ASs
  - BGP basiert auf Vertrauen zwischen Autonomen Systemen
  - BGP-Hijacking ist weiterhin ein großes Problem im Internet
  - Bekannte Fälle auflisten
- Forschungsfrage, Ziele und Teilziele
  - Echtzeit Nachweisen von BGP-Hijackings mithilfe der Datenebene (data plane)
  - Begrenzen auf TLS-Dienste, da diese Dienste potenziell am interessantesten für Angreifer sind
- Vorgehen zum Erreichen der Ziele
  - Entwickeln einer Erkennungssoftware auf Basis von öffentlichen Echtzeitdaten (Vantage Points)
- Einen Ausblick auf den Text

#pagebreak()
