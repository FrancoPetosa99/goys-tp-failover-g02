# F2 — Registro de cambios (R5)

Formato de `docs/f0/operacion.md` §5.1. Cada fila corresponde a uno o más commits de la fase.

| Fecha | Responsable (rol) | Cambio | Motivo | Cómo se revierte |
|-------|-------------------|--------|--------|------------------|
| 2026-10-13 | R4 | VRRP v2 con auth simple: `vrrp10` y `vrrp20` en DIST-1 y DIST-2 (VIP 192.168.10.1 y 192.168.20.1) | Primer salto redundante con load-sharing | Quitar las IPs virtuales y `/interface vrrp remove [find]` en ambos DIST; o volver al backup de F1 |
| 2026-10-13 | R4 | OSPF en DIST-1 y DIST-2: instancia `ospf-lab`, área `backbone`, MD5, LANs y loopback pasivas | Anunciar las LANs de acceso al core | `/routing ospf interface-template remove [find]`, luego `area` e `instance` |
| 2026-10-13 | R3 | OSPF en CORE-1 y CORE-2, incluido el enlace core–core, con MD5 | IGP del núcleo con camino alterno entre cores (defecto 3 de F0) | Igual que arriba |
| 2026-10-13 | R1 | OSPF en EDGE hacia CORE-1 y CORE-2 con MD5; enlaces a ISP fuera de OSPF | Reconvergencia interna; ISP irán por BGP en F3 | Igual que arriba |
| 2026-10-13 | R3 | Se elimina el usuario sobrante `moonitor` de CORE-1 | Cierra una corrección abierta de F1 | No aplica (usuario con typo) |
| 2026-10-13 | R2 | Documentación de claves aplicadas y hallazgo de export (`auth-key` visible) | Política de claves de F0 | No aplica |
| 2026-10-13 | R5 | Backups de F2 de EDGE, CORE-1, CORE-2, DIST-1 y DIST-2 en `backups/2026-10-13/` | Política de backup al cerrar cada fase | No aplica |

Notas:
- Las 5 configuraciones se hicieron en 8 sesiones de 2 routers (ver `docs/f2/verificacion.md`).
- Los `.rsc` llevan `<OSPF-KEY>` en lugar de la clave real.
