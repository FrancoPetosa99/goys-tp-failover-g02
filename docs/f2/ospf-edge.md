# F2 — OSPF en EDGE (R1)

**Fecha:** 2026-10-13 (sesión 3 la configuración, sesión 6 el export) · Configuración: `backups/2026-10-13/EDGE.rsc`.

## Qué se configuró

EDGE habla OSPF solo hacia el core. Los enlaces a los ISP quedan fuera (van por BGP en F3).

| Interfaz | Vecino | Template |
|----------|--------|----------|
| ether3 | CORE-1 (10.0.0.1 ↔ 10.0.0.2) | `ptp`, md5, `auth-id=1` |
| ether4 | CORE-2 (10.0.0.5 ↔ 10.0.0.6) | `ptp`, md5, `auth-id=1` |
| lo (10.255.0.1) | — | pasiva |
| ether1 / ether2 | ISP-1 / ISP-2 | **sin OSPF** |

```routeros
/routing ospf instance add name=ospf-lab version=2 router-id=3.3.3.3
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-lab
/routing ospf interface-template add area=backbone interfaces=ether3 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=ether4 type=ptp auth=md5 auth-id=1 auth-key=<OSPF-KEY>
/routing ospf interface-template add area=backbone interfaces=lo passive
```

## Verificación

| Sesión | Par | Resultado | Capturas |
|:------:|-----|-----------|----------|
| 3 | EDGE ↔ CORE-1 | `Full` (router-id 4.4.4.4, 10.0.0.2). EDGE aprende `10.0.0.8/30`, `10.0.0.12/30`, `10.0.0.16/30`, `10.255.0.11/32` vía `10.0.0.2%ether3` | `f2-05a`, `f2-05b` |
| 6 | EDGE ↔ CORE-2 | `Full` (router-id 5.5.5.5, 10.0.0.6). EDGE aprende `10.0.0.8/30`, `10.0.0.20/30`, `10.0.0.24/30`, `10.255.0.12/32` vía `10.0.0.6%ether4`. Ping a `10.255.0.12`: 2/2 | `f2-08a`, `f2-08c` |

## ⚠ Observación para F3: renombre de interfaces en EDGE

El export de EDGE de esta fase incluye, por primera vez:

```routeros
/interface ethernet set [ find default-name=ether2 ] name=ether1
/interface ethernet set [ find default-name=ether1 ] name=ether2
```

El export de F1 (`backups/2026-10-09/EDGE.rsc`) **no** tenía esas líneas. Las IPs siguen en `ether1` (192.0.2.2/30) y `ether2` (192.0.2.6/30), y OSPF hacia el core (ether3 y ether4) funciona. Es el mismo fenómeno de numeración que en ISP-1 y DIST-2 (ver `docs/f1/mapa-interfaces-e-incidente.md`).

En F2 los ISP estuvieron siempre apagados, así que **no se verificó** que `ether1` siga apuntando a ISP-1 y `ether2` a ISP-2. Antes de configurar BGP en F3: encender EDGE + ISP-1 y ejecutar `/ping 192.0.2.1`, y luego EDGE + ISP-2 con `/ping 192.0.2.5`. Si falla, comparar el último byte de la MAC (`/interface ethernet print`) con el adaptador de GNS3 y mover las IPs por número de fila.
