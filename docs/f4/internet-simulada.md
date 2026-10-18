# F4 — "Internet simulada": `203.0.113.1` en los dos ISP (R2)

**Ejecutado:** 2026-10-17 (sesión 3 y pasada de correcciones) · Evidencia: `capturas/f4/f4-03a`, `f4-03b`, `f4-03d`, `f4-03s`, `f4-03t`, `f1x-07b` · Configuración: `backups/2026-10-17/ISP-1.rsc` y `ISP-2.rsc`.

## Por qué hizo falta

En F3 la "Internet" eran las loopbacks de cada proveedor (`198.51.100.1` y `.2`). Como los ISP no se interconectan, la loopback del proveedor que **no** es el activo no es alcanzable (limitación 2 de `docs/f3/verificacion.md`), y sin un destino que responda por *cualquiera* de los dos caminos no se puede medir un failover de proveedor.

## Qué se hizo

Un destino común en la loopback de ambos ISP, tomado del bloque de documentación `203.0.113.0/24` (RFC 5737, no se enruta en Internet real):

```routeros
# en ISP-1 y en ISP-2
/ip address add address=203.0.113.1/32 interface=lo network=203.0.113.1 comment="Internet simulada"
```

No se anuncia por BGP ni se redistribuye: cada ISP lo tiene conectado, y EDGE llega a él por el default que recibe del proveedor activo. Los ISP siguen sin verse entre sí.

## Verificación

| Prueba | Resultado | Captura |
|--------|-----------|---------|
| `/ip address print where interface=lo` en ISP-1 y en ISP-2 | `198.51.100.x/32` y `203.0.113.1/32` con el comentario | `f4-03a`, `f4-03b` |
| EDGE → `203.0.113.1` | ping 4/4 por el default de ISP-1 | `f4-03d` |
| PC-USER → `203.0.113.1` | 3/3, TTL 61; traceroute en 4 saltos: `192.168.10.2` (DIST-1) → `10.0.0.13` (CORE-1) → `10.0.0.1` (EDGE) → `203.0.113.1` | `f4-03s` |
| SRV → `203.0.113.1` | 3/3, TTL 61; traceroute en 4 saltos: `192.168.20.3` (DIST-2) → `10.0.0.13` → `10.0.0.1` → `203.0.113.1` | `f4-03t` |
| El mismo destino responde cuando cae ISP-1 | el ping de los drills 3 y 4 se recupera por ISP-2 (`docs/f4/` y `runbooks/`) | `f4-03g`, `f4-03l` |

El primer salto de cada host confirma además el reparto de carga de VRRP (`runbooks/drill-5-load-sharing.md`): PC-USER sale por DIST-1 y SRV por DIST-2.

## Observaciones

1. **El mismo destino responde desde dos equipos distintos.** Es lo que se busca (el failover se ve como "el ping se corta y vuelve") pero en una red real sería una dirección anycast con las implicancias del caso; aquí es solo un recurso de laboratorio.
2. **ISP-2 ya no tiene cliente DHCP.** Su `ether1` es el puerto hacia el Cloud/NAT y antes de F4 tenía un lease (`10.0.2.16/24`). Tras la corrección de la devolución de F1 quedó sin direcciones salvo la loopback y `192.0.2.5/30` en `ether2` (`f1x-07b`, `docs/f1/correccion-dhcp-client.md`).
3. **Comentarios en las direcciones:** el comentario `Internet simulada` figura en los exports de los dos ISP, de modo que nadie confunda esa dirección con una real.

## Reversión

`/ip address remove [find comment="Internet simulada"]` en cada ISP.
