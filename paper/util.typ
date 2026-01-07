#let author = "Lennart Kloock"

#let accent_color = rgb("#2056ae")

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

#let date() = [
  Bonn,
  #datetime.today().display("[day]").
  #month_de(datetime.today().month())
  #datetime.today().display("[year]")
  // Bonn, #datetime.today().display("[day]. [month repr:long] [year]")
]
