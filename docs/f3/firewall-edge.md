# F3 — Firewall edge y plano de gestión (R1)

**Fecha:** 2026-10-13 (sesiones 4 y 5) y 2026-10-14 (export y contadores finales, sesión 7), hora de Argentina · Evidencia: `capturas/f3/` · Configuración: `backups/2026-10-14/EDGE.rsc`. Diseño de F0: `docs/f0/edge-seguridad.md`.

## Diseño

Política **default-deny** en las dos cadenas de EDGE. Se usan listas de interfaces para no depender de nombres sueltos.

| Lista | Interfaces | Qué hay detrás |
|-------|------------|----------------|
| `WAN` | ether1, ether2 | ISP-1 e ISP-2 |
| `LAN` | ether3, ether4 | CORE-1 y CORE-2 |

### Cadena `input` (tráfico hacia EDGE)

| # | Comentario | Acción | Qué deja pasar |
|:-:|------------|:------:|----------------|
| 0 | `in-estab` | accept | established, related, untracked |
| 1 | `in-invalid` | drop | connection-state invalid |
| 2 | `in-icmp` | accept | ICMP (de cualquier origen) |
| 3 | `in-bgp-isp1` | accept | tcp/179 desde 192.0.2.1 por ether1 |
| 4 | `in-bgp-isp2` | accept | tcp/179 desde 192.0.2.5 por ether2 |
| 5 | `in-ospf` | accept | protocolo OSPF desde la lista `LAN` |
| 6 | `in-ssh-lan` | accept | tcp/22 desde la lista `LAN` |
| 7 | `in-drop-resto` | drop | todo lo demás |

### Cadena `forward` (tráfico a través de EDGE)

| # | Comentario | Acción | Qué deja pasar |
|:-:|------------|:------:|----------------|
| 8 | `fw-estab` | accept | established, related, untracked |
| 9 | `fw-invalid` | drop | connection-state invalid |
| 10 | `fw-lan-a-wan` | accept | `LAN` → `WAN` (las LANs salen a Internet) |
| 11 | `fw-lan-a-lan` | accept | `LAN` → `LAN` (tránsito entre cores si cae el enlace core–core) |
| 12 | `fw-drop-resto` | drop | todo lo demás: `WAN` → `LAN` nuevo y `WAN` → `WAN` |

La última regla impide dos cosas: que un ISP inicie conexiones hacia las LANs, y que EDGE sirva de tránsito entre ISP-1 e ISP-2.

### Plano de gestión

| Control | Estado | Origen |
|---------|--------|--------|
| telnet, ftp, www, api, api-ssl, winbox deshabilitados | ✅ | F1 |
| SSH limitado a `10.0.0.0/8,192.168.0.0/16` | ✅ | F1 |
| SSH solo desde la lista `LAN` (regla 6) y drop del resto | ✅ | F3 |
| `/ip ssh strong-crypto=yes` | ✅ | F3 |
| MAC-server y discovery de vecinos en `none`, `bandwidth-server` apagado | ✅ | F1 |

La consola de GNS3 es un puerto serie y no pasa por el firewall, así que una regla mal puesta no deja sin acceso al router.

## Configuración

```routeros
/interface list add name=WAN
/interface list add name=LAN
/interface list member add list=WAN interface=ether1
/interface list member add list=WAN interface=ether2
/interface list member add list=LAN interface=ether3
/interface list member add list=LAN interface=ether4

/ip firewall filter add chain=input action=accept connection-state=established,related,untracked comment="in-estab"
/ip firewall filter add chain=input action=drop connection-state=invalid comment="in-invalid"
/ip firewall filter add chain=input action=accept protocol=icmp comment="in-icmp"
/ip firewall filter add chain=input action=accept protocol=tcp dst-port=179 src-address=192.0.2.1 in-interface=ether1 comment="in-bgp-isp1"
/ip firewall filter add chain=input action=accept protocol=tcp dst-port=179 src-address=192.0.2.5 in-interface=ether2 comment="in-bgp-isp2"
/ip firewall filter add chain=input action=accept protocol=ospf in-interface-list=LAN comment="in-ospf"
/ip firewall filter add chain=input action=accept protocol=tcp dst-port=22 in-interface-list=LAN comment="in-ssh-lan"
/ip firewall filter add chain=input action=drop comment="in-drop-resto"

/ip firewall filter add chain=forward action=accept connection-state=established,related,untracked comment="fw-estab"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="fw-invalid"
/ip firewall filter add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="fw-lan-a-wan"
/ip firewall filter add chain=forward action=accept in-interface-list=LAN out-interface-list=LAN comment="fw-lan-a-lan"
/ip firewall filter add chain=forward action=drop comment="fw-drop-resto"

/ip ssh set strong-crypto=yes
```

## Verificación

### Reglas cargadas

| Sesión | Qué se muestra | Captura |
|:------:|----------------|---------|
| 4 | Listas de interfaces: ether1 y ether2 en `WAN`, ether3 y ether4 en `LAN` | `f3-04a` |
| 4 | Reglas `input` | `f3-04b` |
| 4 | Reglas `forward` | `f3-04c` |
| 7 | Estado final de las 13 reglas en el export | `f3-07i1`, `f3-07i2` |

### Pruebas permitidas y bloqueadas (sesión 4, desde ISP-1)

| Prueba | Esperado | Resultado | Captura |
|--------|----------|-----------|---------|
| ISP-1 → EDGE `ping 192.0.2.2` | permitido (`in-icmp`) | 4/4, TTL 64 | `f3-04d` |
| BGP reiniciado con `disable`/`enable` de `to-ISP1` | la sesión vuelve a `E` | `E`, uptime 1m51s en EDGE, `last-stopped` 5 s antes del inicio en ISP-1 | `f3-04e1`, `f3-04e2` |
| ISP-1 → EDGE `/tool fetch http://192.0.2.2/` | bloqueado (`in-drop-resto`) | `failed: Idle timeout - connecting` (sin respuesta, no "refused") | `f3-04f1` |
| ISP-1 → EDGE SSH (`/system ssh address=192.0.2.2`) | bloqueado | queda colgado, se corta con Ctrl+C | `f3-04f2` |
| Contadores | `in-icmp`, `in-drop-resto` con paquetes | `in-icmp` 1 paquete, `in-drop-resto` 90 paquetes (27 376 bytes), `in-estab` 80 | `f3-04g` |

### Pruebas desde adentro (sesión 5, desde CORE-1)

| Prueba | Esperado | Resultado | Captura |
|--------|----------|-----------|---------|
| Adyacencia OSPF EDGE ↔ CORE-1 con el firewall activo | `Full` (`in-ospf`) | `Full`, router-id 4.4.4.4, 10.0.0.2, adyacencia 3m58s | `f3-05a` |
| CORE-1 → EDGE `ping 10.0.0.1` | permitido | 4/4, TTL 64 | `f3-05b` |
| CORE-1 → EDGE SSH (`in-ssh-lan`) | permitido | login correcto y `/system identity print` devuelve `EDGE` | `f3-05c` |
| CORE-1 → EDGE `/tool fetch http://10.0.0.1/` | bloqueado | `failed: Idle timeout - connecting` | `f3-05d` |
| Contadores | `in-ospf`, `in-ssh-lan`, `in-drop-resto` con paquetes | `in-ospf` 12, `in-ssh-lan` 1, `in-icmp` 1, `in-drop-resto` 40 (12 048 bytes), `in-estab` 116 | `f3-05e` |

### Tránsito (sesión 7, ver `docs/f3/salida-lans-y-traceroute.md`)

| Prueba | Esperado | Resultado | Captura |
|--------|----------|-----------|---------|
| PC-USER y SRV → 198.51.100.1 | permitido (`fw-lan-a-wan`) | 4/4 y traceroute en 4 saltos | `f3-07f`, `f3-07g` |
| ISP-1 → 192.168.10.100 | bloqueado (`fw-drop-resto`) | 3/3 timeout | `f3-07e` |
| Contadores `forward` | `fw-lan-a-wan` y `fw-drop-resto` con paquetes | `fw-estab` 20, `fw-lan-a-wan` 8, `fw-drop-resto` 3 | `f3-07h` |

## Observaciones y limitaciones

1. **Las reglas `in-bgp-*` no llegaron a contar paquetes** (0 en `f3-04g` y en `f3-05e`). EDGE inicia las sesiones BGP y las respuestas entran como `established` por la regla 0, así que la dirección "el ISP inicia la conexión" no se ejercitó. Se prueba en F4 (junto con la prueba de clave BGP incorrecta, con EDGE + ISP-1 encendidos).
2. **La sesión BGP reiniciada en la sesión 4 sí pasó por el firewall:** al volver a `E` con la regla `in-drop-resto` activa, queda demostrado que el tráfico de retorno está permitido.
3. **Numeración de reglas.** En `f3-04c` las reglas `forward` figuran como 7 a 11 y en `f3-04g` y en el export como 8 a 12: en el estado final `in-drop-resto` ocupa la posición 7. Vale el estado final.
4. **ICMP sin límite de tasa** en `in-icmp`. Aceptable en el laboratorio; en producción se limitaría.
5. **Sin reglas anti-spoofing ni bogons**, y los drops no se registran en el log (solo hay contadores).
6. **SNMP (F4):** la cadena `input` no acepta udp/161. Al habilitar el monitoreo con el usuario `monitor` hay que agregar la regla correspondiente desde la lista `LAN`.
7. **El firewall está solo en EDGE**, como pedía el diseño de F0; CORE, DIST e ISP no tienen reglas.
