# F1 — Corrección de la devolución: cliente DHCP removido de los 7 routers (R1)

Evidencia: `capturas/f1/f1x-*` · Configuración vigente: `backups/2026-10-18/`.

## Qué pidió la devolución de F1

La corrección de F1 (93/100) pide quitar de los 7 routers la línea de fábrica `/ip dhcp-client add interface=ether1` y regenerar los exports. En F1 la habíamos dejado como "desvío aceptado" porque no había servidor DHCP en los enlaces internos. El riesgo no es de tráfico sino de superficie de ataque: un cliente DHCP activo en un router de producción acepta la dirección, la ruta por defecto y el DNS que le ofrezca *cualquier* servidor DHCP que aparezca en ese segmento (por ejemplo, uno falso), y lo hace sin que el firewall intervenga, porque el cliente DHCP trabaja por debajo del filtrado de `input`. Un router de infraestructura debe tener todo direccionamiento definido a mano.

## Qué se hizo

En cada router, con un backup binario previo (`/system backup save name=f4-s0-pre`, queda en el equipo y **no** se sube al repo):

```routeros
/ip dhcp-client print
/ip dhcp-client remove [find]
/ip dhcp-client print
```

El segundo `print` sale vacío en los 7 routers.

| Router | Estado antes | Después | Captura |
|--------|--------------|---------|---------|
| DIST-1 | `ether1`, `searching...` | sin cliente | `f1x-01` |
| DIST-2 | `ether1`, `searching...` | sin cliente | `f1x-02` |
| CORE-1 | `ether1`, `searching...` | sin cliente | `f1x-03` |
| CORE-2 | `ether1`, `searching...` | sin cliente | `f1x-04` |
| EDGE | `ether1`, `searching...` | sin cliente | `f1x-05`, `f1x-05b` |
| ISP-1 | `ether1`, `searching...` | sin cliente | `f1x-06` |
| ISP-2 | `ether1`, **`bound 10.0.2.16/24`** | sin cliente | `f1x-07`, `f1x-07b` |

## Observaciones

1. **ISP-2 era el único con lease real.** Su `ether1` es el puerto que va al Cloud/NAT de GNS3 (el enlace con EDGE es `ether2`), así que ese puerto había obtenido `10.0.2.16/24` del NAT del laboratorio. La nota de F1 decía lo contrario (que "ISP-1 e ISP-2 necesitarán DHCP en el puerto hacia el Cloud"); eso se corrige: ningún router necesita DHCP para el laboratorio. Después de quitarlo, `/ip address print` en ISP-2 muestra solo la loopback y `192.0.2.5/30` en `ether2` (`f1x-07b`).
2. **EDGE sigue con su default por BGP.** `f1x-05b` muestra `0.0.0.0/0` por `192.0.2.1`, flag `DAb` (dinámica, activa, BGP): no había ninguna ruta por defecto proveniente del cliente.
3. **Los exports históricos de F1, F2 y F3 siguen mostrando la línea** porque son fotos de ese momento. El estado vigente es el de `backups/2026-10-17/*.rsc`, que no la contienen (verificable con `grep -rn "dhcp-client add" backups/2026-10-17/`, que no devuelve nada).

## Cómo se revierte

`/ip dhcp-client add interface=ether1` (no recomendado: reintroduce el hallazgo de la devolución).
