
#import "../../data.typ": moas_routes_table, bgp_updates_table
#import "@preview/typslides:1.3.2": *

#title-slide[Implementierung: Ingest]

#let ris_image(content) = cols(columns: (1fr, auto))[
  #box(height: 12em)[
    #set align(top)
    #content
  ]
][
  #image(height: 16em, "../images/ripe_ris.drawio.pdf")
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
      host SMALLINT NOT NULL, -- e.g. 12 for "rrc12"
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
      host SMALLINT NOT NULL, -- e.g. 12 for "rrc12"
      as_path JSONB NOT NULL, -- ordered, origin last
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
      host SMALLINT NOT NULL, -- e.g. 12 for "rrc12"
      as_path JSONB NOT NULL, -- ordered, origin last
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ```
  ]
]

#slide(title: "Datenbankschema")[
  #ris_image[
    ```sql
    CREATE TABLE routes (
      prefix CIDR NOT NULL,
      origin_asn BIGINT[] NOT NULL,
      peer_asn BIGINT NOT NULL,
      peer_ip INET NOT NULL,
      host SMALLINT NOT NULL, -- e.g. 12 for "rrc12"
      as_path JSONB NOT NULL, -- ordered, origin last
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (prefix, peer_ip, host)
      -- one route per prefix and peering session
    );
    ```
  ]
]

#set figure(numbering: none)

#slide(title: "Evaluation")[
  #figure(caption: "Zeitraum: 1. April 2026, 18:00 Uhr bis 6. April 2026, 21:00 Uhr (UTC)", bgp_updates_table)
  #figure(caption: "Stand: 11. April 11:20:00 UTC", moas_routes_table)
]

#focus-slide[Grafana Dashboard]
