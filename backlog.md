# Backlog — Laboratorio Failover Routing

> **Grupo:** 2 · **Repo:** goys-failover-grupo2 · **Vencimiento final:** vie 23/10

> **F0 entregada · F1 ejecutada (2 correcciones menores abiertas) · F2 en adelante: semana próxima.** Regla de oro: primero el diseño, después el CLI.

## Leyenda de estado

- `[ ]` pendiente · `[~]` en curso · `[x]` hecho
- Cada tarea lleva **dueño** (rol): `[R1]` … `[R5]`.
- **"Hecho" = criterio de aceptación cumplido** (ver spec, sección 6). No "más o menos".

---

## Epic F0 — Diseño y gestión de cambio · *vence vie 2/10*

### IPAM / direccionamiento
- [x] [R1] revisar tabla de enlaces y LANs del plan-f0.md y confirmar cero solapamiento
- [x] [R3] validar IPs de enlaces EDGE↔CORE y CORE↔DIST
- [x] [R4] validar LANs y VRRP (vrid, prioridades, IP virtual)
- [x] [R2] validar enlaces y loopbacks de ISP-1/ISP-2
- [x] [R5] consolidar router-ids y loopbacks en la tabla final

### Corrección del diagrama (≥ 3 defectos)
- [x] [R1] redactar defectos 1 y 5 (firewall SPOF, RR mal ubicado) con justificación
- [x] [R3] redactar defectos 3 y 4 (core–core, HSRP→VRRP) con justificación
- [x] [R4] redactar defecto 2 (subredes solapadas) con justificación
- [x] [R5] redibujar diagrama corregido en `docs/diagramas/`

### Política de seguridad
- [x] [R5] definir usuarios/privilegios (admin, monitor)
- [x] [R1] definir servicios a deshabilitar y diseño del firewall edge
- [x] [R2] definir claves de autenticación (OSPF, BGP ×2, VRRP) y cómo se comparten

### Política de operación (change log + backup)
- [x] [R5] definir formato de change log y convención de commits
- [x] [R5] definir política de backup (cuándo, cómo, nombres)

### Repositorio git
- [x] [R1] crear repo y dar acceso al docente
- [x] [R5] subir estructura + README.md + backlog.md
- [x] [R1] [R2] [R3] [R4] [R5] primer commit de cada rol (trazabilidad por autor)
- [x] [R1] entregar plan F0 al docente para aprobación

---

## Epic F1 — Topología + hardening + backup · *vence vie 9/10*

### Despliegue (7 CHR + 2 switches + 2 hosts)
- [x] [R1] armar (o abrir, si el docente lo entrega) el proyecto GNS3 con los 11 nodos y verificar el cableado contra `docs/f0/topologia-y-failover.md`
- [x] [R5] levantar los 2 switches y los 2 hosts
- [x] [R2] [R3] [R4] encender y nombrar los routers de su rol

### IPs de enlace + loopbacks
- [x] [R1] [R2] [R3] [R4] configurar IPs de enlace y loopback según IPAM (cada rol, su parte)
- [x] [R5] verificar ping entre vecinos directos y registrar capturas _(pings verificados por R1; capturas solo de ISP-2→EDGE y DIST-2, ver `docs/f1/verificacion-ips.md`)_

### Snapshot BASE
- [x] [R5] tomar snapshot BASE en GNS3 y documentarlo

### Hardening (los 7 routers)
- [x] [R1] [R2] [R3] [R4] cambiar password admin, crear usuario `monitor`, apagar servicios (cada rol, sus routers) _(abierto: usuario `moonitor` en CORE-1 y cliente DHCP; ver `docs/f1/hardening-checklist.md`)_
- [x] [R5] verificar hardening en los 7 routers (checklist) _(`docs/f1/hardening-checklist.md`, 2 correcciones abiertas)_

### Backup inicial (`/export`)
- [x] [R5] exportar `/export` de cada router y versionar en `backups/` _(cada rol sube el `.rsc` de sus routers; R5 consolida)_
- [x] [R5] probar restore en un router y documentar evidencia _(hecho en ISP-1)_

---

## Epic F2 — VRRP + OSPF · *vence vie 16/10*

### VRRP (2 grupos, load-sharing, auth)
- [x] [R4] configurar VRRP vrid 10 en DIST-1 (master)
- [x] [R4] configurar VRRP vrid 20 en DIST-2 (master)
- [x] [R4] activar auth simple en ambos grupos
- [x] [R5] verificar master/backup con `/interface vrrp print`

### OSPF área 0 (con MD5, incluido core–core)
- [x] [R3] configurar OSPF en CORE-1/CORE-2 incluyendo enlace core–core
- [x] [R4] configurar OSPF en DIST-1/DIST-2
- [x] [R1] configurar OSPF en EDGE
- [x] [R3] activar MD5 en todas las interfaces OSPF y verificar adyacencias FULL

### Verificación L3 (ping intra-LAN + gateway virtual)
- [x] [R5] ping PC-USER ↔ SRV y a gateways virtuales
- [x] [R5] capturar tablas de rutas y estado OSPF/VRRP

---

## Epic F3 — BGP + firewall · *vence vie 16/10*

### eBGP multi-homing (2 sesiones, TCP-MD5)
- [x] [R2] configurar eBGP en ISP-1 e ISP-2 con default-originate
- [x] [R1] configurar eBGP ×2 en EDGE
- [x] [R1] [R2] activar TCP-MD5 en ambas sesiones y verificar established

### Redistribución OSPF→BGP
- [x] [R1] redistribuir OSPF→BGP y verificar que los ISP aprenden las LANs

### Salida a "Internet" (host → loopback ISP)
- [x] [R5] ping/traceroute de PC-USER y SRV a loopbacks de ISP

### Firewall edge (filtro + plano de gestión)
- [x] [R1] implementar filtro de entrada y proteger plano de gestión
- [x] [R5] verificar reglas con pruebas permitidas/bloqueadas

---

## Epic F4 — Drills + monitoreo · *vence mar 20/10*

### Los 5 drills (runbook + post-mortem + tiempo)
- [x] [R5] drill 1 VRRP: runbook, ejecución, tiempo, post-mortem
- [x] [R5] drill 2 OSPF: runbook, ejecución, tiempo, post-mortem
- [x] [R5] drill 3 BGP (cae proveedor): runbook, ejecución, tiempo, post-mortem
- [x] [R5] drill 4 check-gateway: runbook, ejecución, tiempo, post-mortem
- [x] [R5] drill 5 load-sharing VRRP: runbook, ejecución, post-mortem
- [x] [R1] [R2] rotación de roles en esta fase (R1↔R2): ejecutar un drill intercambiados

### Monitoreo (SNMP/chequeos)
- [x] [R5] habilitar SNMP/chequeos con usuario `monitor`
- [x] [R5] documentar qué se monitorea (enlaces, vecinos OSPF, sesiones BGP, VRRP)

### Verificación de seguridad (clave incorrecta falla)
- [x] [R3] probar clave OSPF incorrecta → adyacencia falla (documentar)
- [x] [R1] probar clave BGP incorrecta → sesión falla (documentar)
- [x] [R4] probar clave VRRP incorrecta → no se forma el grupo (documentar)

---

## Epic F5 — Memoria + defensa · *vence vie 23/10*

### Memoria (plantilla completa)
- [ ] [R5] copiar plantilla a `docs/memoria.md` y consolidar secciones
- [ ] [R1] [R2] [R3] [R4] completar configs finales y secciones de su rol
- [ ] [R5] completar change log (reflejando commits), backups y checklist de entrega

### Backlog cerrado (todo en "hecho")
- [ ] [R5] revisar que cada tarea cumpla su criterio de aceptación y cerrar backlog

### Defensa oral (parte propia + ajena)
- [ ] [R1] [R2] [R3] [R4] [R5] preparar explicación de la parte propia
- [ ] [R1] [R2] [R3] [R4] [R5] estudiar una parte ajena (cruzar roles)
