#import "util.typ": accent_color, date, author
#import "@preview/dashy-todo:0.1.3": todo

#set document(author: author, title: "BGP Hijacking Detection")
#show title: name => {
  set text(fill: accent_color, baseline: -3pt)
  smallcaps(name)
}

#place(right, image("images/uni_logo.svg", alt: "Univesität Bonn", width: 5.2cm))

// Typst doesn't support localization yet
#let month_de(month) = {
  if month == 1 {
    return "Januar"
  } else if month == 2 {
    return "Februar"
  } else if month == 3 {
    return "März"
  } else if month == 4 {
    return "April"
  } else if month == 5 {
    return "Mai"
  } else if month == 6 {
    return "Juni"
  } else if month == 7 {
    return "Juli"
  } else if month == 8 {
    return "August"
  } else if month == 9 {
    return "September"
  } else if month == 10 {
    return "Oktober"
  } else if month == 11 {
    return "November"
  } else if month == 12 {
    return "Dezember"
  } else {
    return "?"
  }
}

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

  #datetime.today().display("[day]").
  #month_de(datetime.today().month())
  #datetime.today().display("[year]")
]

#pagebreak()
