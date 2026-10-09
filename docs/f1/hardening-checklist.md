# F1 — Checklist de hardening (R5)

Política: `docs/f0/operacion.md` §4.1 y `docs/f0/edge-seguridad.md`. Evidencia: `/export terse` + `/user print` de cada router (`capturas/f1/f1-12…f1-18`) y `backups/2026-10-09/*.rsc`.

| Control | EDGE | ISP-1 | ISP-2 | CORE-1 | CORE-2 | DIST-1 | DIST-2 |
|---------|:----:|:-----:|:-----:|:------:|:------:|:------:|:------:|
| Password `admin` cambiada | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ |
| Usuario `monitor` (grupo `read`) | ✅ | ✅ | ✅ | ⚠ `moonitor`² | ✅ | ✅ | ✅ |
| telnet / ftp / www / api / api-ssl / winbox deshabilitados | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SSH limitado a `10.0.0.0/8,192.168.0.0/16` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MAC-server / MAC-winbox: `allowed-interface-list=none` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Discovery de vecinos (`discover-interface-list=none`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `bandwidth-server` apagado | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cliente DHCP removido | ⚠³ | ⚠³ | ⚠³ | ⚠³ | ⚠³ | ⚠³ | ⚠³ |

¹ La contraseña no es visible en el export (por diseño). Declarada por R1 (ejecutó la fase); **no se registra la contraseña en el repo**.

² En CORE-1 el usuario se creó como `moonitor` (typo visible en `f1-15-export-core-1.png`). Corrección: `/user set 1 name=monitor` y repetir `/user print`. Hasta ese momento CORE-1 **no cumple** el control.

³ Los 7 exports todavía incluyen `/ip dhcp-client add interface=ether1` (cliente DHCP por defecto del CHR). No hay servidor DHCP en los enlaces internos, riesgo bajo, pero la política lo pide. Corrección: `/ip dhcp-client remove [find]` en cada router y re-exportar (o dejarlo como desvío aceptado). Nota: ISP-1/ISP-2 sí necesitarán DHCP **en el puerto hacia el Cloud**, no en `ether1` (ver mapa de interfaces §3).

## Estado

Hardening **aplicado en los 7 routers**, con **2 correcciones menores abiertas** (², ³). Hasta cerrarlas el backlog queda en `[~]`.
