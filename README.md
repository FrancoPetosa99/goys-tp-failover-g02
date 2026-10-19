| <h1>UTN-FRLP</h1> | <img src="./logo.png" alt="Logo UTN FRLP" width="100"> |
|-------------------------|----------------------------------|

# Proyecto Integrador — Failover Routing: la red que no se cae

Laboratorio grupal de **Gestión Operativa y Seguridad en Redes (GOYS)**, UTN FR La Plata. Diseño, implementación, operación y aseguramiento de una red empresarial de 5 capas (Internet, Edge, Core, Distribución y Acceso) con redundancia de primer salto (**VRRP**), de IGP (**OSPF**) y de proveedor (**BGP multi-homing**), sobre **GNS3 + MikroTik CHR (RouterOS 7)**.

**Grupo 2** · Entrega final: viernes 23/10/2026

---

## Integrantes

| Integrante | Rol |
|-----------|-----|
| Eliseche, Martín | R1 — Líder / Edge-WAN |
| Kalpin, Sofía | R2 — Proveedores |
| Gutierrez Mora, Agustín | R3 — Core |
| Bresciani, Isabella | R4 — Distribución |
| Petosa Ayala, Franco | R5 — Hosts / QA / Operación |

## Docentes

1. Rodriguez, Emanuel
2. Falabella, Osvaldo

---

## Estado

| Fase | Contenido | Vence | Estado |
|:----:|-----------|:-----:|:------:|
| F0 | Diseño y gestión de cambio | vie 2/10 | Aprobada |
| F1 | Topología + hardening + backup | vie 9/10 | Aprobada |
| F2 | VRRP + OSPF | vie 16/10 | Entregada |
| F3 | BGP + firewall | vie 16/10 | Entregada |
| F4 | Drills de failover + monitoreo | mar 20/10 | En Ejecución |
| F5 | Memoria + defensa | vie 23/10 | Pendiente |

Ningún nodo se enciende hasta que el docente apruebe F0. Seguimiento de tareas en [`backlog.md`](backlog.md).

## Topología objetivo

![Topología objetivo](docs/diagramas/topologia-objetivo.png)

## Índice de F0

| Documento | Contenido | Responsable |
|-----------|-----------|:-----------:|
| [`docs/f0/topologia-y-failover.md`](docs/f0/topologia-y-failover.md) | Topología de 5 capas, 15 enlaces, diseño de failover por capa | R1 |
| [`docs/f0/edge-seguridad.md`](docs/f0/edge-seguridad.md) | Defectos 1 y 5, servicios a deshabilitar, firewall edge | R1 |
| [`docs/f0/proveedores-claves.md`](docs/f0/proveedores-claves.md) | Validación ISP y política de claves de autenticación | R2 |
| [`docs/f0/core-defectos.md`](docs/f0/core-defectos.md) | Defectos 3 y 4 (core–core, HSRP→VRRP) | R3 |
| [`docs/f0/distribucion-vrrp.md`](docs/f0/distribucion-vrrp.md) | Defecto 2 y diseño VRRP | R4 |
| [`docs/f0/ipam.md`](docs/f0/ipam.md) | Plan de direccionamiento consolidado | R5 |
| [`docs/f0/operacion.md`](docs/f0/operacion.md) | Usuarios, change log y política de backup | R5 |

## Índice de F1

| Documento | Contenido | Responsable |
|-----------|-----------|:-----------:|
| [`docs/f1/despliegue-topologia.md`](docs/f1/despliegue-topologia.md) | Entorno, 11 nodos, 15 enlaces y verificación del cableado | R1 |
| [`docs/f1/mapa-interfaces-e-incidente.md`](docs/f1/mapa-interfaces-e-incidente.md) | Interfaz ↔ vecino ↔ IP por router y post-mortem de la numeración | R1 |
| [`docs/f1/verificacion-ips.md`](docs/f1/verificacion-ips.md) | IPs de enlace, loopbacks, hosts y pings | R5 |
| [`docs/f1/snapshot-base.md`](docs/f1/snapshot-base.md) | Snapshot BASE de GNS3 | R5 |
| [`docs/f1/hardening-checklist.md`](docs/f1/hardening-checklist.md) | Checklist de hardening de los 7 routers | R5 |
| [`docs/f1/backup-y-restore.md`](docs/f1/backup-y-restore.md) | Exports iniciales y prueba de restore | R5 |
| [`backups/2026-10-09/`](backups/2026-10-09/) | `/export terse` de cada router | R1 · R2 · R3 · R4 |
| [`configs/hosts/`](configs/hosts/) | Configuración persistente de PC-USER y SRV | R5 |
| [`capturas/f1/`](capturas/f1/) | Evidencia de la fase | todos |

## Índice de F2

| Documento | Contenido | Responsable |
|-----------|-----------|:-----------:|
| [`docs/f2/ospf-core-md5.md`](docs/f2/ospf-core-md5.md) | Diseño OSPF área 0 con MD5 y configuración del core (incluye core–core) | R3 |
| [`docs/f2/ospf-edge.md`](docs/f2/ospf-edge.md) | OSPF en EDGE y observación de interfaces para F3 | R1 |
| [`docs/f2/distribucion-vrrp-ospf.md`](docs/f2/distribucion-vrrp-ospf.md) | VRRP (vrid 10/20) y OSPF en DIST-1 y DIST-2 | R4 |
| [`docs/f2/claves-y-secretos.md`](docs/f2/claves-y-secretos.md) | Claves aplicadas (OSPF, VRRP), hallazgos y desvíos | R2 |
| [`docs/f2/verificacion.md`](docs/f2/verificacion.md) | Verificación de VRRP, 7 adyacencias OSPF, rutas y pings | R5 |
| [`docs/f2/cambios.md`](docs/f2/cambios.md) | Registro de cambios de la fase | R5 |
| [`backups/2026-10-13/`](backups/2026-10-13/) | `/export` de EDGE, CORE-1, CORE-2, DIST-1 y DIST-2 | R1 · R3 · R4 |
| [`capturas/f2/`](capturas/f2/) | Evidencia de la fase | todos |

## Índice de F3

| Documento | Contenido | Responsable |
|-----------|-----------|:-----------:|
| [`docs/f3/bgp-edge.md`](docs/f3/bgp-edge.md) | eBGP ×2 en EDGE, filtros, preferencia y redistribución OSPF→BGP | R1 |
| [`docs/f3/firewall-edge.md`](docs/f3/firewall-edge.md) | Firewall default-deny, plano de gestión y pruebas permitidas/bloqueadas | R1 |
| [`docs/f3/bgp-isp.md`](docs/f3/bgp-isp.md) | eBGP y default-originate en ISP-1 e ISP-2 | R2 |
| [`docs/f3/claves-bgp.md`](docs/f3/claves-bgp.md) | Claves BGP, estado de los secretos y hallazgo de export | R2 |
| [`docs/f3/ospf-default-y-core.md`](docs/f3/ospf-default-y-core.md) | Default por OSPF y propagación hacia el core | R3 |
| [`docs/f3/salida-lans-y-traceroute.md`](docs/f3/salida-lans-y-traceroute.md) | Salida de las LANs a Internet: ping, traceroute y pruebas negativas | R4 |
| [`docs/f3/verificacion.md`](docs/f3/verificacion.md) | Sesiones, matriz de pruebas y limitaciones | R5 |
| [`docs/f3/cambios.md`](docs/f3/cambios.md) | Registro de cambios de la fase | R5 |
| [`backups/2026-10-14/`](backups/2026-10-14/) | `/export` de EDGE, ISP-1 e ISP-2 | R1 · R2 |
| [`capturas/f3/`](capturas/f3/) | Evidencia de la fase (46 capturas) | todos |

## Índice de F4

| Documento | Contenido | Responsable |
|-----------|-----------|:-----------:|
| [`docs/f1/correccion-dhcp-client.md`](docs/f1/correccion-dhcp-client.md) | Corrección de la devolución de F1: cliente DHCP removido de los 7 routers | R1 |
| [`runbooks/drill-1-vrrp.md`](runbooks/drill-1-vrrp.md) | Drill 1: falla del master VRRP (corte ≈ 3 s) | R4 |
| [`runbooks/drill-2-ospf.md`](runbooks/drill-2-ospf.md) | Drill 2: caída de enlace OSPF (≈ 31 s por timers, ≈ 1 s por portadora) | R3 |
| [`runbooks/drill-3-bgp.md`](runbooks/drill-3-bgp.md) | Drill 3: cae el proveedor principal (≈ 160 s solo con BGP) | R1 |
| [`runbooks/drill-4-check-gateway.md`](runbooks/drill-4-check-gateway.md) | Drill 4: `check-gateway` (≈ 23 s) | R1 |
| [`runbooks/drill-5-load-sharing.md`](runbooks/drill-5-load-sharing.md) | Drill 5: reparto de carga de VRRP | R4 |
| [`docs/f4/clave-vrrp-incorrecta.md`](docs/f4/clave-vrrp-incorrecta.md) | Clave VRRP incorrecta: autenticación rechazada y dos masters | R4 |
| [`docs/f4/clave-ospf-incorrecta.md`](docs/f4/clave-ospf-incorrecta.md) | Clave OSPF incorrecta: `md5 mismatch` y adyacencia caída | R3 |
| [`docs/f4/clave-bgp-incorrecta.md`](docs/f4/clave-bgp-incorrecta.md) | Clave BGP incorrecta y reglas `in-bgp-*` con conexión iniciada por el ISP | R1 |
| [`docs/f4/ospf-default-if-installed.md`](docs/f4/ospf-default-if-installed.md) | `originate-default`: `always` contra `if-installed` | R3 |
| [`docs/f4/internet-simulada.md`](docs/f4/internet-simulada.md) | Destino `203.0.113.1` en los dos ISP | R2 |
| [`docs/f4/snmpv3-claves.md`](docs/f4/snmpv3-claves.md) | SNMPv3 en los 7 routers, engine-id y hallazgos | R2 |
| [`docs/f4/monitoreo.md`](docs/f4/monitoreo.md) | Qué se monitorea, alertas por netwatch y syslog, y lo no demostrado | R5 |
| [`docs/f4/ejecucion.md`](docs/f4/ejecucion.md) | Sesiones, quién operó, rotación y relojes | R5 |
| [`docs/f4/verificacion.md`](docs/f4/verificacion.md) | Tiempos, matriz de pruebas y limitaciones | R5 |
| [`docs/f4/cambios.md`](docs/f4/cambios.md) | Registro de cambios de la fase | R5 |
| [`backups/2026-10-17/`](backups/2026-10-17/) | `/export` de los 7 routers, sin cliente DHCP | R1 · R2 · R3 · R4 |
| [`capturas/f4/`](capturas/f4/) · [`capturas/f1/`](capturas/f1/) | Evidencia de la fase (80 capturas de F4 y 9 de la corrección de F1) | todos |

## Estructura del repositorio

```
.
├── README.md
├── backlog.md        # tareas con dueño y estado
├── docs/
│   ├── f0/ 
|   ├── f1/   
|   ├── f2/   
|   ├── f3/   
│   ├── diagramas/    # topología y diagramas de diseño
│   └── memoria.md    # memoria final (F5)
├── configs/          # .rsc finales por router
├── backups/          # /export de cada router, por fecha
|   ├── 2026-10-09/   
|   ├── 2026-10-13/  
|   ├── 2026-10-14/  
├── runbooks/         # un .md por drill de failover
└── capturas/         # screenshots por drill
    ├── f1/   
    ├── f2/   
    └── f3/
```

## Convención de commits

`tipo(alcance): descripción breve`, con tipos `feat`, `fix`, `docs`, `ops` y `chore`. Un commit por cambio lógico y cada integrante commitea su parte con su propio usuario de git.

Ejemplos: `docs(f0): defectos 3 y 4 (core-core, HSRP a VRRP)` · `feat(configs): agrego VRRP vrid10 en DIST-1` · `ops(backup): backup post-F2`.