#import "@preview/typslides:1.3.2": *

#title-slide[Recap: Das Internet]

#let image_example(image_path, caption_text, content) = [
  #cols(columns: (1fr, 1fr))[
    #set align(center + horizon)
    #box(height: 80%, image(image_path))
  ][
    #set align(top + left)
    #content
  ]
]

// Recap aus KIVS und NetSi

#slide(title: "Recap")[
  #image_example("images/network_example_1.drawio.pdf", "Test", none)
]

#slide(title: "Recap")[
  #image_example("images/network_example_1.drawio.pdf", "Test")[
    - #stress[Was ist "das Internet"?]
  ]
]

#slide(title: "Recap")[
  #image_example("images/network_example_2.drawio.pdf", "Test")[
    - Was ist "das Internet"?
      - #stress[Ein Netzwerk von autonomen Systemen (AS)]
  ]
]

#slide(title: "Recap")[
  #image_example("images/network_example_3.drawio.pdf", "Test")[
    - Was ist "das Internet"?
      - Ein Netzwerk von autonomen Systemen (AS) #stress[bestehend aus Routern]
  ]
]

#slide(title: "Recap")[
  #image_example("images/network_example_4_1.drawio.pdf", "Test")[
    - Was ist "das Internet"?
      - Ein Netzwerk von autonomen Systemen (AS) bestehend aus Routern
    - #stress[Woher weiß ein Router wohin ein Paket als Nächstes geschickt werden soll?]
  ]
]

#slide(title: "Recap")[
  #image_example("images/network_example_4_2.drawio.pdf", "Test")[
    - Was ist "das Internet"?
      - Ein Netzwerk von autonomen Systemen (AS) bestehend aus Routern
    - #stress[Woher weiß ein Router wohin ein Paket als Nächstes geschickt werden soll?]
  ]
]

#slide(title: "Recap")[
  #image_example("images/network_example_4_2.drawio.pdf", "Test")[
    - Was ist "das Internet"?
      - Ein Netzwerk von autonomen Systemen (AS) bestehend aus Routern
    - Woher weiß ein Router wohin ein Paket als Nächstes geschickt werden soll?
      - #stress[Routing-Tabellen und das Border Gateway Protocol (BGP)]
  ]
]
