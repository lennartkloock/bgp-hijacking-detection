#import "@preview/typslides:1.3.2": *

#slide(
  title: "Prefix Hijacking",
  cols(
    columns: (1fr, auto),
    box(height: 12em)[
      #set align(top)
      - #stress[Problem: BGP ist ohne Authentifizierung]
        - #stress[Basiert auf gegenseitigem Vertrauen zwischen AS]
    ],
    hide(image("images/moas.drawio.pdf", height: 15em)),
  ),
)

#slide(
  title: "Prefix Hijacking",
  cols(
    columns: (1fr, auto),
    box(height: 12em)[
      #set align(top)
      - Problem: BGP ist ohne Authentifizierung
        - Basiert auf gegenseitigem Vertrauen zwischen AS
      - #stress[Ein beliebiges AS kann verkünden, dass es der Ursprung eines beliebigen IP-Präfixes ist]
        - #stress[MOAS-Konflikt]
    ],
    hide(image("images/moas.drawio.pdf", height: 15em)),
  ),
)

#slide(
  title: "Prefix Hijacking",
  cols(
    columns: (1fr, auto),
    box(height: 12em)[
      #set align(top)
      - Problem: BGP ist ohne Authentifizierung
        - Basiert auf gegenseitigem Vertrauen zwischen AS
      - Ein beliebiges AS kann verkünden, dass es der Ursprung eines beliebigen IP-Präfixes ist
        - MOAS-Konflikt
      - #stress[Teilt das Netzwerk effektiv in zwei Partitionen]
    ],
    image("images/moas.drawio.pdf", height: 15em),
  ),
)
