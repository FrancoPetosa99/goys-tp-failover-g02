# Runbook — Drill 5: load-sharing de VRRP (R4)

**Ejecutado:** 2026-10-16 (sesión 1 de F4; fecha del reloj del router) · Evidencia: `capturas/f4/f4-01a`, `f4-01b`, `f4-01c`, `f4-01d`.

## Objetivo

Comprobar que los dos grupos VRRP reparten la carga: cada router es master de una LAN y backup de la otra, de modo que el tráfico de usuarios sale por DIST-1 y el de servidores por DIST-2.

## Diseño (F2)

| Grupo | LAN | Master | IP real del master |
|-------|-----|--------|--------------------|
| `vrrp10` | USERS `192.168.10.0/24` | DIST-1 | 192.168.10.2 |
| `vrrp20` | SERVERS `192.168.20.0/24` | DIST-2 | 192.168.20.3 |

## Pasos

1. **[DIST-1]** y **[DIST-2]** `/interface vrrp print`. En DIST-1, `vrrp10` en `RM`; en DIST-2, `vrrp20` en `RM` (`f4-01a`, `f4-01b`).
2. **[PC-USER]** `traceroute -n -m 3 198.51.100.1`: el primer salto tiene que ser DIST-1, `192.168.10.2` (`f4-01c`).
3. **[SRV]** `traceroute -n -m 3 198.51.100.1`: el primer salto tiene que ser DIST-2, `192.168.20.3` (`f4-01d`).

## Resultado observado

| Host | Primer salto | Router |
|------|--------------|--------|
| PC-USER | `192.168.10.2` | DIST-1 |
| SRV | `192.168.20.3` | DIST-2 |

Los dos hosts salen por routers distintos en el mismo momento: hay reparto de carga.

## Observaciones

1. **Esta sesión solo tenía encendidos DIST-1, DIST-2 y los hosts**, así que los traceroutes terminan en el primer salto (`!N`, red inalcanzable): DIST-1 no tenía todavía ruta hacia el resto. Alcanza para el objetivo del drill, que es identificar el *primer salto* de cada LAN. La salida hasta `203.0.113.1` pasando por CORE y EDGE está en `docs/f4/internet-simulada.md` (con la red completa).
2. **Reparto por LAN, no por flujo.** Cada host usa siempre el mismo gateway; la carga se reparte entre las dos LANs, no dentro de una. Si una LAN genera casi todo el tráfico, el reparto es desigual.
3. **Si uno de los dos DIST cae**, el otro es master de las dos LANs y absorbe todo el tráfico (es lo que mide el drill 1 para `vrrp10`).

## Reversión

Ninguna: solo lectura.
