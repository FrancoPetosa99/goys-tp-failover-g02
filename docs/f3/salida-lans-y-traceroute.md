# F3 — Salida de las LANs a "Internet" (R4)

**Fecha:** 2026-10-14 (sesión 7), hora de Argentina · Evidencia: `capturas/f3/` (`f3-07*`).

## Qué se probó

El camino completo desde las LANs de acceso (VRRP + OSPF de F2) hasta la loopback de ISP-1, pasando por el default de OSPF, EDGE, el firewall y BGP.

Routers encendidos: ISP-1, EDGE, CORE-1 y DIST-1 (es la única sesión de F3 con 4 routers, ver `docs/f3/verificacion.md`). Apagados: DIST-2, CORE-2 e ISP-2. Los hosts se probaron de a uno.

```
PC-USER / SRV ── DIST-1 ── CORE-1 ── EDGE ── ISP-1 (198.51.100.1)
  LANs          VRRP       default    firewall   default-originate
  192.168.x     master     por OSPF   + BGP      + LANs por BGP
```

## Resultados

| Origen | Destino | Resultado | Captura |
|--------|---------|-----------|---------|
| PC-USER (192.168.10.100) | 198.51.100.1 | 4/4, 0 % pérdida, TTL 61 | `f3-07f` |
| SRV (192.168.20.100) | 198.51.100.1 | 4/4, 0 % pérdida, TTL 61 | `f3-07g` |

Traceroute (`traceroute -n 198.51.100.1`), 4 saltos en ambos casos:

| Salto | PC-USER | SRV | Qué es |
|:-----:|---------|-----|--------|
| 1 | 192.168.10.2 | 192.168.20.2 | DIST-1 (dirección real de la LAN, no la IP virtual) |
| 2 | 10.0.0.13 | 10.0.0.13 | CORE-1 (enlace CORE-1 ↔ DIST-1, 10.0.0.12/30) |
| 3 | 10.0.0.1 | 10.0.0.1 | EDGE (enlace EDGE ↔ CORE-1, 10.0.0.0/30) |
| 4 | 198.51.100.1 | 198.51.100.1 | ISP-1 (loopback) |

TTL 61 = 64 menos los 3 routers del camino (DIST-1, CORE-1, EDGE) en el viaje de vuelta de la respuesta.

## Cómo vuelve el tráfico

No hay NAT. ISP-1 conoce las LANs porque EDGE las redistribuye de OSPF a BGP (`docs/f3/bgp-edge.md`). En ISP-1 (`f3-07d`) aparecen `192.168.10.0/24` y `192.168.20.0/24` por 192.0.2.2 (`DAb`, distancia 20), y nada de 10.x.

## Pruebas negativas (desde ISP-1, `f3-07e`)

| Prueba | Resultado | Por qué |
|--------|-----------|---------|
| `ping 192.168.10.100` | 3/3 timeout | ISP-1 tiene la ruta, pero el firewall de EDGE descarta lo que llega nuevo desde `WAN` hacia `LAN` (`fw-drop-resto`, 3 paquetes en `f3-07h`) |
| `ping 10.255.0.1` | `no route` | el direccionamiento interno no se anuncia a los proveedores |

## Observaciones

1. **VRRP durante la prueba.** Con DIST-2 apagado, DIST-1 es el único router de las dos LANs: para SRV, el salto 1 contesta desde `192.168.20.2` (DIST-1). El comportamiento de VRRP con ambos DIST arriba ya está probado en F2.
2. **Solo se probó la loopback de ISP-1** (proveedor principal). La de ISP-2 no es alcanzable mientras ISP-1 sea el camino por defecto; se verá en el drill 3 de F4 con ISP-1 caído.
3. **Latencia.** Entre 24 y 60 ms desde los hosts; es un valor de laboratorio, no de diseño.
