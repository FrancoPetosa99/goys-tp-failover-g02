# F4 — Clave BGP (TCP-MD5) incorrecta y reglas `in-bgp-*` (R1)

**Ejecutado:** 2026-10-17 (sesión 4) · Evidencia: `capturas/f4/f4-04a … f4-04g` · Política: `docs/f3/claves-bgp.md`. Las claves reales (`<BGP-KEY-ISP1>`, `<BGP-KEY-ISP2>`) no están en este documento ni en las capturas.

Nodos encendidos: **EDGE e ISP-1** (ISP-2 apagado).

## Parte A: clave TCP-MD5 incorrecta

### Prueba

1. **[EDGE]** línea base: sesión `to-ISP1` en `E` y default por `192.0.2.1` (`f4-04a`).
2. **[EDGE]** se cambió el `tcp-md5-key` de `to-ISP1` por un valor incorrecto (`/routing bgp connection set to-ISP1 tcp-md5-key=<CLAVE-INCORRECTA>`; no se captura, lleva la clave).
3. **[EDGE]** `/routing bgp session print`, `/ip route print where dst-address=0.0.0.0/0` y `/system clock print` (`f4-04b`).
4. **[EDGE]** se restauró la clave real (comando no capturado) y se verificó la sesión (`f4-04c`).

### Resultado

| Hecho | Evidencia |
|-------|-----------|
| La sesión cae **al cambiar la clave** (`last-stopped=23:00:09`, reloj del router) y **no vuelve** mientras no coincidan: a las 23:03:14 sigue caída, `prefix-count=0` y no hay ningún default por BGP | `f4-04b` |
| Con la clave restaurada, la sesión se reestablece (`last-started=23:04:18`; `uptime=43s` en la captura) y el default vuelve | `f4-04c` |

Horas anotadas a mano por R2 (hora de Argentina): comando a las 19:35, sesión caída verificada a las 19:38, BGP restaurado a las 19:40. Las diferencias con el reloj del router se explican en `docs/f4/ejecucion.md`.

### Qué significa

- **TCP-MD5 cumple su función:** un extremo con la clave equivocada no logra levantar la sesión, así que un router ajeno no puede inyectar rutas.
- **El corte es total mientras dura la discrepancia:** como en la sesión 4 ISP-2 estaba apagado, EDGE se quedó **sin default**. Con los dos proveedores encendidos el respaldo (ISP-2) habría tomado el tráfico, pero un error de clave en un proveedor igual deja de usarlo.
- **No se capturó ningún log de BGP.** El kernel descarta los segmentos TCP con firma MD5 inválida antes de que BGP los vea, por lo que no se esperan mensajes de autenticación como los de OSPF o VRRP; es una diferencia práctica a tener en cuenta al diagnosticar.

## Parte B: la regla `in-bgp-isp1` y las conexiones iniciadas por el ISP

Pendiente de F3 (limitación 3 de `docs/f3/verificacion.md`): hasta ahora EDGE iniciaba la sesión y el retorno entraba por `in-estab`, así que las reglas `in-bgp-*` nunca contaron paquetes.

### Prueba

1. **[EDGE]** se obligó a que solo ISP-1 inicie la sesión: `/routing bgp connection set to-ISP1 connect=no` (con `disable`/`enable` de la conexión). La sesión se reestableció y **`in-bgp-isp1` contó 106 paquetes / 7 632 bytes**: es el tráfico entrante al puerto 179 desde `192.0.2.1` (`f4-04d`).
2. **[EDGE]** se deshabilitó la regla (`/ip firewall filter disable [find comment=in-bgp-isp1]`), se limpiaron las conexiones al puerto 179 (`/ip firewall connection remove [find dst-address~":179"]`) y se reinició la conexión. La sesión **no vuelve**, el contador de `in-bgp-isp1` queda congelado en 106 y **`in-drop-resto` sube a 68 paquetes / 4 903 bytes** (`f4-04e`).
3. **[EDGE]** se habilitó otra vez la regla: la sesión se reestablece cuando el ISP reintenta (`f4-04f`).
4. **[EDGE]** se volvió a `connect=yes` (valor del proyecto) y se verificó la sesión (`f4-04g`).

### Resultado

La regla `in-bgp-isp1` es **necesaria y suficiente** para que un ISP inicie la sesión: sin ella el SYN del ISP cae en `in-drop-resto`; con ella, la sesión se establece. Queda demostrado además que el firewall de F3 no deja pasar BGP desde otras direcciones (la regla está atada a `src-address=192.0.2.1` y a la interfaz `ether1`).

## Reversión

`connect=yes` restablecido, regla `in-bgp-isp1` habilitada y sesión en `E` (`f4-04g`). En el export final, `to-ISP1` figura con `connect=yes` explícito (es el valor por defecto).
