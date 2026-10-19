# Runbook — Drill 1: falla del master VRRP en la capa de distribución (R4)

**Ejecutado:** 2026-10-16 (sesión 1 de F4; fecha del reloj del router) · Evidencia: `capturas/f4/f4-01a … f4-01h` · Config: `docs/f2/distribucion-vrrp-ospf.md`.

## Objetivo

Medir cuánto tarda la LAN de usuarios (`192.168.10.0/24`) en recuperar su gateway virtual `192.168.10.1` cuando cae DIST-1 (master del grupo 10, prioridad 150), y verificar que al volver DIST-1 retoma el rol sin cortar el servicio.

## Estado inicial esperado

| Grupo | Master | Backup | IP virtual | MAC virtual |
|-------|--------|--------|------------|-------------|
| `vrrp10` (USERS) | DIST-1 (prio 150) | DIST-2 (prio 100) | 192.168.10.1 | `00:00:5E:00:01:0A` |
| `vrrp20` (SERVERS) | DIST-2 (prio 150) | DIST-1 (prio 100) | 192.168.20.1 | `00:00:5E:00:01:14` |

Nodos encendidos: DIST-1, DIST-2, los 2 switches y PC-USER. Hello de VRRP: 1 s (`interval=1s`).

## Pasos

1. **[DIST-1] y [DIST-2]** `/interface vrrp print`. DIST-1 con `RM` en `vrrp10`, DIST-2 con `RM` en `vrrp20` (`f4-01a`, `f4-01b`).
2. **[PC-USER]** ping continuo al gateway virtual y guardado a archivo para contar paquetes perdidos:
   `ping -c 40 192.168.10.1 > /tmp/drill1.txt`
3. **[GNS3]** a los ~10 s del ping, **Stop** sobre el nodo DIST-1. No se usa Suspend: GNS3 no baja la portadora hacia el vecino y la caída se detecta solo por el *master-down timer* (≈3 intervalos).
4. **[PC-USER]** al terminar el ping, ver qué secuencias faltan:
   `grep -o 'seq=[0-9]*' /tmp/drill1.txt | cut -d= -f2 | tr '\n' ' '` (`f4-01e`).
5. **[DIST-2]** `/interface vrrp print`: `vrrp10` pasó a `RM` (`f4-01f`).
6. **Failback.** **[GNS3]** Start sobre DIST-1 y, con la consola de PC-USER lista, `ping -c 90 192.168.10.1 > /tmp/drill1b.txt` (`f4-01g`). **[DIST-1]** `/interface vrrp print` (`f4-01h`).

## Resultado observado

| Medición | Valor | Cómo se obtiene |
|----------|-------|-----------------|
| Corte durante el failover | **3 paquetes perdidos de 40** (seq 14, 15 y 16), ≈ **3 s** | ping a 1 paquete por segundo; resolución de 1 s |
| DIST-2 toma `vrrp10` | log `vrrp10 now MASTER, master down timer` a las **20:06:14** (reloj del router) | `/log print` en DIST-2 (`f4-01k`) |
| Failback | **90 de 90**, 0 % de pérdida; RTT máximo 490 ms | `f4-01g` |
| DIST-1 retoma el master | log `vrrp10 now BACKUP, got higher priority 150 from 192.168.10.2` a las **20:12:02** | `f4-01k` |

El corte esperado era de 3 a 4 s (tres hellos de 1 s más el *skew time*); el observado, 3 s, coincide.

## Post-mortem

- **Qué pasó:** al apagar DIST-1, DIST-2 dejó de recibir anuncios de `vrrp10`, esperó el *master-down timer* y asumió la IP y la MAC virtuales. Los hosts no cambiaron nada: su gateway es la IP virtual.
- **Failback sin pérdida:** DIST-1 vuelve con prioridad 150, DIST-2 lo detecta, cede, y la IP virtual nunca queda sin dueño. El único síntoma es un RTT alto de un par de paquetes (490 ms) durante la transición.
- **Limitación del laboratorio:** el corte se midió con `Stop` del nodo, no con caída de enlace; con caída física de portadora el tiempo sería menor. Ping a 1 pps tiene resolución de 1 s.
- **Lo que no hace VRRP:** no mira si DIST-1 conserva su salida hacia el core. Si se cae el uplink de DIST-1 pero el router sigue vivo, sigue siendo master y la LAN queda sin salida. Mitigación posible (fuera del alcance de F4): `track` de la interfaz o ajuste de prioridad por script.

## Reversión

Ninguna: el drill no deja cambios de configuración (solo se apagó y encendió DIST-1). Verificar que `vrrp10` vuelva a tener a DIST-1 como master.
