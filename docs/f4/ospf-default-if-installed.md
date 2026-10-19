# F4 — `originate-default`: `always` vs `if-installed` (R3)

**Ejecutado:** 2026-10-17 (sesión 4) · Evidencia: `capturas/f4/f4-04k`, `f4-04m`, `f4-04n` · Diseño de base: `docs/f3/ospf-default-y-core.md`.

## Objetivo

En F3 no se pudo probar `originate-default=if-installed` (con dos routers no hay manera de que EDGE pierda su default). Con ISP-1 apagado en la sesión 4 sí: se compara cuándo EDGE anuncia el default por OSPF según cada opción.

## Prueba (EDGE + ISP-1 encendidos)

1. **[EDGE]** `/routing ospf instance set ospf-lab originate-default=if-installed`.
2. **[EDGE]** `/routing ospf lsa print where id=0.0.0.0`: el LSA externo del default (`type=external`, `originator=3.3.3.3`, `metric=1`) está presente porque EDGE tiene un default activo por BGP (`f4-04k`).
3. **[GNS3]** se apaga ISP-1. Al vencer el *hold timer* de BGP (3 min) desaparece el default de EDGE.
4. **[EDGE]** `/ip route print where dst-address=0.0.0.0/0` sale vacío y `/routing ospf lsa print where id=0.0.0.0` también: **el LSA fue retirado** (`f4-04m`).
5. **[EDGE]** `/routing ospf instance set ospf-lab originate-default=always` (configuración del proyecto).
6. **[EDGE]** el LSA `0.0.0.0` reaparece de inmediato (`sequence=0x80000001`, `age=0`) **aunque EDGE no tenga default propio** (`f4-04n`).

## Resultado

| Configuración | EDGE con default por BGP | EDGE **sin** default |
|---------------|:------------------------:|:--------------------:|
| `if-installed` | anuncia el default | **retira** el default de OSPF |
| `always` | anuncia el default | **sigue anunciándolo** |

## Qué significa (decisión de diseño)

- Con **`if-installed`**, si EDGE pierde sus dos ISP, el core deja de recibir el default y el tráfico a Internet se descarta *en el origen* (no atraviesa el core para morir en EDGE). Es más honesto con el estado real de la red, pero el core queda sin default hasta que vuelva un proveedor.
- Con **`always`** (lo que usa el proyecto), el core sigue mandando el tráfico hacia EDGE aunque no haya salida: EDGE lo descarta. Tiene la ventaja de que el default no "parpadea" en el core cuando BGP se reestabiliza, y en este diseño con **dos** ISP es poco probable perder los dos a la vez.
- **Decisión:** se mantiene `always` y se deja documentado que `if-installed` funciona y cuándo convendría usarlo (si hubiera caminos alternativos de salida por otro router de borde).

## Reversión

La instancia quedó otra vez con `originate-default=always` (`f4-04n` y export final de EDGE en `backups/2026-10-17/EDGE.rsc`).
