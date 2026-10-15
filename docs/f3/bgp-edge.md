# F3 — eBGP multi-homing en EDGE (R1)

**Fecha:** 2026-10-13 (sesiones 1, 2 y 3) y 2026-10-14 (sesiones 6 y 7), hora de Argentina · Evidencia: `capturas/f3/` · Configuración: `backups/2026-10-14/EDGE.rsc`.

## Diseño

EDGE (AS 65000) mantiene una sesión eBGP con cada proveedor. Los AS son privados y se eligieron en F3 (los documentos de F0 no los fijaban).

| Sesión | Vecino | AS remoto | IP local ↔ remota | Router-id local | Clave TCP-MD5 en el repo |
|--------|--------|:---------:|-------------------|:---------------:|--------------------------|
| `to-ISP1` | ISP-1 | 65001 | 192.0.2.2 ↔ 192.0.2.1 (ether1) | 3.3.3.3 | `<BGP-KEY-ISP1>` |
| `to-ISP2` | ISP-2 | 65002 | 192.0.2.6 ↔ 192.0.2.5 (ether2) | 3.3.3.3 | `<BGP-KEY-ISP2>` |

Las dos claves son distintas entre sí. Viven en el canal privado del grupo (ver `docs/f3/claves-bgp.md`).

## Configuración

Sesiones 1 y 2 (conexiones con TCP-MD5):

```routeros
/routing bgp connection add name=to-ISP1 as=65000 router-id=3.3.3.3 local.address=192.0.2.2 local.role=ebgp remote.address=192.0.2.1 remote.as=65001 tcp-md5-key=<BGP-KEY-ISP1>
/routing bgp connection add name=to-ISP2 as=65000 router-id=3.3.3.3 local.address=192.0.2.6 local.role=ebgp remote.address=192.0.2.5 remote.as=65002 tcp-md5-key=<BGP-KEY-ISP2>
```

Sesión 3 (política: preferencia de entrada, filtro de salida y redistribución OSPF→BGP):

```routeros
/routing filter rule add chain=in-isp1 rule="set bgp-local-pref 200; accept"
/routing filter rule add chain=in-isp2 rule="set bgp-local-pref 100; accept"
/routing filter rule add chain=out-isp1 rule="if (dst == 192.168.10.0/24 || dst == 192.168.20.0/24) { accept }"
/routing filter rule add chain=out-isp1 rule="reject"
/routing filter rule add chain=out-isp2 rule="if (dst == 192.168.10.0/24 || dst == 192.168.20.0/24) { set bgp-path-prepend 2; accept }"
/routing filter rule add chain=out-isp2 rule="reject"
/routing bgp connection set to-ISP1 input.filter=in-isp1 output.filter-chain=out-isp1 output.redistribute=ospf
/routing bgp connection set to-ISP2 input.filter=in-isp2 output.filter-chain=out-isp2 output.redistribute=ospf
```

| Cadena | Efecto |
|--------|--------|
| `in-isp1` | ISP-1 es el proveedor principal: las rutas recibidas llevan `local-pref 200` |
| `in-isp2` | ISP-2 es el respaldo: `local-pref 100` |
| `out-isp1` | Solo se anuncian las dos LANs (192.168.10.0/24 y 192.168.20.0/24); todo lo demás se rechaza |
| `out-isp2` | Igual, pero con `bgp-path-prepend 2` para que la vuelta también prefiera ISP-1 |

Por qué solo las LANs: los /30 internos (10.0.0.0/27) y las loopbacks no deben salir hacia los proveedores. Las LANs sí, porque es la única forma de que el tráfico vuelva (no se usa NAT).

## Verificación

| Sesión | Prueba | Resultado | Capturas |
|:------:|--------|-----------|----------|
| 1 | Enlace EDGE ↔ ISP-1 | ping 192.0.2.1: 4/4, TTL 64 | `f3-01a` |
| 1 | Sesión con ISP-1 | `E` (established), AS 65001, id 198.51.100.1 | `f3-01c` |
| 1 | Rutas de EDGE | `0.0.0.0/0` por 192.0.2.1, `DAb`, distancia 20 | `f3-01e` |
| 1 | Salida | ping 198.51.100.1: 4/4 | `f3-01f` |
| 2 | Enlace EDGE ↔ ISP-2 | ping 192.0.2.5: 4/4, TTL 64 | `f3-02a` |
| 2 | Sesión con ISP-2 | `E`, AS 65002, id 198.51.100.2; la sesión con ISP-1 (apagado) figura caída con `last-notification` de hold-timer | `f3-02c` |
| 2 | Rutas de EDGE | único default por 192.0.2.5 (`DAb`, 20) | `f3-02e` |
| 2 | Salida | ping 198.51.100.2: 4/4 | `f3-02f` |
| 3 | Reglas de filtro cargadas | 6 reglas en 4 cadenas | `f3-03a` |
| 6 | Filtros aplicados a la sesión ISP-1 | `output.filter-chain=out-isp1` e `input.filter=in-isp1` en el `session print` | `f3-06b` |
| 6 | Preferencia | default de ISP-1 con `bgp.local-pref=200`, `as-path="65001"`, distancia 20 | `f3-06c` |
| 7 | Filtros aplicados a la sesión ISP-2 | `in-isp2`, `out-isp2`, `ospf` | `f3-07a` |
| 7 | LANs aprendidas por OSPF en EDGE | 192.168.10.0/24 y 192.168.20.0/24 por 10.0.0.2%ether3 (más 6 rutas internas) | `f3-07b` |
| 7 | Qué anuncia EDGE a ISP-1 | `/routing bgp advertisements print`: solo 192.168.10.0/24 y 192.168.20.0/24, `as-path=65000` | `f3-07c` |

El cierre del extremo ISP (el ISP aprende las LANs) está en `docs/f3/bgp-isp.md`.

## Observaciones

1. **El enlace EDGE ↔ ISP quedó verificado.** En F2 quedó pendiente comprobar el cableado por los renombres de interfaz de EDGE (`docs/f2/ospf-edge.md`). Los pings de las sesiones 1 y 2 confirman que `ether1` es el enlace a ISP-1 y `ether2` el de ISP-2.
2. **El export de F3 de EDGE ya no muestra las líneas de rename** que sí traía el de F2 (`backups/2026-10-14/EDGE.rsc`). El mapeo funcional no cambió: las IPs siguen en `ether1` y `ether2` y los pings pasan. Antes de reaplicar un `.rsc` en un nodo nuevo, revisar `/interface ethernet print`.
3. **`prefix-count` no sirve como evidencia.** En `session print` de EDGE sigue en 0 aunque el default ya está instalado (con 3m53s de uptime en `f3-06b`). La evidencia válida es la tabla de rutas y `advertisements`.
4. **`get` con propiedad suelta no imprime nada en 7.14.3.** `/routing bgp connection get to-ISP1 input.filter` no devuelve valor (`f3-06a` quedó sin resultados). Funciona la forma `:put [/routing bgp connection get [find name=to-ISP2] input.filter]` (`f3-07a`). Se evita `print` de la conexión para no mostrar la clave.
5. **Nombres de sesión.** RouterOS agrega `-1` al nombre de la sesión (`to-ISP1-1`); es normal.
6. **Preferencia entre ISPs.** Solo se observó el atributo `local-pref=200` de ISP-1. El `local-pref=100` de ISP-2 y el prepend de salida no se pudieron observar porque nunca estuvieron ambos ISP encendidos a la vez: se ejercitan en el drill 3 de F4.

## Pendiente (F4)

- Con ambos ISP arriba: confirmar que EDGE elige a ISP-1 y que el default de ISP-2 queda como respaldo.
- Drill 3: caída de ISP-1 y conmutación a ISP-2; prueba de clave BGP incorrecta (R1).
