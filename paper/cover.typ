#import "util.typ": accent_color, date, author
#import "@preview/dashy-todo:0.1.3": todo

#set document(author: author, title: "BGP Hijacking Detection")
#show title: name => {
  set text(fill: accent_color, baseline: -3pt)
  smallcaps(name)
}

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
    Matthias Wübbeling\
    #text(size: 10pt)[Universität Bonn]
  ]

  #date()#todo[ist auf Englisch]
]

#pagebreak()
