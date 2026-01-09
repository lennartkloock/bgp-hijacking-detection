#import "util.typ": date, author

#heading(level: 1, outlined: false)[Selbstständigkeitserklärung]

Hiermit versichere ich, die vorliegende Arbeit ohne Hilfe Dritter nur mit den angegebenen Quellen und Hilfsmitteln angefertigt zu haben.
Alle Stellen, die aus Quellen entnommen wurden, sind als solche kenntlich gemacht.
Diese Arbeit hat in gleicher oder ähnlicher Form noch keiner Prüfungsbehörde vorgelegen.

#v(1cm)

#grid(
  align: bottom,
  row-gutter: 0.5em,
  columns: (1fr, 1fr),
  date(),
  [
    #image("images/signature.png", width: 7em)
    #v(0.25em, weak: true)
    #line(length: 12em, stroke: 0.5pt)
  ],
  [],
  author,
)

#pagebreak()
