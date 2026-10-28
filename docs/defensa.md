# Material de defensa oral (F5)

Todo lo que sigue se apoya en lo ya documentado y evidenciado en `docs/f0` a `docs/f4`, `runbooks/` y `capturas/`; no se agregan datos nuevos. Cada rol debería poder sostener su resumen de 1 minuto sin leer, y señalar en vivo la captura que respalda cada afirmación.

## R1 — Eliseche (líder, Edge-WAN)

**Resumen de 1 minuto:** "Diseñé la topología de 5 capas y el failover por capa a partir del diagrama con defectos, y me encargué del EDGE: OSPF hacia los dos cores con MD5, las dos sesiones eBGP con TCP-MD5 hacia ISP-1 e ISP-2 (ISP-1 principal por `local-pref`, ISP-2 de respaldo con prepend), la redistribución OSPF→BGP para que los proveedores aprendan solo nuestras dos LANs, y el firewall default-deny del borde. En F4 corrí los drills de caída de proveedor (BGP solo, ≈160 s) y de `check-gateway` (≈23 s, 7 veces más rápido), y probé que una clave TCP-MD5 incorrecta tira la sesión BGP sin que vuelva hasta corregirla."

**5 conceptos que tiene que dominar:**
1. Por qué OSPF usa `ptp` + MD5 en todos los enlaces internos y por qué los enlaces a los ISP quedan fuera de OSPF (van por BGP).
2. La política BGP completa: `local-pref` 200/100, `bgp-path-prepend 2` hacia ISP-2, y por qué solo se anuncian las dos LANs (nunca el direccionamiento interno) vía redistribución OSPF→BGP.
3. El firewall default-deny: listas `WAN`/`LAN`, por qué `fw-lan-a-lan` existe (tránsito entre cores si cae el core-core), y qué impide la regla final (`WAN→LAN` nuevo, EDGE como tránsito entre ISP).
4. La diferencia entre BGP solo (≈160 s, *hold timer*) y `check-gateway=ping` sobre ruta estática (≈23 s): qué detecta cada uno y por qué `check-gateway` no reemplaza a BGP.
5. Por qué se sacó el cliente DHCP de los 7 routers en F4 (corrección de la devolución de F1): el cliente DHCP acepta configuración de red por debajo del firewall.

**Qué demostrar y con qué capturas:** adyacencias OSPF EDGE↔CORE-1/CORE-2 en `Full` (`capturas/f2/f2-05a`, `f2-08a`); sesiones BGP establecidas con TCP-MD5 (`f3-01c`, `f3-01d`, `f3-02c`, `f3-02d`); filtros aplicados y `local-pref` (`f3-06b`, `f3-06c`); reglas de firewall cargadas y pruebas permitidas/bloqueadas (`f3-04a-g`, `f3-05a-e`); drill 3 BGP y drill 4 `check-gateway` (`f4-03g-j`, `f4-03k-n`); clave BGP incorrecta y restaurada (`f4-04a-c`); conexión BGP iniciada por el ISP y la regla `in-bgp-isp1` (`f4-04d-g`).

**Preguntas probables con respuesta modelo:**
- *¿Por qué eBGP directo en el edge y no un Route Reflector?* — El diagrama original tenía un RR mal ubicado (a través del firewall) para un diseño con un solo router de borde; con eBGP directo a cada ISP no hace falta RR, es más simple y es lo correcto para multi-homing de proveedor (no iBGP interno).
- *¿Qué pasa si falla la clave TCP-MD5 de un lado?* — La sesión cae y no se reestablece hasta que ambos extremos coincidan; el kernel descarta los segmentos TCP con firma inválida antes de que BGP los vea, por lo que no hay log de "autenticación fallida" como en OSPF o VRRP (`docs/f4/clave-bgp-incorrecta.md`).
- *¿Por qué `originate-default=always` y no `if-installed`?* — Se probó que `if-installed` retira el default de OSPF si EDGE pierde sus dos ISP (más correcto, pero deja al core sin default); se eligió `always` porque con dos proveedores es poco probable perder ambos a la vez, y el default no "parpadea" en el core cada vez que BGP se reestabiliza (`docs/f4/ospf-default-if-installed.md`).
- *¿Qué significa el prepend de 2 hacia ISP-2 y qué pasó al verificarlo?* — Busca que el camino de vuelta por ISP-2 sea menos atractivo (as-path más largo); al verificarlo se esperaban 3 repeticiones del AS 65000 y se vieron 2 — el efecto buscado se cumple, pero la causa de la diferencia quedó como punto abierto (`runbooks/drill-3-bgp.md`).

## R2 — Kalpin (Proveedores)

**Resumen de 1 minuto:** "Configuré ISP-1 e ISP-2 (AS 65001 y 65002), cada uno con su sesión eBGP hacia EDGE con TCP-MD5 y `default-originate=always`, y documenté la política de claves de los cuatro mecanismos de autenticación del lab. En F4 agregué `203.0.113.1` como 'Internet simulada' en la loopback de ambos ISP (porque antes solo se podía probar la loopback del proveedor activo), configuré SNMPv3 en los 7 routers con usuario `monitor` y `engine-id` único por equipo, y participé de la rotación de roles con R1 para ejecutar un drill intercambiados."

**5 conceptos que tiene que dominar:**
1. Por qué cada ISP usa `default-originate=always` y no filtra nada de EDGE (la política de salida vive en EDGE, no en los proveedores).
2. Qué es la "Internet simulada" (`203.0.113.1/32`, RFC 5737) y por qué hizo falta: sin un destino común, no se puede medir un failover de proveedor porque los ISP no se ven entre sí.
3. SNMPv3 `authPriv`: por qué cada router necesita un `engine-id-suffix` distinto (los CHR clonados comparten el mismo engine-id base) y qué pasa si dos routers lo comparten.
4. Por qué la comunidad `public` no se pudo borrar en RouterOS 7 y cómo se neutralizó (en vez de eliminarla).
5. Las 4 claves del laboratorio (OSPF, VRRP, BGP×2, SNMP×2) y por qué cada una vive en un mecanismo distinto, nunca commiteada.

**Qué demostrar y con qué capturas:** sesiones BGP en `E` desde el lado ISP (`capturas/f3/f3-01d`, `f3-02d`); `default-originate` verificado; `203.0.113.1` en la loopback de los dos ISP (`f4-03a`, `f4-03b`) y alcanzado desde los hosts (`f4-03s`, `f4-03t`); SNMPv3 configurado y comunidad `public` neutralizada en los 7 routers (`f4-02s1-s3`, `f4-02t`, `f4-03o`, `f4-03p`, `f4-04i`, `f4-05b`).

**Preguntas probables con respuesta modelo:**
- *¿Por qué los ISP no se ven entre sí?* — Es una simplificación del laboratorio: no hay interconexión ISP-1↔ISP-2 porque no forma parte del diseño de multi-homing que se quería probar (cada ISP es independiente desde el punto de vista de EDGE); por eso hizo falta un destino común (`203.0.113.1`) para poder medir failover sin depender de la loopback del proveedor activo.
- *¿Por qué SNMPv3 y no SNMPv2c con comunidad simple?* — v3 permite `authPriv` (autenticación + cifrado), evitando que la comunidad viaje en texto plano por la red de gestión; es la opción correcta para un entorno con usuario de solo lectura real.
- *¿Qué garantiza que dos routers con el mismo engine-id no funcionen bien con SNMPv3?* — El engine-id forma parte del cálculo de las claves derivadas de autenticación/cifrado de USM (SNMPv3); si dos equipos comparten engine-id, el descubrimiento y la autenticación pueden fallar o confundirse entre ambos. Se detectó en CORE-2 (que había quedado con el sufijo de CORE-1) y se corrigió.
- *¿Qué clave es más larga y por qué?* — Las de SNMPv3, porque RouterOS exige un mínimo de 8 caracteres para `authPriv`; OSPF MD5 admite hasta 16 y VRRP v2 hasta 8, pero no exige un mínimo tan alto como SNMP.

## R3 — Gutierrez Mora (Core)

**Resumen de 1 minuto:** "Corregí dos defectos del diagrama original: agregué el enlace core-core (CORE-1↔CORE-2) que faltaba, y reemplacé HSRP por VRRP moviendo el primer salto a distribución, dejando el core como tránsito puro. Configuré OSPF área 0 con MD5 en CORE-1 y CORE-2, incluido el enlace core-core. En F4 corrí el drill de caída de un enlace OSPF (≈31 s por *dead timer*, ≈1 s por portadora) y probé que una clave MD5 incorrecta entre los cores no forma la adyacencia pero no corta el tráfico, porque hay camino alterno por DIST-1."

**5 conceptos que tiene que dominar:**
1. Por qué el core-core es necesario: sin él, si cae un enlace CORE↔DIST el tráfico puede quedar sin camino óptimo o directamente sin camino.
2. Por qué HSRP (propietario de Cisco) se reemplaza por VRRP (RFC 5798, estándar abierto) y por qué el FHRP vive en distribución, no en el core.
3. La diferencia entre detección de falla OSPF por *dead timer* (≈31 s, cota entre 30-40 s porque el corte ocurre en un punto cualquiera entre hellos de 10 s) y por portadora (≈1 s).
4. Qué significa `md5 mismatch` en el log de OSPF y por qué el tráfico no se corta al fallar la adyacencia entre los cores (hay camino alterno vía DIST-1).
5. `originate-default`: la diferencia entre `always` y `if-installed`, y por qué el proyecto usa `always`.

**Qué demostrar y con qué capturas:** adyacencia core-core en `Full` con MD5 (`capturas/f2/f2-04a-d`); las 7 adyacencias del diseño (`docs/f2/verificacion.md`); drill 2 OSPF, corte silencioso y por portadora (`f4-02a-g`); clave OSPF incorrecta, `md5 mismatch` y adyacencia caída sin corte de tráfico (`f4-02h-l`); comparación `if-installed` vs `always` (`f4-04k`, `f4-04m`, `f4-04n`).

**Preguntas probables con respuesta modelo:**
- *¿Por qué 31 s y no exactamente 40 s en el corte por dead timer?* — El *dead interval* (40 s) se cuenta desde el último hello recibido, y el corte ocurre en un punto cualquiera entre dos hellos (cada 10 s); el tiempo de detección cae entre 30 y 40 s según el momento exacto del corte.
- *¿Por qué la red sigue en pie cuando falla la clave OSPF entre los cores?* — Porque el diseño tiene doble uplink: el camino CORE-2 → DIST-1 → CORE-1 mantiene la conectividad aunque la adyacencia directa core-core no se forme; es el mismo principio que mide el drill 2.
- *¿Por qué no se usó un área OSPF por capa en vez de una sola área 0?* — Con 5 routers internos y una topología chica, una sola área simplifica el diseño y evita el costo operativo de múltiples áreas (ABR, resumen de rutas) sin ganancia real en esta escala.

## R4 — Bresciani (Distribución)

**Resumen de 1 minuto:** "Corregí el defecto de subredes solapadas con el IPAM sin overlap, y diseñé e implementé VRRP en DIST-1 y DIST-2: dos grupos (USERS y SERVERS), cada DIST master de uno y backup del otro para reparto de carga, con autenticación simple VRRPv2. En F4 corrí el drill de falla del master VRRP (corte ≈3 s, failback sin pérdida), el drill de reparto de carga, y probé que una clave VRRP incorrecta no forma el grupo correctamente: el router que no valida la clave se autoproclama master, generando un split-brain con dos masters simultáneos hasta restaurar la clave."

**5 conceptos que tiene que dominar:**
1. Por qué cada DIST es master de un grupo y backup del otro (load-sharing) en vez de tener un solo master para ambas LANs.
2. Cómo funciona la IP y MAC virtual de VRRP (patrón `00:00:5E:00:01:<VRID hexa>`) y por qué los hosts apuntan siempre a la IP virtual, nunca a la IP real de un DIST.
3. Por qué VRRP usa `version=2` (v3 no soporta autenticación en RouterOS) y qué protege realmente la autenticación simple (routers mal configurados, no un atacante en la LAN).
4. El mecanismo exacto del *master-down timer* y por qué el corte medido fue ≈3 s con hello de 1 s.
5. Por qué una clave VRRP distinta entre los dos DIST produce un split-brain (dos masters) en vez de dejar sin servicio, y por qué eso obliga a cambiar la clave en los dos routers a la vez.

**Qué demostrar y con qué capturas:** estado master/backup de los dos grupos (`capturas/f2/f2-01-vrrp-dist1-dist2.png`); drill 1, corte y failback (`f4-01a-h`); drill 5, reparto de carga por LAN (`f4-01c`, `f4-01d`); clave VRRP incorrecta, dos masters y restauración (`f4-01i-l2`).

**Preguntas probables con respuesta modelo:**
- *¿Qué pasa si DIST-1 pierde su uplink al core pero sigue vivo y con su LAN arriba?* — VRRP no lo detecta: DIST-1 sigue siendo master de su grupo porque VRRP solo mira la LAN, no los uplinks. Es una limitación documentada desde F0; en este diseño se mitiga con el doble uplink (CORE-1 y CORE-2) de cada DIST, y en producción se resolvería con *tracking* de interfaz.
- *¿Por qué el split-brain y no una simple falla de autenticación "silenciosa"?* — Porque VRRP funciona por ausencia de anuncios: si DIST-2 no puede validar (o no recibe) los anuncios de DIST-1, asume que no hay master y se autoproclama. No hay un tercer estado de "esperar"; por diseño del protocolo, el backup se convierte en master ante la duda.
- *¿Por qué la autenticación simple no alcanza como medida de seguridad real?* — Viaja en texto plano dentro del paquete VRRP; un atacante que ya esté en la LAN puede leerla y suplantar al master. Protege contra un error de configuración, no contra un ataque activo.

## R5 — Petosa Ayala (Hosts / QA / Operación)

**Resumen de 1 minuto:** "Fui responsable de la verificación transversal de cada fase, del change log, de los backups y de la ejecución y documentación de los 5 drills de F4 junto con el monitoreo (SNMP, netwatch, syslog). Armé la matriz de pruebas de cada fase, medí los tiempos de failover de VRRP, OSPF, BGP y `check-gateway`, documenté por qué los routers no tienen NTP y qué significa eso para comparar horarios entre equipos, y en F5 consolidé toda esa evidencia en la memoria final."

**5 conceptos que tiene que dominar:**
1. La jerarquía de tiempos de failover medidos (VRRP ≈3 s < OSPF por portadora ≈1 s < `check-gateway` ≈23 s < OSPF por *dead timer* ≈31 s < BGP solo ≈160 s) y por qué existe esa diferencia entre capas.
2. Por qué los routers no tienen NTP y qué distingue una "hora" de una "duración" en la evidencia del lab (las duraciones son confiables, las horas absolutas no son comparables entre equipos).
3. Qué se monitorea realmente hoy (SNMPv3 del lado del router, netwatch a ISP-1, syslog remoto a SRV) y qué de eso quedó sin demostrar (`snmpwalk` desde SRV, por falta de salida a Internet del host Alpine).
4. La limitación de GNS3 con Suspend/Resume de enlaces (deja el cable "muerto") y por qué los drills posteriores usan Stop/Start de nodo.
5. Qué significa "`[x]` hecho" en el backlog (criterio de aceptación cumplido con evidencia) y por qué varias tareas de F4 quedaron marcadas con una nota (✅¹, ✅²) en vez de un simple ✅ liso.

**Qué demostrar y con qué capturas:** matriz de pruebas de F2, F3 y F4 (`docs/f2/verificacion.md`, `docs/f3/verificacion.md`, `docs/f4/verificacion.md`); tabla de tiempos medidos (`docs/f4/verificacion.md` §"Tiempos medidos"); netwatch vs. BGP (`f4-04j`, `f4-04l`, `f4-04o`); syslog remoto con una sola línea por evento (`f4-05g`, `f4-05h2`, `f4-05h3`); intento fallido de `snmpwalk` (`f4-05c`).

**Preguntas probables con respuesta modelo:**
- *¿Por qué los tiempos se midieron con ping y no con una herramienta de medición más precisa?* — Es la herramienta disponible en RouterOS/los hosts sin depender de software externo; a 1 s o 0,5 s de intervalo, el resultado es una cota con esa resolución, suficiente para comparar órdenes de magnitud entre mecanismos (que es lo que se necesitaba), no para medir al milisegundo.
- *¿Por qué no se pudo tener los 11 nodos encendidos a la vez en todas las fases?* — Límite de recursos de la VM de GNS3 (se inestabiliza con muchos nodos); por eso F2 y F3 se hicieron en sesiones de a 2-4 routers, y solo en la pasada de correcciones de F4 se habilitó la virtualización anidada para encender los 11 nodos juntos.
- *¿Qué significa que netwatch avise 2 min 9 s antes que BGP y por qué no alcanza como mecanismo de failover?* — Netwatch hace ping al gateway cada 10 s, así que detecta antes que el *hold timer* de BGP (3 min); pero solo mira si el siguiente salto responde a ICMP, no si la sesión BGP está realmente arriba ni si el proveedor tiene salida. Es una alerta operativa temprana, no un reemplazo de la detección de BGP ni un mecanismo que cambie rutas.

## Cruce de roles (parte ajena)

### R1 ↔ R2 (Edge-WAN ↔ Proveedores)

- **R1 debe poder explicar la parte de R2:** cómo se configuró `default-originate=always` en cada ISP, por qué hizo falta `203.0.113.1` como "Internet simulada" (los ISP no se ven entre sí), y el esquema de SNMPv3 (usuario `monitor`, `engine-id-suffix` único por router). Material mínimo: `docs/f3/bgp-isp.md`, `docs/f4/internet-simulada.md`, `docs/f4/snmpv3-claves.md`.
- **R2 debe poder explicar la parte de R1:** la política de `local-pref`/prepend en EDGE, por qué el firewall es default-deny y qué reglas específicas permiten BGP solo desde la IP de cada ISP, y la diferencia entre el corte de BGP solo (≈160 s) y con `check-gateway` (≈23 s). Material mínimo: `docs/f3/bgp-edge.md`, `docs/f3/firewall-edge.md`, `runbooks/drill-3-bgp.md`, `runbooks/drill-4-check-gateway.md`.
- Ya ejecutaron un drill con roles intercambiados en F4 (`docs/f4/ejecucion.md`, sesión de rotación R1↔R2); pueden apoyarse en esa experiencia concreta durante la defensa.

### R3 ↔ R4 (Core ↔ Distribución)

- **R3 debe poder explicar la parte de R4:** los dos grupos VRRP (vrid 10/20), el patrón de IP/MAC virtual, y por qué una clave VRRP incorrecta produce dos masters en lugar de dejar sin servicio. Material mínimo: `docs/f2/distribucion-vrrp-ospf.md`, `docs/f4/clave-vrrp-incorrecta.md`, `runbooks/drill-1-vrrp.md`.
- **R4 debe poder explicar la parte de R3:** por qué existe el enlace core-core y qué defecto corrige, la diferencia entre detección OSPF por *dead timer* y por portadora, y qué significa `md5 mismatch` en el log. Material mínimo: `docs/f0/core-defectos.md`, `docs/f2/ospf-core-md5.md`, `runbooks/drill-2-ospf.md`, `docs/f4/clave-ospf-incorrecta.md`.

### R5 con la parte de R1 (Hosts/QA/Operación ↔ Edge-WAN)

- **R5 debe poder explicar la parte de R1:** la política BGP completa (local-pref, prepend, redistribución) y el diseño del firewall default-deny, porque gran parte de la verificación y los tiempos que R5 consolidó dependen de ese diseño. Material mínimo: `docs/f3/bgp-edge.md`, `docs/f3/firewall-edge.md`, `docs/f0/edge-seguridad.md`.

## Hoja de números clave

| Dato | Valor | Fuente |
|------|-------|--------|
| Routers MikroTik CHR | 7 (EDGE, ISP-1, ISP-2, CORE-1, CORE-2, DIST-1, DIST-2) | `docs/f0/topologia-y-failover.md` |
| Nodos totales de laboratorio | 11 (7 routers + 2 switches + 2 hosts) | idem |
| Enlaces | 15 | idem |
| AS propios | EDGE 65000, ISP-1 65001, ISP-2 65002 | `ipam.md` |
| VRRP: corte / resolución | ≈ 3 s / 1 s | `docs/f4/verificacion.md` |
| OSPF por *dead timer*: corte | ≈ 31 s | idem |
| OSPF por portadora: corte | ≈ 1 s | idem |
| BGP (*hold* 3 min): corte | ≈ 160 s | idem |
| `check-gateway=ping`: corte | ≈ 23 s (≈7× más rápido que BGP solo) | idem |
| netwatch vs. BGP | avisa ≈ 2 min 9 s antes | `docs/f4/monitoreo.md` |
| Capturas totales | f1: 36 (27 + 9 de corrección) · f2: 36 · f3: 46 · f4: 80 | conteo de `capturas/` |
| Backups por fecha | 2026-10-09, 2026-10-13, 2026-10-14, 2026-10-17 | `backups/` |

## Decisiones de diseño con justificación

| Decisión | Justificación | Fuente |
|----------|----------------|--------|
| VRRP en distribución, no HSRP en el core | Separa responsabilidades (core = tránsito puro); VRRP es RFC abierto y funciona en MikroTik, HSRP no | `docs/f0/core-defectos.md` |
| Área OSPF única (0.0.0.0) para los 5 routers internos | Topología chica; múltiples áreas agregarían costo operativo sin ganancia real en esta escala | `docs/f2/ospf-core-md5.md` |
| eBGP directo en el edge, sin Route Reflector | Un solo router de borde con dos ISP no necesita RR; eBGP directo es más simple y correcto para multi-homing de proveedor | `docs/f0/edge-seguridad.md` |
| `local-pref` 200/100 + prepend 2 hacia ISP-2 | ISP-1 como salida/entrada principal, ISP-2 como respaldo simétrico (entrada y también "vuelta" del tráfico) | `docs/f3/bgp-edge.md` |
| Redistribución OSPF→BGP filtrada a solo las 2 LANs | El direccionamiento interno (/30 y loopbacks) no debe ser alcanzable desde los proveedores | idem |
| Firewall default-deny solo en EDGE | Es el único punto de la red con exposición directa a redes no propias (los ISP); CORE/DIST/ISP no lo necesitan por diseño | `docs/f3/firewall-edge.md` |
| `originate-default=always` en vez de `if-installed` | Con dos proveedores es poco probable perder ambos ISP a la vez; evita que el default "parpadee" en el core en cada reestabilización de BGP, a costa de no ser 100% honesto si EDGE pierde toda salida | `docs/f4/ospf-default-if-installed.md` |
| SNMPv3 `authPriv` en vez de SNMPv2c | Autenticación y cifrado real para el usuario de monitoreo, en vez de una comunidad en texto plano | `docs/f4/snmpv3-claves.md` |
| Cliente DHCP removido de los 7 routers | Un cliente DHCP activo acepta configuración de red de cualquier servidor DHCP que aparezca en el segmento, por debajo del firewall; inaceptable en un router de infraestructura | `docs/f1/correccion-dhcp-client.md` |
