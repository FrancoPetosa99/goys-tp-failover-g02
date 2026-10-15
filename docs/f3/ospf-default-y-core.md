# F3 — Default por OSPF y propagación hacia el core (R3)

**Fecha:** 2026-10-13 (sesiones 3 y 5) y 2026-10-14 (sesión 7), hora de Argentina · Evidencia: `capturas/f3/` · Configuración: `backups/2026-10-14/EDGE.rsc`.

## Qué se configuró

Para que el core y la distribución sepan salir a Internet, EDGE anuncia un default dentro de OSPF:

```routeros
/routing ospf instance set ospf-lab originate-default=always
```

Solo cambia EDGE. CORE-1, CORE-2, DIST-1 y DIST-2 no necesitan cambios: aprenden `0.0.0.0/0` como ruta externa OSPF.

## Desvío: `always` en lugar de `if-installed`

`if-installed` sería lo correcto (el default solo se anuncia mientras EDGE tiene una ruta por BGP), pero no se puede probar con 2 routers encendidos: necesita un ISP arriba para que exista la ruta. Se usó `always`.

Riesgo: si caen las dos sesiones BGP, EDGE sigue anunciando el default y descarta el tráfico en lugar de que el core lo detecte como "sin ruta". Con un solo ISP caído no hay efecto, porque EDGE conserva el otro. Se puede revisar en F4 (drill 3) con los dos ISP disponibles.

## Verificación

| Sesión | Prueba | Resultado | Captura |
|:------:|--------|-----------|---------|
| 3 | Instancia en EDGE | `name="ospf-lab" version=2 router-id=3.3.3.3 originate-default=always` | `f3-03b` |
| 3 | Adyacencia CORE-1 ↔ EDGE | `Full`, 10.0.0.1, router-id 3.3.3.3, adyacencia 3m43s | `f3-03c` |
| 3 | Rutas de CORE-1 | `0.0.0.0/0` por `10.0.0.1%ether1`, `DAo`, distancia 110 | `f3-03d` |
| 3 | CORE-1 → loopback de EDGE | ping 10.255.0.1: 4/4, TTL 64 | `f3-03e` |
| 5 | Adyacencia con el firewall de EDGE activo | EDGE ve a CORE-1 (10.0.0.2, router-id 4.4.4.4) en `Full` | `f3-05a` |
| 7 | Rutas OSPF que ve EDGE | 8 rutas por `10.0.0.2%ether3`: 4 enlaces /30, 2 loopbacks (10.255.0.11/32 y 10.255.0.21/32) y las 2 LANs | `f3-07b` |

Qué prueba cada fila: la adyacencia sigue en `Full` con MD5 y con el firewall activo (la regla `in-ospf` funciona), el default llega al core, y EDGE aprende desde el core las LANs que luego redistribuye a BGP.

## Observaciones

1. **El default llega a DIST-1 pasando por CORE-1.** El traceroute de los hosts (`f3-07f`, `f3-07g`) sale por DIST-1 → CORE-1 → EDGE, así que el default se propagó por todo el camino.
2. **CORE-2 y DIST-2 no participaron en las pruebas de F3.** Estuvieron apagados (límite de la VM). Sus adyacencias OSPF están probadas desde F2; que reciban el default no se observó en F3 y se mira en F4 con los drills de OSPF y de VRRP.
3. **EDGE no tiene ruta propia al default por OSPF**: el default de EDGE es el de BGP (distancia 20), el anunciado por OSPF solo lo ven los demás.
