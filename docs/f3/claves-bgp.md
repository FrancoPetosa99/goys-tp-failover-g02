# F3 — Claves BGP y estado de los secretos (R2)

Política de F0: `docs/f0/proveedores-claves.md`. Continuación de `docs/f2/claves-y-secretos.md`. **Ninguna clave real está en el repo.**

## Mecanismos activos al cierre de F3

| Mecanismo | Dónde | Detalle | Clave en el repo |
|-----------|-------|---------|------------------|
| OSPF MD5 | EDGE, CORE-1, CORE-2, DIST-1, DIST-2 | `auth=md5`, `auth-id=1`, misma clave en toda el área | `<OSPF-KEY>` |
| VRRP auth simple | DIST-1 y DIST-2, grupos 10 y 20 | VRRP v2, `authentication=simple` | `<VRRP-KEY>` |
| BGP TCP-MD5 | EDGE ↔ ISP-1 | `tcp-md5-key` en ambos extremos | `<BGP-KEY-ISP1>` |
| BGP TCP-MD5 | EDGE ↔ ISP-2 | `tcp-md5-key` en ambos extremos | `<BGP-KEY-ISP2>` |

Las dos claves BGP son distintas entre sí, de 6 caracteres cada una. Se comparten por el canal privado del grupo.

## Hallazgos de F3

1. **`/export hide-sensitive` sí oculta `tcp-md5-key`, a diferencia de `auth-key` de OSPF.** En los exports de EDGE, ISP-1 e ISP-2 la línea de `/routing bgp connection add` termina en `router-id=…` y no trae `tcp-md5-key=` (se ve en el tramo final de la línea de EDGE en `f3-07i2`), aunque la clave está configurada. En cambio `auth-key` de OSPF sigue apareciendo en claro en el export de EDGE.
   - Consecuencia: la captura `f3-07i2` se subió con la clave OSPF tapada, y los `.rsc` llevan `<OSPF-KEY>`, `<BGP-KEY-ISP1>` y `<BGP-KEY-ISP2>`.
   - Consecuencia para un restore: el `.rsc` no reproduce el MD5 de BGP por sí solo; hay que volver a cargar `tcp-md5-key` en cada sesión (anotado en el encabezado de cada `.rsc`).
2. **Ningún comando con clave se capturó.** Los comandos de las sesiones 1 y 2 llevan la clave en texto plano; la evidencia son solo salidas de `session print`, `ping` y rutas. Tampoco se usó `/routing bgp connection print` en las capturas.
3. **Lo que no está probado todavía:** que una clave distinta en uno de los extremos impida levantar la sesión. TCP-MD5 está configurado en ambos extremos (comandos de las sesiones 1 y 2) pero la prueba negativa es de F4.

## Desvío respecto de F0

Igual que en F2: la política de F0 dice "no usar claves triviales" y el grupo eligió claves cortas y fáciles de recordar para el laboratorio. Se acepta como desvío porque las claves no se publican; en producción serían largas, aleatorias y rotadas.

## Pendiente (F4)

- Probar clave incorrecta en OSPF (R3), BGP (R1) y VRRP (R4) y documentar que falla.
