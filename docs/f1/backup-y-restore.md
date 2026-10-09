# F1 — Backup inicial y prueba de restore (R5)

## Exports (texto, versionados)

Carpeta `backups/2026-10-09/`, uno por router, comando `/export terse` (RouterOS 7.14.3):

| Archivo | Hora de captura | Dueño del commit |
|---------|-----------------|:----------------:|
| `DIST-2.rsc` | 19:21:41 | R4 |
| `DIST-1.rsc` | 19:31:29 | R4 |
| `CORE-2.rsc` | 19:44:07 | R3 |
| `CORE-1.rsc` | 19:49:06 | R3 |
| `EDGE.rsc` | 19:54:00 | R1 |
| `ISP-2.rsc` | 20:03:00 | R2 |
| `ISP-1.rsc` | 20:31:29 | R2 |

- Los `.rsc` se **transcribieron de las capturas** de consola (`capturas/f1/f1-12…f1-18`). Se omiten las líneas `/disk set slotN slot=slotN`.
- No contienen contraseñas ni claves. Los backups binarios (`.backup`) quedan **fuera del repo** (`.gitignore`).
- Dos routers (ISP-1 y DIST-2) incluyen líneas de renombre de interfaces: ver `mapa-interfaces-e-incidente.md` antes de reaplicarlos.

## Prueba de restore (ISP-1)

Se probó con un backup binario (`/system backup`) guardado en el propio router (que **no** se sube al repo):

1. **Antes:** `/user print` (admin + monitor) y `/ip address print` (lo 198.51.100.1/32, ether1 192.0.2.1/30) — `f1-19a-restore-antes.png`.
2. **Borrado total:** el router vuelve al prompt `[admin@MikroTik]`, sin direcciones y solo con `admin` — `f1-19b-restore-router-borrado.png`.
3. **Restore desde el backup:** vuelven el nombre `ISP-1`, ambas IPs y el usuario `monitor` — `f1-19c-restore-recuperado.png`.

**Resultado:** ✅ el backup restaura configuración **e identidad y usuarios** (algo que el `.rsc` de texto no cubre). Por eso la política mantiene los dos: `.rsc` versionado + `.backup` guardado fuera del repo.

> Una prueba de restore **desde `.rsc`** (`/import`) no se hizo en F1. Queda como mejora si sobra tiempo.
