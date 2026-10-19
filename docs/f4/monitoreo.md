# F4 — Monitoreo: qué se vigila, con qué y qué no se pudo demostrar (R5)

**Ejecutado:** 2026-10-17 (sesiones 2 a 5) · Evidencia: `capturas/f4/f4-04j`, `f4-04l`, `f4-04o`, `f4-05a`, `f4-05c`, `f4-05g`, `f4-05h2`, `f4-05h3` y las de SNMP (`docs/f4/snmpv3-claves.md`) · Configuración: `backups/2026-10-17/EDGE.rsc`.

## Qué se monitorea

| Qué | Cómo | Dónde | Estado |
|-----|------|-------|:------:|
| Estado de los 7 routers (interfaces, tráfico, sistema) | SNMPv3 `authPriv` (SHA1/AES), comunidad `monitor`, solo lectura | los 7 routers | ✅ configurado¹ |
| Alcance del proveedor principal | netwatch `isp1`: ping a `192.0.2.1` cada 10 s, timeout 1 s | EDGE | ✅ |
| Aviso de caída y recuperación | `:log warning "ALERTA netwatch: ISP-1 (192.0.2.1) caido"` y `:log info "netwatch: ISP-1 (192.0.2.1) recuperado"` | EDGE | ✅ |
| Centralización de las alertas | log remoto por syslog (UDP/514) a SRV `192.168.20.100`, solo el tópico `script` | EDGE → SRV | ✅ |
| Vecinos OSPF, sesiones BGP y grupos VRRP | consulta manual (`/routing ospf neighbor print`, `/routing bgp session print`, `/interface vrrp print`) y los logs del router | cada router | manual² |

¹ La consulta con `snmpwalk` desde SRV no se pudo hacer (ver más abajo). Lo que está demostrado es la configuración del lado del router.
² No hay un sistema que consulte esos estados de forma periódica; se vieron con los comandos durante los drills.

## Evidencia de las alertas

- **Entrada de netwatch en EDGE:** `isp1`, tipo `simple`, host `192.0.2.1`, intervalo 10 s, timeout 1 s, estado `up` (`f4-04j`).
- **Caída de ISP-1:** el log de EDGE registra `script,warning ALERTA netwatch: ISP-1 (192.0.2.1) caido` (`f4-04l`) y, al volver, `netwatch: ISP-1 (192.0.2.1) recuperado` (`f4-04o`).
- **Llegada a SRV:** con `nc -l -u -p 514` en SRV se recibió la línea `script,warning ALERTA netwatch: ISP-1 (192.0.2.1) caido` (`f4-05g`).
- **Una línea por evento:** la primera prueba mostraba el mensaje repetido porque la regla de logging estaba duplicada en EDGE; se borró la fila sobrante (`f4-05h2`) y un mensaje de prueba (`:log warning "ALERTA prueba syslog unica"`) llegó una sola vez (`f4-05h3`).
- **Conectividad de SRV con los routers:** ping 3/3 desde SRV a las loopbacks de EDGE (`10.255.0.1`) y de CORE-1 (`10.255.0.11`) (`f4-05a`).

## Netwatch contra BGP

En la sesión 4 se dejó caer ISP-1 y se compararon las dos señales en EDGE (mismo reloj):

| Señal | Momento (reloj de EDGE) |
|-------|-------------------------|
| Netwatch: `ALERTA ... caido` | 23:23:36 |
| BGP: `last-stopped` de la sesión | 23:25:45 |
| Netwatch: `recuperado` | 23:28:13 |
| BGP: reinicio de la sesión | 23:28:16 |

Netwatch avisó **≈ 2 min 9 s antes** de que BGP declarara la caída (el *hold timer* de 3 minutos); la recuperación coincide en segundos. Es el mismo fenómeno del drill 4: sondear el siguiente salto detecta mucho antes que esperar los timers de BGP.

## Qué hay que saber antes de confiar en la alerta

- **Netwatch mira ICMP al gateway**, no el estado de la sesión BGP ni si el ISP tiene salida. Es una alerta temprana, no una prueba de que el servicio funciona.
- **Solo ISP-1.** ISP-2 no tiene entrada de netwatch.
- **El syslog remoto va por UDP, sin cifrar ni confirmación de entrega.** Si SRV está apagado o la red falla, el aviso se pierde sin reintento (queda igual en el log local de EDGE).
- **Reglas del firewall de EDGE:** SNMP entra solo desde la lista `LAN` (`in-snmp-lan`, antes de `in-drop-resto`); los ISP no pueden consultarlo (`f4-04h2`).

## Qué no se pudo demostrar

- **`snmpwalk` desde SRV.** El host es Alpine y no tiene `net-snmp-tools`; `apk add` falla por falta de resolución DNS (`f4-05c`, el laboratorio no tiene salida a Internet). SNMPv3 quedó verificado en los routers (`/snmp print`, engine-id único, comunidad `monitor`) pero no se vio una respuesta real. Para cerrarlo haría falta darle salida a Internet a SRV un momento o llevar el paquete por otro medio.
- **Un sistema de monitoreo real** (Zabbix, LibreNMS, Prometheus): fuera del alcance de F4; el monitoreo del laboratorio se apoya en SNMP del lado del router, netwatch y syslog.
- **Alertas para VRRP, OSPF y BGP.** Sin entradas de netwatch ni scripts: la detección es manual.
