#show raw: set text(size: 9pt)

= Implementierung

== Softwarearchitektur

Um das vorgestellte Konzept umzusetzen, wird das Projekt in mehrere Komponenten aufgeteilt.
@architecture stellt diese Komponenten und deren Verhältnis zueinander, sowie den Datenfluss der Software dar.
Dabei sind verwendete Datenbanksysteme als Zylinder und Programme als Rechtecke dargestellt.
Eigens entwickelte Programme sind blau hervorgehoben und werden im Folgenden näher erläutert.

#figure(caption: "Softwarearchitektur und Datenfluss")[
  #image("images/architecture.drawio.pdf")
] <architecture>

=== Ingest

Die Aufgabe des Ingest-Programms ist es BGP-Daten von _RIPE RIS_ abzurufen und eine globale Routing-Tabelle zu pflegen, die zur späteren Analyse verwendet werden kann.

Wenn das Ingest-Programm anfangs eine leere `routes`-Tabelle vorfindet, wird diese mit einem _RIB Dump_ von _RIPE RIS_ gefüllt.
Ein _RIB Dump_ beinhaltet die gesamte Routing-Tabelle eines Routers und dient somit ideal dazu die `routes`-Tabelle zu initialisieren.
Da die _RIB Dumps_ jedoch nur alle acht Stunden generiert werden, werden außerdem alle Update-Archive heruntergeladen, die seit dem _RIB Dump_ generiert wurden und auf die lokale Routing-Tabelle angewendet.
Am Ende dieses Initalisierungsprozesses ist die lokale Routing-Tabelle also höchstens fünf Minuten veraltet.

Anschließend baut das Programm eine Verbindung zum _RIPE RIS_ Live-Feed auf und leitet alle empfangenen UPDATE-Nachrichten an das Datenbanksystem _ClickHouse_ weiter.
_ClickHouse_ ist eine spaltenorientierte Datenbank, die speziell auf das Sammeln und Auswerten einer großen Menge von Daten ausgelegt ist.
Es nutzt außerdem Komprimierung um den verbrauchten Speicherplatz möglichst klein zu halten.
Das macht es ideal zum Speichern der BGP-Updates, da in sehr kurzer Zeit sehr viele Daten anfallen.
Die BGP-Updates werden gespeichert um sie später bei der manuellen Auswertung nutzen zu können.

Die Hauptaufgabe von Ingest ist es jedoch alle empfangenen UPDATE-Nachrichten auf die lokale Routing-Tabelle anzuwenden,
welche als Tabelle in einer _PostgreSQL_-Datenbank gespeichert wird.

#figure(caption: [Datenbankschema der `routes` Tabelle])[
  ```sql
  -- The live routing table
  CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
      host SMALLINT NOT NULL, -- e.g. 21 for "rrc21"
      as_path JSONB NOT NULL, -- ordered, origin last
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (prefix, peer_ip, host) -- one route per prefix and peering session
  );
  ```
] <routes-sql>

@routes-sql zeigt das Datenbankschema der Tabelle.
Dank der _PostgreSQL_-Datentypen ```sql CIDR``` und ```sql INET``` können dabei IP-Präfixe und -Adressen möglichst effizient gespeichert werden.

// TODO: origin_asn und as_path Typen genauer erläutern
Die Spalte `origin_asn` speichert das letzte Element von `as_path`.
Das BGP-Protokoll unterstützt in AS-Pfaden neben einzelnen AS-Nummern auch das Zusammenführen von mehreren AS-Nummern zu einem AS-Set. @rfc1654
Aus diesem Grund ist der Datentyp der `origin_asn`-Spalte ```sql BIGINT[]``` statt ```sql BIGINT```.

Die Kombination von `peer_ip` (_Vantage Point_) und `host` (_RIPE RIS RRC_) identifiziert eine Peering-Session
zwischen _RIPE RIS_ und einem anderen AS, was in Kombination mit einem Präfix die `UNIQUE`-Bedingung bildet.
Diese stellt sicher, dass immer nur jeweils eine Route pro Präfix und Peering-Session gespeichert wird.
Der Peer ist dabei der _Vantage Point_ vom welchem _RIPE RIS_ die Daten ersprünglich empfangen hat.

#figure(caption: "SQL-Abfrage um ein BGP-Update auf die lokale Routing-Tabelle anzuwenden")[
  ```sql
  INSERT INTO routes
      (prefix, origin_asn, peer_asn, peer_ip, host, as_path, updated_at)
  VALUES ($1, $2, $3, $4, $5, $6, $7)
  ON CONFLICT (prefix, peer_ip, host) DO UPDATE SET
      origin_asn = EXCLUDED.origin_asn,
      peer_asn = EXCLUDED.peer_asn,
      as_path = EXCLUDED.as_path,
      updated_at = EXCLUDED.updated_at;
  ```
] <routes-upsert>

@routes-upsert zeigt die SQL-Abfrage mit der eine Route in der Routing-Tabelle eingefügt bzw. aktualisiert wird.
Die Parameter `$1` bis `$7` werden mit den entsprechenden Daten von _RIPE RIS_ gefüllt.
Falls die neue Route mit einer bereits bestehenden Route in Konflikt steht, wird die bestehende Route mit den Werten der neuen aktualisiert.
Das simuliert das Verhalten eines normalen Routers.

// - Globale Routing-Tabelle pflegen
// - Seeding mit bviews und updates von RIPE RIS
// - Was sind bview und updates?
// - Danach: Live Announcements empfangen und Routing-Tabelle aktualisieren
// - Updates weiterleiten an Clickhouse DB
// - Clickhouse DB speichert alle BGP-UPDATE-Nachrichten zur späteren Analyse
// - PostgreSQL speichert aktuelle Routing-Tabelle
// - Upsert Query zeigen und erklären warum diese so lange dauert
//   - Größe der Tabelle, mehr dazu in @evaluation
//   - Einfache Lösung: Nicht alle RIS RRCs
//   - Zukünftige Lösungen, mehr dazu in @conclusion
// - Konfigrationsoptionen

=== MOAS Analysis

Die Aufgabe des MOAS-Analysis-Programms ist es MOAS-Präfixe zu erkennen und diese weitergehend zu analysieren.

Zuerst werden alle Präfixe gefunden, die von verschiedenen Origin-AS gleichzeitig verkündet werden.
Dazu wird die Routing-Tabelle mithilfe der SQL-Abfrage in @moas-scan-sql nach solchen Präfixen durchsucht.

#figure(caption: "SQL-Abfrage zum Identifizieren von MOAS-Präfixen")[
  ```sql
  SELECT
      prefix,
      array_agg(DISTINCT origin_asn[1] ORDER BY origin_asn[1]) AS origins,
      max(updated_at) AS updated_at
  FROM routes
  WHERE array_length(origin_asn, 1) = 1
  GROUP BY prefix
  HAVING count(DISTINCT origin_asn[1]) > 1;
  ```
] <moas-scan-sql>

Hier wurde sich explizit dafür entschieden AS-Sets zu ignorieren.
Das macht die Analyse anfangs etwas einfacher.

Nachdem die Liste von MOAS-Präfixen generiert wurde, können außerdem Origins aussortiert werden, welche in allen AS-Pfaden des Präfixes auftauchen.

Die übrigen Präfixe werden nun in einer Tabelle der PostgreSQL-Datenbank gespeichert.
Das Schema dieser Tabelle ist @moas-schema-sql zu entnehmen.

#figure(caption: [Datenbankschema der `moas` Tabelle])[
  ```sql
  CREATE TABLE moas (
      prefix CIDR PRIMARY KEY,
      origins BIGINT[] NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL,
      https_hosts INET[] DEFAULT ARRAY[]::INET[],
      last_scanned_at TIMESTAMPTZ DEFAULT NULL
  );
  ```
] <moas-schema-sql>

In den übrigen Präfixen soll nun, wie in @concept vorgestellt, ein TLS-Host gefunden werden.
Das vorher beschriebene Vorgehen mit _Shodan_ funktioniert nicht, da zu viele MOAS-Präfixe gefunden werden.
_Shodan_ ist ohne bezahlten Zugang nicht auf eine große Menge von Anfragen ausgelegt. @shodan
Die genauen Zahlen finden sich später in @evaluation.
Als Alternative wurde für diese Arbeit das ebenfalls populäre Programm _zmap_ @zmap gewählt.
Damit lassen sich ganze IP-Adressbereiche in kurzer Zeit selbst scannen.
Da für diesen Schritt lediglich die Existenz eines TLS-Hosts von Bedeutung ist, reicht ein einfacher _zmap_-Aufruf aus.

#figure(caption: [_zmap_-Befehl zum scannen jeder IP-Adresse in einem Präfix auf Port 443])[
  ```shell-unix-generic
  zmap --output-file=- --target-ports=443 <prefix>
  ```
] <zmap-call>

@zmap-call zeigt den _zmap_-Befehl der genutzt wird um einen gegebenen Präfix nach Hosts zu scannen.
Dabei ist hervorzuheben, dass der Befehl nur nach Diensten auf Port 443 sucht, welcher der Standardport für HTTPS-Server ist.
Falls ein TLS-Dienst auf einem anderen Port antworten sollte, wird dieser mit diesem Verfahren nicht gefunden.
Ebenfalls kann es passieren, dass auf Port 443 ein Dienst antwortet, welcher gar kein TLS-Dienst ist.

Nachdem die `zmap`-Scans durchgeführt wurden, werden alle Hosts, wie in @update-moas-sql gezeigt, aktualisiert.

#figure(caption: [SQL-Abfrage um die Ergebnisse von _zmap_ zu speichern])[
  ```sql
  UPDATE moas
  SET https_hosts = $1::INET[], last_scanned_at = NOW()
  WHERE prefix = $2::CIDR;
  ```
] <update-moas-sql>

Wie im nächsten Kapitel ebenfalls gezeigt wird, gibt es auch an dieser Stelle noch viele Treffer, weswegen die Analyse der Fälle mit _RIPE Atlas_ nicht automatisiert wurde.

// - MOAS Präfixe erkennen
// - Warum nicht Shodan wie anfangs vorgestellt?
//   - Alternative: Scan mit zmap @zmap
// - Port 443 mit zmap @zmap scannen
// - Anbindung an RIPE Atlas ist nicht automatisiert, da es noch zu viele falsch-positive Treffer gibt
//   - Mehr dazu in @evaluation

== Umsetzung mit Rust

Für die Entwicklung der oben erklärten Programme wurde die Programmiersprache _Rust_ gewählt.
_Rust_ ist eine gute Wahl für Programme, die in kürzester Zeit viele Daten verarbeiten müssen, wie das vorgestellte Ingest-Programm.
Abgesehen davon bietet _Rust_ ein vollumfängliches Ecosystem für alle genannten Datenbanksysteme.
Das macht _Rust_ zu einer sehr guten Wahl für diesen Anwendungsfall.

Die genutzten Software-Bibliotheken sind unter anderem `tokio`, `tokio-postgres`, `clickhouse`, das `serde`-Ecosystem,
das `scuffle`-Ecosystem sowie das `tracing`-Ecosystem, da diese die Entwicklung wesentlich einfacher und schneller machen.

#figure(caption: "Parallele Tasks und Datenfluss in Ingest")[
  #image(width: 20em, "images/ingest.drawio.pdf")
] <ingest-flow>

@ingest-flow zeigt die interne Struktur von Ingest.
Die Aufgaben, die Ingest übernimmt sind in verschiedene `tokio`-Tasks @tokio-docs aufgeteilt, sodass sie sich nicht
gegenseitig blockieren können und vollständig parallel zueinander ausgeführt werden können.
Zur Kommunikation zwischen den Tasks werden außerdem `tokio`-Channels @tokio-docs genutzt.

// - Libraries
// - Codebeispiele
// - Implementierungsdetails

#pagebreak()
