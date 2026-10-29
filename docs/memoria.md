# Memoria final — Proyecto Integrador "Failover Routing" (Grupo 2)

> **Nota sobre el formato:** no se encontró en el repositorio ninguna plantilla de la cátedra para esta memoria (se buscaron archivos `.md`/`.pdf` con nombres como "plantilla", "consigna", "enunciado" o "rubrica" en todo el repo, y no hay ninguno). `backlog.md` asume que esa plantilla se copia desde afuera, pero no está versionada. Esta memoria usa en cambio una estructura por defecto (resumen → objetivo → topología → diseño por capa → defectos corregidos → claves → configs finales → verificación/drills → seguridad → monitoreo → change log → backups → limitaciones → checklist). Si la cátedra entrega la plantilla real, hay que reordenar las secciones existentes para que calcen; el contenido de cada una ya está consolidado y no debería perderse en la migración.

## 1. Resumen

El laboratorio implementa, sobre GNS3 con 7 MikroTik CHR (RouterOS 7.14.3), una red empresarial de 5 capas (Internet, Edge, Core, Distribución, Acceso) con redundancia en cada capa: **VRRP** en el primer salto, **OSPF** (área 0, con MD5) como IGP interno y **eBGP multi-homing** con TCP-MD5 hacia dos proveedores en el borde. El EDGE concentra el firewall (default-deny) y la salida a Internet; el monitoreo se apoya en SNMPv3, `netwatch` y syslog remoto. Las 5 fases (F0 a F4) están entregadas y verificadas con evidencia (capturas, exports `/export` y 5 drills de failover); esta memoria (F5) consolida esa evidencia, no repite el trabajo.

## 2. Objetivo y alcance

Diseñar, desplegar, operar y verificar una red con alta disponibilidad por capa, partiendo de un diagrama de referencia con defectos de diseño ("Enterprise Network Design (Cisco)", IT With Manas) que el grupo debía corregir (`docs/f0/topologia-y-failover.md`). Alcance: 7 routers MikroTik CHR + 2 switches + 2 hosts (PC-USER, SRV) en GNS3, sin tocar hardware real. Quedan fuera del alcance (documentado desde F0, `docs/f0/topologia-y-failover.md` §3.7): VLANs de gestión/native VLAN hardening, QoS, STP root designado y DHCP snooping/DAI/port-security en los switches de acceso — se los deja como mejoras de producción.

## 3. Topología e IPAM

Diagrama objetivo: [`docs/diagramas/topologia-objetivo.png`](diagramas/topologia-objetivo.png). 11 nodos de laboratorio (7 routers + 2 switches + 2 hosts) y 15 enlaces (`docs/f0/topologia-y-failover.md`):

```
Cloud1 ─ ISP-1 (AS 65001)          ISP-2 (AS 65002) ─ Cloud2
              \                      /          eBGP + TCP-MD5
               EDGE (AS 65000)                   firewall, default-deny
              /                \                 OSPF área 0 + MD5
         CORE-1 ───────────── CORE-2              (core-core)
          |  \                /  |
          |   \______  ______/   |
          |          \/          |
          |          /\          |
          |   ______/  \______   |
          |  /                \  |
        DIST-1               DIST-2            VRRP (vrid 10/20) + OSPF
          |  \                /  |
       SW-ACC-USERS        SW-ACC-SERVERS       (cada switch dual-homed)
            |                 |
         PC-USER             SRV
```

Plan de direccionamiento consolidado: [`ipam.md`](../ipam.md) — enlaces punto a punto en `10.0.0.0/27` (internos) y `192.0.2.0/29` (hacia los ISP, TEST-NET-1), LANs de acceso `192.168.10.0/24` (USERS) y `192.168.20.0/24` (SERVERS), loopbacks en `10.255.0.0/24` (internas) y `198.51.100.0/24` (ISP, TEST-NET-2), sin solapamiento (verificado en `ipam.md` §3.5). Router-IDs y AS en `ipam.md` §3.4. (Nota de ruta: tanto el README como los `cambios.md` de F2-F4 citan este archivo como `docs/f0/ipam.md`; físicamente está en la raíz del repo — ver `docs/f5/observaciones.md`.)

## 4. Diseño por capa

### 4.1 VRRP (primer salto, capa de distribución)

Diseño: `docs/f0/distribucion-vrrp.md`. Implementación: `docs/f2/distribucion-vrrp-ospf.md`. Dos grupos VRRPv2 con autenticación simple (`<VRRP-KEY>`), cada DIST master de uno y backup del otro (load-sharing):

| Grupo | VRID | Master | Priority (master/backup) | IP virtual |
|-------|:----:|:------:|:-------------------------:|:----------:|
| USERS | 10 | DIST-1 | 150 / 100 | 192.168.10.1 |
| SERVERS | 20 | DIST-2 | 150 / 100 | 192.168.20.1 |

VRRP v3 no soporta autenticación en RouterOS, de ahí la elección de v2 (limitación conocida: la auth simple viaja en texto plano, protege contra un router mal configurado, no contra un atacante en la LAN — `docs/f2/claves-y-secretos.md`). Verificado con `/interface vrrp print` (`capturas/f2/f2-01-vrrp-dist1-dist2.png`) y con el drill 5 de reparto de carga (`runbooks/drill-5-load-sharing.md`): PC-USER sale por DIST-1, SRV por DIST-2.

### 4.2 OSPF (IGP interno, área 0 con MD5)

Diseño: `docs/f2/ospf-core-md5.md` (core) y `docs/f2/ospf-edge.md` (EDGE). Una sola área (`backbone`, 0.0.0.0), los 5 routers internos (EDGE, CORE-1, CORE-2, DIST-1, DIST-2), tipo `ptp` en todos los enlaces /30, autenticación MD5 (`auth-id=1`, `<OSPF-KEY>`) en toda interfaz con vecinos, LANs y loopbacks como `passive`. Timers por defecto: hello 10 s, dead 40 s. Incluye el enlace core-core (CORE-1 ↔ CORE-2) que corrige el defecto 3 del diagrama original. Las 7 adyacencias del diseño quedaron en `Full` con MD5, verificadas por pares en `docs/f2/verificacion.md` (la VM de GNS3 no soporta los 11 nodos a la vez, así que F2 se hizo en 8 sesiones de a 2 routers). EDGE anuncia el default de BGP hacia el core con `originate-default=always` (decisión documentada en §9).

### 4.3 BGP (multi-homing de proveedor)

Diseño: `docs/f3/bgp-edge.md` (EDGE) y `docs/f3/bgp-isp.md` (ISP). EDGE (AS 65000) mantiene dos sesiones eBGP, una con cada proveedor, con TCP-MD5 (`<BGP-KEY-ISP1>`, `<BGP-KEY-ISP2>`, distintas entre sí):

| Sesión | Vecino | AS | `local-pref` de entrada | Prepend de salida |
|--------|--------|:--:|:-----------------------:|:------------------:|
| `to-ISP1` | ISP-1 | 65001 | **200** (principal) | ninguno |
| `to-ISP2` | ISP-2 | 65002 | 100 (respaldo) | `bgp-path-prepend 2` |

Cada ISP origina un default (`default-originate=always`) y EDGE redistribuye OSPF→BGP para anunciar solo las dos LANs (192.168.10.0/24 y 192.168.20.0/24), nunca el direccionamiento interno. Verificado en `docs/f3/verificacion.md` y en `docs/f3/salida-lans-y-traceroute.md` (PC-USER y SRV llegan a la loopback de ISP-1 en 4 saltos).

### 4.4 Firewall (EDGE)

Diseño: `docs/f0/edge-seguridad.md`. Implementación: `docs/f3/firewall-edge.md`. Política **default-deny** en `input` y `forward`, con listas de interfaces `WAN` (ether1/ether2, hacia los ISP) y `LAN` (ether3/ether4, hacia el core). `input` acepta established/related, ICMP, BGP solo desde la IP de cada ISP, OSPF y SSH solo desde `LAN`; el resto se descarta. `forward` permite `LAN→WAN` y `LAN→LAN` (tránsito entre cores si cae el core-core), descarta todo lo demás — en particular, impide que un ISP inicie conexiones hacia las LANs o que EDGE sea tránsito entre ISP-1 e ISP-2. El firewall vive solo en EDGE (corrige el defecto 1 del diagrama original, un único firewall SPOF; ver §5). Verificado con pruebas permitidas/bloqueadas desde ISP-1 y desde CORE-1 (`docs/f3/firewall-edge.md`), y con la conexión BGP iniciada por el propio ISP en F4 (`docs/f4/clave-bgp-incorrecta.md`, parte B): sin la regla `in-bgp-isp1` el SYN del ISP cae en `in-drop-resto`; con ella, la sesión se establece.

### 4.5 Monitoreo

Diseño y resultado: `docs/f4/monitoreo.md`, `docs/f4/snmpv3-claves.md`. Tres mecanismos:

- **SNMPv3** `authPriv` (SHA1/AES, usuario `monitor`, solo lectura, `<SNMP-AUTH-KEY>`/`<SNMP-PRIV-KEY>`) en los 7 routers, con `engine-id-suffix` único por equipo y la comunidad `public` neutralizada (RouterOS 7 no permite borrarla).
- **netwatch** en EDGE: ping a ISP-1 (`192.0.2.1`) cada 10 s, con alerta de caída/recuperación por log.
- **syslog remoto**: EDGE envía las alertas de netwatch por UDP/514 a SRV.

Ver §10 para el detalle de qué quedó sin demostrar (`snmpwalk` desde SRV).

## 5. Defectos corregidos del diagrama original

| # | Defecto (diagrama "Enterprise Network Design", Cisco/IT With Manas) | Corrección aplicada | Documento |
|:-:|------------------------------------------------------------------|----------------------|-----------|
| 1 | Firewall sin par HA (SPOF) | Filtrado concentrado en EDGE (RouterOS); en producción irían dos firewalls activo/standby | `docs/f0/edge-seguridad.md` |
| 2 | Subredes solapadas entre sitios | IPAM con un /30 distinto por enlace y un /24 distinto por LAN, sin overlap | `docs/f0/distribucion-vrrp.md`, `ipam.md` |
| 3 | Sin enlace core–core | CORE-1 ↔ CORE-2 agregado a OSPF área 0 (camino alterno) | `docs/f0/core-defectos.md` |
| 4 | HSRP en el core ("collapsed") | FHRP movido a distribución con VRRP (RFC 5798, estándar abierto); el core queda como tránsito puro | `docs/f0/core-defectos.md` |
| 5 | iBGP Route Reflector mal ubicado (a través del firewall) | eBGP directo en el edge con cada ISP, sin RR (innecesario con un solo router de borde) | `docs/f0/edge-seguridad.md` |

## 6. Política de claves

Diseño: `docs/f0/proveedores-claves.md`. Una clave distinta por mecanismo, nunca commiteada al repo; se comparten por canal privado del grupo. En toda la documentación, configs y backups se usan placeholders:

| Mecanismo | Dónde | Placeholder |
|-----------|-------|-------------|
| OSPF MD5 | EDGE, CORE-1, CORE-2, DIST-1, DIST-2 | `<OSPF-KEY>` |
| VRRP auth simple | DIST-1, DIST-2 (grupos 10 y 20) | `<VRRP-KEY>` |
| BGP TCP-MD5 (ISP-1) | EDGE ↔ ISP-1 | `<BGP-KEY-ISP1>` |
| BGP TCP-MD5 (ISP-2) | EDGE ↔ ISP-2 | `<BGP-KEY-ISP2>` |
| SNMPv3 auth | los 7 routers | `<SNMP-AUTH-KEY>` |
| SNMPv3 priv | los 7 routers | `<SNMP-PRIV-KEY>` |

Hallazgos acumulados (`docs/f2/claves-y-secretos.md`, `docs/f3/claves-bgp.md`, `docs/f4/snmpv3-claves.md`):

- `/export hide-sensitive` **no** oculta `auth-key` de OSPF (sigue en texto plano), pero **sí** oculta `tcp-md5-key` de BGP y los passwords de la comunidad SNMP. Por eso los `.rsc` de OSPF se filtraron a mano (`sed`) antes de subirlos.
- El export tampoco guarda el password de VRRP ni el `tcp-md5-key` de BGP: un restore desde `.rsc` requiere volver a cargarlos a mano.
- Desvío aceptado de laboratorio: las claves usadas son cortas y fáciles de recordar (no "triviales" en el sentido de público, pero tampoco largas/aleatorias como pediría la política de F0). En producción serían largas, aleatorias y rotadas.
- Límites de longitud por protocolo: OSPF MD5 hasta 16 caracteres, VRRP v2 hasta 8, SNMPv3 `authPriv` mínimo 8.

## 7. Configuraciones finales por router

El estado vigente de cada router es el `/export` de **`backups/2026-10-17/`** (cierre de F4, ya sin cliente DHCP — ver §12 y `docs/f1/correccion-dhcp-client.md`). Esos 7 `.rsc` se copiaron sin modificar a `configs/` (`EDGE.rsc`, `CORE-1.rsc`, `CORE-2.rsc`, `DIST-1.rsc`, `DIST-2.rsc`, `ISP-1.rsc`, `ISP-2.rsc`) para que el repositorio tenga, en un solo lugar, la config final de cada equipo junto con las de los hosts (`configs/hosts/PC-USER.interfaces`, `configs/hosts/SRV.interfaces`).

**Pendiente de confirmación por rol** (R1-R4, antes de subir F5): revisar que el `.rsc` de sus routers en `configs/` sea efectivamente el que cada uno validó en F4, dado que esta copia la hizo R5/la memoria de forma mecánica a partir de `backups/2026-10-17/` sin re-verificar contra la consola.

## 8. Verificación y drills: tiempos de failover

Fuente primaria: `docs/f4/verificacion.md` §"Tiempos medidos", corroborada en cada runbook (`runbooks/drill-1-vrrp.md`, `drill-2-ospf.md`, `drill-3-bgp.md`, `drill-4-check-gateway.md`) y en `docs/f4/monitoreo.md` (netwatch vs. BGP).

| Mecanismo | Qué mide | Corte observado | Resolución de la medición |
|-----------|----------|:----------------:|:--------------------------:|
| VRRP (hello 1 s) | failover del gateway virtual al caer DIST-1 | **≈ 3 s** (3 de 40 paquetes perdidos) | 1 s |
| VRRP | failback (DIST-1 retoma el master) | 0 % de pérdida | 1 s |
| OSPF, *dead timer* (hello 10 s / dead 40 s) | reencaminado al caer un enlace sin aviso de portadora | **≈ 31 s** (25 % de pérdida sobre 240 pings) | 0,5 s |
| OSPF, detección por portadora | reencaminado con caída de link detectada | **≈ 1 s** (3 % de pérdida sobre 60 pings) | 0,5 s |
| BGP (*hold time* 3 min) | failover de proveedor sin aviso (caída "dura") | **≈ 160 s** (40 % de pérdida sobre 400 pings) | 1 s |
| BGP | failback (ISP-1 recupera el default) | 0 % de pérdida | 1 s |
| `check-gateway=ping` (ruta estática) | failover de proveedor detectado por ping al gateway | **≈ 23 s** (19 % de pérdida sobre 120 pings) | 1 s |
| netwatch vs. sesión BGP | aviso temprano de caída de ISP-1 | avisó **≈ 2 min 9 s antes** que BGP (23:23:36 vs. 23:25:45, reloj de EDGE) | segundos |

### Post-mortem comparativo

- **VRRP es, por lejos, el mecanismo más rápido** (≈ 3 s): el *master-down timer* es del orden de 3 hellos de 1 s. Es también el único failover sin intervención de un operador: ocurre solo con la caída del nodo.
- **OSPF tiene dos velocidades muy distintas según cómo se detecta la falla:** por *dead timer* (hello/dead por defecto) tarda ≈ 31 s; si la interfaz detecta la caída de portadora, el vecino cae casi de inmediato y el corte baja a ≈ 1 s — una diferencia de **≈ 30 veces**. La recomendación que se desprende (`runbooks/drill-2-ospf.md`): en un enlace físico real conviene la detección por portadora siempre que exista, y evaluar BFD si hiciera falta bajar más el tiempo en un enlace donde la portadora no avisa (por ejemplo, un link lógico sobre una WAN).
- **BGP solo, con los timers por defecto, es el más lento** (≈ 160 s, dentro de la ventana teórica de 180 s del *hold timer*): los keepalive/hold de BGP están pensados para estabilidad de ruteo entre proveedores, no para detectar fallas rápido.
- **`check-gateway=ping` sobre una ruta estática reduce el corte de proveedor en ≈ 7 veces** respecto de BGP solo (160 s → 23 s), porque sondea el siguiente salto cada pocos segundos en lugar de esperar el *hold timer*. Su límite: solo ve si el gateway inmediato responde, no si el proveedor tiene salida real a Internet más allá de ese salto.
- **netwatch adelanta la alerta ≈ 2 min 9 s respecto de BGP**, por el mismo motivo que `check-gateway` (sondea ICMP, no espera los timers de BGP), pero es una alerta operativa, no un mecanismo de conmutación: no cambia rutas ni reemplaza el estado real de la sesión BGP.
- **Los failback siempre fueron limpios (0 % de pérdida)** en los tres mecanismos (VRRP, OSPF, BGP): al volver el camino preferido, la transición no descarta paquetes porque el camino de respaldo sigue siendo válido durante el cambio.
- **Jerarquía de velocidad resultante:** VRRP (≈ 3 s) < OSPF por portadora (≈ 1 s, aún más rápido que VRRP) < `check-gateway` (≈ 23 s) < OSPF por *dead timer* (≈ 31 s) < BGP solo (≈ 160 s). La lectura de diseño: cuanto más alto el nivel del protocolo (primer salto → IGP → BGP entre AS), más lento el mecanismo de detección por defecto, y ahí es donde vale la pena un detector auxiliar (`check-gateway`, netwatch, o BFD en producción).

Todas las mediciones son duraciones por conteo de paquetes de ping a intervalo fijo (1 s o 0,5 s), no cronómetro: son órdenes de magnitud correctos, no mediciones al milisegundo (`docs/f4/verificacion.md`, limitación 3).

## 9. Seguridad: pruebas de clave incorrecta

Objetivo de F4: confirmar que cada mecanismo de autenticación rechaza una clave que no coincide. Las tres pruebas usaron un valor incorrecto nunca documentado (`<CLAVE-INCORRECTA>`), restaurado al final de cada prueba.

| Mecanismo | Documento | Qué pasó | Tiempo de recuperación al restaurar |
|-----------|-----------|----------|:------------------------------------:|
| VRRP (DIST-2, grupo 10) | `docs/f4/clave-vrrp-incorrecta.md` | DIST-2 rechaza los anuncios de DIST-1 (`simple authentication failed`) y se autoproclama master: **split-brain**, dos masters para la misma IP/MAC virtual | inmediato al restaurar la clave |
| OSPF MD5 (CORE-1 ↔ CORE-2) | `docs/f4/clave-ospf-incorrecta.md` | CORE-2 registra `md5 mismatch`; la adyacencia no se forma; el tráfico no se corta porque hay camino alterno por DIST-1 | **1 min 28 s** |
| BGP TCP-MD5 (EDGE ↔ ISP-1) | `docs/f4/clave-bgp-incorrecta.md` | la sesión cae al cambiar la clave y no vuelve mientras no coincidan (con ISP-2 apagado, EDGE queda sin default) | sesión restablecida en segundos tras restaurar |

Lectura de conjunto: los tres mecanismos de autenticación **cumplen su función** (ningún vecino con clave distinta logra participar), pero el efecto de la falla es distinto en cada capa — VRRP genera un split-brain activo (dos masters simultáneos) en vez de dejar sin servicio, mientras que OSPF y BGP simplemente no forman la relación y dependen de la redundancia de camino (OSPF) o de proveedor (BGP) para no perder servicio. Por eso la clave VRRP se cambia en los dos routers a la vez, en ventana de mantenimiento, y nunca de a uno.

## 10. Monitoreo: qué se demostró y qué no

Ver §4.5 para el diseño. Evidencia de funcionamiento: alerta de netwatch registrada en el log de EDGE y recibida en SRV por syslog con una sola línea por evento (`docs/f4/monitoreo.md`); SNMPv3 verificado del lado de cada router (`/snmp print`, engine-id único, comunidad `monitor`) en los 7 equipos.

**Lo que no se pudo demostrar:** la consulta real con `snmpwalk` desde SRV. SRV es un host Alpine sin salida a Internet; `apk add net-snmp-tools` falla por falta de resolución DNS (`docs/f4/verificacion.md`, limitación 1; `docs/f4/monitoreo.md`). Queda configurado y verificado del lado del router, pero sin una consulta cliente real completada.

Otras limitaciones de monitoreo documentadas: netwatch solo vigila ISP-1 (no hay entrada para ISP-2); no hay alertas automáticas para VRRP, OSPF ni BGP (la verificación de esos protocolos durante los drills fue manual); el syslog remoto va por UDP sin cifrar ni confirmación de entrega (si SRV está apagado, el aviso se pierde sin reintento, aunque queda igual en el log local de EDGE).

## 11. Change log consolidado (F0 → F4)

Formato de `operacion.md` §5.1 (archivo en la raíz del repo, ver nota de ruta en §3). F0 y F1 no tienen un `cambios.md` dedicado: F0 fue diseño puro (sin tocar ningún router) y F1 fue el primer despliegue y hardening (documentado por tarea en `docs/f1/*.md`, sin registrarse todavía como tabla de change log; la convención de commits recién se define en `operacion.md` §5.1 durante F0 y se aplica como tabla desde F2). La corrección del cliente DHCP de F1 se ejecutó y registró durante F4 (sesión 0) y aparece en esa fila.

| Fase | Fecha | Responsable | Cambio | Motivo | Cómo se revierte |
|:----:|-------|:-----------:|--------|--------|------------------|
| F2 | 2026-10-13 | R4 | VRRP v2 con auth simple: `vrrp10`/`vrrp20` en DIST-1 y DIST-2 | Primer salto redundante con load-sharing | Quitar IPs virtuales y `/interface vrrp remove [find]` en ambos DIST |
| F2 | 2026-10-13 | R4 | OSPF en DIST-1 y DIST-2 (instancia, área, MD5, LANs/loopback pasivas) | Anunciar las LANs de acceso al core | `/routing ospf interface-template remove [find]`, luego área e instancia |
| F2 | 2026-10-13 | R3 | OSPF en CORE-1 y CORE-2, incluido el core-core, con MD5 | IGP del núcleo con camino alterno (defecto 3 de F0) | Igual que arriba |
| F2 | 2026-10-13 | R1 | OSPF en EDGE hacia CORE-1/CORE-2 con MD5; ISP fuera de OSPF | Reconvergencia interna; ISP irán por BGP en F3 | Igual que arriba |
| F2 | 2026-10-13 | R3 | Se elimina el usuario sobrante `moonitor` de CORE-1 | Cierra una corrección abierta de F1 | No aplica |
| F2 | 2026-10-13 | R2 | Documentación de claves aplicadas y hallazgo de export (`auth-key` visible) | Política de claves de F0 | No aplica |
| F2 | 2026-10-13 | R5 | Backups de EDGE, CORE-1, CORE-2, DIST-1, DIST-2 en `backups/2026-10-13/` | Política de backup al cerrar fase | No aplica |
| F3 | 2026-10-13 | R2 | eBGP en ISP-1/ISP-2 hacia EDGE, TCP-MD5, `default-originate=always` | Multi-homing con dos proveedores | `/routing bgp connection remove [find name=to-EDGE]` en cada ISP |
| F3 | 2026-10-13 | R1 | eBGP en EDGE con ISP-1 e ISP-2, clave TCP-MD5 distinta por sesión | Multi-homing con dos proveedores | `/routing bgp connection remove [find]` en EDGE |
| F3 | 2026-10-13 | R1 | Filtros BGP en EDGE: `in-isp1` (local-pref 200), `in-isp2` (100), `out-isp1`/`out-isp2` (solo las 2 LANs, prepend 2 hacia ISP-2) | ISP-1 principal; no filtrar direccionamiento interno | `/routing filter rule remove [find]` y quitar filtros de las conexiones |
| F3 | 2026-10-13 | R1 | Redistribución OSPF→BGP en EDGE | Que los ISP aprendan las LANs y el tráfico pueda volver | `output.redistribute=""` |
| F3 | 2026-10-13 | R3 | `originate-default=always` en la instancia OSPF de EDGE | Que el core salga a Internet por EDGE | `originate-default=never` |
| F3 | 2026-10-13 | R1 | Firewall edge: listas `WAN`/`LAN`, reglas `input`/`forward` default-deny, `ssh strong-crypto=yes` | Protección del borde y del plano de gestión | `/ip firewall filter remove [find]`, quitar listas |
| F3 | 2026-10-14 | R2 | Documentación de claves BGP y hallazgo de export (`tcp-md5-key` oculta, `auth-key` de OSPF no) | Política de claves de F0 | No aplica |
| F3 | 2026-10-14 | R5 | Backups de EDGE, ISP-1, ISP-2 en `backups/2026-10-14/` | Política de backup al cerrar fase | No aplica |
| F4 (s0) | 2026-10-16 | R1 | Quitar `/ip dhcp-client` de los 7 routers | Corrección de la devolución de F1 (superficie de ataque) | `/ip dhcp-client add interface=ether1` (no recomendado) |
| F4 (s2-5) | 2026-10-17 | R2 | SNMPv3 `authPriv` (SHA1/AES), comunidad `monitor`, en los 7 routers | Monitoreo de solo lectura | `/snmp community remove [find name=monitor]`, `/snmp set enabled=no` |
| F4 (s2-5) | 2026-10-17 | R2 | Comunidad `public` neutralizada (`127.0.0.1/32`, sin lectura) | RouterOS 7 no permite borrarla | `addresses=::/0 read-access=yes` (no recomendado) |
| F4 (s2-5) | 2026-10-17 | R2 | `engine-id-suffix` único por router | SNMPv3 necesita engine-id distinto por equipo (CORE-2 tenía el de CORE-1) | `/snmp set engine-id-suffix=""` |
| F4 (s3) | 2026-10-17 | R2 | `203.0.113.1/32` en la loopback de ISP-1 e ISP-2 ("Internet simulada") | Destino común para medir el failover de proveedor | `/ip address remove [find comment="Internet simulada"]` |
| F4 (s4) | 2026-10-17 | R1 | Regla `in-snmp-lan` (UDP/161 desde `LAN`) antes de `in-drop-resto` en EDGE | Abrir SNMP solo hacia adentro (pendiente de F3) | `/ip firewall filter remove [find comment=in-snmp-lan]` |
| F4 (s4) | 2026-10-17 | R5 | Netwatch `isp1` en EDGE (ping cada 10 s, alerta de caída/recuperación) | Monitoreo del proveedor principal | `/tool netwatch remove [find name=isp1]` |
| F4 (s5) | 2026-10-17 | R5 | Log remoto `srvsyslog` hacia SRV (UDP/514, tópico `script`) | Que las alertas de netwatch lleguen a SRV | Remover la acción y la regla de logging |

Cambios temporales de F4 (probados y revertidos en la misma sesión: clave VRRP/OSPF/BGP incorrecta, corte de enlace DIST-1↔CORE-1, rutas `check-gateway` de prueba, `originate-default=if-installed`, regla de logging duplicada): detalle completo en `docs/f4/cambios.md` — no se listan aquí de nuevo porque no quedan en la configuración final.

## 12. Backups

Política: `operacion.md` §5.2 — exports de texto (`/export`) versionados en `backups/<fecha>/`, backups binarios (`/system backup save`) fuera del repo, snapshot BASE de GNS3 tras el despliegue inicial.

| Fecha | Routers incluidos | Cierre de fase |
|-------|--------------------|-----------------|
| 2026-10-09 | los 7 routers (línea base) | F1 |
| 2026-10-13 | EDGE, CORE-1, CORE-2, DIST-1, DIST-2 | F2 |
| 2026-10-14 | EDGE, ISP-1, ISP-2 | F3 |
| 2026-10-17 | los 7 routers, sin cliente DHCP | F4 (estado vigente) |

`backups/2026-10-17/` es el estado vigente de cada router; sus 7 `.rsc` se copiaron a `configs/` en F5 (§7). Restore probado en F1 sobre ISP-1 (`docs/f1/backup-y-restore.md`).

## 13. Limitaciones y trabajo futuro

Consolidado de `docs/f4/verificacion.md` §"Limitaciones y observaciones" (no se repite contenido ya documentado ahí, solo se resume y se cruza con el resto de las fases):

1. **`snmpwalk` desde SRV no demostrado** — SRV (Alpine) no tiene salida a Internet para instalar `net-snmp-tools`. SNMPv3 queda verificado solo del lado del router. *Trabajo futuro:* darle salida temporal a SRV o llevar el paquete por otro medio (pendrive virtual / imagen con el paquete preinstalado).
2. **Prepend de BGP: 2 repeticiones de AS 65000 en vez de 3 — punto abierto.** Se configuró `bgp-path-prepend 2` esperando 3 repeticiones totales (el prepend más el AS propio que agrega eBGP) y se vieron 2 (`runbooks/drill-3-bgp.md`, observación 1; `docs/f4/verificacion.md`, nota ⁴). El efecto buscado (camino más largo por ISP-2) se cumple igual. No se investigó la causa; es candidato a revisar cómo RouterOS 7 cuenta el prepend del filtro de salida frente al AS que agrega automáticamente la sesión eBGP.
3. **Sin NTP.** Los 7 CHR no tienen sincronización horaria: cada reloj es propio y las horas absolutas entre routers no son comparables (`docs/f4/ejecucion.md`). Las duraciones medidas en los drills sí son confiables porque usan contadores locales (uptime, paquetes por segundo), no las horas de pared. *Trabajo futuro:* NTP interno (el propio EDGE como servidor, o un cliente hacia un NTP público si hubiera salida real a Internet).
4. **DHCP client de F1, corregido en F4.** La devolución de F1 (93/100) pidió remover `/ip dhcp-client add interface=ether1` de los 7 routers por superficie de ataque; se hizo en la sesión 0 de F4 (`docs/f1/correccion-dhcp-client.md`). Cerrado, sin trabajo pendiente.
5. **GNS3: Suspend/Resume de un enlace deja el cable "muerto".** Se solucionó borrando y recreando el cable (`docs/f4/verificacion.md`, limitación 2; `runbooks/drill-2-ospf.md`). *Recomendación para futuros drills:* usar Stop/Start del nodo o deshabilitar la interfaz en vez de Suspend/Resume del enlace.
6. **netwatch solo vigila ISP-1.** No hay entrada equivalente para ISP-2. *Trabajo futuro:* duplicar la entrada de netwatch para ISP-2 (`192.0.2.5`).
7. **No se probó la caída de un enlace físico real de un proveedor**, solo el Stop del nodo (sin aviso ni caída de portadora): es el caso difícil y por eso los tiempos de BGP medidos son el peor caso, no el típico de un enlace con detección de portadora.
8. **Sin un sistema de monitoreo centralizado** (Zabbix, LibreNMS, Prometheus): fuera de alcance de F4; el monitoreo actual se apoya en SNMP + netwatch + syslog, todos puntuales.
9. **Alertas solo para el proveedor; VRRP, OSPF y BGP se verifican a mano** durante los drills, sin netwatch ni scripts dedicados.
10. **Fuera del alcance general del lab** (documentado desde F0): VLAN de gestión/native VLAN hardening, QoS, STP root designado, DHCP snooping/DAI/port-security en los switches de acceso.

## 14. Checklist de entrega (F5)

- [x] `docs/memoria.md` creado y consolidado (este documento).
- [x] `docs/defensa.md` con material de defensa por rol.
- [x] `docs/f5/observaciones.md` con las inconsistencias detectadas entre fases (sin modificar los documentos originales de F0-F4).
- [x] `configs/` completo con los 7 `.rsc` finales (copiados de `backups/2026-10-17/`, sin inventar contenido) + los `.interfaces` de los hosts.
- [x] `README.md` actualizado: estado de F5, índice de F5, links corregidos.
- [x] `backlog.md` revisado y cerrado según evidencia real (ver detalle de qué quedó `[~]`/`[ ]` en el propio archivo).
- [ ] **Pendiente de cada rol (R1-R4):** confirmar su `.rsc` en `configs/` y completar/revisar su sección propia en `docs/defensa.md`.
- [ ] **Pendiente de todos los roles:** preparar el resumen de 1 minuto de la parte propia y estudiar la parte cruzada asignada (ver `docs/defensa.md`).
- [ ] **Pendiente de R5 (o quien suba):** ejecutar `grep -rn` final sobre `*.md` y `*.rsc` buscando claves reales antes de cualquier commit (ver `../guia-commits-f5.md`), y commitear siguiendo esa guía — nunca `git add .`.
