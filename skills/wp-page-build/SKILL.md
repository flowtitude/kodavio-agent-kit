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
3. Elegir perfil de autoría: `fast` (defecto) o `supervised` (brief/boceto aprobado por el humano antes de escribir). Aparte, respeta el **`execution_profile`** del bootstrap (`rules/execution-profile.md`): fija cuánto dry-run/verify y si lees antes de escribir en la Fase 2 — en Seguro, dry-run + read-before-write siempre y verify completo en Fase 3.

Para páginas con datos dinámicos (loops, CPTs, campos): el flujo compuesto es `content_model_dynamic` PRIMERO (playbooks `content-model-schema`, `dynamic-data-binding`), página después.

## Fase 1.5 — Decisión create vs edit (obligatoria, antes de cualquier write)

Antes de tocar Kodavio, resolver la acción de forma determinista:

1. **Si el usuario mencionó una página por nombre, slug o URL existente** ⇒ `action=edit` con su `post_id`, jamás `create`. Verificar con `wp-search` o `builder-router` antes de elegir.
2. **Si el verbo del usuario es** {cambia, edita, ajusta, corrige, retoca, mejora, actualiza, mueve, reordena, reemplaza, reescribe} ⇒ `action=edit`.
3. **Si el verbo es** {crea, construye, monta, haz desde cero, genera} **y NO existe la URL/slug** ⇒ `action=create`.
4. **Ambigüedad o conflicto** (verbo de crear pero el slug ya existe) ⇒ preguntar una pregunta cerrada al usuario **antes** de cualquier write.

No hay penalización por preguntar; hay penalización irrecuperable por reconstruir una página publicada.

## Fase 2 — Construcción

1. `kodavio/workflow-router` → `kodavio/context-bootstrap` → `kodavio/skill-get` del playbook del builder. Bootstrap recupera scope + sistema de diseño activo + memoria vinculante + últimos cambios en una sola llamada (no necesitas llamar a `design-read`/`scope-read` por separado).
2. `kodavio/builder-get-config` + `builder-workflow action=schema`.
3. Página nueva: `builder-workflow` create con el content model completo, **status draft**.
4. **Página existente → EDITAR, no reconstruir.** Usa `builder-workflow action=edit` con `payload.operation` (`insert`/`update`/`patch`/`delete`/`move`) — funciona en Bricks, Elementor y Gutenberg, y el router lo enruta al flow `page_edit`. **Lee el árbol primero** (`action=read`/`analyze`) para obtener `node_id`/anclas; antes de tocar página publicada haz snapshot; **nunca reemplaces el árbol entero** salvo petición explícita del usuario. Tras escribir, **read-back**: relee y confirma que el objetivo cambió y lo no tocado quedó intacto. Para secciones completas reutilizables: `patterns-list` → `patterns-apply` (se adapta al sistema de diseño activo o cae a nativo).
5. Siempre `dry_run=true` primero, **y leer el `materialization_plan` del dry-run**: si `mapped_blocks` < bloques enviados, o aparece `unknown_block_as_card`/`unsupported_block_types`, el contrato está mal — NO escribir.

### Contrato del content_model (verificado en vivo, Kodavio 0.1.3)

- `content_model.sections[].blocks` usa **`type`** (`eyebrow` | `heading` | `text` | `button` | `cards`), no nodos `{name, settings}` del builder. `heading` lleva `tag`; `button` lleva `url`; `cards` lleva `columns` + `items[{heading,text}]`.
- Bloques sin `type` → fallback silencioso a cards con el nombre del tipo como título: **se pierde todo el copy y la verificación interna da PASS igualmente**. El read-back de fidelidad (Fase 3) es la única red.
- No enviar `label` de sección con texto que no deba verse: hoy se materializa como text-basic visible.
- Borrar nodos: `bricks-node-delete` (flag `confirm_destructive`); `apply_changes` agrupado solo existe en Elementor.
- Revisar responsive del grid de cards tras materializar (sale sin breakpoint móvil).

## Fase 2.5 — Pase de diseño (OBLIGATORIO tras materializar)

El output del materializador es un **andamio estructural, nunca el resultado final** (verificado en vivo: px fijos, anchos hardcodeados, sin clases del design system pese a declarar "class-first policy", sin breakpoints, alignment del hero ignorado). Tras el create, SIEMPRE un pase de patches (`bricks-apply-patch` / equivalente):

1. **Spacing** → tokens del sitio (`var(--bt-space-section-*)`, `var(--bt-space-*)` o los del design system activo), nunca dejar los px del andamio.
2. **Responsive** → breakpoints explícitos en grids/columnas (Bricks: claves con sufijo `_setting:tablet_portrait` / `:mobile_landscape` / `:mobile_portrait`; un grid de 3 → 2 → 1).
3. **Alineaciones del brief** → verificar que se aplicaron (el materializador puede ignorarlas).
4. **Superficie de cards/bandas** → fondos y radius con variables del sitio (`var(--bt-neutral-*)`, `var(--radius-*)`), no hex sueltos.
5. **Clases utilitarias** solo si WindPress/Tailwind está activo (`wp-tailwind-windpress`).

Sin pase de diseño no se pasa a Fase 3. "Crea las secciones y los textos bien" no es una página terminada.

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
