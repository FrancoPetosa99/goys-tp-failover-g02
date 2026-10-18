# F4 — Clave OSPF incorrecta (R3)

**Ejecutado:** 2026-10-17 (sesión 2) · Evidencia: `capturas/f4/f4-02h … f4-02l` · Política: `docs/f0/proveedores-claves.md`, `docs/f2/claves-y-secretos.md`. La clave real (`<OSPF-KEY>`) no está en este documento ni en las capturas.

## Objetivo

Probar que OSPF con MD5 **no forma adyacencia** cuando la clave de un extremo no coincide, y observar el efecto sobre el tráfico.

## Prueba

El enlace elegido fue CORE-1 ↔ CORE-2 (`10.0.0.8/30`), porque tiene camino alterno (por DIST-1) y se ve el efecto sin cortar el servicio.

1. **[CORE-2]** se cambió la clave MD5 de la plantilla OSPF de `ether2` a un valor incorrecto (`/routing ospf interface-template set [find interfaces=ether2] auth-key=<CLAVE-INCORRECTA>`; comando no capturado porque lleva la clave). Se evitó `print` de las plantillas, que mostraría la clave.
2. **[CORE-2]** `/log print where topics~"ospf"` (`f4-02h`, `f4-02k`).
3. **[CORE-1]** `/routing ospf neighbor print` (`f4-02i`).
4. **[CORE-2]** ping y traceroute a la loopback de CORE-1, `10.255.0.11` (`f4-02j`).
5. Se restauró la clave original (comando sin capturar) y se verificó con `/routing ospf neighbor print` (`f4-02l`).

## Resultado

| Hecho | Evidencia |
|-------|-----------|
| CORE-2 registra `authentication failed from 10.0.0.9 md5 mismatch` cada 10 s (18:53:34 y 18:53:44, reloj del router: un aviso por hello recibido) | `f4-02h`, `f4-02k` |
| CORE-1 ya no ve a CORE-2: su única adyacencia es DIST-1 (`6.6.6.6`, `10.0.0.14`) | `f4-02i` |
| El tráfico **no se corta**: ping 4/4 de CORE-2 a `10.255.0.11` y el traceroute pasa por `10.0.0.22` (DIST-1) en lugar de ir directo | `f4-02j` |
| Con la clave restaurada, la adyacencia con CORE-1 vuelve a `Full` en **1 min 28 s** | `f4-02l` |

## Qué significa

- **MD5 funciona:** un vecino con clave distinta no pasa de la autenticación (el mensaje `md5 mismatch` lo dice explícitamente) y no llega a formar adyacencia, así que no puede inyectar ni leer rutas.
- **La red sigue en pie por la redundancia del diseño:** el camino CORE-2 → DIST-1 → CORE-1 mantiene la conectividad; es el mismo principio que mide el drill 2.
- **Se recupera sola al corregir la clave**, aunque no de inmediato: la adyacencia tardó 1 min 28 s en volver a `Full` (hello 10 s, dead 40 s).
- **Hallazgo de F3 que sigue vigente:** el `/export hide-sensitive` **no** oculta `auth-key` de OSPF; las capturas de exports se suben con la clave tapada y los `.rsc` llevan `<OSPF-KEY>`.

## Reversión

Clave restaurada (verificado en `f4-02l`). No quedan cambios en CORE-2.
