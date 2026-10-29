# F4 — Registro de cambios (R5)

Formato de `docs/f0/operacion.md` §5.1. Cada fila corresponde a uno o más commits de la fase. Las sesiones 0 y 1 son del 16/10 (según el reloj del router) y las sesiones 2 a 5 del 17/10.

## Cambios permanentes (quedan en la configuración final)

| Sesión | Responsable (rol) | Cambio | Motivo | Cómo se revierte |
|:------:|:-----------------:|--------|--------|------------------|
| 0 | R1 | Quitar `/ip dhcp-client` de los 7 routers | Devolución de F1: superficie de ataque (`docs/f1/correccion-dhcp-client.md`) | `/ip dhcp-client add interface=ether1` (no recomendado) |
| 2 a 5 | R2 | SNMPv3 `authPriv` (SHA1/AES) con comunidad `monitor`, limitado a `10.0.0.0/8` y `192.168.0.0/16`, en los 7 routers | Monitoreo con usuario de solo lectura | `/snmp community remove [find name=monitor]` y `/snmp set enabled=no` |
| 2 a 5 | R2 | Comunidad `public` neutralizada (`addresses=127.0.0.1/32`, `read-access=no`) | RouterOS 7 no permite borrarla | `/snmp community set [find default=yes] addresses=::/0 read-access=yes` (no recomendado) |
| 2 a 5 | R2 | `engine-id-suffix` único por router (`d1`, `d2`, `c1`, `c2`, `a1`, `a2`, `e0`) | SNMPv3 necesita un engine-id distinto por equipo; CORE-2 había quedado con el de CORE-1 y se corrigió | `/snmp set engine-id-suffix=""` |
| 3 | R2 | `203.0.113.1/32` en la loopback de ISP-1 e ISP-2 ("Internet simulada") | Destino común para medir el failover de proveedor | `/ip address remove [find comment="Internet simulada"]` |
| 4 | R1 | Regla `in-snmp-lan` (UDP/161 desde la lista `LAN`) antes de `in-drop-resto` en EDGE | Pendiente de F3: abrir SNMP solo hacia adentro | `/ip firewall filter remove [find comment=in-snmp-lan]` |
| 4 | R1 | `connect=yes` explícito en la conexión `to-ISP1` | Quedó así tras la prueba de conexión iniciada por el ISP (es el valor por defecto) | No aplica |
| 4 | R5 | Netwatch `isp1` en EDGE: sondea `192.0.2.1` cada 10 s, con aviso `ALERTA` al caer y `recuperado` al volver | Monitoreo del proveedor principal | `/tool netwatch remove [find name=isp1]` |
| 5 | R5 | Acción de log `srvsyslog` hacia SRV (`192.168.20.100`) y una regla de logging para el tópico `script` | Que las alertas de netwatch lleguen a SRV | `/system logging remove [find action=srvsyslog]` y `/system logging action remove [find name=srvsyslog]` |

## Cambios temporales (se revirtieron)

| Sesión | Qué | Cómo quedó |
|:------:|-----|------------|
| 1 | Clave VRRP incorrecta en DIST-2 (`vrrp10`) | Restaurada (`f4-01l1`, `f4-01l2`) |
| 2 | Clave OSPF incorrecta en CORE-2 `ether2` | Restaurada; adyacencia `Full` tras 1 min 28 s (`f4-02l`) |
| 2 | Corte del enlace DIST-1 ↔ CORE-1 (Suspend en GNS3) | Cable recreado (`f4-02f`) |
| 3 | Rutas estáticas `d4-isp1` y `d4-isp2` con `check-gateway=ping` en EDGE | Eliminadas (`f4-03n`) |
| 4 | Clave BGP incorrecta en `to-ISP1` | Restaurada (`f4-04c`) |
| 4 | `connect=no` en `to-ISP1` y regla `in-bgp-isp1` deshabilitada | Vueltos a `connect=yes` y regla habilitada (`f4-04f`, `f4-04g`) |
| 4 | `originate-default=if-installed` en la instancia OSPF de EDGE | Vuelta a `always` (`f4-04n`) |
| 5 | Regla de logging duplicada en EDGE (`action=srvsyslog topics=script`, filas 4 y 5) | Se borró la repetida (`f4-05h2`); la prueba posterior muestra una sola línea (`f4-05h3`) |

## Capturas que no se suben

Quedaron en el PDF de trabajo pero **no están en el repo** porque una versión posterior las reemplaza o salieron vacías:

| No se sube | Motivo | Reemplazo |
|------------|--------|-----------|
| `f4-01m`, `f4-01n`, `f4-01o` | `snmp print` de DIST-1 (estado previo, sin `engine-id-suffix`) y exports de DIST-1 y DIST-2 de la sesión 1, anteriores al estado final | `f4-02s1`, `f4-02u1a/b`, `f4-05b`, `f4-05k`, `f4-05l` |
| `f4-02m`, `f4-02n`, `f4-02o` | `snmp print` con la comunidad `public` activa y engine-id repetido en CORE-2 | `f4-02s1 … f4-02s3`, `f4-02t` |
| `f4-02pa`, `f4-02pb`, `f4-02qa`, `f4-02qb`, `f4-02r` | Exports de la sesión 2 antes de la corrección de SNMP | `f4-02u1a/b`, `f4-02u2a/b`, `f4-02u3` |
| `f4-03e`, `f4-03f` | Prepend con CORE y DIST apagados (EDGE sin LANs que anunciar): salieron vacías | `f4-03e2`, `f4-03f2` |
| `f4-04h` | Reglas de firewall antes de agregar `in-snmp-lan` | `f4-04h2` |
| `f4-05h` | Regla de logging duplicada | `f4-05h2`, `f4-05h3` |

## Notas

- Los `.rsc` de `backups/2026-10-17/` llevan `<OSPF-KEY>`, `<VRRP-KEY>`, `<BGP-KEY-ISP1>`, `<BGP-KEY-ISP2>`, `<SNMP-AUTH-KEY>` y `<SNMP-PRIV-KEY>` en lugar de las claves reales.
- Los `.backup` binarios (`f4-s0-pre` en cada router) quedan en el equipo y **no** se suben al repo.
- Cinco capturas de exports (`f4-02u1b`, `f4-02u2b`, `f4-02u3`, `f4-05j`, `f4-05l`) tienen la clave OSPF tapada: el export no oculta `auth-key`.
- El backlog originalmente asignaba los cinco runbooks a R5; en este paquete cada drill lo documenta el rol de su capa (R4 drills 1 y 5, R3 drill 2, R1 drills 3 y 4), con R5 en verificación, cambios y monitoreo.
