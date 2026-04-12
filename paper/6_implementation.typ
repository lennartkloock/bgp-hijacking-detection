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

Die Aufgabe des Ingest-Programms ist es BGP-Daten von _RIPE RIS_ abzurufen und eine globale Routing-Tabelle zu pflegen,
die zur späteren Analyse verwendet werden kann.

Wenn das Ingest-Programm anfangs eine leere `routes`-Tabelle vorfindet,
wird diese mit einem _RIB Dump_ von _RIPE RIS_ initialisiert.
Ein _RIB Dump_ beinhaltet die gesamte Routing-Tabelle eines Routers und dient somit ideal dazu
die `routes`-Tabelle zu initialisieren.
Jeder _RIPE RIS RRC_ generiert alle acht Stunden ein _RIB Dump_, um 00:00 Uhr, 08:00 Uhr und 16:00 Uhr.
Das vorgestellte Programm berechnet den Zeitstempel des neusten _RIP Dumps_ und lädt diesen herunter.
Der _RCC_ wird über einen Konfigurationsparameter gewählt, welcher standardmäßig auf `rrc12` gesetzt ist.

Nachdem die lokale Routing-Tabelle mit einem _RIB Dump_ initialisiert wurde,
werden anschließend nacheinander alle _RIPE RIS_ Update-Archive heruntergeladen, die seit dem _RIB Dump_ generiert wurden.

#figure(caption: "Funktion zum Verarbeiten von Update-Dateien")[
  ```rs
  async fn process_updates(
      global: &Arc<Global>,
      ctx: &scuffle_context::Context,
      since: NaiveDateTime,
      rrc: u8,
  ) -> anyhow::Result<()> {
      tracing::info!(since = ?since, "starting to process updates");

      let mut current = since;

      while let Some(update_date) = next_update_date(current)
          && !ctx.is_done()
      {
          current = update_date;

          let url = update_url(rrc, update_date);
          let Some(file) = download_file(url, &global.config.cache_dir).await?
          else {
              tracing::warn!(
                  update_date = ?update_date,
                  "update file not found, skipping"
              );
              continue;
          };

          // process file
      }

      Ok(())
  }
  ```
] <process-updates-fn>

@process-updates-fn zeigt die gekürzte `process_updates`-Funktion, welche nacheinander alle Update-Dateien seit dem
übergebenen Zeitstempel `since` herunterlädt und verarbeitet.
Die Funktion `next_update_date` gibt den nächsten Zeitstempel zurück indem sie den übergebenen Zeitstempel auf
die nächste 5-Minuten-Marke aufrundet.
Falls dieser in der Zukunft liegen sollte, wird ```rs None``` zurückgegeben und die Schleife somit beendet.
Falls eine Update-Datei nicht auf dem _RIPE RIS_-Server gefunden wird, wird sie übersprungen.
`ctx` speichert den Kontext in dem das Programm ausgeführt wird.
Die `is_done`-Funktion gibt genau dann ```rs true``` zurück, wenn die Ausführung abgebrochen wurde
und das Programm beendet werden soll. @scuffle-context-docs

Am Ende dieses Initalisierungsprozesses ist die lokale Routing-Tabelle also im Normalfall höchstens fünf Minuten veraltet.

Sowohl während der Initialisierung als auch im Live-Betrieb verarbeitet das Programm UPDATE-Nachrichten auf dieselbe Weise.
Alle empfangenen UPDATE-Nachrichten werden an das Datenbanksystem _ClickHouse_ weitergeleitet.
_ClickHouse_ ist eine spaltenorientierte Datenbank, die speziell auf das Sammeln und Auswerten
einer großen Menge von Daten ausgelegt ist.
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
Dank der _PostgreSQL_-Datentypen ```sql CIDR``` und ```sql INET``` können dabei IP-Präfixe und -Adressen
möglichst effizient gespeichert werden.

Die Spalte `origin_asn` speichert das letzte Element von `as_path`.
Das BGP-Protokoll unterstützt in AS-Pfaden neben einzelnen AS-Nummern auch
das Zusammenführen von mehreren AS-Nummern zu einem AS-Set. @rfc1654
Aus diesem Grund ist der Datentyp der `origin_asn`-Spalte ```sql BIGINT[]``` statt ```sql BIGINT```.

Die Kombination von `peer_ip` (_Vantage Point_) und `host` (_RIPE RIS RRC_) identifiziert eine Peering-Session
zwischen _RIPE RIS_ und einem anderen AS, was in Kombination mit einem Präfix die `UNIQUE`-Bedingung bildet.
Diese stellt sicher, dass immer nur jeweils eine Route pro Präfix und Peering-Session gespeichert wird.
Der Peer ist dabei der _Vantage Point_ vom welchem _RIPE RIS_ die Daten ersprünglich empfangen hat.

#figure(caption: "SQL-Abfrage um ein BGP-Announcement auf die lokale Routing-Tabelle anzuwenden")[
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
Falls die neue Route mit einer bereits bestehenden Route in Konflikt steht, wird die bestehende Route mit den Werten der
neuen aktualisiert.

Beim Zurückziehen von BGP-Routen (Withdrawal), wird die entsprechende Route aus der Datenbank entfernt wie in @routes-delete
gezeigt.

#figure(caption: "SQL-Abfrage um ein BGP-Withdrawal auf die lokale Routing-Tabelle anzuwenden")[
  ```sql
  DELETE FROM routes WHERE prefix = $1 AND peer_ip = $2 AND host = $3;
  ```
] <routes-delete>

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

#figure(caption: [SQL-Abfrage zum Identifizieren von MOAS-Präfixen])[
  ```sql
  SELECT
      prefix,
      array_agg(DISTINCT origin_asn[1] ORDER BY origin_asn[1]) AS origins,
      max(updated_at) AS updated_at
  FROM routes
  WHERE array_length(origin_asn, 1) = 1 AND family(prefix) = 4
  GROUP BY prefix
  HAVING count(DISTINCT origin_asn[1]) > 1;
  ```
] <moas-scan-sql>

// TODO: indexierung bei [1] erklären
Hier wurde sich explizit dafür entschieden AS-Sets, sowie IPv6-Präfixe zu ignorieren.
Diese Einschränkungen machen die Analyse anfangs etwas einfacher.

Nachdem die Liste von MOAS-Präfixen generiert wurde, können außerdem Origins aussortiert werden,
welche in allen AS-Pfaden des Präfixes auftauchen.
// TODO: weiter ausführen

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
_Shodan_ ist ohne bezahlten Zugang nicht auf eine große Menge von Anfragen ausgelegt. @shodan-website
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

Wie im nächsten Kapitel ebenfalls gezeigt wird, gibt es auch an dieser Stelle noch viele Treffer,
weswegen die Analyse der Fälle mit _RIPE Atlas_ nicht automatisiert wurde.

// - MOAS Präfixe erkennen
// - Warum nicht Shodan wie anfangs vorgestellt?
//   - Alternative: Scan mit zmap @zmap
// - Port 443 mit zmap @zmap scannen
// - Anbindung an RIPE Atlas ist nicht automatisiert, da es noch zu viele falsch-positive Treffer gibt
//   - Mehr dazu in @evaluation

== Umsetzung mit Rust

Für die Entwicklung der oben erklärten Programme wurde die Programmiersprache _Rust_ gewählt.
_Rust_ ist eine gute Wahl für Programme, die in kürzester Zeit viele Daten verarbeiten müssen, wie das vorgestellte
Ingest-Programm.
Abgesehen davon bietet _Rust_ ein vollumfängliches Ecosystem für alle genannten Datenbanksysteme und
macht es vergleichweise einfach parallele Systeme zu entwickeln.
Das macht die Sprache zu einer sehr guten Wahl für diesen Anwendungsfall.

Die genutzten Software-Bibliotheken sind unter anderem `tokio`, `anyhow`, `tokio-postgres`, `clickhouse`, das
`serde`-Ecosystem, das `scuffle`-Ecosystem sowie das `tracing`-Ecosystem, da diese die Entwicklung wesentlich einfacher machen.

#figure(caption: "Parallele Tasks und Datenfluss in Ingest")[
  #image(width: 20em, "images/ingest.drawio.pdf")
] <ingest-flow>

@ingest-flow zeigt die interne Struktur von Ingest.
Die Aufgaben, die Ingest übernimmt sind in verschiedene `tokio`-Tasks @tokio-docs aufgeteilt, sodass sie sich nicht
gegenseitig blockieren und vollständig parallel zueinander ausgeführt werden können.
Zur Kommunikation zwischen den Tasks werden `tokio` Bound Channels @tokio-docs genutzt.
Diese dienen zum Senden und Empfangen von beliebigen Werten in parallelen Programmen.

Die `main`-Task des Programms wird als erstes gestartet und erstellt, sowie koordiniert die anderen Tasks.
Nachdem der oben beschriebene Initialisierungsprozess beendet wurde, erstellt `main` eine Task, die sich mit dem Live-Endpunkt
von _RIPE RIS_ verbindet um die BGP-Updates zu empfangangen und über einen `tokio`-Channel an die `main`-Task zu schicken.
Diese Task wird in @ingest-flow `watch RIS messages`-Task genannt.
Die `main`-Task sammelt mehrere Updates bis zu einer bestimmten Kapazitätsgrenze und sendet sie anschließend als sogenannten
_Batch_ an die `routes batcher`- und `events inserter`-Tasks.
Diese beiden Tasks sind für die Interaktion mit den Datenbanken zuständig und führen die oben genannten Schreiboperationen durch.

Für maximale Reproduzierbarkeit wird der Code öffentlich auf
#link("https://github.com/lennartkloock/bgp-hijacking-detection")[GitHub] bereitgestellt.
Die Software selbst ist außerdem ebenfalls auf GitHub als Docker-Image abrufbar.

// - Libraries
// - Codebeispiele
// - Implementierungsdetails

#pagebreak()
