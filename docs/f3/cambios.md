# F3 — Registro de cambios (R5)

Formato de `docs/f0/operacion.md` §5.1. Cada fila corresponde a uno o más commits de la fase.

| Fecha | Responsable (rol) | Cambio | Motivo | Cómo se revierte |
|-------|-------------------|--------|--------|------------------|
| 2026-10-13 | R2 | eBGP en ISP-1 (AS 65001) e ISP-2 (AS 65002) hacia EDGE con TCP-MD5 y `default-originate=always` | Multi-homing con dos proveedores | `/routing bgp connection remove [find name=to-EDGE]` en cada ISP |
| 2026-10-13 | R1 | eBGP en EDGE (AS 65000) con ISP-1 y ISP-2, cada una con su clave TCP-MD5 | Multi-homing con dos proveedores | `/routing bgp connection remove [find]` en EDGE |
| 2026-10-13 | R1 | Filtros BGP en EDGE: `in-isp1` (`local-pref` 200), `in-isp2` (100), `out-isp1` y `out-isp2` (solo las 2 LANs; prepend 2 hacia ISP-2) | ISP-1 principal y no filtrar direccionamiento interno | `/routing filter rule remove [find]` y quitar `input.filter` y `output.filter-chain` de las conexiones |
| 2026-10-13 | R1 | Redistribución OSPF→BGP en EDGE (`output.redistribute=ospf`) | Que los ISP aprendan las LANs y el tráfico pueda volver | `/routing bgp connection set [find] output.redistribute=""` |
| 2026-10-13 | R3 | `originate-default=always` en la instancia OSPF de EDGE | Que el core salga a Internet por EDGE | `/routing ospf instance set ospf-lab originate-default=never` |
| 2026-10-13 | R1 | Firewall edge: listas `WAN`/`LAN`, 8 reglas `input` y 5 `forward` (default-deny) y `ssh strong-crypto=yes` | Protección del borde y del plano de gestión | `/ip firewall filter remove [find]`, `/interface list remove [find name~"WAN|LAN"]` |
| 2026-10-14 | R2 | Documentación de claves BGP y hallazgo de export (`tcp-md5-key` oculta, `auth-key` de OSPF no) | Política de claves de F0 | No aplica |
| 2026-10-14 | R5 | Backups de F3 de EDGE, ISP-1 e ISP-2 en `backups/2026-10-14/` | Política de backup al cerrar cada fase | No aplica |

Notas:
- La configuración se hizo en 7 sesiones (ver `docs/f3/verificacion.md`); las filas del 13/10 corresponden a las sesiones 1 a 4 (hora de Argentina; los routers marcan UTC y ya figuran como 14/10).
- Los `.rsc` llevan `<OSPF-KEY>`, `<BGP-KEY-ISP1>` y `<BGP-KEY-ISP2>` en lugar de las claves reales.
- No hubo cambios en CORE-1, CORE-2, DIST-1 ni DIST-2.
