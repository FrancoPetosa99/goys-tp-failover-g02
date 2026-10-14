# F2 — Claves y secretos aplicados (R2)

Política de F0: `docs/f0/proveedores-claves.md`. Este documento registra qué se activó en F2, dónde viven las claves y qué se aprendió. **Ninguna clave real está en el repo.**

## Mecanismos activos al cierre de F2

| Mecanismo | Dónde | Detalle | Clave en el repo |
|-----------|-------|---------|------------------|
| OSPF MD5 | EDGE, CORE-1, CORE-2, DIST-1, DIST-2 (toda interfaz con vecinos) | `auth=md5`, `auth-id=1`, misma clave en toda el área | `<OSPF-KEY>` |
| VRRP auth simple | DIST-1 y DIST-2, grupos 10 y 20 | VRRP v2, `authentication=simple` | `<VRRP-KEY>` |
| BGP TCP-MD5 (×2) | EDGE ↔ ISP-1 / ISP-2 | pendiente, F3 | `<BGP-KEY-ISP1>`, `<BGP-KEY-ISP2>` |

## Dónde viven las claves

Las claves reales se comparten por el canal privado del grupo. En el repo (configs, backups, capturas, memoria) se muestran siempre como `<...>`.

Límites de longitud de los protocolos: la clave OSPF MD5 admite hasta 16 caracteres y la de VRRP v2 hasta 8.

## Hallazgos de F2

1. **`/export hide-sensitive` no oculta la clave OSPF.** En RouterOS 7.14.3 el export omite el password de VRRP, pero muestra `auth-key=` de `/routing ospf interface-template` en texto plano. Lo mismo hace `/routing ospf interface-template print` en consola.
   - Consecuencia: los `.rsc` de `backups/2026-10-13/` tienen la clave reemplazada por `<OSPF-KEY>`, y las capturas de exports y de templates se subieron con la clave tapada.
   - Para futuros exports (F3, F4): filtrar antes de subir, por ejemplo `sed -i 's/auth-key=[^ ]*/auth-key=<OSPF-KEY>/' backups/<fecha>/*.rsc`, y revisar a ojo antes de cada commit.
2. **El export tampoco guarda el password de VRRP**, por lo que un restore desde `.rsc` requiere volver a cargarlo (`/interface vrrp set [find] password=<VRRP-KEY>`). Está anotado en el encabezado de cada `.rsc` de DIST.
3. **VRRP v2 con auth simple viaja en texto plano.** Protege contra un router que se une al grupo por error, no contra alguien que escuche el segmento. VRRP v3 no admite autenticación en RouterOS; es una limitación aceptada para el lab.

## Desvío respecto de F0

La política de F0 dice "no usar claves triviales". Por decisión del grupo, en el laboratorio se usaron claves cortas y fáciles de recordar. Se acepta como desvío de laboratorio porque las claves no se publican; en producción serían largas, aleatorias y rotadas.

## Pendiente

- **F3:** definir dos claves distintas entre sí para las sesiones BGP, y activar TCP-MD5 de ambos lados.
- **F4:** probar que una clave incorrecta rompe la adyacencia OSPF, la sesión BGP y la formación del grupo VRRP.
