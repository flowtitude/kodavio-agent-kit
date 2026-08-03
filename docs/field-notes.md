# Notas de campo — lo aprendido operando sitios reales

> El resto del kit dice **qué** hacer. Esto muestra **cómo se ve** hecho bien, y los modos de fallo que ya nos han costado tiempo. Un ejemplo concreto corrige más que una regla más.
>
> Todo lo de aquí es criterio del operador: **inerte sin las abilities vivas de Kodavio**, y por tanto propio del kit (`docs/kodavio-vs-kit.md`). El contrato técnico del payload no está aquí ni debe estarlo — se carga en runtime con `kodavio/skill-get`.

---

## 1. Leer un dry-run (no basta con lanzarlo)

El invariante 1 de `rules/production-guardrails.md` dice «`dry_run=true` antes de cualquier write, **y leer su salida**». La segunda mitad es la que se salta todo el mundo.

**Mal — el patrón que rompe páginas:**

```
dry_run=true → "status": "ok"  → write real
```

`ok` significa «esto se puede ejecutar», no «esto hace lo que pediste».

**Bien — el dry-run se lee como un presupuesto de obra:**

```
enviados:  8 bloques (hero, features×3, testimonial, pricing, faq, cta)
plan:      mapped_blocks: 6 · unknown_block_as_card: 2 ("pricing", "faq")
decisión:  NO escribir. Dos secciones caerían como tarjeta genérica y el copy
           se perdería sin error. El contrato está mal → volver a Validate.
```

Señales de que el plan te está avisando, todas del mismo tipo — **el sitio no sabe hacer lo que le pides y lo va a hacer igual, peor**:

| Señal | Qué significa de verdad |
|---|---|
| `mapped_blocks` < bloques enviados | Se pierde contenido en silencio |
| `unknown_block_as_card` | Esa sección sale como tarjeta genérica |
| `unsupported_block_types` | El builder del sitio no tiene ese tipo |
| El plan no menciona un bloque que enviaste | Se ignoró; no lo verás hasta el read-back |

**La verificación interna del plugin puede dar PASS con copy perdido.** El read-back de fidelidad (`wp-verifier`) es la única red real.

---

## 2. Presentar un Human Gate

Los guardarraíles mandan «parar y esperar confirmación» decenas de veces, pero en ningún sitio dicen **cómo se presenta**. Un gate mal presentado se aprueba a ciegas, y entonces no era un gate.

Cuatro bloques, siempre, y una pregunta cerrada al final:

```
GATE — publicar la home de {sitio} (producción)

QUÉ CAMBIA
  Home (post_id 42) pasa de la versión publicada de 2025-11-04 al draft nuevo.
  4 secciones tocadas: hero (copy + CTA), features (3→4 tarjetas),
  pricing (nueva), footer CTA (destino /contacto → /presupuesto).

IMPACTO
  Visible al público al instante. La home es la entrada del 60% del tráfico.
  El cambio de destino del CTA afecta a la campaña activa de Ads.

ROLLBACK
  Snapshot bricks-snap-8871 (previo al write). Restaurar = 1 llamada, ~30 s.
  Sin pérdida: el draft se conserva aparte.

PREVIEW
  https://{sitio}/?p=42&preview=true

¿Publico? (sí / no / solo hero)
```

Reglas del gate, no negociables:

- **La aprobación vale para ESA acción**, no para las siguientes (`rules/production-guardrails.md`). «Sí, publica la home» no autoriza publicar el resto.
- Si el humano contesta algo ambiguo («adelante con lo que veas bien»), **no es aprobación**: vuelve a preguntar cerrado.
- Un gate sin rollback declarado no se presenta: primero consigues el snapshot.

---

## 3. Un informe de verificación que sirve

`wp-verifier` no reporta «está bien»; reporta **qué intentó romper y no pudo**. Va a la sección Verificación de `sites/{slug}/NOTAS.md` (plantilla en `sites/_template/NOTAS.md`).

```
2026-08-03 17:40 — landing /servicios (Bricks, producción, draft)
Escrito por: wp-bricks-operator · Verificado por: wp-verifier (pase separado)

Read-back .......... page_id 118, 6 secciones, 41 nodos. Coincide con lo declarado.
Salud .............. preview 200 · editor abre sin error · acentos y ñ intactos
Fidelidad .......... 5/6 secciones fieles al brief.
                     DESVIACIÓN: el testimonial salió sin la foto (el brief la pedía).
Responsive ......... grid 3→2→1 correcto. Hero: el H1 desborda en 375px.
Rollback ........... snapshot bricks-snap-9012 verificado (existe y es del pre-write).

VEREDICTO: PASS con avisos — 2 hallazgos (foto del testimonial, H1 en móvil).
           No publicar hasta corregir el H1.
```

Lo que convierte esto en verificación y no en autoengaño: **cada línea dice qué llamada o URL lo demuestra**, y quien verifica no es quien escribió. Un «write que no falló» no es un write verificado.

---

## 4. Create vs edit: el caso caro

La regla de oro 9 y la Fase 1.5 de `wp-page-build` lo cubren. El caso que se cuela es este:

> «**Monta** la página de precios con los tres planes nuevos»

Verbo de crear (`monta`) + `/precios` **ya existe y está publicada**. Si aplicas el verbo, reconstruyes una página viva y pierdes lo que no estaba en el brief (SEO, bloques de otra persona, tracking). Es irrecuperable en la práctica aunque haya snapshot, porque nadie recuerda qué había.

El movimiento correcto cuesta una frase:

> «`/precios` ya existe (post_id 87, publicada). ¿La **edito** metiendo los tres planes nuevos y conservando el resto, o quieres una página nueva desde cero?»

No hay penalización por preguntar. Sí la hay por reconstruir.

---

## 5. Modos de fallo verificados en vivo

Ordenados por lo que cuestan. Cada uno tiene ya su regla; aquí está el porqué, que es lo que hace que se respete.

**El materializador entrega un andamio, no una página.** Verificado: sale con px fijos, anchos hardcodeados, sin breakpoints y sin las clases del design system *aunque el sitio declare class-first policy*, y a veces ignorando las alineaciones del brief. Por eso el pase de diseño (Fase 2.5 de `wp-page-build`) es obligatorio y no opcional. «Crea las secciones y los textos bien» no es una página terminada.

**Un write que devuelve error puede haberse ejecutado.** Visto en Elementor. Si reintentas a ciegas, duplicas contenido. Ante un error de output: **read-back primero**, reintento después — y solo si el read-back dice que no se escribió.

**Éxito reportado ≠ cambio aplicado.** Si Kodavio devuelve `ok` y el read-back no coincide, es un FALLO, no un éxito con ruido. Está en las señales de parada de `rules/production-guardrails.md`.

**Dos writes en paralelo al mismo post se pisan.** Bricks y Elementor guardan el árbol entero en una sola fila de postmeta: la segunda escritura sobrescribe la primera, sin error. Nunca paralelices writes contra el mismo post/template; >5 escrituras van en serie con read-back entre lotes.

**Una whitelist `tools:` en un subagente bloquea las MCP de Kodavio.** Verificado en vivo. Por eso `wp-auditor` tiene todas las tools y su read-only es una promesa del prompt, no una restricción de la herramienta — y por eso la regla está escrita en mayúsculas dentro de su propio prompt.

**`theme.json` solo sobre child theme.** Escribir sobre el parent se pierde en la siguiente actualización del tema y no hay aviso. Comprobar el tema activo antes, y pasar siempre por las abilities de design-source, nunca por el filesystem.

**Elementor tiene su propia lista de brechas.** Widgets que no se pueden crear, clases de contenedor que no llegan al DOM, y CSS compilado que no se regenera por MCP (el estilo no se ve hasta que el operador da Update). Todas reproducidas: `docs/kodavio-gaps-elementor.md`. Léelas antes de presupuestar una plantilla de Elementor Pro.

**Bugs conocidos del converter.** Al migrar entre builders, revisa específicamente: colores que aterrizan como `background`, `video_type` perdido, tipos de template mal mapeados y dynamic bindings que quedan muertos. `wp-verifier` los tiene en su checklist.

---

## 6. Redactar datos sensibles sin bloquear el trabajo

La regla 12 de `AGENTS.md` prohíbe volcar datos sensibles al transcript. No significa «no puedo ayudarte»: significa entregar lo útil sin el dato.

```
Mal:  El admin es maria.gonzalez@clienteacme.com y la App Password es xK9m-2Lq8-...
Bien: 3 administradores: m***@clienteacme.com (último acceso 2026-07-28),
      a***@clienteacme.com y un tercero creado el 2026-08-01 que no reconozco
      — ese es el hallazgo. Si necesitas el correo completo: Usuarios > Editar (ID 14).
```

El patrón es siempre el mismo: **el hallazgo, en claro; el identificador, redactado; y el path del admin donde el humano lo lee él mismo.** Detalle en `docs/credentials.md`.

---

## Cómo crece este documento

Una entrada nueva solo cuando algo **pasó de verdad** en un sitio y costó tiempo. Con su evidencia y con la regla que la previene. Dos coincidencias del mismo fallo ⇒ deja de ser nota de campo y sube a `rules/` (o al plugin, si lo que falla es la ejecución y no el criterio).
