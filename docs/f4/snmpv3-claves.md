# F4 — SNMPv3 en los 7 routers: usuario, claves y hallazgos (R2)

**Ejecutado:** 2026-10-17 (sesiones 2 a 5) · Evidencia: `capturas/f4/f4-02s1 … f4-02t`, `f4-03o`, `f4-03p`, `f4-04i`, `f4-05b` y los exports de `backups/2026-10-17/` · Política: `docs/f0/proveedores-claves.md`. **Ninguna clave real está en el repo.**

## Qué se configuró

Un mismo bloque en cada router (con `engine-id-suffix` distinto):

```routeros
/snmp community add name=monitor security=private authentication-protocol=SHA1 encryption-protocol=AES authentication-password=<SNMP-AUTH-KEY> encryption-password=<SNMP-PRIV-KEY> addresses=10.0.0.0/8,192.168.0.0/16
/snmp community set [find default=yes] addresses=127.0.0.1/32 read-access=no
/snmp set enabled=yes contact="Grupo 2 GOYS" location="Lab GNS3" engine-id-suffix=<sufijo>
```

- **SNMPv3 con `authPriv`:** autenticación SHA1 y cifrado AES para el usuario `monitor`. Solo lectura, y solo desde `10.0.0.0/8` y `192.168.0.0/16`.
- **Mismo nombre, dos cosas distintas:** el usuario de sistema `monitor` (grupo `read`, F1) y la comunidad SNMP `monitor` son objetos separados.

## Identificador de motor por router

Los CHR clonados comparten el mismo engine-id base (`80003a8c04…`), y SNMPv3 necesita uno único por equipo. El sufijo se guarda como ASCII en hexadecimal.

| Router | Sufijo | `engine-id` | Captura |
|--------|:------:|-------------|---------|
| DIST-1 | `d1` | `80003a8c046431` | export `f4-02u1b` |
| DIST-2 | `d2` | `80003a8c046432` | `f4-05b` |
| CORE-1 | `c1` | `80003a8c046331` | export `f4-02u2b` |
| CORE-2 | `c2` | `80003a8c046332` | `f4-02t` |
| ISP-1 | `a1` | `80003a8c046131` | `f4-03o` |
| ISP-2 | `a2` | `80003a8c046132` | `f4-03p` |
| EDGE | `e0` | `80003a8c046530` | `f4-04i` |

## Hallazgos

1. **La comunidad `public` no se puede borrar.** RouterOS 7 trae `public` como comunidad por defecto y no permite eliminarla (se probaron tres formas de borrarla y todas fallan). Se **neutralizó**: `addresses=127.0.0.1/32` (solo el propio equipo) y `read-access=no`. En el export aparece como `/snmp community set [ find default=yes ] …`. Por eso `/snmp community print count-only` da **2** (la `public` neutralizada y `monitor`), y es el valor esperado. Capturas de la comunidad restringida: `f4-02s1`, `f4-02s2`, `f4-02s3`, `f4-03o`, `f4-03p`, `f4-04i`, `f4-05b`.
2. **Engine-id duplicado en CORE-2 (error nuestro, corregido).** En la sesión 2 se aplicó a CORE-2 el mismo sufijo `c1` de CORE-1, así que ambos tenían `80003a8c046331`. Se detectó al revisar las capturas y se corrigió el mismo día con `/snmp set engine-id-suffix=c2` (`f4-02t`). Un engine-id repetido rompe el descubrimiento y la autenticación de SNMPv3 hacia esos equipos.
3. **El export oculta los passwords de la comunidad.** `/export terse hide-sensitive` muestra la línea de `monitor` sin `authentication-password` ni `encryption-password`; los `.rsc` del repo llevan `<SNMP-AUTH-KEY>` y `<SNMP-PRIV-KEY>` para poder restaurar.
4. **Largo de las claves SNMPv3:** RouterOS exige un mínimo de 8 caracteres para los passwords de `authPriv`; las dos claves de SNMP son por eso más largas que las de OSPF, VRRP y BGP. Se comparten por el canal privado del grupo, igual que las demás.
5. **Disciplina con las capturas:** los comandos con claves no se capturan (se limpia la pantalla antes) y no se usó `/snmp community print` sin filtro. Para verificar se usó `print where name=public`, `print count-only` y `/snmp print`.
6. **`trap-community: public` en `/snmp print`** es el valor por defecto del campo y no tiene efecto sin `trap-target` (que está vacío).

## Exposición

- **EDGE:** la regla `in-snmp-lan` (UDP/161 desde la lista `LAN`) va justo antes de `in-drop-resto`; desde `WAN` (los ISP) SNMP queda bloqueado por el default-deny (`f4-04h2`).
- **Resto de los routers:** no tienen firewall (solo EDGE lo lleva por diseño); la restricción es el campo `addresses` de la comunidad.

## Pendiente

La consulta real con `snmpwalk` desde SRV no se pudo demostrar (el host Alpine no tiene `net-snmp-tools` ni salida a Internet para instalarlo). Ver `docs/f4/monitoreo.md`.
