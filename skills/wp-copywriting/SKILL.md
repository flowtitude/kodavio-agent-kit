---
name: wp-copywriting
description: Escribir copy comercial de WordPress (landing, home, página de servicio, sobre nosotros, precios, FAQ) en castellano perfecto o el idioma del sitio, anclado al scope y al sistema de diseño activo. Antes de cualquier write a través de Kodavio.
---

# wp-copywriting — Copy comercial para WordPress

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

Skill de **autoría** del agente. No mueve nada en el sitio; produce el copy listo para que `wp-page-build` lo materialice después.

## Cuándo arrancarla

- El usuario pide *"haz la landing de X"*, *"escribe la home"*, *"prepara la página de servicio Y"*, *"redacta la página sobre nosotros"*, *"FAQ del producto"* o cualquier petición de **texto comercial** dentro de WordPress.
- También si el operador trae un brief incompleto y necesita ayuda para convertirlo en copy publicable antes de construir.
- Si la petición es **contenido editorial** (post de blog, noticias, materiales formativos) → usa `wp-content-publish`, no esta. Esta cubre la voz comercial; aquella la editorial/SEO largo.

## Fase 0 — Contexto

1. `wp-site-session` ejecutado (obligatorio).
2. `kodavio/workflow-router` con la petición → debería devolver flujo `page_creation` o `content_publish` según el caso.
3. `kodavio/context-bootstrap` para recuperar:
   - **Scope** (propósito del sitio, audiencia, lenguaje, ofertas, tono).
   - **Sistema de diseño activo** (tono visual ya define tono verbal: serio/cálido, técnico/cercano, minimal/exuberante).
   - **Memoria vinculante** (`source=human` + `tag=instruction|caveat`). Léelos. Si dicen "no usar palabra X", "tratar al cliente de usted", "no prometer X feature" → son **vinculantes**, sin excepciones.
4. Si el sitio tiene `wp-bricks-fds` o `wp-tailwind-windpress` activos, el sistema visual ya marca expectativas: **el copy debe encajar con el ritmo**.

## Fase 1 — Brief de copy (NUNCA delegar)

El agente redacta el brief completo ANTES de escribir copy publicable:

1. **Objetivo concreto de la página**: ¿qué quiere el visitante? ¿qué acción tiene que ejecutar? Una sola acción primaria.
2. **Audiencia objetivo**: 1-2 perfiles concretos. No "todos los usuarios".
3. **Promesa central**: una frase que resume el valor. Si no la tienes, no escribas la página todavía — pregunta al operador.
4. **Objeciones probables**: qué pensará el lector que le frena. El copy las resuelve antes de que las articule.
5. **CTA primaria + secundaria** con destino real (URL/ancla/acción). Si el destino aún no existe (página de pago, formulario), declárelo como **bloqueante** y para.
6. **Tono y registro**: formal/informal, técnico/cercano, "tú"/"vosotros"/"usted". Heredado de scope; nunca contradecir.

Si el operador no aporta producto/oferta concretos, **no inventes ni cifras ni promesas**. Pregunta o trabaja en pseudocódigo (`[NOMBRE_PRODUCTO]`, `[PRECIO]`, `[GARANTÍA]`).

## Fase 2 — Estructura de página tipo

Adapta según objetivo; no es un molde rígido.

**Landing/Home comercial:**
1. Hero — promesa central + CTA primaria. ≤14 palabras en el titular, ≤24 en el subtítulo.
2. Pruebas (logos, números, testimonio breve) si las hay reales.
3. Problema/solución — qué resuelves, cómo.
4. Beneficios (3-6 bloques) — verbo de valor + frase corta. Evita listas tipo features sin contexto.
5. Cómo funciona (3 pasos) si el producto/servicio lo necesita.
6. Objeciones contestadas (FAQ corta o sección dedicada).
7. CTA final reforzada.

**Página de servicio:**
1. Hero — para quién es + para qué.
2. Qué incluye / qué no incluye (claridad).
3. Proceso (3-5 pasos).
4. Garantía / política si aplica.
5. Casos / resultados si los hay (sin inventar).
6. Precio o cómo se calcula.
7. CTA.

**Página "sobre nosotros":**
- Apertura honesta, no eslogan.
- Propósito (por qué existe el negocio) — más que historia.
- Equipo (1-3 personas máximo con foto, rol y especialidad).
- Cómo trabajáis (3-4 valores con ejemplo concreto, no abstracciones).
- CTA al final (contacto/agenda).

## Fase 3 — Reglas duras de copy

1. **Castellano perfecto** (o idioma del sitio). Ver `Playbook/rules/copy-review.md` si está disponible (capa SA). Sin anglicismos innecesarios (*"engagement"* → "interacción", *"awareness"* → "notoriedad").
2. **Verbos activos**, voz directa: "te ayudamos" > "podemos ayudarte"; "te enviamos" > "se enviará".
3. **Números concretos** o nada. "Más de 200 clientes" si es verdad. "Muchos clientes" es ruido.
4. **CTA con verbo + destino claro**: "Empieza prueba gratis" > "Más info"; "Hablamos 20 min" > "Contactar".
5. **Sin lorem ipsum, sin "completa esto", sin "ejemplo"**. El copy es publicable o no se entrega.
6. **Anti-features**: explica qué resuelve el feature, no el feature solo. "Backups automáticos cada 6 h" → "Si algo se rompe, vuelves al estado de hace 6 h en un click".
7. **PII fuera del transcript** (regla 12 del kit). Emails, teléfonos personales, datos privados → no se pegan literalmente en respuestas.
8. **Cero promesas que no puedas cumplir**: "garantizado", "100%", "sin riesgo" solo si el contrato/servicio lo respalda.

## Fase 4 — Entrega al builder

1. Empaqueta el copy como **content_model** estructurado por sección, listo para `kodavio/builder-workflow`:
   - Por sección: `role` (hero, problema, beneficios, faq, cta…), `heading`, `subheading`, `text` blocks, `cta_label`, `cta_url`.
   - Si el sistema de diseño activo tiene patterns en `Kodavio › Diseño y memoria › Patterns` que encajan, propón el slug del pattern + las cadenas a sustituir.
2. Avisa al operador del **idioma**, **tono** y **longitud** antes de materializar.
3. Pasa a `wp-page-build` para el write real. Esta skill **NO** llama a `builder-workflow action=create`.

## Cierre

- `kodavio/memory-write` con `source=agent`, `type=decision`, key tipo `copy/landing-x/2026-06`, con: objetivo, audiencia, promesa central, tono elegido y razón. Así la próxima sesión hereda el contexto narrativo.
- Si tomaste una decisión narrativa fuerte ("hablamos de tú", "no usamos la palabra X") y aplica al sitio entero, márcala con `tag=instruction` para que sea vinculante en futuras sesiones.
