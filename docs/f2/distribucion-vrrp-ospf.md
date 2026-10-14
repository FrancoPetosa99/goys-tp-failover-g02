# F2 — Distribución: VRRP y OSPF en DIST-1 y DIST-2 (R4)

**Fecha:** 2026-10-13 (sesión 1 la configuración; exports en las sesiones 7 y 8) · Configuraciones: `backups/2026-10-13/DIST-1.rsc` y `DIST-2.rsc`.

## 1. VRRP (primer salto con load-sharing)

Diseño de F0 (`docs/f0/distribucion-vrrp.md`): dos grupos, cada DIST master de uno y backup del otro, VRRP v2 con autenticación simple.

| Grupo | VRID | Master | Priority (master/backup) | IP virtual | MAC virtual |
|-------|:----:|:------:|:------------------------:|:----------:|:-----------:|
| USERS | 10 | DIST-1 | 150 / 100 | 192.168.10.1/32 en `vrrp10` | 00:00:5E:00:01:0A |
| SERVERS | 20 | DIST-2 | 150 / 100 | 192.168.20.1/32 en `vrrp20` | 00:00:5E:00:01:14 |

**Interfaces físicas (ojo con DIST-2, que tiene los nombres rotados):**

| Router | `vrrp10` (USERS) sobre | `vrrp20` (SERVERS) sobre |
|--------|:----------------------:|:------------------------:|
| DIST-1 | ether3 | ether4 |
| DIST-2 | **ether4** | **ether1** |

Comandos aplicados (la clave real no está en el repo):

```routeros
# DIST-1
/interface vrrp add name=vrrp10 interface=ether3 vrid=10 priority=150 version=2 authentication=simple password=<VRRP-KEY>
/interface vrrp add name=vrrp20 interface=ether4 vrid=20 priority=100 version=2 authentication=simple password=<VRRP-KEY>
/ip address add address=192.168.10.1/32 interface=vrrp10
/ip address add address=192.168.20.1/32 interface=vrrp20

# DIST-2
/interface vrrp add name=vrrp10 interface=ether4 vrid=10 priority=100 version=2 authentication=simple password=<VRRP-KEY>
/interface vrrp add name=vrrp20 interface=ether1 vrid=20 priority=150 version=2 authentication=simple password=<VRRP-KEY>
/ip address add address=192.168.10.1/32 interface=vrrp10
/ip address add address=192.168.20.1/32 interface=vrrp20
```

**Resultado** (`capturas/f2/f2-01-vrrp-dist1-dist2.png`):

| Router | `vrrp10` | `vrrp20` |
|--------|----------|----------|
| DIST-1 | `RM` (master), prio 150 | `B` (backup), prio 100 |
| DIST-2 | `B` (backup), prio 100 | `RM` (master), prio 150 |

Notas:
- VRRP v3 no soporta autenticación en RouterOS, por eso se usa `version=2`. La auth simple viaja en texto plano en el segmento: protege contra un router mal configurado, no contra un atacante en la LAN (limitación documentada en `docs/f2/claves-y-secretos.md`).
- Tras crear un grupo, la interfaz tarda unos 3 segundos en asumir el rol. Una captura inmediata puede mostrar los dos routers como `B`; la captura del repo se tomó una vez estabilizado.
- Cada router lleva la IP real en la LAN (.2 en DIST-1, .3 en DIST-2) y la virtual (.1) en la interfaz `vrrp`. Los hosts apuntan solo al .1.
- La prueba de failover (apagar un master) es el drill 1 de F4.

## 2. OSPF en distribución

| Router | Hacia core (`ptp`, md5) | LANs (pasivas) | Router-ID |
|--------|-------------------------|----------------|-----------|
| DIST-1 | ether1 → CORE-1 (10.0.0.14), ether2 → CORE-2 (10.0.0.22) | ether3 (USERS), ether4 (SERVERS), lo | 6.6.6.6 |
| DIST-2 | ether2 → CORE-1 (10.0.0.18), ether3 → CORE-2 (10.0.0.26) | ether4 (USERS), ether1 (SERVERS), lo | 7.7.7.7 |

```routeros
# DIST-1
/routing ospf instance add name=ospf-lab version=2 router-id=6.6.6.6
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-lab
/routing ospf interface-template add area=backbone interfaces=ether1 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether2 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether3 passive
/routing ospf interface-template add area=backbone interfaces=ether4 passive
/routing ospf interface-template add area=backbone interfaces=lo passive

# DIST-2 (nombres rotados)
/routing ospf instance add name=ospf-lab version=2 router-id=7.7.7.7
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-lab
/routing ospf interface-template add area=backbone interfaces=ether2 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether3 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether4 passive
/routing ospf interface-template add area=backbone interfaces=ether1 passive
/routing ospf interface-template add area=backbone interfaces=lo passive
```

Las LANs son pasivas: 192.168.10.0/24 y 192.168.20.0/24 se anuncian al core sin formar vecinos con los hosts.

**Adyacencias verificadas** (todas `Full`, MD5):

| Sesión | Par | Capturas |
|:------:|-----|----------|
| 4 | DIST-1 ↔ CORE-1 (4.4.4.4, 10.0.0.13) | `f2-06b`, `f2-06d` |
| 5 | DIST-2 ↔ CORE-1 (4.4.4.4, 10.0.0.17) | `f2-07b`, `f2-07d` |
| 7 | DIST-1 ↔ CORE-2 (5.5.5.5, 10.0.0.21) | `f2-09b`, `f2-09d` |
| 8 | DIST-2 ↔ CORE-2 (5.5.5.5, 10.0.0.25) | `f2-10b`, `f2-10d` |

En todas, el core aprendió `192.168.10.0/24`, `192.168.20.0/24` y la loopback del DIST, y el DIST aprendió la loopback del core y los /30 del resto de la red. Detalle de rutas en `docs/f2/verificacion.md`.

Capturas de los templates (clave enmascarada): `f2-02a`, `f2-02b`. Exports: `f2-09e` (DIST-1), `f2-10f` (DIST-2).
