# F1 — Snapshot BASE (R5)

- **Nombre:** `BASE on 08/10/26 at 21:48:44` (GNS3 → Edit → Snapshots).
- **Estado capturado:** topología completa cableada, **sin configuración** de routers (RouterOS de fábrica), 256 MB por CHR.
- **Para qué sirve:** volver a un laboratorio limpio si algo se rompe de forma irrecuperable (política de backup, `docs/f0/operacion.md` §5.2).
- **Cómo restaurar:** GNS3 → Edit → Snapshots → seleccionar BASE → *Restore*. ⚠ Restaura el proyecto completo: se pierde toda la configuración hecha después y los nodos vuelven a 256 MB de RAM (hoy corren con 130 MB).
- **Qué NO incluye:** la configuración de F1 (IPs, hardening). Esa vive en `backups/2026-10-09/*.rsc`.

Evidencia: `capturas/f1/f1-07-snapshot-base.png`.
