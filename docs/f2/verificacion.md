# F2 — Verificación de VRRP, OSPF y conectividad L3 (R5)

**Fecha:** 2026-10-13 · Evidencia: `capturas/f2/` · Configuración: `backups/2026-10-13/`.

## Método: sesiones de a 2 routers

La VM de GNS3 se inestabiliza con varios routers encendidos, así que F2 se ejecutó en **8 sesiones con un máximo de 2 routers encendidos**. La configuración de RouterOS persiste en cada nodo, así que cada router se configuró una vez y luego se encendió de a pares solo para verificar vecinos.

| Sesión | Encendidos | Qué se hizo |
|:------:|------------|-------------|
| 1 | DIST-1 + DIST-2 (+ switches, PC-USER, SRV) | VRRP, OSPF (config) y pruebas L3 de los hosts |
| 2 | CORE-1 + CORE-2 | OSPF (config) y adyacencia core–core |
| 3 | CORE-1 + EDGE | OSPF (config) en EDGE y adyacencia EDGE–CORE-1 |
| 4 | CORE-1 + DIST-1 | Adyacencia, rutas y ping |
| 5 | CORE-1 + DIST-2 | Adyacencia, rutas y ping; export de CORE-1 |
| 6 | CORE-2 + EDGE | Adyacencia, rutas y ping; export de EDGE |
| 7 | CORE-2 + DIST-1 | Adyacencia, rutas y ping; export de DIST-1 |
| 8 | CORE-2 + DIST-2 | Adyacencia, rutas y ping; exports de CORE-2 y DIST-2 |

## 1. VRRP: master y backup

`/interface vrrp print` (captura `f2-01-vrrp-dist1-dist2.png`):

| Router | `vrrp10` (VRID 10, USERS) | `vrrp20` (VRID 20, SERVERS) |
|--------|---------------------------|------------------------------|
| DIST-1 | `RM` master, prio 150 | `B` backup, prio 100 |
| DIST-2 | `B` backup, prio 100 | `RM` master, prio 150 |

Resultado esperado y obtenido: cada DIST es master de un grupo y backup del otro (load-sharing).

## 2. Conectividad L3 desde los hosts (sesión 1)

| Origen | Destino | Resultado | TTL | Captura |
|--------|---------|-----------|:---:|---------|
| PC-USER | 192.168.10.1 (VIP USERS) | 3/3, 0 % pérdida | 64 | `f2-03a` |
| PC-USER | 192.168.20.100 (SRV) | 3/3, 0 % pérdida | 63 | `f2-03a` |
| SRV | 192.168.20.1 (VIP SERVERS) | 3/3, 0 % pérdida | 64 | `f2-03b` |
| SRV | 192.168.10.100 (PC-USER) | 3/3, 0 % pérdida | 63 | `f2-03b` |

TTL 64 = destino en el mismo segmento (el router que responde por la VIP); TTL 63 = un salto de ruteo entre las dos LANs. Con solo los dos DIST encendidos, PC-USER ↔ SRV rutea entre ambas LANs.

## 3. Adyacencias OSPF (las 7 del diseño)

Todas en estado `Full`, con MD5 (`auth-id=1`):

| Sesión | Par | Interfaz (RouterOS) | Capturas |
|:------:|-----|---------------------|----------|
| 2 | CORE-1 ↔ CORE-2 | ether2 (ambos) | `f2-04a`, `f2-04b` |
| 3 | EDGE ↔ CORE-1 | EDGE ether3 / CORE-1 ether1 | `f2-05a`, `f2-05c` |
| 4 | CORE-1 ↔ DIST-1 | CORE-1 ether3 / DIST-1 ether1 | `f2-06a`, `f2-06b` |
| 5 | CORE-1 ↔ DIST-2 | CORE-1 ether4 / DIST-2 ether2 | `f2-07a`, `f2-07b` |
| 6 | EDGE ↔ CORE-2 | EDGE ether4 / CORE-2 ether1 | `f2-08a`, `f2-08b` |
| 7 | CORE-2 ↔ DIST-1 | CORE-2 ether3 / DIST-1 ether2 | `f2-09a`, `f2-09b` |
| 8 | CORE-2 ↔ DIST-2 | CORE-2 ether4 / DIST-2 ether3 | `f2-10a`, `f2-10b` |

## 4. Rutas OSPF aprendidas (`/ip route print where ospf`)

| Sesión | Router | Rutas aprendidas | Gateway |
|:------:|--------|------------------|---------|
| 2 | CORE-1 | 10.0.0.4/30, 10.0.0.20/30, 10.0.0.24/30, 10.255.0.12/32 | 10.0.0.10%ether2 |
| 2 | CORE-2 | 10.0.0.0/30, 10.0.0.12/30, 10.0.0.16/30, 10.255.0.11/32 | 10.0.0.9%ether2 |
| 3 | EDGE | 10.0.0.8/30, 10.0.0.12/30, 10.0.0.16/30, 10.255.0.11/32 | 10.0.0.2%ether3 |
| 3 | CORE-1 | 10.0.0.4/30, 10.255.0.1/32 | 10.0.0.1%ether1 |
| 4 | CORE-1 | 10.0.0.20/30, 10.255.0.21/32, 192.168.10.0/24, 192.168.20.0/24 | 10.0.0.14%ether3 |
| 4 | DIST-1 | 10.0.0.0/30, 10.0.0.8/30, 10.0.0.16/30, 10.255.0.11/32 | 10.0.0.13%ether1 |
| 5 | CORE-1 | 10.0.0.24/30, 10.255.0.22/32, 192.168.10.0/24, 192.168.20.0/24 | 10.0.0.18%ether4 |
| 5 | DIST-2 | 10.0.0.0/30, 10.0.0.8/30, 10.0.0.12/30, 10.255.0.11/32 | 10.0.0.17%ether2 |
| 6 | EDGE | 10.0.0.8/30, 10.0.0.20/30, 10.0.0.24/30, 10.255.0.12/32 | 10.0.0.6%ether4 |
| 6 | CORE-2 | 10.0.0.0/30, 10.255.0.1/32 | 10.0.0.5%ether1 |
| 7 | CORE-2 | 10.0.0.12/30, 10.255.0.21/32, 192.168.10.0/24, 192.168.20.0/24 | 10.0.0.22%ether3 |
| 7 | DIST-1 | 10.0.0.4/30, 10.0.0.8/30, 10.0.0.24/30, 10.255.0.12/32 | 10.0.0.21%ether2 |
| 8 | CORE-2 | 10.0.0.16/30, 10.255.0.22/32, 192.168.10.0/24, 192.168.20.0/24 | 10.0.0.26%ether4 |
| 8 | DIST-2 | 10.0.0.4/30, 10.0.0.8/30, 10.0.0.20/30, 10.255.0.12/32 | 10.0.0.25%ether3 |

Las LANs de acceso (192.168.10.0/24 y 192.168.20.0/24) llegan a los cores desde los DIST (anuncio pasivo), y las loopbacks se aprenden en todos los pares.

## 5. Ping entre loopbacks (sesiones 4 a 8)

Todos 2/2 respondidos, TTL 64:

| Sesión | Origen → destino | Captura |
|:------:|------------------|---------|
| 4 | CORE-1 → 10.255.0.21 (DIST-1) | `f2-06c` |
| 4 | DIST-1 → 10.255.0.11 (CORE-1) | `f2-06d` |
| 5 | CORE-1 → 10.255.0.22 (DIST-2) | `f2-07c` |
| 5 | DIST-2 → 10.255.0.11 (CORE-1) | `f2-07d` |
| 6 | EDGE → 10.255.0.12 (CORE-2) | `f2-08c` |
| 6 | CORE-2 → 10.255.0.1 (EDGE) | `f2-08d` |
| 7 | CORE-2 → 10.255.0.21 (DIST-1) | `f2-09c` |
| 7 | DIST-1 → 10.255.0.12 (CORE-2) | `f2-09d` |
| 8 | CORE-2 → 10.255.0.22 (DIST-2) | `f2-10c` |
| 8 | DIST-2 → 10.255.0.12 (CORE-2) | `f2-10d` |

En las sesiones 2 y 3 no se capturó el ping entre loopbacks: las rutas OSPF aprendidas de esas sesiones ya prueban el camino.

## 6. Observaciones y limitaciones

1. **Sin topología completa a la vez.** Nunca hubo más de 2 routers encendidos, así que cada tabla de rutas es parcial (solo el par) y no se observaron caminos alternativos simultáneos por ambos cores. La convergencia ante fallas se mide en los drills de F4.
2. **VRRP, estado transitorio.** Una captura tomada segundos después de crear los grupos mostraba ambos DIST como backup en `vrrp20`; es el retardo normal de ~3 s. La captura del repo es la posterior, ya estabilizada.
3. **`monitor` en CORE-1.** Quedaba un usuario sobrante `moonitor` de F1; se eliminó (`f2-04e-core1-user-print.png`: solo `admin` y `monitor`). Ver `docs/f1/hardening-checklist.md`.
4. **Las claves no se ocultan solas en el export.** Ver `docs/f2/claves-y-secretos.md`.
5. **EDGE trae renombres de interfaz nuevos respecto de F1** y los enlaces a los ISP no se probaron en F2. Verificar antes de BGP en F3 (detalle en `docs/f2/ospf-edge.md`).
6. **Sin cambios en ISP-1 e ISP-2:** no participan de F2, así que su backup vigente sigue siendo `backups/2026-10-09/`.
