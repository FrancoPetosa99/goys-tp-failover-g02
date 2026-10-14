# F3 — Verificación de BGP, redistribución, salida a Internet y firewall (R5)

**Fecha:** 2026-10-13 (sesiones 1 a 5) y 2026-10-14 (sesiones 6 y 7), hora de Argentina; los routers marcan UTC (los exports de la sesión 7 dicen 03:37 a 03:55 del 14/10) · Evidencia: `capturas/f3/` (46 capturas) · Configuración: `backups/2026-10-14/`.

## Método: sesiones con pocos routers

La VM de GNS3 se inestabiliza con varios routers encendidos. F3 se hizo en 7 sesiones: seis con un máximo de 2 routers y una (la prueba de punta a punta) con 4 routers, porque el camino PC-USER → DIST-1 → CORE-1 → EDGE → ISP-1 no se puede probar con menos. El procedimiento fue: encendido escalonado, consolas solo en EDGE, ISP-1 y el host, y los hosts de a uno.

| Sesión | Encendidos | Qué se hizo | Documento |
|:------:|------------|-------------|-----------|
| 1 | EDGE + ISP-1 | Verificar enlace, eBGP con TCP-MD5 | `bgp-edge.md`, `bgp-isp.md` |
| 2 | EDGE + ISP-2 | Lo mismo con ISP-2 | `bgp-edge.md`, `bgp-isp.md` |
| 3 | EDGE + CORE-1 | Default hacia OSPF, filtros BGP y redistribución | `ospf-default-y-core.md`, `bgp-edge.md` |
| 4 | EDGE + ISP-1 | Firewall: reglas y pruebas desde afuera | `firewall-edge.md` |
| 5 | EDGE + CORE-1 | Firewall: pruebas desde adentro | `firewall-edge.md` |
| 6 | EDGE + ISP-1 | Verificación de la política BGP (filtros aplicados, `local-pref`) | `bgp-edge.md` |
| 7 | ISP-1, EDGE, CORE-1, DIST-1 (+ PC-USER y SRV de a uno); al final ISP-2 solo | Punta a punta, pruebas negativas y exports finales | `salida-lans-y-traceroute.md` |

## Resultados por tarea del backlog

| Tarea de F3 | Resultado | Evidencia |
|-------------|:---------:|-----------|
| eBGP en ISP-1 e ISP-2 con `default-originate` | ✅ | `f3-01d`, `f3-02d` |
| eBGP ×2 en EDGE | ✅ | `f3-01c`, `f3-02c` |
| TCP-MD5 en ambas sesiones y `established` | ✅¹ | `f3-01c/d`, `f3-02c/d` |
| Redistribución OSPF→BGP: los ISP aprenden las LANs | ✅ | `f3-07c`, `f3-07d` |
| PC-USER y SRV → loopback de ISP | ✅² | `f3-07f`, `f3-07g` |
| Filtro de entrada y plano de gestión en EDGE | ✅ | `f3-04a/b/c`, `f3-07i1/i2` |
| Reglas verificadas con pruebas permitidas y bloqueadas | ✅³ | `f3-04d…g`, `f3-05b…e`, `f3-07e`, `f3-07h` |

¹ TCP-MD5 configurado en los dos extremos y sesiones en `E`; la prueba con clave incorrecta es de F4.
² Solo la loopback de ISP-1 (principal). Ver limitaciones.
³ Las reglas `in-bgp-*` están cargadas pero no registraron paquetes; ver limitaciones.

## Matriz de pruebas

| # | Prueba | Esperado | Resultado | Captura |
|:-:|--------|----------|:---------:|---------|
| 1 | EDGE ↔ ISP-1 ping | 4/4 | ✅ | `f3-01a`, `f3-01b` |
| 2 | Sesión BGP EDGE ↔ ISP-1 | `E` | ✅ | `f3-01c`, `f3-01d` |
| 3 | EDGE recibe default de ISP-1 | `0.0.0.0/0` por 192.0.2.1 | ✅ | `f3-01e` |
| 4 | EDGE → 198.51.100.1 | 4/4 | ✅ | `f3-01f` |
| 5 | EDGE ↔ ISP-2 ping | 4/4 | ✅ | `f3-02a`, `f3-02b` |
| 6 | Sesión BGP EDGE ↔ ISP-2 | `E` | ✅ | `f3-02c`, `f3-02d` |
| 7 | EDGE recibe default de ISP-2 | `0.0.0.0/0` por 192.0.2.5 | ✅ | `f3-02e` |
| 8 | EDGE → 198.51.100.2 | 4/4 | ✅ | `f3-02f` |
| 9 | Filtros y `originate-default` cargados | 6 reglas, `always` | ✅ | `f3-03a`, `f3-03b` |
| 10 | CORE-1 aprende default por OSPF | `0.0.0.0/0` por 10.0.0.1 | ✅ | `f3-03c`, `f3-03d`, `f3-03e` |
| 11 | Firewall: ICMP desde ISP-1 | permitido | ✅ | `f3-04d` |
| 12 | Firewall: BGP se restablece tras `disable`/`enable` | `E` | ✅ | `f3-04e1`, `f3-04e2` |
| 13 | Firewall: HTTP y SSH desde ISP-1 | bloqueado | ✅ | `f3-04f1`, `f3-04f2`, `f3-04g` |
| 14 | Firewall: OSPF, ping y SSH desde CORE-1 | permitido | ✅ | `f3-05a`, `f3-05b`, `f3-05c` |
| 15 | Firewall: HTTP desde CORE-1 | bloqueado | ✅ | `f3-05d`, `f3-05e` |
| 16 | Filtros aplicados a las conexiones | `in-isp1`/`out-isp1` e `in-isp2`/`out-isp2`/`ospf` | ✅ | `f3-06b`, `f3-07a` |
| 17 | `local-pref` de ISP-1 | 200 | ✅ | `f3-06c` |
| 18 | EDGE aprende las LANs por OSPF | 2 LANs por 10.0.0.2 | ✅ | `f3-07b` |
| 19 | EDGE anuncia solo las LANs | 2 prefijos a ISP-1 | ✅ | `f3-07c` |
| 20 | ISP-1 aprende las LANs, sin rutas 10.x | 192.168.10.0/24 y .20.0/24 | ✅ | `f3-07d` |
| 21 | ISP-1 → LAN (nuevo desde `WAN`) | bloqueado | ✅ | `f3-07e`, `f3-07h` |
| 22 | ISP-1 → loopback interna | `no route` | ✅ | `f3-07e` |
| 23 | PC-USER → 198.51.100.1 | 4/4, 4 saltos | ✅ | `f3-07f` |
| 24 | SRV → 198.51.100.1 | 4/4, 4 saltos | ✅ | `f3-07g` |
| 25 | Exports finales de EDGE, ISP-1 e ISP-2 | `.rsc` | ✅ | `f3-07i1/i2`, `f3-07j`, `f3-07k` |

## Limitaciones y observaciones

1. **Sin ambos ISP encendidos a la vez.** No se vio la elección entre ISP-1 y ISP-2: solo se observó `local-pref=200` en ISP-1. El `local-pref=100` de ISP-2 y el prepend de salida se ejercitan en el drill 3 de F4.
2. **Solo la loopback de ISP-1 se probó de punta a punta**, y los ISP no se ven entre sí (la de ISP-2 no es alcanzable con ISP-1 como camino principal).
3. **Reglas `in-bgp-*` sin tráfico propio.** EDGE inicia las sesiones y el retorno pasa por `in-estab`; la dirección "el ISP inicia" no se ejercitó. Para F4.
4. **Default por OSPF con `always`**, no `if-installed` (no se puede probar con 2 routers). Ver `docs/f3/ospf-default-y-core.md`.
5. **CORE-2 y DIST-2 no participaron** en F3: sus adyacencias y VRRP están probados en F2, pero la propagación del default hacia ellos no se observó.
6. **`prefix-count` de BGP no es confiable** en esta versión: se usa la tabla de rutas y `advertisements`.
7. **`f3-06a` quedó sin resultados** (el `get` con propiedad suelta no imprime nada en 7.14.3); lo reemplaza `f3-07a`, hecho con `:put [... get [find name=…] …]`.
8. **El export de EDGE de F3 no muestra las líneas de rename de interfaz** que sí traía el de F2; los pings de las sesiones 1 y 2 confirman el cableado.
9. **Los `.rsc` son transcripciones de las capturas.** Las líneas de `/routing bgp connection` aparecen recortadas en las capturas y se completaron con los comandos aplicados (anotado en el encabezado de cada `.rsc`). Si algo no coincide con la consola, vale la consola.
10. **Sin cambios en CORE-1, CORE-2, DIST-1 y DIST-2** durante F3: su backup vigente sigue en `backups/2026-10-13/`.

## Pendiente (F4)

- Drill 3 (caída de proveedor) y prueba de clave incorrecta en BGP, con ambos ISP.
- Pruebas de conectividad iniciada desde el ISP para las reglas `in-bgp-*`.
- Regla de SNMP en el firewall al habilitar el monitoreo.
