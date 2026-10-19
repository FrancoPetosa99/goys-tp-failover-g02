# F3 — eBGP en ISP-1 e ISP-2 (R2)

**Fecha:** 2026-10-13 (sesiones 1 y 2) y 2026-10-14 (sesión 7), hora de Argentina · Evidencia: `capturas/f3/` · Configuración: `backups/2026-10-14/ISP-1.rsc` y `ISP-2.rsc`.

## Diseño

Cada proveedor tiene una sesión eBGP con EDGE y le anuncia un default (`default-originate=always`). La "Internet" del laboratorio es la loopback de cada ISP más ese default.

| Router | AS | Router-id | IP del enlace con EDGE | Loopback | Clave TCP-MD5 en el repo |
|--------|:--:|-----------|------------------------|----------|--------------------------|
| ISP-1 | 65001 | 198.51.100.1 | 192.0.2.1 (ether1) | 198.51.100.1 | `<BGP-KEY-ISP1>` |
| ISP-2 | 65002 | 198.51.100.2 | 192.0.2.5 (ether2) | 198.51.100.2 | `<BGP-KEY-ISP2>` |

## Configuración

```routeros
# ISP-1
/routing bgp connection add name=to-EDGE as=65001 router-id=198.51.100.1 local.address=192.0.2.1 local.role=ebgp remote.address=192.0.2.2 remote.as=65000 tcp-md5-key=<BGP-KEY-ISP1> output.default-originate=always

# ISP-2
/routing bgp connection add name=to-EDGE as=65002 router-id=198.51.100.2 local.address=192.0.2.5 local.role=ebgp remote.address=192.0.2.6 remote.as=65000 tcp-md5-key=<BGP-KEY-ISP2> output.default-originate=always
```

Los ISP no tienen filtros: aceptan lo que EDGE les anuncia (la política de salida está en EDGE) y no se interconectan entre sí.

## Verificación

| Sesión | Prueba | Resultado | Captura |
|:------:|--------|-----------|---------|
| 1 | ISP-1 → EDGE | ping 192.0.2.2: 4/4, TTL 64 | `f3-01b` |
| 1 | Sesión en ISP-1 | `E`, AS 65000, id 3.3.3.3, `default-originate=always` | `f3-01d` |
| 2 | ISP-2 → EDGE | ping 192.0.2.6: 4/4, TTL 64 | `f3-02b` |
| 2 | Sesión en ISP-2 | `E`, AS 65000, id 3.3.3.3, `default-originate=always` | `f3-02d` |
| 7 | ISP-1 aprende las LANs | `session print` en `E` (18 min de uptime) y `/ip route print` con `192.168.10.0/24` y `192.168.20.0/24` por 192.0.2.2 (`DAb`, distancia 20); ninguna ruta 10.x | `f3-07d` |
| 7 | Exports finales | ISP-1 e ISP-2 | `f3-07j`, `f3-07k` |

El bloque de redistribución OSPF→BGP visto desde el lado de EDGE está en `docs/f3/bgp-edge.md`. La prueba de que los hosts llegan a la loopback de ISP-1 está en `docs/f3/salida-lans-y-traceroute.md`.

## Observaciones

1. **Los ISP no tienen ruta a nada interno que no se les anuncie.** `ping 10.255.0.1` desde ISP-1 da `no route` (`f3-07e`): el direccionamiento interno no se filtra hacia afuera.
2. **Los ISP no se ven entre sí.** La loopback del proveedor no activo no es alcanzable desde la LAN mientras ISP-1 sea el principal; sí lo es si ISP-1 cae (drill 3 de F4). Es una simplificación del laboratorio y queda registrada como limitación.
3. **`prefix-count` no es confiable.** ISP-1 muestra `prefix-count=1` (`f3-07d`) y tiene dos rutas BGP en la tabla. Se usa la tabla de rutas como evidencia.
4. **Cliente DHCP sin quitar** (desvío aceptado desde F1): sigue `/ip dhcp-client add interface=ether1` en ISP-1 e ISP-2. En ISP-2 `ether1` es el puerto hacia el Cloud; en ISP-1 es el enlace con EDGE (por el renombre de interfaces). No hay servidor DHCP en el enlace, así que no tiene efecto.
5. **El export oculta la clave TCP-MD5** (ver `docs/f3/claves-bgp.md`); los `.rsc` llevan el placeholder.

## Pendiente (F4)

- Prueba con clave BGP incorrecta y drill 3 (caída de proveedor).
