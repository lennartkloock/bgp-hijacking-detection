# Notizen

## Literatur

- [BGPalerter](https://github.com/nttgin/BGPalerter)
  - Nur um eigenes Netzwerk zu monitoren, nicht global anwendbar
- [Detecting Bogus BGP Route Information: Going Beyond Prefix Hijacking](https://ieeexplore.ieee.org/document/4550358)
- [PHAS: A Prefix Hijack Alert System](https://www.usenix.org/legacy/event/sec06/tech/full_papers/lad/lad.pdf)
  - 2006
- [Towards uncovering BGP hijacking attacks](https://pastel.hal.science/tel-01412800)
- [Inter-AS routing anomalies: Improved detection and classification](https://ieeexplore.ieee.org/document/6916405)
- [A first step towards checking BGP routes in the dataplane](https://dl.acm.org/doi/abs/10.1145/3527974.3545723)
  - Vorschlag Routersoftware anzupassen, sodass Routen mithilfe von TLS und speziellen Validation Servern überprüft werden,
    bevor sie in die Routing Tables eingefügt werden.
  - Aufwändig einzuführen, da Software auf Routern angepasst/gepatcht werden muss
- [Understanding BGP misconfiguration](https://dl.acm.org/doi/10.1145/964725.633027)
  - Wie viele BGP misconfigurations gibt es?
  - 2002!

## Idea: Crowd-sourcing hijacking detection

- [Crowd-based detection of routing anomalies on the internet](https://ieeexplore.ieee.org/abstract/document/7346850)
