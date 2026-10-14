# F2 — OSPF área 0 con MD5: diseño aplicado y core (R3)

**Fecha:** 2026-10-13 · Evidencia: `capturas/f2/` · Configuraciones: `backups/2026-10-13/*.rsc`.

## Diseño aplicado (los 5 routers OSPF)

| Parámetro | Valor |
|-----------|-------|
| Instancia | `ospf-lab`, OSPFv2 |
| Área | `backbone` (0.0.0.0): una sola área, todos los routers |
| Autenticación | MD5, `auth-id=1`, la misma clave en todas las interfaces con vecinos (clave real fuera del repo: `docs/f2/claves-y-secretos.md`) |
| Tipo de red | `ptp` en todos los enlaces /30 entre routers |
| Pasivas (`passive`) | loopbacks y LANs de acceso: se anuncian pero no forman vecinos |
| Timers y costo | valores por defecto de RouterOS 7.14.3: hello 10 s, dead 40 s, costo 1 |
| Router-IDs | EDGE 3.3.3.3 · CORE-1 4.4.4.4 · CORE-2 5.5.5.5 · DIST-1 6.6.6.6 · DIST-2 7.7.7.7 |

Fuera de OSPF quedan los enlaces a los ISP (192.0.2.0/30 y 192.0.2.4/30): irán por BGP en F3.

## Core: CORE-1 y CORE-2

| Router | Interfaz (RouterOS) | Vecino | Template |
|--------|:-------------------:|--------|----------|
| CORE-1 (4.4.4.4) | ether1 | EDGE | `ptp`, md5 |
| | ether2 | CORE-2 (core–core) | `ptp`, md5 |
| | ether3 | DIST-1 | `ptp`, md5 |
| | ether4 | DIST-2 | `ptp`, md5 |
| | lo | — | pasiva |
| CORE-2 (5.5.5.5) | ether1 | EDGE | `ptp`, md5 |
| | ether2 | CORE-1 (core–core) | `ptp`, md5 |
| | ether3 | DIST-1 | `ptp`, md5 |
| | ether4 | DIST-2 | `ptp`, md5 |
| | lo | — | pasiva |

Comandos aplicados en cada core (cambia solo el `router-id`):

```routeros
/routing ospf instance add name=ospf-lab version=2 router-id=<4.4.4.4 | 5.5.5.5>
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-lab
/routing ospf interface-template add area=backbone interfaces=ether1 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether2 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether3 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether4 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=lo passive
```

## Enlace core–core (defecto 3 de F0)

Sesión 2 (solo CORE-1 y CORE-2 encendidos): adyacencia `Full` entre `4.4.4.4` y `5.5.5.5` por `ether2` (10.0.0.9 ↔ 10.0.0.10), con MD5.

- CORE-1 aprendió `10.0.0.4/30`, `10.0.0.20/30`, `10.0.0.24/30` y `10.255.0.12/32` vía `10.0.0.10%ether2`.
- CORE-2 aprendió `10.0.0.0/30`, `10.0.0.12/30`, `10.0.0.16/30` y `10.255.0.11/32` vía `10.0.0.9%ether2`.

Capturas: `f2-04a`, `f2-04b`, `f2-04c`, `f2-04d`.

## Adyacencias de los cores con el resto

Verificadas por pares (ver `docs/f2/verificacion.md`): CORE-1–EDGE (s3), CORE-1–DIST-1 (s4), CORE-1–DIST-2 (s5), CORE-2–EDGE (s6), CORE-2–DIST-1 (s7), CORE-2–DIST-2 (s8). Las 7 adyacencias del diseño quedaron en `Full` con MD5.

## Limitaciones

- Nunca estuvieron los 5 routers a la vez (límite de recursos de la VM), así que no se observó la tabla de rutas completa con caminos alternativos por ambos cores. Eso se prueba en el drill 2 (OSPF) de F4.
- La prueba de "clave incorrecta → adyacencia falla" es de F4.
