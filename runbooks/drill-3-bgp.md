# Runbook — Drill 3: cae el proveedor principal (BGP) (R1)

**Ejecutado:** 2026-10-17 (sesión 3 de F4) · Evidencia: `capturas/f4/f4-03a … f4-03j` · Config: `docs/f3/bgp-edge.md`, `docs/f3/bgp-isp.md`, `docs/f4/internet-simulada.md`.

## Objetivo

Medir cuánto tarda EDGE en pasar de ISP-1 (principal) a ISP-2 (respaldo) cuando ISP-1 deja de responder, usando solo BGP, y qué pasa cuando ISP-1 vuelve.

## Diseño bajo prueba

| | ISP-1 | ISP-2 |
|---|-------|-------|
| AS / vecino | 65001 / `192.0.2.1` | 65002 / `192.0.2.5` |
| `local-pref` en EDGE (entrada) | **200** (principal) | 100 (respaldo) |
| Prepend de salida (EDGE → ISP) | ninguno | **2 veces** el AS 65000 |
| Destino de prueba ("Internet simulada") | `203.0.113.1/32` en la loopback de ambos ISP | ídem |

Nodos encendidos: solo EDGE, ISP-1 e ISP-2. CORE y DIST estaban apagados, así que EDGE no tenía las LANs para anunciar (ver observación 3).

## Pasos

1. **[EDGE]** `/routing bgp session print`, `/ip route print where dst-address=0.0.0.0/0`: dos sesiones `E` y el default activo por `192.0.2.1` (`DAb`), el de `192.0.2.5` como respaldo (`f4-03c`). No se usa `connection print` porque podría mostrar la clave.
2. **[EDGE]** `/ping 203.0.113.1 count=4` (`f4-03d`).
3. **[EDGE]** ping largo, uno por segundo: `/ping 203.0.113.1 interval=1 count=400`.
4. **[GNS3]** a los ~10 s, **Stop** sobre el nodo **ISP-1** (no el cable: GNS3 no baja la portadora, y es el caso difícil: la caída solo se detecta por el *hold timer*).
5. **[EDGE]** al terminar el ping (`f4-03g`): estado final, ISP-1 caída y default por `192.0.2.5` (`f4-03h`).
6. **Failback.** **[EDGE]** `/ping 203.0.113.1 interval=1 count=240` y, enseguida, **[GNS3]** Start sobre ISP-1. Resultado en `f4-03i`; estado en `f4-03j`.

## Resultado observado

| Medición | Valor |
|----------|-------|
| Failover: enviados / recibidos | 400 / 240, **40 % de pérdida** |
| **Corte** (160 paquetes × 1 s) | **≈ 160 s** (2 min 40 s) |
| Tope teórico (*hold time* de BGP = 3 min) | 180 s |
| Failback: enviados / recibidos | 240 / 240, **0 % de pérdida** |
| Default tras el failback | vuelve a `192.0.2.1` (`local-pref` 200) |

## Post-mortem

- **Qué pasó:** al detenerse ISP-1 no hubo aviso (ni NOTIFICATION ni caída de portadora). EDGE siguió enviando por ISP-1 hasta que expiró el *hold time* (3 min sin keepalive); entonces retiró esa ruta y activó el default de ISP-2. El corte observado (160 s) cae dentro de la ventana de 180 s.
- **El failback es limpio:** mientras ISP-1 estaba caído el tráfico fue por ISP-2; al volver la sesión, el default de ISP-1 (`local-pref` 200) desplaza al de ISP-2 sin perder paquetes, porque ISP-2 sigue válido hasta el último momento.
- **Por qué es lento y cómo se acorta:** los timers de BGP (keepalive 1 min, hold 3 min) están pensados para estabilidad, no para detectar fallas rápido. Opciones para bajarlo: `check-gateway` sobre rutas estáticas (drill 4, ≈ 23 s en este laboratorio), BFD, o timers más cortos con el ISP de acuerdo.
- **Qué no se probó:** la caída del *enlace* con portadora (en un equipo real la sesión caería al instante por detección de link).

## Observaciones

1. **El prepend se verificó con los dos ISP y la red completa encendida**, en una pasada de correcciones: desde ISP-1, `192.168.10.0/24` llega con `as-path="65000"`; desde ISP-2, con `as-path="65000,65000"` (`f4-03f2`, `f4-03e2`). **Esperábamos tres repeticiones** (`bgp-path-prepend 2` más el AS propio que agrega eBGP) y se vieron dos. No investigamos la causa (puede ser cómo RouterOS 7 cuenta el prepend del filtro); el efecto buscado se cumple: el camino por ISP-2 es **más largo** que por ISP-1. Queda como punto abierto para la memoria.
2. **Qué hace el prepend:** hace menos atractivo el camino de vuelta por ISP-2 (más largo), de modo que el tráfico de retorno también prefiera ISP-1.
3. **Durante la sesión 3 solo estaban encendidos EDGE y los ISP:** EDGE no tenía las LANs (OSPF sin CORE/DIST), así que no había nada que anunciar y las capturas del prepend de la sesión salieron vacías (`f4-03e`, `f4-03f`, no se suben). Se repitieron con todos los nodos encendidos (`f4-03e2`, `f4-03f2`).

## Reversión

Ninguna: los ISP quedan encendidos y la sesión con ISP-1 restablecida (`f4-03j`).
