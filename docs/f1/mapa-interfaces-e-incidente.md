# F1 — Mapa de interfaces por router e incidente de numeración (R1)

## 1. Mapa final (nombre **RouterOS** → vecino → IP)

Fuente: exports de `backups/2026-10-09/`. "GNS3" es el adaptador que muestra GNS3 en el lienzo.

| Router | RouterOS | GNS3 | Vecino | IP |
|--------|:--------:|:----:|--------|----|
| **EDGE** | ether1 | ether1 | ISP-1 | 192.0.2.2/30 |
| | ether2 | ether2 | ISP-2 | 192.0.2.6/30 |
| | ether3 | ether3 | CORE-1 | 10.0.0.1/30 |
| | ether4 | ether4 | CORE-2 | 10.0.0.5/30 |
| | lo | — | — | 10.255.0.1/32 |
| **ISP-1** | **ether1** | **ether2** | EDGE | 192.0.2.1/30 |
| | **ether2** | **ether1** | Cloud1 (enp0s3) | — (sin IP estática) |
| | lo | — | — | 198.51.100.1/32 |
| **ISP-2** | ether1 | ether1 | Cloud2 (enp0s3) | — |
| | ether2 | ether2 | EDGE | 192.0.2.5/30 |
| | lo | — | — | 198.51.100.2/32 |
| **CORE-1** | ether1 | ether1 | EDGE | 10.0.0.2/30 |
| | ether2 | ether2 | CORE-2 | 10.0.0.9/30 |
| | ether3 | ether3 | DIST-1 | 10.0.0.13/30 |
| | ether4 | ether4 | DIST-2 | 10.0.0.17/30 |
| | lo | — | — | 10.255.0.11/32 |
| **CORE-2** | ether1 | ether1 | EDGE | 10.0.0.6/30 |
| | ether2 | ether2 | CORE-1 | 10.0.0.10/30 |
| | ether3 | ether3 | DIST-1 | 10.0.0.21/30 |
| | ether4 | ether4 | DIST-2 | 10.0.0.25/30 |
| | lo | — | — | 10.255.0.12/32 |
| **DIST-1** | ether1 | ether1 | CORE-1 | 10.0.0.14/30 |
| | ether2 | ether2 | CORE-2 | 10.0.0.22/30 |
| | ether3 | ether3 | SW-ACC-USERS | 192.168.10.2/24 |
| | ether4 | ether4 | SW-ACC-SERVERS | 192.168.20.2/24 |
| | lo | — | — | 10.255.0.21/32 |
| **DIST-2** | **ether2** | **ether1** | CORE-1 | 10.0.0.18/30 |
| | **ether3** | **ether2** | CORE-2 | 10.0.0.26/30 |
| | **ether4** | **ether3** | SW-ACC-USERS | 192.168.10.3/24 |
| | **ether1** | **ether4** | SW-ACC-SERVERS | 192.168.20.3/24 |
| | lo | — | — | 10.255.0.22/32 |

**Hosts:** PC-USER eth0 192.168.10.100/24 gw 192.168.10.1 · SRV eth0 192.168.20.100/24 gw 192.168.20.1.

Las filas en **negrita** son las que no coinciden (ISP-1 y DIST-2). Los otros 5 routers coinciden 1:1.

## 2. Post-mortem: numeración de interfaces

| Campo | Detalle |
|-------|---------|
| **Fecha** | 2026-10-08/09 (verificación de enlaces, subfase "correcciones") |
| **Síntoma** | `ping` entre vecinos directos falló en ISP-1↔EDGE y en los enlaces de DIST-2, aunque el *Topology Summary* de GNS3 mostraba el cableado correcto y las IPs estaban bien tipeadas. |
| **Causa** | En ISP-1 y DIST-2 los nombres `etherN` de RouterOS **no siguen el orden de los adaptadores de GNS3**. Lo que RouterOS llamaba `ether1` en ISP-1 era el adaptador 2 de GNS3 (hacia EDGE), y en DIST-2 los cuatro nombres estaban rotados una posición. Se identificó comparando el último byte de la MAC (`:00` = adaptador 1 de GNS3, `:01` = adaptador 2, …) con `/interface ethernet print`. Los exports de esos dos routers son los únicos con líneas `/interface ethernet set [ find default-name=… ] name=…`. |
| **Causa raíz** | No determinada. Hipótesis: el orden en que arrancó/enumeró los adaptadores el CHR en el primer boot. No se reprodujo. |
| **Impacto** | Ping fallido en 2 routers. Sin impacto en el resto. Se perdió tiempo diagnosticando "el router equivocado": además, la consola de EDGE no estaba abierta/logueada, lo que enmascaró el diagnóstico (el ping de ISP-1 funcionó recién al entrar a EDGE). |
| **Corrección** | Se movieron las IPs a la interfaz correcta **por número de fila** (`/ip address set <n> interface=<etherX>`), sin renombrar interfaces. Detalle en la tabla de la sección 1. |
| **Verificación** | Pings OK entre todos los vecinos directos (verificado por R1; capturas solo de ISP-2→EDGE y DIST-2, ver `docs/f1/verificacion-ips.md`). |
| **Lección** | (1) Antes de poner IPs, comparar MAC ↔ adaptador en cada router (`/interface ethernet print`). (2) Después de cablear, abrir consola en **ambos** extremos antes de concluir "no hay conectividad". (3) `[find address=x/yy]` sin comillas no matchea: usar número de fila. |
| **Prevención** | Mantener esta tabla como referencia; ante un re-deploy volver a verificar MAC ↔ adaptador. |

## 3. Notas para fases siguientes

- En ISP-1 el puerto hacia Cloud1 es **ether2** de RouterOS (en ISP-2 es ether1). Usarlo en las tareas que dependan del Cloud.
- Los 7 exports conservan `/ip dhcp-client add interface=ether1`. En ISP-1 ese `ether1` es el enlace a EDGE (no el Cloud). Ver `docs/f1/hardening-checklist.md`.
