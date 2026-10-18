# Runbook — Drill 4: `check-gateway` sobre rutas estáticas (R1)

**Ejecutado:** 2026-10-17 (sesión 3 de F4) · Evidencia: `capturas/f4/f4-03k … f4-03n` · Relacionado: `runbooks/drill-3-bgp.md`.

## Objetivo

Comparar la detección de falla del proveedor por BGP (drill 3, ≈ 160 s) con la de un default estático con `check-gateway=ping`, que sondea el gateway cada pocos segundos.

## Diseño bajo prueba (temporal)

Rutas estáticas de prueba en EDGE, que se **eliminan al terminar** (en producción el default viene de BGP):

| Comentario | Destino | Gateway | Distancia | `check-gateway` |
|------------|---------|---------|:---------:|:---------------:|
| `d4-isp1` | `0.0.0.0/0` | `192.0.2.1` (ISP-1) | 1 | `ping` |
| `d4-isp2` | `0.0.0.0/0` | `192.0.2.5` (ISP-2) | 2 | `ping` |

Distancia 1 y 2 (las de BGP son 20) para que las estáticas ganen durante la prueba y el resultado mida solo `check-gateway`.

## Pasos

1. **[EDGE]** con ISP-1 e ISP-2 arriba:
   ```routeros
   /ip route add dst-address=0.0.0.0/0 gateway=192.0.2.1 distance=1 check-gateway=ping comment=d4-isp1
   /ip route add dst-address=0.0.0.0/0 gateway=192.0.2.5 distance=2 check-gateway=ping comment=d4-isp2
   /ip route print where comment~"d4-"
   ```
   `d4-isp1` activa (`As`) y `d4-isp2` en espera (`f4-03k`).
2. **[EDGE]** `/ping 203.0.113.1 interval=1 count=120`.
3. **[GNS3]** a los ~10 s, **Stop** sobre el nodo ISP-1.
4. **[EDGE]** al terminar el ping (`f4-03l`): `/ip route print where comment~"d4-"`. `d4-isp1` pasó a inactiva y `d4-isp2` a activa (`f4-03m`).
5. **Reversión.** **[GNS3]** Start sobre ISP-1; **[EDGE]**:
   ```routeros
   /ip route remove [find comment~"d4-"]
   /ip route print where dst-address=0.0.0.0/0
   ```
   Tienen que quedar solo los dos defaults de BGP, `DAb` por `192.0.2.1` y `D b` por `192.0.2.5` (`f4-03n`).

## Resultado observado

| Mecanismo | Enviados / recibidos | Pérdida | Corte estimado |
|-----------|:--------------------:|:-------:|:--------------:|
| BGP solo (drill 3) | 400 / 240 | 40 % | ≈ 160 s |
| `check-gateway=ping` (este drill) | 120 / 97 | 19 % | **≈ 23 s** |

`check-gateway` detectó la falla **unas 7 veces más rápido** que BGP (160 s / 23 s ≈ 7).

## Post-mortem

- **Por qué es más rápido:** `check-gateway=ping` hace un ping al gateway cada 10 s y marca la ruta inactiva tras fallar varios intentos seguidos, sin esperar ningún timer de BGP.
- **Su límite:** solo mira si el *siguiente salto* responde; no ve fallas más allá del ISP (si el proveedor está arriba pero sin salida, el ping a `192.0.2.1` responde y la ruta sigue activa).
- **Cómo se podría combinar:** mantener BGP para el intercambio de rutas y agregar `check-gateway` o un netwatch como detección rápida; en producción, BFD sobre la sesión BGP, si el proveedor lo soporta.
- **Resolución:** ping a 1 por segundo; ±1 s.

## Reversión

Rutas `d4-*` eliminadas y defaults de BGP restablecidos (`f4-03n`). El export final de EDGE (`backups/2026-10-17/EDGE.rsc`) no contiene ninguna ruta estática.
