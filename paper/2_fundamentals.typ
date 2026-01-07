#import "@preview/dashy-todo:0.1.3": todo

= Grundlagen

Im Folgenden werden die Grundlagen zum Thema Inter-AS-Routing und BGP-Hijacking dargestellt.

Das Internet ist ein dezentrales Netzwerk von tausenden autonomen Systemen (kurz: AS) bestehend aus Routern und anderen Netzwerkgeräten, die Daten untereinander austauschen.

Um einzelne Netzwerkgeräte zu adressieren werden IP-Adressen genutzt, welche 32-bit (IPv4) bzw. 128-bit (IPv6) Zahlen sind.
Um ganze Netzwerke, sprich mehrere IP-Adressen adressieren zu können, kommen IP-Präfixe zum Einsatz.
Ein IP-Präfix erlaubt es mehrere aufeinanderfolgende IP-Adressen als Einheit zu adressieren und erleichtert somit den gebündelten Austausch von Routing-Informationen.
Dadurch wird das Handeln und Verwalten von IP-Adressen und deren Nutzungsrechten vereinfacht.
In dieser Arbeit werden IP-Präfixe in der _Classless Inter-Domain Routing_ (kurz: CIDR) Notation dargestellt.

== BGP

Damit ein Datenpaket zuverlässig von A nach B kommt, muss es meistens mehrere Router passieren um schließlich sein Ziel zu erreichen.
Dabei muss an jedem Router an dem das Paket vorbeikommt, klar sein wohin es als nächstes geschickt werden soll um möglichst effizient sein Ziel zu erreichen.
Dafür stehen die Router der verschiedenen AS im ständigen Austausch miteinander, auch um auf Änderungen in der Netzwerktopologie reagieren zu können und die bestehenden Verbindungen zu allen AS weiter auf effizientestem Weg sicherzustellen.
Das etablierte Protokoll, welches diesen Austausch ermöglicht, nennt sich _Border Gateway Protocol_ (kurz: BGP).
Mithilfe der Informationen, die durch BGP-Nachrichten von anderen AS empfangen werden, pflegt jeder Router eine eigene Routing-Tabelle, die den aktuellen Zustand des Netzwerks aus Sicht dieses Routers abbildet.

#figure(caption: "Einfaches Beispielnetzwerk mit drei autonomen Systemen")[
  #image(width: 22em, "images/example_network.drawio.pdf")
] <example_network>
@example_network zeigt ein beispielhaftes Netzwerk mit drei autonomen Systemen und mehreren Routern.
Daten, die von Punkt A nach H geschickt werden nutzen dafür beispielsweise die Route $"A" -> "C" -> "D" -> "J" -> "H"$.

Die zwei wichtigsten Nachrichten bei einer BGP-Verbindung sind die OPEN- und die UPDATE-Nachricht.
Eine OPEN-Nachricht wird einmalig beim Herstellen der Verbindung zwischen zwei Routern ausgetauscht.
Sie beinhaltet unter anderen die AS-Nummer (kurz: ASN) des AS des Absenders.
Nach dem Austausch der OPEN-Nachrichten können UPDATE-Nachrichten ausgetauscht werden, die Routen zurückziehen und neue Routen verkünden können.
Eine Route bedeutet in diesem Fall eine geordnete Liste von ASN für einen bestimmten Präfix.
Diese Route wird durch das AS_PATH-Attribut in der UPDATE-Nachricht dargestellt.
Das letzte AS in der Liste wird Origin-AS genannt und ist das AS bei dem der Datenverkehr für den Präfix letztendlich landet.
Wenn mit einer UPDATE-Nachricht eine neue Route verkündet wird, enthält sie ein NEXT_HOP-Attribut, das angibt an welche IP-Adresse ein Datenpaket weitergeschickt werden soll, um von der verkündeten Route Gebrauch zu machen.
@rfc1654

#figure(caption: "Beispiel für drei BGP-UPDATE-Nachrichten")[
  #image(width: 30em, "images/bgp_updates.drawio.pdf")
] <bgp_update_example>

@bgp_update_example zeigt beispielhaft drei echte BGP-UPDATE-Nachrichten, die den IPv4-Präfix `186.1.198.0/24` betreffen und am 27. Dezember 2025 mithilfe von RIPE RIS aufgezeichnet wurden.
Die erste Nachricht wird von einem Router von Télécommunications de Haití (AS 52260) zu einem Router der LD Telecommunications Inc. (AS 32270) geschickt und verkündet, dass der Präfix `186.1.198.0/24` über den Router mit der IP-Adresse `190.102.95.102` (NEXT_HOP) zu erreichen ist.
Diese Nachricht wird von AS zu AS weitergeschickt bis sie schließlich einen Router des DFN (AS 680) erreicht.
Die in der Nachricht enthaltenen Attribute sagen dem DFN (AS 680), dass der Präfix `186.1.198.0/24` über den Pfad $"AS 1299" -> "AS 32270" -> "AS 52260"$ zu erreichen ist, indem eine Verbindung mit einem bestimmten Router von Arelion (AS 1299) aufgebaut wird.
Diese Information merkt sich der Router in seiner Routing-Tabelle und kann sie somit abrufen sobald er in Zukunft ein Paket an eine Adresse aus diesem Präfix empfängt.

== BGP-Hijacking

Ein Problem des BGP ist jedoch, dass eine Verbindung standardmäßig vollständig unverschlüsselt und ohne Authentifizierung abläuft.
BGP basiert auf gegenseitigem Vertrauen zwischen den beteiligten AS.
Das bedeutet, dass beliebige Routen bekanntgegeben werden können ohne dass unabhängig überprüft werden kann, ob diese valide sind.
Das können sich Angreifer zunutze machen um Datenverkehr ohne die Erlaubnis des eigentlichen Inhabers umzuleiten oder anderweitig zu manipulieren.
Diese Art von Angriff heißt BGP-Hijacking.
@quentin

Zwar existieren BGP-Erweiterungen wie zum Beispiel _Resource Public Key Infrastructure_ (kurz: RPKI) um dieses Problem anzugehen, jedoch ist die Verbreitung dieser Gegenmaßnahmen noch nicht sehr weit fortgeschritten.
Eine Messung von April 2025 zeigt, dass weltweit 50~% bis 60~% der gerouteten IP-Präfixe von RPKI-Zertifikaten abgedeckt sind.
@ru-RPKI-ready
Also ist 40~% bis 50~% des globalen Adressbereichs nicht von RPKI-Zertifikaten abgedeckt und damit anfällig für BGP-Hijacking-Angriffe.

=== Prefix-Hijacking und MOAS-Konflikte

Ein Prefix-Hijacking-Angriff ist ein spezieller Fall eines BGP-Hijacking-Angriffs, der für diese Arbeit von besonderem Interesse ist.
In diesem Fall gibt ein Angreifer-AS $A$ einen Präfix $p$ als seinen eigenen bekannt während das rechtmäßige Origin-AS $T$ diesen Präfix ebenfalls weiter verkündet.
$T$ wird auch True-Origin-AS genannt.
Dadurch entstehen zwei konkurrierende Routen für denselben Präfix $p$.
Router, die eine UPDATE-Nachricht von beiden AS erhalten, müssen sich dann entscheiden welche Route sie in ihre Routing-Tabelle aufnehmen.
In der Regel wird die Route mit dem kürzeren AS-Pfad bevorzugt.
Dadurch kann es passieren, dass von bestimmten AS der Datenverkehr für den Präfix $p$ zum Angreifer-AS $A$ umgeleitet wird, obwohl $T$ das True-Origin-AS des Präfixes ist.
Das teilt das Netzwerk effektiv in zwei Partitionen.
In der einen Partition befinden sich die AS, welche sich für die Route von $A$ entscheiden und in der anderen Partition die AS, welche sich für die Route von $T$ entscheiden.
@quentin

Diese Situation wird auch Multiple-Origin-AS-Konflikt (kurz: MOAS-Konflikt) genannt und ist nicht zwingend bösartig, da es auch legitime Anwendungsfälle wie zum Beispiel
_Multihoming_ #footnote[Bei _Multihoming_ wird ein Präfix gezielt von mehreren AS gleichzeitig verkündet um Datenverkehr auf mehrere Verbindungen zu verteilen und so die Ausfallsicherheit zu erhöhen. Hierbei handelt es sich um einen legitimen MOAS-Konflikt.] gibt.
Ein Prefix-Hijacking-Angriff ist ein bösartiger MOAS-Konflikt.

#figure(caption: "Beispiel für ein Netzwerk während eines MOAS-Konflikts mit AS 1 als True-Origin und Angreifer AS 5")[
  #image("images/moas.drawio.pdf")
] <moas-example>

@moas-example stellt ein beispielhaftes Netzwerk bestehend aus 6 AS während eines MOAS-Konflikts mit $T="AS 1"$ und $A="AS 5"$ dar.
Die beiden Partitionen, die dabei entstehen sind hier mit einer roten Linie getrennt, die zeigt, welche AS näher an $T$ bzw. $A$ liegen.
AS 3 liegt dabei von beiden gleich weit entfernt.
Wenn AS 5 nun ein Announcement mit einem Präfix bekanntgibt, welcher zeitgleich von AS 1 veröffentlicht wird, werden die AS links der Linie dem Pfad zu AS 1 folgen und die AS rechts der Linie dem Pfad zu AS 5 folgen.
So kann der Angreifer AS 5 den Datenverkehr von AS 4, AS 6 und möglicherweise AS 3 abfangen und dafür sorgen, dass dieser nicht mehr das eigentliche Ziel erreicht.

=== Auswirkungen

MOAS-Konflikte sind immer wieder das Ergebnis von fehlerhaften Router-Konfigurationen.
Es wird jedoch auch als Mittel von Angreifern genutzt um illegale Aktivitäten durchzuführen.
Unter anderem werden mithilfe von übernommenen IP-Adressbereichen Spam-E-Mails verschickt und Phishing-Webseiten betrieben.
Es werden gezielt IP-Adressbereiche angegriffen, die nicht auf IP-Blacklists gelistet sind.
Somit bleibt der Angriff länger von automatischen Filtern unerkannt und es ist möglicherweise aufwändiger die Angreifer zu identifizieren.
@quentin

// - Grundlagen/Fakten darstellen
// - Vorstellung der Grundlagen
//   - "Das Internet" besteht aus tausenden autonomen Systemen (AS) und Routern, die Daten untereinander austauschen
//   - Um Daten erfolgreich austauschen zu können muss ein Router immer wissen wo ein Datenpaket als nächstes hingeschickt werden muss um sein Ziel zu erreichen
//   - Verbindungen zwischen AS (Topologie) ändern sich dauernd
//   - BGP de-facto Standard um Änderungen der Netzwerktopologie zwischen AS zu kommunizieren
//   - Grafik mit Beispiel BGP-Session
//   - BGP ist unverschlüsselt und basiert auf gegenseitigem Vertrauen
//   - BGP-Hijacking und MOAS-Konflikte
//   - Welche Auswirkungen hat BGP-Hijacking?
//     - Übernahme von IP-Adressbereichen
//     - Illegale Aktivitäten: Spamming/Scamming (z.B. Phishing)

#pagebreak()
