---
name: wp-page-build
description: Crear o mejorar páginas, secciones, templates y componentes en Bricks/Elementor/Gutenberg vía Kodavio. Orquesta el flujo page_creation con autoría previa de contenido y verificación posterior.
---

# wp-page-build — Construir páginas

Flujo Kodavio: `page_creation`. Playbooks del servidor: `bricks-build-page` / `elementor-build-page` / `gutenberg-build-page` + `design-frameworks`.

## Fase 0 — Sesión

`wp-site-session` ejecutado. Builder del sitio conocido (registry). Guardarraíles aplicados: en producción se trabaja en **draft** y publicar es gate.

## Fase 1 — Autoría (ANTES de tocar Kodavio)

El agente redacta el brief completo; esto NO se delega al plugin:

1. **Contenido**: jerarquía de secciones, copy real (no lorem), CTAs con destino. Castellano perfecto o idioma del sitio (`rules/copy-review.md`).
2. **Diseño**: leer `kodavio/design-read` + `kodavio/design-get-system` → usar tokens/clases del sistema activo. Si el encargo es visual y ambicioso, apoyarse en las skills globales `design-section` / `design-landing` para generar el boceto HTML y usarlo como brief.
3. Elegir perfil: `fast` (defecto) o `supervised` (brief/boceto aprobado por el humano antes de escribir).

Para páginas con datos dinámicos (loops, CPTs, campos): el flujo compuesto es `content_model_dynamic` PRIMERO (playbooks `content-model-schema`, `dynamic-data-binding`), página después.

## Fase 2 — Construcción

1. `kodavio/workflow-router` + `kodavio/skill-get` del playbook del builder.
2. `kodavio/builder-get-config` + `builder-workflow action=schema`.
3. Página nueva: `builder-workflow` create con el content model completo, **status draft**.
4. Página existente (Bricks): leer árbol → `bricks-apply-patch`/primitivas. Antes de tocar página publicada: `bricks-snapshot-page`. Nunca reemplazar el árbol entero.
5. Siempre `dry_run=true` primero, **y leer el `materialization_plan` del dry-run**: si `mapped_blocks` < bloques enviados, o aparece `unknown_block_as_card`/`unsupported_block_types`, el contrato está mal — NO escribir.

### Contrato del content_model (verificado en vivo, Kodavio 0.1.3)

- `content_model.sections[].blocks` usa **`type`** (`eyebrow` | `heading` | `text` | `button` | `cards`), no nodos `{name, settings}` del builder. `heading` lleva `tag`; `button` lleva `url`; `cards` lleva `columns` + `items[{heading,text}]`.
- Bloques sin `type` → fallback silencioso a cards con el nombre del tipo como título: **se pierde todo el copy y la verificación interna da PASS igualmente**. El read-back de fidelidad (Fase 3) es la única red.
- No enviar `label` de sección con texto que no deba verse: hoy se materializa como text-basic visible.
- Borrar nodos: `bricks-node-delete` (flag `confirm_destructive`); `apply_changes` agrupado solo existe en Elementor.
- Revisar responsive del grid de cards tras materializar (sale sin breakpoint móvil).

## Fase 3 — Verificación (subagente wp-verifier si la página es grande)

1. Read-back del árbol/contenido escrito.
2. Page health + editor-open check (la página abre en el builder sin errores).
3. Revisión visual de la URL del draft (preview): jerarquía, responsive, acentos/encoding intactos.
4. Reportar: URL preview, IDs creados, snapshot/backup IDs, y qué falta para publicar (gate en producción).

## Anti-patrones

- Cambiar solo colores globales cuando pidieron una página.
- Code widget como layout.
- Escribir templates en archivos del child theme.
- Publicar directamente en producción "porque quedó bien".
