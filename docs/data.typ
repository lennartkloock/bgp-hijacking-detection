#import "util.typ": display_number, display_percent

#let bgp_updates_total = 347833140
#let bgp_announcements = 329703193
#let bgp_withdrawals = 18486327

#let bgp_updates_table = table(
  columns: 3,
  align: left,
  table.header[*Wert*][*absolut*][*relativ*],
  [Anzahl BGP-Updates], display_number(bgp_updates_total), display_percent(1),
  "    davon Announcements", display_number(bgp_announcements), display_percent(bgp_announcements / bgp_updates_total),
  "    davon Withdrawals", display_number(bgp_withdrawals), display_percent(bgp_withdrawals / bgp_updates_total),
)

#let routes_total = 42534222;
#let routes_4 = 34339723;
#let routes_6 = 8194499;

#let moas_total = 6454;
#let moas_4 = 5378;
#let moas_6 = 1076;

#let moas_routes_table = table(
  columns: 3,
  align: left,
  table.header[*Wert*][*absolut*][*relativ*],
  [Anzahl Routen], display_number(routes_total), display_percent(1),
  "    davon IPv4", display_number(routes_4), display_percent(routes_4 / routes_total),
  "    davon IPv6", display_number(routes_6), display_percent(routes_6 / routes_total),
  [Anzahl MOAS-Präfixe], display_number(moas_total), display_percent(1),
  "    davon IPv4", display_number(moas_4), display_percent(moas_4 / moas_total),
  "    davon IPv6", display_number(moas_6), display_percent(moas_6 / moas_total),
)

#let moas_origins_2 = 6035
#let moas_origins_3 = 355
#let moas_origins_4 = 25
#let moas_origins_5 = 28
#let moas_origins_6 = 6
#let moas_origins_7_up = 4

#let moas_origins_table = table(
  columns: 3,
  align: left,
  table.header[*Origins*][*absolut*][*relativ*],
  [2], display_number(moas_origins_2), display_percent(moas_origins_2 / moas_total),
  [3], display_number(moas_origins_3), display_percent(moas_origins_3 / moas_total),
  [4], display_number(moas_origins_4), display_percent(moas_origins_4 / moas_total),
  [5], display_number(moas_origins_5), display_percent(moas_origins_5 / moas_total),
  [6], display_number(moas_origins_6), display_percent(moas_origins_6 / moas_total),
  [7+], display_number(moas_origins_7_up), display_percent(moas_origins_7_up / moas_total),
)

#let moas_origins_3_up_percentage = (
  calc.ceil(
    ((moas_origins_3 + moas_origins_4 + moas_origins_5 + moas_origins_6 + moas_origins_7_up) / moas_total) * 100,
  )
    / 100
)

#let at_least_one_host = 2152
