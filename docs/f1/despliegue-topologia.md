# F1 — Despliegue de la topología en GNS3 (R1)

**Fecha de ejecución:** 2026-10-08 / 2026-10-09 · **Ejecutó:** R1 (sesión única en GNS3).

## Entorno

| Ítem | Valor |
|------|-------|
| Host | VM Debian 13 "Trixie" 64 bits en VirtualBox (10403 MB RAM, 4 CPU, paginación anidada + KVM, disco 20 GB) |
| GNS3 | 3.0.6 |
| Routers | 7 × MikroTik CHR, RouterOS 7.14.3 |
| Switches | 2 × switch Ethernet de GNS3 (`SW-ACC-USERS`, `SW-ACC-SERVERS`) |
| Hosts | 2 × Docker Alpine (`PC-USER`, `SRV`) |
| Clouds | `Cloud1` y `Cloud2`, enlazados a `enp0s3` (no cuentan como nodos del lab) |

Evidencia: `capturas/f1/f1-01-vm-specs.png`, `f1-02-lienzo-sin-cables.png`, `f1-03-adaptadores-edge.png`.

> **Desvío de recursos:** cada CHR se creó con 256 MB (recomendado por RouterOS 7). Durante la verificación la VM se colgaba, así que se bajó a **130 MB por nodo**. Si se restaura el snapshot BASE, los nodos vuelven a 256 MB (el snapshot se tomó antes del cambio). Ver también `docs/f1/snapshot-base.md`.

## Cableado (11 nodos, 15 enlaces)

| # | Extremo A | Extremo B |
|---|-----------|-----------|
| 1 | ISP-1 ether2 | EDGE ether1 |
| 2 | ISP-2 ether2 | EDGE ether2 |
| 3 | EDGE ether3 | CORE-1 ether1 |
| 4 | EDGE ether4 | CORE-2 ether1 |
| 5 | CORE-1 ether2 | CORE-2 ether2 (core–core) |
| 6 | CORE-1 ether3 | DIST-1 ether1 |
| 7 | CORE-1 ether4 | DIST-2 ether1 |
| 8 | CORE-2 ether3 | DIST-1 ether2 |
| 9 | CORE-2 ether4 | DIST-2 ether2 |
| 10 | DIST-1 ether3 | SW-ACC-USERS e0 |
| 11 | DIST-1 ether4 | SW-ACC-SERVERS e0 |
| 12 | DIST-2 ether3 | SW-ACC-USERS e1 |
| 13 | DIST-2 ether4 | SW-ACC-SERVERS e1 |
| 14 | SW-ACC-USERS e2 | PC-USER eth0 |
| 15 | SW-ACC-SERVERS e2 | SRV eth0 |

Además: `Cloud1 enp0s3 ↔ ISP-1 ether1` y `Cloud2 enp0s3 ↔ ISP-2 ether1` (nombres **de GNS3**, ver el mapa de interfaces).

**Verificación:** el *Topology Summary* de GNS3 coincide enlace por enlace con la tabla (`capturas/f1/f1-06a/06b-topology-summary-*.png`), y con el diagrama de F0 (`docs/diagramas/topologia-objetivo.png`).

Evidencia del cableado: `f1-04-cableado-completo.png` y `f1-05a…05d` (zoom por zona).

> Los nombres de puerto de la tabla son los **de GNS3**. En dos routers (ISP-1 y DIST-2) RouterOS los nombra distinto: ver `docs/f1/mapa-interfaces-e-incidente.md`.
