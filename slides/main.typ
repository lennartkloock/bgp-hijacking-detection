#import "@preview/typslides:1.3.2": *

#let author = "Lennart Kloock"

#set document(author: author, title: "Echtzeiterkennung von Prefix-Hijacking-Angriffen mithilfe von TLS-Zertifikaten")
#set text(lang: "de")

#show: typslides.with(
  ratio: "16-9",
  theme: rgb("#2056ae"),
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-page-numbers: false,
  show-progress: true,
)

#front-slide(
  title: "Echtzeiterkennung von\nPrefix-Hijacking-Angriffen",
  subtitle: [mithilfe von TLS-Zertifikaten],
  authors: author,
  info: [#link("https://github.com/lennartkloock/bgp-hijacking-detection")[github.com/lennartkloock/bgp-hijacking-detection]],
)

#table-of-contents(title: "Inhalt")

#include "1_recap.typ"
#include "2_bgp.typ"
#include "3_prefix_hijacking.typ"
#include "4_data_sources.typ"
#include "5_concept.typ"

// Bibliography
#bibliography-slide(
  title: "Quellen",
  bibliography("bibliography.yaml")
)
