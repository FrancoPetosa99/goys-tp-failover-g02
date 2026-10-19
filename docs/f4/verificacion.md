# F4 — Verificación de los drills, la seguridad de las claves y el monitoreo (R5)

**Fecha:** 2026-10-16 (sesión 1) y 2026-10-17 (sesiones 2 a 5 y correcciones); los routers marcan UTC, sin NTP y con relojes propios (ver `docs/f4/ejecucion.md`) · Evidencia: `capturas/f4/` (80 capturas) y `capturas/f1/f1x-*` (9) · Configuración: `backups/2026-10-17/`.

## Resultados por tarea del backlog

| Tarea de F4 | Resultado | Documento |
|-------------|:---------:|-----------|
| Drill 1: VRRP | ✅ | `runbooks/drill-1-vrrp.md` |
| Drill 2: OSPF | ✅ | `runbooks/drill-2-ospf.md` |
| Drill 3: cae el proveedor (BGP) | ✅ | `runbooks/drill-3-bgp.md` |
| Drill 4: `check-gateway` | ✅ | `runbooks/drill-4-check-gateway.md` |
| Drill 5: load-sharing VRRP | ✅ | `runbooks/drill-5-load-sharing.md` |
| Rotación de roles R1↔R2 | ✅ | `docs/f4/ejecucion.md` |
| SNMP con usuario `monitor` |  ✅1 | `docs/f4/snmpv3-claves.md` |
| Documentar qué se monitorea | ✅ | `docs/f4/monitoreo.md` |
| Clave OSPF incorrecta → adyacencia falla | ✅ | `docs/f4/clave-ospf-incorrecta.md` |
| Clave BGP incorrecta → sesión falla | ✅ | `docs/f4/clave-bgp-incorrecta.md` |
| Clave VRRP incorrecta → el grupo no se forma |  ✅2 | `docs/f4/clave-vrrp-incorrecta.md` |

1 SNMPv3 configurado en los 7 routers y verificado en cada uno; la consulta con `snmpwalk` desde SRV **no** se pudo demostrar (ver limitaciones).
2 Con clave distinta el grupo no se unifica: DIST-2 rechaza los anuncios y se declara master por su cuenta (dos masters). El efecto es un *split-brain* hasta restaurar la clave.

## Tiempos medidos

| Drill | Mecanismo | Resultado | Corte | Resolución |
|-------|-----------|-----------|:-----:|:----------:|
| 1 | VRRP, cae DIST-1 (hello 1 s) | 40 enviados / 37 recibidos (seq 14 a 16) | ≈ 3 s | 1 s |
| 1 | VRRP, failback | 90 / 90, 0 % | 0 s | 1 s |
| 2 | OSPF, corte silencioso (*dead* 40 s) | 240 / 178 | ≈ 31 s | 0,5 s |
| 2 | OSPF, corte con portadora | 60 / 58 | ≈ 1 s | 0,5 s |
| 3 | BGP, cae ISP-1 (*hold* 3 min) | 400 / 240 | ≈ 160 s | 1 s |
| 3 | BGP, failback | 240 / 240, 0 % | 0 s | 1 s |
| 4 | `check-gateway=ping` | 120 / 97 | ≈ 23 s | 1 s |
| Monitoreo | netwatch contra la caída de la sesión BGP | alerta ≈ 2 min 9 s **antes** que la sesión | — | segundos |

`check-gateway` detectó la caída ≈ 7 veces más rápido que BGP solo; OSPF por portadora, ≈ 30 veces más rápido que por *dead timer*.

## Matriz de pruebas

| # | Prueba | Esperado | Resultado | Captura |
|:-:|--------|----------|:---------:|---------|
| 1 | Estado VRRP inicial | DIST-1 `RM` en `vrrp10`, DIST-2 `RM` en `vrrp20` | ✅ | `f4-01a`, `f4-01b` |
| 2 | Primer salto de PC-USER y SRV | DIST-1 y DIST-2 | ✅ | `f4-01c`, `f4-01d` |
| 3 | Drill 1: failover y failback | corte de 3 a 4 s; failback sin pérdida | ✅ | `f4-01e`, `f4-01f`, `f4-01g`, `f4-01h` |
| 4 | Clave VRRP incorrecta | autenticación falla, dos masters | ✅ | `f4-01i`, `f4-01j`, `f4-01k` |
| 5 | Clave VRRP restaurada | un solo master | ✅ | `f4-01l1`, `f4-01l2` |
| 6 | Vecinos y rutas OSPF de DIST-1 | 2 vecinos `Full`, ruta por CORE-1 | ✅ | `f4-02a`, `f4-02b` |
| 7 | Drill 2: corte silencioso y reencaminado | ruta por CORE-2, *timeout* en el log | ✅ | `f4-02c`, `f4-02d`, `f4-02e` |
| 8 | Drill 2: restauración y variante con portadora | vecinos `Full`; corte de ~1 s | ✅ | `f4-02f`, `f4-02g` |
| 9 | Clave OSPF incorrecta en CORE-2 | `md5 mismatch`, adyacencia caída | ✅ | `f4-02h`, `f4-02i`, `f4-02j`, `f4-02k` |
| 10 | Clave OSPF restaurada | adyacencia `Full` | ✅ | `f4-02l` |
| 11 | SNMP: `public` neutralizada y engine-id único | 2 comunidades; engine-id por router | ✅ | `f4-02s1`, `f4-02s2`, `f4-02s3`, `f4-02t`, `f4-03o`, `f4-03p`, `f4-04i`, `f4-05b` |
| 12 | "Internet simulada" en ambos ISP | `203.0.113.1/32` en `lo` | ✅ | `f4-03a`, `f4-03b`, `f4-03d` |
| 13 | Prepend visto desde cada ISP | camino por ISP-2 más largo | ✅⁴ | `f4-03e2`, `f4-03f2` |
| 14 | Drill 3: failover y failback | sin pérdida en el failback | ✅ | `f4-03g`, `f4-03h`, `f4-03i`, `f4-03j` |
| 15 | Drill 4: `check-gateway` | corte menor que con BGP solo | ✅ | `f4-03k`, `f4-03l`, `f4-03m`, `f4-03n` |
| 16 | PC-USER y SRV → `203.0.113.1` | 3/3, 4 saltos | ✅ | `f4-03s`, `f4-03t` |
| 17 | Clave BGP incorrecta y restaurada | sesión cae y vuelve | ✅ | `f4-04a`, `f4-04b`, `f4-04c` |
| 18 | `in-bgp-isp1` con conexión iniciada por el ISP | cuenta paquetes; sin la regla cae en `in-drop-resto` | ✅ | `f4-04d`, `f4-04e`, `f4-04f`, `f4-04g` |
| 19 | Regla `in-snmp-lan` en el firewall | antes de `in-drop-resto` | ✅ | `f4-04h2` |
| 20 | Netwatch: alerta de caída y recuperación | ALERTA al caer ISP-1 | ✅ | `f4-04j`, `f4-04l`, `f4-04o` |
| 21 | `originate-default`: `if-installed` contra `always` | LSA retirado / sigue anunciado | ✅ | `f4-04k`, `f4-04m`, `f4-04n` |
| 22 | SRV alcanza las loopbacks de los routers | 3/3 | ✅ | `f4-05a` |
| 23 | `snmpwalk` desde SRV | respuesta SNMPv3 | ⚠ no demostrado | `f4-05c` |
| 24 | Alerta por syslog remoto a SRV | llega 1 línea por evento | ✅ | `f4-05g`, `f4-05h2`, `f4-05h3` |
| 25 | Exports finales de los 7 routers | `.rsc` sin `dhcp-client` | ✅ | `f4-02u1a/b`, `f4-02u2a/b`, `f4-02u3`, `f4-03q`, `f4-03r`, `f4-05i`, `f4-05j`, `f4-05j-c`, `f4-05k`, `f4-05l` |
| 26 | Cliente DHCP removido de los 7 routers | ninguno | ✅ | `f1x-01 … f1x-07b` |

⁴ Se esperaban **tres** repeticiones del AS 65000 desde ISP-2 y se vieron **dos** (ISP-1 ve `65000`). El efecto buscado se cumple, pero la causa no se investigó (ver `runbooks/drill-3-bgp.md`, observación 1).

## Limitaciones y observaciones

1. **No hay `snmpwalk` desde SRV.** El host es Alpine sin salida a Internet: `apk add net-snmp-tools` falla por DNS (`f4-05c`). SNMPv3 quedó configurado y verificado en los routers (`/snmp print`, engine-id, comunidad), pero la consulta real no se demostró.
2. **Suspend/Resume de enlace en GNS3 deja el cable muerto.** Se arregló borrando y recreando el cable. Para próximos drills: Stop/Start del nodo o deshabilitar la interfaz.
3. **Resolución de los pings.** Un ping a 1 s (o 0,5 s) mide el corte con esa cota; son órdenes de magnitud correctos, no mediciones al milisegundo.
4. **Netwatch mira ICMP, no la sesión BGP.** Avisó 2 min 9 s antes de que BGP se diera por vencido, pero no distingue "el gateway responde" de "el ISP tiene salida". Es una alerta temprana, no un reemplazo del estado de BGP.
5. **Solo ISP-1 está monitoreado por netwatch.** Para ISP-2 habría que repetir la entrada; no se hizo.
6. **ISP-2 estuvo apagado en la sesión 4.** Con ISP-2 apagado la clave BGP incorrecta dejó a EDGE sin default; con los dos proveedores el respaldo habría tomado el tráfico.
7. **Prepend: dos repeticiones en lugar de tres** (observación ⁴). Punto abierto para la memoria.
8. **Los routers no tienen NTP** y los horarios absolutos difieren entre equipos y de las anotaciones a mano (`docs/f4/ejecucion.md`). Los tiempos son duraciones, no horas.
9. **La comunidad SNMP `public` no se puede borrar** en RouterOS 7: se neutralizó (`127.0.0.1/32`, sin lectura). Figura en los exports.
10. **Los `.rsc` son transcripciones de las capturas** y llevan placeholders de claves; si algo no coincide con la consola, vale la consola. La captura del export de EDGE (`f4-05j-c`) todavía muestra la regla de logging duplicada que se borró después (`f4-05h2`); el `.rsc` tiene una sola.
11. **No se probó la caída de un enlace físico real de un ISP** (solo Stop del nodo), así que el corte de BGP medido es el caso difícil: sin aviso ni caída de portadora.

## Pendiente (F5)

- Resumir los tiempos en la memoria (tabla de este documento) y escribir el post-mortem comparativo VRRP / OSPF / BGP / `check-gateway`.
- Decidir si se investiga el prepend (2 contra 3) o se deja como punto abierto.
