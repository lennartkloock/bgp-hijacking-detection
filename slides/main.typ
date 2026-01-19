#import "@preview/typslides:1.3.2": *

#let pre_release = true
// #let pre_release = false
#metadata(pre_release) <pre_release>

#set page(background: rotate(24deg, text(32pt, fill: rgb("#dddddd"))[*ENTWURF*])) if pre_release

#let author = "Lennart Kloock"

#set document(author: author, title: "Echtzeiterkennung von Prefix-Hijacking-Angriffen mithilfe von TLS-Zertifikaten")

#show: typslides.with(
  ratio: "16-9",
  theme: rgb("#2056ae"),
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-page-numbers: true,
  show-progress: true,
)

#front-slide(
  title: "Echtzeiterkennung von\nPrefix-Hijacking-Angriffen",
  subtitle: [mithilfe von TLS-Zertifikaten],
  authors: author,
  info: [#link("https://github.com/lennartkloock/bgp-hijacking-detection")],
)

#table-of-contents()

#title-slide[
  This is a _Title slide_
]

// A simple slide
#slide[
  - This is a simple `slide` with no title.
  - #stress("Bold and coloured") text by using `#stress(text)`.
  - Sample link: #link("typst.app").
    - Link styling using `link-style`: `"color"`, `"underline"`, `"both"`
  - Font selection using `font: "Fira Sans"`, `size: 21pt`.

  #framed[This text has been written using `#framed(text)`. The background color of the box is customisable.]

  #framed(title: "Frame with title")[This text has been written using `#framed(title:"Frame with title")[text]`.]
]

// Focus slide
#focus-slide[
  This is an auto-resized _focus slide_.
]

// Blank slide
#blank-slide[
  - This is a `#blank-slide`.

  - Available #stress[themes]#footnote[Use them as *color* functions! e.g., `#reddy("your text")`]:

  #framed(back-color: white)[
    #bluey("bluey"), #reddy("reddy"), #greeny("greeny"), #yelly("yelly"), #purply("purply"), #dusky("dusky"), darky.
  ]

  // #show: typslides.with(
  //   ratio: "16-9",
  //   theme: "bluey",
  //   ...
  // )
  

  - Or just use *your own theme color*:
    - `theme: rgb("30500B")`
]

// Slide with title
#slide(title: "Outlined slide", outlined: true)[
  - Check out the *progress bar* at the bottom of the slide.

    #h(1cm) `show-progress: true`

  - Outline slides with `outlined: true`.

  #grayed([This is a `#grayed` text. Useful for equations.])
  #grayed($ P_t = alpha - 1 / (sqrt(x) + f(y)) $)

]

// Columns
#slide(title: "Columns")[

  #cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[
    #grayed[Columns can be included using `#cols[...][...]`]
  ][
    #grayed[And this is]
  ][
    #grayed[an example.]
  ]

  - Custom spacing: `#cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[...]`

  - Sample references: @rfc1654, @youtube-hijack.
    - Add a #stress[bibliography slide]...

    1. `#let bib = bibliography("you_bibliography_file.bib")`
    2. `#bibliography-slide(bib)`
]

// Bibliography
#let bib = bibliography("bibliography.yaml")
#bibliography-slide(bib)
