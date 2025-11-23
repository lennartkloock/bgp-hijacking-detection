#import "util.typ": accent_color

#show bibliography: it => {
  show link: set text(fill: accent_color)
  it
}

#bibliography("bibliography.yaml", title: "Literaturverzeichnis", style: "din-1505-2-alphanumeric.csl")

#pagebreak()
