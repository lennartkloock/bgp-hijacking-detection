#let display_percent(n) = {
  let rounded = calc.round(n * 100, digits: 2)
  let s = str(rounded).replace(".", ",")
  return [#s#sym.space.nobreak%]
}

#let display_number(n) = {
  let s = str(n)
  let count = calc.ceil((s.len() / 3) - 1)

  return s.rev().replace(
    regex("\\d{3}"),
    match => match.at("text") + sym.space.thin,
    count: count,
  ).rev()
}
