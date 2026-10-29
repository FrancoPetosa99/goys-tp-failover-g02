# F1 — Checklist de hardening (R5)

Política: `docs/f0/operacion.md` §4.1 y `docs/f0/edge-seguridad.md`. Evidencia: `/export terse` + `/user print` de cada router (`capturas/f1/f1-12…f1-18`) y `backups/2026-10-09/*.rsc`.

| Control | EDGE | ISP-1 | ISP-2 | CORE-1 | CORE-2 | DIST-1 | DIST-2 |
|---------|:----:|:-----:|:-----:|:------:|:------:|:------:|:------:|
| Password `admin` cambiada | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ | ✅¹ |
| Usuario `monitor` (grupo `read`) | ✅ | ✅ | ✅ | ✅² | ✅ | ✅ | ✅ |
| telnet / ftp / www / api / api-ssl / winbox deshabilitados | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| SSH limitado a `10.0.0.0/8,192.168.0.0/16` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MAC-server / MAC-winbox: `allowed-interface-list=none` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Discovery de vecinos (`discover-interface-list=none`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `bandwidth-server` apagado | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cliente DHCP removido | ✅³ | ✅³ | ✅³ | ✅³ | ✅³ | ✅³ | ✅³ |
| Firewall de entrada con default-deny (`input` y `forward`) | ✅⁴ | — | — | — | — | — | — |
| SSH con `strong-crypto` | ✅⁴ | — | — | — | — | — | — |
| SNMP: SNMPv3 `authPriv`, `public` neutralizada | ✅⁵ | ✅⁵ | ✅⁵ | ✅⁵ | ✅⁵ | ✅⁵ | ✅⁵ |

¹ La contraseña no es visible en el export (por diseño). Declarada por R1 (ejecutó la fase); **no se registra la contraseña en el repo**.

² En F1, CORE-1 tenía el usuario creado como `moonitor` (typo visible en `f1-15-export-core-1.png`). **Corregido el 2026-10-13:** se eliminó el usuario sobrante y quedaron solo `admin` y `monitor` (`capturas/f2/f2-04e-core1-user-print.png`).

³ **Corregido en F4 (sesión 0, devolución de F1):** se quitó `/ip dhcp-client` de los 7 routers y los exports vigentes (`backups/2026-10-17/`) no lo contienen. Los exports históricos de F1, F2 y F3 siguen mostrándolo porque son fotos de ese momento. Nota: ISP-2 era el único con lease real (`ether1`, `10.0.2.16/24`): ese puerto va al Cloud/NAT de GNS3 y ya no tiene dirección. Detalle en `docs/f1/correccion-dhcp-client.md`.

⁴ Agregado en F3 (2026-10-13): solo EDGE lleva firewall, como pide el diseño de F0 (`docs/f0/edge-seguridad.md`). Detalle y pruebas en `docs/f3/firewall-edge.md`.

⁵ Agregado en F4 (2026-10-17): usuario de solo lectura `monitor` por SNMPv3 (SHA1/AES), limitado a `10.0.0.0/8` y `192.168.0.0/16`, con `engine-id` único por router. La comunidad `public` de RouterOS 7 **no se puede borrar**: queda neutralizada (`addresses=127.0.0.1/32`, `read-access=no`). Detalle en `docs/f4/snmpv3-claves.md`.

## Estado

Hardening **aplicado y verificado en los 7 routers**. El desvío del cliente DHCP (³) quedó **cerrado en F4**; el único punto abierto es que la consulta SNMP real desde SRV no se pudo demostrar (`docs/f4/monitoreo.md`).
