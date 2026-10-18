# Runbook — Drill 2: caída de un enlace OSPF entre distribución y core (R3)

**Ejecutado:** 2026-10-17 (sesión 2 de F4) · Evidencia: `capturas/f4/f4-02a … f4-02g` · Config: `docs/f2/ospf-core-md5.md`.

## Objetivo

Medir cuánto tarda OSPF en reencaminar cuando se corta el enlace DIST-1 ↔ CORE-1 (`10.0.0.12/30`) y comprobar que el tráfico pasa por el camino alterno DIST-1 → CORE-2 (`10.0.0.20/30`).

## Parámetros relevantes

OSPF área 0, interfaces `type=ptp`, hello 10 s, dead 40 s, MD5 en todos los enlaces. DIST-1 es router-id `6.6.6.6`, CORE-1 `4.4.4.4`, CORE-2 `5.5.5.5`.

## Pasos

1. **[DIST-1]** `/routing ospf neighbor print`: dos vecinos en `Full`, CORE-1 (`10.0.0.13`) y CORE-2 (`10.0.0.21`) (`f4-02a`).
2. **[DIST-1]** `/ip route print where dst-address=10.255.0.11/32`: la loopback de CORE-1 se alcanza por `10.0.0.13%ether1` (`f4-02b`).
3. **[DIST-1]** ping continuo a la loopback de CORE-1: `/ping 10.255.0.11 count=240 interval=0.5`.
4. **[GNS3]** a los ~10 s, **Suspend** sobre el enlace DIST-1 ↔ CORE-1. Es un corte *silencioso*: ningún extremo ve caer la portadora y OSPF lo detecta solo por el *dead timer* (`f4-02c`).
5. **[DIST-1]** tras el corte: la ruta a `10.255.0.11/32` pasa a `10.0.0.21%ether2` (CORE-2) y el vecino de CORE-1 desaparece (`f4-02d`). `/log print` muestra la caída por *timeout* (`f4-02e`).
6. **Restauración.** Se reconectó el enlace y se verificó con `/routing ospf neighbor print` que vuelven los dos vecinos en `Full` y la ruta por `10.0.0.13` (`f4-02f`). Ver la limitación de Suspend/Resume más abajo.
7. **Variante con portadora.** Se repitió el corte de forma que la interfaz de DIST-1 detecta la caída del enlace, con un ping de 60 paquetes (`f4-02g`).

## Resultado observado

| Variante | Enviados | Recibidos | Pérdida | Corte estimado |
|----------|:--------:|:---------:|:-------:|:--------------:|
| Corte silencioso (solo *dead timer*) | 240 | 178 | 25 % | **≈ 31 s** (62 paquetes × 0,5 s) |
| Corte con detección de portadora | 60 | 58 | 3 % | **≈ 1 s** (2 paquetes × 0,5 s) |

- En el corte silencioso el vecino se declaró caído por *timeout* a las `18:17:54` (reloj del router): `neighbor { router-id: 4.4.4.4 state: Full } timeout` seguido de `state change to Down` (`f4-02e`).
- **Por qué 31 s y no 40 s:** el *dead interval* es 40 s contados desde el último hello recibido, y el corte ocurre en un punto cualquiera entre dos hellos (cada 10 s). El tiempo de detección cae entre 30 y 40 s según el momento exacto: 31 s está en el rango esperado.
- **El reencaminado no depende de CORE-1:** la ruta alterna ya estaba en la tabla de OSPF (por CORE-2), así que el reemplazo es inmediato cuando el vecino se declara caído.

## Post-mortem

- **Qué aprendimos:** la detección por *timers* de OSPF (30–40 s) es el cuello de botella; la detección por portadora la reduce a ~1 s. En un enlace físico real conviene tener ambos y, si hiciera falta bajar el tiempo, evaluar BFD (RouterOS 7 lo soporta) o reducir hello/dead con cuidado.
- **Limitación del laboratorio — Suspend/Resume de enlace en GNS3:** al hacer Suspend y luego Resume del enlace, el cable quedó "muerto" (DIST-1 no resolvía ARP de CORE-1: el ping a `10.0.0.13` daba timeout con las interfaces en `R`). **Solución que funcionó:** borrar el cable y volver a conectarlo en los mismos puertos (DIST-1 puerto 0 ↔ CORE-1 puerto 2, identificados por las etiquetas de interfaz). Para futuros drills: usar **Stop/Start del nodo** o **deshabilitar la interfaz** en vez de Suspend/Resume del enlace.
- **Resolución de la medición:** ping a 0,5 s; el valor es una cota con ±0,5 s.

## Reversión

Enlace recreado y adyacencias en `Full` (`f4-02f`). El drill no deja cambios de configuración en los routers.
