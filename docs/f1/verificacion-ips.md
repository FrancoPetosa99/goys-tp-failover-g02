# F1 — IPs de enlace, loopbacks y verificación (R5)

Plan de direccionamiento: `docs/f0/ipam.md`. Configuración aplicada: `backups/2026-10-09/<router>.rsc`. Mapa por interfaz: `docs/f1/mapa-interfaces-e-incidente.md`.

## Resultado

| Enlace | Subred | Configurado | Ping verificado |
|--------|--------|:-----------:|:---------------:|
| ISP-1 ↔ EDGE | 192.0.2.0/30 (.1 / .2) | ✅ | ✅ (R1, sin captura) |
| ISP-2 ↔ EDGE | 192.0.2.4/30 (.5 / .6) | ✅ | ✅ captura `f1-09-ping-isp2-edge.png` |
| EDGE ↔ CORE-1 | 10.0.0.0/30 (.1 / .2) | ✅ | ✅ (R1, sin captura) |
| EDGE ↔ CORE-2 | 10.0.0.4/30 (.5 / .6) | ✅ | ✅ (R1, sin captura) |
| CORE-1 ↔ CORE-2 | 10.0.0.8/30 (.9 / .10) | ✅ | ✅ (R1, sin captura) |
| CORE-1 ↔ DIST-1 | 10.0.0.12/30 (.13 / .14) | ✅ | ✅ (R1, sin captura) |
| CORE-1 ↔ DIST-2 | 10.0.0.16/30 (.17 / .18) | ✅ | ✅ captura `f1-10-dist2-ip-y-pings.png` |
| CORE-2 ↔ DIST-1 | 10.0.0.20/30 (.21 / .22) | ✅ | ✅ (R1, sin captura) |
| CORE-2 ↔ DIST-2 | 10.0.0.24/30 (.25 / .26) | ✅ | ✅ captura `f1-10-dist2-ip-y-pings.png` |
| LAN USERS | 192.168.10.0/24 (DIST-1 .2, DIST-2 .3, PC-USER .100) | ✅ | ✅ DIST-2→PC-USER (captura `f1-10`) y R1 |
| LAN SERVERS | 192.168.20.0/24 (DIST-1 .2, DIST-2 .3, SRV .100) | ✅ | ✅ DIST-2→SRV (captura `f1-10`) y R1 |

Las IPs virtuales VRRP (.1) **no** se configuran en F1 (fase 2). Los gateways `.1` de los hosts quedan sin responder hasta entonces: es lo esperado.

**Loopbacks:** ISP-1 198.51.100.1 · ISP-2 198.51.100.2 · EDGE 10.255.0.1 · CORE-1 10.255.0.11 · CORE-2 10.255.0.12 · DIST-1 10.255.0.21 · DIST-2 10.255.0.22 (todas /32, interfaz `lo`).

## Hosts Alpine (persistencia)

Configuración en *Edit config* del nodo Docker (`/etc/network/interfaces`), así sobrevive a reinicios: `configs/hosts/PC-USER.interfaces` y `configs/hosts/SRV.interfaces`. Evidencia: `f1-08a/08b` (config) y `f1-11a/11b` (`ip a`).

## Limitaciones declaradas

Los pings de la mayoría de los enlaces fueron verificados personalmente por R1 pero **no tienen captura**. Se declara así para que la evidencia del repo no sugiera más de lo que hay. Si el docente lo exige, se repiten en 5 minutos al abrir el lab en F2.
