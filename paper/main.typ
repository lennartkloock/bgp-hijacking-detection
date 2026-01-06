#import "util.typ": accent_color

#let pre_release = true
#metadata(pre_release) <pre_release>

#set page(paper: "a4", margin: 26.5mm)
#set text(lang: "de", size: 11pt)
#set pagebreak(weak: true)
#set par(justify: true)

#set page(background: rotate(24deg, text(22pt, fill: rgb("#dddddd"))[*ENTWURF*])) if pre_release

#show heading.where(level: 1): set heading(supplement: "Kapitel")
#show heading: name => {
  set text(fill: accent_color)
  smallcaps(name)
}
#show heading.where(level: 1): name => [
  #v(3cm)
  #name
  #v(1.2cm)
]
#show heading.where(level: 2): name => [
  #v(0.6cm)
  #name
  #v(0.2cm)
]

#include "cover.typ"

#set page(numbering: "i", number-align: right + bottom)
#counter(page).update(1)

#include "statement.typ"
#include "abstract.typ"
#include "toc.typ"

#let get_first_heading_on_page(loc) = {
  let this_page = loc.page()
  let headings = query(
    heading.where(level: 1, outlined: true)
  )
  for h in headings {
    if h.location().page() == this_page {
      return h
    }
  }
  return none
}

#set heading(numbering: (..nums) => text(fill: black, size: 0.9em, nums.pos().map(str).join(".")))
#set page(
  numbering: "1",
  number-align: right + bottom,
  header: context {
    // Show current chapter in heading when it doesn't start on this page
    if get_first_heading_on_page(here()) == none {
      let selector = selector(heading.where(level: 1).before(here()))
      let previous_headings = query(selector)
      if previous_headings.len() > 0 {
        let h_body = previous_headings.last().body
        let h_count = counter(selector).display()
        align(right, smallcaps[#h_count #h_body])
      }
    }
  }
)
#counter(page).update(1)

#include "1_introduction.typ"
#include "2_fundamentals.typ"
#include "3_related_work.typ"
#include "4_data_sources.typ"
#include "5_concept.typ"

#place(center)[
  #line(length: 50%)
  Bis hier bis zum 09.01.2026
]

#include "6_implementation.typ"
#include "7_evaluation.typ"
#include "8_conclusion.typ"
#include "bibliography.typ"
#include "figures.typ"
#include "abbreviations.typ"
