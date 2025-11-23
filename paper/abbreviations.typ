#import "util.typ": accent_color

#let abbreviations = (
  "BGP": "Border Gateway Protocol",
)

#let abbr(name) = {
  link(label(name), text(fill: accent_color, name))
}

#heading(numbering: none)[Akronyme]

#let make_row(abbr, long) = {
  ([*#text(fill: accent_color, abbr)* #label(abbr)], [#long])
}

#grid(
  columns: 2,
  column-gutter: 1em,
  row-gutter: 0.6em,
  ..abbreviations.pairs().sorted().map(abbr => make_row(..abbr)).flatten()
)

#pagebreak()
