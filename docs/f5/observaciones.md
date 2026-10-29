# F5 — Observaciones sobre inconsistencias en F0-F4 (R5)

Este documento lista errores o inconsistencias encontrados en la documentación de F0 a F4 al redactar la memoria. Por regla de F5, **no se modifican** los documentos originales de esas fases; aquí se deja la corrección propuesta para que el rol responsable la aplique si corresponde.

## 1. `ipam.md` y `operacion.md` citados como `docs/f0/...` pero ubicados en la raíz

`README.md` (Índice de F0) y los `cambios.md` de F2, F3 y F4 (todos con la frase "Formato de `docs/f0/operacion.md` §5.1") citan `docs/f0/ipam.md` y `docs/f0/operacion.md`. Ambos archivos existen y tienen contenido correcto, pero viven físicamente en la **raíz del repositorio** (`ipam.md`, `operacion.md`), no dentro de `docs/f0/`. Los otros 5 documentos de F0 (`core-defectos.md`, `distribucion-vrrp.md`, `edge-seguridad.md`, `proveedores-claves.md`, `topologia-y-failover.md`) sí están en `docs/f0/`.

**Corrección propuesta (a decidir por R1/R5, no aplicada aquí):**
- Opción A: mover `ipam.md` y `operacion.md` a `docs/f0/` (consistente con el resto de F0, pero reescribe historia de archivos ya citados desde otros commits).
- Opción B: dejarlos en la raíz y corregir las citas en los `cambios.md` de F2/F3/F4 y en el README para que apunten a la raíz.

En `README.md` (entregable de F5) ya se corrigieron los links para que apunten a la ubicación real (`ipam.md`, `operacion.md` en la raíz). Las citas dentro de `docs/f2/cambios.md`, `docs/f3/cambios.md` y `docs/f4/cambios.md` **no se tocaron** (son documentos de fases anteriores).

## 2. `docs/f1/correccion-dhcp-client.md` cita una carpeta de backups que no existe

La cabecera de `docs/f1/correccion-dhcp-client.md` dice "Configuración vigente: `backups/2026-10-18/`", pero esa carpeta no existe en el repositorio. Las únicas carpetas de `backups/` son `2026-10-09/`, `2026-10-13/`, `2026-10-14/` y `2026-10-17/`. Por el contenido del propio documento (la corrección del cliente DHCP se ejecutó en la sesión 0 de F4, el 16/10) y por `docs/f4/cambios.md` y `docs/f4/verificacion.md`, el estado vigente real es **`backups/2026-10-17/`**. Es casi seguro un error de tipeo (18 en vez de 17).

**Corrección propuesta:** cambiar "`backups/2026-10-18/`" por "`backups/2026-10-17/`" en `docs/f1/correccion-dhcp-client.md:3`. No se aplicó porque es un documento de F1.

