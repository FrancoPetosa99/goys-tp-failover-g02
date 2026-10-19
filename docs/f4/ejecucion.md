# F4 — Cómo se ejecutó la fase: sesiones, quién operó y relojes (R5)

**Fecha:** 16 y 17/10/2026 (sesión 0 y 1 el 16 según el reloj del router, sesiones 2 a 5 el 17; más una pasada de correcciones el 17) · Evidencia: `capturas/f4/` y `capturas/f1/f1x-*` · Configuración final: `backups/2026-10-17/`.

Este documento deja asentado **cómo** se hizo F4, no solo qué salió: qué nodos estaban encendidos, quién escribió los comandos, quién acompañó y por qué los horarios de los logs no coinciden con los de las anotaciones a mano.

## Sesiones

| Sesión | Qué se hizo | Nodos encendidos | Documentos |
|:------:|-------------|------------------|------------|
| 0 | Corrección de la devolución de F1: quitar `/ip dhcp-client` de los 7 routers y regenerar exports | los 7 routers | `docs/f1/correccion-dhcp-client.md` |
| 1 | Drill 1 (falla del master VRRP), drill 5 (reparto de carga) y prueba de clave VRRP incorrecta | DIST-1, DIST-2, switches, PC-USER y SRV | `runbooks/drill-1-vrrp.md`, `runbooks/drill-5-load-sharing.md`, `docs/f4/clave-vrrp-incorrecta.md` |
| 2 | Drill 2 (caída de enlace OSPF), prueba de clave OSPF incorrecta y SNMPv3 en el core y la distribución | DIST-1, CORE-1 y CORE-2 (más los vecinos que cada prueba necesitaba) | `runbooks/drill-2-ospf.md`, `docs/f4/clave-ospf-incorrecta.md`, `docs/f4/snmpv3-claves.md` |
| 3 | "Internet simulada" (`203.0.113.1`), drill 3 (cae el proveedor, solo BGP) y drill 4 (`check-gateway`) | EDGE, ISP-1 e ISP-2 (CORE y DIST apagados) | `runbooks/drill-3-bgp.md`, `runbooks/drill-4-check-gateway.md`, `docs/f4/internet-simulada.md` |
| 4 | Clave BGP incorrecta, reglas `in-bgp-*` con conexión iniciada por el ISP, `originate-default` y netwatch | EDGE e ISP-1 (ISP-2 apagado) | `docs/f4/clave-bgp-incorrecta.md`, `docs/f4/ospf-default-if-installed.md`, `docs/f4/monitoreo.md` |
| 5 | Alertas por syslog hacia SRV, intento de `snmpwalk`, exports finales | EDGE, CORE, DIST, PC-USER y SRV (ISP-1 apagado durante la prueba de la alerta) | `docs/f4/monitoreo.md` |
| Correcciones | Repetir lo que había salido vacío o incompleto, con **todos los nodos encendidos** (la virtualización anidada ya estaba habilitada) | los 11 nodos | ver `docs/f4/cambios.md` |

La pasada de correcciones repitió, entre otras cosas, el prepend de BGP visto desde cada ISP (`f4-03e2`, `f4-03f2`), el traceroute de PC-USER y SRV hasta `203.0.113.1` (`f4-03s`, `f4-03t`), la regla de SNMP del firewall (`f4-04h2`), la regla duplicada de logging de EDGE (`f4-05h2`, `f4-05h3`) y la unicidad del `engine-id` de SNMPv3 (`f4-02t`).

## Relojes: por qué las horas no coinciden

- Los CHR **no tienen NTP**: cada router lleva su propio reloj, que marca **UTC** (hora de Argentina más 3 h) y no está sincronizado con los demás. Por eso las horas de **routers distintos no son comparables entre sí**.
- La única comparación directa con la hora real es la de EDGE en la sesión 4: R2 anotó el cambio de clave BGP a las 19:35 (Argentina) y el router lo registró a las 23:00:09, es decir, **≈ 25 min por delante** de lo esperable (19:35 + 3 h = 22:35 UTC).
- Por eso en los runbooks hay dos tipos de hora: la **del router** (de `/log print` y `/system clock print`, indicada como "reloj del router") y la **anotada a mano por R2** (hora de Argentina).
- **Las duraciones sí son confiables**: salen de contadores del propio equipo (`uptime`, `last-started`, paquetes enviados y recibidos por segundo) y no dependen del reloj absoluto.
- Para relacionar dos eventos (por ejemplo, el aviso de netwatch contra la caída de la sesión BGP) se usó siempre el reloj del mismo router.

## Archivos que NO se suben

Hay capturas de intentos previos que quedaron reemplazadas por una versión corregida; por eso el repo tiene menos capturas que el PDF de trabajo. Los reemplazos y los motivos están en `docs/f4/cambios.md`. Tampoco se suben los `.backup` binarios (`f4-s0-pre` en cada router) ni el PDF de trabajo.
