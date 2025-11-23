#show outline: set heading(outlined: true)
#show outline.entry: it => link(
  it.element.location(),
  it.indented(it.prefix(), it.inner(), gap: 5em),
)

#show outline.entry: it => {
  // Workaround to hide the prefix
  show "Abbildung": ""
  it
}

#outline(title: [Abbildungsverzeichnis], target: figure.where(kind: image))

#pagebreak()
