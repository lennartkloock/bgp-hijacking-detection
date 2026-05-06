#import "@preview/typslides:1.3.2": *

#title-slide[Prefix-Hijacking-Angriffe]

#include "../prefix_hijacking.typ"

#slide(
  title: "Prefix Hijacking",
  cols(
    columns: (1fr, auto),
    box(height: 12em)[
      #set align(top)
      - #stress[Potentielle Angriffsszenarien:]
        - Blackholing
        - Man-in-the-Middle-Angriffe
        - "Klauen" von IP-Adressen zum Verschicken von E-Mail-Spam oder andere illegale Aktivitäten
    ],
    image("../images/moas.drawio.pdf", height: 15em),
  ),
)
