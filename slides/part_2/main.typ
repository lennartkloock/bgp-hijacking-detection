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
  subtitle: [mithilfe von TLS-Zertifikaten – Part 2],
  authors: author,
  info: link("https://github.com/lennartkloock/bgp-hijacking-detection")[github.com/lennartkloock/bgp-hijacking-detection],
)

#table-of-contents(title: "Inhalt")

#include "1_recap_prefix_hijacking.typ"
#include "2_recap_concept.typ"
#include "3_architecture.typ"

// Codeausschnitte
// Grafana dashboard
// Bachelorarbeitsthema

// Bibliography
#bibliography-slide(
  title: "Quellen",
  bibliography("../bibliography.yaml")
)
