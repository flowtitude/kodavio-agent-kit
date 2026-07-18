---
name: wp-reference-to-brief
description: Convertir imágenes de referencia (capturas de webs, mockups, wireframes) en un brief de construcción preciso - extrae estructura, jerarquía y ritmo con visión, lo mapea al catálogo de patrones y al design system del sitio. Usar cuando el usuario aporte una imagen como referencia de layout.
---

# wp-reference-to-brief — De imagen de referencia a brief

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

Requiere un modelo con visión (Claude Opus/Sonnet, GPT-4o+ — los que usan Claude Code y Cursor la tienen). Si el modelo activo no ve imágenes, dilo y pide descripción textual; no finjas haber visto la imagen.

## Qué es una referencia (y qué no)

- La referencia da **estructura, ritmo y sensación** — no se clona píxel a píxel. Copiar un diseño ajeno identificable = problema de copyright y de marca; el resultado debe ser una **adaptación al sistema del sitio** (sus tokens, su tipografía, su paleta).
- Wireframes y mockups propios del cliente sí se siguen fielmente: ahí la referencia ES el diseño.

## Proceso

### 1. Lectura estructural de la imagen

Recorre la captura de arriba a abajo y extrae, sección por sección:

- **Patrón** (mapea contra el catálogo de `wp-design-patterns`: hero, features grid, zigzag, pricing…).
- **Estructura**: columnas, proporciones aproximadas (1/2-1/2, 1/3-2/3…), alineación, densidad.
- **Jerarquía**: qué es lo más grande, orden de lectura, dónde están las CTAs y cuántas.
- **Ritmo**: alternancia de fondos (claro/oscuro/acento), aire entre secciones, dónde respira.
- **Componentes**: cards, acordeones, badges, formularios, sliders (¿de verdad hace falta el slider?).

### 2. Traducción al sistema del sitio

- Orienta el sistema de diseño (rol *orientar diseño* → nativa `bricks/get-design-context` o `kodavio/design-read`+`design-get-system`): la referencia se reinterpreta con LOS TOKENS DEL SITIO (no con los colores/fuentes de la captura, salvo que el usuario quiera adoptarlos — eso sería flujo `design_system` aparte).
- Sitio Bricks+FDS → mapea cada sección a clases FDS (`wp-bricks-fds`): qué heading, qué spacing semántico, qué grid.
- Lo que la referencia hace con JS/animación compleja: anótalo como "efecto opcional, fase 2" — no condiciona la estructura.

### 3. Brief de salida

El mismo formato que consume `wp-page-build` Fase 2: lista ordenada de secciones, cada una con patrón + estructura + jerarquía + copy REAL (el copy nunca sale de la referencia: se redacta para el negocio del sitio) + comportamiento responsive. Adjunta las desviaciones deliberadas respecto a la referencia y por qué.

### 4. Validación con el usuario

Presenta el brief y, si el encargo es grande o ambiguo, un boceto HTML rápido (skills de diseño tipo `design-section`/`design-landing` si están instaladas) ANTES de escribir en el builder. Imagen aprobada ≠ página aprobada: en producción sigue aplicando el gate de publicación.

## Verificación posterior (cierre del círculo)

Tras construir, compara preview contra brief sección a sección (wp-verifier). Si hay herramienta de captura disponible (Playwright/preview del agente), captura el draft y revísala con visión contra la referencia: estructura y jerarquía deben coincidir; colores y tipografía deben ser los del sitio.
