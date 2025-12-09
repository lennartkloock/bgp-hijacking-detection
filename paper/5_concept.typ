= Design/Konzept

- Darstellung möglicher Lösungsansätze
- Bewertung der Lösungsansätze

1. MOAS Präfixe live identifizieren mithilfe RIPE RIS Live (https://ris-live.ripe.net/)
2. TLS Hosts (z.B. HTTPS, SMTP) im Prefix finden
  - Einfach alle Adressen auf bestimmten Ports scannen?
  - Legal?
  - Könnte möglicherweise sehr lange dauern
3. Zwei RIPE Atlas Probes in den beiden Partitionen finden
  - Wie können wir uns sicher sein, dass wir uns tatsächlich in einer bestimmten Partition befinden?
4. Von beiden Verbindung aufbauen und TLS Zertifikat abfragen
5. Ergebnisse vergleichen

#pagebreak()
