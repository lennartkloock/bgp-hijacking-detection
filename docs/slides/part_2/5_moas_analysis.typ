#import "../../data.typ": *
#import "@preview/typslides:1.3.2": *

#title-slide[Implementierung: MOAS Analysis]

// SQL-Query zum Finden von MOAS
// Anzahl MOAS mit/ohne TLS-Host
// Beispiel Atlas-Analyse
// Atlas Messungen zeigen

#slide(title: "MOAS Analysis")[
  ```sql
  
  
  
  
  FROM routes
  
  

  
  ```
]

#slide(title: "MOAS Analysis")[
  ```sql
  
  
  
  
  FROM routes
  WHERE array_length(origin_asn, 1) = 1
  
  

  ```
]

#slide(title: "MOAS Analysis")[
  ```sql
  
  
  
  
  FROM routes
  WHERE array_length(origin_asn, 1) = 1
  GROUP BY prefix
  HAVING count(DISTINCT origin_asn[1]) > 1;
  ```
]

#slide(title: "MOAS Analysis")[
  ```sql
  SELECT
      prefix,
      array_agg(DISTINCT origin_asn[1] ORDER BY origin_asn[1]) AS origins,
      max(updated_at) AS updated_at
  FROM routes
  WHERE array_length(origin_asn, 1) = 1
  GROUP BY prefix
  HAVING count(DISTINCT origin_asn[1]) > 1;
  ```
]

#slide(title: "MOAS Analysis: Evaluation")[
  #figure(caption: "Stand: 11. April 11:20:00 UTC", moas_table)
  #hide(figure(caption: "Stand: 11. April 11:20:00 UTC", moas_origins_table))
]

#slide(title: "MOAS Analysis: Evaluation")[
  #figure(caption: "Stand: 11. April 11:20:00 UTC", moas_table)
  #figure(caption: "Stand: 11. April 11:20:00 UTC", moas_origins_table)
]

#let slide_box(content) = box(height: 11em, align(top, content))

#slide(title: "MOAS Analysis: Evaluation", slide_box[
  - #stress[Alle #moas_4 Präfixe wurden mit zmap gescannt]
])

#slide(title: "MOAS Analysis: Evaluation", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - #stress[Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host]
])

#slide(title: "MOAS Analysis: Evaluation", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host
  #stress[Beispielfall:]
])

#slide(title: "MOAS Analysis: Beispiel", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host
  Beispielfall:
  - #stress[Präfix `41.221.216.0/24` wird sowohl von AS 31713, als auch von AS 3491 bekanntgegeben]
])

#slide(title: "MOAS Analysis: Beispiel", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host
  Beispielfall:
  - Präfix `41.221.216.0/24` wird sowohl von AS 31713, als auch von AS 3491 bekanntgegeben
  - #stress[AS 31713: "Gateway Communications"]
])

#slide(title: "MOAS Analysis: Beispiel", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host
  Beispielfall:
  - Präfix `41.221.216.0/24` wird sowohl von AS 31713, als auch von AS 3491 bekanntgegeben
  - AS 31713: "Gateway Communications"
  - #stress[AS 3491: "PCCW Global (HK) Ltd."]
])

#slide(title: "MOAS Analysis: Beispiel", slide_box[
  - Alle #moas_4 Präfixe wurden mit zmap gescannt
  - Davon haben #at_least_one_host Präfixe (#sym.approx #display_percent(at_least_one_host / moas_4)) mindestens einen TLS-Host
  Beispielfall:
  - Präfix `41.221.216.0/24` wird sowohl von AS 31713, als auch von AS 3491 bekanntgegeben
  - AS 31713: "Gateway Communications"
  - AS 3491: "PCCW Global (HK) Ltd."
  - #stress[In beiden AS befinden sich Atlas Probes, die zur Messung genutzt werden können]
])

// https://atlas.ripe.net/measurements/163261121/overview
#focus-slide[RIPE Atlas Messung]
