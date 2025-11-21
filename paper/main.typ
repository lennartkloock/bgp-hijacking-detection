#import "util.typ": accent_color

#set page(paper: "a4", margin: 26.5mm)
#set text(lang: "de", size: 11pt)
#set pagebreak(weak: true)
#set par(justify: true)

#set page(background: rotate(24deg, text(22pt, fill: rgb("#dddddd"))[*ENTWURF*]))

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
    if get_first_heading_on_page(here()) == none {
      let previous_headings = query(heading.where(level: 1).before(here()))
      if previous_headings.len() > 0 {
        align(right, smallcaps(previous_headings.last().body))
      }
    }
  }
)
#counter(page).update(1)
#include "introduction.typ"

#include "content1.typ"
