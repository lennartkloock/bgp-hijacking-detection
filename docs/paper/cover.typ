#import "util.typ": accent_color, date, author

#let doc_title = "Echtzeiterkennung von\nPrefix-Hijacking-Angriffen\nmithilfe von TLS-Zertifikaten"

#set document(author: author, title: doc_title.replace("\n", " "))
#show title: smallcaps(text(fill: accent_color, baseline: -3pt, doc_title))

#place(right, image("images/uni_logo.svg", alt: "Univesität Bonn", width: 5.2cm))

#align(center + horizon)[
  #line(length: 75%, stroke: 0.5pt)
  #title()
  #line(length: 75%, stroke: 0.5pt)
  ausgearbeitet von

  #smallcaps(text(size: 13pt)[
    #text(fill: accent_color)[*Lennart Kloock*]\
    Matr. Nr. 50055005
  ])

  vorgelegt an der\
  #smallcaps[
    Rheinischen Friedrich-Wilhelms-Universität Bonn\
    Institut für Informatik IV\
    Arbeitsgruppe für Kommunikationssysteme
  ]

  im Studiengang\
  #smallcaps[Informatik (B.Sc.)]

  #grid(
    columns: 2,
    align: left + top,
    gutter: 1em,
  )[
    Erstprüfer:
  ][
    Dr. Matthias Wübbeling\
    #text(size: 10pt)[Universität Bonn]
  ]

  #date()
]

#pagebreak()
