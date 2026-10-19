# F4 — Clave VRRP incorrecta (R4)

**Ejecutado:** 2026-10-16 (sesión 1; fecha del reloj del router) · Evidencia: `capturas/f4/f4-01i`, `f4-01j`, `f4-01k`, `f4-01l1`, `f4-01l2` · Política de claves: `docs/f0/proveedores-claves.md`, `docs/f2/claves-y-secretos.md`.

## Objetivo

Probar que VRRP con autenticación simple **no forma el grupo** cuando las claves no coinciden. La clave real (`<VRRP-KEY>`) no está en este documento ni en las capturas.

## Prueba

1. **[DIST-2]** se cambió la clave del grupo 10 a un valor distinto de la de DIST-1 (`/interface vrrp set vrrp10 password=<CLAVE-INCORRECTA>`). El comando no se capturó porque lleva la clave.
2. **[DIST-2]** `/interface vrrp print` (`f4-01i`) y **[DIST-1]** `/interface vrrp print` (`f4-01j`).
3. **[DIST-2]** `/log print` (`f4-01k`).
4. Se restauró la clave original en DIST-2 (comando sin capturar, por la clave) y se verificó el estado en los dos routers (`f4-01l1`, `f4-01l2`).

## Resultado

| Hecho | Evidencia |
|-------|-----------|
| DIST-2 pasa a **`RM`** en `vrrp10`, igual que DIST-1: hay **dos masters** para la misma IP virtual | `f4-01i`, `f4-01j` |
| DIST-2 rechaza los anuncios de DIST-1: `received packet from 192.168.10.2 simple authentication failed` (aviso en rojo en `vrrp print` y en el log). DIST-1 sigue siendo master con prioridad 150 | `f4-01i`, `f4-01j`, `f4-01k` |
| DIST-2 asume el master **8 s después** del cambio de clave (cambio a las 20:15:21, `now MASTER, master down timer` a las 20:15:29, reloj del router) | `f4-01k` |
| Con la clave restaurada, DIST-2 vuelve a `B` (backup) de `vrrp10` y DIST-1 queda como único master | `f4-01l1`, `f4-01l2` |

## Qué significa

- **La autenticación funciona:** los anuncios con clave distinta se rechazan. Un router que no conozca la clave no puede ingresar al grupo ni forzar un cambio de master.
- **El efecto colateral es un split-brain:** al no poder validar los anuncios de DIST-1, DIST-2 cree que no hay master y se declara master. En la LAN hay dos dueños de la misma IP y MAC virtual hasta que se corrija la clave. Por eso la clave VRRP se cambia en los dos routers a la vez (ventana de mantenimiento) y no de a uno.
- **Autenticación simple de VRRP v2 no cifra:** la clave viaja en texto plano dentro del paquete VRRP. Protege contra configuraciones erróneas y un equipo ajeno por accidente, no contra un atacante que ya esté en la LAN. Limitación aceptada para el laboratorio (ver `docs/f2/claves-y-secretos.md`).

## Reversión

Restaurar la clave en DIST-2 (`/interface vrrp set vrrp10 password=<VRRP-KEY>`). Verificado en `f4-01l1` y `f4-01l2`.
