#import "@preview/typslides:1.3.2": *

#title-slide[Das Border Gateway Protocol (BGP)]

#let example_table = [
  #set align(horizon)
  #cols(
    columns: (auto, auto),
    table(
      columns: 4, align: left, table.header[*Prefix*][*AS Path*][*Next Hop*][*Interface*],
      [`192.0.2.0/24`], [`2,3`], [`198.51.100.1`], [`eth0`],
      [`198.51.100.0/24`], [`2`], [`198.51.100.1`], [`eth0`],
      [`203.0.113.0/24`], [`4`], [`203.0.113.1`], [`eth1`],
      [...], [...], [...], [...],
      [`0.0.0.0/0`], [-], [`203.0.113.2`], [`eth1`],
    ),
    image("images/simple_bgp.drawio.pdf", height: 8.5em),
  )
]

#slide(title: "BGP")[
  #box(height: 14em)[
    #set align(top)
    - #stress[Router sind durch BGP verbunden und tauschen Routing-Informationen aus]
  ]
]

#slide(title: "BGP")[
  #box(height: 14em)[
    #set align(top)
    - Router sind durch BGP verbunden und tauschen Routing-Informationen aus
    - #stress[Jeder Router pflegt eine Routing-Tabelle mit Pfaden zu verschiedenen IP-Präfixen]
    #example_table
  ]
]

#slide(title: "BGP")[
  #box(height: 14em)[
    #set align(top)
    - Router sind durch BGP verbunden und tauschen Routing-Informationen aus
    - Jeder Router pflegt eine Routing-Tabelle mit Pfaden zu verschiedenen IP-Präfixen
    #example_table
    - #stress["Next Hop" speichert die IP-Adresse des nächsten Routers auf dem Pfad zum Zielpräfix] @rfc1654
  ]
]

#slide(title: "BGP")[
  #set align(top)
  - #stress[Routing-Tabellen werden durch BGP-Update-Nachrichten aktualisiert]
]

#slide(title: "BGP")[
  #set align(top)
  - Routing-Tabellen werden durch BGP-Update-Nachrichten aktualisiert
  - #stress[Echte BGP-Updates vom 27. Dezember 2025:]
  #align(center, image("images/bgp_updates_1.drawio.pdf", height: 15em))
]

#slide(title: "BGP")[
  #set align(top)
  - Routing-Tabellen werden durch BGP-Update-Nachrichten aktualisiert
  - #stress[Echte BGP-Updates vom 27. Dezember 2025:]
  #align(center, image("images/bgp_updates_2.drawio.pdf", height: 15em))
]

#slide(title: "BGP")[
  #set align(top)
  - Routing-Tabellen werden durch BGP-Update-Nachrichten aktualisiert
  - #stress[Echte BGP-Updates vom 27. Dezember 2025:]
  #align(center, image("images/bgp_updates_3.drawio.pdf", height: 15em))
]
